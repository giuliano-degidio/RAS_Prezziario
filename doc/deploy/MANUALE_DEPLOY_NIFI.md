# Manuale di Deploy — FRONTIERE METADATA RUNNER (NiFi)

Documento operativo per il sistemista. Contiene tutti i passi, in ordine, per
installare da zero NiFi e il progetto `frontiere-metadata-runner` su un nuovo
server, collaudarlo e gestirlo in esercizio.

Per il "perché" delle scelte progettuali (architettura, logging, lock,
semantica transazionale) vedere `nifi/frontiere-metadata-runner/README.md`:
qui ci sono solo le azioni da eseguire.

> Convenzioni: i comandi preceduti da `$` vanno eseguiti con l'utente di
> servizio (`nifi` di default); quelli preceduti da `#` richiedono `sudo`/root.
> Sostituire i placeholder tra `< >` con i valori reali del vostro ambiente.

---

## 0. Indice

1. Ambiente di riferimento
2. Prerequisiti
3. Checklist pre-deploy
4. Installazione di NiFi
5. Gestione del servizio NiFi (start/stop/status/log)
6. Preparazione filesystem del progetto FMR
7. Database: creazione oggetti
8. Configurazione segreti (credenziali cifrate)
9. Virtual environment Python
10. Deploy del flusso NiFi (process group)
11. Scheduler DWH: automatico e manuale
12. Esecuzione FMR: UI oppure riga di comando
13. Verifica stato / monitoraggio da riga di comando
14. Collaudo (smoke test)
15. Troubleshooting
16. Rollback / disinstallazione
17. Riferimenti

---

## 1. Ambiente di riferimento

Valori rilevati sull'ambiente attualmente in esercizio (adattare se il nuovo
server differisce):

| Elemento | Valore |
|---|---|
| Sistema operativo | Oracle Linux Server 8.10 |
| Java richiesto da NiFi 2.11 | Java 21 (`java-21-openjdk-headless`) |
| NiFi | 2.11.0, installato in `/opt/nifi-2.11.0` |
| Servizio NiFi | systemd unit `nifi.service` |
| NiFi UI | `https://<NIFI_HOST>:8443/nifi` (es. `https://192.168.248.135:8443/nifi`) |
| Firewall | `firewalld` attivo, porta `8443/tcp` aperta |
| Autenticazione NiFi | single-user (username/password locali NiFi) |
| Database | PostgreSQL 17.0 |
| DB applicativo | `hcbi` su `<DB_HOST>:5432` (es. `192.168.248.135:5432`) |
| Scheduler DWH | timer `systemd` giornaliero alle 03:00 `Europe/Rome`; frequenza decisa da `hcbi_utility.dwh_schedule` |
| Schemi coinvolti | `hcbi_ras`, `hcbi_utility` |
| Ruoli DB esistenti | `hcbi`, `hcbi_ras`, `hcbi_utility` |
| DB sorgente frontiere | `RAS_Operazionales` sullo stesso host Postgres (utente dedicato, es. `rasop`) |
| Python richiesto da FMR | 3.11 |
| Utente/gruppo di servizio FMR | `nifi` / `nifi` |
| Progetto FMR installato in | `/opt/etl/frontiere-metadata-runner` |

> Nota: non esiste un ruolo Postgres dedicato "nifi": NiFi/il progetto FMR si
> collegano al DB con le credenziali applicative (`hcbi`, e un utente dedicato
> sul DB `RAS_Operazionales`) definite nel file segreti cifrato (§8), non con
> l'autenticazione NiFi stessa.

---

## 2. Prerequisiti

Prima di iniziare, richiedere/preparare:

- [ ] Accesso SSH al server target con utente sudo
- [ ] Credenziali del DB `hcbi` (utente applicativo, es. `hcbi`) con accesso a
      `hcbi_ras` e `hcbi_utility`
- [ ] DBA o referente DBA disponibile per applicare il DDL dello scheduler e
      concedere i privilegi necessari (non si presume che l'utente applicativo
      possa creare tabelle, funzioni e trigger)
- [ ] Frequenza, calendario e retry della schedulazione approvati prima
      dell'abilitazione del timer
