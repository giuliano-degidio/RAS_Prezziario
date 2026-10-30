# FRONTIERE METADATA RUNNER v0.4

## 1. Scopo

Il progetto realizza, tramite Apache NiFi 2.11 e script Python, una catena ETL composta da due fasi sequenziali:

1. caricamento full refresh delle tabelle di frontiera già esistenti in `hcbi_ras`;
2. avvio della procedura di refresh del DWH:

```sql
CALL hcbi_utility.prc_execute_chain(1);
```

Il parametro della procedura è fisso a `1`.

Il progetto legge le configurazioni attive da `hcbi_utility.etl_frontiere_config`, esegue i flussi in ordine e registra gli esiti negli oggetti di log dello schema `hcbi_utility`.

---

## 2. Architettura del flusso

```text
Manual trigger
    |
    v
Run sequential full refresh
    |
    | output stream
    v
Gate DWH on frontiere success marker (ExtractText)
    |
    | matched: FMR_EXECUTION_UUID valido
    v
Run DWH refresh chain 1
    |
    +-- output stream --> Log DWH refresh completed
    |
    +-- nonzero status --> Log DWH refresh failed

Run sequential full refresh
    |
    +-- nonzero status --> Log frontiere failed

Gate DWH on frontiere success marker
    |
    +-- unmatched / failure --> Terminate (DWH non avviato)
```

Il runner emette `FMR_EXECUTION_UUID=<uuid>` su stdout soltanto dopo il completamento corretto di tutte le frontiere. I log applicativi vanno su stderr e nel file di log. Il gate NiFi inoltra al refresh DWH solo il contenuto che contiene un marker UUID valido; senza marker, il ramo viene terminato e il DWH non parte.

Entrambi i processor `ExecuteStreamCommand` hanno la relationship:

```text
original -> Terminate = true
```

Questo evita che i processor risultino invalidi per relationship non gestite.
Anche `unmatched` e `failure` del gate sono auto-terminate.

---

## 3. Funzionamento del caricamento frontiere

Per ogni configurazione attiva letta da `hcbi_utility.etl_frontiere_config`, il runner:

1. apre un record in `hcbi_utility.etl_frontiere_run`;
2. acquisisce il lock applicativo in `hcbi_utility.etl_frontiere_execution_lock`;
3. esegue `source_query` sul database RASOP;
4. esegue `TRUNCATE` della tabella target in `hcbi_ras`;
5. inserisce i record estratti;
6. registra conteggi, esito, warning ed eventuale errore;
7. rilascia il lock della frontiera.

Le configurazioni vengono elaborate in ordine:

```sql
ORDER BY execution_order, frontiera_code
```

La query di configurazione è:

```sql
SELECT
    frontiera_code,
    description,
    execution_order,
    source_service_code,
    source_query,
    target_schema,
    target_table,
    truncate_before_load
FROM hcbi_utility.etl_frontiere_config
WHERE enabled = true
ORDER BY execution_order, frontiera_code;
```

### Regole applicate

- `source_service_code` deve essere `RASOP`;
- `target_schema` deve essere `hcbi_ras`;
- `truncate_before_load` deve essere `true`;
- `target_table` deve rispettare il naming PostgreSQL previsto;
- `source_query` deve iniziare con `SELECT` o `WITH`;
- `source_query` deve contenere una sola istruzione;
- i nomi delle colonne restituite dalla sorgente devono essere univoci e compatibili con il target.

Le tabelle `hcbi_ras.frontiera_*` sono già esistenti. Il progetto non contiene DDL per crearle.

---

## 4. Semantica transazionale delle frontiere

Ogni frontiera usa una transazione HCBI separata:

```text
BEGIN implicito
TRUNCATE hcbi_ras.<target>
INSERT in batch
COMMIT
```

In caso di errore nella scrittura, la connessione dati viene chiusa senza commit e PostgreSQL annulla la transazione, incluso il `TRUNCATE`.

Il logging e i lock sono gestiti tramite una connessione HCBI separata con `autocommit=True`, per conservare l'esito del run anche quando la transazione dati fallisce.

Il batch iniziale del runner è:

```text
1000 righe
```

