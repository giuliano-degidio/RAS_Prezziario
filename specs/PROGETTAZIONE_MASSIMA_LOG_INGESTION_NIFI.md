# Progettazione di massima — Ingestione dei log NiFi in `hcbi_utility`

## 1. Obiettivo e vincolo principale

Progettare un'estensione che archivi in PostgreSQL gli eventi prodotti dai tre file di log del ciclo NiFi, senza modificare il comportamento funzionale già esistente. L'estensione opera dopo la conclusione del ciclo e ha un proprio audit tecnico.

## 2. Sorgenti

| Codice sorgente | Percorso | Caratteristiche osservate |
|---|---|---|
| `DWH_SCHEDULER` | `/opt/etl/log/dwh-scheduler/dwh-scheduler.log` | eventi scheduler, output del runner, heartbeat, run scheduler e righe anche senza `execution_uuid` |
| `DWH_REFRESH` | `/opt/etl/log/frontiere-metadata-runner/dwh-refresh.log` | avvio/esito DWH, `execution_uuid`, `chain_id`, traceback multilinea |
| `FRONTIERE_RUNNER` | `/opt/etl/log/frontiere-metadata-runner/frontiere-metadata-runner.log` | avvio, configurazioni, esiti frontiere, riepilogo e traceback multilinea |

I percorsi sono configurati mediante allowlist statica. Il componente non accetta percorsi arbitrari dal FlowFile o dalla riga di comando.

## 3. Grain

**Una riga di `hcbi_utility.etl_execution_log_event` rappresenta un evento logico proveniente da uno specifico segmento di file; un evento può comprendere più righe fisiche quando si tratta di traceback o testo di continuazione.**

La tabella di audit ha invece grain distinto:

**Una riga di `hcbi_utility.etl_execution_log_ingestion` rappresenta un tentativo di acquisizione di un intervallo di byte di un singolo file sorgente.**

## 4. Architettura logica

```text
Ciclo esistente
  |
  +--> frontiere-metadata-runner.log
  +--> dwh-refresh.log
  +--> dwh-scheduler.log
  |
  +--> esito del ciclo già determinato
          |
          v
     manifest di ingestione
     (file, inode, offset iniziale/finale,
      execution_uuid noto, scheduler_run_id noto)
          |
          v
     load_execution_logs.py
          |
          +--> validazione allowlist
          +--> snapshot e controllo rotazione
          +--> lettura intervallo
          +--> parser multilinea
          +--> estrazione metadati
          +--> classificazione correlazione
          +--> hash e deduplicazione
          +--> insert batch
          +--> audit e riconciliazione
          |
          v
     hcbi_utility.etl_execution_log_ingestion
     hcbi_utility.etl_execution_log_event
```

## 5. Scelta del punto di integrazione

### Soluzione raccomandata

Integrare l'invocazione nel livello esterno del ciclo, dopo la determinazione dell'exit code corrente e prima della chiusura definitiva del run scheduler, oppure in un passo immediatamente successivo che riceva un manifest già chiuso.

Motivazioni:

- il livello esterno osserva tutti e tre i file;
- può catturare gli offset prima e dopo il ciclo;
- può archiviare anche i fallimenti avvenuti prima del refresh DWH;
- non richiede scritture aggiuntive nel codice di frontiere o DWH;
- mantiene separati esito business ed esito dell'archiviazione.

### Vincolo di non regressione

L'exit code originale viene salvato prima di invocare l'archiviatore. L'archiviatore restituisce un proprio exit code e aggiorna il proprio audit, ma non sostituisce l'exit code del ciclo. Un eventuale alert tecnico è separato.

## 6. Manifest di ingestione

Formato logico proposto:

```json
{
  "cycle_result": "SUCCESS|FAILED|SKIPPED",
  "execution_uuid": "uuid-or-null",
  "scheduler_run_id": "uuid-or-null",
  "files": [
    {
      "source_code": "DWH_SCHEDULER",
      "path": "/opt/etl/log/dwh-scheduler/dwh-scheduler.log",
      "device": 0,
      "inode": 0,
      "offset_start": 0,
      "offset_end": 0,
      "size_at_close": 0,
      "modified_at": "timestamp"
    }
  ]
}
```

I numeri sono valorizzati a runtime. Il manifest non contiene credenziali.

