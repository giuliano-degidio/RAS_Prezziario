CREATE TABLE IF NOT EXISTS hcbi_ras.fe_ai_output_match
(
    anno integer,
    cd_completo_sardegna character varying(400) COLLATE pg_catalog."default",
    cd_articolo_firenze character varying(400) COLLATE pg_catalog."default",
    fl_match integer,
    rank integer,
    cd_regione character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.fe_ai_output_match
    OWNER to hcbi_ras;

ALTER TABLE hcbi_ras.fe_ai_output_match OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.fe_ai_output_match IS 'Tabella utilizzata dall''applicazione front end.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.fe_ai_output_match TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.fe_ai_output_match TO hcbi_utility;