Il valore deve essere verificato con test nell'ambiente target prima di eventuali ottimizzazioni.

---

## 5. Gestione zero righe

Se una query sorgente restituisce zero righe, il caricamento è considerato riuscito con warning:

```text
status          = SUCCEEDED
rows_read       = 0
rows_written    = 0
warning_message = La query sorgente ha restituito zero righe
error_message   = NULL
```

Il warning viene scritto anche nel log filesystem.

---

## 6. Funzionamento del refresh DWH

Lo script:

```text
/opt/etl/frontiere-metadata-runner/scripts/run_dwh_refresh.py
```

riceve tramite standard input il contenuto stdout del runner, inoltrato dal gate NiFi solo se il marker è valido:

```text
FMR_EXECUTION_UUID=<uuid>
```

Dopo aver validato l'UUID:

1. si connette al database `hcbi` usando le credenziali cifrate;
2. inserisce un record `RUNNING` in `hcbi_utility.etl_dwh_refresh_run`;
3. acquisisce un advisory lock dedicato alla chain `1`;
4. esegue:

```sql
CALL hcbi_utility.prc_execute_chain(1);
```

5. aggiorna il log a `SUCCEEDED`, `FAILED` oppure `SKIPPED`.

### Gestione transazionale del refresh DWH

La connessione usa:

```python
autocommit=True
```

Lo script non esegue esplicitamente:

```text
COMMIT
ROLLBACK
```

La procedura `hcbi_utility.prc_execute_chain(1)` gestisce autonomamente le proprie transazioni.

---

## 7. Execution UUID

A ogni ciclo completo viene assegnato un UUID generato da `run_frontiere.py`.

Lo stesso UUID viene utilizzato per correlare l'intera esecuzione ETL attraverso:

```text
hcbi_utility.etl_frontiere_run.nifi_flowfile_uuid
hcbi_utility.etl_dwh_refresh_run.execution_uuid
hcbi_utility.log_chain.etl_execution_uuid
```

Il nome `nifi_flowfile_uuid` viene mantenuto per compatibilità con la tabella esistente, ma il valore rappresenta l'UUID dell'esecuzione complessiva generato dal runner.

Durante l'esecuzione di `hcbi_utility.prc_execute_chain(1)`, l'UUID viene recuperato tramite la funzione:

```sql
hcbi_utility.get_current_etl_execution_uuid()
```

La funzione individua l'ultima esecuzione presente in `hcbi_utility.etl_dwh_refresh_run` con:

- `status = 'RUNNING'`;
- `ended_at IS NULL`;
- valore massimo di `run_id`.

L'`execution_uuid` individuato viene registrato in `hcbi_utility.log_chain.etl_execution_uuid`.

In questo modo lo stesso UUID correla il caricamento delle frontiere, l'esecuzione del refresh DWH e il log interno della chain.

La funzione è non bloccante. Se non individua un UUID valido oppure si verifica un errore durante il recupero, restituisce lo UUID zero:

```text
00000000-0000-0000-0000-000000000000
```

Non viene più utilizzata la property NiFi:

```text
FMR_FLOWFILE_UUID=${uuid}
```

---

## 8. Logging database

### 8.1 Caricamenti frontiere

Tabella:

```text
hcbi_utility.etl_frontiere_run
```

Campi utilizzati:

```text
run_id
frontiera_code
started_at
ended_at
status
rows_read
rows_written
error_message
warning_message
nifi_flowfile_uuid
```

Stati:

```text
RUNNING
SUCCEEDED
FAILED
SKIPPED
```

### 8.2 Refresh DWH

Tabella:

```text
hcbi_utility.etl_dwh_refresh_run
```

Campi:

```text
run_id
execution_uuid
chain_id
started_at
ended_at
status
error_message
```

Stati:

```text
RUNNING
SUCCEEDED
FAILED
SKIPPED
```

DDL incluso nel pacchetto:

```text
sql/01_create_hcbi_utility_etl_dwh_refresh_run.sql
```

Il DDL assegna owner `hcbi_utility` e grant esplicite ai ruoli:

```text
hcbi_utility
hcbi_ras
```

---

## 9. Logging filesystem

Directory:

