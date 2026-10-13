
CREATE TABLE hcbi_utility.srv_config_step (
	id_step BIGSERIAL NOT NULL, 
	id_chain BIGINT NOT NULL, 
	ds_step_name VARCHAR(100) NOT NULL, 
	ds_package_name VARCHAR(100) NOT NULL, 
	nr_step_order BIGINT NOT NULL, 
	id_dependency_step BIGINT, 
	nr_retry_count BIGINT DEFAULT 0, 
	fl_blocking CHAR(1) DEFAULT 'Y'::bpchar, 
	fl_active CHAR(1) DEFAULT 'Y'::bpchar, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	tx_update_by VARCHAR(4000) NOT NULL, 
	CONSTRAINT pk_srv_config_step PRIMARY KEY (id_step, id_chain), 
	CONSTRAINT fk_srv_config_step_id_chain FOREIGN KEY(id_chain) REFERENCES hcbi_utility.srv_config_chain (id_chain), 
	CONSTRAINT chk_srv_config_step_active CHECK (fl_active = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])), 
	CONSTRAINT chk_srv_config_step_blocking CHECK (fl_blocking = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])), 
	CONSTRAINT chk_srv_config_step_retry CHECK (nr_retry_count >= 0)
);
