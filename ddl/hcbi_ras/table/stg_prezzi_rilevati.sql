
CREATE TABLE hcbi_ras.stg_prezzi_rilevati (
	cd_articolo VARCHAR(60) NOT NULL, 
	ds_anno INTEGER NOT NULL, 
	id_sorgente_provincia INTEGER NOT NULL, 
	id_sorgente_informatore INTEGER NOT NULL, 
	id_sorgente_rilevatore INTEGER NOT NULL, 
	nr_prezzo NUMERIC(24, 5) NOT NULL, 
	dt_inserimento TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	fl_nascosto SMALLINT NOT NULL, 
	ds_anno_ribaltamento INTEGER, 
	cd_versione SMALLINT NOT NULL, 
	cd_versione_ribaltamento INTEGER, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	CONSTRAINT ck_stg_prezzi_rilevati_nascosto CHECK (fl_nascosto = ANY (ARRAY[0, 1]))
);

ALTER TABLE hcbi_ras.stg_prezzi_rilevati OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_prezzi_rilevati IS 'Staging valida del flusso PREZZI_RILEVATI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_prezzi_rilevati TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_prezzi_rilevati TO hcbi_utility;
