
CREATE TABLE hcbi_ras.frontiera_prezzi_rilevati (
	codice VARCHAR(60), 
	anno VARCHAR(100), 
	provincia VARCHAR(100), 
	informatore VARCHAR(100), 
	rilevatore VARCHAR(100), 
	prezzo VARCHAR(100), 
	data_inserimento TIMESTAMP WITHOUT TIME ZONE, 
	nascosto VARCHAR(20), 
	ribaltato_da_anno VARCHAR(100), 
	addendum VARCHAR(20), 
	ribaltato_da_addendum VARCHAR(100), 
	last_update TIMESTAMP WITHOUT TIME ZONE
);