- [ ] Credenziali del DB `RAS_Operazionales` (utente di sola lettura sulle
      tabelle sorgente delle frontiere)
- [ ] Username/password da assegnare all'utente single-user NiFi
- [ ] Connettività di rete: server NiFi → host Postgres, porta 5432, su
      entrambi i database
- [ ] Pacchetto del progetto FMR (checkout di questo repository o tarball
      della cartella `nifi/frontiere-metadata-runner/`)
- [ ] Conferma che la porta 8443 sia raggiungibile dalla postazione da cui si
      amministrerà la UI NiFi (o predisposizione tunnel SSH)

---

## 3. Checklist pre-deploy

- [ ] OS aggiornato, Java 21 disponibile
- [ ] NiFi 2.11 installato e avviato come servizio systemd
- [ ] UI NiFi raggiungibile via HTTPS
- [ ] Postgres 17 raggiungibile da questo host sulle due basi dati
- [ ] Oggetti FMR e scheduler DB creati/verificati (§7)
- [ ] Configurazione scheduler verificata; al massimo una riga abilitata (§7)
- [ ] File segreti cifrato generato, validato, e permessi ristretti (§8)
- [ ] Virtual environment Python creato con dipendenze installate (§9)
- [ ] Process group FMR deployato e verificato nella UI (§10)
- [ ] Launcher `DWH_MANUAL_LAUNCH` installato (§11)
- [ ] Timer attivato solo dopo approvazione operativa (§11)
- [ ] Smoke test eseguito con esito positivo (§14)

---

## 4. Installazione di NiFi

Se NiFi non è già installato sul server:

```bash
# 1. Java 21
# dnf install -y java-21-openjdk-headless
# alternatives --config java   # selezionare Java 21

# 2. Download ed estrazione NiFi 2.11.0 sotto /opt
# cd /opt
# wget https://downloads.apache.org/nifi/2.11.0/nifi-2.11.0-bin.zip
# unzip nifi-2.11.0-bin.zip
# mv nifi-2.11.0 nifi-2.11.0
# chown -R nifi:nifi /opt/nifi-2.11.0

# 3. Configurare l'esposizione HTTP(S)
# modificare conf/nifi.properties:
#   nifi.web.https.host=0.0.0.0   (oppure l'IP/hostname del server)
#   nifi.web.https.port=8443

# 4. Impostare credenziali single-user
# /opt/nifi-2.11.0/bin/nifi.sh set-single-user-credentials <username> <password>

# 5. Creare l'unit systemd nifi.service che avvia:
#   /opt/nifi-2.11.0/bin/nifi.sh start
#   (ExecStop: /opt/nifi-2.11.0/bin/nifi.sh stop)

# 6. Abilitare e avviare il servizio
# systemctl daemon-reload
# systemctl enable --now nifi.service

# 7. Aprire la porta nel firewall
# firewall-cmd --permanent --add-port=8443/tcp
# firewall-cmd --reload
```

Accesso alla UI: `https://<NIFI_HOST>:8443/nifi`. Se il certificato è
self-signed, il browser segnalerà un warning: procedere accettando
l'eccezione, oppure installare un certificato valido. Se si accede da remoto
dietro NAT/hostname diverso, usare un tunnel SSH:

```bash
ssh -L 8443:localhost:8443 <utente>@<NIFI_HOST>
# poi aprire https://localhost:8443/nifi
```

---

## 5. Gestione del servizio NiFi (start/stop/status/log)

È disponibile lo script `bin/nifi_service.sh` (wrapper su `systemctl`/
`journalctl`):

```bash
$ bin/nifi_service.sh start
$ bin/nifi_service.sh status
$ bin/nifi_service.sh restart
$ bin/nifi_service.sh stop
$ bin/nifi_service.sh logs 300     # ultime 300 righe di log
```

Equivalenti manuali:

```bash
# systemctl status nifi.service
# systemctl restart nifi.service
# journalctl -u nifi.service -n 300 --no-pager
```

---

## 6. Preparazione filesystem del progetto FMR

Dal checkout del repository, posizionarsi in `nifi/frontiere-metadata-runner/`
ed eseguire come utente con sudo:

