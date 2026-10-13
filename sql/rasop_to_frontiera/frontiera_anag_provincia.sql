INSERT INTO hcbi_ras.frontiera_anag_provincia (
    id, provincia, nome, id_area_vasta,
    provincia_principale_regionale, provincia_principale_area_vasta
)
SELECT
    p.id::character varying(100) AS id,
    p.provincia,
    p.nome,
    p.id_area_vasta::character varying(20) AS id_area_vasta,
    p.provincia_principale_regionale::character varying(20) AS provincia_principale_regionale,
    p.provincia_principale_area_vasta::character varying(20) AS provincia_principale_area_vasta
FROM public.province AS p
ORDER BY p.id;
