CREATE OR REPLACE VIEW "hcbi_ras"."v_fct_firenze_analisi_src" AS
 SELECT src.id_firenze_analisi,
    src.nr_anno,
    src.ds_regione,
    src.ds_provincia,
    src.nr_riga_file,
    src.cd_analisi,
    src.ds_analisi,
    src.fl_cam,
    src.cd_dettaglio_cam,
    src.ds_voce_articolo,
    src.cd_collegato,
    src.cd_unita_misura,
    src.nr_quantita,
    src.nr_prezzo_unitario,
    src.nr_importo,
    src.tx_nome_file,
    src.dt_caricamento,
    src.tx_caricamento_by,
    src.cd_dettaglio AS cd_codice_completo_lookup,
        CASE
            WHEN src.cd_dettaglio IS NULL THEN 0::bigint
            ELSE COALESCE(art.id_firenze_articolo, '-1'::integer::bigint)
        END AS id_firenze_articolo,
        CASE
            WHEN src.cd_dettaglio IS NULL THEN 'TAPPO 0: codice articolo sorgente assente'::text
            WHEN art.id_firenze_articolo IS NULL THEN 'TAPPO -1: codice articolo non presente in DIM_FIRENZE_ARTICOLI: '::text || src.cd_dettaglio::text
            ELSE NULL::text
        END::character varying(4000) AS tx_motivo_lookup
   FROM hcbi_ras.dwh_firenze_analisi src
     LEFT JOIN hcbi_ras.dim_firenze_articoli art ON art.cd_codice_completo::text = src.cd_dettaglio::text;;
