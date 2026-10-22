# Riassunto chat - RAS_Prezziario


## 1) Connessione PostgreSQL hcbi

- Creata la connessione Lens SQL `hcbi` verso PostgreSQL su 192.168.248.135:5432.
- DB: `hcbi`
- Utente: `hcbi`
- Schema: `hcbi_ras`, `hcbi_utility`
- È stato chiarito che i dettagli di connessione non erano persistiti nel progetto come file.

## 2) Esportazione DDL dallo schema hcbi_ras e hcbi_utility

- Sono state estratte e salvate le DDL delle tabelle, viste, procedure, funzioni e sequence di:
  - `hcbi_ras`
  - `hcbi_utility`
- I file sono stati organizzati nella cartella `ddl/` con sottocartelle per tipo oggetto.
- Per `hcbi_utility` sono stati aggiunti anche i tipi compositi trovati.

## 3) GitHub / repository

- Il progetto Atlas `RAS_Prezziario` è collegato al repo GitHub `giuliano-degidio/RAS_Prezziario` sul branch `main`.
- È stato risolto il problema dei push 403: Git stava usando un credential helper diverso da `gh auth git-credential`.
- Soluzione definitiva: forzare Git a usare `gh` per il push.
- È stato creato l’alias locale `git pushgh` nel repository.
- Il repo è stato aggiornato con vari commit, tra cui:
  - DDL esportate
  - comando Atlas per DWH Flowforge
  - roadmap NiFi
  - file di mapping `rasop_to_frontiera.csv`
  - file SQL di mapping `sql/rasop_to_frontiera/*.sql`

## 4) Credenziali locali nel .git/config

- Sono stati salvati nel `.git/config` locale del repo alcuni parametri di connessione:
  - `hcbi.*`
  - `ras-operazionale.*`
- È stato creato l’alias `git hcbi` per visualizzare la sezione `hcbi.*`.
- È stato creato un alias simile per `ras-operazionale`.

## 5) Comando Atlas `dwh-flowforge-architect`

- È stato creato il comando riutilizzabile `/dwh-flowforge-architect`.
- È stato usato il file specifica:
  - `specs/dwh_flowforge_architect.md`
- Il comando serve per analisi e progettazione DWH con regole rigorose su mapping, chiavi, SCD, controlli, audit, test, deployment e rollback.

## 6) Roadmap NiFi

- È stato creato il documento:
  - `specs/nifi_dwh_roadmap.md`
- Contiene la roadmap per usare Apache NiFi come layer di trasferimento dati da `rasop` a `hcbi`.
- Include:
  - obiettivo
  - fasi di analisi tecnica
  - installazione NiFi
  - progettazione dei flow
  - esecuzione controllata
  - industrializzazione
  - prerequisiti per NiFi Server

## 7) Confronto tabelle frontiera tra hcbi e rasop

- È stata creata la connessione Lens `rasop`.
- In seguito è stata corretta la connessione verso il database effettivo `RAS_Operazionales`.
- È stata prodotta una mappa di corrispondenza tra tabelle `frontiera_*` di `hcbi` e tabelle analoghe di `rasop`.
- È stato creato il file CSV:
  - `exports/rasop_to_frontiera.csv`
- Dentro al CSV sono state aggiunte note specifiche per:
  - `frontiera_anag_ateco_2002` -> tabella statica
  - `frontiera_firenze_analisi` -> importata da foglio Excel
  - `frontiera_firenze_articoli` -> importata da foglio Excel

## 8) Query SQL di caricamento da rasop a frontiera

- È stata creata la cartella:
  - `sql/rasop_to_frontiera/`
- Sono stati generati 18 file SQL, uno per tabella `frontiera_*`.
- I file contengono query `INSERT ... SELECT` da `rasop` verso le tabelle frontiera di `hcbi` con conversioni/cast dove necessario.
- Per alcune tabelle, in particolare quelle Excel-driven, sono stati creati template best-effort o note statiche, perché non completamente derivabili solo da `rasop`.

## 9) Connessione locale `rasop` nel .git/config

- È stata salvata nel `.git/config` una sezione locale `ras-operazionale.*` con:
  - host `192.168.248.135`
  - porta `5432`
  - database `RAS_Operazionales`
  - utente `postgres`
  - password `bitbros`
  - schema `public`
- È stata aggiunta una voce alias per richiamare la configurazione.

## 10) Installazione e configurazione NiFi su Oracle Linux 8.10

