
CREATE TABLE hcbi_ras.dim_provincia (
	id_anag_provincia BIGINT NOT NULL, 
	cd_provincia VARCHAR(2) NOT NULL, 
	ds_nome VARCHAR(100) NOT NULL, 
	id_area_vasta BIGINT NOT NULL, 
	fl_provincia_principale_regionale SMALLINT NOT NULL, 
	fl_provincia_principale_area_vasta SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dim_provincia PRIMARY KEY (id_anag_provincia), 
	CONSTRAINT fk_dim_provincia_area_vasta FOREIGN KEY(id_area_vasta) REFERENCES hcbi_ras.dim_area_vasta (id_anag_area_vasta) ON DELETE RESTRICT ON UPDATE RESTRICT, 
	CONSTRAINT uq_dim_provincia UNIQUE NULLS NOT DISTINCT (cd_provincia)
);

ALTER TABLE hcbi_ras.dim_provincia OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_provincia IS 'Dimensione delle province alimentata da HCBI_RAS.DWH_ANAG_PROVINCIA.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_provincia TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_provincia TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dim_provincia.id_anag_provincia IS 'Chiave primaria globale della dimensione, mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.anno IS 'Anno del contesto applicativo usato per le lookup contestualizzate.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.cd_versione IS 'Cd_versione del contesto applicativo usato per le lookup contestualizzate.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.cd_provincia IS 'Codice della provincia; business key contestualizzata con anno e cd_versione.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.ds_nome IS 'Descrizione della provincia.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.id_area_vasta IS 'Chiave esterna verso DIM_AREA_VASTA: 0 con riferimento sorgente NULL; -1 con riferimento valorizzato ma non risolto; altrimenti chiave della DIM_AREA_VASTA.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.fl_provincia_principale_regionale IS 'Indicatore di provincia principale regionale.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.fl_provincia_principale_area_vasta IS 'Indicatore di provincia principale per area vasta.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.dt_creation IS 'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.tx_creation_by IS 'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.dt_update IS 'Timestamp dell''ultimo aggiornamento del record.';
COMMENT ON COLUMN hcbi_ras.dim_provincia.tx_update_by IS 'Processo che ha eseguito l''ultimo aggiornamento.';
COMMENT ON CONSTRAINT fk_dim_provincia_area_vasta ON hcbi_ras.dim_provincia IS 'Relazione tra DIM_PROVINCIA e DIM_AREA_VASTA tramite id_area_vasta.';
COMMENT ON CONSTRAINT pk_dim_provincia ON hcbi_ras.dim_provincia IS 'Chiave primaria della dimensione: id_anag_provincia.';
COMMENT ON CONSTRAINT uq_dim_provincia ON hcbi_ras.dim_provincia IS 'Business key contestualizzata della dimensione: anno, cd_versione, cd_provincia.';
