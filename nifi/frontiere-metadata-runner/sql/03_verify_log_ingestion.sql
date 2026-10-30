-- Run after applying both etl_execution_log_ingestion.sql and
-- etl_execution_log_event.sql.

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'hcbi_utility'
  AND table_name IN ('etl_execution_log_ingestion', 'etl_execution_log_event')
ORDER BY table_name;

SELECT status, count(*) AS ingestion_count,
       sum(events_read) AS events_read,
       sum(events_inserted) AS events_inserted,
       sum(events_duplicate) AS events_duplicate,
       sum(events_rejected) AS events_rejected,
       sum(bytes_read) AS bytes_read
FROM hcbi_utility.etl_execution_log_ingestion
GROUP BY status
ORDER BY status;

SELECT i.ingestion_id, i.source_code, i.scheduler_run_id, i.cycle_result,
       i.status, i.events_read, i.events_inserted, i.events_duplicate,
       i.events_rejected, i.bytes_read, i.error_code, i.error_message,
       i.started_at, i.finished_at
FROM hcbi_utility.etl_execution_log_ingestion AS i
ORDER BY i.started_at DESC
LIMIT 50;

SELECT source_code, correlation_status, parse_status, count(*) AS event_count
FROM hcbi_utility.etl_execution_log_event
GROUP BY source_code, correlation_status, parse_status
ORDER BY source_code, correlation_status, parse_status;
