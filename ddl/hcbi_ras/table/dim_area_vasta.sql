
CREATE TABLE hcbi_ras.dim_area_vasta (
	id_anag_area_vasta BIGINT NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	ds_nome VARCHAR(100) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_area_vasta PRIMARY KEY (id_anag_area_vasta), 
	CONSTRAINT uq_dim_area_vasta UNIQUE NULLS NOT DISTINCT (ds_nome)
);

ALTER TABLE hcbi_ras.dim_area_vasta OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_area_vasta IS 'Dimensione delle aree vaste alimentata da HCBI_RAS.DWH_ANAG_AREA_VASTA.';
CREATE UNIQUE INDEX uq_dim_area_vasta_sorgente ON hcbi_ras.dim_area_vasta USING btree (anno, cd_versione, id_sorgente_area_vasta) NULLS NOT DISTINCT;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_area_vasta TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_area_vasta TO hcbi_utility;
