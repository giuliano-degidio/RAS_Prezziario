
CREATE TABLE hcbi_ras.dim_periodo (
	id_periodo SERIAL NOT NULL, 
	ds_periodo VARCHAR(500) NOT NULL, 
	cd_modalita_temporale VARCHAR(50) NOT NULL, 
	ds_modalita_temporale VARCHAR(500) NOT NULL, 
	ds_tipo_periodo VARCHAR(500) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE, 
	tx_creation_by VARCHAR(4000), 
	dt_update TIMESTAMP(6) WITHOUT TIME ZONE, 
	tx_update_by VARCHAR, 
	CONSTRAINT pk_dim_periodo PRIMARY KEY (id_periodo), 
	CONSTRAINT uk_dim_periodo UNIQUE NULLS DISTINCT (ds_anno)
);
