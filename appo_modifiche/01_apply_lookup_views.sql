-- Proposta di correzione lookup per le viste FCT_PREZZI.
-- Questo file NON viene eseguito automaticamente.
-- Eseguire solo dopo verifica e approvazione.

BEGIN;

CREATE OR REPLACE VIEW hcbi_ras.v_fct_prezzi_approvati_src AS
WITH base AS MATERIALIZED (
    SELECT
        p.id_prezzi_approvati,
        p.cd_articolo,
        trim(trailing '.' FROM btrim(p.cd_articolo::text))::varchar(60) AS cd_articolo_normalizzato,
        p.ds_anno,
        p.id_sorgente_provincia,
        p.cd_versione,
        p.nr_prezzo,
        p.dt_approvazione,
        per.id_periodo,
        dpr.id_anag_provincia AS dwh_id_anag_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_prezzi_approvati p
    LEFT JOIN hcbi_ras.dim_periodo per
        ON per.ds_anno = p.ds_anno
    LEFT JOIN hcbi_ras.dwh_anag_provincia dpr
        ON dpr.anno = p.ds_anno
       AND dpr.cd_versione = p.cd_versione
       AND dpr.id_sorgente_provincia = p.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia prv
        ON prv.id_anag_provincia = dpr.id_anag_provincia
       AND prv.anno = dpr.anno
       AND prv.cd_versione = dpr.cd_versione
), resolved AS MATERIALIZED (
    SELECT
        b.*,
        ver.id_anag_versione,
        art.id_anag_articolo
    FROM base b
    LEFT JOIN hcbi_ras.dwh_anag_versione ver_dwh
        ON ver_dwh.ds_anno_pubblicazione = b.ds_anno
       AND ver_dwh.cd_versione = b.cd_versione
       AND ver_dwh.id_sorgente_provincia = 0
    LEFT JOIN hcbi_ras.dim_versione ver
        ON ver.id_anag_versione = ver_dwh.id_anag_versione
    LEFT JOIN hcbi_ras.dwh_anag_articolo art_dwh
        ON art_dwh.ds_anno = b.ds_anno
       AND btrim(art_dwh.cd_articolo::text) = btrim(b.cd_articolo::text)
       AND art_dwh.cd_versione = b.cd_versione
       AND art_dwh.id_sorgente_provincia = 0
    LEFT JOIN hcbi_ras.dim_articolo art
        ON art.id_anag_articolo = art_dwh.id_anag_articolo
)
SELECT
    id_prezzi_approvati,
    coalesce(id_periodo, -1)::integer AS id_periodo_pubblicazione,
    coalesce(id_anag_provincia, -1)::bigint AS id_anag_provincia,
    coalesce(id_anag_versione, -1)::bigint AS id_anag_versione,
    coalesce(id_anag_articolo, -1)::bigint AS id_anag_articolo,
    nr_prezzo,
    dt_approvazione,
    cd_articolo,
    cd_articolo_normalizzato,
    ds_anno,
    cd_versione,
    id_sorgente_provincia,
    nullif(concat_ws('; ',
        CASE WHEN id_periodo IS NULL
             THEN 'DIM_PERIODO non risolta' END,
        CASE WHEN dwh_id_anag_provincia IS NULL
             THEN 'DWH_ANAG_PROVINCIA non risolta' END,
        CASE WHEN dwh_id_anag_provincia IS NOT NULL AND id_anag_provincia IS NULL
             THEN 'DIM_PROVINCIA non contiene la PK DWH' END,
        CASE WHEN id_anag_versione IS NULL
             THEN 'DIM_VERSIONE non risolta su anno+versione+anagrafica globale' END,
        CASE WHEN id_anag_articolo IS NULL
             THEN 'DIM_ARTICOLO non risolta su anno+articolo+versione+anagrafica globale' END
    ), '')::varchar(4000) AS tx_motivo_lookup
FROM resolved;

