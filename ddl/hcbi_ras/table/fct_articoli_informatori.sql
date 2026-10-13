
CREATE TABLE hcbi_ras.fct_articoli_informatori (
	id_articoli_informatori BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	id_anag_articolo BIGINT NOT NULL, 
	id_anag_informatore BIGINT NOT NULL, 
	id_anag_utente BIGINT NOT NULL, 
	fl_escluso SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_fct_articoli_informatori PRIMARY KEY (id_articoli_informatori), 
	CONSTRAINT fk_fct_articoli_informatori_articolo FOREIGN KEY(id_anag_articolo) REFERENCES hcbi_ras.dim_articolo (id_anag_articolo), 
	CONSTRAINT fk_fct_articoli_informatori_informatore FOREIGN KEY(id_anag_informatore) REFERENCES hcbi_ras.dim_informatori (id_anag_informatore), 
	CONSTRAINT fk_fct_articoli_informatori_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo), 
	CONSTRAINT fk_fct_articoli_informatori_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia), 
	CONSTRAINT fk_fct_articoli_informatori_utente FOREIGN KEY(id_anag_utente) REFERENCES hcbi_ras.dim_utenti (id_anag_utente), 
	CONSTRAINT fk_fct_articoli_informatori_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione), 
	CONSTRAINT ck_fct_articoli_informatori_escluso CHECK (fl_escluso = ANY (ARRAY[0, 1]))
);

CREATE INDEX ix_fct_articoli_informatori_articolo ON hcbi_ras.fct_articoli_informatori (id_anag_articolo);

CREATE INDEX ix_fct_articoli_informatori_informatore ON hcbi_ras.fct_articoli_informatori (id_anag_informatore);

CREATE INDEX ix_fct_articoli_informatori_periodo ON hcbi_ras.fct_articoli_informatori (id_periodo_pubblicazione);

CREATE INDEX ix_fct_articoli_informatori_provincia ON hcbi_ras.fct_articoli_informatori (id_anag_provincia);

CREATE INDEX ix_fct_articoli_informatori_utente ON hcbi_ras.fct_articoli_informatori (id_anag_utente);

CREATE INDEX ix_fct_articoli_informatori_versione ON hcbi_ras.fct_articoli_informatori (id_anag_versione);
