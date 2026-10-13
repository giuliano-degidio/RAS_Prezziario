
CREATE TABLE hcbi_ras.dim_sottocapitolo (
	id_anag_sottocapitolo BIGINT NOT NULL, 
	cd_sottocapitolo VARCHAR(60) NOT NULL, 
	ds_sottocapitolo TEXT NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_sottocapitolo PRIMARY KEY (id_anag_sottocapitolo), 
	CONSTRAINT fk_dim_sottocapitolo_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_sottocapitolo_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_sottocapitolo_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_sottocapitolo UNIQUE NULLS NOT DISTINCT (cd_sottocapitolo, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia)
);
