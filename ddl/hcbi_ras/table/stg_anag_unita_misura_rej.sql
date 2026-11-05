
CREATE TABLE hcbi_ras.stg_anag_unita_misura_rej (
	cd_unita_misura VARCHAR(20), 
	ds_unita_misura TEXT, 
	nr_decimali VARCHAR(100), 
	id_sorgente_unita_misura VARCHAR(100), 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	dt_fine_validita TIMESTAMP WITHOUT TIME ZONE, 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_unita_misura_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_unita_misura_rej IS 'Record scartati del flusso ANAG_UNITA_MISURA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_unita_misura_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_unita_misura_rej TO hcbi_utility;
