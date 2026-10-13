CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_articoli_informatori_src" AS
 WITH base AS MATERIALIZED (
         SELECT ai.id_articoli_informatori,
            ai.id_sorgente_articoli_informatori,
            ai.id_sorgente_informatore,
            ai.cd_articolo,
            TRIM(TRAILING '.'::text FROM btrim(ai.cd_articolo::text))::character varying(60) AS cd_articolo_normalizzato,
            ai.ds_anno,
            ai.id_sorgente_provincia,
            ai.cd_versione,
            ai.id_sorgente_utente,
            ai.fl_escluso,
            per.id_periodo,
            dpr.id_anag_provincia AS dwh_id_anag_provincia,
            prv.id_anag_provincia
           FROM hcbi_ras.dwh_articoli_informatori ai
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno = ai.ds_anno
             LEFT JOIN hcbi_ras.dwh_anag_provincia dpr ON dpr.id_sorgente_provincia = ai.id_sorgente_provincia::bigint
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.id_anag_provincia = dpr.id_anag_provincia
        ), resolved AS MATERIALIZED (
         SELECT b.id_articoli_informatori,
            b.id_sorgente_articoli_informatori,
            b.id_sorgente_informatore,
            b.cd_articolo,
            b.cd_articolo_normalizzato,
            b.ds_anno,
            b.id_sorgente_provincia,
            b.cd_versione,
            b.id_sorgente_utente,
            b.fl_escluso,
            b.id_periodo,
            b.dwh_id_anag_provincia,
            b.id_anag_provincia,
            ver.id_anag_versione,
            art.id_anag_articolo,
            dinf.id_anag_informatore AS dwh_id_anag_informatore,
            inf.id_anag_informatore,
            dusr.id_anag_utente AS dwh_id_anag_utente,
            usr.id_anag_utente
           FROM base b
             LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione = b.id_periodo AND ver.cd_versione = b.cd_versione AND ver.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_periodo_pubblicazione = b.id_periodo AND btrim(art.cd_articolo::text) = btrim(b.cd_articolo_normalizzato::text) AND art.id_anag_versione = ver.id_anag_versione AND art.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dwh_anag_informatori dinf ON dinf.id_sorgente_informatore = b.id_sorgente_informatore AND dinf.id_sorgente_provincia = b.id_sorgente_provincia::bigint AND dinf.ds_anno_pubblicazione = b.ds_anno AND dinf.cd_versione = b.cd_versione
             LEFT JOIN hcbi_ras.dim_informatori inf ON inf.id_anag_informatore = dinf.id_anag_informatore
             LEFT JOIN hcbi_ras.dwh_anag_utenti dusr ON dusr.id_sorgente_utente = b.id_sorgente_utente::bigint
             LEFT JOIN hcbi_ras.dim_utenti usr ON usr.id_anag_utente = dusr.id_anag_utente
        )
 SELECT id_articoli_informatori,
    COALESCE(id_periodo, '-1'::integer) AS id_periodo_pubblicazione,
    COALESCE(id_anag_provincia, - 1::bigint) AS id_anag_provincia,
    COALESCE(id_anag_versione, - 1::bigint) AS id_anag_versione,
    COALESCE(id_anag_articolo, - 1::bigint) AS id_anag_articolo,
    COALESCE(id_anag_informatore, - 1::bigint) AS id_anag_informatore,
    COALESCE(id_anag_utente, - 1::bigint) AS id_anag_utente,
    fl_escluso,
    id_sorgente_articoli_informatori,
    id_sorgente_informatore,
    cd_articolo,
    cd_articolo_normalizzato,
    ds_anno,
    id_sorgente_provincia,
    cd_versione,
    id_sorgente_utente,
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
            WHEN id_anag_provincia IS NULL THEN 'DIM_PROVINCIA non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_versione IS NULL THEN 'DIM_VERSIONE non risolta su periodo+versione+provincia'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_articolo IS NULL THEN 'DIM_ARTICOLO non risolta su periodo+articolo+versione+provincia'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_informatore IS NULL THEN 'DWH_ANAG_INFORMATORI non risolta su informatore+provincia+anno+versione'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_informatore IS NOT NULL AND id_anag_informatore IS NULL THEN 'DIM_INFORMATORI non contiene la PK DWH'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_sorgente_utente IS NOT NULL AND dwh_id_anag_utente IS NULL THEN 'DWH_ANAG_UTENTI non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_utente IS NOT NULL AND id_anag_utente IS NULL THEN 'DIM_UTENTI non contiene la PK DWH'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_lookup
   FROM resolved r;;
