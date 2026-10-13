
CREATE TABLE hcbi_ras.stg_anag_unita_misura_rej (
	cd_unita_misura VARCHAR(20), 
	ds_unita_misura TEXT, 
	nr_decimali VARCHAR(100), 
	id_sorgente_unita_misura VARCHAR(100), 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	dt_fine_validita TIMESTAMP WITHOUT TIME ZONE, 
	tx_motivo_scarto VARCHAR(4000)
);
