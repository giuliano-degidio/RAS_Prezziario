
CREATE TABLE hcbi_ras.stg_anag_provincia (
	id_sorgente_provincia BIGINT, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_sorgente_area_vasta BIGINT, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL
);
