CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_sel bigint:=0; v_ins bigint:=0; v_upd bigint:=0; v_err bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
   p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
 INTO v_id_log;

 IF NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_informatori WHERE id_anag_informatore=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_utenti WHERE id_anag_utente=-1) THEN
  RAISE EXCEPTION 'Membri tecnici -1 mancanti nelle dimensioni della fact';
 END IF;

 DROP TABLE IF EXISTS tmp_fct_prezzi_rilevati_src;
 CREATE TEMP TABLE tmp_fct_prezzi_rilevati_src ON COMMIT DROP AS
 SELECT * FROM hcbi_ras.v_fct_prezzi_rilevati_src;

 SELECT count(*) INTO v_sel FROM tmp_fct_prezzi_rilevati_src;
 IF v_sel<>(SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati) THEN
  RAISE EXCEPTION 'Cardinalita vista (%) diversa dal DWH (%)',v_sel,(SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati);
 END IF;
 IF EXISTS(SELECT 1 FROM tmp_fct_prezzi_rilevati_src GROUP BY id_prezzi_rilevati HAVING count(*)>1) THEN
  RAISE EXCEPTION 'Lookup non univoci nella vista FCT_PREZZI_RILEVATI';
 END IF;
 SELECT count(*) INTO v_err FROM tmp_fct_prezzi_rilevati_src WHERE tx_motivo_lookup IS NOT NULL;
 SELECT count(*) INTO v_ins FROM tmp_fct_prezzi_rilevati_src s LEFT JOIN hcbi_ras.fct_prezzi_rilevati f USING(id_prezzi_rilevati) WHERE f.id_prezzi_rilevati IS NULL;
 SELECT count(*) INTO v_upd FROM tmp_fct_prezzi_rilevati_src s JOIN hcbi_ras.fct_prezzi_rilevati f USING(id_prezzi_rilevati)
 WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_versione,f.id_anag_articolo,f.id_anag_informatore,f.id_anag_utente_rilevatore,f.nr_prezzo,f.dt_inserimento,f.fl_nascosto,f.ds_anno_ribaltamento,f.cd_versione_ribaltamento,f.dt_last_update)
 IS DISTINCT FROM ROW(s.id_periodo_pubblicazione,s.id_anag_provincia,s.id_anag_versione,s.id_anag_articolo,s.id_anag_informatore,s.id_anag_utente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,s.ds_anno_ribaltamento,s.cd_versione_ribaltamento,s.dt_last_update);

 INSERT INTO hcbi_ras.fct_prezzi_rilevati AS f
 (id_prezzi_rilevati,id_periodo_pubblicazione,id_anag_provincia,id_anag_versione,
  id_anag_articolo,id_anag_informatore,id_anag_utente_rilevatore,nr_prezzo,
  dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione_ribaltamento,
  dt_last_update,dt_creation,tx_creation_by,dt_update,tx_update_by)
 SELECT id_prezzi_rilevati,id_periodo_pubblicazione,id_anag_provincia,id_anag_versione,
  id_anag_articolo,id_anag_informatore,id_anag_utente_rilevatore,nr_prezzo,
  dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione_ribaltamento,
  dt_last_update,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
 FROM tmp_fct_prezzi_rilevati_src
 ON CONFLICT(id_prezzi_rilevati) DO UPDATE SET
  id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
  id_anag_provincia=EXCLUDED.id_anag_provincia,
  id_anag_versione=EXCLUDED.id_anag_versione,
  id_anag_articolo=EXCLUDED.id_anag_articolo,
  id_anag_informatore=EXCLUDED.id_anag_informatore,
  id_anag_utente_rilevatore=EXCLUDED.id_anag_utente_rilevatore,
  nr_prezzo=EXCLUDED.nr_prezzo,dt_inserimento=EXCLUDED.dt_inserimento,
  fl_nascosto=EXCLUDED.fl_nascosto,ds_anno_ribaltamento=EXCLUDED.ds_anno_ribaltamento,
  cd_versione_ribaltamento=EXCLUDED.cd_versione_ribaltamento,
  dt_last_update=EXCLUDED.dt_last_update,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_versione,f.id_anag_articolo,f.id_anag_informatore,f.id_anag_utente_rilevatore,f.nr_prezzo,f.dt_inserimento,f.fl_nascosto,f.ds_anno_ribaltamento,f.cd_versione_ribaltamento,f.dt_last_update)
 IS DISTINCT FROM ROW(EXCLUDED.id_periodo_pubblicazione,EXCLUDED.id_anag_provincia,EXCLUDED.id_anag_versione,EXCLUDED.id_anag_articolo,EXCLUDED.id_anag_informatore,EXCLUDED.id_anag_utente_rilevatore,EXCLUDED.nr_prezzo,EXCLUDED.dt_inserimento,EXCLUDED.fl_nascosto,EXCLUDED.ds_anno_ribaltamento,EXCLUDED.cd_versione_ribaltamento,EXCLUDED.dt_last_update);

 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_sel,v_ins,v_upd,0,v_err,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
 END IF;
 RAISE;
END;$procedure$
