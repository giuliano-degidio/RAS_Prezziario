# Schedulazione configurabile del caricamento DWH

## Scopo e perimetro

Questo pacchetto prepara l'esecuzione giornaliera del ciclo NiFi che carica le
frontiere e avvia il refresh DWH. La schedulazione è conservata in PostgreSQL,
mentre un timer `systemd` avvia ogni giorno un batch Python. Il batch non
esegue il flusso se il calendario configurato non lo richiede.

Gli artefatti sono separati per ambiente:

- `deploy/postgresql/`: DDL e query di verifica per PostgreSQL 17;
- `deploy/unix-linux/`: batch Python, unità `systemd`, configurazione,
  installazione, rotazione log e test unitari;
- `doc/`: progettazione e istruzioni operative.

Le strutture PostgreSQL e le otto righe di schedulazione sono state applicate
dall'utente e verificate in sola lettura il 2026-10-29. L'audit contiene inoltre
un run manuale concluso con successo. L'utente riferisce di aver applicato i
componenti Linux e NiFi; lo stato del timer systemd e la configurazione live del
flow non sono stati interrogati direttamente. Nessuna modifica è stata eseguita
su DB, Linux o NiFi durante questa verifica.

## Decisioni operative

| Voce | Decisione |
|---|---|
| Database | PostgreSQL 17, database applicativo `hcbi` |
| Schema | `hcbi_utility`; non viene creato né usato lo schema `ctl` |
| Servizio | `systemd` giornaliero alle 03:00, timezone `Europe/Rome` |
| Identità Linux | utente e gruppo `nifi` |
| Python | virtualenv FMR esistente `/opt/etl/frontiere-metadata-runner/.venv` |
| Lock batch | advisory lock PostgreSQL di sessione, mantenuto durante tutto il ciclo |
| Giorno non dovuto | run `SKIPPED` con motivazione nel DB e nel log applicativo |
| Log applicativo | `/opt/etl/log/dwh-scheduler/dwh-scheduler.log`, rotazione mensile |

## Modello dati

`hcbi_utility.dwh_schedule` contiene la configurazione corrente e lo stato
sintetico; `hcbi_utility.dwh_schedule_run` conserva una riga per ogni tentativo,
inclusi i giorni `SKIPPED`. `trigger_source` distingue `SCHEDULED` da `MANUAL_UI`;
`requested_by` riporta il canale `NiFi-UI` e non l'identità personale. Il DDL
include vincoli per le otto frequenze, validazione dei parametri, indice che
ammette una sola configurazione attiva e grant al ruolo applicativo `hcbi_ras`.

Frequenze ammesse: `ANNUAL`, `SEMIANNUAL`, `FOUR_MONTHLY`, `QUARTERLY`,
`BIMONTHLY`, `MONTHLY`, `WEEKLY` e `DAILY`. I giorni ISO sono 1=lunedì fino a
7=domenica. Per le frequenze periodiche, la data è calcolata secondo la
settimana ISO del mese; se il giorno richiesto cade fuori dal mese, slitta alla
settimana successiva. Il retry è inclusivo e non oltrepassa la data pianificata
del ciclo seguente. `last_success_period_start` identifica il periodo logico,
anche quando la data fisica è slittata.

Il DDL di creazione non inserisce righe di configurazione. Nel database live,
verificato il 2026-10-29, risultano otto codici distinti:
`DWH_REFRESH_DAILY`, `DWH_REFRESH_WEEKLY`, `DWH_REFRESH_MONTHLY`,
`DWH_REFRESH_BIMONTHLY`, `DWH_REFRESH_QUARTERLY`, `DWH_REFRESH_FOUR_MONTHLY`,
`DWH_REFRESH_SEMIANNUAL` e `DWH_REFRESH_ANNUAL`. È abilitato `DWH_REFRESH_WEEKLY`; gli altri sette sono disabilitati.
`last_success_period_start` è `2026-10-26`. Gli ultimi run `MANUAL_UI`, alle
13:48 e 13:54 UTC, sono entrambi `SUCCESS`; il secondo non aveva un periodo
candidato. Nell'audit letto in sola lettura non compaiono run `SCHEDULED`, ma lo
stato live del timer non è stato interrogato. In un giorno non
dovuto il batch registra `SKIPPED` nel DB e nel log. Se manca una configurazione
abilitata o il DB non è raggiungibile, l'errore resta nel log; non è possibile
scrivere una riga di audit in assenza di una connessione/configurazione valida.

## Flusso di esecuzione

