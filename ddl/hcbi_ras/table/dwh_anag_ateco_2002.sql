
CREATE TABLE hcbi_ras.dwh_anag_ateco_2002 (
	id_anag_ateco_2002 BIGSERIAL NOT NULL, 
	cd_ateco_2002 VARCHAR(200) NOT NULL, 
	ds_ateco_2002 VARCHAR(512) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_ateco_2002 PRIMARY KEY (id_anag_ateco_2002), 
	CONSTRAINT uq_dwh_anag_ateco_2002 UNIQUE NULLS NOT DISTINCT (cd_ateco_2002)
);

ALTER TABLE hcbi_ras.dwh_anag_ateco_2002 OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dwh_anag_ateco_2002 IS 'DWH del flusso ANAG_ATECO_2002.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dwh_anag_ateco_2002 TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dwh_anag_ateco_2002 TO hcbi_utility;

COMMENT ON CONSTRAINT uq_dwh_anag_ateco_2002 ON hcbi_ras.dwh_anag_ateco_2002 IS 'Business key del flusso ANAG_ATECO_2002: cd_ateco_2002.';
