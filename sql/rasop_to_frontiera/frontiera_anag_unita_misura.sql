INSERT INTO hcbi_ras.frontiera_anag_unita_misura (
    codice, descrizione, decimali, id, last_update, data_fine_validita
)
SELECT
    um.codice,
    um.descrizione,
    um.decimali::character varying(100) AS decimali,
    um.id::character varying(100) AS id,
    um.last_update,
    um.data_fine_validita
FROM public.unita_misura AS um
ORDER BY um.codice;
