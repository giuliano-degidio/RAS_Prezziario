CREATE OR REPLACE PROCEDURE hcbi_utility.prc_end_chain(IN p_id_log bigint, IN p_ds_status text, IN p_error_msg text DEFAULT NULL::text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
DECLARE
    v_sql          text;
    v_exec_result  text;
BEGIN
    IF p_id_log IS NULL THEN
        RAISE EXCEPTION
            'PRC_END_CHAIN: p_id_log obbligatorio';
    END IF;

    PERFORM hcbi_utility.ensure_dblink_logging();

    v_sql := format(
        $sql$
        UPDATE hcbi_utility.log_chain
           SET dt_end           = clock_timestamp(),
               ds_status        = %L::text,
               tx_error_message = %L::text
         WHERE id_log = %L::bigint
        $sql$,
        p_ds_status,
        p_error_msg,
        p_id_log
    );

    v_exec_result :=
        hcbi_utility.dblink_exec(
            'LOG_DBLINK',
            v_sql
        );

    IF v_exec_result = 'UPDATE 0' THEN
        RAISE EXCEPTION
            'PRC_END_CHAIN: nessuna riga LOG_CHAIN trovata '
            'per ID_LOG=%',
            p_id_log;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION
            'PRC_END_CHAIN: errore chiusura LOG_CHAIN '
            'ID_LOG=%. SQLSTATE: %, errore: %',
            p_id_log,
            SQLSTATE,
            SQLERRM;
END;
$procedure$
