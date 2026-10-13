CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_delete_data_fct_dynamic_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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

    v_error_message text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DELETE_DATA_FCT_DYNAMIC, chain %, step %',
        p_id_chain,
        p_ds_step_name;

    /*
     * Apertura del log.
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
     * La procedura Oracle non esegue operazioni applicative
     * durante l'inizializzazione.
     */

    /*
     * Chiusura positiva del log.
     */
    CALL hcbi_utility.pkg_log_prc_update_log
    (
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

    p_result := 1;

EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        v_error_message :=
            'PKG_DELETE_DATA_FCT_DYNAMIC.PRC_INITIALIZE: '
            || SQLSTATE
            || ': '
            || SQLERRM;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log
                (
                    v_id_log,
                    'FAILED',
                    left(v_error_message, 4000),
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
            'Errore in pkg_delete_data_fct_dynamic_prc_initialize. SQLSTATE=%, errore=%',
            SQLSTATE,
            SQLERRM;
END;
$procedure$
