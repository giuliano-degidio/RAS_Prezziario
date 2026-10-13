
CREATE TABLE hcbi_ras.stg_anag_sottocapitolo (
	ds_anno INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	cd_sottocapitolo VARCHAR(60) NOT NULL, 
	ds_sottocapitolo TEXT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL
);
