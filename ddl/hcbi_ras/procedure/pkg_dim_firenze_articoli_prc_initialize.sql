CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_firenze_articoli_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint;v_inserted bigint:=0;v_updated bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;

 INSERT INTO hcbi_ras.dim_firenze_articoli
 (id_firenze_articolo,nr_anno,ds_regione,ds_provincia,nr_riga_file,
  cd_codice_completo,cd_articolo,fl_cam,ds_tipologia_famiglia,
  ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,
  dt_creation,tx_creation_by,dt_update,tx_update_by)
 VALUES
 (0,0,'ND','ND',0,'ND','ND','ND','NON DISPONIBILE',
  'NON DISPONIBILE','NON DISPONIBILE','NON DISPONIBILE','ND',
  clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name),
 (-1,-1,'AA','AA',-1,'AA','AA','AA','ANAGRAFICA ASSENTE',
  'ANAGRAFICA ASSENTE','ANAGRAFICA ASSENTE','ANAGRAFICA ASSENTE','AA',
  clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name)
 ON CONFLICT(id_firenze_articolo) DO UPDATE SET
  nr_anno=EXCLUDED.nr_anno,ds_regione=EXCLUDED.ds_regione,
  ds_provincia=EXCLUDED.ds_provincia,nr_riga_file=EXCLUDED.nr_riga_file,
  cd_codice_completo=EXCLUDED.cd_codice_completo,cd_articolo=EXCLUDED.cd_articolo,
  fl_cam=EXCLUDED.fl_cam,ds_tipologia_famiglia=EXCLUDED.ds_tipologia_famiglia,
  ds_capitolo=EXCLUDED.ds_capitolo,ds_voce=EXCLUDED.ds_voce,
  ds_articolo=EXCLUDED.ds_articolo,cd_unita_misura=EXCLUDED.cd_unita_misura,
  dt_update=clock_timestamp(),tx_update_by=p_ds_step_name;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;

 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,2,v_inserted,v_updated,0,0,
  'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
  left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);END IF;
 RAISE WARNING 'Errore initialize DIM_FIRENZE_ARTICOLI: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;$procedure$
