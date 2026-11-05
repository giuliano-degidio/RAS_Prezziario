
CREATE TABLE hcbi_ras.src_tmp_prezzi_approvati (
	codice VARCHAR(60), 
	anno VARCHAR(100), 
	prezzo VARCHAR(100), 
	provincia VARCHAR(100), 
	data_approvazione TIMESTAMP WITHOUT TIME ZONE, 
	addendum VARCHAR(20)
);

ALTER TABLE hcbi_ras.src_tmp_prezzi_approvati OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_prezzi_approvati IS 'Sorgente temporanea del flusso PREZZI_APPROVATI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_prezzi_approvati TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_prezzi_approvati TO hcbi_utility;
