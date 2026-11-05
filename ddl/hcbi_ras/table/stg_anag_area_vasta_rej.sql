
CREATE TABLE hcbi_ras.stg_anag_area_vasta_rej (
	id_sorgente_area_vasta VARCHAR(100), 
	ds_nome VARCHAR(100), 
	tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_area_vasta_rej OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_area_vasta_rej IS 'Record scartati del flusso ANAG_AREA_VASTA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_area_vasta_rej TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_area_vasta_rej TO hcbi_utility;
