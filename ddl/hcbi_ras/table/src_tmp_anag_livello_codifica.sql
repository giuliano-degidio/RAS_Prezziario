
CREATE TABLE hcbi_ras.src_tmp_anag_livello_codifica (
	id VARCHAR(100), 
	nome VARCHAR(100), 
	plurale VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_livello_codifica OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_livello_codifica IS 'Tabella sorgente temporanea del flusso ANAG_LIVELLO_CODIFICA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_livello_codifica TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_livello_codifica TO hcbi_utility;
