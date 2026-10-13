
CREATE TABLE hcbi_ras.stg_anag_versione (
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
	id_sorgente_provincia NUMERIC(10, 0) DEFAULT 0
);
