
CREATE TABLE hcbi_ras.stg_articoli_informatori (
	id_sorgente_informatore INTEGER NOT NULL, 
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	fl_escluso SMALLINT NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_articoli_informatori BIGINT NOT NULL, 
	id_sorgente_utente INTEGER, 
	CONSTRAINT ck_stg_articoli_informatori_escluso CHECK (fl_escluso = ANY (ARRAY[0, 1]))
);
