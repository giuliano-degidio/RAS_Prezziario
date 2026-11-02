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