```bash
# bin/install_layout.sh
```

Lo script crea (utente/gruppo `nifi`, override con `FMR_SERVICE_USER`/
`FMR_SERVICE_GROUP`):

```text
/opt/etl/
├── log/frontiere-metadata-runner/      (0750 nifi:nifi)
├── config/                             (0700 nifi:nifi)
├── secrets/                            (0700 nifi:nifi)
└── frontiere-metadata-runner/
    ├── scripts/   (0750 directory, 0750 i .py)
    ├── sql/
    ├── config/
    ├── requirements.txt
    └── README.md
```

Verificare permessi e proprietario al termine:

```bash
$ ls -la /opt/etl /opt/etl/frontiere-metadata-runner
```

Il deploy scheduler della sezione 11 aggiunge `scripts/dwh_schedule_runner.py`,
`bin/launch_manual_dwh_run.sh` e la directory log
`/opt/etl/log/dwh-scheduler`. `ExecuteStreamCommand` gira con l'identità OS del
servizio NiFi (qui `nifi`): l'utente deve poter eseguire il Python dell'ambiente
virtuale e gli script `.sh` usati come comando, leggere gli script `.py` passati
come argomenti e scrivere nelle directory di log.

```bash
$ sudo systemctl show nifi.service -p User --value
$ sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/.venv/bin/python
$ sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/bin/launch_manual_dwh_run.sh
$ sudo -u nifi test -r /opt/etl/frontiere-metadata-runner/scripts/dwh_schedule_runner.py
$ sudo -u nifi test -w /opt/etl/log/dwh-scheduler
```

I test di accesso devono terminare con codice `0`; non è necessario concedere
l'esecuzione a tutti gli utenti.

---

## 7. Database: creazione oggetti

Gli oggetti applicativi di tracciamento sono **già presenti** nello schema
`hcbi_utility` sull'ambiente corrente (verificato live su Postgres 17.0 il
2026-10-22): `etl_frontiere_config`, `etl_frontiere_run`,
`etl_frontiere_execution_lock`, `etl_dwh_refresh_run`. Le relative DDL
(allineate al DB) sono mantenute in `ddl/hcbi_utility/table/` in questo
repository, a scopo di riferimento/versionamento.

Per un **nuovo** ambiente, creare gli oggetti nell'ordine seguente (assumendo
che `hcbi_ras`/`hcbi_utility` e i ruoli omonimi esistano già):

```bash
$ psql "host=<DB_HOST> port=5432 dbname=hcbi user=hcbi" \
    -f ddl/hcbi_utility/table/etl_frontiere_config.sql
$ psql "host=<DB_HOST> port=5432 dbname=hcbi user=hcbi" \
    -f ddl/hcbi_utility/table/etl_frontiere_run.sql
$ psql "host=<DB_HOST> port=5432 dbname=hcbi user=hcbi" \
    -f ddl/hcbi_utility/table/etl_frontiere_execution_lock.sql
$ psql "host=<DB_HOST> port=5432 dbname=hcbi user=hcbi" \
    -f nifi/frontiere-metadata-runner/sql/01_create_hcbi_utility_etl_dwh_refresh_run.sql
```

Lo script `01_create_hcbi_utility_etl_dwh_refresh_run.sql` include anche le
`GRANT` necessarie (`SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES,
TRIGGER` sulla tabella, più i default privileges) per i ruoli `hcbi_utility` e
`hcbi_ras`.

Verifica runtime (presenza oggetti, grant, lock residui):

```bash
$ psql "host=<DB_HOST> port=5432 dbname=hcbi user=hcbi" \
    -f nifi/frontiere-metadata-runner/sql/02_verify_runtime.sql
```

Per lo scheduler DWH servono inoltre `hcbi_utility.dwh_schedule` e
`hcbi_utility.dwh_schedule_run`. In un nuovo ambiente applicare e verificare:

```bash
$ psql -v ON_ERROR_STOP=1 -d hcbi \
    -f nifi/Schedulazione_Caricamenti/deploy/postgresql/01_create_dwh_schedule.sql
$ psql -v ON_ERROR_STOP=1 -d hcbi \
    -f nifi/Schedulazione_Caricamenti/deploy/postgresql/02_verify_dwh_schedule.sql
```

