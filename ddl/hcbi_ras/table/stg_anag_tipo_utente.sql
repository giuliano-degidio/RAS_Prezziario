
CREATE TABLE hcbi_ras.stg_anag_tipo_utente (
	ds_tipo_utente VARCHAR(100) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_tipo_utente OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_tipo_utente IS 'Staging del flusso ANAG_TIPO_UTENTE';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_tipo_utente TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_tipo_utente TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_anag_tipo_utente.ds_tipo_utente IS 'Tipologia dell''utente.';
