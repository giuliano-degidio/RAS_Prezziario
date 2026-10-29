-- Verifiche read-only dopo l'applicazione di 01_create_dwh_schedule.sql.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'hcbi_utility'
  AND table_name IN ('dwh_schedule', 'dwh_schedule_run')
ORDER BY table_name;

SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'hcbi_utility'
  AND table_name IN ('dwh_schedule', 'dwh_schedule_run')
ORDER BY table_name, ordinal_position;

SELECT conrelid::regclass AS table_name, conname, contype
FROM pg_constraint
WHERE connamespace = 'hcbi_utility'::regnamespace
  AND conrelid IN (
      'hcbi_utility.dwh_schedule'::regclass,
      'hcbi_utility.dwh_schedule_run'::regclass
  )
ORDER BY conrelid::regclass::text, conname;

SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'hcbi_utility'
  AND tablename IN ('dwh_schedule', 'dwh_schedule_run')
ORDER BY tablename, indexname;

SELECT process_code, enabled, frequency_code, anchor_month,
       week_ordinal, weekday_iso, retry_days, last_success_period_start,
       last_attempt_status
FROM hcbi_utility.dwh_schedule
ORDER BY process_code;

SELECT run_id, process_code, trigger_source, requested_by, period_start, planned_date, started_at,
       finished_at, status, return_code, error_message
FROM hcbi_utility.dwh_schedule_run
ORDER BY started_at DESC
LIMIT 20;

SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'hcbi_utility'
  AND grantee = 'hcbi_ras'
  AND table_name IN ('dwh_schedule', 'dwh_schedule_run')
ORDER BY table_name, privilege_type;

SELECT current_setting('server_version') AS server_version,
       has_schema_privilege('hcbi_ras', 'hcbi_utility', 'USAGE') AS role_schema_usage,
       has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule', 'SELECT')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule', 'INSERT')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule', 'UPDATE')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule', 'DELETE')
         AS role_schedule_dml,
       has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule_run', 'SELECT')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule_run', 'INSERT')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule_run', 'UPDATE')
         AND has_table_privilege('hcbi_ras', 'hcbi_utility.dwh_schedule_run', 'DELETE')
         AS role_run_dml,
       has_sequence_privilege('hcbi_ras',
         pg_get_serial_sequence('hcbi_utility.dwh_schedule', 'schedule_id'), 'USAGE')
         AND has_sequence_privilege('hcbi_ras',
         pg_get_serial_sequence('hcbi_utility.dwh_schedule', 'schedule_id'), 'SELECT')
         AS role_schedule_sequence,
       has_function_privilege('hcbi_ras',
         'hcbi_utility.fn_dwh_schedule_enable_exclusive()', 'EXECUTE') AS role_trigger_function;
