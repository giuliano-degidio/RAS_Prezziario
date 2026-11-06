
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

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.id_sorgente_utente IS 'Identificativo dell''utente nella sorgente operazionale';
COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_username IS 'Username dell''utente';
COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.ds_email IS 'Indirizzo email dell''utente';
COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.ds_nome_visualizzato IS 'Nome visualizzato dell''utente';
COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_stato IS 'Stato dell''utente';
COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_tipo_utente IS 'Tipologia dell''utente';
