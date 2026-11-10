
CREATE OR REPLACE VIEW hcbi_ras.v_fct_prezzi_approvati_src
 AS
 WITH base AS MATERIALIZED (
         SELECT p.id_prezzi_approvati,
            p.cd_articolo,
            TRIM(TRAILING '.'::text FROM btrim(p.cd_articolo::text))::character varying(60) AS cd_articolo_normalizzato,
            p.ds_anno,
            p.id_sorgente_provincia,
            p.cd_versione,
            p.nr_prezzo,
            p.dt_approvazione,
            per.id_periodo,
            dpr.id_anag_provincia AS dwh_id_anag_provincia,
            prv.id_anag_provincia
           FROM hcbi_ras.dwh_prezzi_approvati p
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno = p.ds_anno
             LEFT JOIN hcbi_ras.dwh_anag_provincia dpr ON dpr.anno = p.ds_anno AND dpr.cd_versione = p.cd_versione AND dpr.id_sorgente_provincia = p.id_sorgente_provincia::bigint
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.id_anag_provincia = dpr.id_anag_provincia AND prv.anno = dpr.anno AND prv.cd_versione = dpr.cd_versione
        ), resolved AS MATERIALIZED (
         SELECT b.id_prezzi_approvati,
            b.cd_articolo,
            b.cd_articolo_normalizzato,
            b.ds_anno,
            b.id_sorgente_provincia,
            b.cd_versione,
            b.nr_prezzo,
            b.dt_approvazione,
            b.id_periodo,
            b.dwh_id_anag_provincia,
            b.id_anag_provincia,
            ver.id_anag_versione,
            art.id_anag_articolo
           FROM base b
             LEFT JOIN hcbi_ras.dwh_anag_versione ver_dwh ON ver_dwh.ds_anno_pubblicazione = b.ds_anno AND ver_dwh.cd_versione = b.cd_versione AND ver_dwh.id_sorgente_provincia = 0::numeric
             LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_anag_versione = ver_dwh.id_anag_versione
             LEFT JOIN hcbi_ras.dwh_anag_articolo art_dwh ON art_dwh.ds_anno = b.ds_anno AND btrim(art_dwh.cd_articolo::text) = btrim(b.cd_articolo::text) AND art_dwh.cd_versione = b.cd_versione AND art_dwh.id_sorgente_provincia = 0::numeric
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_anag_articolo = art_dwh.id_anag_articolo
        )
 SELECT id_prezzi_approvati,
    COALESCE(id_periodo, '-1'::integer) AS id_periodo_pubblicazione,
    COALESCE(id_anag_provincia, '-1'::integer::bigint) AS id_anag_provincia,
    COALESCE(id_anag_versione, '-1'::integer::bigint) AS id_anag_versione,
    COALESCE(id_anag_articolo, '-1'::integer::bigint) AS id_anag_articolo,
    nr_prezzo,
    dt_approvazione,
    cd_articolo,
    cd_articolo_normalizzato,
    ds_anno,
    cd_versione,
    id_sorgente_provincia,
    NULLIF(concat_ws('; '::text,
        CASE
            WHEN id_periodo IS NULL THEN 'DIM_PERIODO non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_provincia IS NULL THEN 'DWH_ANAG_PROVINCIA non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_provincia IS NOT NULL AND id_anag_provincia IS NULL THEN 'DIM_PROVINCIA non contiene la PK DWH'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_versione IS NULL THEN 'DIM_VERSIONE non risolta su anno+versione+anagrafica globale'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_articolo IS NULL THEN 'DIM_ARTICOLO non risolta su anno+articolo+versione+anagrafica globale'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_lookup
   FROM resolved;

ALTER TABLE hcbi_ras.v_fct_prezzi_approvati_src
    OWNER TO postgres;