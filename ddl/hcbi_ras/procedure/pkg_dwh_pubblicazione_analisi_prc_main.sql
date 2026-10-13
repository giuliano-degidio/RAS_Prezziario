CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log      bigint;
    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Avvio PKG_DWH_PUBBLICAZIONE_ANALISI per lo step %',
        p_ds_step_name;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    /*
     * Tabella di lavoro persistente nello schema hcbi_ras.
     * Non e' ammessa l'esecuzione concorrente della procedura
     * per lo stesso flusso.
     */
    DROP TABLE IF EXISTS
        hcbi_ras.tmp_dwh_pubblicazione_analisi;

    CREATE TABLE
        hcbi_ras.tmp_dwh_pubblicazione_analisi
    AS
    SELECT
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga
    FROM hcbi_ras.v_dwh_pubblicazione_analisi;

    /*
     * L'indice replica la semantica della business key DWH
     * e segnala eventuali duplicati nella sorgente materializzata.
     */
    CREATE UNIQUE INDEX
        tmp_dwh_pubblicazione_analisi_uq
    ON hcbi_ras.tmp_dwh_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        cd_articolo,
        cd_versione,
        nr_riga
    ) NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_pubblicazione_analisi;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_pubblicazione_analisi;

    UPDATE hcbi_ras.dwh_pubblicazione_analisi AS dwh
       SET nr_quantita = src.nr_quantita,
           id_sorgente_pubblicazione_analisi =
               src.id_sorgente_pubblicazione_analisi,
           id_sorgente_categoria = src.id_sorgente_categoria,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_pubblicazione_analisi AS src
     WHERE
		   dwh.ds_anno_pubblicazione = src.ds_anno_pubblicazione
	   AND dwh.cd_codice_analisi = src.cd_codice_analisi
	   AND dwh.cd_articolo = src.cd_articolo
	   AND dwh.cd_versione = src.cd_versione
	   AND dwh.nr_riga = src.nr_riga
       AND (
              dwh.nr_quantita IS DISTINCT FROM src.nr_quantita
           OR dwh.id_sorgente_pubblicazione_analisi IS DISTINCT FROM
                  src.id_sorgente_pubblicazione_analisi
           OR dwh.id_sorgente_categoria IS DISTINCT FROM
                  src.id_sorgente_categoria
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.ds_anno_pubblicazione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.cd_articolo,
        src.cd_versione,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_analisi AS src
    ON CONFLICT (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        cd_articolo,
        cd_versione,
        nr_riga
    )
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS
        hcbi_ras.tmp_dwh_pubblicazione_analisi;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_DWH_PUBBLICAZIONE_ANALISI: selected=%, inserted=%, updated=%',
        v_selected,
        v_inserted,
        v_updated;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        /* Cleanup best effort: non deve sostituire l'errore originario. */
        BEGIN
            DROP TABLE IF EXISTS
                hcbi_ras.tmp_dwh_pubblicazione_analisi;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante la pulizia della tabella di lavoro: '
                    'SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE
                    WHEN nullif(v_sql_detail, '') IS NOT NULL
                        THEN 'DETAIL=' || left(v_sql_detail, 1000)
                END,
                CASE
                    WHEN nullif(v_sql_hint, '') IS NOT NULL
                        THEN 'HINT=' || left(v_sql_hint, 500)
                END,
                CASE
                    WHEN nullif(v_sql_context, '') IS NOT NULL
                        THEN 'CONTEXT=' || left(v_sql_context, 800)
                END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_pubblicazione_analisi_prc_main. '
            'SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
