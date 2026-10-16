CREATE TABLE hcbi_utility.etl_dwh_refresh_run (
	run_id BIGINT NOT NULL,
	execution_uuid UUID NOT NULL,
	chain_id INTEGER NOT NULL,
	started_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
	ended_at TIMESTAMPTZ,
	status VARCHAR(20) NOT NULL DEFAULT 'RUNNING'::character varying,
	error_message TEXT,
	CONSTRAINT pk_etl_dwh_refresh_run PRIMARY KEY (run_id),
	CONSTRAINT ck_etl_dwh_refresh_run_chain CHECK (chain_id > 0),
	CONSTRAINT ck_etl_dwh_refresh_run_closed CHECK (((status)::text = ANY ((ARRAY['SUCCEEDED'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[])) AND ended_at IS NOT NULL OR (status)::text = 'RUNNING'::text),
	CONSTRAINT ck_etl_dwh_refresh_run_dates CHECK (ended_at IS NULL OR ended_at >= started_at),
	CONSTRAINT ck_etl_dwh_refresh_run_error CHECK (((status)::text = 'FAILED'::text) AND error_message IS NOT NULL OR (status)::text <> 'FAILED'::text),
	CONSTRAINT ck_etl_dwh_refresh_run_running CHECK (((status)::text = 'RUNNING'::text) AND ended_at IS NULL OR (status)::text <> 'RUNNING'::text),
	CONSTRAINT ck_etl_dwh_refresh_run_status CHECK ((status)::text = ANY ((ARRAY['RUNNING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[]))
);
CREATE INDEX ix_etl_dwh_refresh_run_01 ON hcbi_utility.etl_dwh_refresh_run USING btree (execution_uuid, started_at DESC);
CREATE INDEX ix_etl_dwh_refresh_run_02 ON hcbi_utility.etl_dwh_refresh_run USING btree (status, started_at DESC);
