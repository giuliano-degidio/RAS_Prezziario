
CREATE TABLE hcbi_ras.dim_tipologia (
	id_anag_tipologia BIGINT NOT NULL, 
	cd_tipologia VARCHAR(60) NOT NULL, 
	ds_tipologia TEXT NOT NULL, 
	id_anag_provincia BIGINT NOT NULL, 
	id_periodo_pubblicazione INTEGER NOT NULL, 
	id_anag_versione BIGINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_tipologia PRIMARY KEY (id_anag_tipologia), 
	CONSTRAINT fk_dim_tipologia_periodo FOREIGN KEY(id_periodo_pubblicazione) REFERENCES hcbi_ras.dim_periodo (id_periodo) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_tipologia_provincia FOREIGN KEY(id_anag_provincia) REFERENCES hcbi_ras.dim_provincia (id_anag_provincia) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT fk_dim_tipologia_versione FOREIGN KEY(id_anag_versione) REFERENCES hcbi_ras.dim_versione (id_anag_versione) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_tipologia UNIQUE NULLS NOT DISTINCT (cd_tipologia, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia)
);

ALTER TABLE hcbi_ras.dim_tipologia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_tipologia IS 'Dimensione delle tipologie alimentata da HCBI_RAS.DWH_ANAG_TIPOLOGIA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_tipologia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_tipologia TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_tipologia IS 'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.cd_tipologia IS 'Codice della tipologia normalizzato eliminando esclusivamente un eventuale punto finale.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.ds_tipologia IS 'Descrizione della tipologia.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_provincia IS 'FK verso DIM_PROVINCIA risolta in DWH_ANAG_PROVINCIA tramite anno, cd_versione di DWH_ANAG_TIPOLOGIA e id_sorgente_provincia; la DIM e quindi raggiunta tramite id_anag_provincia nel medesimo contesto anno/cd_versione; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_periodo_pubblicazione IS 'FK verso DIM_PERIODO; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_versione IS 'FK verso DIM_VERSIONE; -1 se la lookup composta periodo-versione-provincia non e risolta.';
COMMENT ON CONSTRAINT fk_dim_tipologia_periodo ON hcbi_ras.dim_tipologia IS 'Relazione verso DIM_PERIODO.';
COMMENT ON CONSTRAINT fk_dim_tipologia_provincia ON hcbi_ras.dim_tipologia IS 'Relazione verso DIM_PROVINCIA.';
COMMENT ON CONSTRAINT fk_dim_tipologia_versione ON hcbi_ras.dim_tipologia IS 'Relazione verso DIM_VERSIONE.';
COMMENT ON CONSTRAINT pk_dim_tipologia ON hcbi_ras.dim_tipologia IS 'Chiave primaria: id_anag_tipologia.';
COMMENT ON CONSTRAINT uq_dim_tipologia ON hcbi_ras.dim_tipologia IS 'Business key: cd_tipologia, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia.';
