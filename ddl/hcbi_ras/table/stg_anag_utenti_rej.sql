
CREATE TABLE hcbi_ras.stg_anag_utenti_rej (
	id_sorgente_utente VARCHAR(100), 
	cd_username VARCHAR(255), 
	ds_email VARCHAR(255), 
	ds_nome_visualizzato VARCHAR(50), 
	cd_stato VARCHAR(20), 
	cd_tipo_utente VARCHAR(25), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_utenti_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_utenti_rej IS 'Record scartati del flusso ANAG_UTENTI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_utenti_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_utenti_rej TO hcbi_utility;
