
CREATE TABLE hcbi_ras.stg_anag_sottocapitolo (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_sottocapitolo VARCHAR(60) NOT NULL, 
	ds_sottocapitolo TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_sottocapitolo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_sottocapitolo IS 'Staging del flusso ANAG_SOTTOCAPITOLO';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_sottocapitolo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_sottocapitolo TO hcbi_utility;
