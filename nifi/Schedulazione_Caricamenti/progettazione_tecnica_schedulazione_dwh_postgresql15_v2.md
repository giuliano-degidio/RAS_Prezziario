# Progettazione tecnica della schedulazione configurabile DWH - versione 2

## 1. Obiettivo e stato delle decisioni

Il documento consolida la progettazione del batch Python che, con esecuzione giornaliera, legge da PostgreSQL la configurazione attiva e decide se avviare un'elaborazione DWH.

### Requisiti confermati

- Database: PostgreSQL versione minima 15.
- Una sola elaborazione abilitata globalmente.
- Frequenze: annuale, semestrale, quadrimestrale, trimestrale, bimestrale, mensile, settimanale e quotidiana.
- Giorni ISO: `1 = lunedì`, ..., `7 = domenica`.
- La data dell'ultimo successo resta distinta dall'esito dell'ultimo tentativo.
- Gli errori sono troncati a 4.000 caratteri.
- In assenza di righe abilitate il batch non esegue nulla e scrive sul log.
- Una configurazione non valida produce un errore sul log e non avvia il carico.
- L'ultimo giorno della finestra di retry è incluso.
- `DAILY` non prevede retry.
- Il file di log viene ruotato mensilmente.
- La runtime del batch DWH impedisce più istanze concorrenti dell'elaborazione reale.

## 2. Architettura proposta

Si propongono due tabelle:

- `ctl.dwh_schedule`: una riga per elaborazione, configurazione corrente e stato sintetico;
- `ctl.dwh_schedule_run`: una riga per ogni tentativo, per audit e diagnosi.

La configurazione della regola è rappresentata da colonne tipizzate:

- `frequency_code`;
- `anchor_month`;
- `week_ordinal`;
- `weekday_iso`;
- `retry_days`.

Questa soluzione è preferita a JSONB e cron perché consente constraint SQL espliciti, query leggibili e manutenzione diretta.

## 3. Semantica dei periodi

`anchor_month` identifica il primo mese del ciclo:

- `ANNUAL`: ogni 12 mesi;
- `SEMIANNUAL`: ogni 6 mesi;
- `FOUR_MONTHLY`: ogni 4 mesi;
- `QUARTERLY`: ogni 3 mesi;
- `BIMONTHLY`: ogni 2 mesi;
- `MONTHLY`: ogni mese, con `anchor_month = NULL`;
- `WEEKLY`: usa solo `weekday_iso`;
- `DAILY`: non usa parametri di calendario.

Esempio: `QUARTERLY` con `anchor_month = 2` produce cicli ancorati a febbraio, maggio, agosto e novembre.

## 4. Regola mensile basata su settimane ISO

### 4.1 Definizione della settimana del mese

Per le frequenze annuale, semestrale, quadrimestrale, trimestrale, bimestrale e mensile:

- la settimana 1 è la settimana ISO, da lunedì a domenica, che contiene il primo giorno del mese;
- la settimana 2 è la settimana ISO successiva;
- lo stesso criterio vale fino alla settimana 5.

La settimana 1 può iniziare nel mese precedente. La settimana 5 può terminare nel mese successivo.

### 4.2 Regola vincolante di slittamento

Il programma calcola il giorno `weekday_iso` nella settimana `week_ordinal`.

- Se la data appartiene al mese di esecuzione, diventa la data pianificata.
- Se la data non appartiene al mese di esecuzione, il programma passa alla settimana ISO successiva e sceglie lo stesso giorno ISO.
- La seconda data diventa la data pianificata anche se ricade nel mese o nell'anno successivo.
- Lo slittamento è parte del calcolo della data pianificata e non è un retry.

```text
inizio_settimana_1 = lunedì della settimana ISO contenente il giorno 1 del mese
candidato = inizio_settimana_1
            + 7 * (week_ordinal - 1)
            + (weekday_iso - 1) giorni

se candidato appartiene al mese:
    data_pianificata = candidato
altrimenti:
    data_pianificata = candidato + 7 giorni
```

### 4.3 Esempio: primo sabato della prima settimana di marzo

Se il 1° marzo cade di domenica:

- la settimana ISO 1 va da lunedì 24 febbraio a domenica 2 marzo;
- il sabato della settimana è il 28 febbraio;
- il 28 febbraio non appartiene a marzo;
- il programma passa alla settimana ISO successiva;
- la data pianificata diventa sabato 7 marzo.

```text
week_ordinal = 1
weekday_iso  = 6
```

