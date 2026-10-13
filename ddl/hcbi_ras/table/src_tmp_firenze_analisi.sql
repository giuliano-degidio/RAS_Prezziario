
CREATE TABLE hcbi_ras.src_tmp_firenze_analisi (
	nr_anno INTEGER, 
	ds_regione VARCHAR(50), 
	ds_provincia VARCHAR(50), 
	nr_riga_file BIGINT, 
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
	tx_nome_file VARCHAR(255), 
	dt_caricamento TIMESTAMP WITHOUT TIME ZONE, 
	tx_caricamento_by VARCHAR(100)
);
