CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
  v_id_log bigint; v_selected bigint := 0; v_inserted bigint := 0;
  v_updated bigint := 0; v_deleted bigint := 0; v_errors bigint := 0;
  v_duplicate_rows bigint := 0;
BEGIN
  p_result := -1;
  SELECT hcbi_utility.pkg_log_fnc_insert_log(
    p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
    clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
  INTO v_id_log;

  IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = 0)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = -1)
  THEN
    RAISE EXCEPTION USING
      ERRCODE = '23503',
      MESSAGE = 'Membro tecnico richiesto (-1 oppure 0 per DIM_ARTICOLO) mancante';
  END IF;

  DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_albero_src;
  CREATE TABLE hcbi_ras.tmp_fct_pubblicazione_albero_src AS
  SELECT * FROM hcbi_ras.v_fct_pubblicazione_albero_src;

  SELECT count(*) INTO v_selected FROM hcbi_ras.dwh_pubblicazione_albero;
  SELECT count(*) INTO v_duplicate_rows
  FROM (SELECT id_pubblicazione_albero FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
        GROUP BY id_pubblicazione_albero HAVING count(*) > 1) AS d;
  IF v_duplicate_rows > 0 THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE=format('Lookup non univoci per %s record PUBBLICAZIONE_ALBERO',v_duplicate_rows),
      HINT='Verificare unicita di DIM_PERIODO, DIM_PROVINCIA, DIM_VERSIONE e della mappa articolo.';
  END IF;

  SELECT count(*)
  INTO v_errors
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
  WHERE tx_motivo_scarto IS NOT NULL;

  SELECT count(*)
  INTO v_inserted
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src AS src
  LEFT JOIN hcbi_ras.fct_pubblicazione_albero AS f
    ON f.id_pubblicazione_albero = src.id_pubblicazione_albero
  WHERE f.id_pubblicazione_albero IS NULL;

  SELECT count(*)
  INTO v_updated
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src AS src
  JOIN hcbi_ras.fct_pubblicazione_albero AS f
    ON f.id_pubblicazione_albero = src.id_pubblicazione_albero
  WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_articolo,
            f.id_anag_versione,f.nr_prezzo,f.id_sorgente_um,f.fl_isanalisi,
            f.fl_isincidenza,f.nr_scostamento,f.nr_scostamento_con_spese,
            f.fl_is_nuovo_codice,f.fl_is_prezzo_modificato,
            f.fl_is_prezzo_con_spese_modificato,f.fl_is_analisi_modificata,
            f.fl_is_descrizione_modificata,f.fl_is_uinta_misura_modificata,
            f.fl_is_spese_generali_modificate,f.fl_is_utili_impresa_modificati,
            f.fl_is_oneri_sicurezza_modificati,f.fl_is_ufficiale,
            f.id_sorgente_categoria,f.ds_nome,f.ds_link_cam,f.ds_annotazione,
            f.id_sorgente_pubblicazione_albero,f.fl_esporta_come_articolo,
            f.fl_escludi_manodopera,f.fl_mostra_struttura_analisi,
            f.id_anag_macro_gruppo,f.fl_is_cam)
     IS DISTINCT FROM
        ROW(src.id_periodo_pubblicazione,src.id_anag_provincia,
            src.id_anag_articolo,src.id_anag_versione,src.nr_prezzo,
            src.id_sorgente_um,src.fl_isanalisi,src.fl_isincidenza,
            src.nr_scostamento,src.nr_scostamento_con_spese,
            src.fl_is_nuovo_codice,src.fl_is_prezzo_modificato,
            src.fl_is_prezzo_con_spese_modificato,src.fl_is_analisi_modificata,
            src.fl_is_descrizione_modificata,src.fl_is_uinta_misura_modificata,
            src.fl_is_spese_generali_modificate,src.fl_is_utili_impresa_modificati,
            src.fl_is_oneri_sicurezza_modificati,src.fl_is_ufficiale,
            src.id_sorgente_categoria,src.ds_nome,src.ds_link_cam,src.ds_annotazione,
            src.id_sorgente_pubblicazione_albero,src.fl_esporta_come_articolo,
            src.fl_escludi_manodopera,src.fl_mostra_struttura_analisi,
            src.id_anag_macro_gruppo,src.fl_is_cam);

  INSERT INTO hcbi_ras.fct_pubblicazione_albero AS f
  (id_pubblicazione_albero,id_periodo_pubblicazione,id_anag_provincia,
   id_anag_articolo,id_anag_versione,nr_prezzo,id_sorgente_um,fl_isanalisi,
   fl_isincidenza,nr_scostamento,nr_scostamento_con_spese,fl_is_nuovo_codice,
   fl_is_prezzo_modificato,fl_is_prezzo_con_spese_modificato,
   fl_is_analisi_modificata,fl_is_descrizione_modificata,
   fl_is_uinta_misura_modificata,fl_is_spese_generali_modificate,
   fl_is_utili_impresa_modificati,fl_is_oneri_sicurezza_modificati,
   fl_is_ufficiale,id_sorgente_categoria,ds_nome,ds_link_cam,ds_annotazione,
   id_sorgente_pubblicazione_albero,fl_esporta_come_articolo,
   fl_escludi_manodopera,fl_mostra_struttura_analisi,id_anag_macro_gruppo,fl_is_cam,
   dt_creation,tx_creation_by,dt_update,tx_update_by)
  SELECT id_pubblicazione_albero,id_periodo_pubblicazione,id_anag_provincia,
   id_anag_articolo,id_anag_versione,nr_prezzo,id_sorgente_um,fl_isanalisi,
   fl_isincidenza,nr_scostamento,nr_scostamento_con_spese,fl_is_nuovo_codice,
   fl_is_prezzo_modificato,fl_is_prezzo_con_spese_modificato,
   fl_is_analisi_modificata,fl_is_descrizione_modificata,
   fl_is_uinta_misura_modificata,fl_is_spese_generali_modificate,
   fl_is_utili_impresa_modificati,fl_is_oneri_sicurezza_modificati,
   fl_is_ufficiale,id_sorgente_categoria,ds_nome,ds_link_cam,ds_annotazione,
   id_sorgente_pubblicazione_albero,fl_esporta_come_articolo,
   fl_escludi_manodopera,fl_mostra_struttura_analisi,id_anag_macro_gruppo,fl_is_cam,
   clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
  ON CONFLICT (id_pubblicazione_albero) DO UPDATE SET
    id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
    id_anag_provincia=EXCLUDED.id_anag_provincia,
    id_anag_articolo=EXCLUDED.id_anag_articolo,
    id_anag_versione=EXCLUDED.id_anag_versione,
    nr_prezzo=EXCLUDED.nr_prezzo,id_sorgente_um=EXCLUDED.id_sorgente_um,
    fl_isanalisi=EXCLUDED.fl_isanalisi,fl_isincidenza=EXCLUDED.fl_isincidenza,
    nr_scostamento=EXCLUDED.nr_scostamento,
    nr_scostamento_con_spese=EXCLUDED.nr_scostamento_con_spese,
    fl_is_nuovo_codice=EXCLUDED.fl_is_nuovo_codice,
    fl_is_prezzo_modificato=EXCLUDED.fl_is_prezzo_modificato,
    fl_is_prezzo_con_spese_modificato=EXCLUDED.fl_is_prezzo_con_spese_modificato,
    fl_is_analisi_modificata=EXCLUDED.fl_is_analisi_modificata,
    fl_is_descrizione_modificata=EXCLUDED.fl_is_descrizione_modificata,
    fl_is_uinta_misura_modificata=EXCLUDED.fl_is_uinta_misura_modificata,
    fl_is_spese_generali_modificate=EXCLUDED.fl_is_spese_generali_modificate,
    fl_is_utili_impresa_modificati=EXCLUDED.fl_is_utili_impresa_modificati,
    fl_is_oneri_sicurezza_modificati=EXCLUDED.fl_is_oneri_sicurezza_modificati,
    fl_is_ufficiale=EXCLUDED.fl_is_ufficiale,
    id_sorgente_categoria=EXCLUDED.id_sorgente_categoria,
    ds_nome=EXCLUDED.ds_nome,ds_link_cam=EXCLUDED.ds_link_cam,
    ds_annotazione=EXCLUDED.ds_annotazione,
    id_sorgente_pubblicazione_albero=EXCLUDED.id_sorgente_pubblicazione_albero,
    fl_esporta_come_articolo=EXCLUDED.fl_esporta_come_articolo,
    fl_escludi_manodopera=EXCLUDED.fl_escludi_manodopera,
    fl_mostra_struttura_analisi=EXCLUDED.fl_mostra_struttura_analisi,
    id_anag_macro_gruppo=EXCLUDED.id_anag_macro_gruppo,fl_is_cam=EXCLUDED.fl_is_cam,
    dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
  WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_articolo,
            f.id_anag_versione,f.nr_prezzo,f.id_sorgente_um,f.fl_isanalisi,
            f.fl_isincidenza,f.nr_scostamento,f.nr_scostamento_con_spese,
            f.fl_is_nuovo_codice,f.fl_is_prezzo_modificato,
            f.fl_is_prezzo_con_spese_modificato,f.fl_is_analisi_modificata,
            f.fl_is_descrizione_modificata,f.fl_is_uinta_misura_modificata,
            f.fl_is_spese_generali_modificate,f.fl_is_utili_impresa_modificati,
            f.fl_is_oneri_sicurezza_modificati,f.fl_is_ufficiale,
            f.id_sorgente_categoria,f.ds_nome,f.ds_link_cam,f.ds_annotazione,
            f.id_sorgente_pubblicazione_albero,f.fl_esporta_come_articolo,
            f.fl_escludi_manodopera,f.fl_mostra_struttura_analisi,
            f.id_anag_macro_gruppo,f.fl_is_cam)
     IS DISTINCT FROM
        ROW(EXCLUDED.id_periodo_pubblicazione,EXCLUDED.id_anag_provincia,
            EXCLUDED.id_anag_articolo,EXCLUDED.id_anag_versione,
            EXCLUDED.nr_prezzo,EXCLUDED.id_sorgente_um,EXCLUDED.fl_isanalisi,
            EXCLUDED.fl_isincidenza,EXCLUDED.nr_scostamento,
            EXCLUDED.nr_scostamento_con_spese,EXCLUDED.fl_is_nuovo_codice,
            EXCLUDED.fl_is_prezzo_modificato,
            EXCLUDED.fl_is_prezzo_con_spese_modificato,
            EXCLUDED.fl_is_analisi_modificata,EXCLUDED.fl_is_descrizione_modificata,
            EXCLUDED.fl_is_uinta_misura_modificata,
            EXCLUDED.fl_is_spese_generali_modificate,
            EXCLUDED.fl_is_utili_impresa_modificati,
            EXCLUDED.fl_is_oneri_sicurezza_modificati,EXCLUDED.fl_is_ufficiale,
            EXCLUDED.id_sorgente_categoria,EXCLUDED.ds_nome,EXCLUDED.ds_link_cam,
            EXCLUDED.ds_annotazione,EXCLUDED.id_sorgente_pubblicazione_albero,
            EXCLUDED.fl_esporta_come_articolo,EXCLUDED.fl_escludi_manodopera,
            EXCLUDED.fl_mostra_struttura_analisi,EXCLUDED.id_anag_macro_gruppo,
            EXCLUDED.fl_is_cam);
  IF v_selected <> (SELECT count(*) FROM hcbi_ras.tmp_fct_pubblicazione_albero_src) THEN
    RAISE EXCEPTION 'La vista di lookup ha alterato la cardinalita sorgente';
  END IF;

  CALL hcbi_utility.pkg_log_prc_update_log(
    v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,'SUCCESS',
    clock_timestamp()::timestamp,p_ds_step_name);
  DROP TABLE hcbi_ras.tmp_fct_pubblicazione_albero_src;
  p_result := 1;
EXCEPTION WHEN OTHERS THEN
  p_result := -1;
  BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_albero_src; EXCEPTION WHEN OTHERS THEN NULL; END;
  IF v_id_log IS NOT NULL THEN
    CALL hcbi_utility.pkg_log_prc_error_update_log(
      v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
      clock_timestamp()::timestamp,p_ds_step_name);
  END IF;
  RAISE WARNING 'Errore main FCT_PUBBLICAZIONE_ALBERO: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$procedure$
