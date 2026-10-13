CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0;
 v_updated bigint:=0; v_deleted bigint:=0; v_errors bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_prezzi_rilevati;
 UPDATE hcbi_ras.dwh_prezzi_rilevati d
 SET id_sorgente_rilevatore=s.id_sorgente_rilevatore, nr_prezzo=s.nr_prezzo,
     dt_inserimento=s.dt_inserimento, fl_nascosto=s.fl_nascosto,
     ds_anno_ribaltamento=s.ds_anno_ribaltamento,
     cd_versione_ribaltamento=s.cd_versione_ribaltamento,
     dt_last_update=s.dt_last_update, dt_update=clock_timestamp(), tx_update_by=p_ds_step_name
 FROM hcbi_ras.v_dwh_prezzi_rilevati s
 WHERE d.cd_articolo=s.cd_articolo AND d.ds_anno=s.ds_anno
   AND d.id_sorgente_provincia=s.id_sorgente_provincia
   AND d.cd_versione=s.cd_versione
   AND d.id_sorgente_informatore=s.id_sorgente_informatore
   AND ROW(d.id_sorgente_rilevatore,d.nr_prezzo,d.dt_inserimento,d.fl_nascosto,
           d.ds_anno_ribaltamento,d.cd_versione_ribaltamento,d.dt_last_update)
       IS DISTINCT FROM
       ROW(s.id_sorgente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,
           s.ds_anno_ribaltamento,s.cd_versione_ribaltamento,s.dt_last_update);
 GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_prezzi_rilevati
 (cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
  nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
  cd_versione_ribaltamento,dt_last_update,tx_creation_by,tx_update_by)
 SELECT s.cd_articolo,s.ds_anno,s.id_sorgente_provincia,s.id_sorgente_informatore,
  s.id_sorgente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,
  s.ds_anno_ribaltamento,s.cd_versione,s.cd_versione_ribaltamento,s.dt_last_update,
  p_ds_step_name,p_ds_step_name
 FROM hcbi_ras.v_dwh_prezzi_rilevati s
 ON CONFLICT (cd_articolo,ds_anno,id_sorgente_provincia,cd_versione,id_sorgente_informatore)
 DO NOTHING;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,
  v_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
   left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore main DWH PREZZI_RILEVATI: %',SQLERRM;
END;$procedure$