```text
/opt/etl/log/frontiere-metadata-runner/
```

File:

```text
frontiere-metadata-runner.log
dwh-refresh.log
```

Rotazione applicativa per ciascun file:

```text
dimensione massima: 20 MB
backup: 10
```

Il progetto non deve scrivere nei log:

- password;
- chiave Fernet;
- token NiFi;
- contenuto decifrato del file dei segreti.

### 9.1 Riversamento in `hcbi_utility`

Il runner scheduler può acquisire, a fine ciclo, i soli byte aggiunti ai tre log
FMR/scheduler. L'integrazione è nel runner esterno, non nei processor NiFi; è
best effort e non modifica il risultato o l'exit code del ciclo. È disabilitata
per default con `FMR_LOG_INGESTION_ENABLED=false`.

Le sorgenti allowlist sono `dwh-scheduler.log`, `dwh-refresh.log` e
`frontiere-metadata-runner.log`. Il runner delimita gli offset mentre detiene il
lock globale; device/inode, dimensione e fingerprint proteggono da rotazione e
troncamento. Gli eventi multilinea vengono conservati come un unico messaggio,
con offset byte e stato di correlazione esplicito. Un vincolo univoco impedisce
duplicati; gli errori d'ingestione sono registrati separatamente.

Il modello è composto da `hcbi_utility.etl_execution_log_ingestion` (audit) e
`hcbi_utility.etl_execution_log_event` (eventi). Applicare prima
`ddl/hcbi_utility/table/etl_execution_log_ingestion.sql`, poi
`ddl/hcbi_utility/table/etl_execution_log_event.sql`. Le verifiche sono in
`sql/03_verify_log_ingestion.sql`. Lo script Python è
`scripts/load_execution_logs.py`; i test locali sono in
`tests/test_load_execution_logs.py`.

Per configurazione, rollout, limiti, recupero e rollback consultare
`doc/design/LOG_INGESTION_HIGH_LEVEL_DESIGN.md` e
`doc/operations/RUNBOOK_LOG_INGESTION_NIFI.md`. Non abilitare l'opzione prima
dell'applicazione dei DDL e della verifica dei grant.

---

## 10. Lock e concorrenza

### 10.1 Lock globale delle frontiere

Il runner usa un advisory lock PostgreSQL globale per impedire due esecuzioni complete contemporanee.

### 10.2 Lock della singola frontiera

La tabella:

```text
hcbi_utility.etl_frontiere_execution_lock
```

contiene soltanto i lock delle frontiere attualmente in esecuzione.

Dopo una conclusione normale deve risultare vuota.

### 10.3 Lock del refresh DWH

Il refresh DWH usa un advisory lock PostgreSQL dedicato alla chain `1`.

Il lock è associato alla sessione e viene rilasciato automaticamente alla chiusura della connessione.

Se il lock non viene acquisito, il run DWH viene registrato come `SKIPPED` e il processor termina con exit code non-zero.

### 10.4 Arresto anomalo

Un arresto del server durante una frontiera può lasciare:

```text
etl_frontiere_run.status = RUNNING
etl_frontiere_execution_lock = riga residua
```

Prima di rimuovere un lock residuo verificare sempre che non esista un processo attivo:

```bash
ps -ef | grep '[r]un_frontiere.py'
ps -ef | grep '[r]un_dwh_refresh.py'
```

---

## 11. Struttura filesystem

```text
/opt/etl/
├── config/
│   └── fmr-secrets.json.enc
├── secrets/
│   └── fmr-secrets.key
├── log/
│   └── frontiere-metadata-runner/
│       ├── frontiere-metadata-runner.log
│       └── dwh-refresh.log
└── frontiere-metadata-runner/
    ├── .venv/
    ├── README.md
    ├── requirements.txt
    ├── bin/
    │   └── install_layout.sh
    ├── config/
    │   └── fmr-secrets.template.json
    ├── scripts/
    │   ├── load_execution_logs.py
    │   ├── deploy_nifi_flow.py
    │   ├── encrypt_fmr_secrets.py
    │   ├── run_frontiere.py
    │   ├── run_dwh_refresh.py
    │   ├── secrets_common.py
    │   └── validate_fmr_secrets.py
    └── sql/
        ├── 01_create_hcbi_utility_etl_dwh_refresh_run.sql
        ├── 02_verify_runtime.sql
        └── 03_verify_log_ingestion.sql
```