Se si migra una precedente installazione con audit manuale non aggiornato,
applicare anche `03_add_manual_trigger_audit.sql` e poi ripetere la verifica,
come descritto in
`nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md`.
Inserire la schedulazione approvata usando gli esempi in
`nifi/Schedulazione_Caricamenti/doc/03_esempi_schedulazioni_dwh.md`; iniziare con
`enabled=false` e abilitarla solo dopo aver verificato i parametri. Verificare che
ci sia una sola riga abilitata e che calendario, giorno settimanale e retry siano
quelli approvati. Il DDL non inserisce una schedulazione iniziale.

Popolare/validare `hcbi_utility.etl_frontiere_config` con le frontiere da
attivare (`enabled=true`, `execution_order`, query sorgente) secondo le
esigenze del nuovo ambiente — vedere la vista di supporto
`ddl/hcbi_utility/view/vw_etl_frontiere_config.sql`.

---

## 8. Configurazione segreti (credenziali cifrate)

Il progetto non legge mai credenziali in chiaro da variabili d'ambiente: usa
un file JSON cifrato con Fernet (`config/fmr-secrets.json.enc` + chiave
`secrets/fmr-secrets.key`).

### 8.1 Creare il file in chiaro temporaneo

```bash
$ cp nifi/frontiere-metadata-runner/config/fmr-secrets.template.json /tmp/fmr-secrets.json
$ vi /tmp/fmr-secrets.json
```

Compilare (vedi struttura attesa in `scripts/secrets_common.py::REQUIRED`):

```json
{
  "nifi": {
    "base_url": "https://<NIFI_HOST>:8443/nifi",
    "username": "<nifi_user>",
    "password": "<nifi_password>",
    "verify_ssl": false
  },
  "rasop": {
    "jdbc_url": "jdbc:postgresql://<DB_HOST>:5432/RAS_Operazionales",
    "username": "<rasop_user>",
    "password": "<rasop_password>"
  },
  "hcbi": {
    "jdbc_url": "jdbc:postgresql://<DB_HOST>:5432/hcbi",
    "username": "<hcbi_user>",
    "password": "<hcbi_password>"
  }
}
```

### 8.2 Cifratura

```bash
$ cd /opt/etl/frontiere-metadata-runner
$ .venv/bin/python scripts/encrypt_fmr_secrets.py \
    --input /tmp/fmr-secrets.json \
    --key-file /opt/etl/secrets/fmr-secrets.key \
    --output /opt/etl/config/fmr-secrets.json.enc
$ shred -u /tmp/fmr-secrets.json   # eliminare il file in chiaro
$ chmod 0600 /opt/etl/secrets/fmr-secrets.key /opt/etl/config/fmr-secrets.json.enc
$ chown nifi:nifi /opt/etl/secrets/fmr-secrets.key /opt/etl/config/fmr-secrets.json.enc
```

### 8.3 Validazione

```bash
$ .venv/bin/python scripts/validate_fmr_secrets.py \
    --key-file /opt/etl/secrets/fmr-secrets.key \
    --encrypted-config /opt/etl/config/fmr-secrets.json.enc
```

Deve confermare: struttura valida, nessun placeholder residuo
(`CHANGE_ME`/`_HOST`), connessione Postgres reale riuscita su entrambi i DB.

### 8.4 Rotazione password

Ripetere 8.1–8.3 con i nuovi valori; non serve ridistribuire il process group
NiFi (le credenziali sono lette ad ogni esecuzione degli script).

---

## 9. Virtual environment Python

```bash
$ cd /opt/etl/frontiere-metadata-runner
$ python3.11 -m venv .venv
$ .venv/bin/pip install --upgrade pip
$ .venv/bin/pip install -r requirements.txt
$ .venv/bin/python -c "import psycopg, cryptography; print('OK')"
```

---

## 10. Deploy del flusso NiFi (process group)

Il process group **non va creato a mano**: si usa lo script di deploy, che lo
crea via REST API in stato `STOPPED` con tutti i processor, le connessioni e
le relationship auto-terminate già corrette.

