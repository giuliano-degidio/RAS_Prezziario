CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_finalize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp,
        p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.fct_articoli_informatori;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log, 'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                clock_timestamp()::timestamp, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FINALIZE FCT_ARTICOLI_INFORMATORI: %', SQLERRM;
        END;
    END IF;
    RAISE;
END;
$procedure$
