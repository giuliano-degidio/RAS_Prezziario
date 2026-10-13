
CREATE TABLE hcbi_ras.dwh_anag_tipo_utente (
	id_anag_tipo_utente BIGSERIAL NOT NULL, 
	ds_tipo_utente VARCHAR(100) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_tipo_utente PRIMARY KEY (id_anag_tipo_utente), 
	CONSTRAINT uq_dwh_anag_tipo_utente UNIQUE NULLS NOT DISTINCT (ds_tipo_utente)
);
