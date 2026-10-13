CREATE OR REPLACE VIEW "hcbi_ras"."v_frontiera_anag_sottocapitolo" AS
 SELECT DISTINCT anno,
    addendum,
    codice,
    nome,
    provincia
   FROM hcbi_ras.frontiera_anag_articolo ar
  WHERE TRIM(BOTH FROM livello::text) = '3'::text;;
