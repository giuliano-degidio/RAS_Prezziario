-- PostgreSQL 17. Apply before etl_execution_log_event.sql.
-- Run as a DBA able to set ownership to hcbi_utility and grant to hcbi_ras.
BEGIN;

CREATE TABLE hcbi_utility.etl_execution_log_ingestion (
    ingestion_id            bigint GENERATED ALWAYS AS IDENTITY,
    source_code             varchar(50) NOT NULL,
    source_path             text NOT NULL,
    source_device           bigint,
    source_inode            bigint,
    offset_start            bigint NOT NULL,
    offset_end              bigint NOT NULL,
    manifest_execution_uuid uuid,
    scheduler_run_id        uuid,
    cycle_result            varchar(20),
    cycle_exit_code         integer,
    started_at              timestamptz NOT NULL DEFAULT clock_timestamp(),
    finished_at             timestamptz,
    status                  varchar(30) NOT NULL DEFAULT 'RUNNING',
    events_read             bigint NOT NULL DEFAULT 0,
    events_inserted         bigint NOT NULL DEFAULT 0,
    events_duplicate        bigint NOT NULL DEFAULT 0,
    events_rejected         bigint NOT NULL DEFAULT 0,
    bytes_read              bigint NOT NULL DEFAULT 0,
    error_code              varchar(50),
    error_message           varchar(4000),
    retry_of_ingestion_id   bigint,
    CONSTRAINT pk_etl_execution_log_ingestion
        PRIMARY KEY (ingestion_id),
    CONSTRAINT fk_etl_execution_log_ingestion_retry
        FOREIGN KEY (retry_of_ingestion_id)
        REFERENCES hcbi_utility.etl_execution_log_ingestion (ingestion_id),
    CONSTRAINT ck_etl_execution_log_ingestion_offsets
        CHECK (offset_start >= 0 AND offset_end >= offset_start),
    CONSTRAINT ck_etl_execution_log_ingestion_counts
        CHECK (events_read = events_inserted + events_duplicate + events_rejected),
    CONSTRAINT ck_etl_execution_log_ingestion_bytes
        CHECK (events_read >= 0 AND events_inserted >= 0 AND
               events_duplicate >= 0 AND events_rejected >= 0 AND bytes_read >= 0),
    CONSTRAINT ck_etl_execution_log_ingestion_result
        CHECK (cycle_result IS NULL OR cycle_result IN ('SUCCESS', 'FAILED', 'SKIPPED')),
    CONSTRAINT ck_etl_execution_log_ingestion_status
        CHECK (status IN ('RUNNING', 'SUCCEEDED', 'SUCCEEDED_WITH_REJECTS',
                          'FAILED', 'ROTATED', 'SKIPPED')),
    CONSTRAINT ck_etl_execution_log_ingestion_lifecycle
        CHECK ((status = 'RUNNING' AND finished_at IS NULL) OR
               (status <> 'RUNNING' AND finished_at IS NOT NULL)),
    CONSTRAINT ck_etl_execution_log_ingestion_dates
        CHECK (finished_at IS NULL OR finished_at >= started_at)
);

ALTER TABLE hcbi_utility.etl_execution_log_ingestion
    OWNER TO hcbi_utility;
COMMENT ON TABLE hcbi_utility.etl_execution_log_ingestion IS
    'Audit dei tentativi di acquisizione dei segmenti dei log FMR/DWH.';

CREATE INDEX ix_etl_execution_log_ingestion_status_started
    ON hcbi_utility.etl_execution_log_ingestion (status, started_at DESC);
CREATE INDEX ix_etl_execution_log_ingestion_source_started
    ON hcbi_utility.etl_execution_log_ingestion (source_code, started_at DESC);

GRANT USAGE ON SCHEMA hcbi_utility TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE
    ON hcbi_utility.etl_execution_log_ingestion TO hcbi_ras;
GRANT USAGE, SELECT
    ON SEQUENCE hcbi_utility.etl_execution_log_ingestion_ingestion_id_seq
    TO hcbi_ras;

COMMIT;
