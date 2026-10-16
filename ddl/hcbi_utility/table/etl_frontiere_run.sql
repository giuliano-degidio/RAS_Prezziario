CREATE TABLE hcbi_utility.etl_frontiere_run (
	run_id BIGINT NOT NULL,
	frontiera_code VARCHAR(100) NOT NULL,
	started_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
	ended_at TIMESTAMPTZ,
	status VARCHAR(20) NOT NULL DEFAULT 'RUNNING'::character varying,
	rows_read BIGINT,
	rows_written BIGINT,
	error_message TEXT,
	warning_message TEXT,
	nifi_flowfile_uuid VARCHAR(100),
	CONSTRAINT pk_etl_frontiere_run PRIMARY KEY (run_id),
	CONSTRAINT fk_etl_frontiere_run_config FOREIGN KEY(frontiera_code) REFERENCES hcbi_utility.etl_frontiere_config (frontiera_code),
	CONSTRAINT ck_etl_frontiere_run_closed CHECK (((status)::text = ANY ((ARRAY['SUCCEEDED'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[])) AND ended_at IS NOT NULL OR (status)::text = 'RUNNING'::text),
	CONSTRAINT ck_etl_frontiere_run_dates CHECK (ended_at IS NULL OR ended_at >= started_at),
	CONSTRAINT ck_etl_frontiere_run_error CHECK (((status)::text = 'FAILED'::text) AND error_message IS NOT NULL OR (status)::text <> 'FAILED'::text),
	CONSTRAINT ck_etl_frontiere_run_rows_read CHECK (rows_read IS NULL OR rows_read >= 0),
	CONSTRAINT ck_etl_frontiere_run_rows_written CHECK (rows_written IS NULL OR rows_written >= 0),
	CONSTRAINT ck_etl_frontiere_run_running CHECK (((status)::text = 'RUNNING'::text) AND ended_at IS NULL OR (status)::text <> 'RUNNING'::text),
	CONSTRAINT ck_etl_frontiere_run_status CHECK ((status)::text = ANY ((ARRAY['RUNNING'::character varying, 'SUCCEEDED'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[]))
);
CREATE INDEX ix_etl_frontiere_run_01 ON hcbi_utility.etl_frontiere_run USING btree (frontiera_code, started_at DESC) WITH (fillfactor='100', deduplicate_items='true');
CREATE INDEX ix_etl_frontiere_run_02 ON hcbi_utility.etl_frontiere_run USING btree (status, started_at DESC) WITH (fillfactor='100', deduplicate_items='true');
