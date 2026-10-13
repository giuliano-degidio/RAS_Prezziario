
CREATE TABLE hcbi_ras.dim_area_vasta (
	id_anag_area_vasta BIGINT NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	ds_nome VARCHAR(100) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_area_vasta PRIMARY KEY (id_anag_area_vasta), 
	CONSTRAINT uq_dim_area_vasta UNIQUE NULLS NOT DISTINCT (ds_nome)
);
