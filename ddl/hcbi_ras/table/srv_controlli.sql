
CREATE TABLE hcbi_ras.srv_controlli (
	dt_data_check TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	id_chain_log NUMERIC NOT NULL, 
	id_chain NUMERIC NOT NULL, 
	ds_tipo_controllo VARCHAR(4000) NOT NULL, 
	ds_oggetto_controllo VARCHAR(4000) NOT NULL, 
	ds_risultato_controllo VARCHAR(4000)
);

COMMENT ON TABLE hcbi_ras.srv_controlli
    IS 'Tabella di servizio controlli; Attualmente non utilizzata';

ALTER TABLE hcbi_ras.srv_controlli OWNER TO hcbi_ras;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.srv_controlli TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.srv_controlli TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.srv_controlli.dt_data_check IS 'Data Data Check';
COMMENT ON COLUMN hcbi_ras.srv_controlli.id_chain_log IS 'ID di sistema Chain Log';
COMMENT ON COLUMN hcbi_ras.srv_controlli.id_chain IS 'ID di sistema Chain';
COMMENT ON COLUMN hcbi_ras.srv_controlli.ds_tipo_controllo IS 'Descrizione Tipo Controllo';
COMMENT ON COLUMN hcbi_ras.srv_controlli.ds_oggetto_controllo IS 'Descrizione Oggetto Controllo';
COMMENT ON COLUMN hcbi_ras.srv_controlli.ds_risultato_controllo IS 'Descrizione Risultato Controllo';
