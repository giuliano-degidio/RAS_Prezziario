BEGIN;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_schema = 'hcbi_ras'
          AND table_type = 'BASE TABLE'
          AND (
              table_name LIKE 'frontiera\_%' ESCAPE '\'
              OR table_name LIKE 'src\_tmp\_%' ESCAPE '\'
              OR table_name LIKE 'stg\_%' ESCAPE '\'
              OR table_name LIKE 'wrk\_%' ESCAPE '\'
              OR table_name LIKE 'dwh\_%' ESCAPE '\'
          )
          AND table_name NOT LIKE 'fct\_%' ESCAPE '\'
          AND table_name NOT LIKE 'dim\_%' ESCAPE '\'
          AND table_name NOT IN ('srv_controlli', 'zz_anagrafica_articolo_liv4')
        ORDER BY table_name
    LOOP
        EXECUTE format('TRUNCATE TABLE %I.%I', r.table_schema, r.table_name);
    END LOOP;
END $$;

COMMIT;

/* la query sotto produce solamente il testo SQL che da controllare e successivamente eseguire.
SELECT format(
           'TRUNCATE TABLE %I.%I;',
           table_schema,
           table_name
       ) AS sql_script
FROM information_schema.tables
WHERE table_schema = 'hcbi_ras'
  AND table_type = 'BASE TABLE'
  AND (
      table_name LIKE 'frontiera\_%' ESCAPE '\'
      OR table_name LIKE 'src\_tmp\_%' ESCAPE '\'
      OR table_name LIKE 'stg\_%' ESCAPE '\'
      OR table_name LIKE 'wrk\_%' ESCAPE '\'
      OR table_name LIKE 'dwh\_%' ESCAPE '\'
  )
  AND table_name NOT LIKE 'fct\_%' ESCAPE '\'
  AND table_name NOT LIKE 'dim\_%' ESCAPE '\'
  AND table_name NOT IN (
      'srv_controlli',
      'zz_anagrafica_articolo_liv4'
  )
ORDER BY table_name;


*/
