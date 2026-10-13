CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT; v_selected BIGINT := 0; v_inserted BIGINT := 0;
    v_updated BIGINT := 0; v_sqlstate TEXT; v_sqlerrm TEXT;
    v_sql_detail TEXT; v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_unita_misura;
    CREATE TABLE hcbi_ras.tmp_dwh_anag_unita_misura AS
    SELECT cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita
    FROM hcbi_ras.v_dwh_anag_unita_misura;

    CREATE UNIQUE INDEX tmp_dwh_anag_unita_misura_uq
        ON hcbi_ras.tmp_dwh_anag_unita_misura (cd_unita_misura) NULLS NOT DISTINCT;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_unita_misura;

    UPDATE hcbi_ras.dwh_anag_unita_misura AS d
    SET ds_unita_misura = src.ds_unita_misura,
        nr_decimali = src.nr_decimali,
        id_sorgente_unita_misura = src.id_sorgente_unita_misura,
        dt_last_update = src.dt_last_update,
        dt_fine_validita = src.dt_fine_validita,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_unita_misura AS src
    WHERE d.cd_unita_misura = src.cd_unita_misura
      AND (d.ds_unita_misura IS DISTINCT FROM src.ds_unita_misura
        OR d.nr_decimali IS DISTINCT FROM src.nr_decimali
        OR d.id_sorgente_unita_misura IS DISTINCT FROM src.id_sorgente_unita_misura
        OR d.dt_last_update IS DISTINCT FROM src.dt_last_update
        OR d.dt_fine_validita IS DISTINCT FROM src.dt_fine_validita);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_unita_misura (
        cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita,
        dt_creation, tx_creation_by, dt_update, tx_update_by)
    SELECT src.cd_unita_misura, src.ds_unita_misura, src.nr_decimali,
        src.id_sorgente_unita_misura, src.dt_last_update, src.dt_fine_validita,
        clock_timestamp(), p_ds_step_name, clock_timestamp(), p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_unita_misura AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_unita_misura DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, 0, 0, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);
    DROP TABLE hcbi_ras.tmp_dwh_anag_unita_misura;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_unita_misura;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %', SQLERRM; END;
    v_log_error := LEFT(CONCAT_WS(E'\n', 'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||COALESCE(v_sqlerrm,''), 'DETAIL='||COALESCE(v_sql_detail,''),
        'HINT='||COALESCE(v_sql_hint,''), 'CONTEXT='||COALESCE(v_sql_context,'')), 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_unita_misura_prc_main: %', v_sqlerrm;
END;
$procedure$