### 4.4 Esempio senza slittamento

Con `week_ordinal = 2` e `weekday_iso = 2`, se il candidato è martedì 10 marzo, la data appartiene a marzo. La pianificazione resta il 10 marzo.

### 4.5 Esempio: quinta domenica esterna al mese

Se la domenica della quinta settimana ISO cade nel mese successivo, l'occorrenza non è disponibile nel mese configurato. Il programma passa alla settimana ISO successiva e pianifica la domenica di quella settimana.

Questa regola può causare uno slittamento rilevante rispetto alla fine del mese. Il comportamento è intenzionale e deve essere coperto da test specifici.

## 5. Periodo logico e data fisica di esecuzione

Una data slittata resta associata al periodo logico che l'ha generata.

Esempio: una schedulazione mensile riferita a marzo, eseguita dopo slittamento il 7 aprile, completa il periodo logico di marzo.

La sola colonna `last_success_at` non è sufficiente, perché il mese del timestamp fisico può essere diverso dal periodo completato. Si aggiunge quindi:

- `last_success_period_start date`: inizio del periodo logico completato con successo.

Il controllo di idempotenza confronta `last_success_period_start` con `period_start`. Non deduce il periodo dal mese di `last_success_at`.

## 6. Interazione tra slittamento, retry e ciclo successivo

La data slittata diventa la nuova `planned_date`. Il retry decorre da tale data.

Per evitare la sovrapposizione di due cicli:

1. il batch valuta il periodo precedente e il periodo corrente;
2. i periodi sono esaminati dal più vecchio al più recente;
3. la fine del retry è il minore tra:
   - `planned_date + retry_days`;
   - il giorno precedente alla `planned_date` del ciclo successivo;
4. se il limite calcolato precede `planned_date`, rimane valido almeno il giorno pianificato;
5. una singola invocazione giornaliera avvia al massimo un ciclo;
6. se due cicli risultano dovuti nello stesso giorno, ha priorità il ciclo più vecchio.

Lo slittamento oltre `period_end` è ammesso. Il retry, invece, non può oltrepassare la data pianificata del ciclo successivo.

## 7. Casi particolari verificati

### 7.1 Mese che inizia di domenica

I giorni da lunedì a sabato della settimana 1 sono nel mese precedente. Per tali giorni si applica lo slittamento di sette giorni.

### 7.2 Mese che inizia di lunedì

Tutti i giorni della settimana 1 appartengono al mese. Non si applica slittamento.

### 7.3 Quinta settimana parziale

Il giorno richiesto può essere nel mese successivo. In tal caso si applica un ulteriore slittamento di sette giorni, come richiesto.

### 7.4 Passaggio dicembre-gennaio

La data pianificata può ricadere nell'anno successivo. `last_success_period_start` conserva l'attribuzione al periodo originario.

### 7.5 Anno bisestile

Il calcolo usa date di calendario, quindi febbraio viene gestito con 28 o 29 giorni senza una regola ad hoc.

### 7.6 Ora legale e timezone

Le regole usano valori `date`; l'audit usa `timestamptz`. La timezone applicativa che determina il giorno corrente deve essere configurata esplicitamente. Fino a tale decisione, non è corretto assumere la timezone del server.

### 7.7 Due cicli dovuti nello stesso giorno

Ha priorità il periodo più vecchio e viene avviata una sola elaborazione. Il ciclo più recente viene rivalutato il giorno successivo, se ancora nella propria finestra.

### 7.8 Modifica della configurazione durante uno slittamento

Rischio: cambiare regola dopo la fine del periodo ma prima della data slittata modifica il calcolo retroattivamente. Proposta: registrare nell'audit i parametri effettivamente usati (`frequency_code`, `anchor_month`, `week_ordinal`, `weekday_iso`, `retry_days`) oppure introdurre una versione della configurazione. Questa estensione è raccomandata ma non ancora confermata.

## 8. Modello fisico

### 8.1 Tabella di configurazione

