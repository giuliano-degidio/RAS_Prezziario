CREATE OR REPLACE PROCEDURE hcbi_utility.pkg_log_prc_update_log(IN p_id_log bigint, IN p_nr_selected bigint DEFAULT NULL::bigint, IN p_nr_inserted bigint DEFAULT NULL::bigint, IN p_nr_updated bigint DEFAULT NULL::bigint, IN p_nr_deleted bigint DEFAULT NULL::bigint, IN p_nr_rec_errors bigint DEFAULT NULL::bigint, IN p_ds_status text DEFAULT NULL::text, IN p_dt_update timestamp without time zone DEFAULT clock_timestamp(), IN p_ds_transaction text DEFAULT CURRENT_USER)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
DECLARE
    v_sql           text;
    v_exec_result   text;
BEGIN
    IF p_id_log IS NULL THEN
        RAISE EXCEPTION
            'PKG_LOG_PRC_UPDATE_LOG: p_id_log obbligatorio';
    END IF;

    PERFORM hcbi_utility.ensure_dblink_logging();

    v_sql := format(
        $sql$
        UPDATE hcbi_utility.log_step
           SET dt_end          = clock_timestamp(),
               nr_rec_selected = %L::bigint,
               nr_rec_inserted = %L::bigint,
               nr_rec_updated  = %L::bigint,
               nr_rec_deleted  = %L::bigint,
               nr_rec_errors   = %L::bigint,
               ds_status       = %L::text,
               dt_update       = %L::timestamp,
               tx_update_by    = %L::text
         WHERE id_log = %L::bigint
        $sql$,
        p_nr_selected,
        p_nr_inserted,
        p_nr_updated,
        p_nr_deleted,
        p_nr_rec_errors,
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
            'PKG_LOG_PRC_UPDATE_LOG: nessuna riga LOG_STEP '
            'trovata per ID_LOG=%',
            p_id_log;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION
            'PKG_LOG_PRC_UPDATE_LOG: errore aggiornamento '
            'LOG_STEP ID_LOG=%. SQLSTATE: %, errore: %',
            p_id_log,
            SQLSTATE,
            SQLERRM;
END;
$procedure$
