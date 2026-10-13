
CREATE TABLE hcbi_ras.stg_pubblicazione_analisi (
	ds_anno_pubblicazione NUMERIC(10, 0) NOT NULL, 
	cd_codice_analisi VARCHAR(70) NOT NULL, 
	nr_quantita NUMERIC(24, 6), 
	cd_articolo VARCHAR(70) NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_pubblicazione_analisi BIGINT, 
	id_sorgente_categoria BIGINT, 
	nr_riga SMALLINT NOT NULL
);
