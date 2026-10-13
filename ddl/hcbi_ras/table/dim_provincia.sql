
CREATE TABLE hcbi_ras.dim_provincia (
	id_anag_provincia BIGINT NOT NULL, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_area_vasta BIGINT NOT NULL, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_provincia PRIMARY KEY (id_anag_provincia), 
	CONSTRAINT fk_dim_provincia_area_vasta FOREIGN KEY(id_area_vasta) REFERENCES hcbi_ras.dim_area_vasta (id_anag_area_vasta) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_provincia UNIQUE NULLS NOT DISTINCT (cd_provincia)
);
