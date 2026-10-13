
CREATE TABLE hcbi_ras.dwh_anag_unita_misura (
	id_anag_unita_misura BIGSERIAL NOT NULL, 
	cd_unita_misura VARCHAR(20) NOT NULL, 
	ds_unita_misura TEXT, 
	nr_decimali NUMERIC(10, 0), 
	id_sorgente_unita_misura INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	dt_fine_validita TIMESTAMP WITHOUT TIME ZONE, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_unita_misura PRIMARY KEY (id_anag_unita_misura), 
	CONSTRAINT uq_dwh_anag_unita_misura UNIQUE NULLS NOT DISTINCT (cd_unita_misura)
);
