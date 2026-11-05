
CREATE TABLE hcbi_ras.stg_anag_unita_misura (
	cd_unita_misura VARCHAR(20) NOT NULL, 
	ds_unita_misura TEXT, 
	nr_decimali NUMERIC(10, 0), 
	id_sorgente_unita_misura INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	dt_fine_validita TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE hcbi_ras.stg_anag_unita_misura OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_unita_misura IS 'Staging del flusso ANAG_UNITA_MISURA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_unita_misura TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_unita_misura TO hcbi_utility;
