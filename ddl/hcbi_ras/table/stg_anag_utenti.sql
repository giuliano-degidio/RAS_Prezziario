
CREATE TABLE hcbi_ras.stg_anag_utenti (
	id_sorgente_utente BIGINT, 
	cd_username VARCHAR(255) NOT NULL, 
	ds_email VARCHAR(255), 
	ds_nome_visualizzato VARCHAR(50), 
	cd_stato SMALLINT, 
	cd_tipo_utente VARCHAR(25)
);

ALTER TABLE hcbi_ras.stg_anag_utenti OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_utenti IS 'Staging del flusso ANAG_UTENTI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_utenti TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_utenti TO hcbi_utility;
