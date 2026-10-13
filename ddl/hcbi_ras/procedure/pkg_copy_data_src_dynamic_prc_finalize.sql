CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_copy_data_src_dynamic_prc_finalize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_COPY_DATA_SRC_DYNAMIC per lo step %',
        p_ds_step_name;

    /*
     * Apertura del log dello step.
     */
    SELECT hcbi_utility.pkg_log_fnc_insert_log
    (
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    /*
     * Chiusura positiva del log.
     */
    CALL hcbi_utility.pkg_log_prc_update_log
    (
        v_id_log,
        0,
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
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log
                (
                    v_id_log,
                    'FAILED',
                    SQLSTATE || ': ' || SQLERRM,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante la registrazione del log di errore: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_copy_data_src_dynamic_prc_finalize. SQLSTATE=%, errore=%',
            SQLSTATE,
            SQLERRM;
END;
$procedure$