CREATE OR REPLACE VIEW hcbi_ras.v_fct_prezzi_rilevati_src AS
WITH base AS MATERIALIZED (
    SELECT
        p.id_prezzi_rilevati,
        p.cd_articolo,
        trim(trailing '.' FROM btrim(p.cd_articolo::text))::varchar(60) AS cd_articolo_normalizzato,
        p.ds_anno,
        p.id_sorgente_provincia,
        p.id_sorgente_informatore,
        p.id_sorgente_rilevatore,
        p.nr_prezzo,
        p.dt_inserimento,
        p.fl_nascosto,
        p.ds_anno_ribaltamento,
        p.cd_versione,
        p.cd_versione_ribaltamento,
        p.dt_last_update,
        per.id_periodo,
        dpr.id_anag_provincia AS dwh_id_anag_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_prezzi_rilevati p
    LEFT JOIN hcbi_ras.dim_periodo per
        ON per.ds_anno = p.ds_anno
    LEFT JOIN hcbi_ras.dwh_anag_provincia dpr
        ON dpr.anno = p.ds_anno
       AND dpr.cd_versione = p.cd_versione
       AND dpr.id_sorgente_provincia = p.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia prv
        ON prv.id_anag_provincia = dpr.id_anag_provincia
       AND prv.anno = dpr.anno
       AND prv.cd_versione = dpr.cd_versione
), resolved AS MATERIALIZED (
    SELECT
        b.*,
        ver.id_anag_versione,
        art.id_anag_articolo,
        dinf.id_anag_informatore AS dwh_id_anag_informatore,
        inf.id_anag_informatore,
        dusr.id_anag_utente AS dwh_id_anag_utente,
        usr.id_anag_utente AS id_anag_utente_rilevatore
    FROM base b
    LEFT JOIN hcbi_ras.dwh_anag_versione ver_dwh
        ON ver_dwh.ds_anno_pubblicazione = b.ds_anno
       AND ver_dwh.cd_versione = b.cd_versione
       AND ver_dwh.id_sorgente_provincia = 0
    LEFT JOIN hcbi_ras.dim_versione ver
        ON ver.id_anag_versione = ver_dwh.id_anag_versione
    LEFT JOIN hcbi_ras.dwh_anag_articolo art_dwh
        ON art_dwh.ds_anno = b.ds_anno
       AND btrim(art_dwh.cd_articolo::text) = btrim(b.cd_articolo::text)
       AND art_dwh.cd_versione = b.cd_versione
       AND art_dwh.id_sorgente_provincia = 0
    LEFT JOIN hcbi_ras.dim_articolo art
        ON art.id_anag_articolo = art_dwh.id_anag_articolo
    LEFT JOIN hcbi_ras.dwh_anag_informatori dinf
        ON dinf.id_sorgente_informatore = b.id_sorgente_informatore
       AND dinf.id_sorgente_provincia = 0
       AND dinf.ds_anno_pubblicazione = b.ds_anno
       AND dinf.cd_versione = b.cd_versione
    LEFT JOIN hcbi_ras.dim_informatori inf
        ON inf.id_anag_informatore = dinf.id_anag_informatore
    LEFT JOIN hcbi_ras.dwh_anag_utenti dusr
        ON dusr.id_sorgente_utente = b.id_sorgente_rilevatore::bigint
    LEFT JOIN hcbi_ras.dim_utenti usr
        ON usr.id_anag_utente = dusr.id_anag_utente
)
SELECT
    id_prezzi_rilevati,
    coalesce(id_periodo, -1)::integer AS id_periodo_pubblicazione,
    coalesce(id_anag_provincia, -1)::bigint AS id_anag_provincia,
    coalesce(id_anag_versione, -1)::bigint AS id_anag_versione,
    coalesce(id_anag_articolo, -1)::bigint AS id_anag_articolo,
    coalesce(id_anag_informatore, -1)::bigint AS id_anag_informatore,
    coalesce(id_anag_utente_rilevatore, -1)::bigint AS id_anag_utente_rilevatore,
    nr_prezzo,
    dt_inserimento,
    fl_nascosto,
    ds_anno_ribaltamento,
    cd_versione_ribaltamento,
    dt_last_update,
    cd_articolo,
    ds_anno,
    cd_versione,
    id_sorgente_provincia,
    id_sorgente_informatore,
    id_sorgente_rilevatore,
    nullif(concat_ws('; ',
        CASE WHEN id_periodo IS NULL
             THEN 'DIM_PERIODO non risolta' END,
        CASE WHEN dwh_id_anag_provincia IS NULL
             THEN 'DWH_ANAG_PROVINCIA non risolta' END,
        CASE WHEN id_anag_provincia IS NULL
             THEN 'DIM_PROVINCIA non risolta' END,
        CASE WHEN id_anag_versione IS NULL
             THEN 'DIM_VERSIONE non risolta su anno+versione+anagrafica globale' END,
        CASE WHEN id_anag_articolo IS NULL
             THEN 'DIM_ARTICOLO non risolta su anno+articolo+versione+anagrafica globale' END,
        CASE WHEN dwh_id_anag_informatore IS NULL
             THEN 'DWH_ANAG_INFORMATORI non risolta su informatore+anno+versione+anagrafica globale' END,
        CASE WHEN dwh_id_anag_informatore IS NOT NULL AND id_anag_informatore IS NULL
             THEN 'DIM_INFORMATORI non contiene la PK DWH' END,
        CASE WHEN dwh_id_anag_utente IS NULL
             THEN 'DWH_ANAG_UTENTI non risolta' END,
        CASE WHEN dwh_id_anag_utente IS NOT NULL AND id_anag_utente_rilevatore IS NULL
             THEN 'DIM_UTENTI non contiene la PK DWH' END
    ), '')::varchar(4000) AS tx_motivo_lookup
FROM resolved;

COMMIT;
