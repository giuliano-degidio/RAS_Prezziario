
CREATE TABLE hcbi_ras.dwh_prezzi_rilevati (
	id_prezzi_rilevati BIGSERIAL NOT NULL, 
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	id_sorgente_informatore INTEGER NOT NULL, 
	id_sorgente_rilevatore INTEGER NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	dt_inserimento TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	fl_nascosto SMALLINT NOT NULL, 
	ds_anno_ribaltamento INTEGER, 
	cd_versione SMALLINT NOT NULL, 
	cd_versione_ribaltamento INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_prezzi_rilevati PRIMARY KEY (id_prezzi_rilevati), 
	CONSTRAINT uk_dwh_prezzi_rilevati UNIQUE NULLS DISTINCT (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione, id_sorgente_informatore), 
	CONSTRAINT ck_dwh_prezzi_rilevati_nascosto CHECK (fl_nascosto = ANY (ARRAY[0, 1]))
);

CREATE INDEX ix_dwh_prezzi_rilevati_articolo ON hcbi_ras.dwh_prezzi_rilevati (cd_articolo, ds_anno, cd_versione);
