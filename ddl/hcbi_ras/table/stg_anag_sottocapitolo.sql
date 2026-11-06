
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

COMMENT ON COLUMN hcbi_ras.stg_anag_sottocapitolo.ds_anno IS 'Anno del sottocapitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_sottocapitolo.cd_versione IS 'Addendum/versione del sottocapitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_sottocapitolo.cd_sottocapitolo IS 'Codice del sottocapitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_sottocapitolo.ds_sottocapitolo IS 'Descrizione del sottocapitolo.';
COMMENT ON COLUMN hcbi_ras.stg_anag_sottocapitolo.id_sorgente_provincia IS 'Identificativo sorgente della provincia letto da frontiera_anag_articolo.';
