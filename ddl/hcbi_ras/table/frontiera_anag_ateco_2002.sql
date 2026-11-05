-- Table: hcbi_ras.frontiera_anag_ateco_2002

-- DROP TABLE IF EXISTS hcbi_ras.frontiera_anag_ateco_2002;

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_ateco_2002
(
    cd_ateco_2002 character varying(200) COLLATE pg_catalog."default",
    ds_ateco_2002 character varying(512) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.frontiera_anag_ateco_2002
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_ateco_2002 FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_anag_ateco_2002
    IS 'Frontiera del flusso ANAG_ATECO_2002.Frontiera statica, non caricata da ETL';

ALTER TABLE hcbi_ras.frontiera_anag_ateco_2002 OWNER TO hcbi_ras;

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_utility;
