
CREATE TABLE hcbi_ras.dim_macro_gruppo (
	id_anag_macro_gruppo BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50), 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_macro_gruppo PRIMARY KEY (id_anag_macro_gruppo), 
	CONSTRAINT uq_dim_macro_gruppo UNIQUE NULLS NOT DISTINCT (ds_nome)
);

ALTER TABLE hcbi_ras.dim_macro_gruppo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_macro_gruppo IS 'Dimensione dei macro-gruppi alimentata da HCBI_RAS.DWH_ANAG_MACRO_GRUPPO.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_macro_gruppo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_macro_gruppo TO hcbi_utility;
