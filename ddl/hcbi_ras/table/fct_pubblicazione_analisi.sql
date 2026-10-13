
CREATE TABLE hcbi_ras.fct_pubblicazione_analisi (
	id_pubblicazione_analisi BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_articolo BIGINT NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	cd_codice_analisi VARCHAR(70) NOT NULL, 
	nr_quantita NUMERIC(24, 6), 
	id_sorgente_pubblicazione_analisi BIGINT, 
	id_sorgente_categoria BIGINT, 
	nr_riga SMALLINT, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_fct_pubblicazione_analisi PRIMARY KEY (id_pubblicazione_analisi), 
	CONSTRAINT fk_fct_pub_analisi_articolo FOREIGN KEY(id_anag_articolo) REFERENCES hcbi_ras.dim_articolo (id_anag_articolo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_fct_pub_analisi_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_fct_pub_analisi_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione) ON DELETE RESTRICT ON UPDATE RESTRICT
);
