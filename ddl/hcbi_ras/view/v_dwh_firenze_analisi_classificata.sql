CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_firenze_analisi_classificata" AS
 WITH base AS (
         SELECT s.nr_anno,
            s.ds_regione,
            s.ds_provincia,
            s.nr_riga_file,
            s.analisi,
            s.descrizione,
            s.cam,
            s.codice_dettaglio,
            s.cam_codice_dettaglio,
            s.voce_articolo,
            s.codice_collegato,
            s.unita_misura,
            s.quantita,
            s.prezzo_unitario,
            s.importo,
            s.tx_nome_file,
            s.dt_caricamento,
            s.tx_caricamento_by,
            sum(
                CASE
                    WHEN NULLIF(btrim(s.analisi), ''::text) IS NOT NULL AND btrim(s.analisi) <> 'Analisi'::text THEN 1
                    ELSE 0
                END) OVER (PARTITION BY s.nr_anno ORDER BY s.nr_riga_file ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS grp_analisi
           FROM hcbi_ras.stg_firenze_analisi s
        ), ctx AS (
         SELECT b.nr_anno,
            b.ds_regione,
            b.ds_provincia,
            b.nr_riga_file,
            b.analisi,
            b.descrizione,
            b.cam,
            b.codice_dettaglio,
            b.cam_codice_dettaglio,
            b.voce_articolo,
            b.codice_collegato,
            b.unita_misura,
            b.quantita,
            b.prezzo_unitario,
            b.importo,
            b.tx_nome_file,
            b.dt_caricamento,
            b.tx_caricamento_by,
            b.grp_analisi,
            max(
                CASE
                    WHEN NULLIF(btrim(b.analisi), ''::text) IS NOT NULL AND btrim(b.analisi) <> 'Analisi'::text THEN btrim(b.analisi)
                    ELSE NULL::text
                END) OVER (PARTITION BY b.nr_anno, b.grp_analisi) AS cd_analisi_propagato,
            max(
                CASE
                    WHEN NULLIF(btrim(b.analisi), ''::text) IS NOT NULL AND btrim(b.analisi) <> 'Analisi'::text THEN b.descrizione
                    ELSE NULL::text
                END) OVER (PARTITION BY b.nr_anno, b.grp_analisi) AS ds_analisi_propagata,
            max(
                CASE
                    WHEN NULLIF(btrim(b.analisi), ''::text) IS NOT NULL AND btrim(b.analisi) <> 'Analisi'::text THEN NULLIF(btrim(b.cam), ''::text)
                    ELSE NULL::text
                END) OVER (PARTITION BY b.nr_anno, b.grp_analisi) AS fl_cam_propagato
           FROM base b
        ), converted AS (
         SELECT c_1.nr_anno,
            c_1.ds_regione,
            c_1.ds_provincia,
            c_1.nr_riga_file,
            c_1.analisi,
            c_1.descrizione,
            c_1.cam,
            c_1.codice_dettaglio,
            c_1.cam_codice_dettaglio,
            c_1.voce_articolo,
            c_1.codice_collegato,
            c_1.unita_misura,
            c_1.quantita,
            c_1.prezzo_unitario,
            c_1.importo,
            c_1.tx_nome_file,
            c_1.dt_caricamento,
            c_1.tx_caricamento_by,
            c_1.grp_analisi,
            c_1.cd_analisi_propagato,
            c_1.ds_analisi_propagata,
            c_1.fl_cam_propagato,
            COALESCE(c_1.codice_dettaglio, ''::text) ~ '^TOS[0-9]{2}_[A-Z0-9]+\..+'::text AS fl_componente_candidato,
            NULLIF(btrim(c_1.codice_dettaglio), ''::text) AS cd_dettaglio_normalizzato,
            NULLIF(btrim(c_1.unita_misura), ''::text) AS cd_unita_misura_normalizzata,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(c_1.quantita), ','::text, '.'::text), ''::text)) AS nr_quantita_convertita,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(c_1.prezzo_unitario), ','::text, '.'::text), ''::text)) AS nr_prezzo_unitario_convertito,
            hcbi_ras.try_numeric_24_6(NULLIF(replace(btrim(c_1.importo), ','::text, '.'::text), ''::text)) AS nr_importo_convertito
           FROM ctx c_1
        ), keyed AS (
         SELECT x.nr_anno,
            x.ds_regione,
            x.ds_provincia,
            x.nr_riga_file,
            x.analisi,
            x.descrizione,
            x.cam,
            x.codice_dettaglio,
            x.cam_codice_dettaglio,
            x.voce_articolo,
            x.codice_collegato,
            x.unita_misura,
            x.quantita,
            x.prezzo_unitario,
            x.importo,
            x.tx_nome_file,
            x.dt_caricamento,
            x.tx_caricamento_by,
            x.grp_analisi,
            x.cd_analisi_propagato,
            x.ds_analisi_propagata,
            x.fl_cam_propagato,
            x.fl_componente_candidato,
            x.cd_dettaglio_normalizzato,
            x.cd_unita_misura_normalizzata,
            x.nr_quantita_convertita,
            x.nr_prezzo_unitario_convertito,
            x.nr_importo_convertito,
            count(*) FILTER (WHERE x.fl_componente_candidato) OVER (PARTITION BY x.nr_anno, x.cd_analisi_propagato, x.cd_dettaglio_normalizzato, x.nr_riga_file) AS duplicate_count
           FROM converted x
        ), classified AS (
         SELECT k.nr_anno,
            k.ds_regione,
            k.ds_provincia,
            k.nr_riga_file,
            k.analisi,
            k.descrizione,
            k.cam,
            k.codice_dettaglio,
            k.cam_codice_dettaglio,
            k.voce_articolo,
            k.codice_collegato,
            k.unita_misura,
            k.quantita,
            k.prezzo_unitario,
            k.importo,
            k.tx_nome_file,
            k.dt_caricamento,
            k.tx_caricamento_by,
            k.grp_analisi,
            k.cd_analisi_propagato,
            k.ds_analisi_propagata,
            k.fl_cam_propagato,
            k.fl_componente_candidato,
            k.cd_dettaglio_normalizzato,
            k.cd_unita_misura_normalizzata,
            k.nr_quantita_convertita,
            k.nr_prezzo_unitario_convertito,
            k.nr_importo_convertito,
            k.duplicate_count,
                CASE
                    WHEN NOT k.fl_componente_candidato THEN 'STRUCTURAL'::text
                    WHEN k.cd_analisi_propagato IS NULL THEN 'REJECT'::text
                    WHEN k.duplicate_count > 1 THEN 'REJECT'::text
                    WHEN length(k.cd_analisi_propagato) > 100 THEN 'REJECT'::text
                    WHEN length(k.cd_dettaglio_normalizzato) > 200 THEN 'REJECT'::text
                    WHEN k.cd_unita_misura_normalizzata IS NULL THEN 'REJECT'::text
                    WHEN length(k.cd_unita_misura_normalizzata) > 50 THEN 'REJECT'::text
                    WHEN NULLIF(btrim(k.quantita), ''::text) IS NULL THEN 'REJECT'::text
                    WHEN k.nr_quantita_convertita IS NULL THEN 'REJECT'::text
                    WHEN NULLIF(btrim(k.prezzo_unitario), ''::text) IS NULL THEN 'REJECT'::text
                    WHEN k.nr_prezzo_unitario_convertito IS NULL THEN 'REJECT'::text
                    WHEN NULLIF(btrim(k.importo), ''::text) IS NULL THEN 'REJECT'::text
                    WHEN k.nr_importo_convertito IS NULL THEN 'REJECT'::text
                    ELSE 'LOAD'::text
                END::character varying(30) AS cd_esito,
                CASE
                    WHEN NOT k.fl_componente_candidato THEN NULL::text
                    WHEN k.cd_analisi_propagato IS NULL THEN 'DWH001_ANALISI_NON_PROPAGABILE'::text
                    WHEN k.duplicate_count > 1 THEN 'DWH060_BUSINESS_KEY_DUPLICATA'::text
                    WHEN length(k.cd_analisi_propagato) > 100 THEN 'DWH050_CD_ANALISI_TROPPO_LUNGO'::text
                    WHEN length(k.cd_dettaglio_normalizzato) > 200 THEN 'DWH051_CD_DETTAGLIO_TROPPO_LUNGO'::text
                    WHEN k.cd_unita_misura_normalizzata IS NULL THEN 'DWH011_UNITA_MISURA_MANCANTE'::text
                    WHEN length(k.cd_unita_misura_normalizzata) > 50 THEN 'DWH052_UNITA_MISURA_TROPPO_LUNGA'::text
                    WHEN NULLIF(btrim(k.quantita), ''::text) IS NULL THEN 'DWH020_QUANTITA_MANCANTE'::text
                    WHEN k.nr_quantita_convertita IS NULL THEN 'DWH021_QUANTITA_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(k.prezzo_unitario), ''::text) IS NULL THEN 'DWH030_PREZZO_MANCANTE'::text
                    WHEN k.nr_prezzo_unitario_convertito IS NULL THEN 'DWH031_PREZZO_NON_CONVERTIBILE'::text
                    WHEN NULLIF(btrim(k.importo), ''::text) IS NULL THEN 'DWH040_IMPORTO_MANCANTE'::text
                    WHEN k.nr_importo_convertito IS NULL THEN 'DWH041_IMPORTO_NON_CONVERTIBILE'::text
                    ELSE NULL::text
                END::character varying(100) AS cd_motivo_scarto
           FROM keyed k
        )
 SELECT nr_anno,
    ds_regione,
    ds_provincia,
    nr_riga_file,
    analisi,
    descrizione,
    cam,
    codice_dettaglio,
    cam_codice_dettaglio,
    voce_articolo,
    codice_collegato,
    unita_misura,
    quantita,
    prezzo_unitario,
    importo,
    tx_nome_file,
    dt_caricamento,
    tx_caricamento_by,
    cd_analisi_propagato,
    ds_analisi_propagata,
    fl_cam_propagato,
    cd_dettaglio_normalizzato,
    cd_unita_misura_normalizzata,
    nr_quantita_convertita,
    nr_prezzo_unitario_convertito,
    nr_importo_convertito,
    duplicate_count,
        CASE
            WHEN fl_componente_candidato THEN 'COMPONENT'::text
            ELSE 'STRUCTURAL'::text
        END::character varying(30) AS cd_tipo_riga,
    cd_esito,
    cd_motivo_scarto,
        CASE
            WHEN cd_esito::text = 'REJECT'::text THEN concat_ws('; '::text,
            CASE
                WHEN cd_analisi_propagato IS NULL THEN 'Codice analisi non propagabile'::text
                ELSE NULL::text
            END,
            CASE
                WHEN duplicate_count > 1 THEN 'Business key DWH duplicata'::text
                ELSE NULL::text
            END,
            CASE
                WHEN length(cd_analisi_propagato) > 100 THEN 'Codice analisi oltre 100 caratteri'::text
                ELSE NULL::text
            END,
            CASE
                WHEN length(cd_dettaglio_normalizzato) > 200 THEN 'Codice dettaglio oltre 200 caratteri'::text
                ELSE NULL::text
            END,
            CASE
                WHEN cd_unita_misura_normalizzata IS NULL THEN 'Unita di misura mancante'::text
                ELSE NULL::text
            END,
            CASE
                WHEN length(cd_unita_misura_normalizzata) > 50 THEN 'Unita di misura oltre 50 caratteri'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(quantita), ''::text) IS NULL THEN 'Quantita mancante'::text
                WHEN nr_quantita_convertita IS NULL THEN 'Quantita non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(prezzo_unitario), ''::text) IS NULL THEN 'Prezzo unitario mancante'::text
                WHEN nr_prezzo_unitario_convertito IS NULL THEN 'Prezzo unitario non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END,
            CASE
                WHEN NULLIF(btrim(importo), ''::text) IS NULL THEN 'Importo mancante'::text
                WHEN nr_importo_convertito IS NULL THEN 'Importo non convertibile in numeric(24,6)'::text
                ELSE NULL::text
            END)
            ELSE NULL::text
        END::character varying(4000) AS tx_motivo_scarto
   FROM classified c;;
