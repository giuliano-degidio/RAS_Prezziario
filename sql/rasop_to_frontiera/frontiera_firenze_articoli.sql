-- Tabella importata da foglio Excel.
-- Non esiste una query deterministicamente derivabile da rasop per tutti i campi.
-- Template best-effort basato su public.articoli.
INSERT INTO hcbi_ras.frontiera_firenze_articoli (
    nr_anno, ds_regione, ds_provincia, nr_riga_file, cd_codice_completo,
    fl_cam, ds_tipologia_famiglia, ds_capitolo, ds_voce, ds_articolo,
    cd_unita_misura, nr_prezzo_senza_sg_ui, nr_prezzo,
    nr_perc_spese_generali, nr_spese_generali, nr_perc_utili_impresa,
    nr_utili_impresa, nr_perc_oneri_sicurezza_impresa,
    nr_oneri_sicurezza_impresa, nr_incidenza_manodopera_indiretta,
    nr_manodopera_indiretta, nr_incidenza_manodopera_diretta,
    nr_manodopera_diretta, nr_incidenza_oneri_sicurezza_prezzo
)
SELECT
    a.anno::integer AS nr_anno,
    NULL::varchar(100) AS ds_regione,
    NULL::varchar(100) AS ds_provincia,
    row_number() OVER (ORDER BY a.id)::bigint AS nr_riga_file,
    a.codice AS cd_codice_completo,
    CASE WHEN a.is_cam IS TRUE THEN '1' WHEN a.is_cam IS FALSE THEN '0' END::varchar(50) AS fl_cam,
    NULL::text AS ds_tipologia_famiglia,
    NULL::text AS ds_capitolo,
    NULL::text AS ds_voce,
    a.nome::text AS ds_articolo,
    a.unita_misura::character varying(50) AS cd_unita_misura,
    NULL::varchar(50) AS nr_prezzo_senza_sg_ui,
    NULL::varchar(50) AS nr_prezzo,
    a.spese_generali::character varying(50) AS nr_perc_spese_generali,
    a.spese_generali::character varying(50) AS nr_spese_generali,
    a.utile_impresa::character varying(50) AS nr_perc_utili_impresa,
    a.utile_impresa::character varying(50) AS nr_utili_impresa,
    NULL::varchar(50) AS nr_perc_oneri_sicurezza_impresa,
    NULL::varchar(50) AS nr_oneri_sicurezza_impresa,
    NULL::varchar(50) AS nr_incidenza_manodopera_indiretta,
    NULL::varchar(50) AS nr_manodopera_indiretta,
    NULL::varchar(50) AS nr_incidenza_manodopera_diretta,
    NULL::varchar(50) AS nr_manodopera_diretta,
    NULL::varchar(50) AS nr_incidenza_oneri_sicurezza_prezzo
FROM public.articoli AS a;
