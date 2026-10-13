
CREATE TABLE hcbi_ras.stg_prezzi_approvati (
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	dt_approvazione TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	cd_versione SMALLINT NOT NULL
);
