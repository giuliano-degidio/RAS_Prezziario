
CREATE TABLE hcbi_ras.stg_anag_macro_gruppo (
	id_sorgente_macro_gruppo BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50)
);

ALTER TABLE hcbi_ras.stg_anag_macro_gruppo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_macro_gruppo IS 'Staging validata del flusso ANAG_MACRO_GRUPPO.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_macro_gruppo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_macro_gruppo TO hcbi_utility;
