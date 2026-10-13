
CREATE TABLE hcbi_ras.dim_capitolo (
	id_anag_capitolo BIGINT NOT NULL, 
	cd_capitolo VARCHAR(60) NOT NULL, 
	ds_capitolo TEXT NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_capitolo PRIMARY KEY (id_anag_capitolo), 
	CONSTRAINT fk_dim_capitolo_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_capitolo_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_capitolo_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_capitolo UNIQUE NULLS NOT DISTINCT (cd_capitolo, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia)
);
