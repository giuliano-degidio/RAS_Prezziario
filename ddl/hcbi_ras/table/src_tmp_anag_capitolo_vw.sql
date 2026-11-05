
CREATE TABLE hcbi_ras.src_tmp_anag_capitolo_vw (
	anno VARCHAR(100), 
	addendum VARCHAR(20), 
	codice VARCHAR(60), 
	nome TEXT, 
	provincia VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_capitolo_vw OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_capitolo_vw IS 'Tabella temporanea del flusso ANAG_CAPITOLO alimentata dalla vista di frontiera.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_capitolo_vw TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_capitolo_vw TO hcbi_utility;
