
CREATE TABLE hcbi_ras.dwh_anag_provincia (
	id_anag_provincia BIGSERIAL NOT NULL, 
	id_sorgente_provincia BIGINT, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_provincia PRIMARY KEY (id_anag_provincia), 
	CONSTRAINT uq_dwh_anag_provincia UNIQUE NULLS NOT DISTINCT (cd_provincia)
);

ALTER TABLE hcbi_ras.dwh_anag_provincia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dwh_anag_provincia IS 'DWH del flusso ANAG_PROVINCIA';
CREATE UNIQUE INDEX uq_dwh_anag_provincia_sorgente ON hcbi_ras.dwh_anag_provincia USING btree (anno, cd_versione, id_sorgente_provincia) NULLS NOT DISTINCT;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dwh_anag_provincia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dwh_anag_provincia TO hcbi_utility;
