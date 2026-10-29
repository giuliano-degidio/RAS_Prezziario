# Manuale Operativo per lo Sviluppo dei Flussi — Progetto RAS_Prezziario

Componente di Data Management

---

## Sommario

1. [Introduzione](#1-introduzione)
   - 1.1 [Scopo del documento](#11-scopo-del-documento)
2. [Architettura](#2-architettura)
   - 2.1 [Database PostgreSQL di riferimento](#21-database-postgresql-di-riferimento)
   - 2.2 [Schemi e layer](#22-schemi-e-layer)
3. [Step per l'implementazione di un nuovo flusso](#3-step-per-limplementazione-di-un-nuovo-flusso)
   - 3.1 [Step sulle tabelle](#31-step-sulle-tabelle-ddl)
   - 3.2 [Step sulle procedure (STG / DWH / DIM)](#32-step-sulle-procedure-stg--dwh--dim)
   - 3.3 [Funzioni di conversione (`try_*`)](#33-funzioni-di-conversione-try_)
   - 3.4 [Registrazione del flusso nell'orchestratore](#34-registrazione-del-flusso-nellorchestratore)
4. [Caricamento dinamico frontiera: `run_frontiere.py`](#4-caricamento-dinamico-frontiera-run_frontierepy)
5. [HCBI_UTILITY: motore di schedulazione e orchestrazione](#5-hcbi_utility-motore-di-schedulazione-e-orchestrazione)
   - 5.1 [Tabelle di configurazione](#51-tabelle-di-configurazione)
   - 5.2 [Tabelle di log](#52-tabelle-di-log)
   - 5.3 [Procedure di orchestrazione](#53-procedure-di-orchestrazione)
   - 5.4 [Schedulazione DWH con systemd](#54-schedulazione-dwh-con-systemd)
6. [Orchestrazione NiFi e scheduler DWH](#6-orchestrazione-nifi-e-scheduler-dwh)
7. [Notifiche](#7-notifiche)
8. [Git: versioning del software](#8-git-versioning-del-software)
9. [Riferimenti](#9-riferimenti)

---

## 1. Introduzione

### 1.1 Scopo del documento

Il documento fornisce le istruzioni operative per sviluppare, configurare ed
eseguire nuovi flussi di acquisizione/integrazione dati nel progetto
**RAS_Prezziario**, seguendo le convenzioni già adottate nei flussi esistenti
(`doc/flussi/`), nelle DDL (`ddl/`) e nell'orchestrazione (`hcbi_utility` +
NiFi). È rivolto a chi deve realizzare un nuovo flusso o manutenere quelli
esistenti.

---

## 2. Architettura

### 2.1 Database PostgreSQL di riferimento

| Elemento | Valore |
|---|---|
| Motore | PostgreSQL 17 |
| Host | `192.168.248.135` |
| Porta | `5432` |
| Database applicativo | `hcbi` |
| Database sorgente | `RAS_Operazionales` (stesso host) |
| Linguaggio procedurale | PL/pgSQL |
| Orchestrazione ETL | Apache NiFi 2.11; timer systemd giornaliero e calendario DWH in PostgreSQL |
| Reportistica | Pentaho, Power BI |

A differenza di architetture a "uno schema per modulo" (es. Oracle
`HCBI_XXX`), in RAS_Prezziario **tutti i flussi condividono due soli schemi**:

- `hcbi_ras` — dati (tabelle di ogni layer, procedure, viste, funzioni)
- `hcbi_utility` — orchestrazione, configurazione, logging trasversale a
  tutti i flussi

Non esiste quindi uno script di "creazione schema per nuovo modulo": un nuovo
flusso aggiunge solo oggetti dentro `hcbi_ras` (tabelle + procedure) e righe
di configurazione dentro `hcbi_utility`.

### 2.2 Schemi e layer

Ogni flusso attraversa 5 layer, ciascuno con convenzione di naming fissa
(`<layer>_<entità>`):

| Layer | Prefisso tabella | Scopo |
|---|---|---|
| Frontiera | `frontiera_<entità>` | Copia grezza 1:1 della sorgente esterna (tutto testo/VARCHAR) |
| Src tmp | `src_tmp_<entità>` (spesso solo vista `v_src_tmp_<entità>`) | Normalizzazione minima prima dello staging |
| Staging | `stg_<entità>` / `stg_<entità>_rej` | Dati tipizzati e validati; righe scartate in tabella `_rej` parallela |
| DWH | `dwh_<entità>` | Storico integrato, tipizzato, con chiavi tecniche |
| Dimensione/Fact | `dim_<entità>` / `fct_<entità>` | Modello dimensionale per il reporting |

Esempio reale completo (famiglia `anag_utenti`): `frontiera_anag_utenti` →
`v_src_tmp_anag_utenti` → `stg_anag_utenti`/`stg_anag_utenti_rej` →
`dwh_anag_utenti` → `dim_utenti`.

---

## 3. Step per l'implementazione di un nuovo flusso

### 3.1 Step sulle tabelle (DDL)

1. Creare (se non esiste già una sorgente frontiera) `hcbi_ras.frontiera_<entità>`
   con tutte le colonne come `VARCHAR`/testo, a specchio della sorgente.
2. Creare la vista `hcbi_ras.v_src_tmp_<entità>` (o tabella `src_tmp_`) che
   seleziona dalla frontiera applicando solo `trim`/`nullif`, senza cast.
3. Creare `hcbi_ras.stg_<entità>` (colonne tipizzate finali) e
   `hcbi_ras.stg_<entità>_rej` (stesse colonne della frontiera + colonna
   `tx_motivo_scarto TEXT`).
4. Creare `hcbi_ras.dwh_<entità>` (tipizzata, con chiave tecnica e colonne di
   versioning/audit se richiesto, es. `cd_versione SMALLINT`).
5. Creare `hcbi_ras.dim_<entità>` (o `fct_`) per il modello dimensionale.
6. Salvare ogni DDL in `ddl/hcbi_ras/table/<nome_tabella>.sql`, un file per
   oggetto, e mantenerlo allineato alla definizione effettiva sul DB. Non inserire
   credenziali o altri segreti nelle DDL versionate.

### 3.2 Step sulle procedure (STG / DWH / DIM)

Convenzione di naming procedure: `hcbi_ras.pkg_<layer>_<entità>_prc_<fase>`,
dove `<fase>` è una delle tre riconosciute dall'orchestratore (vedi §5.3):
`prc_initialize`, `prc_main`, `prc_finalize` (anche solo `prc_main` se le
altre due non servono).

Firma standard (riutilizzata identica in tutti i flussi esistenti):

```sql
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_<entità>_prc_main(
    IN  p_id_chain_log   bigint,
    IN  p_id_chain        bigint,
    IN  p_id_step         bigint,
    IN  p_ds_step_name    varchar,
    OUT p_result          integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
...
$procedure$
```

Struttura interna obbligatoria (vedi `pkg_stg_anag_utenti_prc_main.sql` come
riferimento completo):

1. `p_result := -1;` a inizio procedura (default pessimista).
2. Apertura log con `hcbi_utility.pkg_log_fnc_insert_log(...)` → `v_id_log`.
3. Classificazione in tabella temporanea (`CREATE TABLE hcbi_ras.tmp_...`,
   non `TEMP TABLE` di sessione) con CTE `src` (raw) → `converted` (cast via
   `try_*`) → SELECT finale con colonna `tx_motivo_scarto` (NULL = riga
   valida).
4. `INSERT` verso la tabella target filtrando `tx_motivo_scarto IS NULL`.
5. `INSERT` verso la tabella `_rej` filtrando `tx_motivo_scarto IS NOT NULL`.
6. Riconciliazione conteggi: `selected = inserted + rejected`, altrimenti
   `RAISE EXCEPTION`.
7. Chiusura log con `hcbi_utility.pkg_log_prc_update_log(...)`.
8. `DROP TABLE` della temporanea, poi `p_result := 1;`.
9. Blocco `EXCEPTION WHEN OTHERS` che: cattura
   `SQLSTATE/MESSAGE_TEXT/DETAIL/HINT/CONTEXT` via `GET STACKED DIAGNOSTICS`,
   tenta comunque il cleanup della temporanea, registra l'errore con
   `hcbi_utility.pkg_log_prc_error_update_log(...)`, e fa `RAISE WARNING`
   (mai `RAISE EXCEPTION` qui, altrimenti la chain non riceve lo stato FAILED
   in modo pulito).

Salvare ogni procedura in
`ddl/hcbi_ras/procedure/pkg_<layer>_<entità>_prc_<fase>.sql`.

### 3.3 Funzioni di conversione (`try_*`)

Per ogni cast testo→tipo nel layer STG usare le funzioni già disponibili in
`hcbi_ras` (mai un cast diretto `::tipo`, che solleva eccezione sui valori non
validi invece di scartare la riga):

`try_bigint`, `try_integer`, `try_smallint`, `try_double_precision`,
`try_numeric_10_0`, `try_numeric_10_5`, `try_numeric_24_5`,
`try_numeric_24_6`, `try_timestamp`, `try_boolean_integer`,
`try_boolean_smallint`, `try_flag_smallint`, più alcune varianti dominio
specifiche (`try_anag_um_*`).

Se serve un nuovo tipo di conversione non coperto, crearne una nuova con lo
stesso pattern (`RETURN NULL` su eccezione invece di propagarla) e salvarla in
`ddl/hcbi_ras/function/try_<tipo>.sql`.

### 3.4 Registrazione del flusso nell'orchestratore

Dopo aver creato tabelle e procedure, il flusso va agganciato
all'orchestratore `hcbi_utility` (vedi §5 per i dettagli):

1. Se il flusso fa parte di una chain esistente (es. chain DWH `id_chain=1`),
   aggiungere una riga in `hcbi_utility.srv_config_step` con
   `ds_package_name` = nome della procedura, `nr_step_order` coerente con le
   dipendenze (`id_dependency_step`), `fl_blocking` secondo necessità.
2. Se il flusso è un nuovo caricamento frontiera (fonte esterna →
   `hcbi_ras.frontiera_*`), aggiungere una riga in
   `hcbi_utility.etl_frontiere_config` (vedi §4): nessuna modifica al codice
   Python è necessaria, il loop legge la configurazione a runtime.

La configurazione della chain (`srv_config_chain`/`srv_config_step`), quella delle
frontiere (`etl_frontiere_config`) e il calendario del ciclo completo
(`dwh_schedule`, §5.4) sono livelli distinti. La schedulazione DWH riguarda il
ciclo frontiere + chain 1 nel suo complesso: non si crea una riga di calendario
per ogni tabella o frontiera.

---

## 4. Caricamento dinamico frontiera: `run_frontiere.py`

Non esiste un package PL/pgSQL generico di copia dinamica (l'equivalente
concettuale di un `PKG_COPY_DATA_SRC_DYNAMIC`): la copia da `RAS_Operazionales`
alle tabelle `hcbi_ras.frontiera_*` è realizzata dallo script Python
`nifi/frontiere-metadata-runner/scripts/run_frontiere.py`, guidato interamente
da riga di configurazione in `hcbi_utility.etl_frontiere_config`:

| Colonna | Significato |
|---|---|
| `frontiera_code` | chiave, nome logico della frontiera |
| `enabled` | se `false` il flusso viene ignorato |
| `execution_order` | ordine di esecuzione tra le frontiere |
| `source_service_code` | deve essere `'RASOP'` (unico sorgente supportato oggi) |
| `source_query` | `SELECT`/`WITH` puro (no `;`, validato a runtime) eseguito su `RAS_Operazionales` |
| `target_schema` | deve essere `'hcbi_ras'` |
| `target_table` | nome tabella frontiera di destinazione (validato con regex identificatore Postgres) |
| `truncate_before_load` | deve essere `true` (full refresh, unica modalità supportata) |

Per aggiungere una nuova frontiera **non serve scrivere codice**: basta
inserire una riga in questa tabella con la query sorgente e il nome tabella
target (già esistente, creata come da §3.1). Lo script gestisce da solo lock
per-frontiera, log in `hcbi_utility.etl_frontiere_run`, riconciliazione righe
lette/scritte e gestione zero-righe (warning, non errore).

Il runner esegue le frontiere attive in sequenza. Se una frontiera termina con
`FAILED` o `SKIPPED`, `run_frontiere.py` non emette il marker di successo e
restituisce un codice non-zero; in questo caso il gate NiFi non inoltra il
FlowFile al refresh DWH (§6). A ciclo riuscito, stdout è riservato al marker
`FMR_EXECUTION_UUID=<uuid>`; i log applicativi vanno su stderr e nel file.

---

## 5. HCBI_UTILITY: motore di schedulazione e orchestrazione

### 5.1 Tabelle di configurazione

| Tabella | Scopo |
|---|---|
| `srv_config_chain` | catalogo delle chain (`id_chain`, nome, attiva/disattiva) |
| `srv_config_step` | step di ogni chain, in ordine (`nr_step_order`), con dipendenze (`id_dependency_step`), flag bloccante/non bloccante, retry |
| `srv_metadata_copy_src` | metadati di copia legati a una chain (sorgente → tabella temp target) |
| `etl_frontiere_config` | configurazione del caricamento frontiere (§4) |
| `dwh_schedule` | frequenza, calendario, retry e ultimo periodo riuscito del ciclo DWH; al massimo una riga abilitata |
| `cfg_connections` | connessioni esterne configurate (es. dblink) |

### 5.2 Tabelle di log

| Tabella | Scopo |
|---|---|
| `log_chain` | una riga per esecuzione di chain (`dt_start`, `dt_end`, `ds_status`, `etl_execution_uuid` — correlato all'esecuzione NiFi, vedi §6) |
| `log_step` | una riga per step eseguito all'interno di una chain (conteggi `nr_rec_selected/inserted/updated/deleted/errors`, stato, errore) |
| `etl_frontiere_run` | log per singola frontiera caricata (righe lette/scritte, stato, `nifi_flowfile_uuid`) |
| `etl_frontiere_execution_lock` | lock applicativo per frontiera, a riposo deve essere sempre vuota |
| `etl_dwh_refresh_run` | log per esecuzione della chain DWH lanciata da NiFi (`execution_uuid`, `chain_id`, stato `RUNNING`/`SUCCEEDED`/`FAILED`/`SKIPPED`) |
| `dwh_schedule_run` | audit del runner scheduler: un tentativo per avvio, con `trigger_source` (`SCHEDULED`/`MANUAL_UI`), periodo, stato (`RUNNING`/`SUCCESS`/`FAILED`/`SKIPPED`) ed errore |

### 5.3 Procedure di orchestrazione

- **`hcbi_utility.prc_start_chain(p_id_chain, OUT p_id_log)`** — verifica che
  la chain non sia già `IN_PROGRESS`, apre una riga in `log_chain` via
  `dblink` (connessione `LOG_DBLINK`, cosicché il log sopravviva anche se la
  chain fallisce e fa rollback).
- **`hcbi_utility.prc_execute_chain(p_id_chain)`** — punto di ingresso
  principale (è questa la procedura invocata da NiFi, `CALL
  hcbi_utility.prc_execute_chain(1)`):
  1. valida il parametro e l'esistenza/attivazione della chain;
  2. acquisisce un **lock applicativo** (`pg_try_advisory_xact_lock`) per
     impedire esecuzioni concorrenti della stessa chain, più un controllo
     aggiuntivo su righe `IN_PROGRESS` residue in `log_chain`;
  3. imposta tuning di sessione (`work_mem`, `maintenance_work_mem` — da
     adattare alle risorse del server, vedi commento `ATTENZIONE` nel
     sorgente);
  4. apre il log chain propagando `etl_execution_uuid` se disponibile
     dall'orchestratore esterno (NiFi);
  5. itera gli step attivi di `srv_config_step` in ordine, invocando la
     procedura `ds_package_name` di ciascuno per le fasi
     `prc_initialize`/`prc_main`/`prc_finalize` presenti, rispettando
     `id_dependency_step` e `fl_blocking` (uno step bloccante fallito ferma
     la chain, uno non bloccante la lascia proseguire registrando l'errore);
  6. chiude il log chain con stato finale coerente.
- **`hcbi_utility.prc_end_chain(...)`** — chiusura esplicita del log chain
  (stato, messaggio errore).
- **`hcbi_utility.pkg_log_prc_update_log` / `pkg_log_prc_error_update_log`** —
  utility di logging a livello di step, usate da ogni procedura `prc_main`
  (vedi pattern in §3.2).

> Dettaglio completo (786 righe) in
> `ddl/hcbi_utility/procedure/prc_execute_chain__bigint.sql`.

La schedulazione non sostituisce queste procedure e non modifica il modello delle
chain: decide quando avviare il ciclo NiFi. Quando il ciclo è dovuto, il runner
utilizza il wrapper FMR, che invoca il Process Group; il processor DWH continua a
chiamare `hcbi_utility.prc_execute_chain(1)`.

### 5.4 Schedulazione DWH con systemd

Il calendario del refresh completo è conservato in
`hcbi_utility.dwh_schedule`; i tentativi e i relativi esiti sono registrati in
`hcbi_utility.dwh_schedule_run`. Il DDL crea vincoli per le frequenze supportate
(`DAILY`, `WEEKLY`, `MONTHLY`, `BIMONTHLY`, `QUARTERLY`, `FOUR_MONTHLY`,
`SEMIANNUAL`, `ANNUAL`) e ammette al massimo una configurazione abilitata. Il DDL
non inserisce righe: frequenza, giorno, settimana del mese, mese di ancoraggio e
finestra di retry vanno concordati e configurati esplicitamente. Senza una riga
abilitata il runner segnala un errore nei log e non può creare un tentativo con
`dwh_schedule_run`, perché manca lo `schedule_id` da associare all'audit.

Il timer `dwh-scheduler.timer` si attiva ogni giorno alle 03:00
(`Europe/Rome`, `Persistent=true`). L'orario del timer è solo il momento in cui
il runner valuta il calendario: è `dwh_schedule` a stabilire se il ciclo è dovuto.
La modalità automatica `scheduled` registra `SKIPPED` senza avviare NiFi quando
la data non è dovuta, il retry è scaduto o il periodo logico è già stato
completato con successo.

Il runner Python usa il virtualenv FMR, carica i segreti cifrati, acquisisce un
advisory lock globale e, quando previsto, invoca `bin/run_group_cycle.sh`. Il
runner schedulato attende il lock fino al timeout configurato (due ore di
default); dopo il ciclo registra `SUCCESS` o `FAILED` in `dwh_schedule_run`.
Un'interruzione può lasciare un tentativo `RUNNING`, riconciliato a `FAILED` al
successivo avvio.

L'avvio manuale operativo passa invece dal Process Group `DWH_MANUAL_LAUNCH`,
che lancia lo stesso runner in modalità `manual-ui`. Questa modalità richiede una
configurazione abilitata ma ignora la data pianificata: ogni richiesta può
rieseguire frontiere e DWH anche dopo un successo dello stesso periodo. Se non
c'è un periodo dovuto, i campi del periodo restano nulli e
`last_success_period_start` non avanza. Se il lock è occupato, la richiesta
manuale termina come `SKIPPED` senza attendere. `trigger_source` distingue
`SCHEDULED` da `MANUAL_UI`; `requested_by='NiFi-UI'` identifica il canale, non la
persona.

Non avviare direttamente `FRONTIERE_METADATA_RUNNER` per un'esecuzione operativa: è
riservato ai test tecnici e non crea l'audit `dwh_schedule_run`. L'entry point UI
manuale è `DWH_MANUAL_LAUNCH`; il gruppo business viene avviato e fermato dal
runner.

Il DDL e la verifica PostgreSQL sono in
`nifi/Schedulazione_Caricamenti/deploy/postgresql/`; runner, timer, service e
installer sono in `nifi/Schedulazione_Caricamenti/deploy/unix-linux/`, mentre
l'helper di deploy del launcher UI è in `nifi/Schedulazione_Caricamenti/deploy/nifi/`.
La procedura dettagliata di DDL, deploy, permessi, attivazione, monitoraggio e
rollback è in
`nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md`; le regole
di calendario e i casi d'esempio sono in
`nifi/Schedulazione_Caricamenti/doc/01_progettazione_scheduler_dwh.md` e
`nifi/Schedulazione_Caricamenti/doc/03_esempi_schedulazioni_dwh.md`.

---

## 6. Orchestrazione NiFi e scheduler DWH

L'orchestrazione end-to-end usa tre livelli separati:

```text
systemd timer (ogni giorno alle 03:00 Europe/Rome)
  -> dwh-scheduler.service / dwh_schedule_runner.py (mode scheduled)
       -> se il periodo è dovuto: run_group_cycle.sh
            -> NiFi Process Group FRONTIERE_METADATA_RUNNER
                 -> run_frontiere.py
                 -> marker FMR_EXECUTION_UUID -> gate ExtractText (matched)
                 -> run_dwh_refresh.py -> CALL hcbi_utility.prc_execute_chain(1)

UI: DWH_MANUAL_LAUNCH -> runner dwh_schedule_runner.py (mode manual-ui)
                          -> stesso wrapper e stesso Process Group business
```

Il timer si attiva ogni giorno, ma non equivale a un refresh giornaliero: il
runner valuta la riga abilitata in `dwh_schedule` e il periodo/retry. Se una
frontiera fallisce o viene saltata, `run_frontiere.py` non emette
`FMR_EXECUTION_UUID=<uuid>`; la relationship `nonzero status` raggiunge il
processor `Log frontiere failed`. Un FlowFile privo del marker valido viene
terminato da `unmatched` del gate (anche `failure` è auto-terminate). Il refresh
DWH riceve un FlowFile solo da `matched`, quindi la chain 1 non parte. Se le
frontiere terminano con successo, il marker canonico collega i log di
`etl_frontiere_run`, `etl_dwh_refresh_run` e `log_chain` tramite lo stesso UUID.

Per l'esercizio normale, l'avvio automatico è `systemd` (non `cron`), mentre
`DWH_MANUAL_LAUNCH` è il punto di accesso per una richiesta manuale. L'avvio
diretto del gruppo business o l'uso diretto di `run_group_cycle.sh` è utile per
test tecnici, ma non valuta il calendario né produce l'audit
`dwh_schedule_run`. Non lasciare `Manual trigger` attivo nella UI: è un trigger
tecnico a intervallo di un giorno, non l'interfaccia operativa.

`DWH_MANUAL_LAUNCH` torna rapidamente `STOPPED`: il runner continua in
background, quindi l'esito va verificato nell'audit e nei log, non dallo stato
del launcher. `dwh_schedule_run` registra `SCHEDULED` o `MANUAL_UI` e stati
`RUNNING`/`SUCCESS`/`FAILED`/`SKIPPED`; per il singolo DWH refresh,
`etl_dwh_refresh_run` usa `RUNNING`/`SUCCEEDED`/`FAILED`/`SKIPPED`. `requested_by` riporta
il canale `NiFi-UI`, non l'utente autenticato. I log FMR sono in
`/opt/etl/log/frontiere-metadata-runner/`; il log scheduler è
`/opt/etl/log/dwh-scheduler/dwh-scheduler.log`, con output disponibile anche nel
journal systemd. Per controllare gli ultimi tentativi:

```sql
SELECT run_id, process_code, trigger_source, planned_date, period_start,
       status, started_at, finished_at, return_code, error_message
FROM hcbi_utility.dwh_schedule_run
ORDER BY started_at DESC
LIMIT 20;
```

NiFi esegue i processor con l'identità OS del servizio (in esercizio `nifi`):
verificare che possa eseguire il virtualenv e gli script `.sh`, leggere gli
script Python e scrivere nelle directory di log. Non è necessario concedere
l'esecuzione a tutti gli utenti.

Per installazione, gate, launcher, permessi, monitoraggio e rollback consultare:

- `nifi/frontiere-metadata-runner/README.md` — architettura, gate UUID, logging,
  lock, concorrenza e test di accettazione
- `doc/deploy/MANUALE_DEPLOY_NIFI.md` — manuale di deploy NiFi e scheduler DWH
- `nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md` —
  procedura operativa completa dello scheduler

---

## 7. Notifiche

**Non è configurato un invio automatico di notifiche** (email o altro) per il
successo/fallimento dei flussi o delle chain. Il monitoraggio usa le tabelle
`log_chain`, `log_step`, `etl_frontiere_run`, `etl_dwh_refresh_run` e
`dwh_schedule_run`, i log filesystem FMR/scheduler, il journal systemd e i
bulletin NiFi. Un eventuale alert va progettato sui segnali corretti del flow o
sull'audit DB; non deve aggirare il gate che impedisce l'avvio del DWH dopo un
errore delle frontiere.

---

## 8. Git: versioning del software

A differenza di workflow basati su SourceTree/coppie di chiavi SSH, il
progetto usa un repository **GitHub** (`giuliano-degidio/RAS_Prezziario`,
branch `main`) con autenticazione via **GitHub CLI**:

```bash
# Clone
git clone https://github.com/giuliano-degidio/RAS_Prezziario.git
cd RAS_Prezziario

# Autenticazione (una tantum per postazione)
gh auth login

# Aggiornamento locale prima di ogni modifica
git pull origin main

# Commit
git add <file...>
git commit -m "<messaggio>"

# Push: forzare Git a usare la credenziale di gh invece di eventuali
# credential helper preesistenti (necessario in alcuni ambienti dove
# l'helper di default restituisce 403)
git -c credential.helper= \
    -c credential.https://github.com.helper= \
    -c credential.helper='!gh auth git-credential' \
    push origin main
```

Convenzioni repository:

- `ddl/<schema>/<tipo_oggetto>/<nome_oggetto>.sql` — un file per oggetto DB
  (table/view/procedure/function/sequence), mantenuto allineato al DB reale
- `doc/flussi/` — script end-to-end di un flusso (frontiera → DWH), versione
  "ufficiale" in uso
- `doc/flussi_appo/` — copie di lavoro/correzione in attesa di merge nello
  script ufficiale
- `doc/deploy/` — manuali operativi per i sistemisti
- `nifi/frontiere-metadata-runner/` — progetto FMR e flow NiFi
- `nifi/Schedulazione_Caricamenti/` — runner, DDL, unità systemd, launcher UI e
  documentazione della schedulazione DWH
- `summaries/chat_summary.md` — riepilogo cronologico delle attività svolte
  sul progetto

---

## 9. Riferimenti

- `README.md` (root repository) — architettura sintetica e layer
- `nifi/frontiere-metadata-runner/README.md` — dettaglio completo
  dell'orchestrazione NiFi
- `doc/deploy/MANUALE_DEPLOY_NIFI.md` — manuale di deploy NiFi e scheduler
- `nifi/Schedulazione_Caricamenti/doc/01_progettazione_scheduler_dwh.md` —
  modello dati, calendario e semantica dei run automatici/manuali
- `nifi/Schedulazione_Caricamenti/doc/02_manual_deploy_scheduler_dwh.md` —
  deploy Linux/NiFi, attivazione e diagnosi
- `nifi/Schedulazione_Caricamenti/doc/03_esempi_schedulazioni_dwh.md` — esempi
  di configurazione delle frequenze
- `ddl/hcbi_ras/procedure/pkg_stg_anag_utenti_prc_main.sql` — esempio
  completo di procedura STG da usare come template
- `ddl/hcbi_utility/procedure/prc_execute_chain__bigint.sql` — motore di
  orchestrazione chain
- `ddl/hcbi_ras/function/try_*.sql` — funzioni di conversione disponibili
