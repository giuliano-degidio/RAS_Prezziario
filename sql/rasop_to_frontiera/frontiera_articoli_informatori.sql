INSERT INTO hcbi_ras.frontiera_articoli_informatori (
    id_informatore, codice_articolo, anno, escluso, addendum, id, user_id
)
SELECT
    ai.id_informatore::character varying(100) AS id_informatore,
    ai.codice_articolo,
    ai.anno::character varying(100) AS anno,
    CASE WHEN ai.escluso IS TRUE THEN '1' WHEN ai.escluso IS FALSE THEN '0' END::character varying(20) AS escluso,
    ai.addendum::character varying(20) AS addendum,
    ai.id::character varying(100) AS id,
    ai.user_id::character varying(100) AS user_id
FROM public.articoli_informatori AS ai
ORDER BY ai.id;
