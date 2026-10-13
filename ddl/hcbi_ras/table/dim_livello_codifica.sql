
CREATE TABLE hcbi_ras.dim_livello_codifica (
	id_anag_livello_codifica BIGINT NOT NULL, 
	ds_nome VARCHAR(50) NOT NULL, 
	ds_plurale VARCHAR(50) NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_livello_codifica PRIMARY KEY (id_anag_livello_codifica), 
	CONSTRAINT uq_dim_livello_codifica UNIQUE NULLS NOT DISTINCT (ds_nome)
);
