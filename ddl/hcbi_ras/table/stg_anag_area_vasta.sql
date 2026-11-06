
CREATE TABLE hcbi_ras.stg_anag_area_vasta (
	id_sorgente_area_vasta BIGINT NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_area_vasta OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_area_vasta IS 'Staging del flusso ANAG_AREA_VASTA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_area_vasta TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_area_vasta TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_anag_area_vasta.id_sorgente_area_vasta IS 'Identificativo sorgente facoltativo; se valorizzato deve essere convertibile in BIGINT.';
COMMENT ON COLUMN hcbi_ras.stg_anag_area_vasta.ds_nome IS 'Nome dell''area vasta e business key del flusso.';
