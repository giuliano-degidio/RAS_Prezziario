
CREATE TABLE hcbi_utility.srv_config_chain (
	id_chain BIGINT NOT NULL, 
	ds_chain_name VARCHAR(500) NOT NULL, 
	tx_description VARCHAR(4000), 
	fl_active CHAR(1) DEFAULT 'Y'::bpchar, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	tx_update_by VARCHAR(4000) NOT NULL, 
	CONSTRAINT pk_srv_config_chain PRIMARY KEY (id_chain), 
	CONSTRAINT uk_ds_chain_name UNIQUE NULLS DISTINCT (ds_chain_name), 
	CONSTRAINT chk_srv_config_chain_active CHECK (fl_active = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))
);
