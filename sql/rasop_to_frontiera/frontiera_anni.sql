INSERT INTO hcbi_ras.frontiera_anni (
    anno, addendum, addendum_name, scostamento_1_visibile,
    scostamento_2_visibile, scostamento_3_visibile,
    scostamento_4_visibile, spese_generali, utile_impresa,
    llpp_homepage_title, llpp_homepage_description, di_cui_analisi,
    pubblicazione_regionale, llpp_homepage_title_de,
    llpp_homepage_description_de, scostamento_5_visibile,
    preferenze_esportazione, id, impostazioni_prezzi,
    mostra_annotazioni, mostra_struttura_analisi, is_errata_corrige,
    mostra_cam
)
SELECT
    a.anno::character varying(100) AS anno,
    a.addendum::character varying(20) AS addendum,
    a.addendum_name,
    CASE WHEN a.scostamento_1_visibile IS TRUE THEN '1' WHEN a.scostamento_1_visibile IS FALSE THEN '0' END::character varying(20) AS scostamento_1_visibile,
    CASE WHEN a.scostamento_2_visibile IS TRUE THEN '1' WHEN a.scostamento_2_visibile IS FALSE THEN '0' END::character varying(20) AS scostamento_2_visibile,
    CASE WHEN a.scostamento_3_visibile IS TRUE THEN '1' WHEN a.scostamento_3_visibile IS FALSE THEN '0' END::character varying(20) AS scostamento_3_visibile,
    CASE WHEN a.scostamento_4_visibile IS TRUE THEN '1' WHEN a.scostamento_4_visibile IS FALSE THEN '0' END::character varying(20) AS scostamento_4_visibile,
    a.spese_generali::character varying(100) AS spese_generali,
    a.utile_impresa::character varying(100) AS utile_impresa,
    a.llpp_homepage_title,
    a.llpp_homepage_description,
    a.di_cui_analisi::character varying(100) AS di_cui_analisi,
    CASE WHEN a.pubblicazione_regionale IS TRUE THEN '1' WHEN a.pubblicazione_regionale IS FALSE THEN '0' END::character varying(20) AS pubblicazione_regionale,
    a.llpp_homepage_title_de,
    a.llpp_homepage_description_de,
    CASE WHEN a.scostamento_5_visibile IS TRUE THEN '1' WHEN a.scostamento_5_visibile IS FALSE THEN '0' END::character varying(20) AS scostamento_5_visibile,
    a.preferenze_esportazione::text AS preferenze_esportazione,
    a.id::character varying(100) AS id,
    a.impostazioni_prezzi::text AS impostazioni_prezzi,
    a.mostra_annotazioni::character varying(20) AS mostra_annotazioni,
    a.mostra_struttura_analisi::character varying(20) AS mostra_struttura_analisi,
    CASE WHEN a.is_errata_corrige IS TRUE THEN '1' WHEN a.is_errata_corrige IS FALSE THEN '0' END::character varying(20) AS is_errata_corrige,
    a.mostra_cam::character varying(20) AS mostra_cam
FROM public.anni AS a
ORDER BY a.anno;
