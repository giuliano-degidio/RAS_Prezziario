
CREATE TABLE hcbi_ras.wrk_firenze_analisi_csv (
	id_import BIGINT GENERATED ALWAYS AS IDENTITY (INCREMENT BY 1 START WITH 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 NO CYCLE), 
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
	CONSTRAINT pk_wrk_firenze_analisi_csv PRIMARY KEY (id_import)
);
