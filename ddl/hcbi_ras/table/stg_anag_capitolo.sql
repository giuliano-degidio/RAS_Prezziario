
CREATE TABLE hcbi_ras.stg_anag_capitolo (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_capitolo VARCHAR(60) NOT NULL, 
	ds_capitolo TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);
