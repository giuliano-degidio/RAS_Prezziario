
CREATE TABLE hcbi_ras.dwh_firenze_analisi_rej (
	id_dwh_firenze_analisi_rej BIGSERIAL NOT NULL, 
	nr_anno INTEGER, 
	ds_regione VARCHAR(50), 
	ds_provincia VARCHAR(50), 
	nr_riga_file BIGINT, 
	analisi TEXT, 
	descrizione TEXT, 
	cam TEXT, 
	codice_dettaglio TEXT, 
	cam_codice_dettaglio TEXT, 
	voce_articolo TEXT, 
	codice_collegato TEXT, 
	unita_misura TEXT, 
	quantita TEXT, 
	prezzo_unitario TEXT, 
	importo TEXT, 
	cd_analisi_propagato TEXT, 
	ds_analisi_propagata TEXT, 
	fl_cam_propagato TEXT, 
	cd_dettaglio_normalizzato TEXT, 
	cd_unita_misura_normalizzata TEXT, 
	nr_quantita_convertita NUMERIC(24, 6), 
	nr_prezzo_unitario_convertito NUMERIC(24, 6), 
	nr_importo_convertito NUMERIC(24, 6), 
	cd_tipo_riga VARCHAR(30) DEFAULT 'COMPONENT'::character varying NOT NULL, 
	cd_esito VARCHAR(30) DEFAULT 'REJECT'::character varying NOT NULL, 
	cd_motivo_scarto VARCHAR(100) NOT NULL, 
	tx_motivo_scarto VARCHAR(4000) NOT NULL, 
	tx_nome_file VARCHAR(255), 
	dt_caricamento TIMESTAMP WITHOUT TIME ZONE, 
	tx_caricamento_by VARCHAR(100), 
	id_chain_log BIGINT, 
	id_chain BIGINT, 
	id_step BIGINT, 
	ds_step_name VARCHAR(4000), 
	dt_scarto TIMESTAMP WITHOUT TIME ZONE DEFAULT clock_timestamp() NOT NULL, 
	tx_scarto_by VARCHAR(100) DEFAULT CURRENT_USER NOT NULL, 
	CONSTRAINT pk_dwh_firenze_analisi_rej PRIMARY KEY (id_dwh_firenze_analisi_rej), 
	CONSTRAINT ck_dwh_firenze_analisi_rej_descrizione CHECK (NULLIF(btrim(tx_motivo_scarto::text), ''::text) IS NOT NULL), 
	CONSTRAINT ck_dwh_firenze_analisi_rej_esito CHECK (cd_esito::text = 'REJECT'::text), 
	CONSTRAINT ck_dwh_firenze_analisi_rej_motivo CHECK (NULLIF(btrim(cd_motivo_scarto::text), ''::text) IS NOT NULL), 
	CONSTRAINT ck_dwh_firenze_analisi_rej_tipo CHECK (cd_tipo_riga::text = ANY (ARRAY['COMPONENT'::character varying::text, 'UNKNOWN'::character varying::text]))
);

CREATE INDEX ix_dwh_firenze_analisi_rej_file_riga ON hcbi_ras.dwh_firenze_analisi_rej (tx_nome_file, nr_anno, nr_riga_file);

CREATE INDEX ix_dwh_firenze_analisi_rej_motivo ON hcbi_ras.dwh_firenze_analisi_rej (cd_motivo_scarto, nr_anno);

CREATE UNIQUE INDEX uq_dwh_firenze_analisi_rej_run ON hcbi_ras.dwh_firenze_analisi_rej (id_chain_log, id_step, nr_anno, nr_riga_file, cd_motivo_scarto) NULLS NOT DISTINCT WHERE ((id_chain_log IS NOT NULL) AND (id_step IS NOT NULL));
