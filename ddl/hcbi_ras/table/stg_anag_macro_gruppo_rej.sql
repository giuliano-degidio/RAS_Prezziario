
CREATE TABLE hcbi_ras.stg_anag_macro_gruppo_rej (
	id_sorgente_macro_gruppo VARCHAR(100), 
	ds_nome VARCHAR(100), 
	ds_plurale VARCHAR(100), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_macro_gruppo_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_macro_gruppo_rej IS 'Record scartati del flusso ANAG_MACRO_GRUPPO.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_macro_gruppo_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_macro_gruppo_rej TO hcbi_utility;
