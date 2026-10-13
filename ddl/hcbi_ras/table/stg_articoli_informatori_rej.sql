
CREATE TABLE hcbi_ras.stg_articoli_informatori_rej (
	id_sorgente_informatore VARCHAR(100), 
	cd_articolo VARCHAR(60), 
	ds_anno VARCHAR(100), 
	id_sorgente_provincia VARCHAR(100), 
	fl_escluso VARCHAR(20), 
	cd_versione VARCHAR(20), 
	id_sorgente_articoli_informatori VARCHAR(100), 
	id_sorgente_utente VARCHAR(100), 
	tx_motivo_scarto VARCHAR(4000), 
	dt_scarto TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL
);
