
CREATE TABLE hcbi_ras.stg_anag_tipologia (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_tipologia VARCHAR(60) NOT NULL, 
	ds_tipologia TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_tipologia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_tipologia IS 'Staging del flusso ANAG_TIPOLOGIA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_tipologia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_tipologia TO hcbi_utility;
