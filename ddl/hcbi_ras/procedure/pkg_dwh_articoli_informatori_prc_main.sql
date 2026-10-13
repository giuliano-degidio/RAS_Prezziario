CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_errors bigint := 0;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.v_dwh_articoli_informatori;

    UPDATE hcbi_ras.dwh_articoli_informatori d
       SET id_sorgente_articoli_informatori = s.id_sorgente_articoli_informatori,
           fl_escluso = s.fl_escluso,
           id_sorgente_utente = s.id_sorgente_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_articoli_informatori s
     WHERE d.id_sorgente_informatore = s.id_sorgente_informatore
       AND d.cd_articolo = s.cd_articolo
       AND d.ds_anno = s.ds_anno
       AND d.id_sorgente_provincia = s.id_sorgente_provincia
       AND d.cd_versione = s.cd_versione
       AND ROW(d.id_sorgente_articoli_informatori,d.fl_escluso,d.id_sorgente_utente)
           IS DISTINCT FROM
           ROW(s.id_sorgente_articoli_informatori,s.fl_escluso,s.id_sorgente_utente);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_articoli_informatori (
        id_sorgente_articoli_informatori,id_sorgente_informatore,cd_articolo,
        ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,id_sorgente_utente,
        tx_creation_by,tx_update_by)
    SELECT s.id_sorgente_articoli_informatori,s.id_sorgente_informatore,s.cd_articolo,
           s.ds_anno,s.id_sorgente_provincia,s.fl_escluso,s.cd_versione,s.id_sorgente_utente,
           p_ds_step_name,p_ds_step_name
    FROM hcbi_ras.v_dwh_articoli_informatori s
    ON CONFLICT (id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,cd_versione)
    DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore main DWH ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$procedure$
