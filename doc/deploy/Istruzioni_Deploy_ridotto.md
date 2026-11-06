# Istruzioni di deploy ridotte

Questa guida descrive il deploy del progetto `frontiere-metadata-runner` e dello
scheduler DWH su un server Linux con NiFi, PostgreSQL e systemd.

## 0. Prerequisiti

Prima di iniziare verificare che siano disponibili:

- Apache NiFi 2.11 raggiungibile via HTTPS;
- Oracle Linux 8.10, o un ambiente compatibile;
- Python 3.11 in `/usr/bin/python3.11`;
- accesso PostgreSQL al database RASOP, utilizzato per le query sulle frontiere;
- accesso PostgreSQL al database HCBI, che contiene il DWH;
- gli schemi `hcbi_utility` e `hcbi_ras` nello stesso database `hcbi`;
- le tabelle `hcbi_ras.frontiera_*` gia esistenti;
- `hcbi_utility.etl_frontiere_config` gia popolata;
- `hcbi_utility.etl_frontiere_run` gia esistente e dotata della colonna
  `warning_message` di tipo `text`;
- `hcbi_utility.etl_frontiere_execution_lock` gia esistente;
- la procedura `hcbi_utility.prc_execute_chain(integer)` disponibile ed
  eseguibile;
- privilegi `SELECT` sul database RASOP;
- privilegi di lettura, scrittura e `TRUNCATE` sulle tabelle interessate;
- autorizzazione all'uso di `ExecuteStreamCommand` in NiFi.

## 1. Installazione completa da zero

### 1.1 Pulizia del deploy precedente

1. Dalla UI di NiFi, aprire il Process Group `FRONTIERE_METADATA_RUNNER` e
   selezionare **Stop**.
2. Attendere che tutti i processori risultino fermi.

   Esempio di URL:

   ```text
   https://192.168.248.135:8443/nifi/
   ```

3. Dal terminale verificare che non siano rimasti processi attivi:

   ```bash
   ps -ef | grep '[r]un_frontiere.py'
   ps -ef | grep '[r]un_dwh_refresh.py'
   ```

4. Dalla UI NiFi eliminare il Process Group `FRONTIERE_METADATA_RUNNER`.
5. Se NiFi segnala `Queue not empty`, selezionare il Process Group, scegliere
   **Empty All Queues** e ripetere l'eliminazione.

### 1.2 Estrazione del pacchetto

Copiare `fmr-v0.4.zip` in `/tmp` ed eseguire:

```bash
rm -rf /tmp/fmr-v0.4
cd /tmp
unzip fmr-v0.4.zip -d /tmp
```

### 1.3 Installazione del progetto

```bash
export FMR_SERVICE_USER=nifi
export FMR_SERVICE_GROUP=nifi
cd /tmp/fmr-v0.4
sudo -E bash bin/install_layout.sh
```

Lo script installa il progetto in:

```text
/opt/etl/frontiere-metadata-runner
```

I file esterni dei segreti gia presenti non vengono rimossi.

### 1.4 Creazione del virtual environment

```bash
export FMR_SERVICE_USER=nifi
export FMR_SERVICE_GROUP=nifi
sudo rm -rf /opt/etl/frontiere-metadata-runner/.venv
sudo -u nifi /usr/bin/python3.11 -m venv \
  /opt/etl/frontiere-metadata-runner/.venv
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m pip install --upgrade pip setuptools wheel
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m pip install -r /opt/etl/frontiere-metadata-runner/requirements.txt
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m py_compile /opt/etl/frontiere-metadata-runner/scripts/*.py
```

### 1.5 Configurazione e cifratura dei segreti

#### 1.5.1 File temporaneo in chiaro

Copiare `fmr-secrets.template.json` in `/tmp/fmr-secrets.json`, proteggerlo e
valorizzare URL, utenze e password reali:

```bash
cp /opt/etl/frontiere-metadata-runner/config/fmr-secrets.template.json \
  /tmp/fmr-secrets.json
chmod 0600 /tmp/fmr-secrets.json
```

