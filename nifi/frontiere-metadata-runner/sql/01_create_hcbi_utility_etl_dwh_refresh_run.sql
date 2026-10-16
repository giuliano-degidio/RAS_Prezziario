-- PostgreSQL. Validare sulla versione installata.
BEGIN;

CREATE TABLE hcbi_utility.etl_dwh_refresh_run (
    run_id          bigint GENERATED ALWAYS AS IDENTITY,
    execution_uuid  uuid                        NOT NULL,
    chain_id        integer                     NOT NULL,
    started_at      timestamp with time zone    NOT NULL DEFAULT clock_timestamp(),
    ended_at        timestamp with time zone,
    status          varchar(20)                 NOT NULL DEFAULT 'RUNNING',
    error_message   text,
    CONSTRAINT pk_etl_dwh_refresh_run PRIMARY KEY (run_id),
    CONSTRAINT ck_etl_dwh_refresh_run_chain CHECK (chain_id > 0),
    CONSTRAINT ck_etl_dwh_refresh_run_status CHECK (status IN ('RUNNING','SUCCEEDED','FAILED','SKIPPED')),
    CONSTRAINT ck_etl_dwh_refresh_run_dates CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT ck_etl_dwh_refresh_run_running CHECK ((status='RUNNING' AND ended_at IS NULL) OR status<>'RUNNING'),
    CONSTRAINT ck_etl_dwh_refresh_run_closed CHECK ((status IN ('SUCCEEDED','FAILED','SKIPPED') AND ended_at IS NOT NULL) OR status='RUNNING'),
    CONSTRAINT ck_etl_dwh_refresh_run_error CHECK ((status='FAILED' AND error_message IS NOT NULL) OR status<>'FAILED')
);

ALTER TABLE hcbi_utility.etl_dwh_refresh_run OWNER TO hcbi_utility;
COMMENT ON TABLE hcbi_utility.etl_dwh_refresh_run IS 'Tracciamento esecuzioni della procedura DWH hcbi_utility.prc_execute_chain.';
CREATE INDEX ix_etl_dwh_refresh_run_01 ON hcbi_utility.etl_dwh_refresh_run (execution_uuid, started_at DESC);
CREATE INDEX ix_etl_dwh_refresh_run_02 ON hcbi_utility.etl_dwh_refresh_run (status, started_at DESC);

GRANT USAGE ON SCHEMA hcbi_utility TO hcbi_utility, hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
    ON hcbi_utility.etl_dwh_refresh_run TO hcbi_utility, hcbi_ras;
GRANT USAGE, SELECT, UPDATE
    ON ALL SEQUENCES IN SCHEMA hcbi_utility TO hcbi_utility, hcbi_ras;

ALTER DEFAULT PRIVILEGES FOR ROLE hcbi_utility IN SCHEMA hcbi_utility
    GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
    ON TABLES TO hcbi_utility, hcbi_ras;
ALTER DEFAULT PRIVILEGES FOR ROLE hcbi_utility IN SCHEMA hcbi_utility
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO hcbi_utility, hcbi_ras;

COMMIT;
