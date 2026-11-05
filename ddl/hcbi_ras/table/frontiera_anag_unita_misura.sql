
CREATE TABLE hcbi_ras.frontiera_anag_unita_misura (
	codice VARCHAR(20), 
	descrizione TEXT, 
	decimali VARCHAR(100), 
	id VARCHAR(100), 
	last_update TIMESTAMP WITHOUT TIME ZONE, 
	data_fine_validita TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE hcbi_ras.frontiera_anag_unita_misura OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.frontiera_anag_unita_misura IS 'Frontiera del flusso ANAG_UNITA_MISURA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_anag_unita_misura TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.frontiera_anag_unita_misura TO hcbi_utility;
