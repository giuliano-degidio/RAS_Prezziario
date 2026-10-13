CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_prezzi_rilevati_src" AS
 WITH base AS MATERIALIZED (
         SELECT p.id_prezzi_rilevati,
            p.cd_articolo,
            TRIM(TRAILING '.'::text FROM btrim(p.cd_articolo::text))::character varying(60) AS cd_articolo_normalizzato,
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
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno = p.ds_anno
             LEFT JOIN hcbi_ras.dwh_anag_provincia dpr ON dpr.id_sorgente_provincia = p.id_sorgente_provincia::bigint
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.id_anag_provincia = dpr.id_anag_provincia
        ), resolved AS MATERIALIZED (
         SELECT b.id_prezzi_rilevati,
            b.cd_articolo,
            b.cd_articolo_normalizzato,
            b.ds_anno,
            b.id_sorgente_provincia,
            b.id_sorgente_informatore,
            b.id_sorgente_rilevatore,
            b.nr_prezzo,
            b.dt_inserimento,
            b.fl_nascosto,
            b.ds_anno_ribaltamento,
            b.cd_versione,
            b.cd_versione_ribaltamento,
            b.dt_last_update,
            b.id_periodo,
            b.dwh_id_anag_provincia,
            b.id_anag_provincia,
            ver.id_anag_versione,
            art.id_anag_articolo,
            dinf.id_anag_informatore AS dwh_id_anag_informatore,
            inf.id_anag_informatore,
            dusr.id_anag_utente AS dwh_id_anag_utente,
            usr.id_anag_utente AS id_anag_utente_rilevatore
           FROM base b
             LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione = b.id_periodo AND ver.cd_versione = b.cd_versione AND ver.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_periodo_pubblicazione = b.id_periodo AND btrim(art.cd_articolo::text) = btrim(b.cd_articolo_normalizzato::text) AND art.id_anag_versione = ver.id_anag_versione AND art.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dwh_anag_informatori dinf ON dinf.id_sorgente_informatore = b.id_sorgente_informatore AND dinf.id_sorgente_provincia = b.id_sorgente_provincia::bigint AND dinf.ds_anno_pubblicazione = b.ds_anno AND dinf.cd_versione = b.cd_versione
             LEFT JOIN hcbi_ras.dim_informatori inf ON inf.id_anag_informatore = dinf.id_anag_informatore
             LEFT JOIN hcbi_ras.dwh_anag_utenti dusr ON dusr.id_sorgente_utente = b.id_sorgente_rilevatore::bigint
             LEFT JOIN hcbi_ras.dim_utenti usr ON usr.id_anag_utente = dusr.id_anag_utente
        )
 SELECT id_prezzi_rilevati,
        CASE
            WHEN id_periodo IS NULL THEN '-1'::integer
            ELSE id_periodo
        END AS id_periodo_pubblicazione,
        CASE
            WHEN id_anag_provincia IS NULL THEN '-1'::integer::bigint
            ELSE id_anag_provincia
        END AS id_anag_provincia,
        CASE
            WHEN id_anag_versione IS NULL THEN '-1'::integer::bigint
            ELSE id_anag_versione
        END AS id_anag_versione,
        CASE
            WHEN id_anag_articolo IS NULL THEN '-1'::integer::bigint
            ELSE id_anag_articolo
        END AS id_anag_articolo,
        CASE
            WHEN id_anag_informatore IS NULL THEN '-1'::integer::bigint
            ELSE id_anag_informatore
        END AS id_anag_informatore,
        CASE
            WHEN id_anag_utente_rilevatore IS NULL THEN '-1'::integer::bigint
            ELSE id_anag_utente_rilevatore
        END AS id_anag_utente_rilevatore,
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
            WHEN dwh_id_anag_utente IS NULL THEN 'DWH_ANAG_UTENTI non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN dwh_id_anag_utente IS NOT NULL AND id_anag_utente_rilevatore IS NULL THEN 'DIM_UTENTI non contiene la PK DWH'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_lookup
   FROM resolved r;;
