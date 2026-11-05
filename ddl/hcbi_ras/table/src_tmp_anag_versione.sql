
CREATE TABLE hcbi_ras.src_tmp_anag_versione (
	anno VARCHAR(100), 
	addendum VARCHAR(20), 
	addendum_name TEXT, 
	scostamento_1_visibile VARCHAR(20), 
	scostamento_2_visibile VARCHAR(20), 
	scostamento_3_visibile VARCHAR(20), 
	scostamento_4_visibile VARCHAR(20), 
	spese_generali VARCHAR(100), 
	utile_impresa VARCHAR(100), 
	llpp_homepage_title TEXT, 
	llpp_homepage_description TEXT, 
	di_cui_analisi VARCHAR(100), 
	pubblicazione_regionale VARCHAR(20), 
	llpp_homepage_title_de TEXT, 
	llpp_homepage_description_de TEXT, 
	scostamento_5_visibile VARCHAR(20), 
	preferenze_esportazione TEXT, 
	id VARCHAR(100), 
	impostazioni_prezzi TEXT, 
	mostra_annotazioni VARCHAR(20), 
	mostra_struttura_analisi VARCHAR(20), 
	is_errata_corrige VARCHAR(20), 
	mostra_cam VARCHAR(20), 
	provincia VARCHAR(20) DEFAULT '0'::character varying
);

ALTER TABLE hcbi_ras.src_tmp_anag_versione OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_versione IS 'Tabella temporanea sorgente del flusso ANAG_VERSIONE';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_versione TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_versione TO hcbi_utility;
