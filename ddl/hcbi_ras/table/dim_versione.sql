
CREATE TABLE hcbi_ras.dim_versione (
	id_anag_versione BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	ds_versione TEXT, 
	id_anag_provincia BIGINT NOT NULL, 
	nr_spese_generali NUMERIC(10, 5) NOT NULL, 
	nr_utile_impresa NUMERIC(10, 5) NOT NULL, 
	nr_di_cui_analisi NUMERIC(10, 5) NOT NULL, 
	fl_pubblicazione_regionale SMALLINT NOT NULL, 
	fl_is_errata_corrige SMALLINT NOT NULL, 
	fl_mostra_cam SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_versione PRIMARY KEY (id_anag_versione), 
	CONSTRAINT fk_dim_versione_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_versione_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_versione UNIQUE NULLS NOT DISTINCT (id_periodo_pubblicazione, cd_versione, id_anag_provincia)
);
