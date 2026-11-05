
CREATE TABLE hcbi_ras.stg_anag_provincia_rej (
	id_sorgente_provincia VARCHAR(100), 
	cd_provincia VARCHAR(2), 
	ds_nome VARCHAR(100), 
	id_sorgente_area_vasta VARCHAR(20), 
	fl_provincia_principale_regionale VARCHAR(20), 
	fl_provincia_principale_area_vasta VARCHAR(20), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_provincia_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_provincia_rej IS 'Record scartati del flusso ANAG_PROVINCIA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_provincia_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_provincia_rej TO hcbi_utility;
