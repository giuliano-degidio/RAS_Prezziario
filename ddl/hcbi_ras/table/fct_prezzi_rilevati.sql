
CREATE TABLE hcbi_ras.fct_prezzi_rilevati (
	id_prezzi_rilevati BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	id_anag_articolo BIGINT NOT NULL, 
	id_anag_informatore BIGINT NOT NULL, 
	id_anag_utente_rilevatore BIGINT NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	dt_inserimento TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	fl_nascosto SMALLINT NOT NULL, 
	ds_anno_ribaltamento INTEGER, 
	cd_versione_ribaltamento INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_fct_prezzi_rilevati PRIMARY KEY (id_prezzi_rilevati), 
	CONSTRAINT fk_fct_prezzi_rilevati_articolo FOREIGN KEY(id_anag_articolo) REFERENCES hcbi_ras.dim_articolo (id_anag_articolo), 
	CONSTRAINT fk_fct_prezzi_rilevati_informatore FOREIGN KEY(id_anag_informatore) REFERENCES hcbi_ras.dim_informatori (id_anag_informatore), 
	CONSTRAINT fk_fct_prezzi_rilevati_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo), 
	CONSTRAINT fk_fct_prezzi_rilevati_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia), 
	CONSTRAINT fk_fct_prezzi_rilevati_rilevatore FOREIGN KEY(id_anag_utente_rilevatore) REFERENCES hcbi_ras.dim_utenti (id_anag_utente), 
	CONSTRAINT fk_fct_prezzi_rilevati_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione), 
	CONSTRAINT ck_fct_prezzi_rilevati_nascosto CHECK (fl_nascosto = ANY (ARRAY[0, 1]))
);

CREATE INDEX ix_fct_prezzi_rilevati_articolo ON hcbi_ras.fct_prezzi_rilevati (id_anag_articolo);

CREATE INDEX ix_fct_prezzi_rilevati_informatore ON hcbi_ras.fct_prezzi_rilevati (id_anag_informatore);

CREATE INDEX ix_fct_prezzi_rilevati_periodo ON hcbi_ras.fct_prezzi_rilevati (id_periodo_pubblicazione);

CREATE INDEX ix_fct_prezzi_rilevati_provincia ON hcbi_ras.fct_prezzi_rilevati (id_anag_provincia);

CREATE INDEX ix_fct_prezzi_rilevati_rilevatore ON hcbi_ras.fct_prezzi_rilevati (id_anag_utente_rilevatore);

CREATE INDEX ix_fct_prezzi_rilevati_versione ON hcbi_ras.fct_prezzi_rilevati (id_anag_versione);
