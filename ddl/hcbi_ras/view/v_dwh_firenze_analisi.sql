CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_firenze_analisi" AS
 SELECT nr_anno,
    btrim(ds_regione::text)::character varying(50) AS ds_regione,
    btrim(ds_provincia::text)::character varying(50) AS ds_provincia,
    nr_riga_file,
    cd_analisi_propagato::character varying(100) AS cd_analisi,
    ds_analisi_propagata AS ds_analisi,
    fl_cam_propagato::character varying(20) AS fl_cam,
    cd_dettaglio_normalizzato::character varying(200) AS cd_dettaglio,
    NULLIF(btrim(cam_codice_dettaglio), ''::text)::character varying(200) AS cd_dettaglio_cam,
    NULLIF(btrim(voce_articolo), ''::text) AS ds_voce_articolo,
    NULLIF(btrim(codice_collegato), ''::text)::character varying(200) AS cd_collegato,
    cd_unita_misura_normalizzata::character varying(50) AS cd_unita_misura,
    nr_quantita_convertita AS nr_quantita,
    nr_prezzo_unitario_convertito AS nr_prezzo_unitario,
    nr_importo_convertito AS nr_importo,
    btrim(tx_nome_file::text)::character varying(255) AS tx_nome_file,
    dt_caricamento,
    NULLIF(btrim(tx_caricamento_by::text), ''::text)::character varying(100) AS tx_caricamento_by
   FROM hcbi_ras.v_dwh_firenze_analisi_classificata c
  WHERE cd_esito::text = 'LOAD'::text;;
