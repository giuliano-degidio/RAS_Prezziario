CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_versione; CREATE TABLE hcbi_ras.tmp_dwh_anag_versione AS SELECT ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia FROM hcbi_ras.v_dwh_anag_versione;
 CREATE UNIQUE INDEX tmp_dwh_anag_versione_uq ON hcbi_ras.tmp_dwh_anag_versione(ds_anno_pubblicazione,cd_versione,id_sorgente_provincia) NULLS NOT DISTINCT; ANALYZE hcbi_ras.tmp_dwh_anag_versione; SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_versione;
 UPDATE hcbi_ras.dwh_anag_versione d SET ds_versione=src.ds_versione,
       fl_scostamento_1_visibile=src.fl_scostamento_1_visibile,
       fl_scostamento_2_visibile=src.fl_scostamento_2_visibile,
       fl_scostamento_3_visibile=src.fl_scostamento_3_visibile,
       fl_scostamento_4_visibile=src.fl_scostamento_4_visibile,
       fl_scostamento_5_visibile=src.fl_scostamento_5_visibile,
       nr_spese_generali=src.nr_spese_generali,
       nr_utile_impresa=src.nr_utile_impresa,
       nr_di_cui_analisi=src.nr_di_cui_analisi,
       ds_llpp_homepage_title=src.ds_llpp_homepage_title,
       ds_llpp_homepage_description=src.ds_llpp_homepage_description,
       fl_pubblicazione_regionale=src.fl_pubblicazione_regionale,
       id_sorgente_versione=src.id_sorgente_versione,
       fl_mostra_annotazioni=src.fl_mostra_annotazioni,
       fl_mostra_struttura_analisi=src.fl_mostra_struttura_analisi,
       fl_is_errata_corrige=src.fl_is_errata_corrige,
       fl_mostra_cam=src.fl_mostra_cam,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_versione src WHERE d.ds_anno_pubblicazione=src.ds_anno_pubblicazione AND d.cd_versione=src.cd_versione AND d.id_sorgente_provincia=src.id_sorgente_provincia AND (d.ds_versione IS DISTINCT FROM src.ds_versione
       OR d.fl_scostamento_1_visibile IS DISTINCT FROM src.fl_scostamento_1_visibile
       OR d.fl_scostamento_2_visibile IS DISTINCT FROM src.fl_scostamento_2_visibile
       OR d.fl_scostamento_3_visibile IS DISTINCT FROM src.fl_scostamento_3_visibile
       OR d.fl_scostamento_4_visibile IS DISTINCT FROM src.fl_scostamento_4_visibile
       OR d.fl_scostamento_5_visibile IS DISTINCT FROM src.fl_scostamento_5_visibile
       OR d.nr_spese_generali IS DISTINCT FROM src.nr_spese_generali
       OR d.nr_utile_impresa IS DISTINCT FROM src.nr_utile_impresa
       OR d.nr_di_cui_analisi IS DISTINCT FROM src.nr_di_cui_analisi
       OR d.ds_llpp_homepage_title IS DISTINCT FROM src.ds_llpp_homepage_title
       OR d.ds_llpp_homepage_description IS DISTINCT FROM src.ds_llpp_homepage_description
       OR d.fl_pubblicazione_regionale IS DISTINCT FROM src.fl_pubblicazione_regionale
       OR d.id_sorgente_versione IS DISTINCT FROM src.id_sorgente_versione
       OR d.fl_mostra_annotazioni IS DISTINCT FROM src.fl_mostra_annotazioni
       OR d.fl_mostra_struttura_analisi IS DISTINCT FROM src.fl_mostra_struttura_analisi
       OR d.fl_is_errata_corrige IS DISTINCT FROM src.fl_is_errata_corrige
       OR d.fl_mostra_cam IS DISTINCT FROM src.fl_mostra_cam); GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_anag_versione(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia,dt_creation,tx_creation_by,dt_update,tx_update_by) SELECT src.ds_anno_pubblicazione,src.cd_versione,src.ds_versione,src.fl_scostamento_1_visibile,src.fl_scostamento_2_visibile,src.fl_scostamento_3_visibile,src.fl_scostamento_4_visibile,src.fl_scostamento_5_visibile,src.nr_spese_generali,src.nr_utile_impresa,src.nr_di_cui_analisi,src.ds_llpp_homepage_title,src.ds_llpp_homepage_description,src.fl_pubblicazione_regionale,src.id_sorgente_versione,src.fl_mostra_annotazioni,src.fl_mostra_struttura_analisi,src.fl_is_errata_corrige,src.fl_mostra_cam,src.id_sorgente_provincia,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_versione src ON CONFLICT ON CONSTRAINT uq_dwh_anag_versione DO NOTHING; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_dwh_anag_versione; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_versione; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_versione_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