Il file deve contenere almeno:

```json
{
  "nifi": {
    "base_url": "https://NIFI_HOST:8443/nifi",
    "username": "CHANGE_ME",
    "password": "CHANGE_ME",
    "verify_ssl": false
  },
  "rasop": {
    "jdbc_url": "jdbc:postgresql://RASOP_HOST:5432/RAS_Operazionales?currentSchema=public",
    "username": "CHANGE_ME",
    "password": "CHANGE_ME"
  },
  "hcbi": {
    "jdbc_url": "jdbc:postgresql://HCBI_HOST:5432/hcbi?currentSchema=hcbi_ras",
    "username": "CHANGE_ME",
    "password": "CHANGE_ME"
  }
}
```

#### 1.5.2 Cifratura

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/encrypt_fmr_secrets.py \
  --input /tmp/fmr-secrets.json \
  --key-file /opt/etl/secrets/fmr-secrets.key \
  --output /opt/etl/config/fmr-secrets.json.enc \
  --delete-input
```

Lo script valida le sezioni obbligatorie, rifiuta i placeholder, genera la chiave
Fernet se necessaria, cifra il JSON, imposta i permessi `0600`, verifica la
decifratura ed elimina il file in chiaro. Le password non vengono stampate.

Se la chiave e il file cifrato esistenti sono gia corretti, non e necessario
rigenerarli.

### 1.6 Deploy del flow NiFi

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/deploy_nifi_flow.py
```

### 1.7 Avvio facoltativo da shell

Per eseguire manualmente un ciclo completo:

```bash
cd /opt/etl/frontiere-metadata-runner
./bin/run_group_cycle.sh --frontiere-timeout 3600 --dwh-timeout 1800
```

Il comando avvia `FRONTIERE_METADATA_RUNNER`, attende il caricamento delle
frontiere e il refresh della chain DWH 1, legge le tabelle di tracciamento e
ferma il Process Group al termine o allo scadere del timeout.

Se compare `Permission denied`, verificare che gli script nella directory
`bin/` siano eseguibili; rieseguire `bin/install_layout.sh` se necessario.

## 2. Deploy dello scheduler DWH

### 2.1 Prerequisiti dello scheduler

Verificare che siano disponibili:

- PostgreSQL 17 con lo schema `hcbi_utility` gia creato;
- il ruolo `hcbi` e i privilegi necessari per le tabelle e la sequence;
- un host Linux con systemd, il servizio NiFi e l'account `nifi:nifi`;
- FMR installato in `/opt/etl/frontiere-metadata-runner`;
- il virtual environment Python 3.11 in `.venv`;
- i file dei segreti nei percorsi previsti e leggibili dall'utente `nifi`;
- il Process Group `FRONTIERE_METADATA_RUNNER` importato e funzionante.

Lo scheduler riutilizza il virtual environment di FMR e usa un timer systemd,
non cron. Il timer verifica ogni giorno alle 03:00, ora `Europe/Rome`, se la
tabella `hcbi_utility.dwh_schedule` richiede l'esecuzione.

### 2.2 Installazione e verifica PostgreSQL

Se non gia applicati, eseguire i DDL dal pacchetto dello scheduler:

```bash
psql -v ON_ERROR_STOP=1 -d hcbi \
  -f deploy/postgresql/01_create_dwh_schedule.sql
psql -v ON_ERROR_STOP=1 -d hcbi \
  -f deploy/postgresql/02_verify_dwh_schedule.sql
```

Inserire inizialmente la configurazione con `enabled = false`:

```sql
INSERT INTO hcbi_utility.dwh_schedule
  (process_code, process_description, enabled, frequency_code,
   anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
  ('DWH_REFRESH_DAILY', 'Refresh DWH DAILY', false, 'DAILY',
   NULL, NULL, NULL, NULL);
```

Gli esempi per le altre frequenze sono disponibili in:

