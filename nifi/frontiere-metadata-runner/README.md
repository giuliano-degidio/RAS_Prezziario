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
    | output stream, exit code 0
    v
Run DWH refresh chain 1
    |
    +-- output stream --> Log DWH refresh completed
    |
    +-- nonzero status --> Log DWH refresh failed

Run sequential full refresh
    |
    +-- nonzero status --> Log frontiere failed
```

Il refresh del DWH parte soltanto quando tutte le frontiere attive hanno terminato senza stati `FAILED` o `SKIPPED`.

Entrambi i processor `ExecuteStreamCommand` hanno la relationship:

```text
original -> Terminate = true
```

Questo evita che i processor risultino invalidi per relationship non gestite.

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

riceve tramite standard input l'output del runner delle frontiere e recupera il marker:

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
    │   ├── deploy_nifi_flow.py
    │   ├── encrypt_fmr_secrets.py
    │   ├── run_frontiere.py
    │   ├── run_dwh_refresh.py
    │   ├── secrets_common.py
    │   └── validate_fmr_secrets.py
    └── sql/
        ├── 01_create_hcbi_utility_etl_dwh_refresh_run.sql
        └── 02_verify_runtime.sql
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

## 13. Installazione completa da zero

### 13.1 Pulizia del precedente deploy

Fermare il Process Group:

```text
FRONTIERE_METADATA_RUNNER
```

Verificare che non siano presenti processi attivi:

```bash
ps -ef | grep '[r]un_frontiere.py'
ps -ef | grep '[r]un_dwh_refresh.py'
```

Verificare i lock residui:

```sql
SELECT
    l.frontiera_code,
    l.run_id,
    l.acquired_at,
    l.acquired_by,
    r.status,
    r.started_at,
    r.ended_at
FROM hcbi_utility.etl_frontiere_execution_lock AS l
JOIN hcbi_utility.etl_frontiere_run AS r
  ON r.run_id = l.run_id
ORDER BY l.acquired_at;
```

Dalla UI NiFi eliminare il Process Group precedente.

Il deployer interrompe l'operazione se trova già un Process Group omonimo.

### 13.2 Estrazione del pacchetto

```bash
rm -rf /tmp/fmr-v0.4
mkdir -p /tmp/fmr-v0.4

unzip frontiere-metadata-runner-v0.4-full.zip \
  -d /tmp/fmr-v0.4
```

Entrare nella directory estratta che contiene `README.md`, `bin`, `scripts` e `sql`.

### 13.3 Creazione della tabella di log DWH

Eseguire sul database `hcbi`:

```bash
psql \
  -f sql/01_create_hcbi_utility_etl_dwh_refresh_run.sql
```

Verificare:

```sql
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'hcbi_utility'
  AND table_name = 'etl_dwh_refresh_run'
ORDER BY ordinal_position;
```

### 13.4 Installazione file

```bash
export FMR_SERVICE_USER=nifi
export FMR_SERVICE_GROUP=nifi

sudo -E bash bin/install_layout.sh
```

Lo script installa il progetto sotto:

```text
/opt/etl/frontiere-metadata-runner
```

Non elimina i file esterni dei segreti già presenti.

### 13.5 Creazione del virtual environment

Sul server il comando generico `python3` può puntare a Python 3.6. Usare esplicitamente Python 3.11:

```bash
rm -rf /opt/etl/frontiere-metadata-runner/.venv

sudo -u nifi /usr/bin/python3.11 -m venv \
  /opt/etl/frontiere-metadata-runner/.venv
```

Aggiornare gli strumenti di packaging:

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m pip install --upgrade pip setuptools wheel
```

Installare le dipendenze:

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m pip install \
  -r /opt/etl/frontiere-metadata-runner/requirements.txt
```

Verificare:

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -c "import sys, cryptography, psycopg; \
print(sys.version); \
print('cryptography', cryptography.__version__); \
print('psycopg', psycopg.__version__)"
```

---

## 14. Generazione e cifratura delle password

### 14.1 File temporaneo in chiaro