Permessi proposti:

```text
/opt/etl/secrets                         0700
/opt/etl/secrets/fmr-secrets.key         0600
/opt/etl/config                          0700
/opt/etl/config/fmr-secrets.json.enc     0600
/opt/etl/log                             0750
/opt/etl/log/frontiere-metadata-runner   0750
```

L'owner deve essere l'utenza che esegue NiFi e gli script, negli esempi `nifi:nifi`.

### Permessi di esecuzione per NiFi

`ExecuteStreamCommand` esegue i comandi con l'identità OS del servizio NiFi; in
questa installazione l'utenza prevista è `nifi`. Questa utenza deve poter
attraversare le directory del percorso, eseguire l'interprete Python e gli
script `.sh` usati come `Command Path`, leggere gli script Python passati come
argomenti e scrivere nelle directory di log. I file `.py` invocati come
`python file.py` devono essere leggibili, non necessariamente eseguibili.

Verificare sul server che il servizio NiFi usi l'utenza attesa e che i permessi siano sufficienti:

```bash
sudo systemctl show nifi.service -p User --value
sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/.venv/bin/python
sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/bin/launch_manual_dwh_run.sh
sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/bin/run_group_cycle.sh
sudo -u nifi test -r /opt/etl/frontiere-metadata-runner/scripts/dwh_schedule_runner.py
sudo -u nifi test -w /opt/etl/log/dwh-scheduler
```

Ogni comando deve terminare con codice `0`. Preferire permessi assegnati
all'owner/gruppo `nifi` (ad esempio `nifi:nifi` e `0750` per gli eseguibili)
anziché abilitare l'esecuzione a tutti gli utenti.

---

## 12. Prerequisiti

- Apache NiFi 2.11 raggiungibile in HTTPS;
- Oracle Linux 8.10 o ambiente compatibile;
- Python 3.11 disponibile in `/usr/bin/python3.11`;
- accesso PostgreSQL al database RASOP;
- accesso PostgreSQL al database HCBI;
- schemi `hcbi_utility` e `hcbi_ras` nello stesso database `hcbi`;
- tabelle `hcbi_ras.frontiera_*` già esistenti;
- `hcbi_utility.etl_frontiere_config` già popolata;
- `hcbi_utility.etl_frontiere_run` già esistente con `warning_message text`;
- `hcbi_utility.etl_frontiere_execution_lock` già esistente;
- procedura `hcbi_utility.prc_execute_chain(integer)` disponibile ed eseguibile;
- privilegi `SELECT` sulla sorgente RASOP;
- privilegi di lettura, scrittura e `TRUNCATE` sulle tabelle interessate;
- autorizzazione all'uso di `ExecuteStreamCommand` in NiFi.

Questi prerequisiti devono essere verificati nell'ambiente target. Il pacchetto non è dichiarato production-ready senza collaudo.

---

## 13. Installazione e packaging

La procedura completa per sistemisti, inclusi manifest dei file, preparazione
degli archivi, destinazioni e installazione NiFi/FMR/scheduler, è mantenuta nel
manuale canonico `doc/deploy/MANUALE_DEPLOY_NIFI.md`. Questo README resta il
riferimento tecnico su architettura e comportamento del runner.

## 14. Credenziali e segreti

La creazione, cifratura, validazione e rotazione dei segreti sono descritte nel
manuale canonico. Non versionare la chiave Fernet né file con credenziali in
chiaro o cifrate.


