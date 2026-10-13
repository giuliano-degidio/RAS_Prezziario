CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero;
    CREATE TABLE hcbi_ras.tmp_dwh_pubblicazione_albero AS SELECT
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
    FROM hcbi_ras.v_dwh_pubblicazione_albero;
    CREATE UNIQUE INDEX tmp_dwh_pubblicazione_albero_uq ON hcbi_ras.tmp_dwh_pubblicazione_albero (ds_anno_pubblicazione,id_sorgente_provincia,cd_articolo,cd_versione) NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dwh_pubblicazione_albero;
    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_pubblicazione_albero;
    UPDATE hcbi_ras.dwh_pubblicazione_albero AS dwh SET
        ds_articolo = src.ds_articolo,
        nr_prezzo = src.nr_prezzo,
        id_sorgente_um = src.id_sorgente_um,
        fl_isanalisi = src.fl_isanalisi,
        fl_isincidenza = src.fl_isincidenza,
        nr_scostamento = src.nr_scostamento,
        nr_scostamento_con_spese = src.nr_scostamento_con_spese,
        fl_is_nuovo_codice = src.fl_is_nuovo_codice,
        fl_is_prezzo_modificato = src.fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato = src.fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata = src.fl_is_analisi_modificata,
        fl_is_descrizione_modificata = src.fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata = src.fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate = src.fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati = src.fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati = src.fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de = src.ds_descrizione_de,
        fl_is_ufficiale = src.fl_is_ufficiale,
        id_sorgente_categoria = src.id_sorgente_categoria,
        ds_nome = src.ds_nome,
        ds_nome_de = src.ds_nome_de,
        fl_is_nome_modificato = src.fl_is_nome_modificato,
        ds_link_cam = src.ds_link_cam,
        ds_annotazione = src.ds_annotazione,
        ds_annotazione_de = src.ds_annotazione_de,
        id_sorgente_pubblicazione_albero = src.id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo = src.fl_esporta_come_articolo,
        fl_escludi_manodopera = src.fl_escludi_manodopera,
        fl_mostra_struttura_analisi = src.fl_mostra_struttura_analisi,
        nr_macro_gruppo = src.nr_macro_gruppo,
        fl_is_cam = src.fl_is_cam,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_albero AS src
    WHERE dwh.ds_anno_pubblicazione=src.ds_anno_pubblicazione
      AND dwh.id_sorgente_provincia=src.id_sorgente_provincia
      AND dwh.cd_articolo=src.cd_articolo
      AND dwh.cd_versione=src.cd_versione
      AND (
dwh.ds_articolo IS DISTINCT FROM src.ds_articolo
        OR dwh.nr_prezzo IS DISTINCT FROM src.nr_prezzo
        OR dwh.id_sorgente_um IS DISTINCT FROM src.id_sorgente_um
        OR dwh.fl_isanalisi IS DISTINCT FROM src.fl_isanalisi
        OR dwh.fl_isincidenza IS DISTINCT FROM src.fl_isincidenza
        OR dwh.nr_scostamento IS DISTINCT FROM src.nr_scostamento
        OR dwh.nr_scostamento_con_spese IS DISTINCT FROM src.nr_scostamento_con_spese
        OR dwh.fl_is_nuovo_codice IS DISTINCT FROM src.fl_is_nuovo_codice
        OR dwh.fl_is_prezzo_modificato IS DISTINCT FROM src.fl_is_prezzo_modificato
        OR dwh.fl_is_prezzo_con_spese_modificato IS DISTINCT FROM src.fl_is_prezzo_con_spese_modificato
        OR dwh.fl_is_analisi_modificata IS DISTINCT FROM src.fl_is_analisi_modificata
        OR dwh.fl_is_descrizione_modificata IS DISTINCT FROM src.fl_is_descrizione_modificata
        OR dwh.fl_is_uinta_misura_modificata IS DISTINCT FROM src.fl_is_uinta_misura_modificata
        OR dwh.fl_is_spese_generali_modificate IS DISTINCT FROM src.fl_is_spese_generali_modificate
        OR dwh.fl_is_utili_impresa_modificati IS DISTINCT FROM src.fl_is_utili_impresa_modificati
        OR dwh.fl_is_oneri_sicurezza_modificati IS DISTINCT FROM src.fl_is_oneri_sicurezza_modificati
        OR dwh.ds_descrizione_de IS DISTINCT FROM src.ds_descrizione_de
        OR dwh.fl_is_ufficiale IS DISTINCT FROM src.fl_is_ufficiale
        OR dwh.id_sorgente_categoria IS DISTINCT FROM src.id_sorgente_categoria
        OR dwh.ds_nome IS DISTINCT FROM src.ds_nome
        OR dwh.ds_nome_de IS DISTINCT FROM src.ds_nome_de
        OR dwh.fl_is_nome_modificato IS DISTINCT FROM src.fl_is_nome_modificato
        OR dwh.ds_link_cam IS DISTINCT FROM src.ds_link_cam
        OR dwh.ds_annotazione IS DISTINCT FROM src.ds_annotazione
        OR dwh.ds_annotazione_de IS DISTINCT FROM src.ds_annotazione_de
        OR dwh.id_sorgente_pubblicazione_albero IS DISTINCT FROM src.id_sorgente_pubblicazione_albero
        OR dwh.fl_esporta_come_articolo IS DISTINCT FROM src.fl_esporta_come_articolo
        OR dwh.fl_escludi_manodopera IS DISTINCT FROM src.fl_escludi_manodopera
        OR dwh.fl_mostra_struttura_analisi IS DISTINCT FROM src.fl_mostra_struttura_analisi
        OR dwh.nr_macro_gruppo IS DISTINCT FROM src.nr_macro_gruppo
        OR dwh.fl_is_cam IS DISTINCT FROM src.fl_is_cam
      );
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    INSERT INTO hcbi_ras.dwh_pubblicazione_albero (
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
        dt_creation,tx_creation_by,dt_update,tx_update_by
    )
    SELECT
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
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_albero AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_pubblicazione_albero DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero;
    p_result := 1;
    RAISE NOTICE 'Fine DWH PUBBLICAZIONE_ALBERO: selected=%, inserted=%, updated=%',v_selected,v_inserted,v_updated;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM; END;
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
        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_albero_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$procedure$
