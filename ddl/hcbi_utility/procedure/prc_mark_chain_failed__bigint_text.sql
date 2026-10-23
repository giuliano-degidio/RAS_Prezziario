CREATE OR REPLACE PROCEDURE hcbi_utility.prc_mark_chain_failed(
    IN p_id_log bigint,
    IN p_error_msg text
)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
DECLARE
    v_sql          text;
    v_exec_result  text;
    v_sqlstate     text;
    v_sqlerrm      text;
BEGIN
    IF p_id_log IS NULL THEN
        RAISE EXCEPTION
            'PRC_MARK_CHAIN_FAILED: p_id_log obbligatorio';
    END IF;

    /*
     * Questo helper registra il fallimento di uno step senza chiudere
     * anticipatamente il log della catena. prc_execute_chain continua a
     * decidere se interrompere o proseguire con gli step successivi e
     * richiama prc_end_chain alla conclusione per valorizzare dt_end.
     *
     * L'UPDATE passa da LOG_DBLINK, cosi' lo stato FAILED e il messaggio
     * restano registrati anche se la transazione principale fa rollback.
     */
    PERFORM hcbi_utility.ensure_dblink_logging();

    v_sql := format(
        $sql$
        UPDATE hcbi_utility.log_chain
           SET ds_status = 'FAILED',
               tx_error_message = left(%L::text, 4000)
         WHERE id_log = %L::bigint
        $sql$,
        p_error_msg,
        p_id_log
    );

    v_exec_result := hcbi_utility.dblink_exec('LOG_DBLINK', v_sql);

    IF v_exec_result = 'UPDATE 0' THEN
        RAISE EXCEPTION
            'PRC_MARK_CHAIN_FAILED: nessuna riga LOG_CHAIN trovata per ID_LOG=%',
            p_id_log;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        v_sqlstate := SQLSTATE;
        v_sqlerrm := SQLERRM;

        RAISE EXCEPTION
            'PRC_MARK_CHAIN_FAILED: errore aggiornamento LOG_CHAIN ID_LOG=%. SQLSTATE: %, errore: %',
            p_id_log,
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$

ALTER PROCEDURE hcbi_utility.prc_mark_chain_failed(bigint, text) OWNER TO hcbi_utility;
