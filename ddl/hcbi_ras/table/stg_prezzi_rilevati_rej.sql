
CREATE TABLE hcbi_ras.stg_prezzi_rilevati_rej (
	cd_articolo VARCHAR(60), 
	ds_anno VARCHAR(100), 
	id_sorgente_provincia VARCHAR(100), 
	id_sorgente_informatore VARCHAR(100), 
	id_sorgente_rilevatore VARCHAR(100), 
	nr_prezzo VARCHAR(100), 
	dt_inserimento TIMESTAMP WITHOUT TIME ZONE, 
	fl_nascosto VARCHAR(20), 
	ds_anno_ribaltamento VARCHAR(100), 
	cd_versione VARCHAR(20), 
	cd_versione_ribaltamento VARCHAR(100), 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	tx_motivo_scarto VARCHAR(4000), 
	dt_scarto TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL
);
