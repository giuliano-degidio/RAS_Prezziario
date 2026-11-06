
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

COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.ds_anno IS 'Anno della tipologia.';
COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.cd_versione IS 'Addendum/versione della tipologia.';
COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.cd_tipologia IS 'Codice della tipologia.';
COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.ds_tipologia IS 'Descrizione della tipologia.';
COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.id_sorgente_provincia IS 'Identificativo sorgente della provincia letto da frontiera_anag_articolo.';
