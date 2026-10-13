CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_pubblicazione_albero_src" AS
 WITH mappa_pubblicazione_articolo AS MATERIALIZED (
         SELECT pa.id_pubblicazione_articoli,
            aa.id_anag_articolo,
            pa.cd_codice_completo,
            aa.cd_articolo AS cd_articolo_anagrafica,
            aa.ds_nome,
            pa.ds_anno_pubblicazione,
            pa.id_sorgente_provincia,
            pa.cd_versione
           FROM hcbi_ras.dwh_pubblicazione_articoli pa
             JOIN hcbi_ras.dwh_anag_articolo aa ON aa.ds_anno::numeric = pa.ds_anno_pubblicazione AND TRIM(TRAILING '.'::text FROM btrim(aa.cd_articolo::text)) = TRIM(TRAILING '.'::text FROM btrim(pa.cd_articolo::text)) AND btrim(aa.cd_versione::text) = btrim(pa.cd_versione::text)
        ), nodi_padre AS MATERIALIZED (
         SELECT DISTINCT src.id_pubblicazione_albero
           FROM hcbi_ras.dwh_pubblicazione_albero src
          WHERE (EXISTS ( SELECT 1
                   FROM hcbi_ras.dwh_pubblicazione_articoli figlio
                  WHERE figlio.ds_anno_pubblicazione::numeric = src.ds_anno_pubblicazione::numeric AND figlio.id_sorgente_provincia::numeric = src.id_sorgente_provincia::numeric AND btrim(figlio.cd_versione::text) = btrim(src.cd_versione::text) AND btrim(figlio.cd_codice_completo::text) ~~ (btrim(src.cd_articolo::text) || '.%'::text)))
        ), lookup_base AS (
         SELECT src.id_pubblicazione_albero,
            src.ds_anno_pubblicazione,
            src.id_sorgente_provincia,
            src.cd_articolo,
            src.ds_articolo,
            src.nr_prezzo,
            src.id_sorgente_um,
            src.fl_isanalisi,
            src.fl_isincidenza,
            src.cd_versione,
            src.nr_scostamento,
            src.nr_scostamento_con_spese,
            src.fl_is_nuovo_codice,
            src.fl_is_prezzo_modificato,
            src.fl_is_prezzo_con_spese_modificato,
            src.fl_is_analisi_modificata,
            src.fl_is_descrizione_modificata,
            src.fl_is_uinta_misura_modificata,
            src.fl_is_spese_generali_modificate,
            src.fl_is_utili_impresa_modificati,
            src.fl_is_oneri_sicurezza_modificati,
            src.ds_descrizione_de,
            src.fl_is_ufficiale,
            src.id_sorgente_categoria,
            src.ds_nome,
            src.ds_nome_de,
            src.fl_is_nome_modificato,
            src.ds_link_cam,
            src.ds_annotazione,
            src.ds_annotazione_de,
            src.id_sorgente_pubblicazione_albero,
            src.fl_esporta_come_articolo,
            src.fl_escludi_manodopera,
            src.fl_mostra_struttura_analisi,
            src.nr_macro_gruppo,
            src.fl_is_cam,
            src.dt_creation,
            src.tx_creation_by,
            src.dt_update,
            src.tx_update_by,
            src.dt_reciclo,
            COALESCE(per.id_periodo, '-1'::integer) AS id_periodo_pubblicazione_lkp,
            COALESCE(prv.id_anag_provincia, - 1::bigint) AS id_anag_provincia_lkp,
                CASE
                    WHEN nodo.id_pubblicazione_albero IS NOT NULL THEN 0::bigint
                    ELSE COALESCE(art.id_anag_articolo, - 1::bigint)
                END AS id_anag_articolo_lkp,
                CASE
                    WHEN src.nr_macro_gruppo IS NULL THEN 0::bigint
                    ELSE COALESCE(mg.id_anag_macro_gruppo, - 1::bigint)
                END AS id_anag_macro_gruppo_lkp,
            per.id_periodo IS NULL AS fl_periodo_ko,
            prv.id_anag_provincia IS NULL AS fl_provincia_ko,
            nodo.id_pubblicazione_albero IS NULL AND (map.id_anag_articolo IS NULL OR art.id_anag_articolo IS NULL) AS fl_articolo_ko,
            src.nr_macro_gruppo IS NOT NULL AND mg.id_anag_macro_gruppo IS NULL AS fl_macro_gruppo_ko
           FROM hcbi_ras.dwh_pubblicazione_albero src
             LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno::numeric = src.ds_anno_pubblicazione
             LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_prv ON dwh_prv.id_sorgente_provincia::numeric = src.id_sorgente_provincia
             LEFT JOIN hcbi_ras.dim_provincia prv ON prv.cd_provincia::text = dwh_prv.cd_provincia::text
             LEFT JOIN nodi_padre nodo ON nodo.id_pubblicazione_albero = src.id_pubblicazione_albero
             LEFT JOIN mappa_pubblicazione_articolo map ON map.ds_anno_pubblicazione::numeric = src.ds_anno_pubblicazione::numeric AND map.id_sorgente_provincia::numeric = src.id_sorgente_provincia::numeric AND btrim(map.cd_codice_completo::text) = btrim(src.cd_articolo::text) AND btrim(map.cd_versione::text) = btrim(src.cd_versione::text)
             LEFT JOIN hcbi_ras.dim_articolo art ON art.id_anag_articolo = map.id_anag_articolo
             LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo dwh_mg ON dwh_mg.id_sorgente_macro_gruppo = src.nr_macro_gruppo::bigint
             LEFT JOIN hcbi_ras.dim_macro_gruppo mg ON mg.id_anag_macro_gruppo = dwh_mg.id_anag_macro_gruppo
        )
 SELECT b.id_pubblicazione_albero,
    b.id_periodo_pubblicazione_lkp AS id_periodo_pubblicazione,
    b.id_anag_provincia_lkp AS id_anag_provincia,
    b.id_anag_articolo_lkp AS id_anag_articolo,
    COALESCE(ver.id_anag_versione, - 1::bigint) AS id_anag_versione,
    b.nr_prezzo,
    b.id_sorgente_um,
    b.fl_isanalisi,
    b.fl_isincidenza,
    b.nr_scostamento,
    b.nr_scostamento_con_spese,
    b.fl_is_nuovo_codice,
    b.fl_is_prezzo_modificato,
    b.fl_is_prezzo_con_spese_modificato,
    b.fl_is_analisi_modificata,
    b.fl_is_descrizione_modificata,
    b.fl_is_uinta_misura_modificata,
    b.fl_is_spese_generali_modificate,
    b.fl_is_utili_impresa_modificati,
    b.fl_is_oneri_sicurezza_modificati,
    b.fl_is_ufficiale,
    b.id_sorgente_categoria,
    b.ds_nome,
    b.ds_link_cam,
    b.ds_annotazione,
    b.id_sorgente_pubblicazione_albero,
    b.fl_esporta_come_articolo,
    b.fl_escludi_manodopera,
    b.fl_mostra_struttura_analisi,
    b.id_anag_macro_gruppo_lkp AS id_anag_macro_gruppo,
    b.fl_is_cam,
    b.ds_anno_pubblicazione,
    b.id_sorgente_provincia,
    b.cd_articolo,
    b.cd_versione,
    NULLIF(concat_ws('; '::text,
        CASE
            WHEN b.fl_periodo_ko THEN 'FK DIM_PERIODO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN b.fl_provincia_ko THEN 'FK DIM_PROVINCIA non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN b.fl_articolo_ko THEN 'FK DIM_ARTICOLO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN b.fl_macro_gruppo_ko THEN 'FK DIM_MACRO_GRUPPO non risolta: applicato -1'::text
            ELSE NULL::text
        END,
        CASE
            WHEN ver.id_anag_versione IS NULL THEN 'FK DIM_VERSIONE non risolta: applicato -1'::text
            ELSE NULL::text
        END), ''::text)::character varying(4000) AS tx_motivo_scarto
   FROM lookup_base b
     LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione = b.id_periodo_pubblicazione_lkp AND ver.cd_versione = b.cd_versione AND ver.id_anag_provincia = b.id_anag_provincia_lkp;;
