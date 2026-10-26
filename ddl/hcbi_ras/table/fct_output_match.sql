CREATE TABLE hcbi_ras.fct_output_match (
	anno int4 NULL,
	cd_completo_sardegna varchar(400) NULL,
	id_anag_articolo_sardegna int8 NULL,
	cd_articolo_firenze varchar(400) NULL,
	id_anag_articolo_firenze int8 NULL,
	id_anag_regione int8 NULL,
	fl_match int4 NULL,
	"rank" int4 NULL
);

ALTER TABLE hcbi_ras.fct_output_match OWNER TO hcbi_ras;

GRANT ALL ON TABLE hcbi_ras.fct_output_match TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.fct_output_match TO hcbi_utility;
