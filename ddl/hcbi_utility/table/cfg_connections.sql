
CREATE TABLE hcbi_utility.cfg_connections (
	conn_name VARCHAR(100) NOT NULL, 
	conn_string TEXT, 
	CONSTRAINT cfg_connections_pkey PRIMARY KEY (conn_name)
);

ALTER TABLE hcbi_utility.cfg_connections OWNER TO hcbi_utility;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_utility.cfg_connections TO hcbi_ras;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_utility.cfg_connections TO hcbi_utility;
