
CREATE TABLE hcbi_ras.frontiera_pubblicazione_analisi (
	anno VARCHAR(100), 
	codice_analisi VARCHAR(70), 
	quantita VARCHAR(100), 
	codice_elemento VARCHAR(70), 
	addendum VARCHAR(20), 
	id VARCHAR(100), 
	id_categoria VARCHAR(20), 
	nr_riga SMALLINT
);

ALTER TABLE hcbi_ras.frontiera_pubblicazione_analisi OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.frontiera_pubblicazione_analisi IS 'Frontiera del flusso PUBBLICAZIONE_ANALISI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_pubblicazione_analisi TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.frontiera_pubblicazione_analisi TO hcbi_utility;
