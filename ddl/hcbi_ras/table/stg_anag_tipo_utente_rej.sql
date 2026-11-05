
CREATE TABLE hcbi_ras.stg_anag_tipo_utente_rej (
	ds_tipo_utente VARCHAR(100), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_tipo_utente_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_tipo_utente_rej IS 'Record scartati del flusso ANAG_TIPO_UTENTE';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_tipo_utente_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_tipo_utente_rej TO hcbi_utility;
