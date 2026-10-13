
CREATE TABLE hcbi_ras.dim_utenti (
	id_anag_utente BIGINT NOT NULL, 
	id_sorgente_utente BIGINT, 
	cd_username VARCHAR(255) NOT NULL, 
	ds_email VARCHAR(255), 
	ds_nome_visualizzato VARCHAR(50), 
	cd_stato SMALLINT, 
	cd_tipo_utente VARCHAR(25), 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_utenti PRIMARY KEY (id_anag_utente), 
	CONSTRAINT uq_dim_utenti UNIQUE NULLS NOT DISTINCT (cd_username)
);
