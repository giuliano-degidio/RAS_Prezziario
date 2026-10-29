# Manuale operativo — scheduler DWH

## Stato e avvertenza

Il database live è stato verificato in sola lettura il 2026-10-29: tabelle,
vincoli, indici, trigger e privilegi corrispondono alle DDL locali. Sono presenti
otto configurazioni distinte: `DWH_REFRESH_DAILY` è abilitata e le altre sette
sono disabilitate. L'ultimo run registrato è `MANUAL_UI` / `SUCCESS`.

L'utente riferisce di aver applicato le modifiche Linux e NiFi; il run manuale
riuscito è visibile nell'audit. Lo stato del timer systemd e il flow NiFi live
non sono stati interrogati direttamente. Non ripetere il deploy su questo host;
le istruzioni seguenti restano una procedura per installazioni nuove o future.

Percorso del pacchetto nel repository:

```text
nifi/Schedulazione_Caricamenti/deploy/
nifi/Schedulazione_Caricamenti/doc/
```

## Prerequisiti

- PostgreSQL 17 sul database `hcbi`; lo schema `hcbi_utility` deve già esistere.
- Ruolo applicativo `hcbi_ras` autorizzato sulle tabelle e sulla sequence; il login
  `hcbi` deve disporre dei privilegi direttamente o tramite membership.
- Host Linux con systemd, servizio NiFi e account `nifi:nifi`.
- FMR già installato in `/opt/etl/frontiere-metadata-runner`, con il suo
  virtualenv Python 3.11 in `.venv` e il wrapper `bin/run_group_cycle.sh`.
- File segreti FMR presenti nei percorsi dell'esempio e leggibili da `nifi`.
- Process Group `FRONTIERE_METADATA_RUNNER` importato e funzionante.

Non vengono installate dipendenze Python. Si riutilizza il virtualenv FMR.

## 1. Applicare e verificare il DDL

Verificare che lo schema `hcbi_utility` esista e che i nomi non siano già
occupati. Per una nuova installazione applicare, da una postazione autorizzata:

```bash
psql -v ON_ERROR_STOP=1 -d hcbi -f deploy/postgresql/01_create_dwh_schedule.sql
psql -v ON_ERROR_STOP=1 -d hcbi -f deploy/postgresql/02_verify_dwh_schedule.sql
```

Se le tabelle scheduler sono già state create con la versione precedente,
applicare prima la migrazione audit manuale e poi la verifica:

```bash
psql -v ON_ERROR_STOP=1 -d hcbi -f deploy/postgresql/03_add_manual_trigger_audit.sql
psql -v ON_ERROR_STOP=1 -d hcbi -f deploy/postgresql/02_verify_dwh_schedule.sql
```

Il DDL non crea lo schema, non inserisce una schedulazione iniziale e non
contiene dati sensibili. In caso di errore, fermarsi e correggere il problema.

Inserire la configurazione approvata con `enabled = false`, quindi controllare
frequenza e parametri. Esempio esclusivamente illustrativo per una schedulazione
quotidiana disabilitata:

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_DAILY', 'Refresh DWH', false, 'DAILY', NULL, NULL, NULL, NULL);
```

L'esempio non abilita il processo. `DAILY` non accetta parametri calendario o
retry; per le altre frequenze compilare le colonne richieste dai vincoli del
DDL. Abilitare una sola riga soltanto dopo aver approvato la regola e le date
attese: il trigger disabilita automaticamente la precedente.

Per gli esempi di tutte le frequenze, vedere
[`03_esempi_schedulazioni_dwh.md`](03_esempi_schedulazioni_dwh.md).

## 2. Installare i file Linux senza avviare il timer

Distribuire il repository sul server mantenendo la struttura delle cartelle.
Verificare il file `deploy/unix-linux/dwh-scheduler.env.example`, in
particolare i percorsi dei segreti e dei log. Poi, come root:

```bash
cd nifi/Schedulazione_Caricamenti/deploy/unix-linux
sudo ./install_dwh_scheduler.sh
```

L'installer copia il batch, il launcher manuale, l'helper di deploy NiFi, le unità
service/timer e la configurazione logrotate,
crea `/etc/sysconfig/dwh-scheduler` solo se assente e ricarica systemd. Non
abilita né avvia il timer o il servizio. Controllare i permessi dei file e
rivedere `/etc/sysconfig/dwh-scheduler`; non aggiungere password in chiaro.

### Deploy del launcher manuale NiFi

Dopo l'installazione dei file, creare il gruppo UI una sola volta tramite le
credenziali NiFi già configurate nel secrets cifrato FMR:

```bash
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/deploy_manual_launcher.py
```

Lo script crea `DWH_MANUAL_LAUNCH` e lo lascia `STOPPED`; non avvia il refresh.
Se il gruppo esiste già, non rilanciare lo script: controllare il gruppo esistente
nella UI. Concedere agli operatori autorizzati il permesso di avvio/stop su
`DWH_MANUAL_LAUNCH`, senza il permesso di avvio diretto su
`FRONTIERE_METADATA_RUNNER`. L'identità API usata dal runner deve invece poter
operare il gruppo business. Verificare che in UI siano visibili entrambi i gruppi.

Per una nuova installazione, non avviare il timer prima del test manuale: avvia
un vero ciclo ETL e va eseguito solo in una finestra approvata. Sul target live
un run manuale `SUCCESS` è già registrato nell'audit.


## 3. Verifiche prima dell'abilitazione

Eseguire i test di calendario con il Python del virtualenv FMR dalla cartella
`deploy/unix-linux`:

```bash
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  -m unittest -v test_dwh_schedule_runner.py
```

Controllare quindi unità e configurazione senza lanciare il batch:

```bash
sudo systemd-analyze verify /etc/systemd/system/dwh-scheduler.service \
  /etc/systemd/system/dwh-scheduler.timer
