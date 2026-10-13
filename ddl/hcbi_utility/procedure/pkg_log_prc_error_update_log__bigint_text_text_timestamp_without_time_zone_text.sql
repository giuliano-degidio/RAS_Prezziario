CREATE OR REPLACE PROCEDURE hcbi_utility.pkg_log_prc_error_update_log(IN p_id_log bigint, IN p_ds_status text, IN p_ds_error text, IN p_dt_update timestamp without time zone DEFAULT clock_timestamp(), IN p_ds_transaction text DEFAULT CURRENT_USER)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
DECLARE
    v_sql          text;
    v_exec_result  text;
    v_error_message text;

    v_sqlstate text;
    v_sqlerrm  text;
BEGIN
    IF p_id_log IS NULL THEN
        RAISE EXCEPTION
            'PKG_LOG_PRC_ERROR_UPDATE_LOG: p_id_log obbligatorio';
    END IF;

    /*
     * Il messaggio viene già costruito dalla procedura chiamante.
     * Non vengono richiamate funzioni aggiuntive di formattazione
     * dello stack, evitando che un loro errore mascheri l'errore originale.
     */
    v_error_message :=
        COALESCE(
            p_ds_error,
            'Errore PostgreSQL non specificato'
        );

    PERFORM hcbi_utility.ensure_dblink_logging();

    v_sql := format(
        $sql$
        UPDATE hcbi_utility.log_step
           SET dt_end           = clock_timestamp(),
               tx_error_message = %L::text,
               ds_status        = %L::text,
               dt_update        = %L::timestamp,
               tx_update_by     = %L::text
         WHERE id_log = %L::bigint
        $sql$,
        v_error_message,
        p_ds_status,
        p_dt_update,
        p_ds_transaction,
        p_id_log
    );

    v_exec_result :=
        hcbi_utility.dblink_exec(
            'LOG_DBLINK',
            v_sql
        );

    IF v_exec_result = 'UPDATE 0' THEN
        RAISE EXCEPTION
            'PKG_LOG_PRC_ERROR_UPDATE_LOG: nessuna riga LOG_STEP trovata per ID_LOG=%',
            p_id_log;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        /*
         * SQLSTATE e SQLERRM vengono utilizzati soltanto
         * all'interno del blocco EXCEPTION.
         */
        v_sqlstate := SQLSTATE;
        v_sqlerrm  := SQLERRM;

        RAISE EXCEPTION
            'PKG_LOG_PRC_ERROR_UPDATE_LOG: errore aggiornamento LOG_STEP ID_LOG=%. SQLSTATE: %, errore: %',
            p_id_log,
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
