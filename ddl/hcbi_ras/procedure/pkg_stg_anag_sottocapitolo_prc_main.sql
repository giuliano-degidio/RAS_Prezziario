CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_sottocapitolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_anag_sottocapitolo_classificata;
 CREATE TABLE hcbi_ras.tmp_anag_sottocapitolo_classificata AS
 WITH src AS MATERIALIZED(SELECT f.ds_anno ds_anno_raw,f.cd_versione cd_versione_raw,f.cd_sottocapitolo cd_sottocapitolo_raw,f.ds_sottocapitolo ds_sottocapitolo_raw,f.id_sorgente_provincia id_sorgente_provincia_raw,nullif(btrim(f.ds_anno),'') ds_anno_txt,nullif(btrim(f.cd_versione),'') cd_versione_txt,nullif(btrim(f.cd_sottocapitolo),'') cd_sottocapitolo_txt,nullif(btrim(f.ds_sottocapitolo),'') ds_sottocapitolo_txt,nullif(btrim(f.id_sorgente_provincia),'') id_sorgente_provincia_txt,count(*) OVER(PARTITION BY nullif(btrim(f.ds_anno),''),nullif(btrim(f.cd_sottocapitolo),''),nullif(btrim(f.cd_versione),''),nullif(btrim(f.id_sorgente_provincia),'')) duplicate_count FROM hcbi_ras.v_src_tmp_anag_sottocapitolo f),
 cv AS MATERIALIZED(SELECT s.*,hcbi_ras.try_integer(ds_anno_txt) ds_anno_cv,hcbi_ras.try_smallint(cd_versione_txt) cd_versione_cv,hcbi_ras.try_bigint(id_sorgente_provincia_txt) id_sorgente_provincia_cv FROM src s)
 SELECT c.*,CASE WHEN duplicate_count>1 THEN 'Chiave duplicata: (ds_anno, cd_sottocapitolo, cd_versione, id_sorgente_provincia)' WHEN ds_anno_txt IS NULL THEN 'ds_anno obbligatorio' WHEN ds_anno_cv IS NULL THEN 'ds_anno non convertibile' WHEN cd_versione_txt IS NULL THEN 'cd_versione obbligatorio' WHEN cd_versione_cv IS NULL THEN 'cd_versione non convertibile' WHEN cd_sottocapitolo_txt IS NULL THEN 'cd_sottocapitolo obbligatorio' WHEN length(cd_sottocapitolo_txt)>60 THEN 'cd_sottocapitolo eccede 60 caratteri' WHEN ds_sottocapitolo_txt IS NULL THEN 'ds_sottocapitolo obbligatorio' WHEN id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio' WHEN id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile in bigint' ELSE NULL END::text tx_motivo_scarto FROM cv c;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_anag_sottocapitolo_classificata;
 INSERT INTO hcbi_ras.stg_anag_sottocapitolo(ds_anno,cd_versione,cd_sottocapitolo,ds_sottocapitolo,id_sorgente_provincia) SELECT ds_anno_cv,cd_versione_cv,cd_sottocapitolo_txt,ds_sottocapitolo_txt,id_sorgente_provincia_cv FROM hcbi_ras.tmp_anag_sottocapitolo_classificata WHERE tx_motivo_scarto IS NULL; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_anag_sottocapitolo_rej(ds_anno,cd_versione,cd_sottocapitolo,ds_sottocapitolo,id_sorgente_provincia,tx_motivo_scarto) SELECT ds_anno_raw,cd_versione_raw,cd_sottocapitolo_raw,ds_sottocapitolo_raw,id_sorgente_provincia_raw,tx_motivo_scarto FROM hcbi_ras.tmp_anag_sottocapitolo_classificata WHERE tx_motivo_scarto IS NOT NULL; GET DIAGNOSTICS v_rec_errors=ROW_COUNT;
 IF v_selected<>v_inserted+v_rec_errors THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors); END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_anag_sottocapitolo_classificata; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_sottocapitolo_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_sottocapitolo_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