- La macchina ospite è Oracle Linux Server 8.10.
- Java 17 era già presente; NiFi 2.11.0 richiedeva Java 21.
- È stato installato `java-21-openjdk-headless` e selezionato Java 21 per NiFi.
- NiFi è stato scaricato e installato manualmente sotto `/opt/nifi-2.11.0`.
- NiFi è stato configurato per avviarsi come servizio systemd `nifi.service`.
- Il firewall `firewalld` era attivo e la porta `8443/tcp` è stata aperta.
- È stato risolto il problema di accesso HTTPS:
  - NiFi inizialmente rispondeva su `localhost`
  - poi è stato esposto su `0.0.0.0` / IP macchina
  - il browser Windows dava `Invalid SNI`
- È stato chiarito che il problema era nel certificato/self-signed e nel nome host usato.
- È stato spiegato come accedere via tunnel SSH e come gestire la UI NiFi via browser.
- È stata anche cambiata la single-user credential di NiFi con un username/password personalizzati.

## 11) Stato attuale NiFi

- NiFi risulta installato e avviato come servizio.
- La UI è accessibile via HTTPS.
- Il riavvio automatico al boot è stato configurato via systemd.
- Rimaneva aperto il tema della configurazione TLS/SNI per accesso diretto via IP.

## 12) Migrazione campo `addendum` → `cd_versione`

- In quattro flussi sotto `doc/flussi/` il campo `addendum` doveva diventare
  `cd_versione SMALLINT` a partire dallo staging in poi (lasciando invariato
  il livello raw/frontiera dove presente):
  - `flusso_anag_provincia_all_ver_03.sql`
  - `flusso_anag_area_vasta_all_ver_02.sql`
  - `flusso_dim_area_vasta_all_ver_02.sql`
  - `flusso_dim_provincia_all_ver_05.sql`
- Per ciascuno è stata prodotta una copia corretta `*_new.sql` nella cartella
  `doc/flussi_appo/`, con analisi di impatto a cascata (es. il rename in
  `dim_area_vasta` ha richiesto la correzione del JOIN nel flusso
  `dim_provincia`) e, dove serviva, aggiunta la funzione di conversione
  `hcbi_ras.try_smallint(text)`.
- Nota: lo skill `dwh-flowforge-architect` richiesto per questi task non
  risulta disponibile nell'ambiente; il lavoro è stato svolto manualmente con
  gli strumenti DB/file/git standard.

## 13) Progetto NiFi `frontiere-metadata-runner`: verifica e automazione

- Verificata l'architettura del flusso NiFi (`FRONTIERE_METADATA_RUNNER.json`):
  il refresh DWH (`CALL hcbi_utility.prc_execute_chain(1)`) parte solo dopo il
  completamento con successo del caricamento frontiere, sia a livello di
  topologia NiFi (relationship `output stream`) sia a livello di codice
  (`run_dwh_refresh.py` legge l'UUID di esecuzione dallo stdin prodotto da
  `run_frontiere.py` a fine ciclo) — nessuna esecuzione parallela o anticipata.
- Chiarito che avviare il process group dalla UI ("Start" sul gruppo) non
  causa parallelismo, ma che il processor `Manual trigger` è schedulato a
  timer (`1 day`): se lasciato `Running` si riattiva automaticamente ogni 24
  ore e va fermato esplicitamente dopo l'uso.
- Aggiunti nuovi script in `nifi/frontiere-metadata-runner/`:
  - `scripts/run_group_cycle.py` + `bin/run_group_cycle.sh`: avvia il process
    group da riga di comando, attende il completamento leggendo le tabelle
    `hcbi_utility.etl_frontiere_run` / `etl_dwh_refresh_run`, poi ferma il
    gruppo automaticamente (con exit code distinti per i vari esiti/timeout).
  - `scripts/check_group_status.py` + `bin/check_group_status.sh`: stato del
    process group/processor (thread attivi, code, bulletin) via REST API.
  - `bin/nifi_service.sh`: wrapper `systemctl`/`journalctl` per gestire il
    servizio `nifi.service` (start/stop/restart/status/logs).
- Creato il manuale operativo `doc/deploy/MANUALE_DEPLOY_NIFI.md`, pensato per
  il sistemista: installazione NiFi, gestione servizio, setup filesystem/DB/
  segreti/venv, deploy del process group, esecuzione da UI e da CLI,
  monitoraggio, collaudo, troubleshooting e rollback. Verificato a DB live
  (PostgreSQL 17.0) che gli oggetti di tracciamento in `hcbi_utility`
  (`etl_frontiere_config`, `etl_frontiere_run`, `etl_frontiere_execution_lock`,
  `etl_dwh_refresh_run`) sono allineati alle DDL già presenti in
  `ddl/hcbi_utility/table/`.
- Rilevata una cartella `appo-nifi/frontiere-metadata-runner` nel repo
  (committata il 16/10), parzialmente divergente da
  `nifi/frontiere-metadata-runner` (README diverso, script CLI mancanti):
  probabile copia di staging residua, da valutare se rimuovere.

Fine riepilogo.
