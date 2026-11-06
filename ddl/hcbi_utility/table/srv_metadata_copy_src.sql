
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

ALTER TABLE hcbi_utility.srv_metadata_copy_src OWNER TO hcbi_utility;
COMMENT ON TABLE hcbi_utility.srv_metadata_copy_src IS 'Tabella di servizio, controlli, configurazioni Metadata Copy Src';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_utility.srv_metadata_copy_src TO hcbi_ras;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_utility.srv_metadata_copy_src TO hcbi_utility;

COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.id_config IS 'ID di sistema Config';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.id_chain IS 'ID di sistema Chain';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.ds_source_name IS 'Descrizione Source Name';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.ds_target_tmp_table IS 'Descrizione Target Tmp Table';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.fl_active IS 'Flag Active';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.dt_creation IS 'Data di creazione del record';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.tx_creation_by IS 'Processo che ha creato il record';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.dt_update IS 'Data di aggiornamento del record';
COMMENT ON COLUMN hcbi_utility.srv_metadata_copy_src.tx_update_by IS 'Processo che ha aggiornato il record';