```bash
$ cd /opt/etl/frontiere-metadata-runner
$ .venv/bin/python scripts/deploy_nifi_flow.py \
    --key-file /opt/etl/secrets/fmr-secrets.key \
    --encrypted-config /opt/etl/config/fmr-secrets.json.enc
```

Output atteso:

```text
[OK] Process Group creato STOPPED: FRONTIERE_METADATA_RUNNER (<id>)
[OK] Frontiere -> gate FMR_EXECUTION_UUID -> DWH chain 1; output senza marker terminato
```

Lo script **fallisce volutamente** se un process group con lo stesso nome
esiste già sotto root (va eliminato manualmente dalla UI prima di rilanciare,
per evitare doppioni).

### 10.1 Verifica nella UI NiFi

Aprire `FRONTIERE_METADATA_RUNNER`:
- 7 processor presenti: `Manual trigger`, `Run sequential full refresh`,
  `Gate DWH on frontiere success marker`, `Run DWH refresh chain 1`,
  `Log frontiere failed`, `Log DWH refresh completed`, `Log DWH refresh failed`
- `Run sequential full refresh` → gate sulla relationship `output stream`;
  gate → DWH sulla sola relationship `matched`
- Il gate estrae un UUID canonico `FMR_EXECUTION_UUID`; `unmatched` e `failure`
  sono auto-terminate. Non deve esistere una connessione diretta runner→DWH.
- Lo stdout del runner frontiere contiene solo il marker emesso dopo il successo
  completo delle frontiere; i log vanno su stderr e nel file
- Entrambi gli `ExecuteStreamCommand` hanno la relationship `original`
  auto-terminata
- `Run DWH refresh chain 1` ha **`Ignore STDIN = false`** e riceve il FlowFile
  inoltrato dal gate
- `Command Path` punta a `/opt/etl/frontiere-metadata-runner/.venv/bin/python`
  e `Command Arguments` agli script in `scripts/`

---

## 11. Scheduler DWH: automatico e manuale

Il timer automatico è `systemd`, non `cron`: `dwh-scheduler.timer` avvia ogni
giorno alle 03:00 (`Europe/Rome`) il runner in modalità `scheduled`. Il runner
consulta `hcbi_utility.dwh_schedule` e avvia FMR solo se il periodo è dovuto; se
il periodo è già concluso con successo registra `SKIPPED` senza avviare il flow.
Il timer è `Persistent=true`; l'installer lo copia ma non lo abilita né lo avvia.

### 11.1 Installare i componenti Linux

Con FMR, Python 3.11 e `bin/run_group_cycle.sh` già installati, dal checkout del
repository eseguire come root:

```bash
# cd nifi/Schedulazione_Caricamenti/deploy/unix-linux
# ./install_dwh_scheduler.sh
```

Rivedere `/etc/sysconfig/dwh-scheduler` (percorsi e timeout; non contiene
credenziali). L'installer la crea solo se assente, installa runner, launcher,
unità service/timer e configurazione logrotate, e lascia il timer disattivato.
Verificare anche unità e permessi:

```bash
# systemd-analyze verify /etc/systemd/system/dwh-scheduler.service \
    /etc/systemd/system/dwh-scheduler.timer
$ sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/.venv/bin/python
$ sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/bin/launch_manual_dwh_run.sh
$ sudo -u nifi test -r /opt/etl/frontiere-metadata-runner/scripts/dwh_schedule_runner.py
$ sudo -u nifi test -w /opt/etl/log/dwh-scheduler
```

I test di accesso devono terminare con codice `0`. Il `.py` passato all'interprete
deve essere leggibile; l'interprete e il launcher `.sh` devono essere eseguibili
da `nifi`, senza abilitare l'esecuzione a tutti gli utenti.

### 11.2 Creare il launcher UI

Creare `DWH_MANUAL_LAUNCH` una sola volta; lo script lo lascia `STOPPED` e non
avvia il refresh:

```bash
$ sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
    /opt/etl/frontiere-metadata-runner/scripts/deploy_manual_launcher.py
```

