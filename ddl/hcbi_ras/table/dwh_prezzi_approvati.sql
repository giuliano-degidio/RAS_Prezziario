
CREATE TABLE hcbi_ras.dwh_prezzi_approvati (
	id_prezzi_approvati BIGSERIAL NOT NULL, 
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	dt_approvazione TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_prezzi_approvati PRIMARY KEY (id_prezzi_approvati), 
	CONSTRAINT uk_dwh_prezzi_approvati UNIQUE NULLS DISTINCT (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione)
);

CREATE INDEX ix_dwh_prezzi_approvati_articolo ON hcbi_ras.dwh_prezzi_approvati (cd_articolo, ds_anno, cd_versione);
