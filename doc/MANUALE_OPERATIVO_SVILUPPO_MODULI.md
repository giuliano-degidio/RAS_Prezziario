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
6. [Orchestrazione NiFi: FRONTIERE_METADATA_RUNNER](#6-orchestrazione-nifi-frontiere_metadata_runner)
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
| Orchestrazione/scheduling | Apache NiFi 2.11 |
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
   oggetto, allineato all'oggetto reale sul DB (vedi §9 per come estrarlo).

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

---

## 5. HCBI_UTILITY: motore di schedulazione e orchestrazione

### 5.1 Tabelle di configurazione

| Tabella | Scopo |
|---|---|
| `srv_config_chain` | catalogo delle chain (`id_chain`, nome, attiva/disattiva) |
| `srv_config_step` | step di ogni chain, in ordine (`nr_step_order`), con dipendenze (`id_dependency_step`), flag bloccante/non bloccante, retry |
| `srv_metadata_copy_src` | metadati di copia legati a una chain (sorgente → tabella temp target) |
| `etl_frontiere_config` | configurazione del caricamento frontiere (§4) |
| `cfg_connections` | connessioni esterne configurate (es. dblink) |

### 5.2 Tabelle di log

| Tabella | Scopo |
|---|---|
| `log_chain` | una riga per esecuzione di chain (`dt_start`, `dt_end`, `ds_status`, `etl_execution_uuid` — correlato all'esecuzione NiFi, vedi §6) |
| `log_step` | una riga per step eseguito all'interno di una chain (conteggi `nr_rec_selected/inserted/updated/deleted/errors`, stato, errore) |
| `etl_frontiere_run` | log per singola frontiera caricata (righe lette/scritte, stato, `nifi_flowfile_uuid`) |
| `etl_frontiere_execution_lock` | lock applicativo per frontiera, a riposo deve essere sempre vuota |
| `etl_dwh_refresh_run` | log per esecuzione della chain DWH lanciata da NiFi (`execution_uuid`, `chain_id`, stato) |

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

---

## 6. Orchestrazione NiFi: FRONTIERE_METADATA_RUNNER

Il progetto `nifi/frontiere-metadata-runner/` orchestra, a monte delle chain
PL/pgSQL, la sequenza completa: caricamento full-refresh di tutte le frontiere
attive (`run_frontiere.py`, §4) seguito, solo in caso di successo completo,
dalla chiamata a `CALL hcbi_utility.prc_execute_chain(1)`
(`run_dwh_refresh.py`). Per la messa in esercizio, gestione, monitoraggio e
troubleshooting di questa parte vedere i due documenti dedicati, già
disponibili in repository e qui solo richiamati:

- `nifi/frontiere-metadata-runner/README.md` — architettura, semantica
  transazionale, logging, lock, test di accettazione
- `doc/deploy/MANUALE_DEPLOY_NIFI.md` — manuale di deploy per il sistemista
  (installazione NiFi, setup, esecuzione da UI/CLI, monitoraggio, rollback)

---

## 7. Notifiche

**Non è presente, ad oggi, alcun meccanismo di notifica** (email o
altro) in caso di successo/fallimento dei flussi o delle chain. Il
monitoraggio degli esiti avviene esclusivamente per via applicativa (tabelle
`log_chain`, `log_step`, `etl_frontiere_run`, `etl_dwh_refresh_run`) e
filesystem (log in `/opt/etl/log/frontiere-metadata-runner/`). Se serve
introdurre notifiche, valutare un processor NiFi aggiuntivo (es. `PutEmail`)
agganciato alle relationship `nonzero status`/`failed` già presenti nel
template `FRONTIERE_METADATA_RUNNER.json`, oppure un controllo schedulato
esterno che interroga le tabelle di log sopra elencate.

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
- `nifi/frontiere-metadata-runner/` — progetto di orchestrazione NiFi
  (script, SQL di deploy, README)
- `summaries/chat_summary.md` — riepilogo cronologico delle attività svolte
  sul progetto

---

## 9. Riferimenti

- `README.md` (root repository) — architettura sintetica e layer
- `nifi/frontiere-metadata-runner/README.md` — dettaglio completo
  dell'orchestrazione NiFi
- `doc/deploy/MANUALE_DEPLOY_NIFI.md` — manuale di deploy NiFi
- `ddl/hcbi_ras/procedure/pkg_stg_anag_utenti_prc_main.sql` — esempio
  completo di procedura STG da usare come template
- `ddl/hcbi_utility/procedure/prc_execute_chain__bigint.sql` — motore di
  orchestrazione chain
- `ddl/hcbi_ras/function/try_*.sql` — funzioni di conversione disponibili