Se il gruppo esiste già, non rilanciare lo script: controllarlo nella UI.
Concedere agli operatori il permesso di start/stop su `DWH_MANUAL_LAUNCH`, non
su `FRONTIERE_METADATA_RUNNER`; l'identità API cifrata del runner deve poter
avviare e fermare il gruppo business.

### 11.3 Abilitare il timer

Dopo aver approvato la configurazione DB e la finestra operativa:

```bash
# systemctl enable --now dwh-scheduler.timer
# systemctl list-timers dwh-scheduler.timer
```

La valutazione immediata è facoltativa e non serve per abilitare il timer.
Eseguirla solo se si vuole deliberatamente avviare subito una valutazione
`scheduled`, in una finestra approvata: se la schedulazione è dovuta può partire
un refresh reale.

```bash
# systemctl start dwh-scheduler.service
```

### 11.4 Launcher manuale e monitoraggio

`DWH_MANUAL_LAUNCH` è un override manuale, non un controllo della scadenza:
ogni nuovo avvio riesegue frontiere e DWH anche se il periodo corrente è già
stato completato. Se non c'è un periodo dovuto, i campi del periodo in audit
sono nulli e `last_success_period_start` non avanza. Per ottenere `SKIPPED` dopo
un successo del periodo deve operare il timer in modalità `scheduled`; anche una
richiesta manuale può essere `SKIPPED` se il lock è occupato.

Monitorare timer, servizio, journal e audit:

```bash
# systemctl status dwh-scheduler.timer dwh-scheduler.service
# journalctl -u dwh-scheduler.service --since today
$ tail -n 100 /opt/etl/log/dwh-scheduler/dwh-scheduler.log
```

```sql
SELECT run_id, process_code, trigger_source, planned_date, period_start,
       status, started_at, finished_at, return_code, error_message
FROM hcbi_utility.dwh_schedule_run
ORDER BY started_at DESC
LIMIT 20;
```

Per i run del timer ci si aspetta `trigger_source='SCHEDULED'`; il launcher UI
registra `MANUAL_UI`. Per il deploy dettagliato, consultare
`nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md`.

---

## 12. Esecuzione FMR: UI oppure riga di comando

### 12.1 Avvio tecnico diretto da UI NiFi

1. Posizionarsi sul process group `FRONTIERE_METADATA_RUNNER`
2. Tasto destro → **Start**

> **Attenzione**: `Manual trigger` è uno `GenerateFlowFile` con
> `schedulingStrategy=TIMER_DRIVEN` e `schedulingPeriod=1 day`. Avviarlo
> genera subito un'esecuzione, ma se lasciato `Running` **si riattiva da solo
> ogni 24 ore**. Al termine del ciclo, fare **Stop** sul gruppo (o almeno sul
> processor `Manual trigger`) se non si desidera la ripetizione giornaliera
> automatica.
3. Il DWH refresh (`CALL hcbi_utility.prc_execute_chain(1)`) parte **solo**
   dopo che tutte le frontiere attive sono terminate con successo (vedi
   README §6 e §10 per la semantica di lock/skip).

L'avvio diretto di questo gruppo è riservato ai test tecnici: non applica la
scadenza di `dwh_schedule` e non crea una riga di audit `dwh_schedule_run`. Per
l'avvio manuale operativo usare `DWH_MANUAL_LAUNCH` (§11).

### 12.2 Da riga di comando (start → attesa → stop automatico)

Script dedicato `scripts/run_group_cycle.py` (wrapper `bin/run_group_cycle.sh`):
avvia il process group, attende la fine della fase frontiere leggendo
`hcbi_utility.etl_frontiere_run`, poi (se tutte le frontiere sono riuscite)
attende la fine del refresh DWH leggendo `hcbi_utility.etl_dwh_refresh_run`,
e ferma il gruppo al termine (o al timeout).

```bash
$ cd /opt/etl/frontiere-metadata-runner
$ ./bin/run_group_cycle.sh --frontiere-timeout 3600 --dwh-timeout 1800
```

