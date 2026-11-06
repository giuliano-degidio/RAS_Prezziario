
CREATE TABLE hcbi_ras.src_tmp_anag_articolo (
	id VARCHAR(100), 
	anno VARCHAR(100), 
	codice VARCHAR(60), 
	livello VARCHAR(20), 
	nome TEXT, 
	descrizione TEXT, 
	eliminato VARCHAR(20), 
	prezzo_regionale VARCHAR(20), 
	unita_misura VARCHAR(100), 
	macro_gruppo VARCHAR(20), 
	spese_generali VARCHAR(100), 
	di_cui_analisi VARCHAR(100), 
	utile_impresa VARCHAR(100), 
	last_update TIMESTAMP WITHOUT TIME ZONE, 
	analisi_approvata VARCHAR(20), 
	has_utile_impresa VARCHAR(20), 
	analisi_pubblicata VARCHAR(20), 
	addendum VARCHAR(20), 
	is_analisi VARCHAR(20), 
	is_cam VARCHAR(20), 
	is_ufficiale VARCHAR(20), 
	id_categoria VARCHAR(100), 
	is_manodopera VARCHAR(20), 
	codice_lev1 VARCHAR(60), 
	codice_lev2 VARCHAR(60), 
	codice_lev3 VARCHAR(60), 
	codice_lev4 VARCHAR(60), 
	codice_lev5 VARCHAR(60), 
	is_minuteria VARCHAR(20), 
	percentuale_aumento VARCHAR(100), 
	annotazione TEXT, 
	esporta_come_articolo VARCHAR(20), 
	escludi_manodopera VARCHAR(20), 
	provincia VARCHAR(20) DEFAULT '0'::character varying
);

ALTER TABLE hcbi_ras.src_tmp_anag_articolo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_articolo IS 'Tabella temporanea sorgente del flusso ANAG_ARTICOLO';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_articolo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_articolo TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.src_tmp_anag_articolo.provincia IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';