| Colonna | Tipo | Null | Descrizione |
|---|---|---:|---|
| `schedule_id` | `bigint identity` | No | PK tecnica |
| `process_code` | `varchar(100)` | No | Codice univoco processo |
| `process_description` | `varchar(500)` | No | Descrizione |
| `enabled` | `boolean` | No | Elaborazione attiva |
| `frequency_code` | `varchar(20)` | No | Frequenza |
| `anchor_month` | `smallint` | Sì | Mese 1..12 |
| `week_ordinal` | `smallint` | Sì | Settimana 1..5 |
| `weekday_iso` | `smallint` | Sì | Giorno ISO 1..7 |
| `retry_days` | `smallint` | Sì | Giorni di retry |
| `last_success_at` | `timestamptz` | Sì | Timestamp ultimo successo |
| `last_success_period_start` | `date` | Sì | Periodo logico completato |
| `last_attempt_at` | `timestamptz` | Sì | Ultimo tentativo |
| `last_attempt_status` | `varchar(20)` | Sì | `RUNNING`, `SUCCESS`, `FAILED`, `SKIPPED` |
| `last_error_message` | `varchar(4000)` | Sì | Errore troncato |
| `created_at` | `timestamptz` | No | Creazione |
| `updated_at` | `timestamptz` | No | Modifica |

### 8.2 DDL PostgreSQL 15

```sql
CREATE SCHEMA IF NOT EXISTS ctl;

CREATE TABLE ctl.dwh_schedule (
    schedule_id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    process_code                varchar(100) NOT NULL,
    process_description         varchar(500) NOT NULL,
    enabled                     boolean NOT NULL DEFAULT false,
    frequency_code              varchar(20) NOT NULL,
    anchor_month                smallint,
    week_ordinal                smallint,
    weekday_iso                 smallint,
    retry_days                  smallint,
    last_success_at             timestamptz,
    last_success_period_start   date,
    last_attempt_at             timestamptz,
    last_attempt_status         varchar(20),
    last_error_message          varchar(4000),
    created_at                  timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                  timestamptz NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uq_dwh_schedule_process UNIQUE (process_code),
    CONSTRAINT ck_dwh_schedule_frequency CHECK (frequency_code IN (
        'ANNUAL', 'SEMIANNUAL', 'FOUR_MONTHLY', 'QUARTERLY',
        'BIMONTHLY', 'MONTHLY', 'WEEKLY', 'DAILY'
    )),
    CONSTRAINT ck_dwh_schedule_anchor CHECK (
        anchor_month IS NULL OR anchor_month BETWEEN 1 AND 12
    ),
    CONSTRAINT ck_dwh_schedule_week CHECK (
        week_ordinal IS NULL OR week_ordinal BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_dwh_schedule_weekday CHECK (
        weekday_iso IS NULL OR weekday_iso BETWEEN 1 AND 7
    ),
    CONSTRAINT ck_dwh_schedule_retry CHECK (
        retry_days IS NULL OR retry_days >= 0
    ),
    CONSTRAINT ck_dwh_schedule_status CHECK (
        last_attempt_status IS NULL OR
        last_attempt_status IN ('RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED')
    ),
    CONSTRAINT ck_dwh_schedule_shape CHECK (
        (frequency_code = 'DAILY'
         AND anchor_month IS NULL AND week_ordinal IS NULL
         AND weekday_iso IS NULL AND retry_days IS NULL)
        OR
        (frequency_code = 'WEEKLY'
         AND anchor_month IS NULL AND week_ordinal IS NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
        OR
        (frequency_code = 'MONTHLY'
         AND anchor_month IS NULL AND week_ordinal IS NOT NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
        OR
        (frequency_code IN (
            'ANNUAL', 'SEMIANNUAL', 'FOUR_MONTHLY',
            'QUARTERLY', 'BIMONTHLY'
         )
         AND anchor_month IS NOT NULL AND week_ordinal IS NOT NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
    )
);

CREATE UNIQUE INDEX uq_dwh_schedule_one_enabled
    ON ctl.dwh_schedule ((enabled))
    WHERE enabled;

CREATE TABLE ctl.dwh_schedule_run (
    run_id          uuid PRIMARY KEY,
    schedule_id     bigint NOT NULL REFERENCES ctl.dwh_schedule(schedule_id),
    process_code    varchar(100) NOT NULL,
    planned_date    date,
    period_start    date,
    period_end      date,
    started_at      timestamptz NOT NULL,
    finished_at     timestamptz,
    status          varchar(20) NOT NULL,
    return_code     integer,
    duration_ms     bigint,
    error_message   varchar(4000),
    CONSTRAINT ck_dwh_run_status CHECK (
        status IN ('RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED')
    ),
    CONSTRAINT ck_dwh_run_duration CHECK (
        duration_ms IS NULL OR duration_ms >= 0
    )
);

CREATE INDEX ix_dwh_run_schedule_started
    ON ctl.dwh_schedule_run (schedule_id, started_at DESC);
```