Opzioni principali: `--pg-name`/`--pg-id` (se il nome differisce),
`--poll-interval`, `--quiet-seconds` (silenzio richiesto prima di considerare
chiusa la fase frontiere), `--no-stop` (debug, non ferma il gruppo).

Exit code: `0` tutto OK, `3` almeno una frontiera non riuscita (DWH non
avviato), `4` DWH fallito, `5` timeout, `6` errore generico, `7` stop del
gruppo fallito. Questo wrapper avvia il flow direttamente e non valuta la tabella
`dwh_schedule`; per le esecuzioni automatiche schedulate usare il timer descritto
in §11.

---

## 13. Verifica stato / monitoraggio da riga di comando

Script `scripts/check_group_status.py` (wrapper `bin/check_group_status.sh`):
mostra stato del process group, stato/thread attivi/code di ogni processor e
i bulletin NiFi recenti, senza passare dalla UI.

```bash
$ ./bin/check_group_status.sh
$ ./bin/check_group_status.sh --watch 5     # refresh ogni 5s, Ctrl+C per uscire
```

Per lo stato del servizio NiFi stesso vedere §5 (`bin/nifi_service.sh status`
/ `logs`).

Query dirette alle tabelle di tracciamento (utile per audit/storico):

```sql
SELECT * FROM hcbi_utility.etl_frontiere_run ORDER BY started_at DESC LIMIT 20;
SELECT * FROM hcbi_utility.etl_dwh_refresh_run ORDER BY started_at DESC LIMIT 10;
SELECT * FROM hcbi_utility.etl_frontiere_execution_lock;  -- deve essere vuota a riposo
```

---

## 14. Collaudo (smoke test)

Questo collaudo esegue un ciclo FMR diretto; non verifica la logica di scadenza
dello scheduler. Per i test di calendario usare quelli documentati nel manuale
scheduler (§11) e non avviare il timer come semplice test.

1. Verificare che `hcbi_utility.etl_frontiere_config` abbia almeno una riga
   `enabled=true` con `source_query` valida (solo `SELECT`/`WITH`, no `;`)
2. Lanciare un ciclo completo: `./bin/run_group_cycle.sh --no-stop`
3. Verificare:
   - `./bin/check_group_status.sh` mostra i processor in esecuzione e poi a
     riposo (code vuote, `activeThreadCount=0`)
   - `SELECT * FROM hcbi_utility.etl_frontiere_run` mostra righe `SUCCEEDED`
     per tutte le frontiere attive
   - `SELECT * FROM hcbi_utility.etl_dwh_refresh_run` mostra una riga
     `SUCCEEDED` con lo stesso `execution_uuid` presente in
     `etl_frontiere_run.nifi_flowfile_uuid`
   - log filesystem in `/opt/etl/log/frontiere-metadata-runner/*.log` coerenti
4. Fermare il gruppo: `bin/check_group_status.sh` seguito da Stop via UI,
   oppure rilanciare `run_group_cycle.sh` senza `--no-stop`
5. Eseguire i test minimi T01–T10 descritti in README §19 se si vuole una
   copertura completa (zero righe, errore sorgente, lock, concorrenza, ecc.)

---

## 15. Troubleshooting

