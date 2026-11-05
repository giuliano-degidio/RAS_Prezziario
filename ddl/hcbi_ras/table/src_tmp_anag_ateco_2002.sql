
CREATE TABLE hcbi_ras.src_tmp_anag_ateco_2002 (
	cd_ateco_2002 VARCHAR(200), 
	ds_ateco_2002 VARCHAR(512)
);

ALTER TABLE hcbi_ras.src_tmp_anag_ateco_2002 OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_ateco_2002 IS 'Tabella temporanea sorgente del flusso ANAG_ATECO_2002.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_ateco_2002 TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_ateco_2002 TO hcbi_utility;
