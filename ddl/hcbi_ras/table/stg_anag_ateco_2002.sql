
CREATE TABLE hcbi_ras.stg_anag_ateco_2002 (
	cd_ateco_2002 VARCHAR(200) NOT NULL, 
	ds_ateco_2002 VARCHAR(512) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_ateco_2002 OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_ateco_2002 IS 'Staging del flusso ANAG_ATECO_2002.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_ateco_2002 TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_ateco_2002 TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_anag_ateco_2002.cd_ateco_2002 IS 'Codice ATECO 2002 e business key del flusso.';
COMMENT ON COLUMN hcbi_ras.stg_anag_ateco_2002.ds_ateco_2002 IS 'Nome dell''area vasta e business key del flusso.';
