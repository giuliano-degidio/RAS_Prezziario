CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_ateco_2002 AS
    SELECT
        s.cd_ateco_2002,
        s.ds_ateco_2002
    FROM hcbi_ras.v_dwh_anag_ateco_2002 AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_ateco_2002_uq
    ON hcbi_ras.tmp_dwh_anag_ateco_2002 (cd_ateco_2002)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_ateco_2002;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_ateco_2002;

    UPDATE hcbi_ras.dwh_anag_ateco_2002 AS dwh
       SET ds_ateco_2002 = src.ds_ateco_2002,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_ateco_2002 AS src
     WHERE dwh.cd_ateco_2002 = src.cd_ateco_2002
       AND dwh.ds_ateco_2002 IS DISTINCT FROM src.ds_ateco_2002;
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_ateco_2002 (
        cd_ateco_2002,
        ds_ateco_2002,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.cd_ateco_2002,
        src.ds_ateco_2002,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_ateco_2002 AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_ateco_2002
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL,
            v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        BEGIN
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_ateco_2002_prc_main: %',
            v_sqlerrm;
END;
$procedure$
