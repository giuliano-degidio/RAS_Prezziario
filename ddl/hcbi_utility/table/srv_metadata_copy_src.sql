
CREATE TABLE hcbi_utility.srv_metadata_copy_src (
	id_config BIGSERIAL NOT NULL, 
	id_chain BIGINT NOT NULL, 
	ds_source_name TEXT NOT NULL, 
	ds_target_tmp_table TEXT NOT NULL, 
	fl_active CHAR(1) DEFAULT 'Y'::bpchar NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	tx_creation_by TEXT NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	tx_update_by TEXT NOT NULL, 
	CONSTRAINT pk_srv_metadata_copy_src PRIMARY KEY (id_config), 
	CONSTRAINT fk_srv_metadata_copy_src_id_chain FOREIGN KEY(id_chain) REFERENCES hcbi_utility.srv_config_chain (id_chain)
);
