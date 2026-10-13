CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0;
 v_rejected bigint:=0; v_updated bigint:=0; v_deleted bigint:=0;
BEGIN
 p_result := -1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_rilevati_classificata;
 CREATE TABLE hcbi_ras.tmp_prezzi_rilevati_classificata AS
 WITH src AS MATERIALIZED (
  SELECT f.*,
   NULLIF(btrim(f.cd_articolo),'') codice_txt,
   NULLIF(btrim(f.ds_anno),'') anno_txt,
   NULLIF(btrim(f.id_sorgente_provincia),'') provincia_txt,
   NULLIF(btrim(f.id_sorgente_informatore),'') informatore_txt,
   NULLIF(btrim(f.id_sorgente_rilevatore),'') rilevatore_txt,
   NULLIF(btrim(f.nr_prezzo),'') prezzo_txt,
   NULLIF(btrim(f.fl_nascosto),'') nascosto_txt,
   NULLIF(btrim(f.ds_anno_ribaltamento),'') rib_anno_txt,
   NULLIF(btrim(f.cd_versione),'') addendum_txt,
   NULLIF(btrim(f.cd_versione_ribaltamento),'') rib_addendum_txt,
   count(*) OVER(PARTITION BY f.cd_articolo,f.ds_anno,f.id_sorgente_provincia,
                              f.cd_versione,f.id_sorgente_informatore) duplicate_count
  FROM hcbi_ras.v_src_tmp_prezzi_rilevati f
 ), cv AS MATERIALIZED (
  SELECT s.*,
   s.codice_txt codice_cv, hcbi_ras.try_integer(s.anno_txt) anno_cv,
   hcbi_ras.try_integer(s.provincia_txt) provincia_cv,
   hcbi_ras.try_integer(s.informatore_txt) informatore_cv,
   hcbi_ras.try_integer(s.rilevatore_txt) rilevatore_cv,
   hcbi_ras.try_numeric_24_5(replace(s.prezzo_txt,',','.')) prezzo_cv,
   hcbi_ras.try_smallint(s.nascosto_txt) nascosto_cv,
   hcbi_ras.try_integer(s.rib_anno_txt) rib_anno_cv,
   hcbi_ras.try_smallint(s.addendum_txt) addendum_cv,
   hcbi_ras.try_integer(s.rib_addendum_txt) rib_addendum_cv
  FROM src s
 )
 SELECT cv.*,
  CASE
   WHEN duplicate_count>1 THEN 'Chiave duplicata: (codice, anno, provincia, addendum, informatore)'
   WHEN codice_txt IS NULL THEN 'codice obbligatorio'
   WHEN length(codice_txt)>60 THEN 'codice eccede 60 caratteri'
   WHEN anno_txt IS NULL THEN 'anno obbligatorio'
   WHEN anno_cv IS NULL THEN 'anno non convertibile o fuori dominio integer'
   WHEN provincia_txt IS NULL THEN 'provincia obbligatoria'
   WHEN provincia_cv IS NULL THEN 'provincia non convertibile o fuori dominio integer'
   WHEN informatore_txt IS NULL THEN 'informatore obbligatorio'
   WHEN informatore_cv IS NULL THEN 'informatore non convertibile o fuori dominio integer'
   WHEN rilevatore_txt IS NULL THEN 'rilevatore obbligatorio'
   WHEN rilevatore_cv IS NULL THEN 'rilevatore non convertibile o fuori dominio integer'
   WHEN prezzo_txt IS NULL THEN 'prezzo obbligatorio'
   WHEN prezzo_cv IS NULL THEN 'prezzo non convertibile o fuori dominio numeric(24,5)'
   WHEN dt_inserimento IS NULL THEN 'data_inserimento obbligatoria'
   WHEN nascosto_txt IS NULL THEN 'nascosto obbligatorio'
   WHEN nascosto_cv IS NULL OR nascosto_cv NOT IN (0,1) THEN 'nascosto deve valere 0 o 1'
   WHEN addendum_txt IS NULL THEN 'addendum obbligatorio'
   WHEN addendum_cv IS NULL THEN 'addendum non convertibile o fuori dominio smallint'
   WHEN dt_last_update IS NULL THEN 'last_update obbligatorio'
   WHEN rib_anno_txt IS NOT NULL AND rib_anno_cv IS NULL THEN 'ribaltato_da_anno non convertibile'
   WHEN rib_addendum_txt IS NOT NULL AND rib_addendum_cv IS NULL THEN 'ribaltato_da_addendum non convertibile'
   ELSE NULL END::text tx_motivo_scarto
 FROM cv;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_prezzi_rilevati_classificata;
 INSERT INTO hcbi_ras.stg_prezzi_rilevati
 SELECT codice_cv,anno_cv,provincia_cv,informatore_cv,rilevatore_cv,prezzo_cv,
        dt_inserimento,nascosto_cv,rib_anno_cv,addendum_cv,rib_addendum_cv,dt_last_update
 FROM hcbi_ras.tmp_prezzi_rilevati_classificata WHERE tx_motivo_scarto IS NULL;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_prezzi_rilevati_rej
 (cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
  nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
  cd_versione_ribaltamento,dt_last_update,tx_motivo_scarto)
 SELECT cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
        nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
        cd_versione_ribaltamento,dt_last_update,tx_motivo_scarto
 FROM hcbi_ras.tmp_prezzi_rilevati_classificata WHERE tx_motivo_scarto IS NOT NULL;
 GET DIAGNOSTICS v_rejected=ROW_COUNT;
 IF v_selected<>v_inserted+v_rejected THEN
  RAISE EXCEPTION 'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',v_selected,v_inserted,v_rejected;
 END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,
   v_rejected,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_prezzi_rilevati_classificata;
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1; DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_rilevati_classificata;
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
   left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore main STG PREZZI_RILEVATI: %',SQLERRM;
END;$procedure$
