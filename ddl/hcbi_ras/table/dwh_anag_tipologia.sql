
CREATE TABLE hcbi_ras.dwh_anag_tipologia (
	id_anag_tipologia BIGSERIAL NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_tipologia VARCHAR(60) NOT NULL, 
	ds_tipologia TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_tipologia PRIMARY KEY (id_anag_tipologia), 
	CONSTRAINT uq_dwh_anag_tipologia UNIQUE NULLS NOT DISTINCT (ds_anno, cd_tipologia, cd_versione, id_sorgente_provincia)
);
