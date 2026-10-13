CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log      bigint;
    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;

    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
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

    TRUNCATE
        hcbi_ras.stg_anag_informatori,
        hcbi_ras.stg_anag_informatori_rej;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.v_src_tmp_anag_informatori;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

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

        v_log_error := LEFT(
            CONCAT_WS(
                E'\n',
                'SQLSTATE=' || COALESCE(v_sqlstate, ''),
                'MESSAGE=' || COALESCE(v_sqlerrm, ''),
                'DETAIL=' || COALESCE(v_sql_detail, ''),
                'HINT=' || COALESCE(v_sql_hint, ''),
                'CONTEXT=' || COALESCE(v_sql_context, '')
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore logging: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_informatori_prc_initialize: %',
            v_sqlerrm;
END;
$procedure$
