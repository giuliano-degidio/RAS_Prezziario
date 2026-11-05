
CREATE TABLE hcbi_ras.frontiera_anag_macro_gruppo (
	id VARCHAR(100), 
	nome VARCHAR(100), 
	plurale VARCHAR(100)
);

ALTER TABLE hcbi_ras.frontiera_anag_macro_gruppo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.frontiera_anag_macro_gruppo IS 'Frontiera del flusso ANAG_MACRO_GRUPPO.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_anag_macro_gruppo TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.frontiera_anag_macro_gruppo TO hcbi_utility;
