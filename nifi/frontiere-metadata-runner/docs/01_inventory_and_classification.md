# Step 1 - Inventory and classification of HCBI tables

Scope: database `hcbi`, schemas `hcbi_ras` and `hcbi_utility`.

## Summary

| Schema | Tables | Classes |
| --- | ---: | --- |
| `hcbi_ras` | 134 | frontiera, src_tmp, staging, work, dimension, dwh_dimension, dwh_domain, fact, support |
| `hcbi_utility` | 10 | config, runtime_log, runtime_lock |

## Classification rules used

- **config**: not to be touched by cleanup scripts.
- **runtime_log / runtime_lock**: operational tables; keep separate from data-layer cleanup.
- **frontiera / src_tmp / staging / work / fact / dwh_* / dimension**: in-scope for cleanup planning.
- **dimension**: cleanup must preserve seed/tappo rows.
- **support**: manually verified in later steps.

## `hcbi_utility`

### Config tables (do not touch)

- `cfg_connections`
- `etl_frontiere_config`
- `srv_config_chain`
- `srv_config_step`
- `srv_metadata_copy_src`

### Runtime tables

- `etl_frontiere_execution_lock`
- `etl_frontiere_run`
- `etl_dwh_refresh_run`
- `log_chain`
- `log_step`

## `hcbi_ras`

### Frontiera layer (18)

- `frontiera_anag_area_vasta`
- `frontiera_anag_articolo`
- `frontiera_anag_ateco_2002`
- `frontiera_anag_informatori`
- `frontiera_anag_livello_codifica`
- `frontiera_anag_macro_gruppo`
- `frontiera_anag_provincia`
- `frontiera_anag_unita_misura`
- `frontiera_anag_utenti`
- `frontiera_anni`
- `frontiera_articoli_informatori`
- `frontiera_firenze_analisi`
- `frontiera_firenze_articoli`
- `frontiera_prezzi_approvati`
- `frontiera_prezzi_rilevati`
- `frontiera_pubblicazione_albero`
- `frontiera_pubblicazione_analisi`
- `frontiera_pubblicazione_articoli`

### Source-temp layer (23)

Prefix: `src_tmp_*`

### Staging layer (44)

Prefix: `stg_*`

### Work layer (1)

- `wrk_firenze_analisi_csv`

### Dimension layer (15) - preserve tappo rows

Prefix: `dim_*`

### DWH dimension domain layer (14) - provisional classification, to confirm in next step

Prefix: `dwh_anag_*`

### DWH domain tables (10) - provisional classification, to confirm in next step

Prefix: `dwh_*` excluding `dwh_anag_*`, `dwh_*` facts and rejected variants

### Fact layer (7)

Prefix: `fct_*`

### Support / manual review

- `srv_controlli`
- `zz_anagrafica_articolo_liv4`

## Notes for next step

1. Configuration tables in `hcbi_utility` are excluded from cleanup scripts.
2. Dimension tables are in scope, but seed/tappo rows must be preserved.
3. Runtime tables and locks are intentionally kept separate from the data purge plan.
4. The `dwh_*` domain tables will be refined in the FK/order step.
