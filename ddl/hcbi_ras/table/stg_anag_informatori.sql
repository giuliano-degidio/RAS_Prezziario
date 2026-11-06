
CREATE TABLE hcbi_ras.stg_anag_informatori (
	id_sorgente_informatore INTEGER NOT NULL, 
	ds_ragione_sociale VARCHAR(100) NOT NULL, 
	cd_p_iva VARCHAR(100), 
	cd_codice_ateco_2002 VARCHAR(100), 
	ds_indirizzo_sede_legale VARCHAR(100), 
	cd_cap_sede_legale VARCHAR(10), 
	ds_citta_sede_legale VARCHAR(100), 
	cd_provincia_sede_legale VARCHAR(100), 
	ds_indirizzo_sede_operativa VARCHAR(100), 
	cd_cap_sede_operativa VARCHAR(10), 
	ds_citta_sede_operativa VARCHAR(100), 
	cd_provincia_sede_operativa VARCHAR(100), 
	ds_contatti TEXT, 
	cd_stato INTEGER, 
	ds_note TEXT, 
	ds_stato_attivita VARCHAR(100), 
	cd_codice_fiscale VARCHAR(100), 
	ds_anno_pubblicazione INTEGER NOT NULL, 
	dt_last_update TIMESTAMP WITHOUT TIME ZONE, 
	ds_nazione VARCHAR(40), 
	cd_versione SMALLINT NOT NULL, 
	id_sorgente_provincia BIGINT NOT NULL, 
	fl_escludi_invio_mail_assoc_listino_completa INTEGER
);

ALTER TABLE hcbi_ras.stg_anag_informatori OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.stg_anag_informatori IS 'Staging del flusso ANAG_INFORMATORI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.stg_anag_informatori TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.stg_anag_informatori TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.stg_anag_informatori.id_sorgente_provincia IS 'Identificativo sorgente della provincia, derivato dal campo provincia della frontiera.';
