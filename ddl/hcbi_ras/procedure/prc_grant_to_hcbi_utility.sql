CREATE OR REPLACE PROCEDURE hcbi_ras.prc_grant_to_hcbi_utility()
 LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_sql text;
BEGIN

    ----------------------------------------------------------------------
    -- TABELLE E VISTE
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE %I.%I TO hcbi_utility;',
            schemaname,
            tablename
        )
        FROM pg_tables
        WHERE schemaname = 'hcbi_ras'
    LOOP
        EXECUTE v_sql;
    END LOOP;

    ----------------------------------------------------------------------
    -- VISTE
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT SELECT ON TABLE %I.%I TO hcbi_utility;',
            schemaname,
            viewname
        )
        FROM pg_views
        WHERE schemaname = 'hcbi_ras'
    LOOP
        EXECUTE v_sql;
    END LOOP;

    ----------------------------------------------------------------------
    -- MATERIALIZED VIEW
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT SELECT ON TABLE %I.%I TO hcbi_utility;',
            schemaname,
            matviewname
        )
        FROM pg_matviews
        WHERE schemaname = 'hcbi_ras'
    LOOP
        EXECUTE v_sql;
    END LOOP;

    ----------------------------------------------------------------------
    -- SEQUENCE
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT USAGE, SELECT, UPDATE ON SEQUENCE %I.%I TO hcbi_utility;',
            sequence_schema,
            sequence_name
        )
        FROM information_schema.sequences
        WHERE sequence_schema = 'hcbi_ras'
    LOOP
        EXECUTE v_sql;
    END LOOP;

    ----------------------------------------------------------------------
    -- FUNZIONI
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO hcbi_utility;',
            n.nspname,
            p.proname,
            pg_get_function_identity_arguments(p.oid)
        )
        FROM pg_proc p
        JOIN pg_namespace n
            ON n.oid = p.pronamespace
        WHERE n.nspname = 'hcbi_ras'
          AND p.prokind = 'f'
    LOOP
        EXECUTE v_sql;
    END LOOP;

    ----------------------------------------------------------------------
    -- PROCEDURE
    ----------------------------------------------------------------------
    FOR v_sql IN
        SELECT format(
            'GRANT EXECUTE ON PROCEDURE %I.%I(%s) TO hcbi_utility;',
            n.nspname,
            p.proname,
            pg_get_function_identity_arguments(p.oid)
        )
        FROM pg_proc p
        JOIN pg_namespace n
            ON n.oid = p.pronamespace
        WHERE n.nspname = 'hcbi_ras'
          AND p.prokind = 'p'
    LOOP
        EXECUTE v_sql;
    END LOOP;

END;
$procedure$
