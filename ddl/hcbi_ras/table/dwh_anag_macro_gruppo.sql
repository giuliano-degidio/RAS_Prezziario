
CREATE TABLE hcbi_ras.dwh_anag_macro_gruppo (
	id_anag_macro_gruppo BIGSERIAL NOT NULL, 
	id_sorgente_macro_gruppo BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50), 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_anag_macro_gruppo PRIMARY KEY (id_anag_macro_gruppo), 
	CONSTRAINT uq_dwh_anag_macro_gruppo UNIQUE NULLS NOT DISTINCT (ds_nome), 
	CONSTRAINT uq_dwh_anag_macro_gruppo_sorgente UNIQUE NULLS NOT DISTINCT (id_sorgente_macro_gruppo)
);
