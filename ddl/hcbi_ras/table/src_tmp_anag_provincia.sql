
CREATE TABLE hcbi_ras.src_tmp_anag_provincia (
	id VARCHAR(100), 
	provincia VARCHAR(2), 
	nome VARCHAR(100), 
	id_area_vasta VARCHAR(20), 
	provincia_principale_regionale VARCHAR(20), 
	provincia_principale_area_vasta VARCHAR(20)
);

ALTER TABLE hcbi_ras.src_tmp_anag_provincia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_provincia IS 'Tabella temporanea sorgente del flusso ANAG_PROVINCIA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_provincia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_provincia TO hcbi_utility;
