
CREATE TABLE hcbi_ras.stg_pubblicazione_analisi_rej (
	ds_anno_pubblicazione VARCHAR(100), 
	cd_codice_analisi VARCHAR(70), 
	nr_quantita VARCHAR(100), 
	cd_articolo VARCHAR(70), 
	cd_versione VARCHAR(20), 
	id_sorgente_pubblicazione_analisi VARCHAR(100), 
	id_sorgente_categoria VARCHAR(20), 
	tx_motivo_scarto VARCHAR(4000), 
	nr_riga SMALLINT
);

ALTER TABLE hcbi_ras.stg_pubblicazione_analisi_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_pubblicazione_analisi_rej IS 'Record scartati del flusso PUBBLICAZIONE_ANALISI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_pubblicazione_analisi_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_pubblicazione_analisi_rej TO hcbi_utility;
