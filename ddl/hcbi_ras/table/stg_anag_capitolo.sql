
CREATE TABLE hcbi_ras.stg_anag_capitolo (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_capitolo VARCHAR(60) NOT NULL, 
	ds_capitolo TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_capitolo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_capitolo IS 'Staging del flusso ANAG_CAPITOLO';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_capitolo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_capitolo TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_anag_capitolo.ds_anno IS 'Anno del capitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_capitolo.cd_versione IS 'Addendum/versione del capitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_capitolo.cd_capitolo IS 'Codice del capitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_capitolo.ds_capitolo IS 'Descrizione del capitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_capitolo.id_sorgente_provincia IS 'Identificativo sorgente della provincia letto da frontiera_anag_articolo.';