1. `dwh-scheduler.timer` avvia `dwh-scheduler.service` alle 03:00 Europe/Rome.
2. Il batch carica le credenziali cifrate FMR, apre una connessione dedicata e
   acquisisce un advisory lock PostgreSQL globale.
3. Riconcilia eventuali run `RUNNING` rimasti da un arresto precedente,
   legge la configurazione e valuta la data locale.
4. Se non è dovuto, registra `SKIPPED` e termina. Se è dovuto, registra
   `RUNNING` e avvia `bin/run_group_cycle.sh`.
5. Il wrapper avvia il Process Group NiFi `FRONTIERE_METADATA_RUNNER`, attende
   la fine delle frontiere e del refresh DWH chain 1, quindi ferma il gruppo.
6. Il batch aggiorna il run a `SUCCESS` o `FAILED` e rilascia il lock quando
   chiude la connessione.

Il lock serializza le istanze automatiche e manuali. Un run pianificato attende
fino a due ore il rilascio del lock; una richiesta manuale concorrente viene
registrata `SKIPPED` e non attende. Il lock applicativo non sostituisce i lock
interni ai carichi.

## Avvio manuale dalla UI NiFi

Il Process Group `FRONTIERE_METADATA_RUNNER` rimane visibile. Nel flow business,
l'output di `Run sequential full refresh` passa attraverso un gate `ExtractText`:
il DWH riceve il FlowFile soltanto se stdout contiene il marker valido
`FMR_EXECUTION_UUID=<uuid>`, emesso dopo il successo di tutte le frontiere. Log o
output senza marker non raggiungono il refresh DWH. Il `GenerateFlowFile`
esistente resta il trigger tecnico che il wrapper FMR usa per avviare un ciclo;
non deve essere avviato direttamente dagli operatori, perché se lasciato attivo
può riemettere il FlowFile il giorno successivo.

Il pacchetto aggiunge il Process Group indipendente `DWH_MANUAL_LAUNCH`. Un
operatore autorizzato lo avvia dalla UI per inviare una richiesta one-shot. Il
gruppo esegue `ExecuteStreamCommand`, che avvia in background lo stesso runner
Python usato da systemd con modalità `manual-ui`. Il runner ferma il gruppo
launcher, acquisisce lo stesso advisory lock, registra `MANUAL_UI` in audit e
invoca il wrapper FMR standard, che avvia e ferma `FRONTIERE_METADATA_RUNNER`.
Non viene usato un Input Port né viene avviato direttamente il gruppo business.

Il runner manuale richiede una configurazione abilitata ma forza
l'esecuzione: ignora il calendario anche se il periodo corrente è già stato
completato con successo. Ogni nuovo avvio manuale riesegue frontiere e DWH. Se
non c'è un periodo dovuto, i campi del periodo restano nulli nell'audit e il run
non modifica `last_success_period_start`. Solo il modo `scheduled` del timer
registra `SKIPPED` e non avvia il flow quando il periodo è già completato. `requested_by` indica `NiFi-UI`, non l'identità personale
dell'operatore: l'identità va ricostruita dai log/autorizzazioni NiFi.

Il gruppo launcher torna rapidamente `STOPPED`; questo non significa che il
refresh sia terminato, perché l'orchestratore prosegue in background. Per
verificare l'esito usare `dwh_schedule_run` e i log dello scheduler. Se il
runner non riesce a caricare la configurazione o a fermare il launcher, fermarlo
dalla UI e controllare il log prima di riprovare. Agli operatori concedere il
permesso di avvio/stop su `DWH_MANUAL_LAUNCH`, ma non quello di avvio diretto su
`FRONTIERE_METADATA_RUNNER`.

## Rischi e decisioni da confermare in esercizio

- Confermare la riga di schedulazione effettiva (frequenza, calendario e retry)
  prima di abilitare il timer.
- Verificare che il virtualenv contenga le dipendenze già usate da FMR (`psycopg`
  e `cryptography`) e che `nifi` possa leggere i file segreti cifrati.
- Un arresto forzato può lasciare il Process Group NiFi attivo anche se il
  servizio scheduler è terminato. Prima di un nuovo tentativo, controllare e
  fermare il gruppo se necessario; il run `RUNNING` sarà riconciliato come
  `FAILED` al successivo avvio dello scheduler.
- La retention configurata per il log file è 12 mesi. Non è impostata una
  retention automatica per `dwh_schedule_run`; definirla prima che il volume
  di audit diventi significativo.
- Non viene registrato uno snapshot della configurazione usata da ogni run;
  modifiche alla configurazione possono quindi limitare la ricostruzione
  storica dei parametri.
