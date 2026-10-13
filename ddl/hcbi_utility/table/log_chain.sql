
CREATE TABLE hcbi_utility.log_chain (
	id_log BIGSERIAL NOT NULL, 
	id_chain BIGINT, 
	dt_start TIMESTAMP WITHOUT TIME ZONE, 
	dt_end TIMESTAMP WITHOUT TIME ZONE, 
	ds_status VARCHAR(500), 
	tx_error_message VARCHAR(4000), 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000), 
	dt_update TIMESTAMP WITHOUT TIME ZONE, 
	tx_update_by VARCHAR(4000), 
	CONSTRAINT pk_log_chain PRIMARY KEY (id_log), 
	CONSTRAINT fk_log_chain_id_chain FOREIGN KEY(id_chain) REFERENCES hcbi_utility.srv_config_chain (id_chain)
);

CREATE INDEX ix_log_chain_id_chain ON hcbi_utility.log_chain (id_chain);

CREATE INDEX ix_log_chain_status ON hcbi_utility.log_chain (ds_status);
