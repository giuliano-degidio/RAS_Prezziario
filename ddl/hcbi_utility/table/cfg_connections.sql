
CREATE TABLE hcbi_utility.cfg_connections (
	conn_name VARCHAR(100) NOT NULL, 
	conn_string TEXT, 
	CONSTRAINT cfg_connections_pkey PRIMARY KEY (conn_name)
);
