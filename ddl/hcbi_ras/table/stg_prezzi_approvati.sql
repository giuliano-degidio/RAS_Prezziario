
CREATE TABLE hcbi_ras.stg_prezzi_approvati (
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	dt_approvazione TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	cd_versione SMALLINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_prezzi_approvati OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_prezzi_approvati IS 'Staging valida del flusso PREZZI_APPROVATI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_prezzi_approvati TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_prezzi_approvati TO hcbi_utility;
