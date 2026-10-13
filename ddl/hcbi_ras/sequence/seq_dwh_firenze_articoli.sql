CREATE SEQUENCE "hcbi_ras"."seq_dwh_firenze_articoli"
    AS bigint
    INCREMENT BY 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START WITH 1
    CACHE 1
    NO CYCLE
    OWNED BY "hcbi_ras"."dwh_firenze_articoli"."id_firenze_articolo";
