
CREATE TABLE hcbi_ras.stg_firenze_analisi (
	nr_anno INTEGER NOT NULL, 
	ds_regione VARCHAR(50) NOT NULL, 
	ds_provincia VARCHAR(50) NOT NULL, 
	nr_riga_file BIGINT NOT NULL, 
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
	tx_nome_file VARCHAR(255) NOT NULL, 
	dt_caricamento TIMESTAMP WITHOUT TIME ZONE, 
	tx_caricamento_by VARCHAR(100), 
	CONSTRAINT uq_stg_firenze_analisi UNIQUE NULLS DISTINCT (nr_anno, nr_riga_file)
);
