
CREATE TABLE hcbi_ras.dim_tipologia (
	id_anag_tipologia BIGINT NOT NULL, 
	cd_tipologia VARCHAR(60) NOT NULL, 
	ds_tipologia TEXT NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_tipologia PRIMARY KEY (id_anag_tipologia), 
	CONSTRAINT fk_dim_tipologia_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_tipologia_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_tipologia_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_tipologia UNIQUE NULLS NOT DISTINCT (cd_tipologia, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia)
);