```bash
umask 077

cp /opt/etl/frontiere-metadata-runner/config/fmr-secrets.template.json \
  /tmp/fmr-secrets.json

chmod 0600 /tmp/fmr-secrets.json
```

Valorizzare:

- URL, username e password NiFi;
- JDBC URL, username e password RASOP;
- JDBC URL, username e password HCBI;
- `verify_ssl` per NiFi.

Esempio di formato JDBC:

```text
jdbc:postgresql://host:5432/database
```

### 14.2 Cifratura

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/encrypt_fmr_secrets.py \
  --input /tmp/fmr-secrets.json \
  --key-file /opt/etl/secrets/fmr-secrets.key \
  --output /opt/etl/config/fmr-secrets.json.enc \
  --delete-input
```

Lo script:

- valida le sezioni obbligatorie;
- rifiuta placeholder non sostituiti;
- genera una chiave Fernet se non esiste;
- cifra integralmente il JSON;
- salva chiave e file cifrato con permessi `0600`;
- verifica immediatamente la decifratura;
- elimina il file in chiaro con `--delete-input`;
- non stampa le password.

Se chiave e file cifrato esistenti sono già corretti, non è necessario rigenerarli.

### 14.3 Validazione con connessione reale

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/validate_fmr_secrets.py \
  --connect
```

Il comando deve verificare sia HCBI sia RASOP.

### 14.4 Rotazione password

Per cambiare le password mantenendo la chiave:

1. creare un nuovo JSON temporaneo protetto;
2. eseguire nuovamente `encrypt_fmr_secrets.py` senza eliminare la chiave;
3. validare con `--connect`;
4. eliminare il file temporaneo in chiaro.

La chiave non deve essere versionata, inserita nei log o salvata insieme al file cifrato in un backup non protetto.

---

