CREATE OR REPLACE VIEW "hcbi_ras"."v_frontiera_anag_tipo_utente" AS
 SELECT DISTINCT usertype
   FROM hcbi_ras.frontiera_anag_utenti u
  ORDER BY usertype;;