Se il file cambia device/inode tra inizio e fine, l'acquisizione viene marcata `ROTATED`; il componente acquisisce i segmenti solo quando entrambi sono identificabili in modo certo. In caso contrario registra l'anomalia senza leggere contenuto potenzialmente estraneo.

## 7. Parsing

### 7.1 Intestazione evento

Pattern di massima:

```regex
^(?<ts>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\s+(?<level>[A-Z]+)\s+(?<message>.*)$
```

Una riga che rispetta il pattern apre un nuovo evento. Le righe successive prive di intestazione vengono concatenate a `message_text` fino alla successiva intestazione o alla fine dell'intervallo.

### 7.2 Campi estratti

Estrarre solo quando esplicitamente presenti:

- `execution_uuid`;
- `scheduler_run_id`, da messaggi del tipo `Run <uuid>`;
- `chain_id`;
- `process_name` o nome frontiera, quando riconosciuto da pattern versionati;
- `cycle_exit_code`;
- livello e timestamp.

Il testo integrale dell'evento resta in `message_text`. Il parser non ricostruisce valori mancanti per prossimità temporale.

### 7.3 Correlazione

Valori proposti di `correlation_status`:

- `CORRELATED`: UUID presente nell'evento oppure fornito dal manifest in un segmento univocamente delimitato;
- `UNCORRELATED`: evento valido ma senza identificativo associabile in modo deterministico;
- `AMBIGUOUS`: sono presenti segnali tra loro discordanti;
- `NOT_APPLICABLE`: evento scheduler non riferito a un ciclo, per esempio una schedulazione non dovuta.

Regola prudenziale: in caso di discordanza tra UUID nel testo e UUID del manifest, conservare entrambi, usare quello nel testo come `event_execution_uuid`, valorizzare `manifest_execution_uuid` separatamente e impostare `AMBIGUOUS`.

## 8. Modello dati preliminare

### 8.1 Audit ingestione

```sql
CREATE TABLE hcbi_utility.etl_execution_log_ingestion (
    ingestion_id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_code            varchar(50) NOT NULL,
    source_path            text NOT NULL,
    source_device          bigint NULL,
    source_inode           bigint NULL,
    offset_start           bigint NOT NULL,
    offset_end             bigint NOT NULL,
    manifest_execution_uuid uuid NULL,
    scheduler_run_id       uuid NULL,
    cycle_result           varchar(20) NULL,
    started_at             timestamptz NOT NULL DEFAULT clock_timestamp(),
    finished_at            timestamptz NULL,
    status                 varchar(30) NOT NULL,
    events_read            bigint NOT NULL DEFAULT 0,
    events_inserted        bigint NOT NULL DEFAULT 0,
    events_duplicate       bigint NOT NULL DEFAULT 0,
    events_rejected        bigint NOT NULL DEFAULT 0,
    bytes_read             bigint NOT NULL DEFAULT 0,
    error_code             varchar(50) NULL,
    error_message          text NULL,
    retry_of_ingestion_id  bigint NULL,
    CONSTRAINT ck_log_ingestion_offsets
        CHECK (offset_start >= 0 AND offset_end >= offset_start),
    CONSTRAINT ck_log_ingestion_counts
        CHECK (events_read = events_inserted + events_duplicate + events_rejected),
    CONSTRAINT fk_log_ingestion_retry
        FOREIGN KEY (retry_of_ingestion_id)
        REFERENCES hcbi_utility.etl_execution_log_ingestion (ingestion_id)
);
```

Stati proposti:

- `RUNNING`
- `SUCCEEDED`
- `SUCCEEDED_WITH_REJECTS`
- `FAILED`
- `ROTATED`
- `SKIPPED`

### 8.2 Eventi

