
CREATE TABLE hcbi_ras.dwh_anag_versione (
	id_anag_versione BIGSERIAL NOT NULL, 
	ds_anno_pubblicazione INTEGER NOT NULL, 
	cd_versione SMALLINT NOT NULL, 
	ds_versione TEXT, 
	fl_scostamento_1_visibile SMALLINT NOT NULL, 
	fl_scostamento_2_visibile SMALLINT NOT NULL, 
	fl_scostamento_3_visibile SMALLINT NOT NULL, 
	fl_scostamento_4_visibile SMALLINT NOT NULL, 
	fl_scostamento_5_visibile SMALLINT NOT NULL, 
	nr_spese_generali NUMERIC(10, 5) NOT NULL, 
	nr_utile_impresa NUMERIC(10, 5) NOT NULL, 
	nr_di_cui_analisi NUMERIC(10, 5) NOT NULL, 
	ds_llpp_homepage_title TEXT, 
	ds_llpp_homepage_description TEXT, 
	fl_pubblicazione_regionale SMALLINT NOT NULL, 
	id_sorgente_versione BIGINT NOT NULL, 
	fl_mostra_annotazioni SMALLINT NOT NULL, 
	fl_mostra_struttura_analisi SMALLINT NOT NULL, 
	fl_is_errata_corrige SMALLINT NOT NULL, 
	fl_mostra_cam SMALLINT NOT NULL, 
	dt_creation TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_creation_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_update TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_update_by VARCHAR(4000) DEFAULT CURRENT_USER NOT NULL, 
	dt_reciclo TIMESTAMP WITHOUT TIME ZONE, 
	id_sorgente_provincia NUMERIC(10, 0) DEFAULT 0 NOT NULL, 
	CONSTRAINT pk_dwh_anag_versione PRIMARY KEY (id_anag_versione), 
	CONSTRAINT uq_dwh_anag_versione UNIQUE NULLS NOT DISTINCT (ds_anno_pubblicazione, cd_versione, id_sorgente_provincia)
);

ALTER TABLE hcbi_ras.dwh_anag_versione OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dwh_anag_versione IS 'DWH del flusso ANAG_VERSIONE';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dwh_anag_versione TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.dwh_anag_versione TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_1_visibile IS 'Indicatore scostamento 1: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_2_visibile IS 'Indicatore scostamento 2: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_3_visibile IS 'Indicatore scostamento 3: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_4_visibile IS 'Indicatore scostamento 4: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_5_visibile IS 'Indicatore scostamento 5: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_pubblicazione_regionale IS 'Indicatore pubblicazione regionale: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_is_errata_corrige IS 'Indicatore errata corrige: 0 falso, 1 vero';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.id_sorgente_provincia IS 'Identificativo sorgente della provincia e componente della business key.';
COMMENT ON CONSTRAINT uq_dwh_anag_versione ON hcbi_ras.dwh_anag_versione IS 'Business key: ds_anno_pubblicazione, cd_versione, id_sorgente_provincia.';
