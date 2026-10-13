
CREATE TABLE hcbi_ras.stg_anag_tipologia (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_tipologia VARCHAR(60) NOT NULL, 
	ds_tipologia TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);