sudo systemctl status nifi.service
sudo -u nifi test -x /opt/etl/frontiere-metadata-runner/.venv/bin/python
sudo -u nifi test -r /opt/etl/secrets/fmr-secrets.key
sudo -u nifi test -r /opt/etl/config/fmr-secrets.json.enc
```

Confermare che:

- il runner si collega al database `hcbi` e usa `hcbi_utility`;
- vi è una sola riga di schedulazione abilitata e i suoi parametri sono corretti;
- il Process Group è fermo prima di ogni avvio automatico;
- nessuna esecuzione manuale o batch è già in corso;
- `nifi` può creare e scrivere il log scheduler e leggere i segreti FMR.

Il lock è comune ai run pianificati e manuali. Se il lock è occupato, il runner
systemd riprova per un massimo predefinito di due ore; una richiesta manuale
concorrente viene invece registrata `SKIPPED` e termina senza avviare il flow.
Una prova funzionale del lock o del launcher può avviare il refresh reale:
eseguirla solo con approvazione e in una finestra controllata.

## 4. Abilitazione controllata

Questa procedura vale per una nuova installazione. Sul target live, verificare
prima lo stato effettivo del timer: non abilitarlo o riavviarlo alla cieca. Per
un nuovo host, concordare data di attivazione, finestra giornaliera e rollback;
l'abilitazione può avviare il caricamento alla prima scadenza utile e richiede
approvazione operativa:

```bash
sudo systemctl enable --now dwh-scheduler.timer
sudo systemctl list-timers dwh-scheduler.timer
```

Non usare `systemctl start dwh-scheduler.service` come test generico: il batch
valuta la data corrente e può avviare subito il refresh se è dovuto.

## 5. Monitoraggio e diagnosi

```bash
sudo systemctl status dwh-scheduler.timer dwh-scheduler.service
sudo journalctl -u dwh-scheduler.service --since today
sudo tail -n 100 /opt/etl/log/dwh-scheduler/dwh-scheduler.log
```

`hcbi_utility.dwh_schedule_run` è la fonte di audit: `trigger_source` distingue
`SCHEDULED` da `MANUAL_UI`; `requested_by` riporta il canale `NiFi-UI`, non
l'utente autenticato. `SKIPPED` può significare data non dovuta/fuori retry o
lock occupato; `RUNNING`, `SUCCESS` e `FAILED` descrivono il ciclo. Se non esiste
una schedulazione abilitata, manca uno `schedule_id` e l'errore resta nel log.
Errori prima di poter scrivere l'audit (per esempio segreti illeggibili o DB non
disponibile) si diagnosticano nel log, non nella tabella.

Se un run resta `RUNNING` dopo un'interruzione, il successivo avvio dello
scheduler lo riconcilia a `FAILED`. Prima di rilanciare, verificare nella UI
NiFi e nell'audit/log che non sia ancora in corso un refresh.

## 6. Avvio manuale dalla UI NiFi

1. Verificare che esista una schedulazione abilitata e che non vi siano run
   `RUNNING` o refresh già in corso.
2. Nella UI avviare il Process Group `DWH_MANUAL_LAUNCH`. L'orchestratore
   ignora la data pianificata, usa il lock condiviso e registra il run con
   origine `MANUAL_UI`; quindi avvia il wrapper FMR standard.
3. Il gruppo launcher dovrebbe tornare rapidamente `STOPPED`. Il refresh
   prosegue in background: controllare `hcbi_utility.dwh_schedule_run` e il
   log, non lo stato del launcher, per conoscerne l'esito.
4. Se il launcher resta attivo, fermarlo dalla UI e controllare il log prima di
   riprovare. Non avviare direttamente `FRONTIERE_METADATA_RUNNER`.

Il Process Group business `FRONTIERE_METADATA_RUNNER` rimane visibile e
inalterato. Il suo `GenerateFlowFile` (periodo di un giorno) resta un trigger
tecnico usato dal wrapper, non un punto di accesso per operatori. Il gruppo
`DWH_MANUAL_LAUNCH` è il solo entry point manuale UI: il suo trigger invia una
richiesta e il runner lo ferma. Se il run manuale coincide con un periodo dovuto,
un successo aggiorna quel periodo; fuori finestra non consuma una scadenza
futura. Per evitare run senza lock/audit, non avviare il wrapper FMR o il gruppo
business manualmente al di fuori di questo percorso.

## 7. Rollback

Per sospendere nuove valutazioni automatiche:

```bash
sudo systemctl disable --now dwh-scheduler.timer
sudo systemctl stop dwh-scheduler.service
```

Verificare che il servizio sia inattivo e controllare il Process Group nella UI
NiFi. Il rollback non annulla un refresh già avviato né rimuove le tabelle di
audit/configurazione. Non eliminare le tabelle mentre `dwh_schedule_run` contiene
record o il servizio è installato. Le operazioni distruttive e la rimozione del
DDL richiedono un piano separato e un backup.
