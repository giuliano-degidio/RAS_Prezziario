
CREATE TABLE hcbi_ras.stg_pubblicazione_analisi (
	ds_anno_pubblicazione NUMERIC(10, 0) NOT NULL, 
	cd_codice_analisi VARCHAR(70) NOT NULL, 
	nr_quantita NUMERIC(24, 6), 
	cd_articolo VARCHAR(70) NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_pubblicazione_analisi BIGINT, 
	id_sorgente_categoria BIGINT, 
	nr_riga SMALLINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_pubblicazione_analisi OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_pubblicazione_analisi IS 'Staging del flusso PUBBLICAZIONE_ANALISI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_pubblicazione_analisi TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_pubblicazione_analisi TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_pubblicazione_analisi.cd_articolo IS 'Codice articolo associato all''analisi';
