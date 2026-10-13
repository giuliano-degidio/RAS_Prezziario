CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_pubblicazione_articoli_src" AS
 WITH base AS MATERIALIZED (
         SELECT src.id_pubblicazione_articoli,
            src.id_sorgente_provincia,
            src.ds_anno_pubblicazione,
            src.cd_codice_completo,
            src.cd_versione,
            src.cd_articolo,
            TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text))::character varying(60) AS cd_articolo_normalizzato,
            split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 1)::character varying(60) AS cd_tipologia_lookup,
            concat_ws('.'::text, split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 1), split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 2))::character varying(60) AS cd_capitolo_lookup,
            concat_ws('.'::text, split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 1), split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 2), split_part(TRIM(TRAILING '.'::text FROM btrim(src.cd_articolo::text)), '.'::text, 3))::character varying(60) AS cd_sottocapitolo_lookup,
            src.cd_titolo,
            src.cd_capitolo,
            src.cd_sottocapitolo,
            src.cd_categoria_articolo,
            src.cd_subarticolo,
            src.cd_unita_misura,
            src.ds_unita_misura_de,
            src.id_sorgente_categoria,
            src.id_sorgente_pubblicazione_articoli,
            src.nr_macro_gruppo,
            src.nr_prezzo,
            src.nr_prezzo_annuo,
            src.nr_perc_spese,
            src.nr_perc_utile,
            src.nr_sicur,
            src.nr_perc_manodopera,
            src.nr_perc_oneri,
            src.nr_prezzo_manodopera,
            src.nr_perc_manodopera_dir,
            src.nr_prezzo_manodopera_dir,
            src.nr_spese,
            src.nr_utili,
            src.fl_isanalisi,
            src.fl_is_minuteria,
            src.fl_ifc_scaricabile,
            per.id_periodo,
            dwh_prv.cd_provincia,
            prv.id_anag_provincia
           FROM hcbi_ras.dwh_pubblicazione_articoli src
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno::numeric = src.ds_anno_pubblicazione::numeric
             LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_prv ON dwh_prv.id_sorgente_provincia::numeric = src.id_sorgente_provincia::numeric
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.cd_provincia::text = dwh_prv.cd_provincia::text
        ), resolved AS MATERIALIZED (
         SELECT b.id_pubblicazione_articoli,
            b.id_sorgente_provincia,
            b.ds_anno_pubblicazione,
            b.cd_codice_completo,
            b.cd_versione,
            b.cd_articolo,
            b.cd_articolo_normalizzato,
            b.cd_tipologia_lookup,
            b.cd_capitolo_lookup,
            b.cd_sottocapitolo_lookup,
            b.cd_titolo,
            b.cd_capitolo,
            b.cd_sottocapitolo,
            b.cd_categoria_articolo,
            b.cd_subarticolo,
            b.cd_unita_misura,
            b.ds_unita_misura_de,
            b.id_sorgente_categoria,
            b.id_sorgente_pubblicazione_articoli,
            b.nr_macro_gruppo,
            b.nr_prezzo,
            b.nr_prezzo_annuo,
            b.nr_perc_spese,
            b.nr_perc_utile,
            b.nr_sicur,
            b.nr_perc_manodopera,
            b.nr_perc_oneri,
            b.nr_prezzo_manodopera,
            b.nr_perc_manodopera_dir,
            b.nr_prezzo_manodopera_dir,
            b.nr_spese,
            b.nr_utili,
            b.fl_isanalisi,
            b.fl_is_minuteria,
            b.fl_ifc_scaricabile,
            b.id_periodo,
            b.cd_provincia,
            b.id_anag_provincia,
            ver.id_anag_versione,
            art.id_anag_articolo,
            tip.id_anag_tipologia,
            cap.id_anag_capitolo,
            sot.id_anag_sottocapitolo,
            um.id_anag_unita_misura,
            dwh_mg.id_anag_macro_gruppo AS dwh_id_anag_macro_gruppo,
            mg.id_anag_macro_gruppo
           FROM base b
             LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione = b.id_periodo AND ver.id_anag_provincia = b.id_anag_provincia AND btrim(ver.cd_versione::text) = btrim(b.cd_versione::text)
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_periodo_pubblicazione = b.id_periodo AND art.id_anag_provincia = b.id_anag_provincia AND art.id_anag_versione = ver.id_anag_versione AND TRIM(TRAILING '.'::text FROM btrim(art.cd_articolo::text)) = b.cd_articolo_normalizzato::text
             LEFT JOIN hcbi_ras.dim_tipologia tip ON btrim(tip.cd_tipologia::text) = btrim(b.cd_tipologia_lookup::text) AND tip.id_periodo_pubblicazione = b.id_periodo AND tip.id_anag_versione = ver.id_anag_versione AND tip.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dim_capitolo cap ON btrim(cap.cd_capitolo::text) = btrim(b.cd_capitolo_lookup::text) AND cap.id_periodo_pubblicazione = b.id_periodo AND cap.id_anag_versione = ver.id_anag_versione AND cap.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dim_sottocapitolo sot ON btrim(sot.cd_sottocapitolo::text) = btrim(b.cd_sottocapitolo_lookup::text) AND sot.id_periodo_pubblicazione = b.id_periodo AND sot.id_anag_versione = ver.id_anag_versione AND sot.id_anag_provincia = b.id_anag_provincia
             LEFT JOIN hcbi_ras.dim_unita_misura um ON btrim(um.cd_unita_misura::text) = btrim(b.cd_unita_misura::text)
             LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo dwh_mg ON dwh_mg.id_sorgente_macro_gruppo = b.nr_macro_gruppo::bigint
             LEFT JOIN hcbi_ras.dim_macro_gruppo mg ON mg.id_anag_macro_gruppo = dwh_mg.id_anag_macro_gruppo
        )
 SELECT id_pubblicazione_articoli,
    COALESCE(id_periodo, '-1'::integer) AS id_periodo_pubblicazione,
    COALESCE(id_anag_provincia, - 1::bigint) AS id_anag_provincia,
    COALESCE(id_anag_versione, - 1::bigint) AS id_anag_versione,
    COALESCE(id_anag_articolo, - 1::bigint) AS id_anag_articolo,
        CASE
            WHEN NULLIF(btrim(cd_titolo::text), ''::text) IS NULL THEN 0::bigint
            ELSE COALESCE(id_anag_tipologia, - 1::bigint)
        END AS id_anag_tipologia,
        CASE
            WHEN NULLIF(btrim(cd_capitolo::text), ''::text) IS NULL THEN 0::bigint
            ELSE COALESCE(id_anag_capitolo, - 1::bigint)
        END AS id_anag_capitolo,
        CASE
            WHEN NULLIF(btrim(cd_sottocapitolo::text), ''::text) IS NULL THEN 0::bigint
            ELSE COALESCE(id_anag_sottocapitolo, - 1::bigint)
        END AS id_anag_sottocapitolo,
        CASE
            WHEN NULLIF(btrim(cd_unita_misura::text), ''::text) IS NULL THEN 0::bigint
            ELSE COALESCE(id_anag_unita_misura, - 1::bigint)
        END AS id_anag_unita_misura,
        CASE
            WHEN nr_macro_gruppo IS NULL THEN 0::bigint
            ELSE COALESCE(id_anag_macro_gruppo, - 1::bigint)
        END AS id_anag_macro_gruppo,
    cd_codice_completo,
    cd_categoria_articolo,
    cd_subarticolo,
    ds_unita_misura_de,
    id_sorgente_categoria,
    id_sorgente_pubblicazione_articoli,
    nr_prezzo,
    nr_prezzo_annuo,
    nr_perc_spese,
    nr_perc_utile,
    nr_sicur,
    nr_perc_manodopera,
    nr_perc_oneri,
    nr_prezzo_manodopera,
    nr_perc_manodopera_dir,
    nr_prezzo_manodopera_dir,
    nr_spese,
    nr_utili,
    fl_isanalisi,
    fl_is_minuteria,
    fl_ifc_scaricabile,
    id_sorgente_provincia,
    ds_anno_pubblicazione,
    cd_versione,
    cd_articolo,
    cd_articolo_normalizzato,
    cd_tipologia_lookup,
    cd_capitolo_lookup,
    cd_sottocapitolo_lookup,
    cd_titolo,
    cd_capitolo,
    cd_sottocapitolo,
    cd_unita_misura,
    nr_macro_gruppo,
    NULLIF(concat_ws('; '::text,
        CASE
            WHEN id_periodo IS NULL THEN 'FK DIM_PERIODO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN cd_provincia IS NULL THEN 'DWH_ANAG_PROVINCIA non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_provincia IS NULL THEN 'FK DIM_PROVINCIA non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_versione IS NULL THEN 'FK DIM_VERSIONE non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN id_anag_articolo IS NULL THEN 'FK DIM_ARTICOLO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN NULLIF(btrim(cd_titolo::text), ''::text) IS NOT NULL AND id_anag_tipologia IS NULL THEN 'FK DIM_TIPOLOGIA non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN NULLIF(btrim(cd_capitolo::text), ''::text) IS NOT NULL AND id_anag_capitolo IS NULL THEN 'FK DIM_CAPITOLO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN NULLIF(btrim(cd_sottocapitolo::text), ''::text) IS NOT NULL AND id_anag_sottocapitolo IS NULL THEN 'FK DIM_SOTTOCAPITOLO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN NULLIF(btrim(cd_unita_misura::text), ''::text) IS NOT NULL AND id_anag_unita_misura IS NULL THEN 'FK DIM_UNITA_MISURA non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN nr_macro_gruppo IS NOT NULL AND dwh_id_anag_macro_gruppo IS NULL THEN 'DWH_ANAG_MACRO_GRUPPO non risolta'::text
            ELSE NULL::text
        END,
        CASE
            WHEN nr_macro_gruppo IS NOT NULL AND id_anag_macro_gruppo IS NULL THEN 'FK DIM_MACRO_GRUPPO non risolta: applicato -1'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_lookup
   FROM resolved r;;
