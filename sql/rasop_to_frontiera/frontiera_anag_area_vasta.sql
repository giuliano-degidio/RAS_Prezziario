INSERT INTO hcbi_ras.frontiera_anag_area_vasta (id, nome)
SELECT
    av.id::character varying(100) AS id,
    av.nome::character varying(100) AS nome
FROM public.aree_vaste AS av
ORDER BY av.id;
