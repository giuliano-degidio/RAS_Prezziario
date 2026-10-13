
CREATE TABLE hcbi_ras.dwh_pubblicazione_analisi (
	id_pubblicazione_analisi BIGSERIAL NOT NULL, 
	ds_anno_pubblicazione NUMERIC(10, 0) NOT NULL, 
	cd_codice_analisi VARCHAR(70) NOT NULL, 
	nr_quantita NUMERIC(24, 6), 
	cd_articolo VARCHAR(70) NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_pubblicazione_analisi BIGINT, 
	id_sorgente_categoria BIGINT, 
	nr_riga SMALLINT, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_pubblicazione_analisi PRIMARY KEY (id_pubblicazione_analisi), 
	CONSTRAINT uq_dwh_pubblicazione_analisi UNIQUE NULLS NOT DISTINCT (ds_anno_pubblicazione, cd_codice_analisi, cd_articolo, cd_versione, nr_riga)
);
