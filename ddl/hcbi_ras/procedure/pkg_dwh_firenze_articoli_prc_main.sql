CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_firenze_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint;v_selected bigint:=0;v_inserted bigint:=0;v_updated bigint:=0;v_rejected bigint:=0;v_unchanged bigint:=0;
BEGIN
 p_result:=-1;SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_articoli_classificata;
 CREATE TABLE hcbi_ras.tmp_dwh_firenze_articoli_classificata AS SELECT nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,cd_esito,cd_motivo_scarto,tx_motivo_scarto FROM hcbi_ras.v_dwh_firenze_articoli_classificata;
 SELECT count(*) FILTER(WHERE cd_esito='LOAD'),count(*) FILTER(WHERE cd_esito='REJECT') INTO v_selected,v_rejected FROM hcbi_ras.tmp_dwh_firenze_articoli_classificata;
 DELETE FROM hcbi_ras.dwh_firenze_articoli_rej WHERE id_chain_log=p_id_chain_log AND id_step=p_id_step;
 INSERT INTO hcbi_ras.dwh_firenze_articoli_rej(nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,cd_esito,cd_motivo_scarto,tx_motivo_scarto,id_chain_log,id_chain,id_step,ds_step_name)
 SELECT nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,cd_esito,cd_motivo_scarto,tx_motivo_scarto,p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name FROM hcbi_ras.tmp_dwh_firenze_articoli_classificata WHERE cd_esito='REJECT';
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_articoli;
 CREATE TABLE hcbi_ras.tmp_dwh_firenze_articoli AS SELECT nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo FROM hcbi_ras.v_dwh_firenze_articoli;
 CREATE UNIQUE INDEX tmp_dwh_firenze_articoli_uq ON hcbi_ras.tmp_dwh_firenze_articoli(nr_anno,nr_riga_file) NULLS NOT DISTINCT;
 ANALYZE hcbi_ras.tmp_dwh_firenze_articoli;
 UPDATE hcbi_ras.dwh_firenze_articoli d SET
        ds_regione=s.ds_regione,
        ds_provincia=s.ds_provincia,
        cd_codice_completo=s.cd_codice_completo,
        fl_cam=s.fl_cam,
        ds_tipologia_famiglia=s.ds_tipologia_famiglia,
        ds_capitolo=s.ds_capitolo,
        ds_voce=s.ds_voce,
        ds_articolo=s.ds_articolo,
        cd_unita_misura=s.cd_unita_misura,
        nr_prezzo_senza_sg_ui=s.nr_prezzo_senza_sg_ui,
        nr_prezzo=s.nr_prezzo,
        nr_perc_spese_generali=s.nr_perc_spese_generali,
        nr_spese_generali=s.nr_spese_generali,
        nr_perc_utili_impresa=s.nr_perc_utili_impresa,
        nr_utili_impresa=s.nr_utili_impresa,
        nr_perc_oneri_sicurezza_impresa=s.nr_perc_oneri_sicurezza_impresa,
        nr_oneri_sicurezza_impresa=s.nr_oneri_sicurezza_impresa,
        nr_incidenza_manodopera_indiretta=s.nr_incidenza_manodopera_indiretta,
        nr_manodopera_indiretta=s.nr_manodopera_indiretta,
        nr_incidenza_manodopera_diretta=s.nr_incidenza_manodopera_diretta,
        nr_manodopera_diretta=s.nr_manodopera_diretta,
        nr_incidenza_oneri_sicurezza_prezzo=s.nr_incidenza_oneri_sicurezza_prezzo,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 FROM hcbi_ras.tmp_dwh_firenze_articoli s
 WHERE d.nr_anno=s.nr_anno AND d.nr_riga_file=s.nr_riga_file
   AND ROW(d.ds_regione,d.ds_provincia,d.cd_codice_completo,d.fl_cam,d.ds_tipologia_famiglia,d.ds_capitolo,d.ds_voce,d.ds_articolo,d.cd_unita_misura,d.nr_prezzo_senza_sg_ui,d.nr_prezzo,d.nr_perc_spese_generali,d.nr_spese_generali,d.nr_perc_utili_impresa,d.nr_utili_impresa,d.nr_perc_oneri_sicurezza_impresa,d.nr_oneri_sicurezza_impresa,d.nr_incidenza_manodopera_indiretta,d.nr_manodopera_indiretta,d.nr_incidenza_manodopera_diretta,d.nr_manodopera_diretta,d.nr_incidenza_oneri_sicurezza_prezzo) IS DISTINCT FROM ROW(s.ds_regione,s.ds_provincia,s.cd_codice_completo,s.fl_cam,s.ds_tipologia_famiglia,s.ds_capitolo,s.ds_voce,s.ds_articolo,s.cd_unita_misura,s.nr_prezzo_senza_sg_ui,s.nr_prezzo,s.nr_perc_spese_generali,s.nr_spese_generali,s.nr_perc_utili_impresa,s.nr_utili_impresa,s.nr_perc_oneri_sicurezza_impresa,s.nr_oneri_sicurezza_impresa,s.nr_incidenza_manodopera_indiretta,s.nr_manodopera_indiretta,s.nr_incidenza_manodopera_diretta,s.nr_manodopera_diretta,s.nr_incidenza_oneri_sicurezza_prezzo);
 GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_firenze_articoli(nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,dt_creation,tx_creation_by,dt_update,tx_update_by)
 SELECT nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_codice_completo,fl_cam,ds_tipologia_famiglia,ds_capitolo,ds_voce,ds_articolo,cd_unita_misura,nr_prezzo_senza_sg_ui,nr_prezzo,nr_perc_spese_generali,nr_spese_generali,nr_perc_utili_impresa,nr_utili_impresa,nr_perc_oneri_sicurezza_impresa,nr_oneri_sicurezza_impresa,nr_incidenza_manodopera_indiretta,nr_manodopera_indiretta,nr_incidenza_manodopera_diretta,nr_manodopera_diretta,nr_incidenza_oneri_sicurezza_prezzo,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_firenze_articoli
 ON CONFLICT(nr_anno,nr_riga_file) DO NOTHING;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 v_unchanged:=v_selected-v_inserted-v_updated;
 IF v_unchanged<0 THEN RAISE EXCEPTION 'Riconciliazione DWH non valida load=%, inserted=%, updated=%',v_selected,v_inserted,v_updated;END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected+v_rejected,v_inserted,v_updated,0,v_rejected,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_dwh_firenze_articoli;DROP TABLE hcbi_ras.tmp_dwh_firenze_articoli_classificata;p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_articoli;DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_articoli_classificata;
 IF v_id_log IS NOT NULL THEN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'
MESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);END IF;
 RAISE WARNING 'Errore DWH main FIRENZE_ARTICOLI: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;$procedure$
