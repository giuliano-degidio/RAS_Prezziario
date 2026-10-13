CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_firenze_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
 v_id_log bigint;v_selected bigint:=0;v_inserted bigint:=0;v_updated bigint:=0;
 v_unchanged bigint:=0;v_deleted bigint:=0;v_errors bigint:=0;
 v_duplicate_pk bigint:=0;v_lookup_minus_one bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
   clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;

 DROP TABLE IF EXISTS hcbi_ras.tmp_fct_firenze_analisi_src;
 CREATE TABLE hcbi_ras.tmp_fct_firenze_analisi_src AS
 SELECT
        id_firenze_analisi,
        id_firenze_articolo,
        nr_anno,
        ds_regione,
        ds_provincia,
        nr_riga_file,
        cd_analisi,
        ds_analisi,
        fl_cam,
        cd_dettaglio_cam,
        ds_voce_articolo,
        cd_collegato,
        cd_unita_misura,
        nr_quantita,
        nr_prezzo_unitario,
        nr_importo,
        tx_nome_file,
        dt_caricamento,
        tx_caricamento_by,
        cd_codice_completo_lookup,tx_motivo_lookup
 FROM hcbi_ras.v_fct_firenze_analisi_src;

 SELECT count(1) INTO v_selected FROM hcbi_ras.dwh_firenze_analisi;
 SELECT count(1) INTO v_duplicate_pk FROM
 (SELECT id_firenze_analisi FROM hcbi_ras.tmp_fct_firenze_analisi_src
  GROUP BY id_firenze_analisi HAVING count(1)>1) d;
 SELECT count(1) INTO v_lookup_minus_one
 FROM hcbi_ras.tmp_fct_firenze_analisi_src WHERE id_firenze_articolo=-1;
 v_errors:=v_duplicate_pk+v_lookup_minus_one;

 IF v_duplicate_pk>0 THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE=format('Lookup CD_CODICE_COMPLETO non univoco per %s record DWH_FIRENZE_ANALISI',v_duplicate_pk),
   HINT='Rendere univoco CD_CODICE_COMPLETO in DIM_FIRENZE_ARTICOLI o completare la chiave di join.';
 END IF;
 IF v_selected<>(SELECT count(1) FROM hcbi_ras.tmp_fct_firenze_analisi_src) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE='Il lookup articolo ha alterato la cardinalita sorgente';
 END IF;


 SELECT count(1) INTO v_inserted
 FROM hcbi_ras.tmp_fct_firenze_analisi_src src
 LEFT JOIN hcbi_ras.fct_firenze_analisi f ON f.id_firenze_analisi=src.id_firenze_analisi
 WHERE f.id_firenze_analisi IS NULL;
 SELECT count(1) INTO v_updated
 FROM hcbi_ras.tmp_fct_firenze_analisi_src src
 JOIN hcbi_ras.fct_firenze_analisi f ON f.id_firenze_analisi=src.id_firenze_analisi
 WHERE ROW(
            f.id_firenze_articolo,
            f.nr_anno,
            f.ds_regione,
            f.ds_provincia,
            f.nr_riga_file,
            f.cd_analisi,
            f.ds_analisi,
            f.fl_cam,
            f.cd_dettaglio_cam,
            f.ds_voce_articolo,
            f.cd_collegato,
            f.cd_unita_misura,
            f.nr_quantita,
            f.nr_prezzo_unitario,
            f.nr_importo,
            f.tx_nome_file,
            f.dt_caricamento,
            f.tx_caricamento_by
        ) IS DISTINCT FROM ROW(
            src.id_firenze_articolo,
            src.nr_anno,
            src.ds_regione,
            src.ds_provincia,
            src.nr_riga_file,
            src.cd_analisi,
            src.ds_analisi,
            src.fl_cam,
            src.cd_dettaglio_cam,
            src.ds_voce_articolo,
            src.cd_collegato,
            src.cd_unita_misura,
            src.nr_quantita,
            src.nr_prezzo_unitario,
            src.nr_importo,
            src.tx_nome_file,
            src.dt_caricamento,
            src.tx_caricamento_by
        );

 INSERT INTO hcbi_ras.fct_firenze_analisi AS f
 (
        id_firenze_analisi,
        id_firenze_articolo,
        nr_anno,
        ds_regione,
        ds_provincia,
        nr_riga_file,
        cd_analisi,
        ds_analisi,
        fl_cam,
        cd_dettaglio_cam,
        ds_voce_articolo,
        cd_collegato,
        cd_unita_misura,
        nr_quantita,
        nr_prezzo_unitario,
        nr_importo,
        tx_nome_file,
        dt_caricamento,
        tx_caricamento_by,
        dt_creation,tx_creation_by,dt_update,tx_update_by
 )
 SELECT
        src.id_firenze_analisi,
        src.id_firenze_articolo,
        src.nr_anno,
        src.ds_regione,
        src.ds_provincia,
        src.nr_riga_file,
        src.cd_analisi,
        src.ds_analisi,
        src.fl_cam,
        src.cd_dettaglio_cam,
        src.ds_voce_articolo,
        src.cd_collegato,
        src.cd_unita_misura,
        src.nr_quantita,
        src.nr_prezzo_unitario,
        src.nr_importo,
        src.tx_nome_file,
        src.dt_caricamento,
        src.tx_caricamento_by,
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
 FROM hcbi_ras.tmp_fct_firenze_analisi_src src
 ON CONFLICT(id_firenze_analisi) DO UPDATE SET
        id_firenze_articolo=EXCLUDED.id_firenze_articolo,
        nr_anno=EXCLUDED.nr_anno,
        ds_regione=EXCLUDED.ds_regione,
        ds_provincia=EXCLUDED.ds_provincia,
        nr_riga_file=EXCLUDED.nr_riga_file,
        cd_analisi=EXCLUDED.cd_analisi,
        ds_analisi=EXCLUDED.ds_analisi,
        fl_cam=EXCLUDED.fl_cam,
        cd_dettaglio_cam=EXCLUDED.cd_dettaglio_cam,
        ds_voce_articolo=EXCLUDED.ds_voce_articolo,
        cd_collegato=EXCLUDED.cd_collegato,
        cd_unita_misura=EXCLUDED.cd_unita_misura,
        nr_quantita=EXCLUDED.nr_quantita,
        nr_prezzo_unitario=EXCLUDED.nr_prezzo_unitario,
        nr_importo=EXCLUDED.nr_importo,
        tx_nome_file=EXCLUDED.tx_nome_file,
        dt_caricamento=EXCLUDED.dt_caricamento,
        tx_caricamento_by=EXCLUDED.tx_caricamento_by,
        dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 WHERE ROW(
            f.id_firenze_articolo,
            f.nr_anno,
            f.ds_regione,
            f.ds_provincia,
            f.nr_riga_file,
            f.cd_analisi,
            f.ds_analisi,
            f.fl_cam,
            f.cd_dettaglio_cam,
            f.ds_voce_articolo,
            f.cd_collegato,
            f.cd_unita_misura,
            f.nr_quantita,
            f.nr_prezzo_unitario,
            f.nr_importo,
            f.tx_nome_file,
            f.dt_caricamento,
            f.tx_caricamento_by
        ) IS DISTINCT FROM ROW(
            EXCLUDED.id_firenze_articolo,
            EXCLUDED.nr_anno,
            EXCLUDED.ds_regione,
            EXCLUDED.ds_provincia,
            EXCLUDED.nr_riga_file,
            EXCLUDED.cd_analisi,
            EXCLUDED.ds_analisi,
            EXCLUDED.fl_cam,
            EXCLUDED.cd_dettaglio_cam,
            EXCLUDED.ds_voce_articolo,
            EXCLUDED.cd_collegato,
            EXCLUDED.cd_unita_misura,
            EXCLUDED.nr_quantita,
            EXCLUDED.nr_prezzo_unitario,
            EXCLUDED.nr_importo,
            EXCLUDED.tx_nome_file,
            EXCLUDED.dt_caricamento,
            EXCLUDED.tx_caricamento_by
        );

 v_unchanged:=v_selected-v_inserted-v_updated;
 IF v_unchanged<0 THEN RAISE EXCEPTION 'Riconciliazione FCT non valida selected=%, inserted=%, updated=%',v_selected,v_inserted,v_updated;END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
  'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_fct_firenze_analisi_src;p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;DROP TABLE IF EXISTS hcbi_ras.tmp_fct_firenze_analisi_src;
 IF v_id_log IS NOT NULL THEN
  CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
   left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
 END IF;
 RAISE WARNING 'Errore main FCT_FIRENZE_ANALISI: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;$procedure$
