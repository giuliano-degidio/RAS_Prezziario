
CREATE TABLE hcbi_ras.dim_ateco_2002 (
	id_anag_ateco_2002 BIGINT NOT NULL, 
	cd_ateco_2002 VARCHAR(200) NOT NULL, 
	ds_ateco_2002 VARCHAR(512) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_ateco_2002 PRIMARY KEY (id_anag_ateco_2002), 
	CONSTRAINT uq_dim_ateco_2002 UNIQUE NULLS NOT DISTINCT (cd_ateco_2002)
);

ALTER TABLE hcbi_ras.dim_ateco_2002 OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_ateco_2002 IS 'Dimensione dei codici ATECO 2002 alimentata da HCBI_RAS.DWH_ANAG_ATECO_2002.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_ateco_2002 TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_ateco_2002 TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.id_anag_ateco_2002 IS 'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.cd_ateco_2002 IS 'Codice ATECO 2002 e business key della dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.ds_ateco_2002 IS 'Descrizione ufficiale del codice ATECO 2002.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.dt_creation IS 'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.tx_creation_by IS 'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.dt_update IS 'Timestamp dell ultimo aggiornamento del record.';
COMMENT ON COLUMN hcbi_ras.dim_ateco_2002.tx_update_by IS 'Processo che ha eseguito l ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_ateco_2002 ON hcbi_ras.dim_ateco_2002 IS 'Chiave primaria tecnica: id_anag_ateco_2002.';
COMMENT ON CONSTRAINT uq_dim_ateco_2002 ON hcbi_ras.dim_ateco_2002 IS 'Business key della dimensione: cd_ateco_2002.';
