
CREATE TABLE hcbi_ras.dwh_articoli_informatori (
	id_articoli_informatori BIGSERIAL NOT NULL, 
	id_sorgente_articoli_informatori BIGINT NOT NULL, 
	id_sorgente_informatore INTEGER NOT NULL, 
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	fl_escluso SMALLINT NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_utente INTEGER, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	CONSTRAINT pk_dwh_articoli_informatori PRIMARY KEY (id_articoli_informatori), 
	CONSTRAINT uk_dwh_articoli_informatori UNIQUE NULLS DISTINCT (id_sorgente_informatore, cd_articolo, ds_anno, id_sorgente_provincia, cd_versione), 
	CONSTRAINT ck_dwh_articoli_informatori_escluso CHECK (fl_escluso = ANY (ARRAY[0, 1]))
);

CREATE INDEX ix_dwh_articoli_informatori_articolo ON hcbi_ras.dwh_articoli_informatori (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione);

CREATE INDEX ix_dwh_articoli_informatori_informatore ON hcbi_ras.dwh_articoli_informatori (id_sorgente_informatore, ds_anno, id_sorgente_provincia, cd_versione);

CREATE UNIQUE INDEX ux_dwh_articoli_informatori_id_sorgente ON hcbi_ras.dwh_articoli_informatori (id_sorgente_articoli_informatori);
