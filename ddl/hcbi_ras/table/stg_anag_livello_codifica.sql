
CREATE TABLE hcbi_ras.stg_anag_livello_codifica (
	id_sorgente_livello_codifica BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_livello_codifica OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_livello_codifica IS 'Staging validata del flusso ANAG_LIVELLO_CODIFICA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_livello_codifica TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_livello_codifica TO hcbi_utility;
