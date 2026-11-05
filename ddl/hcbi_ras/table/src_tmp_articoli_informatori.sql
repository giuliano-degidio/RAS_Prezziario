
CREATE TABLE hcbi_ras.src_tmp_articoli_informatori (
	id_informatore VARCHAR(100), 
	codice_articolo VARCHAR(60), 
	anno VARCHAR(100), 
	provincia VARCHAR(100), 
	escluso VARCHAR(20), 
	addendum VARCHAR(20), 
	id VARCHAR(100), 
	user_id VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_articoli_informatori OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_articoli_informatori IS 'Sorgente temporanea del flusso ARTICOLI_INFORMATORI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_articoli_informatori TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_articoli_informatori TO hcbi_utility;
