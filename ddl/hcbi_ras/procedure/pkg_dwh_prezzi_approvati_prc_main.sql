CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    SELECT count(*)
      INTO v_selected
      FROM hcbi_ras.v_dwh_prezzi_approvati;

    UPDATE hcbi_ras.dwh_prezzi_approvati d
       SET nr_prezzo = s.nr_prezzo,
           dt_approvazione = s.dt_approvazione,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_prezzi_approvati s
     WHERE d.cd_articolo = s.cd_articolo
       AND d.ds_anno = s.ds_anno
       AND d.id_sorgente_provincia = s.id_sorgente_provincia
       AND d.cd_versione = s.cd_versione
       AND ROW(d.nr_prezzo, d.dt_approvazione)
           IS DISTINCT FROM
           ROW(s.nr_prezzo, s.dt_approvazione);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_prezzi_approvati (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione,
        tx_creation_by,
        tx_update_by)
    SELECT s.cd_articolo,
           s.ds_anno,
           s.nr_prezzo,
           s.id_sorgente_provincia,
           s.dt_approvazione,
           s.cd_versione,
           p_ds_step_name,
           p_ds_step_name
      FROM hcbi_ras.v_dwh_prezzi_approvati s
    ON CONFLICT (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione)
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore main DWH PREZZI_APPROVATI: %', SQLERRM;
END;
$procedure$