```sql
CREATE TABLE hcbi_utility.etl_execution_log_event (
    event_id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingestion_id             bigint NOT NULL,
    source_code              varchar(50) NOT NULL,
    source_path              text NOT NULL,
    source_device            bigint NULL,
    source_inode             bigint NULL,
    byte_offset_start        bigint NOT NULL,
    byte_offset_end          bigint NOT NULL,
    source_line_start        bigint NULL,
    source_line_end          bigint NULL,
    event_timestamp          timestamptz NULL,
    log_level                varchar(20) NULL,
    event_execution_uuid     uuid NULL,
    manifest_execution_uuid  uuid NULL,
    scheduler_run_id         uuid NULL,
    chain_id                 bigint NULL,
    process_name             varchar(255) NULL,
    correlation_status       varchar(30) NOT NULL,
    parse_status             varchar(30) NOT NULL,
    message_text             text NOT NULL,
    event_hash               char(64) NOT NULL,
    ingested_at              timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT fk_log_event_ingestion
        FOREIGN KEY (ingestion_id)
        REFERENCES hcbi_utility.etl_execution_log_ingestion (ingestion_id),
    CONSTRAINT ck_log_event_offsets
        CHECK (byte_offset_start >= 0 AND byte_offset_end >= byte_offset_start),
    CONSTRAINT uq_log_event_identity
        UNIQUE (source_code, source_device, source_inode,
                byte_offset_start, byte_offset_end, event_hash)
);
```

Il DDL è preliminare: owner, tablespace, naming definitivo, policy di retention e dimensionamenti devono essere allineati alle convenzioni reali del repository.

### 8.3 Indici iniziali

Solo gli indici giustificati dai casi operativi:

```sql
CREATE INDEX ix_log_event_execution_uuid
    ON hcbi_utility.etl_execution_log_event (event_execution_uuid, event_timestamp);

CREATE INDEX ix_log_event_ingested_at
    ON hcbi_utility.etl_execution_log_event (ingested_at);

CREATE INDEX ix_log_ingestion_status
    ON hcbi_utility.etl_execution_log_ingestion (status, started_at);
```

Ulteriori indici e partizionamento richiedono evidenze su volume e query.

## 9. Identità e idempotenza

`event_hash` è SHA-256 della rappresentazione canonica:

```text
source_code
source_device
source_inode
byte_offset_start
byte_offset_end
message_text normalizzato solo per newline
```

Non rimuovere spazi dal messaggio e non cambiare maiuscole/minuscole. La posizione nel segmento distingue messaggi testualmente uguali ma realmente ripetuti.

In caso di replay dello stesso segmento, il vincolo univoco classifica l'evento come duplicato. Se il file viene copiato e cambia inode, la modalità di backfill deve aggiungere un `source_fingerprint` del file per evitare duplicazioni tra copia e originale; questa modalità va implementata e testata separatamente.

## 10. Transazioni e concorrenza

- creare l'audit `RUNNING` in una transazione breve;
- processare eventi in batch configurabili;
- usare `INSERT ... ON CONFLICT DO NOTHING` per la deduplicazione;
- aggiornare i contatori dopo ogni batch in modo coerente;
- chiudere l'audit solo dopo la riconciliazione;
- impedire due acquisizioni concorrenti dello stesso segmento mediante advisory lock calcolato sull'identità del segmento o vincolo equivalente;
- non mantenere lock sul file o sul DB per la durata dell'intero ciclo business.

## 11. Sicurezza

- utente OS del servizio con sola lettura dei tre file;
- utenza DB con `USAGE` sullo schema e `SELECT/INSERT/UPDATE` solo sulle nuove tabelle e sequenze;
- nessun `DELETE`, `TRUNCATE` o DDL al runtime;
- credenziali recuperate con il meccanismo cifrato già in uso;
- rifiuto di path traversal e symlink non autorizzati;
- limiti configurabili su byte ed eventi;
- messaggi di errore dell'archiviatore privi di credenziali;
- campionamento iniziale per definire eventuale redazione di password, token e connection string;
- accesso in lettura alle tabelle limitato ai ruoli operativi autorizzati.

## 12. Gestione errori

Exit code proposti per il nuovo componente:

- `0`: completato;
- `2`: completato con record scartati;
- `3`: sorgente assente;
- `4`: parsing o encoding non gestibile;
- `5`: errore DB;
- `6`: manifest/configurazione non valida;
- `7`: permesso filesystem negato;
- `8`: rotazione non risolvibile;
- `9`: acquisizione concorrente già attiva.

Questi codici sono esclusivi dell'archiviatore e non sostituiscono quelli del ciclo esistente.

## 13. Recovery e backfill

### Retry ordinario

- selezionare audit `FAILED` o `ROTATED` risolto;
- creare un nuovo tentativo con `retry_of_ingestion_id`;
- riusare lo stesso segmento;
- lasciare al vincolo univoco la deduplicazione.

