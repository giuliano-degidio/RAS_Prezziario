
CREATE TABLE hcbi_ras.stg_pubblicazione_analisi_rej (
	ds_anno_pubblicazione VARCHAR(100), 
	cd_codice_analisi VARCHAR(70), 
	nr_quantita VARCHAR(100), 
	cd_articolo VARCHAR(70), 
	cd_versione VARCHAR(20), 
	id_sorgente_pubblicazione_analisi VARCHAR(100), 
	id_sorgente_categoria VARCHAR(20), 
	tx_motivo_scarto VARCHAR(4000), 
	nr_riga SMALLINT
);
