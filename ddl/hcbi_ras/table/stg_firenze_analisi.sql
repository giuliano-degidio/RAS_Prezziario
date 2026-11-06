
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

ALTER TABLE hcbi_ras.stg_firenze_analisi OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_firenze_analisi IS 'Staging fedele alla struttura originaria del flusso FIRENZE_ANALISI.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_firenze_analisi TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, TRUNCATE, UPDATE ON hcbi_ras.stg_firenze_analisi TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_firenze_analisi.quantita IS 'Quantita testuale conservata nella rappresentazione sorgente.';
COMMENT ON COLUMN hcbi_ras.stg_firenze_analisi.prezzo_unitario IS 'Prezzo unitario testuale conservato nella rappresentazione sorgente.';
COMMENT ON COLUMN hcbi_ras.stg_firenze_analisi.importo IS 'Importo testuale conservato nella rappresentazione sorgente.';
