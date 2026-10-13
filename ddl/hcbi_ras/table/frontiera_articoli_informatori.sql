
CREATE TABLE hcbi_ras.frontiera_articoli_informatori (
	id_informatore VARCHAR(100), 
	codice_articolo VARCHAR(60), 
	anno VARCHAR(100), 
	provincia VARCHAR(100) DEFAULT 0, 
	escluso VARCHAR(20), 
	addendum VARCHAR(20), 
	id VARCHAR(100), 
	user_id VARCHAR(100)
);
