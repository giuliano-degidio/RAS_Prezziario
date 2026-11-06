
CREATE TABLE hcbi_ras.frontiera_firenze_analisi (
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
	dt_caricamento TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_caricamento_by VARCHAR(100) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT frontiera_firenze_analisi_pkey PRIMARY KEY (nr_anno, nr_riga_file), 
	CONSTRAINT uk_frontiera_firenze_analisi_riga UNIQUE NULLS DISTINCT (nr_anno, nr_riga_file), 
	CONSTRAINT ck_frontiera_firenze_analisi_anno CHECK (nr_anno >= 2000 AND nr_anno <= 2999), 
	CONSTRAINT ck_frontiera_firenze_analisi_file CHECK (tx_nome_file::text ~ '^Firenze-Analisi-[0-9]{4}[.]csv$'::text), 
	CONSTRAINT ck_frontiera_firenze_analisi_provincia CHECK (btrim(ds_provincia::text) <> ''::text), 
	CONSTRAINT ck_frontiera_firenze_analisi_regione CHECK (btrim(ds_regione::text) <> ''::text), 
	CONSTRAINT ck_frontiera_firenze_analisi_riga CHECK (nr_riga_file > 0)
);

ALTER TABLE hcbi_ras.frontiera_firenze_analisi OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.frontiera_firenze_analisi IS 'Frontiera multi-annualita del flusso FIRENZE_ANALISI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_firenze_analisi TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, TRUNCATE, UPDATE ON hcbi_ras.frontiera_firenze_analisi TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.nr_anno IS 'Anno di riferimento.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.ds_regione IS 'Regione dichiarata dall ETL.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.ds_provincia IS 'Provincia dichiarata dall ETL.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.nr_riga_file IS 'Numero progressivo della riga logica, generato dall ETL e univoco nell anno.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.analisi IS 'Codice analisi sulla testata sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.descrizione IS 'Descrizione estesa della testata analisi.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.cam IS 'Indicazione CAM sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.codice_dettaglio IS 'Codice sezione, componente o totale sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.cam_codice_dettaglio IS 'Codice CAM del dettaglio.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.voce_articolo IS 'Descrizione della voce o componente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.codice_collegato IS 'Codice collegato sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.unita_misura IS 'Unita di misura sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.quantita IS 'Quantita testuale sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.prezzo_unitario IS 'Prezzo unitario testuale sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.importo IS 'Importo testuale sorgente.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.tx_nome_file IS 'Nome del file CSV.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.dt_caricamento IS 'Data e ora del caricamento.';
COMMENT ON COLUMN hcbi_ras.frontiera_firenze_analisi.tx_caricamento_by IS 'Utente o processo di caricamento.';
