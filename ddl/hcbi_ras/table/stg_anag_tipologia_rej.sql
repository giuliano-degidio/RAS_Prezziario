
CREATE TABLE hcbi_ras.stg_anag_tipologia_rej (
	ds_anno VARCHAR(100), 
	cd_versione VARCHAR(20), 
	cd_tipologia VARCHAR(60), 
	ds_tipologia TEXT, 
	id_sorgente_provincia VARCHAR(100), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_tipologia_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_tipologia_rej IS 'Record scartati del flusso ANAG_TIPOLOGIA';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_tipologia_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_tipologia_rej TO hcbi_utility;
