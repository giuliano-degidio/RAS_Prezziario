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

Fine riepilogo.
