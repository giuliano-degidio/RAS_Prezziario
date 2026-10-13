CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0; v_inserted bigint := 0; v_updated bigint := 0; v_deleted bigint := 0; v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata;
    CREATE TABLE hcbi_ras.tmp_pubblicazione_albero_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.*,
            NULLIF(btrim(f.ds_anno_pubblicazione::text), '') AS anno_txt,
            NULLIF(btrim(f.id_sorgente_provincia::text), '') AS provincia_txt,
            NULLIF(btrim(f.cd_articolo::text), '') AS articolo_txt,
            NULLIF(btrim(f.ds_articolo::text), '') AS descrizione_txt,
            NULLIF(replace(btrim(f.nr_prezzo::text), ',', '.'), '') AS prezzo_txt,
            NULLIF(btrim(f.id_sorgente_um::text), '') AS um_txt,
            NULLIF(btrim(f.fl_isanalisi::text), '') AS isanalisi_txt,
            NULLIF(btrim(f.fl_isincidenza::text), '') AS isincidenza_txt,
            NULLIF(btrim(f.cd_versione::text), '') AS versione_txt,
            NULLIF(replace(btrim(f.nr_scostamento::text), ',', '.'), '') AS scostamento_txt,
            NULLIF(replace(btrim(f.nr_scostamento_con_spese::text), ',', '.'), '') AS scostamento_spese_txt,
            NULLIF(btrim(f.fl_is_nuovo_codice::text), '') AS is_nuovo_codice_txt,
            NULLIF(btrim(f.fl_is_prezzo_modificato::text), '') AS is_prezzo_modificato_txt,
            NULLIF(btrim(f.fl_is_prezzo_con_spese_modificato::text), '') AS is_prezzo_spese_modificato_txt,
            NULLIF(btrim(f.fl_is_analisi_modificata::text), '') AS is_analisi_modificata_txt,
            NULLIF(btrim(f.fl_is_descrizione_modificata::text), '') AS is_descrizione_modificata_txt,
            NULLIF(btrim(f.fl_is_uinta_misura_modificata::text), '') AS is_unita_misura_modificata_txt,
            NULLIF(btrim(f.fl_is_spese_generali_modificate::text), '') AS is_spese_generali_modificate_txt,
            NULLIF(btrim(f.fl_is_utili_impresa_modificati::text), '') AS is_utili_impresa_modificati_txt,
            NULLIF(btrim(f.fl_is_oneri_sicurezza_modificati::text), '') AS is_oneri_sicurezza_modificati_txt,
            NULLIF(btrim(f.ds_descrizione_de::text), '') AS descrizione_de_txt,
            NULLIF(btrim(f.fl_is_ufficiale::text), '') AS is_ufficiale_txt,
            NULLIF(btrim(f.id_sorgente_categoria::text), '') AS categoria_txt,
            NULLIF(btrim(f.ds_nome::text), '') AS nome_txt,
            NULLIF(btrim(f.ds_nome_de::text), '') AS nome_de_txt,
            NULLIF(btrim(f.fl_is_nome_modificato::text), '') AS is_nome_modificato_txt,
            NULLIF(btrim(f.ds_link_cam::text), '') AS link_cam_txt,
            NULLIF(btrim(f.ds_annotazione::text), '') AS annotazione_txt,
            NULLIF(btrim(f.ds_annotazione_de::text), '') AS annotazione_de_txt,
            NULLIF(btrim(f.id_sorgente_pubblicazione_albero::text), '') AS id_pubblicazione_txt,
            NULLIF(btrim(f.fl_esporta_come_articolo::text), '') AS esporta_articolo_txt,
            NULLIF(btrim(f.fl_escludi_manodopera::text), '') AS escludi_manodopera_txt,
            NULLIF(btrim(f.fl_mostra_struttura_analisi::text), '') AS mostra_struttura_txt,
            NULLIF(btrim(f.nr_macro_gruppo::text), '') AS macro_gruppo_txt,
            NULLIF(btrim(f.fl_is_cam::text), '') AS is_cam_txt,
            count(*) OVER (PARTITION BY f.ds_anno_pubblicazione,f.id_sorgente_provincia,f.cd_articolo,f.cd_versione) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_pubblicazione_albero AS f
    ), converted AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_numeric_10_0(s.anno_txt) AS ds_anno_pubblicazione_convertito,
            hcbi_ras.try_numeric_10_0(s.provincia_txt) AS id_sorgente_provincia_convertito,
            hcbi_ras.try_numeric_24_5(s.prezzo_txt) AS nr_prezzo_convertito,
            hcbi_ras.try_numeric_10_0(s.um_txt) AS id_sorgente_um_convertito,
            hcbi_ras.try_flag_smallint(s.isanalisi_txt) AS fl_isanalisi_convertito,
            hcbi_ras.try_flag_smallint(s.isincidenza_txt) AS fl_isincidenza_convertito,
            hcbi_ras.try_smallint(s.versione_txt) AS cd_versione_convertito,
            hcbi_ras.try_double_precision(s.scostamento_txt) AS nr_scostamento_convertito,
            hcbi_ras.try_double_precision(s.scostamento_spese_txt) AS nr_scostamento_con_spese_convertito,
            hcbi_ras.try_flag_smallint(s.is_nuovo_codice_txt) AS fl_is_nuovo_codice_convertito,
            hcbi_ras.try_flag_smallint(s.is_prezzo_modificato_txt) AS fl_is_prezzo_modificato_convertito,
            hcbi_ras.try_flag_smallint(s.is_prezzo_spese_modificato_txt) AS fl_is_prezzo_con_spese_modificato_convertito,
            hcbi_ras.try_flag_smallint(s.is_analisi_modificata_txt) AS fl_is_analisi_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_descrizione_modificata_txt) AS fl_is_descrizione_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_unita_misura_modificata_txt) AS fl_is_uinta_misura_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_spese_generali_modificate_txt) AS fl_is_spese_generali_modificate_convertito,
            hcbi_ras.try_flag_smallint(s.is_utili_impresa_modificati_txt) AS fl_is_utili_impresa_modificati_convertito,
            hcbi_ras.try_flag_smallint(s.is_oneri_sicurezza_modificati_txt) AS fl_is_oneri_sicurezza_modificati_convertito,
            hcbi_ras.try_flag_smallint(s.is_ufficiale_txt) AS fl_is_ufficiale_convertito,
            hcbi_ras.try_bigint(s.categoria_txt) AS id_sorgente_categoria_convertito,
            hcbi_ras.try_flag_smallint(s.is_nome_modificato_txt) AS fl_is_nome_modificato_convertito,
            hcbi_ras.try_bigint(s.id_pubblicazione_txt) AS id_sorgente_pubblicazione_albero_convertito,
            hcbi_ras.try_flag_smallint(s.esporta_articolo_txt) AS fl_esporta_come_articolo_convertito,
            hcbi_ras.try_flag_smallint(s.escludi_manodopera_txt) AS fl_escludi_manodopera_convertito,
            hcbi_ras.try_flag_smallint(s.mostra_struttura_txt) AS fl_mostra_struttura_analisi_convertito,
            hcbi_ras.try_integer(s.macro_gruppo_txt) AS nr_macro_gruppo_convertito,
            hcbi_ras.try_flag_smallint(s.is_cam_txt) AS fl_is_cam_convertito
        FROM src AS s
    )
    SELECT c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata nella sorgente: (ds_anno_pubblicazione, id_sorgente_provincia, cd_articolo, cd_versione)'
            WHEN c.anno_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_convertito IS NULL THEN 'ds_anno_pubblicazione non convertibile in numeric(10,0)'
            WHEN c.provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_convertito IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            WHEN c.articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_convertito IS NULL THEN 'cd_versione non convertibile in smallint'
            WHEN c.prezzo_txt IS NOT NULL AND c.nr_prezzo_convertito IS NULL THEN 'nr_prezzo non convertibile in numeric(24,5)'
            WHEN c.um_txt IS NOT NULL AND c.id_sorgente_um_convertito IS NULL THEN 'id_sorgente_um non convertibile in numeric(10,0)'
            WHEN c.isanalisi_txt IS NOT NULL AND c.fl_isanalisi_convertito IS NULL THEN 'fl_isanalisi non convertibile in smallint'
            WHEN c.isincidenza_txt IS NOT NULL AND c.fl_isincidenza_convertito IS NULL THEN 'fl_isincidenza non convertibile in smallint'
            WHEN c.scostamento_txt IS NOT NULL AND c.nr_scostamento_convertito IS NULL THEN 'nr_scostamento non convertibile in double precision'
            WHEN c.scostamento_spese_txt IS NOT NULL AND c.nr_scostamento_con_spese_convertito IS NULL THEN 'nr_scostamento_con_spese non convertibile in double precision'
            WHEN c.is_nuovo_codice_txt IS NOT NULL AND c.fl_is_nuovo_codice_convertito IS NULL THEN 'fl_is_nuovo_codice non convertibile in smallint'
            WHEN c.is_prezzo_modificato_txt IS NOT NULL AND c.fl_is_prezzo_modificato_convertito IS NULL THEN 'fl_is_prezzo_modificato non convertibile in smallint'
            WHEN c.is_prezzo_spese_modificato_txt IS NOT NULL AND c.fl_is_prezzo_con_spese_modificato_convertito IS NULL THEN 'fl_is_prezzo_con_spese_modificato non convertibile in smallint'
            WHEN c.is_analisi_modificata_txt IS NOT NULL AND c.fl_is_analisi_modificata_convertito IS NULL THEN 'fl_is_analisi_modificata non convertibile in smallint'
            WHEN c.is_descrizione_modificata_txt IS NOT NULL AND c.fl_is_descrizione_modificata_convertito IS NULL THEN 'fl_is_descrizione_modificata non convertibile in smallint'
            WHEN c.is_unita_misura_modificata_txt IS NOT NULL AND c.fl_is_uinta_misura_modificata_convertito IS NULL THEN 'fl_is_uinta_misura_modificata non convertibile in smallint'
            WHEN c.is_spese_generali_modificate_txt IS NOT NULL AND c.fl_is_spese_generali_modificate_convertito IS NULL THEN 'fl_is_spese_generali_modificate non convertibile in smallint'
            WHEN c.is_utili_impresa_modificati_txt IS NOT NULL AND c.fl_is_utili_impresa_modificati_convertito IS NULL THEN 'fl_is_utili_impresa_modificati non convertibile in smallint'
            WHEN c.is_oneri_sicurezza_modificati_txt IS NOT NULL AND c.fl_is_oneri_sicurezza_modificati_convertito IS NULL THEN 'fl_is_oneri_sicurezza_modificati non convertibile in smallint'
            WHEN c.is_ufficiale_txt IS NOT NULL AND c.fl_is_ufficiale_convertito IS NULL THEN 'fl_is_ufficiale non convertibile in smallint'
            WHEN c.categoria_txt IS NOT NULL AND c.id_sorgente_categoria_convertito IS NULL THEN 'id_sorgente_categoria non convertibile in bigint'
            WHEN c.is_nome_modificato_txt IS NOT NULL AND c.fl_is_nome_modificato_convertito IS NULL THEN 'fl_is_nome_modificato non convertibile in smallint'
            WHEN c.id_pubblicazione_txt IS NOT NULL AND c.id_sorgente_pubblicazione_albero_convertito IS NULL THEN 'id_sorgente_pubblicazione_albero non convertibile in bigint'
            WHEN c.esporta_articolo_txt IS NOT NULL AND c.fl_esporta_come_articolo_convertito IS NULL THEN 'fl_esporta_come_articolo non convertibile in smallint'
            WHEN c.escludi_manodopera_txt IS NOT NULL AND c.fl_escludi_manodopera_convertito IS NULL THEN 'fl_escludi_manodopera non convertibile in smallint'
            WHEN c.mostra_struttura_txt IS NOT NULL AND c.fl_mostra_struttura_analisi_convertito IS NULL THEN 'fl_mostra_struttura_analisi non convertibile in smallint'
            WHEN c.macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_convertito IS NULL THEN 'nr_macro_gruppo non convertibile in integer'
            WHEN c.is_cam_txt IS NOT NULL AND c.fl_is_cam_convertito IS NULL THEN 'fl_is_cam non convertibile in smallint'
            ELSE NULL END::text AS tx_motivo_scarto
    FROM converted AS c;
    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_pubblicazione_albero_classificata;
    INSERT INTO hcbi_ras.stg_pubblicazione_albero (
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam
    )
    SELECT
        c.ds_anno_pubblicazione_convertito,
        c.id_sorgente_provincia_convertito,
        c.articolo_txt,
        c.descrizione_txt,
        c.nr_prezzo_convertito,
        c.id_sorgente_um_convertito,
        c.fl_isanalisi_convertito,
        c.fl_isincidenza_convertito,
        c.cd_versione_convertito,
        c.nr_scostamento_convertito,
        c.nr_scostamento_con_spese_convertito,
        c.fl_is_nuovo_codice_convertito,
        c.fl_is_prezzo_modificato_convertito,
        c.fl_is_prezzo_con_spese_modificato_convertito,
        c.fl_is_analisi_modificata_convertito,
        c.fl_is_descrizione_modificata_convertito,
        c.fl_is_uinta_misura_modificata_convertito,
        c.fl_is_spese_generali_modificate_convertito,
        c.fl_is_utili_impresa_modificati_convertito,
        c.fl_is_oneri_sicurezza_modificati_convertito,
        c.descrizione_de_txt,
        c.fl_is_ufficiale_convertito,
        c.id_sorgente_categoria_convertito,
        c.nome_txt,
        c.nome_de_txt,
        c.fl_is_nome_modificato_convertito,
        c.link_cam_txt,
        c.annotazione_txt,
        c.annotazione_de_txt,
        c.id_sorgente_pubblicazione_albero_convertito,
        c.fl_esporta_come_articolo_convertito,
        c.fl_escludi_manodopera_convertito,
        c.fl_mostra_struttura_analisi_convertito,
        c.nr_macro_gruppo_convertito,
        c.fl_is_cam_convertito
    FROM hcbi_ras.tmp_pubblicazione_albero_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    INSERT INTO hcbi_ras.stg_pubblicazione_albero_rej (
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam,
        tx_motivo_scarto
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.id_sorgente_provincia,
        c.cd_articolo,
        c.ds_articolo,
        c.nr_prezzo,
        c.id_sorgente_um,
        c.fl_isanalisi,
        c.fl_isincidenza,
        c.cd_versione,
        c.nr_scostamento,
        c.nr_scostamento_con_spese,
        c.fl_is_nuovo_codice,
        c.fl_is_prezzo_modificato,
        c.fl_is_prezzo_con_spese_modificato,
        c.fl_is_analisi_modificata,
        c.fl_is_descrizione_modificata,
        c.fl_is_uinta_misura_modificata,
        c.fl_is_spese_generali_modificate,
        c.fl_is_utili_impresa_modificati,
        c.fl_is_oneri_sicurezza_modificati,
        c.ds_descrizione_de,
        c.fl_is_ufficiale,
        c.id_sorgente_categoria,
        c.ds_nome,
        c.ds_nome_de,
        c.fl_is_nome_modificato,
        c.ds_link_cam,
        c.ds_annotazione,
        c.ds_annotazione_de,
        c.id_sorgente_pubblicazione_albero,
        c.fl_esporta_come_articolo,
        c.fl_escludi_manodopera,
        c.fl_mostra_struttura_analisi,
        c.nr_macro_gruppo,
        c.fl_is_cam,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_albero_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;
    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors);
    END IF;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata;
    p_result := 1;
    RAISE NOTICE 'Fine STG PUBBLICAZIONE_ALBERO: selected=%, inserted=%, rejected=%',v_selected,v_inserted,v_rec_errors;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM; END;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_pubblicazione_albero_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$procedure$
