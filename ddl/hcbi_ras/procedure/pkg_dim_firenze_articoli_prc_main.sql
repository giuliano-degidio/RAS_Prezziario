CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_firenze_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
 v_id_log bigint;v_selected bigint:=0;v_inserted bigint:=0;v_updated bigint:=0;
 v_unchanged bigint:=0;v_deleted bigint:=0;v_errors bigint:=0;
 v_duplicate_pk bigint:=0;v_duplicate_cd bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dim_firenze_articoli_src;
 CREATE TABLE hcbi_ras.tmp_dim_firenze_articoli_src AS
 SELECT
        id_firenze_articolo,
        nr_anno,
        ds_regione,
        ds_provincia,
        nr_riga_file,
        cd_codice_completo,
        cd_articolo,
        fl_cam,
        ds_tipologia_famiglia,
        ds_capitolo,
        ds_voce,
        ds_articolo,
        cd_unita_misura,
        nr_prezzo_senza_sg_ui,
        nr_prezzo,
        nr_perc_spese_generali,
        nr_spese_generali,
        nr_perc_utili_impresa,
        nr_utili_impresa,
        nr_perc_oneri_sicurezza_impresa,
        nr_oneri_sicurezza_impresa,
        nr_incidenza_manodopera_indiretta,
        nr_manodopera_indiretta,
        nr_incidenza_manodopera_diretta,
        nr_manodopera_diretta,
        nr_incidenza_oneri_sicurezza_prezzo
 FROM hcbi_ras.v_dim_firenze_articoli_src;
 SELECT count(1) INTO v_selected FROM hcbi_ras.tmp_dim_firenze_articoli_src;
 SELECT count(1) INTO v_duplicate_pk FROM
 (SELECT id_firenze_articolo FROM hcbi_ras.tmp_dim_firenze_articoli_src
  GROUP BY id_firenze_articolo HAVING count(1)>1)d;
 SELECT count(1) INTO v_duplicate_cd FROM
 (SELECT cd_codice_completo FROM hcbi_ras.tmp_dim_firenze_articoli_src
  GROUP BY cd_codice_completo HAVING count(1)>1)d;
 IF v_duplicate_pk>0 OR v_duplicate_cd>0 THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE=format('Duplicati sorgente DIM_FIRENZE_ARTICOLI: PK=%s, CD_CODICE_COMPLETO=%s',v_duplicate_pk,v_duplicate_cd);
 END IF;
 SELECT count(1) INTO v_inserted FROM hcbi_ras.tmp_dim_firenze_articoli_src src
 LEFT JOIN hcbi_ras.dim_firenze_articoli d ON d.id_firenze_articolo=src.id_firenze_articolo
 WHERE d.id_firenze_articolo IS NULL;
 SELECT count(1) INTO v_updated FROM hcbi_ras.tmp_dim_firenze_articoli_src src
 JOIN hcbi_ras.dim_firenze_articoli d ON d.id_firenze_articolo=src.id_firenze_articolo
 WHERE ROW(
            d.nr_anno,
            d.ds_regione,
            d.ds_provincia,
            d.nr_riga_file,
            d.cd_codice_completo,
            d.cd_articolo,
            d.fl_cam,
            d.ds_tipologia_famiglia,
            d.ds_capitolo,
            d.ds_voce,
            d.ds_articolo,
            d.cd_unita_misura,
            d.nr_prezzo_senza_sg_ui,
            d.nr_prezzo,
            d.nr_perc_spese_generali,
            d.nr_spese_generali,
            d.nr_perc_utili_impresa,
            d.nr_utili_impresa,
            d.nr_perc_oneri_sicurezza_impresa,
            d.nr_oneri_sicurezza_impresa,
            d.nr_incidenza_manodopera_indiretta,
            d.nr_manodopera_indiretta,
            d.nr_incidenza_manodopera_diretta,
            d.nr_manodopera_diretta,
            d.nr_incidenza_oneri_sicurezza_prezzo
        ) IS DISTINCT FROM ROW(
            src.nr_anno,
            src.ds_regione,
            src.ds_provincia,
            src.nr_riga_file,
            src.cd_codice_completo,
            src.cd_articolo,
            src.fl_cam,
            src.ds_tipologia_famiglia,
            src.ds_capitolo,
            src.ds_voce,
            src.ds_articolo,
            src.cd_unita_misura,
            src.nr_prezzo_senza_sg_ui,
            src.nr_prezzo,
            src.nr_perc_spese_generali,
            src.nr_spese_generali,
            src.nr_perc_utili_impresa,
            src.nr_utili_impresa,
            src.nr_perc_oneri_sicurezza_impresa,
            src.nr_oneri_sicurezza_impresa,
            src.nr_incidenza_manodopera_indiretta,
            src.nr_manodopera_indiretta,
            src.nr_incidenza_manodopera_diretta,
            src.nr_manodopera_diretta,
            src.nr_incidenza_oneri_sicurezza_prezzo
        );

 INSERT INTO hcbi_ras.dim_firenze_articoli AS d
 (
        id_firenze_articolo,
        nr_anno,
        ds_regione,
        ds_provincia,
        nr_riga_file,
        cd_codice_completo,
        cd_articolo,
        fl_cam,
        ds_tipologia_famiglia,
        ds_capitolo,
        ds_voce,
        ds_articolo,
        cd_unita_misura,
        nr_prezzo_senza_sg_ui,
        nr_prezzo,
        nr_perc_spese_generali,
        nr_spese_generali,
        nr_perc_utili_impresa,
        nr_utili_impresa,
        nr_perc_oneri_sicurezza_impresa,
        nr_oneri_sicurezza_impresa,
        nr_incidenza_manodopera_indiretta,
        nr_manodopera_indiretta,
        nr_incidenza_manodopera_diretta,
        nr_manodopera_diretta,
        nr_incidenza_oneri_sicurezza_prezzo,
        dt_creation,tx_creation_by,dt_update,tx_update_by
 )
 SELECT
        src.id_firenze_articolo,
        src.nr_anno,
        src.ds_regione,
        src.ds_provincia,
        src.nr_riga_file,
        src.cd_codice_completo,
        src.cd_articolo,
        src.fl_cam,
        src.ds_tipologia_famiglia,
        src.ds_capitolo,
        src.ds_voce,
        src.ds_articolo,
        src.cd_unita_misura,
        src.nr_prezzo_senza_sg_ui,
        src.nr_prezzo,
        src.nr_perc_spese_generali,
        src.nr_spese_generali,
        src.nr_perc_utili_impresa,
        src.nr_utili_impresa,
        src.nr_perc_oneri_sicurezza_impresa,
        src.nr_oneri_sicurezza_impresa,
        src.nr_incidenza_manodopera_indiretta,
        src.nr_manodopera_indiretta,
        src.nr_incidenza_manodopera_diretta,
        src.nr_manodopera_diretta,
        src.nr_incidenza_oneri_sicurezza_prezzo,
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
 FROM hcbi_ras.tmp_dim_firenze_articoli_src src
 ON CONFLICT(id_firenze_articolo) DO UPDATE SET
        nr_anno=EXCLUDED.nr_anno,
        ds_regione=EXCLUDED.ds_regione,
        ds_provincia=EXCLUDED.ds_provincia,
        nr_riga_file=EXCLUDED.nr_riga_file,
        cd_codice_completo=EXCLUDED.cd_codice_completo,
        cd_articolo=EXCLUDED.cd_articolo,
        fl_cam=EXCLUDED.fl_cam,
        ds_tipologia_famiglia=EXCLUDED.ds_tipologia_famiglia,
        ds_capitolo=EXCLUDED.ds_capitolo,
        ds_voce=EXCLUDED.ds_voce,
        ds_articolo=EXCLUDED.ds_articolo,
        cd_unita_misura=EXCLUDED.cd_unita_misura,
        nr_prezzo_senza_sg_ui=EXCLUDED.nr_prezzo_senza_sg_ui,
        nr_prezzo=EXCLUDED.nr_prezzo,
        nr_perc_spese_generali=EXCLUDED.nr_perc_spese_generali,
        nr_spese_generali=EXCLUDED.nr_spese_generali,
        nr_perc_utili_impresa=EXCLUDED.nr_perc_utili_impresa,
        nr_utili_impresa=EXCLUDED.nr_utili_impresa,
        nr_perc_oneri_sicurezza_impresa=EXCLUDED.nr_perc_oneri_sicurezza_impresa,
        nr_oneri_sicurezza_impresa=EXCLUDED.nr_oneri_sicurezza_impresa,
        nr_incidenza_manodopera_indiretta=EXCLUDED.nr_incidenza_manodopera_indiretta,
        nr_manodopera_indiretta=EXCLUDED.nr_manodopera_indiretta,
        nr_incidenza_manodopera_diretta=EXCLUDED.nr_incidenza_manodopera_diretta,
        nr_manodopera_diretta=EXCLUDED.nr_manodopera_diretta,
        nr_incidenza_oneri_sicurezza_prezzo=EXCLUDED.nr_incidenza_oneri_sicurezza_prezzo,
        dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 WHERE ROW(
            d.nr_anno,
            d.ds_regione,
            d.ds_provincia,
            d.nr_riga_file,
            d.cd_codice_completo,
            d.cd_articolo,
            d.fl_cam,
            d.ds_tipologia_famiglia,
            d.ds_capitolo,
            d.ds_voce,
            d.ds_articolo,
            d.cd_unita_misura,
            d.nr_prezzo_senza_sg_ui,
            d.nr_prezzo,
            d.nr_perc_spese_generali,
            d.nr_spese_generali,
            d.nr_perc_utili_impresa,
            d.nr_utili_impresa,
            d.nr_perc_oneri_sicurezza_impresa,
            d.nr_oneri_sicurezza_impresa,
            d.nr_incidenza_manodopera_indiretta,
            d.nr_manodopera_indiretta,
            d.nr_incidenza_manodopera_diretta,
            d.nr_manodopera_diretta,
            d.nr_incidenza_oneri_sicurezza_prezzo
        ) IS DISTINCT FROM ROW(
            EXCLUDED.nr_anno,
            EXCLUDED.ds_regione,
            EXCLUDED.ds_provincia,
            EXCLUDED.nr_riga_file,
            EXCLUDED.cd_codice_completo,
            EXCLUDED.cd_articolo,
            EXCLUDED.fl_cam,
            EXCLUDED.ds_tipologia_famiglia,
            EXCLUDED.ds_capitolo,
            EXCLUDED.ds_voce,
            EXCLUDED.ds_articolo,
            EXCLUDED.cd_unita_misura,
            EXCLUDED.nr_prezzo_senza_sg_ui,
            EXCLUDED.nr_prezzo,
            EXCLUDED.nr_perc_spese_generali,
            EXCLUDED.nr_spese_generali,
            EXCLUDED.nr_perc_utili_impresa,
            EXCLUDED.nr_utili_impresa,
            EXCLUDED.nr_perc_oneri_sicurezza_impresa,
            EXCLUDED.nr_oneri_sicurezza_impresa,
            EXCLUDED.nr_incidenza_manodopera_indiretta,
            EXCLUDED.nr_manodopera_indiretta,
            EXCLUDED.nr_incidenza_manodopera_diretta,
            EXCLUDED.nr_manodopera_diretta,
            EXCLUDED.nr_incidenza_oneri_sicurezza_prezzo
        );
 v_unchanged:=v_selected-v_inserted-v_updated;
 IF v_unchanged<0 THEN RAISE EXCEPTION 'Riconciliazione DIM non valida';END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
  'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_dim_firenze_articoli_src;p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;DROP TABLE IF EXISTS hcbi_ras.tmp_dim_firenze_articoli_src;
 IF v_id_log IS NOT NULL THEN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
  left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);END IF;
 RAISE WARNING 'Errore main DIM_FIRENZE_ARTICOLI: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;$procedure$