| Sintomo | Causa probabile | Azione |
|---|---|---|
| `deploy_nifi_flow.py` fallisce con "Process Group gia esistente" | Deploy precedente non rimosso | Eliminare il PG dalla UI, rilanciare |
| NiFi non riesce a eseguire uno script o non produce log | L'utente OS del servizio NiFi non può eseguire l'interprete o il launcher, leggere lo script, oppure scrivere nella directory log | Verificare `User` di `nifi.service` e i comandi `test -x`, `test -r` e `test -w` eseguiti come `nifi` (§6 e §11); concedere i permessi minimi necessari |
| Un avvio manuale ripete un periodo già completato | `DWH_MANUAL_LAUNCH` forza l'esecuzione e ignora la scadenza | Comportamento previsto; usare il timer `systemd` in modalità `scheduled` per applicare la regola di skip (§11) |
| Il timer non avvia valutazioni | `dwh-scheduler.timer` non è abilitato oppure il servizio/configurazione ha errori | Verificare `systemctl list-timers`, `systemctl status` e `journalctl`; controllare `/etc/sysconfig/dwh-scheduler` e l'audit (§11) |
| Frontiera in stato `SKIPPED` | Lock per quel `frontiera_code` non acquisito (altra esecuzione in corso/residua) | Verificare `etl_frontiere_execution_lock`; se residua da crash, eliminare la riga manualmente dopo aver confermato che nessun processo è realmente attivo |
| Il DWH refresh non parte mai | Almeno una frontiera non `SUCCEEDED` nel ciclo (`run_frontiere.py` esce con codice ≠0 se c'è anche un solo `FAILED`/`SKIPPED`) | Controllare `etl_frontiere_run` per la riga non riuscita, correggere la causa, rilanciare |
| `run_group_cycle.py` termina con exit code 5 (timeout) | Query sorgente lenta, DB irraggiungibile, o timeout troppo basso | Alzare `--frontiere-timeout`/`--dwh-timeout`; controllare log `/opt/etl/log/frontiere-metadata-runner/` |
| Join/query rotte dopo una modifica di schema (es. rename colonna) | Una tabella a monte è stata modificata (es. `addendum`→`cd_versione`) senza propagare la modifica ai flussi a valle | Verificare tutti gli script in `doc/flussi/` che referenziano la tabella modificata |
| Browser mostra "Invalid SNI" o certificato non valido su `https://<NIFI_HOST>:8443` | Self-signed cert / hostname diverso da quello configurato | Accettare l'eccezione per test, oppure installare certificato valido con il hostname corretto; in alternativa tunnel SSH su `localhost` |
| `validate_fmr_secrets.py` segnala placeholder non sostituito | File JSON compilato parzialmente (valori `CHANGE_ME` o contenenti `_HOST`) | Ricompilare il file in chiaro, rifare §8.1–8.3 |
| Il ciclo sembra ripartire da solo il giorno dopo | `Manual trigger` lasciato `Running` (timer 1 day) | Fermarlo esplicitamente dopo ogni test diretto (§12.1) |

---

## 16. Rollback / disinstallazione

1. Disabilitare lo scheduler e fermare l'eventuale servizio: `systemctl disable --now dwh-scheduler.timer` e `systemctl stop dwh-scheduler.service`.
2. Fermare ed eliminare i process group dalla UI NiFi (Stop → Delete).
3. Rimuovere le unità `dwh-scheduler.service`, `dwh-scheduler.timer` e la
   configurazione logrotate, quindi eseguire `systemctl daemon-reload`. Conservare
   `/etc/sysconfig/dwh-scheduler` e i log/audit se si prevede una reinstallazione
   o serve lo storico.
4. Rimuovere la cartella applicativa: `rm -rf /opt/etl/frontiere-metadata-runner`
   (conservare `/opt/etl/secrets` e `/opt/etl/config` se si prevede un nuovo
   deploy con le stesse credenziali)
5. Gli oggetti DB (`etl_frontiere_*`, `etl_dwh_refresh_run`, `dwh_schedule`,
   `dwh_schedule_run`) **non** vengono
   rimossi automaticamente: eliminarli solo se richiesto esplicitamente,
   previo backup/estrazione dello storico (contengono l'audit trail delle
   esecuzioni)
6. Per disinstallare anche NiFi: `systemctl disable --now nifi.service`,
   rimuovere `/opt/nifi-2.11.0` e l'unit file systemd

---

## 17. Riferimenti

- `nifi/frontiere-metadata-runner/README.md` — architettura, gate del marker,
  permessi, semantica transazionale, logging, lock e test di accettazione
- `nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md` — DDL,
  installazione, attivazione, monitoraggio e rollback del timer DWH
- `nifi/Schedulazione_Caricamenti/doc/01_progettazione_scheduler_dwh.md` —
  progettazione e regole di schedulazione
- `nifi/frontiere-metadata-runner/scripts/` — tutti gli script Python citati
  in questo manuale
- `ddl/hcbi_utility/table/` — DDL correnti (allineate al DB) degli oggetti di
  tracciamento
- `config/nifi_server.md` — dati di connessione alla UI NiFi dell'ambiente
  corrente