```text
deploy/postgresql/04_esempi_schedulazioni_dwh.sql
```

### 2.3 Installazione dei file Linux

Copiare `unix-linux.zip` in `/tmp` ed eseguire:

```bash
cd /tmp
rm -rf /tmp/unix-linux
unzip unix-linux.zip -d /tmp
cd /tmp/unix-linux
sudo -E bash install_dwh_scheduler.sh
```

L'installer installa il service e il timer systemd, ma non abilita e non avvia
automaticamente il timer.

### 2.4 Deploy del launcher manuale NiFi

Creare una sola volta il Process Group per l'avvio manuale:

```bash
sudo -u nifi \
  /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/deploy_manual_launcher.py
```

Lo script crea `DWH_MANUAL_LAUNCH` e lo lascia fermo; non avvia il refresh.
Verificare che l'utente `nifi` abbia permessi di attraversamento ed esecuzione su
tutte le directory del percorso `/opt/etl/frontiere-metadata-runner`.

### 2.5 Abilitazione del timer

```bash
sudo systemctl enable --now dwh-scheduler.timer
sudo systemctl list-timers dwh-scheduler.timer
```

Per avviare immediatamente il servizio senza attendere la prossima scadenza:

```bash
sudo systemctl start dwh-scheduler.service
```

L'abilitazione del timer puo avviare il caricamento alla prima scadenza utile,
se la configurazione in `dwh_schedule` lo consente.

### 2.6 Abilitazione dell'ingestion dei log

L'ingestion salva i log di esecuzione nelle tabelle:

- `hcbi_utility.etl_execution_log_event`;
- `hcbi_utility.etl_execution_log_ingestion`.

Per abilitarla, aggiungere al file `/etc/sysconfig/dwh-scheduler`:

```bash
FMR_LOG_INGESTION_ENABLED=true
```

La modifica viene letta al successivo avvio del servizio. Il loader acquisisce i
segmenti dei log al termine del ciclo.

### 2.7 Monitoraggio e diagnosi

```bash
sudo systemctl status dwh-scheduler.timer dwh-scheduler.service
sudo journalctl -u dwh-scheduler.service --since today
sudo tail -n 100 /opt/etl/log/dwh-scheduler/dwh-scheduler.log
```
### 2.8 TroubleShooting
Mancato Refresh del DWH : se sul file di log 'dwh-scheduler.log' compare ripetutamente la voce:

2026-11-06 13:10:49,101 INFO [run_group_cycle] 2026-11-06T12:10:49.101446+00:00 [heartbeat] fase DWH: in attesa della riga di avvio nel log DWH, in attesa...
2026-11-06 13:11:49,116 INFO [run_group_cycle] 2026-11-06T12:11:49.116248+00:00 [heartbeat] fase DWH: in attesa della riga di avvio nel log DWH, in attesa...
e poi scatta il timeout:
2026-11-06 13:38:49,542 INFO [run_group_cycle] 2026-11-06T12:38:49.537584+00:00 [TIMEOUT] Timeout: nessuna riga 'Avvio DWH refresh' nel log /opt/etl/log/frontiere-metadata-runner/dwh-refresh.log dopo 1800.0s
2026-11-06 13:38:49,545 INFO [run_group_cycle] 2026-11-06T12:38:49.537650+00:00 Arresto process group (state=STOPPED)...
2026-11-06 13:38:50,533 INFO [run_group_cycle] 2026-11-06T12:38:50.529430+00:00 Ciclo terminato con exit_code=5
2026-11-06 13:38:54,643 INFO Run d34321bd-d818-4fa0-ab8f-23e093061d8d concluso con stato FAILED

Probabilmente ci sono dei processi appessi su NiFI, per eliminarli:
sulla UI web di NiFi selezionare il gruppo FRONTIERE_METADATA_RUNNER
con il tasto destro del mouse selezionare 'Empty All Queues' 
e rilanciare l'intero processo manualmente.
