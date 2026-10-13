
CREATE TABLE hcbi_ras.dwh_anag_capitolo (
	id_anag_capitolo BIGSERIAL NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_capitolo VARCHAR(60) NOT NULL, 
	ds_capitolo TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_capitolo PRIMARY KEY (id_anag_capitolo), 
	CONSTRAINT uq_dwh_anag_capitolo UNIQUE NULLS NOT DISTINCT (ds_anno, cd_capitolo, cd_versione, id_sorgente_provincia)
);
