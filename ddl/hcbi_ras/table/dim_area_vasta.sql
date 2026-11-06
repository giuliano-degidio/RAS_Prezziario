
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

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_anag_area_vasta IS 'Chiave primaria globale della dimensione, mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.anno IS 'Anno del contesto applicativo usato nelle lookup contestualizzate.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.cd_versione IS 'Cd_versione del contesto applicativo usato nelle lookup contestualizzate.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_sorgente_area_vasta IS 'Identificativo dell''area vasta nel sistema sorgente, univoco nel contesto anno/cd_versione.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.ds_nome IS 'Nome dell''area vasta; business key contestualizzata con anno e cd_versione.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.dt_creation IS 'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.tx_creation_by IS 'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.dt_update IS 'Timestamp dell''ultimo aggiornamento del record.';
COMMENT ON COLUMN hcbi_ras.dim_area_vasta.tx_update_by IS 'Processo che ha eseguito l''ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_area_vasta ON hcbi_ras.dim_area_vasta IS 'Chiave primaria tecnica della dimensione: id_anag_area_vasta.';
COMMENT ON CONSTRAINT uq_dim_area_vasta ON hcbi_ras.dim_area_vasta IS 'Business key contestualizzata della dimensione: anno, cd_versione, ds_nome.';
COMMENT ON CONSTRAINT uq_dim_area_vasta_sorgente ON hcbi_ras.dim_area_vasta IS 'Chiave di lookup contestualizzata: anno, cd_versione, id_sorgente_area_vasta.';
