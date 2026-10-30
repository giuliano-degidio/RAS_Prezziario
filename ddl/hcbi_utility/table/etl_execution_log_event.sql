-- PostgreSQL 17. Requires etl_execution_log_ingestion.sql.
-- Run as a DBA able to set ownership to hcbi_utility and grant to hcbi_ras.
BEGIN;

CREATE TABLE hcbi_utility.etl_execution_log_event (
    event_id                   bigint GENERATED ALWAYS AS IDENTITY,
    ingestion_id               bigint NOT NULL,
    source_code                varchar(50) NOT NULL,
    source_path                text NOT NULL,
    source_device              bigint NOT NULL,
    source_inode               bigint NOT NULL,
    byte_offset_start          bigint NOT NULL,
    byte_offset_end            bigint NOT NULL,
    source_line_start          bigint,
    source_line_end            bigint,
    event_timestamp            timestamptz,
    log_level                  varchar(20),
    event_execution_uuid       uuid,
    manifest_execution_uuid    uuid,
    event_scheduler_run_id     uuid,
    manifest_scheduler_run_id  uuid,
    chain_id                   integer,
    process_name               varchar(255),
    cycle_exit_code            integer,
    correlation_status         varchar(30) NOT NULL,
    parse_status               varchar(30) NOT NULL,
    is_redacted                boolean NOT NULL DEFAULT false,
    message_text               text NOT NULL,
    event_hash                 char(64) NOT NULL,
    ingested_at                timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_etl_execution_log_event PRIMARY KEY (event_id),
    CONSTRAINT fk_etl_execution_log_event_ingestion
        FOREIGN KEY (ingestion_id)
        REFERENCES hcbi_utility.etl_execution_log_ingestion (ingestion_id),
    CONSTRAINT ck_etl_execution_log_event_offsets
        CHECK (byte_offset_start >= 0 AND byte_offset_end > byte_offset_start),
    CONSTRAINT ck_etl_execution_log_event_lines
        CHECK (source_line_start IS NULL OR source_line_end IS NULL OR
               source_line_end >= source_line_start),
    CONSTRAINT ck_etl_execution_log_event_correlation
        CHECK (correlation_status IN ('CORRELATED', 'UNCORRELATED',
                                      'AMBIGUOUS', 'NOT_APPLICABLE')),
    CONSTRAINT ck_etl_execution_log_event_parse
        CHECK (parse_status IN ('PARSED', 'UNPARSED', 'ENCODING_REPLACED')),
    CONSTRAINT ck_etl_execution_log_event_hash
        CHECK (event_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT uq_etl_execution_log_event_identity
        UNIQUE (source_code, source_device, source_inode,
                byte_offset_start, byte_offset_end, event_hash)
);

ALTER TABLE hcbi_utility.etl_execution_log_event OWNER TO hcbi_utility;
COMMENT ON TABLE hcbi_utility.etl_execution_log_event IS
    'Eventi logici acquisiti dai segmenti dei log NiFi/FMR e scheduler DWH.';
COMMENT ON COLUMN hcbi_utility.etl_execution_log_event.message_text IS
    'Testo dell''evento con redazione automatica dei pattern di segreti noti.';

CREATE INDEX ix_etl_execution_log_event_execution_time
    ON hcbi_utility.etl_execution_log_event
       (event_execution_uuid, event_timestamp);
CREATE INDEX ix_etl_execution_log_event_scheduler_run
    ON hcbi_utility.etl_execution_log_event
       (manifest_scheduler_run_id, event_timestamp);
CREATE INDEX ix_etl_execution_log_event_ingestion
    ON hcbi_utility.etl_execution_log_event (ingestion_id);

GRANT USAGE ON SCHEMA hcbi_utility TO hcbi_ras;
GRANT SELECT, INSERT
    ON hcbi_utility.etl_execution_log_event TO hcbi_ras;
GRANT USAGE, SELECT
    ON SEQUENCE hcbi_utility.etl_execution_log_event_event_id_seq
    TO hcbi_ras;

COMMIT;
