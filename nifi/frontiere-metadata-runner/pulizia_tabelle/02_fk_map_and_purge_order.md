# Step 2 - FK map and purge order for HCBI cleanup

Scope: database `hcbi`, schemas `hcbi_ras` and `hcbi_utility`.

## Goal

Define the purge order for cleanup scripts so that referential integrity is preserved.

## Rules

- `hcbi_utility` configuration tables are **out of scope** and must not be touched.
- Tables with foreign keys must be purged **from children to parents**.
- Dimension tables must keep their seed / tappo rows in the next implementation step.
- Tables without FKs can be truncated independently, but are kept in the purge plan for completeness.

## FK graph: `hcbi_ras`

### Parent dimensions

- `dim_area_vasta` -> root
- `dim_ateco_2002` -> root
- `dim_firenze_articoli` -> root
- `dim_livello_codifica` -> root
- `dim_macro_gruppo` -> root
- `dim_periodo` -> root
- `dim_unita_misura` -> root
- `dim_utenti` -> root

### Dependent dimensions

- `dim_provincia` -> `dim_area_vasta`
- `dim_versione` -> `dim_periodo`, `dim_provincia`
- `dim_capitolo` -> `dim_periodo`, `dim_provincia`, `dim_versione`
- `dim_sottocapitolo` -> `dim_periodo`, `dim_provincia`, `dim_versione`
- `dim_tipologia` -> `dim_periodo`, `dim_provincia`, `dim_versione`
- `dim_informatori` -> `dim_ateco_2002`, `dim_periodo`, `dim_provincia`, `dim_versione`
- `dim_articolo` -> `dim_macro_gruppo`, `dim_periodo`, `dim_provincia`, `dim_unita_misura`, `dim_versione`

### Facts

- `fct_firenze_analisi` -> `dim_firenze_articoli`
- `fct_articoli_informatori` -> `dim_articolo`, `dim_informatori`, `dim_periodo`, `dim_provincia`, `dim_utenti`, `dim_versione`
- `fct_prezzi_approvati` -> `dim_articolo`, `dim_periodo`, `dim_provincia`, `dim_versione`
- `fct_prezzi_rilevati` -> `dim_articolo`, `dim_informatori`, `dim_periodo`, `dim_provincia`, `dim_utenti`, `dim_versione`
- `fct_pubblicazione_albero` -> `dim_macro_gruppo`, `dim_periodo`, `dim_provincia`, `dim_versione`
- `fct_pubblicazione_analisi` -> `dim_articolo`, `dim_periodo`, `dim_versione`
- `fct_pubblicazione_articoli` -> `dim_articolo`, `dim_capitolo`, `dim_macro_gruppo`, `dim_periodo`, `dim_provincia`, `dim_sottocapitolo`, `dim_tipologia`, `dim_unita_misura`, `dim_versione`

## FK graph: `hcbi_utility`

### Config tables (not touched)

- `cfg_connections`
- `etl_frontiere_config`
- `srv_config_chain`
- `srv_config_step`
- `srv_metadata_copy_src`

### Runtime/log tables with FKs

- `etl_frontiere_run` -> `etl_frontiere_config`
- `etl_frontiere_execution_lock` -> `etl_frontiere_run`, `etl_frontiere_config`
- `log_chain` -> `srv_config_chain`
- `srv_config_step` -> `srv_config_chain`
- `log_step` -> `srv_config_step`
- `srv_metadata_copy_src` -> `srv_config_chain`

## Cleanup order proposal

### Phase A - tables without FK constraints

These tables can be cleaned independently because no other table points to them.

Suggested groups:

1. `frontiera_*`
2. `src_tmp_*`
3. `stg_*`
4. `wrk_*`
5. `dwh_*` and `dwh_anag_*`
6. support tables: `srv_controlli`, `zz_anagrafica_articolo_liv4`

### Phase B - facts

Delete all fact tables before touching dimensions:

1. `fct_firenze_analisi`
2. `fct_articoli_informatori`
3. `fct_prezzi_approvati`
4. `fct_prezzi_rilevati`
5. `fct_pubblicazione_albero`
6. `fct_pubblicazione_analisi`
7. `fct_pubblicazione_articoli`

### Phase C - dependent dimensions

Delete the child dimensions before the root dimensions:

1. `dim_articolo`
2. `dim_capitolo`
3. `dim_informatori`
4. `dim_provincia`
5. `dim_sottocapitolo`
6. `dim_tipologia`
7. `dim_versione`

### Phase D - root dimensions

Delete the root dimensions last:

1. `dim_area_vasta`
2. `dim_ateco_2002`
3. `dim_firenze_articoli`
4. `dim_livello_codifica`
5. `dim_macro_gruppo`
6. `dim_periodo`
7. `dim_unita_misura`
8. `dim_utenti`

## Notes for the next implementation step

- The FK-free groups can be collapsed into fewer scripts if needed.
- The final cleanup scripts should preserve dimension seed / tappo rows.
- `hcbi_utility` runtime/log tables are documented here only for reference; they are not part of the data cleanup scope.