## 9. Trigger di abilitazione esclusiva

```sql
CREATE OR REPLACE FUNCTION ctl.fn_dwh_schedule_enable_exclusive()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.enabled THEN
        UPDATE ctl.dwh_schedule
           SET enabled = false,
               updated_at = clock_timestamp()
         WHERE enabled = true
           AND schedule_id IS DISTINCT FROM NEW.schedule_id;
    END IF;

    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_dwh_schedule_enable_exclusive
BEFORE INSERT OR UPDATE OF enabled
ON ctl.dwh_schedule
FOR EACH ROW
EXECUTE FUNCTION ctl.fn_dwh_schedule_enable_exclusive();
```

Il trigger applica la disabilitazione automatica. L'indice univoco parziale garantisce che non possano essere committate due righe attive. In caso di abilitazioni realmente concorrenti una transazione può ricevere una violazione di unicità e deve essere gestita dal chiamante.

## 10. Algoritmo Python aggiornato

### 10.1 Calcolo della data con slittamento

```python
from datetime import date, timedelta


def planned_weekday_with_rollover(
    year: int,
    month: int,
    week_ordinal: int,
    weekday_iso: int,
) -> date:
    if week_ordinal not in range(1, 6):
        raise ValueError("week_ordinal deve essere compreso tra 1 e 5")
    if weekday_iso not in range(1, 8):
        raise ValueError("weekday_iso deve essere compreso tra 1 e 7")

    first_day = date(year, month, 1)
    week_1_monday = first_day - timedelta(days=first_day.isoweekday() - 1)
    candidate = (
        week_1_monday
        + timedelta(weeks=week_ordinal - 1)
        + timedelta(days=weekday_iso - 1)
    )

    if candidate.month != month:
        candidate += timedelta(days=7)

    return candidate
```

### 10.2 Selezione del ciclo dovuto

```python
def select_due_cycle(schedule, today, candidate_cycles):
    due_cycles = []

    for cycle in sorted(candidate_cycles, key=lambda c: c.period_start):
        if schedule.last_success_period_start == cycle.period_start:
            continue

        planned = calculate_planned_date(schedule, cycle)
        next_planned = calculate_next_cycle_planned_date(schedule, cycle)

        if schedule.frequency_code == "DAILY":
            allowed_end = planned
        else:
            retry_end = planned + timedelta(days=schedule.retry_days)
            allowed_end = min(retry_end, next_planned - timedelta(days=1))
            if allowed_end < planned:
                allowed_end = planned

        if planned <= today <= allowed_end:
            due_cycles.append((cycle, planned, allowed_end))

    return due_cycles[0] if due_cycles else None
```

`candidate_cycles` deve contenere almeno il periodo precedente e quello corrente. L'implementazione deve registrare nel log entrambi i calcoli e il motivo di inclusione o esclusione.

### 10.3 Aggiornamento dell'esito

In caso di successo:

```sql
UPDATE ctl.dwh_schedule
   SET last_success_at = clock_timestamp(),
       last_success_period_start = :period_start,
       last_attempt_status = 'SUCCESS',
       last_error_message = NULL,
       updated_at = clock_timestamp()
 WHERE schedule_id = :schedule_id;
```

In caso di errore, `last_success_at` e `last_success_period_start` non vengono modificati. Il messaggio è salvato come `str(error)[:4000]`.

## 11. Logging e rotazione mensile

### 11.1 Impostazione Python

Il programma deve usare un file stabile senza una seconda rotazione interna:

```python
import logging
from pathlib import Path


def configure_logging(log_file: str) -> logging.Logger:
    path = Path(log_file)
    path.parent.mkdir(parents=True, exist_ok=True)

    handler = logging.FileHandler(path, encoding="utf-8")
    handler.setFormatter(logging.Formatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s"
    ))

    logger = logging.getLogger("dwh_scheduler")
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)
    logger.propagate = False
    return logger
```

### 11.2 Rotazione mensile proposta

Su Linux la rotazione può essere affidata a `logrotate`:

```text
/var/log/dwh/dwh_scheduler.log {
    monthly
    rotate 12
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    dateext
    dateformat -%Y-%m
}
```

La rotazione mensile è un requisito confermato. `rotate 12` è solo una proposta: il numero di mesi da conservare non è stato definito.

