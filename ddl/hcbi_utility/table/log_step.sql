
CREATE TABLE hcbi_utility.log_step (
	id_log BIGSERIAL NOT NULL, 
	id_chain_log BIGINT, 
	id_chain BIGINT, 
	id_step BIGINT, 
	ds_step_name VARCHAR(500), 
	dt_start TIMESTAMP WITHOUT TIME ZONE, 
	dt_end TIMESTAMP WITHOUT TIME ZONE, 
	ds_status VARCHAR(500), 
	tx_error_message VARCHAR(4000), 
	nr_rec_selected BIGINT, 
	nr_rec_inserted BIGINT, 
	nr_rec_updated BIGINT, 
	nr_rec_deleted BIGINT, 
	nr_rec_errors BIGINT, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp(), 
	tx_creation_by VARCHAR(4000), 
	dt_update TIMESTAMP WITHOUT TIME ZONE, 
	tx_update_by VARCHAR(4000), 
	CONSTRAINT pk_log_step PRIMARY KEY (id_log), 
	CONSTRAINT fk_log_step_id_chain_id_step FOREIGN KEY(id_step, id_chain) REFERENCES hcbi_utility.srv_config_step (id_step, id_chain)
);

CREATE INDEX ix_log_step_chain ON hcbi_utility.log_step (id_chain);

CREATE INDEX ix_log_step_chainlog ON hcbi_utility.log_step (id_chain_log);

CREATE INDEX ix_log_step_status ON hcbi_utility.log_step (ds_status);

CREATE INDEX ix_log_step_step ON hcbi_utility.log_step (id_step);
