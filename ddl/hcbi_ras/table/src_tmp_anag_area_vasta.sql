
CREATE TABLE hcbi_ras.src_tmp_anag_area_vasta (
	id VARCHAR(100), 
	nome VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_area_vasta OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_area_vasta IS 'Tabella temporanea sorgente del flusso ANAG_AREA_VASTA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_area_vasta TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_area_vasta TO hcbi_utility;
