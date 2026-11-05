
CREATE TABLE hcbi_ras.dwh_anag_livello_codifica (
	id_anag_livello_codifica BIGSERIAL NOT NULL, 
	id_sorgente_livello_codifica BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_livello_codifica PRIMARY KEY (id_anag_livello_codifica), 
	CONSTRAINT uq_dwh_anag_livello_codifica UNIQUE NULLS NOT DISTINCT (ds_nome), 
	CONSTRAINT uq_dwh_anag_livello_codifica_sorgente UNIQUE NULLS NOT DISTINCT (id_sorgente_livello_codifica)
);

ALTER TABLE hcbi_ras.dwh_anag_livello_codifica OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dwh_anag_livello_codifica IS 'DWH del flusso ANAG_LIVELLO_CODIFICA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dwh_anag_livello_codifica TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dwh_anag_livello_codifica TO hcbi_utility;
