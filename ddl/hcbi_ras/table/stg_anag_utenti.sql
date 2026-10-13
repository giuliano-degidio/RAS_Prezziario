
CREATE TABLE hcbi_ras.stg_anag_utenti (
	id_sorgente_utente BIGINT, 
	cd_username VARCHAR(255) NOT NULL, 
	ds_email VARCHAR(255), 
	ds_nome_visualizzato VARCHAR(50), 
	cd_stato SMALLINT, 
	cd_tipo_utente VARCHAR(25)
);
