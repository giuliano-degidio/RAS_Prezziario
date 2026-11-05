
CREATE TABLE hcbi_ras.frontiera_anag_utenti (
	user_id VARCHAR(100), 
	username VARCHAR(255), 
	email VARCHAR(255), 
	display_name VARCHAR(50), 
	state VARCHAR(20), 
	usertype VARCHAR(25)
);

ALTER TABLE hcbi_ras.frontiera_anag_utenti OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.frontiera_anag_utenti IS 'Frontiera del flusso ANAG_UTENTI';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_anag_utenti TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.frontiera_anag_utenti TO hcbi_utility;
