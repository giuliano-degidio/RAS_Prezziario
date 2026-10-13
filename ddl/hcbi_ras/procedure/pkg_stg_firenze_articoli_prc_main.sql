CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_firenze_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint;v_selected bigint:=0;v_inserted bigint:=0;v_rejected bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_firenze_articoli_stg_classificata;
 CREATE TABLE hcbi_ras.tmp_firenze_articoli_stg_classificata AS
 WITH src AS MATERIALIZED
 (
   SELECT f.*,hcbi_ras.try_integer(nullif(btrim(f.nr_anno),'')) nr_anno_c,
          hcbi_ras.try_bigint(nullif(btrim(f.nr_riga_file),'')) nr_riga_file_c,
          count(*) OVER(PARTITION BY f.nr_anno,f.nr_riga_file) duplicate_count
   FROM hcbi_ras.v_src_tmp_firenze_articoli f
 )
 SELECT s.*,CASE
   WHEN duplicate_count>1 THEN 'Chiave sorgente duplicata: (nr_anno, nr_riga_file)'
   WHEN nr_anno_c IS NULL THEN 'nr_anno obbligatorio o non convertibile in integer'
   WHEN nr_riga_file_c IS NULL THEN 'nr_riga_file obbligatorio o non convertibile in bigint'
   WHEN nullif(btrim(ds_regione),'') IS NULL THEN 'ds_regione obbligatoria'
   WHEN nullif(btrim(ds_provincia),'') IS NULL THEN 'ds_provincia obbligatoria'
   ELSE NULL END::text tx_motivo_scarto
 FROM src s;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_firenze_articoli_stg_classificata;
 INSERT INTO hcbi_ras.stg_firenze_articoli(nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo)
 SELECT nr_anno_c,btrim(ds_regione),btrim(ds_provincia),nr_riga_file_c,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo
 FROM hcbi_ras.tmp_firenze_articoli_stg_classificata WHERE tx_motivo_scarto IS NULL;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_firenze_articoli_rej(nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,tx_motivo_scarto)
 SELECT nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,tx_motivo_scarto FROM hcbi_ras.tmp_firenze_articoli_stg_classificata WHERE tx_motivo_scarto IS NOT NULL;
 GET DIAGNOSTICS v_rejected=ROW_COUNT;
 IF v_selected<>v_inserted+v_rejected THEN RAISE EXCEPTION 'Riconciliazione STG non valida selected=%, inserted=%, rejected=%',v_selected,v_inserted,v_rejected; END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,0,0,v_rejected,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_firenze_articoli_stg_classificata;p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;DROP TABLE IF EXISTS hcbi_ras.tmp_firenze_articoli_stg_classificata;
 IF v_id_log IS NOT NULL THEN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'
MESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name); END IF;
 RAISE WARNING 'Errore STG main FIRENZE_ARTICOLI: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;$procedure$
