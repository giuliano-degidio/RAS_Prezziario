
CREATE TABLE hcbi_ras.fct_prezzi_approvati (
	id_prezzi_approvati BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	id_anag_articolo BIGINT NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	dt_approvazione TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_fct_prezzi_approvati PRIMARY KEY (id_prezzi_approvati), 
	CONSTRAINT fk_fct_prezzi_approvati_articolo FOREIGN KEY(id_anag_articolo) REFERENCES hcbi_ras.dim_articolo (id_anag_articolo), 
	CONSTRAINT fk_fct_prezzi_approvati_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo), 
	CONSTRAINT fk_fct_prezzi_approvati_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia), 
	CONSTRAINT fk_fct_prezzi_approvati_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione)
);

CREATE INDEX ix_fct_prezzi_approvati_articolo ON hcbi_ras.fct_prezzi_approvati (id_anag_articolo);

CREATE INDEX ix_fct_prezzi_approvati_periodo ON hcbi_ras.fct_prezzi_approvati (id_periodo_pubblicazione);

CREATE INDEX ix_fct_prezzi_approvati_provincia ON hcbi_ras.fct_prezzi_approvati (id_anag_provincia);

CREATE INDEX ix_fct_prezzi_approvati_versione ON hcbi_ras.fct_prezzi_approvati (id_anag_versione);
