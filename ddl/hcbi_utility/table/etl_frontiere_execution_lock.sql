CREATE TABLE hcbi_utility.etl_frontiere_execution_lock (
	frontiera_code VARCHAR(100) NOT NULL,
	run_id BIGINT NOT NULL,
	acquired_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
	acquired_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
	CONSTRAINT pk_etl_frontiere_execution_lock PRIMARY KEY (frontiera_code),
	CONSTRAINT fk_etl_frontiere_execution_lock_config FOREIGN KEY(frontiera_code) REFERENCES hcbi_utility.etl_frontiere_config (frontiera_code),
	CONSTRAINT fk_etl_frontiere_execution_lock_run FOREIGN KEY(run_id) REFERENCES hcbi_utility.etl_frontiere_run (run_id) ON DELETE CASCADE,
	CONSTRAINT uq_etl_frontiere_execution_lock_run UNIQUE (run_id)
);
