
CREATE TABLE hcbi_ras.stg_anag_ateco_2002_rej (
	cd_ateco_2002 VARCHAR(200), 
	ds_ateco_2002 VARCHAR(512), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_ateco_2002_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_ateco_2002_rej IS 'Record scartati del flusso ANAG_ATECO_2002.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_ateco_2002_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_ateco_2002_rej TO hcbi_utility;
