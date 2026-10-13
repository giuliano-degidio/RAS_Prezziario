CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_firenze_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_stg bigint := 0;
    v_structural bigint := 0;
    v_candidate bigint := 0;
    v_load bigint := 0;
    v_rejected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_unchanged bigint := 0;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_analisi_classificata;
    CREATE TABLE hcbi_ras.tmp_dwh_firenze_analisi_classificata AS
    SELECT
        nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
        codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
        unita_misura,quantita,prezzo_unitario,importo,tx_nome_file,
        dt_caricamento,tx_caricamento_by,cd_analisi_propagato,
        ds_analisi_propagata,fl_cam_propagato,cd_dettaglio_normalizzato,
        cd_unita_misura_normalizzata,nr_quantita_convertita,
        nr_prezzo_unitario_convertito,nr_importo_convertito,duplicate_count,
        cd_tipo_riga,cd_esito,cd_motivo_scarto,tx_motivo_scarto
    FROM hcbi_ras.v_dwh_firenze_analisi_classificata;

    SELECT count(*) INTO v_stg FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata;
    SELECT count(*) INTO v_structural FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata WHERE cd_esito='STRUCTURAL';
    SELECT count(*) INTO v_candidate FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata WHERE cd_tipo_riga='COMPONENT';
    SELECT count(*) INTO v_load FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata WHERE cd_esito='LOAD';
    SELECT count(*) INTO v_rejected FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata WHERE cd_esito='REJECT';

    IF v_stg <> v_structural + v_candidate THEN
        RAISE EXCEPTION 'Riconciliazione DWH righe non valida stg=%, structural=%, candidate=%',v_stg,v_structural,v_candidate;
    END IF;
    IF v_candidate <> v_load + v_rejected THEN
        RAISE EXCEPTION 'Riconciliazione DWH candidati non valida candidate=%, load=%, reject=%',v_candidate,v_load,v_rejected;
    END IF;

    DELETE FROM hcbi_ras.dwh_firenze_analisi_rej
    WHERE id_chain_log = p_id_chain_log AND id_step = p_id_step;

    INSERT INTO hcbi_ras.dwh_firenze_analisi_rej
    (nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
     codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
     unita_misura,quantita,prezzo_unitario,importo,cd_analisi_propagato,
     ds_analisi_propagata,fl_cam_propagato,cd_dettaglio_normalizzato,
     cd_unita_misura_normalizzata,nr_quantita_convertita,
     nr_prezzo_unitario_convertito,nr_importo_convertito,cd_tipo_riga,
     cd_esito,cd_motivo_scarto,tx_motivo_scarto,tx_nome_file,
     dt_caricamento,tx_caricamento_by,id_chain_log,id_chain,id_step,ds_step_name)
    SELECT
        nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
        codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
        unita_misura,quantita,prezzo_unitario,importo,cd_analisi_propagato,
        ds_analisi_propagata,fl_cam_propagato,cd_dettaglio_normalizzato,
        cd_unita_misura_normalizzata,nr_quantita_convertita,
        nr_prezzo_unitario_convertito,nr_importo_convertito,cd_tipo_riga,
        cd_esito,cd_motivo_scarto,tx_motivo_scarto,tx_nome_file,
        dt_caricamento,tx_caricamento_by,p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name
    FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata
    WHERE cd_esito='REJECT';

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_analisi;
    CREATE TABLE hcbi_ras.tmp_dwh_firenze_analisi AS
    SELECT
        nr_anno,
        btrim(ds_regione)::varchar(50) AS ds_regione,
        btrim(ds_provincia)::varchar(50) AS ds_provincia,
        nr_riga_file,
        cd_analisi_propagato::varchar(100) AS cd_analisi,
        ds_analisi_propagata AS ds_analisi,
        fl_cam_propagato::varchar(20) AS fl_cam,
        cd_dettaglio_normalizzato::varchar(200) AS cd_dettaglio,
        nullif(btrim(cam_codice_dettaglio),'')::varchar(200) AS cd_dettaglio_cam,
        nullif(btrim(voce_articolo),'') AS ds_voce_articolo,
        nullif(btrim(codice_collegato),'')::varchar(200) AS cd_collegato,
        cd_unita_misura_normalizzata::varchar(50) AS cd_unita_misura,
        nr_quantita_convertita AS nr_quantita,
        nr_prezzo_unitario_convertito AS nr_prezzo_unitario,
        nr_importo_convertito AS nr_importo,
        btrim(tx_nome_file)::varchar(255) AS tx_nome_file,
        dt_caricamento,
        nullif(btrim(tx_caricamento_by),'')::varchar(100) AS tx_caricamento_by
    FROM hcbi_ras.tmp_dwh_firenze_analisi_classificata
    WHERE cd_esito='LOAD';

    CREATE UNIQUE INDEX tmp_dwh_firenze_analisi_uq
    ON hcbi_ras.tmp_dwh_firenze_analisi(nr_anno,cd_analisi,cd_dettaglio,nr_riga_file)
    NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dwh_firenze_analisi;

    UPDATE hcbi_ras.dwh_firenze_analisi d SET
        ds_regione=s.ds_regione, ds_provincia=s.ds_provincia,
        ds_analisi=s.ds_analisi, fl_cam=s.fl_cam,
        cd_dettaglio_cam=s.cd_dettaglio_cam,
        ds_voce_articolo=s.ds_voce_articolo, cd_collegato=s.cd_collegato,
        cd_unita_misura=s.cd_unita_misura, nr_quantita=s.nr_quantita,
        nr_prezzo_unitario=s.nr_prezzo_unitario, nr_importo=s.nr_importo,
        tx_nome_file=s.tx_nome_file, dt_caricamento=s.dt_caricamento,
        tx_caricamento_by=s.tx_caricamento_by,
        dt_update=clock_timestamp(), tx_update_by=p_ds_step_name
    FROM hcbi_ras.tmp_dwh_firenze_analisi s
    WHERE d.nr_anno=s.nr_anno
      AND d.cd_analisi=s.cd_analisi
      AND d.cd_dettaglio=s.cd_dettaglio
      AND d.nr_riga_file=s.nr_riga_file
      AND ROW(d.ds_regione,d.ds_provincia,d.ds_analisi,d.fl_cam,
              d.cd_dettaglio_cam,d.ds_voce_articolo,d.cd_collegato,
              d.cd_unita_misura,d.nr_quantita,d.nr_prezzo_unitario,
              d.nr_importo,d.tx_nome_file,d.dt_caricamento,d.tx_caricamento_by)
          IS DISTINCT FROM
          ROW(s.ds_regione,s.ds_provincia,s.ds_analisi,s.fl_cam,
              s.cd_dettaglio_cam,s.ds_voce_articolo,s.cd_collegato,
              s.cd_unita_misura,s.nr_quantita,s.nr_prezzo_unitario,
              s.nr_importo,s.tx_nome_file,s.dt_caricamento,s.tx_caricamento_by);
    GET DIAGNOSTICS v_updated=ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_firenze_analisi
    (nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_analisi,ds_analisi,
     fl_cam,cd_dettaglio,cd_dettaglio_cam,ds_voce_articolo,cd_collegato,
     cd_unita_misura,nr_quantita,nr_prezzo_unitario,nr_importo,
     tx_nome_file,dt_caricamento,tx_caricamento_by,dt_creation,
     tx_creation_by,dt_update,tx_update_by)
    SELECT
        nr_anno,ds_regione,ds_provincia,nr_riga_file,cd_analisi,ds_analisi,
        fl_cam,cd_dettaglio,cd_dettaglio_cam,ds_voce_articolo,cd_collegato,
        cd_unita_misura,nr_quantita,nr_prezzo_unitario,nr_importo,
        tx_nome_file,dt_caricamento,tx_caricamento_by,clock_timestamp(),
        p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dwh_firenze_analisi
    ON CONFLICT (nr_anno,cd_analisi,cd_dettaglio,nr_riga_file) DO NOTHING;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    v_unchanged := v_load - v_inserted - v_updated;
    IF v_unchanged < 0 OR v_load <> v_inserted + v_updated + v_unchanged THEN
        RAISE EXCEPTION 'Riconciliazione DWH load non valida load=%, inserted=%, updated=%, unchanged=%',
            v_load,v_inserted,v_updated,v_unchanged;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_candidate,v_inserted,v_updated,0,v_rejected,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_dwh_firenze_analisi;
    DROP TABLE hcbi_ras.tmp_dwh_firenze_analisi_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_analisi;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_firenze_analisi_classificata;
    IF v_id_log IS NOT NULL THEN
        CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
            left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
    END IF;
    RAISE WARNING 'Errore DWH main: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$procedure$
