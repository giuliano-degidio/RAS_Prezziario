
CREATE TABLE hcbi_ras.dwh_anag_provincia (
	id_anag_provincia BIGSERIAL NOT NULL, 
	id_sorgente_provincia BIGINT, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_provincia PRIMARY KEY (id_anag_provincia), 
	CONSTRAINT uq_dwh_anag_provincia UNIQUE NULLS NOT DISTINCT (cd_provincia)
);
