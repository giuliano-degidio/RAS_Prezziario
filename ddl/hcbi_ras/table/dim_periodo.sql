
CREATE TABLE hcbi_ras.dim_periodo (
	id_periodo SERIAL NOT NULL, 
	ds_periodo VARCHAR(500) NOT NULL, 
	cd_modalita_temporale VARCHAR(50) NOT NULL, 
	ds_modalita_temporale VARCHAR(500) NOT NULL, 
	ds_tipo_periodo VARCHAR(500) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE, 
	tx_creation_by VARCHAR(4000), 
	dt_update TIMESTAMP(6) WITHOUT TIME ZONE, 
	tx_update_by VARCHAR, 
	CONSTRAINT pk_dim_periodo PRIMARY KEY (id_periodo), 
	CONSTRAINT uk_dim_periodo UNIQUE NULLS DISTINCT (ds_anno)
);
COMMENT ON TABLE hcbi_ras.dim_periodo
    IS 'Dimensione dei periodi temporali utilizzati nel modello DWH.Tabella statica';

ALTER TABLE hcbi_ras.dim_periodo OWNER TO hcbi_ras;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_periodo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dim_periodo TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dim_periodo.id_periodo IS 'Identificativo univoco del periodo temporale.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.ds_periodo IS 'Descrizione del periodo temporale.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.cd_modalita_temporale IS 'Codice della modalità temporale associata al periodo.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.ds_modalita_temporale IS 'Descrizione della modalità temporale associata al periodo.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.ds_tipo_periodo IS 'Descrizione della tipologia di periodo.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.ds_anno IS 'Anno di riferimento del periodo.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.dt_creation IS 'Data e ora di creazione del record.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.tx_creation_by IS 'Utente, processo o procedura che ha creato il record.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.dt_update IS 'Data e ora dell''ultima modifica del record.';
COMMENT ON COLUMN hcbi_ras.dim_periodo.tx_update_by IS 'Utente, processo o procedura che ha effettuato l''ultima modifica del record.';
