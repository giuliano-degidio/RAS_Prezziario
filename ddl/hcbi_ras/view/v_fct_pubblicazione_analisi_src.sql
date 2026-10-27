CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_pubblicazione_analisi_src" AS
 WITH mappa_analisi_provincia AS (
         SELECT DISTINCT pa.ds_anno_pubblicazione,
            pa.cd_codice_completo::character varying(70) AS cd_codice_analisi_completo,
            pa.cd_versione,
            pa.id_sorgente_provincia
           FROM hcbi_ras.dwh_pubblicazione_articoli pa
        ), base AS (
         SELECT src.id_pubblicazione_analisi,
            src.ds_anno_pubblicazione,
            src.cd_codice_analisi,
            src.nr_quantita,
            src.cd_articolo,
            src.cd_versione,
            src.id_sorgente_pubblicazione_analisi,
            src.id_sorgente_categoria,
            src.nr_riga,
            src.dt_creation,
            src.tx_creation_by,
            src.dt_update,
            src.tx_update_by,
            src.dt_reciclo,
            per.id_periodo,
            map.id_sorgente_provincia,
            prv.id_anag_provincia,
            regexp_replace(substr(btrim(src.cd_articolo::text), 7), '\.$'::text, ''::text)::character varying(70) AS cd_articolo_normalizzato,
            src.cd_codice_analisi::character varying(70) AS cd_codice_analisi_completo
           FROM hcbi_ras.dwh_pubblicazione_analisi src
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno::numeric = src.ds_anno_pubblicazione
             LEFT JOIN mappa_analisi_provincia map ON map.ds_anno_pubblicazione = src.ds_anno_pubblicazione AND map.cd_codice_analisi_completo::text = src.cd_codice_analisi::text AND map.cd_versione = src.cd_versione
             LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_prv ON dwh_prv.anno = src.ds_anno_pubblicazione::integer AND dwh_prv.cd_versione = src.cd_versione::smallint AND dwh_prv.id_sorgente_provincia = map.id_sorgente_provincia::bigint
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.id_anag_provincia = dwh_prv.id_anag_provincia AND prv.anno = dwh_prv.anno AND prv.cd_versione = dwh_prv.cd_versione
        ), resolved AS (
         SELECT b.id_pubblicazione_analisi,
            b.ds_anno_pubblicazione,
            b.cd_codice_analisi,
            b.nr_quantita,
            b.cd_articolo,
            b.cd_versione,
            b.id_sorgente_pubblicazione_analisi,
            b.id_sorgente_categoria,
            b.nr_riga,
            b.dt_creation,
            b.tx_creation_by,
            b.dt_update,
            b.tx_update_by,
            b.dt_reciclo,
            b.id_periodo,
            b.id_sorgente_provincia,
            b.id_anag_provincia,
            b.cd_articolo_normalizzato,
            b.cd_codice_analisi_completo,
            ver.id_anag_versione,
            art.id_anag_articolo
           FROM base b
             LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione = COALESCE(b.id_periodo, '-1'::integer) AND ver.cd_versione = b.cd_versione AND ver.id_anag_provincia = COALESCE(b.id_anag_provincia, - 1::bigint)
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_periodo_pubblicazione = COALESCE(b.id_periodo, '-1'::integer) AND art.cd_articolo::text = b.cd_articolo_normalizzato::text AND art.id_anag_versione = COALESCE(ver.id_anag_versione, - 1::bigint) AND art.id_anag_provincia = COALESCE(b.id_anag_provincia, - 1::bigint)
        )
 SELECT id_pubblicazione_analisi,
    COALESCE(id_periodo, '-1'::integer) AS id_periodo_pubblicazione,
    COALESCE(id_anag_articolo, - 1::bigint) AS id_anag_articolo,
    COALESCE(id_anag_versione, - 1::bigint) AS id_anag_versione,
    substr(btrim(cd_codice_analisi::text), 7)::character varying(70) AS cd_codice_analisi,
    nr_quantita,
    id_sorgente_pubblicazione_analisi,
    id_sorgente_categoria,
    nr_riga,
    ds_anno_pubblicazione,
    cd_articolo,
    cd_articolo_normalizzato,
    cd_codice_analisi_completo,
    cd_versione,
    id_sorgente_provincia,
    id_anag_provincia,
    NULLIF(concat_ws('; '::text,
        CASE
            WHEN id_periodo IS NULL THEN 'FK DIM_PERIODO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_sorgente_provincia IS NULL THEN 'Provincia non derivata da DWH_PUBBLICAZIONE_ARTICOLI'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_provincia IS NULL THEN 'Lookup DIM_PROVINCIA non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_versione IS NULL THEN 'FK DIM_VERSIONE non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_articolo IS NULL THEN 'FK DIM_ARTICOLO non risolta: applicato -1'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_lookup
   FROM resolved;;
