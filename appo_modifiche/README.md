# Proposta modifica lookup FCT prezzi

## Contenuto

- `01_apply_lookup_views.sql`: sostituisce le due viste sorgente delle fact:
  - `hcbi_ras.v_fct_prezzi_approvati_src`;
  - `hcbi_ras.v_fct_prezzi_rilevati_src`.
- `02_verify_lookup_views.sql`: query di verifica in sola lettura.

## Obiettivo

Le anagrafiche di versione, articolo e informatore presenti nel database sono
caricate con `id_sorgente_provincia = 0`. Le viste precedenti cercavano invece
questi oggetti usando la provincia della riga prezzo, causando lookup mancanti.

La proposta risolve versione e articolo tramite le rispettive tabelle DWH
(`dwh_anag_versione` e `dwh_anag_articolo`) e risolve l'informatore tramite
`dwh_anag_informatori`, usando la provincia anagrafica globale `0`. La provincia
della riga prezzo continua a essere usata per la lookup della provincia della
fact.

## Importante

Questi file sono solo una proposta: **non sono stati eseguiti** e non è stata
modificata la base dati.

Prima dell'applicazione:

1. verificare i file e fare un backup delle definizioni correnti delle viste;
2. eseguire `01_apply_lookup_views.sql` in una sessione PostgreSQL con utenza
   autorizzata;
3. eseguire `02_verify_lookup_views.sql` e verificare che il numero di righe con
   `tx_motivo_lookup` sia coerente con i dati attesi;
4. rieseguire le procedure FCT solo dopo aver validato le lookup.

Lo script di applicazione contiene `BEGIN`/`COMMIT`, ma non esegue operazioni
DML sulle tabelle di dati: sostituisce esclusivamente le definizioni delle due
viste.

## Esecuzione proposta

Da `psql`, dopo approvazione:

```bash
psql -h <host> -p 5432 -U <utente> -d hcbi \
  -v ON_ERROR_STOP=1 \
  -f appo_modifiche/01_apply_lookup_views.sql

psql -h <host> -p 5432 -U <utente> -d hcbi \
  -v ON_ERROR_STOP=1 \
  -f appo_modifiche/02_verify_lookup_views.sql
```

Non inserire password nei comandi o nei file versionati; usare il meccanismo
sicuro di autenticazione PostgreSQL previsto dall'ambiente.

## Verifica del merge

`03_verify_fct_merge.sql` è una diagnostica in sola lettura. Confronta tutte le
colonne funzionali usate dalle clausole `ON CONFLICT ... DO UPDATE` e restituisce:

- numero di righe sorgente e fact;
- numero di aggiornamenti realmente necessari;
- numero di nuovi record;
- ultimi contatori registrati in `hcbi_utility.log_step`.

La verifica eseguita sul database tramite `hcbi_postgres` ha restituito zero
differenze per entrambe le fact: la clausola `WHERE ... IS DISTINCT FROM` delle
procedure attuali impedisce l'aggiornamento dei record invariati.

Non è stato creato uno script di modifica delle procedure perché, allo stato
verificato, il merge è già corretto. Se il log continua a mostrare tutti i
record come aggiornati, occorre eseguire questa diagnostica sulla stessa
istanza/database e prima della stessa procedura utilizzati dal job, perché il
comportamento osservato non coincide con le definizioni attualmente presenti.

## Interpretazione dei log 874-878

Nel run analizzato le procedure hanno operato in sequenza:

1. `prc_initialize` ha contato tutte le righe della fact con almeno una chiave
   tecnica `-1` e le ha marcate nel DWH con `dt_reciclo`; per questo ha scritto
   `nr_rec_updated = 10.907` e `69.623`.
2. `prc_main` ha confrontato le fact con le viste aggiornate. Le nuove lookup
   hanno prodotto valori diversi da quelli precedenti, quindi il primo run dopo
   la correzione ha aggiornato tutte le righe: `10.907` e `69.623`.
3. La verifica attuale restituisce zero differenze residue tra viste e fact.

Questi contatori descrivono il riallineamento iniziale dopo la correzione delle
lookup, non un aggiornamento ripetuto a ogni esecuzione. Il successivo run, a
parità di dati, dovrebbe riportare `nr_rec_updated = 0` per `prc_main`.
