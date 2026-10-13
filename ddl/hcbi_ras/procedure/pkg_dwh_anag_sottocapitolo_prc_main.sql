CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_sottocapitolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_sottocapitolo; CREATE TABLE hcbi_ras.tmp_dwh_anag_sottocapitolo AS SELECT ds_anno,cd_versione,cd_sottocapitolo,ds_sottocapitolo,id_sorgente_provincia FROM hcbi_ras.v_dwh_anag_sottocapitolo;
 CREATE UNIQUE INDEX tmp_dwh_anag_sottocapitolo_uq ON hcbi_ras.tmp_dwh_anag_sottocapitolo(ds_anno,cd_sottocapitolo,cd_versione,id_sorgente_provincia) NULLS NOT DISTINCT; ANALYZE hcbi_ras.tmp_dwh_anag_sottocapitolo; SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_sottocapitolo;
 UPDATE hcbi_ras.dwh_anag_sottocapitolo d SET ds_sottocapitolo=t.ds_sottocapitolo,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_sottocapitolo t WHERE d.ds_anno=t.ds_anno AND d.cd_sottocapitolo=t.cd_sottocapitolo AND d.cd_versione=t.cd_versione AND d.id_sorgente_provincia=t.id_sorgente_provincia AND d.ds_sottocapitolo IS DISTINCT FROM t.ds_sottocapitolo; GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_anag_sottocapitolo(ds_anno,cd_versione,cd_sottocapitolo,ds_sottocapitolo,id_sorgente_provincia,dt_creation,tx_creation_by,dt_update,tx_update_by) SELECT ds_anno,cd_versione,cd_sottocapitolo,ds_sottocapitolo,id_sorgente_provincia,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_sottocapitolo ON CONFLICT ON CONSTRAINT uq_dwh_anag_sottocapitolo DO NOTHING; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_dwh_anag_sottocapitolo; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_sottocapitolo; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_sottocapitolo_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
