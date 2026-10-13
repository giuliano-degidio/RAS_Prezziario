
CREATE TABLE hcbi_ras.stg_anag_unita_misura (
	cd_unita_misura VARCHAR(20) NOT NULL, 
	ds_unita_misura TEXT, 
	nr_decimali NUMERIC(10, 0), 
	id_sorgente_unita_misura INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	dt_fine_validita TIMESTAMP WITHOUT TIME ZONE
);
