CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_anag_articolo;

    UPDATE hcbi_ras.dwh_anag_articolo AS dwh
       SET id_sorgente_articolo = src.id_sorgente_articolo,
           nr_livello = src.nr_livello,
           ds_nome = src.ds_nome,
           ds_descrizione = src.ds_descrizione,
           fl_eliminato = src.fl_eliminato,
           fl_prezzo_regionale = src.fl_prezzo_regionale,
           ds_unita_misura = src.ds_unita_misura,
           nr_macro_gruppo = src.nr_macro_gruppo,
           nr_spese_generali = src.nr_spese_generali,
           nr_di_cui_analisi = src.nr_di_cui_analisi,
           nr_utile_impresa = src.nr_utile_impresa,
           dt_last_update = src.dt_last_update,
           fl_analisi_approvata = src.fl_analisi_approvata,
           fl_has_utile_impresa = src.fl_has_utile_impresa,
           fl_analisi_pubblicata = src.fl_analisi_pubblicata,
           fl_is_analisi = src.fl_is_analisi,
           fl_is_cam = src.fl_is_cam,
           fl_is_ufficiale = src.fl_is_ufficiale,
           id_sorgente_categoria = src.id_sorgente_categoria,
           fl_is_manodopera = src.fl_is_manodopera,
           cd_codice_lev1 = src.cd_codice_lev1,
           cd_codice_lev2 = src.cd_codice_lev2,
           cd_codice_lev3 = src.cd_codice_lev3,
           cd_codice_lev4 = src.cd_codice_lev4,
           cd_codice_lev5 = src.cd_codice_lev5,
           fl_is_minuteria = src.fl_is_minuteria,
           nr_percentuale_aumento = src.nr_percentuale_aumento,
           ds_annotazione = src.ds_annotazione,
           fl_esporta_come_articolo = src.fl_esporta_come_articolo,
           fl_escludi_manodopera = src.fl_escludi_manodopera,
           id_sorgente_provincia = src.id_sorgente_provincia,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_anag_articolo AS src
     WHERE dwh.ds_anno = src.ds_anno
       AND dwh.cd_articolo = src.cd_articolo
       AND dwh.cd_versione = src.cd_versione
       AND ROW(dwh.id_sorgente_articolo, dwh.nr_livello, dwh.ds_nome, dwh.ds_descrizione, dwh.fl_eliminato, dwh.fl_prezzo_regionale, dwh.ds_unita_misura, dwh.nr_macro_gruppo, dwh.nr_spese_generali, dwh.nr_di_cui_analisi, dwh.nr_utile_impresa, dwh.dt_last_update, dwh.fl_analisi_approvata, dwh.fl_has_utile_impresa, dwh.fl_analisi_pubblicata, dwh.fl_is_analisi, dwh.fl_is_cam, dwh.fl_is_ufficiale, dwh.id_sorgente_categoria, dwh.fl_is_manodopera, dwh.cd_codice_lev1, dwh.cd_codice_lev2, dwh.cd_codice_lev3, dwh.cd_codice_lev4, dwh.cd_codice_lev5, dwh.fl_is_minuteria, dwh.nr_percentuale_aumento, dwh.ds_annotazione, dwh.fl_esporta_come_articolo, dwh.fl_escludi_manodopera, dwh.id_sorgente_provincia) IS DISTINCT FROM ROW(src.id_sorgente_articolo, src.nr_livello, src.ds_nome, src.ds_descrizione, src.fl_eliminato, src.fl_prezzo_regionale, src.ds_unita_misura, src.nr_macro_gruppo, src.nr_spese_generali, src.nr_di_cui_analisi, src.nr_utile_impresa, src.dt_last_update, src.fl_analisi_approvata, src.fl_has_utile_impresa, src.fl_analisi_pubblicata, src.fl_is_analisi, src.fl_is_cam, src.fl_is_ufficiale, src.id_sorgente_categoria, src.fl_is_manodopera, src.cd_codice_lev1, src.cd_codice_lev2, src.cd_codice_lev3, src.cd_codice_lev4, src.cd_codice_lev5, src.fl_is_minuteria, src.nr_percentuale_aumento, src.ds_annotazione, src.fl_esporta_come_articolo, src.fl_escludi_manodopera, src.id_sorgente_provincia);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_articolo (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_articolo,
        src.ds_anno,
        src.cd_articolo,
        src.nr_livello,
        src.ds_nome,
        src.ds_descrizione,
        src.fl_eliminato,
        src.fl_prezzo_regionale,
        src.ds_unita_misura,
        src.nr_macro_gruppo,
        src.nr_spese_generali,
        src.nr_di_cui_analisi,
        src.nr_utile_impresa,
        src.dt_last_update,
        src.fl_analisi_approvata,
        src.fl_has_utile_impresa,
        src.fl_analisi_pubblicata,
        src.cd_versione,
        src.fl_is_analisi,
        src.fl_is_cam,
        src.fl_is_ufficiale,
        src.id_sorgente_categoria,
        src.fl_is_manodopera,
        src.cd_codice_lev1,
        src.cd_codice_lev2,
        src.cd_codice_lev3,
        src.cd_codice_lev4,
        src.cd_codice_lev5,
        src.fl_is_minuteria,
        src.nr_percentuale_aumento,
        src.ds_annotazione,
        src.fl_esporta_come_articolo,
        src.fl_escludi_manodopera,
        src.id_sorgente_provincia,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.v_dwh_anag_articolo AS src
    ON CONFLICT (ds_anno, cd_articolo, cd_versione) DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted, v_rec_errors,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_articolo_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$procedure$