## 15. Verifica sintattica

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m py_compile \
  /opt/etl/frontiere-metadata-runner/scripts/*.py
```

L'assenza di output indica che gli script sono sintatticamente validi.

---

## 16. Deploy e verifica NiFi

Il deploy del Process Group, le verifiche post-deploy e lo smoke test sono
descritti nel manuale canonico `doc/deploy/MANUALE_DEPLOY_NIFI.md`. Questo
documento mantiene i test di accettazione funzionale nella sezione 17.


## 17. Test minimi di accettazione

### T01 - Caricamento frontiera riuscito

- Input: configurazione valida e sorgente disponibile.
- Atteso: `SUCCEEDED`, conteggi valorizzati, target aggiornato.
- Verifica: confronto tra `rows_read`, `rows_written` e conteggio target.

### T02 - Zero righe

- Input: query valida senza risultati.
- Atteso: `SUCCEEDED`, conteggi a zero, `warning_message` valorizzato.
- Verifica: tabella run e file di log.

### T03 - Errore sorgente

- Input: query sorgente errata.
- Atteso: `FAILED`, errore registrato, refresh DWH non avviato.
- Verifica: assenza di un run DWH con lo stesso execution UUID; il gate auto-termina l'output senza marker e non viene creato un nuovo run DWH per il ciclo fallito.

### T04 - Errore scrittura target

- Input: mapping incompatibile.
- Atteso: `FAILED`, rollback della transazione frontiera, refresh DWH non avviato.
- Verifica: contenuto precedente del target e log DB.

### T05 - Lock frontiera

- Input: lock applicativo già esistente.
- Atteso: frontiera `SKIPPED`, refresh DWH non avviato.
- Verifica: stato run e target invariato.

### T06 - Refresh DWH riuscito

- Input: tutte le frontiere riuscite e procedura disponibile.
- Atteso: `etl_dwh_refresh_run.status = SUCCEEDED`.
- Verifica: `chain_id = 1`, UUID coincidente e log filesystem.

### T07 - Errore procedura DWH

- Input: errore restituito dalla procedura.
- Atteso: `FAILED`, `error_message` valorizzato, ramo NiFi `nonzero status`.
- Verifica: tabella DWH e `dwh-refresh.log`.

### T08 - Concorrenza DWH

- Input: secondo refresh DWH mentre il primo detiene il lock.
- Atteso: secondo run `SKIPPED` ed exit code non-zero.
- Verifica: tabella DWH e log.

### T09 - UUID condiviso

- Input: ciclo completo riuscito.
- Atteso: stesso UUID in `etl_frontiere_run.nifi_flowfile_uuid`, `etl_dwh_refresh_run.execution_uuid` e `log_chain.etl_execution_uuid`.
- Verifica: correlazione tra le tre tabelle di log tramite l'UUID dell'esecuzione e assenza dello UUID zero in `log_chain` per il ciclo completato.

### T10 - Restart a sistema inattivo

- Input: riavvio del server senza processi attivi.
- Atteso: flow, script, virtual environment e segreti ancora disponibili.
- Verifica: connessioni, UI NiFi e nuovo `Run Once`.

---

## 18. Riavvio del server

Verifiche di persistenza, ripartenza dei servizi e controlli dopo reboot sono
incluse nel manuale canonico `doc/deploy/MANUALE_DEPLOY_NIFI.md`.

## 19. Rollback

La procedura di rollback applicativa è nel manuale canonico. Il rollback del
database è separato e non va eseguito come parte del rollback FMR.

---

## 20. Limiti e decisioni aperte

- il timer systemd è predisposto; l'abilitazione va verificata sul server target;
- timeout e batch size definitivi richiedono test;
- alerting su `FAILED`, `SKIPPED` e warning zero righe è da definire;
- la procedura DWH è considerata autonoma nella gestione transazionale, come requisito fornito;
- il comportamento della procedura in caso di riavvio deve essere collaudato;
- il pacchetto deve essere verificato in ambiente di sviluppo prima della promozione;
- non sono definiti SLA, RPO/RTO, retention o volumetrie.

---

## 21. Checklist finale di deploy

La checklist completa per il sistemista è nel manuale canonico
`doc/deploy/MANUALE_DEPLOY_NIFI.md`.

---

## 22. Stato del progetto

```text
Versione documentata: v0.4
NiFi: 2.11
Python runtime: 3.11
Trigger iniziale: manuale
Caricamento frontiere: full refresh sequenziale
Refresh DWH: CALL hcbi_utility.prc_execute_chain(1)
Transazione procedura DWH: autonoma
Logging frontiere: database + filesystem
Logging DWH: database + filesystem
Execution UUID: condiviso tra i due step
```
