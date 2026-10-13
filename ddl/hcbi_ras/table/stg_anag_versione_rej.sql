
CREATE TABLE hcbi_ras.stg_anag_versione_rej (
	ds_anno_pubblicazione VARCHAR(100), 
	cd_versione VARCHAR(20), 
	ds_versione TEXT, 
	fl_scostamento_1_visibile VARCHAR(20), 
	fl_scostamento_2_visibile VARCHAR(20), 
	fl_scostamento_3_visibile VARCHAR(20), 
	fl_scostamento_4_visibile VARCHAR(20), 
	fl_scostamento_5_visibile VARCHAR(20), 
	nr_spese_generali VARCHAR(100), 
	nr_utile_impresa VARCHAR(100), 
	nr_di_cui_analisi VARCHAR(100), 
	ds_llpp_homepage_title TEXT, 
	ds_llpp_homepage_description TEXT, 
	fl_pubblicazione_regionale VARCHAR(20), 
	id_sorgente_versione VARCHAR(100), 
	fl_mostra_annotazioni VARCHAR(20), 
	fl_mostra_struttura_analisi VARCHAR(20), 
	fl_is_errata_corrige VARCHAR(20), 
	fl_mostra_cam VARCHAR(20), 
	tx_motivo_scarto VARCHAR(4000), 
	id_sorgente_provincia VARCHAR(20)
);
