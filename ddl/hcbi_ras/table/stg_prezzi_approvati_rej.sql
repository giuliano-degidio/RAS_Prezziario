
CREATE TABLE hcbi_ras.stg_prezzi_approvati_rej (
	cd_articolo VARCHAR(60), 
	ds_anno VARCHAR(100), 
	nr_prezzo VARCHAR(100), 
	id_sorgente_provincia VARCHAR(100), 
	dt_approvazione TIMESTAMP WITHOUT TIME ZONE, 
	cd_versione VARCHAR(20), 
	tx_motivo_scarto VARCHAR(4000), 
	dt_scarto TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL
);
