
CREATE TABLE hcbi_ras.stg_anag_provincia (
	id_sorgente_provincia BIGINT, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_provincia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_provincia IS 'Staging del flusso ANAG_PROVINCIA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_provincia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_provincia TO hcbi_utility;
