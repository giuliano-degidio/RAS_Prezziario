CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_firenze_articoli_classificata" AS
 WITH converted AS (
         SELECT s.nr_anno,
            s.ds_regione,
            s.ds_provincia,
            s.nr_riga_file,
            s.cd_codice_completo,
            s.fl_cam,
            s.ds_tipologia_famiglia,
            s.ds_capitolo,
            s.ds_voce,
            s.ds_articolo,
            s.cd_unita_misura,
            s.nr_prezzo_senza_sg_ui,
            s.nr_prezzo,
            s.nr_perc_spese_generali,
            s.nr_spese_generali,
            s.nr_perc_utili_impresa,
            s.nr_utili_impresa,
            s.nr_perc_oneri_sicurezza_impresa,
            s.nr_oneri_sicurezza_impresa,
            s.nr_incidenza_manodopera_indiretta,
            s.nr_manodopera_indiretta,
            s.nr_incidenza_manodopera_diretta,
            s.nr_manodopera_diretta,
            s.nr_incidenza_oneri_sicurezza_prezzo,
            s.dt_caricamento,
            s.tx_caricamento_by,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_prezzo_senza_sg_ui::text), ','::text, '.'::text), ''::text)) AS nr_prezzo_senza_sg_ui_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_prezzo::text), ','::text, '.'::text), ''::text)) AS nr_prezzo_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_perc_spese_generali::text), ','::text, '.'::text), ''::text)) AS nr_perc_spese_generali_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_spese_generali::text), ','::text, '.'::text), ''::text)) AS nr_spese_generali_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_perc_utili_impresa::text), ','::text, '.'::text), ''::text)) AS nr_perc_utili_impresa_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_utili_impresa::text), ','::text, '.'::text), ''::text)) AS nr_utili_impresa_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_perc_oneri_sicurezza_impresa::text), ','::text, '.'::text), ''::text)) AS nr_perc_oneri_sicurezza_impresa_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_oneri_sicurezza_impresa::text), ','::text, '.'::text), ''::text)) AS nr_oneri_sicurezza_impresa_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_incidenza_manodopera_indiretta::text), ','::text, '.'::text), ''::text)) AS nr_incidenza_manodopera_indiretta_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_manodopera_indiretta::text), ','::text, '.'::text), ''::text)) AS nr_manodopera_indiretta_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_incidenza_manodopera_diretta::text), ','::text, '.'::text), ''::text)) AS nr_incidenza_manodopera_diretta_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_manodopera_diretta::text), ','::text, '.'::text), ''::text)) AS nr_manodopera_diretta_c,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(s.nr_incidenza_oneri_sicurezza_prezzo::text), ','::text, '.'::text), ''::text)) AS nr_incidenza_oneri_sicurezza_prezzo_c,
            count(*) OVER (PARTITION BY s.nr_anno, s.nr_riga_file) AS duplicate_count
           FROM hcbi_ras.stg_firenze_articoli s
        ), classified AS (
         SELECT c_1.nr_anno,
            c_1.ds_regione,
            c_1.ds_provincia,
            c_1.nr_riga_file,
            c_1.cd_codice_completo,
            c_1.fl_cam,
            c_1.ds_tipologia_famiglia,
            c_1.ds_capitolo,
            c_1.ds_voce,
            c_1.ds_articolo,
            c_1.cd_unita_misura,
            c_1.nr_prezzo_senza_sg_ui,
            c_1.nr_prezzo,
            c_1.nr_perc_spese_generali,
            c_1.nr_spese_generali,
            c_1.nr_perc_utili_impresa,
            c_1.nr_utili_impresa,
            c_1.nr_perc_oneri_sicurezza_impresa,
            c_1.nr_oneri_sicurezza_impresa,
            c_1.nr_incidenza_manodopera_indiretta,
            c_1.nr_manodopera_indiretta,
            c_1.nr_incidenza_manodopera_diretta,
            c_1.nr_manodopera_diretta,
            c_1.nr_incidenza_oneri_sicurezza_prezzo,
            c_1.dt_caricamento,
            c_1.tx_caricamento_by,
            c_1.nr_prezzo_senza_sg_ui_c,
            c_1.nr_prezzo_c,
            c_1.nr_perc_spese_generali_c,
            c_1.nr_spese_generali_c,
            c_1.nr_perc_utili_impresa_c,
            c_1.nr_utili_impresa_c,
            c_1.nr_perc_oneri_sicurezza_impresa_c,
            c_1.nr_oneri_sicurezza_impresa_c,
            c_1.nr_incidenza_manodopera_indiretta_c,
            c_1.nr_manodopera_indiretta_c,
            c_1.nr_incidenza_manodopera_diretta_c,
            c_1.nr_manodopera_diretta_c,
            c_1.nr_incidenza_oneri_sicurezza_prezzo_c,
            c_1.duplicate_count,
                CASE
                    WHEN c_1.duplicate_count > 1 THEN 'DWH_001_BUSINESS_KEY_DUPLICATA'::text
                    WHEN NULLIF(btrim(c_1.cd_codice_completo::text), ''::text) IS NULL THEN 'DWH_002_CODICE_COMPLETO_MANCANTE'::text
                    WHEN length(btrim(c_1.cd_codice_completo::text)) > 100 THEN 'DWH_003_CODICE_COMPLETO_TROPPO_LUNGO'::text
                    WHEN NULLIF(btrim(c_1.nr_prezzo_senza_sg_ui::text), ''::text) IS NOT NULL AND c_1.nr_prezzo_senza_sg_ui_c IS NULL THEN 'DWH_020_NR_PREZZO_SENZA_SG_UI_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_prezzo::text), ''::text) IS NOT NULL AND c_1.nr_prezzo_c IS NULL THEN 'DWH_021_NR_PREZZO_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_perc_spese_generali::text), ''::text) IS NOT NULL AND c_1.nr_perc_spese_generali_c IS NULL THEN 'DWH_022_NR_PERC_SPESE_GENERALI_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_spese_generali::text), ''::text) IS NOT NULL AND c_1.nr_spese_generali_c IS NULL THEN 'DWH_023_NR_SPESE_GENERALI_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_perc_utili_impresa::text), ''::text) IS NOT NULL AND c_1.nr_perc_utili_impresa_c IS NULL THEN 'DWH_024_NR_PERC_UTILI_IMPRESA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_utili_impresa::text), ''::text) IS NOT NULL AND c_1.nr_utili_impresa_c IS NULL THEN 'DWH_025_NR_UTILI_IMPRESA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_perc_oneri_sicurezza_impresa::text), ''::text) IS NOT NULL AND c_1.nr_perc_oneri_sicurezza_impresa_c IS NULL THEN 'DWH_026_NR_PERC_ONERI_SICUREZZA_IMPRESA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_oneri_sicurezza_impresa::text), ''::text) IS NOT NULL AND c_1.nr_oneri_sicurezza_impresa_c IS NULL THEN 'DWH_027_NR_ONERI_SICUREZZA_IMPRESA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_incidenza_manodopera_indiretta::text), ''::text) IS NOT NULL AND c_1.nr_incidenza_manodopera_indiretta_c IS NULL THEN 'DWH_028_NR_INCIDENZA_MANODOPERA_INDIRETTA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_manodopera_indiretta::text), ''::text) IS NOT NULL AND c_1.nr_manodopera_indiretta_c IS NULL THEN 'DWH_029_NR_MANODOPERA_INDIRETTA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_incidenza_manodopera_diretta::text), ''::text) IS NOT NULL AND c_1.nr_incidenza_manodopera_diretta_c IS NULL THEN 'DWH_030_NR_INCIDENZA_MANODOPERA_DIRETTA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_manodopera_diretta::text), ''::text) IS NOT NULL AND c_1.nr_manodopera_diretta_c IS NULL THEN 'DWH_031_NR_MANODOPERA_DIRETTA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(c_1.nr_incidenza_oneri_sicurezza_prezzo::text), ''::text) IS NOT NULL AND c_1.nr_incidenza_oneri_sicurezza_prezzo_c IS NULL THEN 'DWH_032_NR_INCIDENZA_ONERI_SICUREZZA_PREZZO_NON_CONVERTIBILE'::text
                    ELSE NULL::text
                END::character varying(150) AS cd_motivo_scarto
           FROM converted c_1
        )
 SELECT nr_anno,
    ds_regione,
    ds_provincia,
    nr_riga_file,
    cd_codice_completo,
    fl_cam,
    ds_tipologia_famiglia,
    ds_capitolo,
    ds_voce,
    ds_articolo,
    cd_unita_misura,
    nr_prezzo_senza_sg_ui,
    nr_prezzo,
    nr_perc_spese_generali,
    nr_spese_generali,
    nr_perc_utili_impresa,
    nr_utili_impresa,
    nr_perc_oneri_sicurezza_impresa,
    nr_oneri_sicurezza_impresa,
    nr_incidenza_manodopera_indiretta,
    nr_manodopera_indiretta,
    nr_incidenza_manodopera_diretta,
    nr_manodopera_diretta,
    nr_incidenza_oneri_sicurezza_prezzo,
    dt_caricamento,
    tx_caricamento_by,
    nr_prezzo_senza_sg_ui_c,
    nr_prezzo_c,
    nr_perc_spese_generali_c,
    nr_spese_generali_c,
    nr_perc_utili_impresa_c,
    nr_utili_impresa_c,
    nr_perc_oneri_sicurezza_impresa_c,
    nr_oneri_sicurezza_impresa_c,
    nr_incidenza_manodopera_indiretta_c,
    nr_manodopera_indiretta_c,
    nr_incidenza_manodopera_diretta_c,
    nr_manodopera_diretta_c,
    nr_incidenza_oneri_sicurezza_prezzo_c,
    duplicate_count,
    cd_motivo_scarto,
        CASE
            WHEN cd_motivo_scarto IS NULL THEN 'LOAD'::text
            ELSE 'REJECT'::text
        END::character varying(30) AS cd_esito,
        CASE
            WHEN cd_motivo_scarto IS NULL THEN NULL::text
            ELSE concat_ws('; '::text,
            CASE
                WHEN duplicate_count > 1 THEN 'Business key duplicata'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(cd_codice_completo::text), ''::text) IS NULL THEN 'Codice completo mancante'::text
                ELSE NULL::text
            END,
            CASE
                WHEN length(btrim(cd_codice_completo::text)) > 100 THEN 'Codice completo oltre 100 caratteri'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_prezzo_senza_sg_ui::text), ''::text) IS NOT NULL AND nr_prezzo_senza_sg_ui_c IS NULL THEN 'nr_prezzo_senza_sg_ui non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_prezzo::text), ''::text) IS NOT NULL AND nr_prezzo_c IS NULL THEN 'nr_prezzo non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_perc_spese_generali::text), ''::text) IS NOT NULL AND nr_perc_spese_generali_c IS NULL THEN 'nr_perc_spese_generali non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_spese_generali::text), ''::text) IS NOT NULL AND nr_spese_generali_c IS NULL THEN 'nr_spese_generali non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_perc_utili_impresa::text), ''::text) IS NOT NULL AND nr_perc_utili_impresa_c IS NULL THEN 'nr_perc_utili_impresa non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_utili_impresa::text), ''::text) IS NOT NULL AND nr_utili_impresa_c IS NULL THEN 'nr_utili_impresa non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_perc_oneri_sicurezza_impresa::text), ''::text) IS NOT NULL AND nr_perc_oneri_sicurezza_impresa_c IS NULL THEN 'nr_perc_oneri_sicurezza_impresa non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_oneri_sicurezza_impresa::text), ''::text) IS NOT NULL AND nr_oneri_sicurezza_impresa_c IS NULL THEN 'nr_oneri_sicurezza_impresa non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_incidenza_manodopera_indiretta::text), ''::text) IS NOT NULL AND nr_incidenza_manodopera_indiretta_c IS NULL THEN 'nr_incidenza_manodopera_indiretta non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_manodopera_indiretta::text), ''::text) IS NOT NULL AND nr_manodopera_indiretta_c IS NULL THEN 'nr_manodopera_indiretta non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_incidenza_manodopera_diretta::text), ''::text) IS NOT NULL AND nr_incidenza_manodopera_diretta_c IS NULL THEN 'nr_incidenza_manodopera_diretta non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_manodopera_diretta::text), ''::text) IS NOT NULL AND nr_manodopera_diretta_c IS NULL THEN 'nr_manodopera_diretta non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(nr_incidenza_oneri_sicurezza_prezzo::text), ''::text) IS NOT NULL AND nr_incidenza_oneri_sicurezza_prezzo_c IS NULL THEN 'nr_incidenza_oneri_sicurezza_prezzo non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END)
        END::character varying(4000) AS tx_motivo_scarto
   FROM classified c;;
