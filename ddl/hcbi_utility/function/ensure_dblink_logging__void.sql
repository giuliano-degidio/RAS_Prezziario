CREATE OR REPLACE FUNCTION hcbi_utility.ensure_dblink_logging()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $function$
DECLARE
    v_connections text[];
    v_health       integer;
    v_sqlstate     text;
    v_sqlerrm      text;
    v_sql_detail   text;
    v_sql_hint     text;
    v_sql_context  text;
    v_error_detail text;
BEGIN
    v_connections := hcbi_utility.dblink_get_connections();

    IF v_connections IS NULL
       OR NOT ('LOG_DBLINK' = ANY(v_connections))
    THEN
        PERFORM hcbi_utility.dblink_connect(
            'LOG_DBLINK',
            hcbi_utility.get_conn_string()
        );
    ELSE
        -- A registered connection may no longer be usable.
        -- Verify it with a minimal query and reconnect once if necessary.
        BEGIN
            SELECT t.health
              INTO STRICT v_health
              FROM hcbi_utility.dblink(
                       'LOG_DBLINK',
                       'SELECT 1::integer'
                   ) AS t(health integer);

            IF v_health IS DISTINCT FROM 1 THEN
                RAISE EXCEPTION
                    USING
                        ERRCODE = 'P0001',
                        MESSAGE = 'Verifica LOG_DBLINK non valida',
                        DETAIL = format(
                            'La query di health check ha restituito il valore %s.',
                            coalesce(v_health::text, 'NULL')
                        );
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                -- Best effort: remove the unusable named connection.
                BEGIN
                    PERFORM hcbi_utility.dblink_disconnect('LOG_DBLINK');
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;

                PERFORM hcbi_utility.dblink_connect(
                    'LOG_DBLINK',
                    hcbi_utility.get_conn_string()
                );

                -- Verify the newly opened connection before returning success.
                SELECT t.health
                  INTO STRICT v_health
                  FROM hcbi_utility.dblink(
                           'LOG_DBLINK',
                           'SELECT 1::integer'
                       ) AS t(health integer);

                IF v_health IS DISTINCT FROM 1 THEN
                    RAISE EXCEPTION
                        USING
                            ERRCODE = 'P0001',
                            MESSAGE = 'Riconnessione LOG_DBLINK non valida',
                            DETAIL = format(
                                'La query di health check ha restituito il valore %s.',
                                coalesce(v_health::text, 'NULL')
                            );
                END IF;
        END;
    END IF;

EXCEPTION
    WHEN duplicate_object THEN
        -- Ignore the duplicate only if the expected connection now exists.
        v_connections := hcbi_utility.dblink_get_connections();

        IF v_connections IS NULL
           OR NOT ('LOG_DBLINK' = ANY(v_connections))
        THEN
            RAISE;
        END IF;

    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        v_error_detail := left(
            concat_ws(
                E'\n',
                CASE
                    WHEN nullif(v_sql_detail, '') IS NOT NULL
                        THEN 'DETAIL=' || left(v_sql_detail, 1000)
                END,
                CASE
                    WHEN nullif(v_sql_hint, '') IS NOT NULL
                        THEN 'HINT=' || left(v_sql_hint, 500)
                END,
                CASE
                    WHEN nullif(v_sql_context, '') IS NOT NULL
                        THEN 'CONTEXT=' || left(v_sql_context, 1200)
                END
            ),
            3000
        );

        RAISE EXCEPTION
            USING
                ERRCODE = coalesce(nullif(v_sqlstate, ''), 'P0001'),
                MESSAGE = left(
                    'Errore inizializzazione LOG_DBLINK: '
                    || coalesce(v_sqlerrm, 'errore PostgreSQL non specificato'),
                    2000
                ),
                DETAIL = coalesce(
                    nullif(v_error_detail, ''),
                    'Nessun dettaglio aggiuntivo disponibile.'
                );
END;
$function$