`copytruncate` semplifica la gestione perché il processo continua a scrivere sullo stesso file, ma presenta una piccola finestra di possibile perdita o duplicazione durante la copia. Se la piattaforma supporta la riapertura del file, è preferibile una rotazione con rename e reopen.

### 11.3 Contenuti minimi del log

- avvio e fine dello scheduler;
- durata complessiva;
- identificativo e codice processo;
- periodo precedente e corrente valutati;
- candidato iniziale;
- eventuale slittamento;
- data pianificata finale;
- finestra di retry;
- motivo della decisione;
- avvio e fine del placeholder;
- codice di ritorno;
- errore troncato;
- nessuna credenziale o DSN completo.

## 12. Test aggiornati

### 12.1 Test della regola ISO

1. Mese che inizia di domenica, settimana 1, sabato: il candidato è nel mese precedente e la data finale è sette giorni dopo.
2. Mese che inizia di lunedì: nessun giorno della settimana 1 viene slittato.
3. Seconda settimana con giorno interno al mese: nessuno slittamento.
4. Quinta settimana con giorno nel mese successivo: ulteriore slittamento di sette giorni.
5. Dicembre con slittamento a gennaio: periodo logico invariato.
6. Febbraio bisestile e non bisestile: calcolo valido senza eccezioni.

### 12.2 Test di periodo e idempotenza

1. Successo fisico ad aprile per periodo marzo: `last_success_period_start` resta marzo.
2. Riesecuzione dello scheduler nello stesso giorno: il periodo completato non viene rilanciato.
3. Errore sul periodo slittato: i dati dell'ultimo successo restano invariati.
4. Periodo precedente e corrente entrambi dovuti: viene scelto il precedente.
5. Una sola invocazione avvia al massimo un ciclo.

### 12.3 Test del retry

1. Giorno pianificato: esecuzione ammessa.
2. Ultimo giorno del retry: esecuzione ammessa.
3. Giorno successivo: esecuzione esclusa.
4. Retry oltre la pianificazione successiva: troncamento al giorno precedente.
5. Finestra calcolata vuota: resta valido il giorno pianificato.

### 12.4 Test operativi

1. Nessuna riga attiva: log `INFO`, nessuna esecuzione, codice 0.
2. Configurazione non valida: log `ERROR`, nessuna esecuzione, codice 1.
3. Errore oltre 4.000 caratteri: persistenza dei primi 4.000.
4. Rotazione al cambio mese: file precedente chiuso e nuovo file attivo.
5. Log ruotato compresso secondo la configurazione operativa.

## 13. Deployment e rollback

### Deployment

1. Creare schema, tabelle, constraint e indici.
2. Creare funzione e trigger.
3. Applicare privilegi minimi al ruolo runtime.
4. Distribuire ambiente Python e dipendenze bloccate.
5. Distribuire scheduler e placeholder.
6. Configurare DSN, timezone, percorso log e timeout.
7. Installare la regola di rotazione mensile.
8. Eseguire test del calendario, incluso il cambio mese e anno.
9. Inserire configurazioni inizialmente disabilitate.
10. Abilitare una sola configurazione dopo lo smoke test.

### Rollback

- Disabilitare lo scheduler esterno.
- Ripristinare la versione precedente del codice.
- Mantenere tabelle e audit per non perdere evidenze.
- Rimuovere trigger e funzione solo se richiesto dal rollback database.
- Non eliminare le tabelle senza backup e autorizzazione esplicita.

## 14. Rischi e decisioni aperte

- Timezone applicativa non ancora confermata.
- Versione Python non ancora confermata.
- Numero di mesi di retention dei log non ancora definito.
- Scheduler di sistema non indicato.
- La runtime DWH evita il doppio carico, ma un advisory lock PostgreSQL renderebbe atomica anche la selezione dello scheduler.
- Gli stati `RUNNING` rimasti dopo crash richiedono una regola di riconciliazione.
- La modifica retroattiva della configurazione durante uno slittamento richiede versionamento o snapshot dei parametri nell'audit.
- La regola sulla quinta settimana può spostare molto in avanti l'esecuzione; è una conseguenza del requisito e va validata con esempi di business.

## 15. Esito della revisione

La precedente regola “occorrenza inesistente uguale nessuna esecuzione” è eliminata. La progettazione ora prevede lo slittamento allo stesso giorno ISO della settimana successiva, anche oltre il mese o l'anno, e distingue il periodo logico dalla data fisica mediante `last_success_period_start`.

La rotazione del log è stata modificata da giornaliera a mensile.