### Audit `RUNNING` obsoleto

Non convertirlo automaticamente in `FAILED` senza una soglia operativa approvata. Fornire un comando amministrativo che verifichi assenza di processo attivo e chiuda il tentativo con motivazione.

### Backfill storico

Il backfill deve essere esplicito, per file/intervallo, con dry-run e report. Gli eventi storici privi di UUID restano `UNCORRELATED`; non usare la sola vicinanza temporale per forzare legami.

## 14. Test di accettazione

### T01 — Successo completo

Input: segmenti contenenti frontiere e DWH conclusi con successo.  
Atteso: eventi inseriti, UUID coerente, audit `SUCCEEDED`, riconciliazione valida.

### T02 — Fallimento frontiera

Input: evento `ERROR` seguito da traceback.  
Atteso: un evento logico multilinea, testo completo, esito di ingestione indipendente dal fallimento business.

### T03 — Fallimento DWH

Input: errore DWH con traceback SQL/PLpgSQL.  
Atteso: evento multilinea conservato e correlato all'UUID esplicito.

### T04 — Scheduler senza UUID

Input: messaggio di schedulazione non dovuta.  
Atteso: evento persistito con UUID nullo e `NOT_APPLICABLE` o `UNCORRELATED` secondo la regola puntuale.

### T05 — Discordanza UUID

Input: UUID nel testo diverso da quello del manifest.  
Atteso: entrambi conservati, stato `AMBIGUOUS`, nessuna sovrascrittura.

### T06 — Replay

Input: stesso manifest eseguito due volte.  
Atteso: seconda esecuzione senza nuovi eventi; contatore duplicati valorizzato.

### T07 — Crash parziale

Input: interruzione dopo un batch.  
Atteso: retry senza duplicati e audit del tentativo precedente preservato.

### T08 — Rotazione

Input: inode diverso tra apertura e chiusura.  
Atteso: acquisizione solo se i segmenti sono identificabili; altrimenti stato `ROTATED` senza letture arbitrarie.

### T09 — File non leggibile

Input: permesso negato.  
Atteso: audit `FAILED`, exit code dedicato, esito business invariato.

### T10 — Concorrenza

Input: due acquisizioni dello stesso segmento.  
Atteso: una sola attiva o deduplicazione completa, senza contatori incoerenti.

### T11 — Regressione

Input: stessi casi con archiviatore disabilitato e abilitato.  
Atteso: stessi esiti, exit code e dati business del ciclo corrente.

## 15. Deployment

Prerequisiti:

- accesso ai tre file da parte dell'utente di servizio;
- connettività e grant DB;
- directory/configurazione dello script;
- backup o restore point;
- campioni e baseline di regressione.

Ordine:

1. DDL tabelle e indici;
2. grant;
3. deploy script e configurazione;
4. dry-run;
5. test manuale su segmento chiuso;
6. integrazione additiva;
7. smoke test;
8. riconciliazione;
9. attivazione operativa.

Rollback:

1. disabilitare il nuovo passo;
2. ripristinare runner/flow precedente;
3. non cancellare tabelle o storico;
4. analizzare i tentativi incompleti;
5. rimuovere gli oggetti solo tramite change separato.

## 16. Monitoraggio operativo

Query/controlli da predisporre:

- ingestione fallita per sorgente;
- audit `RUNNING` non concluso;
- eventi `AMBIGUOUS`;
- eventi non correlati;
- differenza tra letti, inseriti, duplicati e scartati;
- byte acquisiti per esecuzione;
- tempi di ingestione;
- crescita per sorgente e giorno;
- segmenti riprocessati;
- errori di rotazione o permesso.

Le soglie di allarme e la retention restano da definire dopo la raccolta delle metriche reali.

## 17. Casi particolari da discutere prima dell'implementazione esecutiva

1. rotazione effettiva dei tre file e disponibilità dei file ruotati;
2. eventuali esecuzioni concorrenti sullo stesso file;
3. ownership e convenzioni DDL del repository;
4. retention richiesta nel DB e sul filesystem;
5. presenza di segreti o dati personali nei log completi;
6. comportamento del runner quando un ciclo non produce un `execution_uuid` affidabile;
7. necessità di backfill dello storico già presente.

Questi punti non bloccano la progettazione di massima, ma vanno chiusi prima di dichiarare il componente pronto alla produzione.