## 15. Verifica sintattica

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m py_compile \
  /opt/etl/frontiere-metadata-runner/scripts/*.py
```

L'assenza di output indica che gli script sono sintatticamente validi.

---

## 16. Deploy NiFi da zero

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/deploy_nifi_flow.py
```

Il deployer:

- autentica tramite le credenziali NiFi cifrate;
- crea `FRONTIERE_METADATA_RUNNER` sotto root;
- crea il trigger manuale;
- crea i due `ExecuteStreamCommand`;
- collega i rami di successo e di errore;
- imposta `original -> Terminate = true` su entrambi;
- verifica via REST API l'auto-terminazione;
- lascia il Process Group fermo;
- interrompe il deploy se il Process Group esiste già.

Output atteso:

```text
[OK] Process Group creato STOPPED: FRONTIERE_METADATA_RUNNER (...)
[OK] Frontiere -> DWH chain 1; original terminate=true su entrambi
```

---

## 17. Verifica post-deploy nella UI NiFi

### 17.1 `Run sequential full refresh`

Proprietà runtime:

```text
FMR_SECRET_KEY_FILE
FMR_ENCRYPTED_CONFIG
FMR_LOG_DIR
```

Non deve essere presente:

```text
FMR_FLOWFILE_UUID
```

Relationship:

```text
original         Terminate = true
output stream    collegata a Run DWH refresh chain 1
nonzero status   collegata a Log frontiere failed
```

### 17.2 `Run DWH refresh chain 1`

```text
Ignore STDIN = false
```

Relationship:

```text
original         Terminate = true
output stream    collegata a Log DWH refresh completed
nonzero status   collegata a Log DWH refresh failed
```

Il secondo processor deve ricevere il contenuto prodotto dal primo, perché contiene il marker dell'execution UUID.

---

## 18. Primo collaudo

Usare **Run Once** sul processor:

```text
Manual trigger
```

Verificare i run delle frontiere:

```sql
SELECT
    run_id,
    frontiera_code,
    started_at,
    ended_at,
    status,
    rows_read,
    rows_written,
    warning_message,
    error_message,
    nifi_flowfile_uuid
FROM hcbi_utility.etl_frontiere_run
ORDER BY run_id DESC
LIMIT 20;
```

Verificare il refresh DWH:

```sql
SELECT
    run_id,
    execution_uuid,
    chain_id,
    started_at,
    ended_at,
    status,
    error_message
FROM hcbi_utility.etl_dwh_refresh_run
ORDER BY run_id DESC
LIMIT 20;
```

Verificare la correlazione:

```sql
SELECT
    f.nifi_flowfile_uuid AS execution_uuid,
    f.frontiera_code,
    f.status AS frontiera_status,
    d.chain_id,
    d.status AS dwh_status
FROM hcbi_utility.etl_frontiere_run AS f
LEFT JOIN hcbi_utility.etl_dwh_refresh_run AS d
  ON d.execution_uuid::text = f.nifi_flowfile_uuid
ORDER BY f.run_id DESC;
```

Controllare i log filesystem:

```bash
tail -n 100 \
  /opt/etl/log/frontiere-metadata-runner/frontiere-metadata-runner.log

tail -n 100 \
  /opt/etl/log/frontiere-metadata-runner/dwh-refresh.log
```

---

## 19. Test minimi di accettazione

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
- Verifica: assenza di un run DWH con lo stesso execution UUID.

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

## 20. Riavvio del server

Il virtual environment è una directory persistente:

```text
/opt/etl/frontiere-metadata-runner/.venv
```

Dopo un reboot non deve essere riattivato. NiFi usa direttamente:

```text
/opt/etl/frontiere-metadata-runner/.venv/bin/python
```

Il progetto continua a funzionare se:

- `/opt/etl` è persistente e montato;
- Python 3.11 resta installato;
- `.venv` resta disponibile;
- chiave e file cifrato sono leggibili da `nifi`;
- NiFi riparte correttamente;
- il flow è conservato dalla configurazione NiFi.

Verifica runtime dopo il reboot:

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -c "import cryptography, psycopg; print('FMR runtime OK')"
```

Se il server viene riavviato durante un caricamento, verificare run `RUNNING`, lock residui e stato delle tabelle prima di rilanciare.

---

## 21. Rollback

1. fermare il Process Group;
2. verificare che non siano attivi `run_frontiere.py` o `run_dwh_refresh.py`;
3. verificare run e lock;
4. conservare i log database e filesystem;
5. esportare il flow se richiesto dalle procedure operative;
6. eliminare manualmente il Process Group;
7. ripristinare la precedente directory applicativa;
8. ripristinare chiave e file cifrato soltanto da backup protetto;
9. non cancellare automaticamente i record di audit;
10. valutare separatamente il rollback del DDL `etl_dwh_refresh_run` solo se la tabella non contiene evidenze da conservare.

---

## 22. Limiti e decisioni aperte

- la schedulazione periodica non è ancora attivata;
- timeout e batch size definitivi richiedono test;
- alerting su `FAILED`, `SKIPPED` e warning zero righe è da definire;
- la procedura DWH è considerata autonoma nella gestione transazionale, come requisito fornito;
- il comportamento della procedura in caso di riavvio deve essere collaudato;
- il pacchetto deve essere verificato in ambiente di sviluppo prima della promozione;
- non sono definiti SLA, RPO/RTO, retention o volumetrie.

---

## 23. Checklist finale di deploy

- [ ] precedente Process Group eliminato;
- [ ] nessun processo Python attivo;
- [ ] lock residui verificati;
- [ ] tabella `etl_dwh_refresh_run` creata;
- [ ] grant verificate;
- [ ] file installati sotto `/opt/etl`;
- [ ] virtual environment creato con Python 3.11;
- [ ] dipendenze installate;
- [ ] segreti cifrati validati;
- [ ] connessioni HCBI e RASOP riuscite;
- [ ] script compilati senza errori;
- [ ] Process Group creato e fermo;
- [ ] `original -> Terminate = true` su entrambi i processor;
- [ ] `Ignore STDIN = false` sul refresh DWH;
- [ ] primo `Run Once` completato;
- [ ] log frontiere verificato;
- [ ] log DWH verificato;
- [ ] UUID condiviso verificato;
- [ ] assenza di lock residui verificata;
- [ ] rollback documentato.

---

## 24. Stato del progetto

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
