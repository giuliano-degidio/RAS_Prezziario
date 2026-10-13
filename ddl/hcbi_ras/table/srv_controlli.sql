
CREATE TABLE hcbi_ras.srv_controlli (
	dt_data_check TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	id_chain_log NUMERIC NOT NULL, 
	id_chain NUMERIC NOT NULL, 
	ds_tipo_controllo VARCHAR(4000) NOT NULL, 
	ds_oggetto_controllo VARCHAR(4000) NOT NULL, 
	ds_risultato_controllo VARCHAR(4000)
);
