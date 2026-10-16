SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='hcbi_utility' AND table_name='etl_dwh_refresh_run'
ORDER BY ordinal_position;

SELECT run_id, execution_uuid, chain_id, started_at, ended_at, status, error_message
FROM hcbi_utility.etl_dwh_refresh_run
ORDER BY run_id DESC
LIMIT 20;
