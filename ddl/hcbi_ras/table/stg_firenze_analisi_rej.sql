
CREATE TABLE hcbi_ras.stg_firenze_analisi_rej (
	nr_anno VARCHAR(100), 
	ds_regione VARCHAR(4000), 
	ds_provincia VARCHAR(4000), 
	nr_riga_file VARCHAR(100), 
	analisi TEXT, 
	descrizione TEXT, 
	cam TEXT, 
	codice_dettaglio TEXT, 
	cam_codice_dettaglio TEXT, 
	voce_articolo TEXT, 
	codice_collegato TEXT, 
	unita_misura TEXT, 
	quantita TEXT, 
	prezzo_unitario TEXT, 
	importo TEXT, 
	tx_nome_file VARCHAR(4000), 
	dt_caricamento VARCHAR(100), 
	tx_caricamento_by VARCHAR(4000), 
	tx_motivo_scarto VARCHAR(4000) NOT NULL, 
	dt_scarto TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL
);
