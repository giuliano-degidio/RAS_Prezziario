CREATE OR REPLACE FUNCTION hcbi_utility.get_conn_string(p_conn_name character varying DEFAULT 'LOOPBACK_DBLINK'::character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_conn_string TEXT;
BEGIN

    SELECT conn_string
    INTO v_conn_string
    FROM hcbi_utility.cfg_connections
    WHERE UPPER(conn_name) = UPPER(p_conn_name);

    IF v_conn_string IS NULL THEN
        RAISE EXCEPTION
            'Connessione "%" non trovata nella tabella hcbi_utility.cfg_connections',
            p_conn_name;
    END IF;

    RETURN v_conn_string;

END;
$function$
