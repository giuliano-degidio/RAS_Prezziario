CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log        bigint;
    v_selected      bigint := 0;
    v_inserted      bigint := 0;
    v_updated       bigint := 0;
    v_deleted       bigint := 0;
    v_rec_errors    bigint := 0;

    v_sqlstate      text;
    v_sqlerrm       text;
    v_sql_detail    text;
    v_sql_hint      text;
    v_sql_context   text;
    v_log_error     text;
    v_ts_start      timestamp;
BEGIN
    p_result  := -1;
    v_ts_start := clock_timestamp()::timestamp;

    RAISE NOTICE
        'Avvio PKG_STG_PUBBLICAZIONE_ANALISI per lo step %',
        p_ds_step_name;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        v_ts_start,
        v_ts_start,
        p_ds_step_name
    )
    INTO v_id_log;

    -- Tabella di lavoro persistente. Nessuna concorrenza ammessa.
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;

    CREATE TABLE hcbi_ras.tmp_pubblicazione_analisi_classificata
    AS
    WITH src AS MATERIALIZED (
        SELECT
            f.ds_anno_pubblicazione,
            f.cd_codice_analisi,
            f.nr_quantita,
            f.cd_articolo,
            f.cd_versione,
            f.id_sorgente_pubblicazione_analisi,
            f.id_sorgente_categoria,
            f.nr_riga,

            NULLIF(btrim(f.ds_anno_pubblicazione), '')
                AS anno_txt,

            NULLIF(btrim(f.cd_codice_analisi), '')
                AS codice_analisi_txt,

            NULLIF(
                replace(btrim(f.nr_quantita), ',', '.'),
                ''
            ) AS quantita_txt,

            NULLIF(btrim(f.cd_articolo), '')
                AS articolo_txt,

            NULLIF(btrim(f.cd_versione), '')
                AS versione_txt,

            NULLIF(
                btrim(f.id_sorgente_pubblicazione_analisi),
                ''
            ) AS id_pubblicazione_txt,

            NULLIF(
                btrim(f.id_sorgente_categoria),
                ''
            ) AS id_categoria_txt,

            count(*) OVER (
                PARTITION BY
                    f.ds_anno_pubblicazione,
                    f.cd_codice_analisi,
                    f.cd_articolo,
                    f.cd_versione,
                    f.nr_riga
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_pubblicazione_analisi AS f
    ),
    converted AS MATERIALIZED (
        SELECT
            s.ds_anno_pubblicazione,
            s.cd_codice_analisi,
            s.nr_quantita,
            s.cd_articolo,
            s.cd_versione,
            s.id_sorgente_pubblicazione_analisi,
            s.id_sorgente_categoria,
            s.nr_riga,
            s.anno_txt,
            s.codice_analisi_txt,
            s.quantita_txt,
            s.articolo_txt,
            s.versione_txt,
            s.id_pubblicazione_txt,
            s.id_categoria_txt,
            s.duplicate_count,

            hcbi_ras.try_numeric_10_0(s.anno_txt)
                AS anno_convertito,

            hcbi_ras.try_numeric_24_6(s.quantita_txt)
                AS quantita_convertita,

            hcbi_ras.try_smallint(s.versione_txt)
                AS versione_convertita,

            hcbi_ras.try_bigint(s.id_pubblicazione_txt)
                AS id_pubblicazione_convertito,

            hcbi_ras.try_bigint(s.id_categoria_txt)
                AS id_categoria_convertito
        FROM src AS s
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.cd_codice_analisi,
        c.nr_quantita,
        c.cd_articolo,
        c.cd_versione,
        c.id_sorgente_pubblicazione_analisi,
        c.id_sorgente_categoria,
        c.nr_riga,
        c.anno_txt,
        c.codice_analisi_txt,
        c.quantita_txt,
        c.articolo_txt,
        c.versione_txt,
        c.id_pubblicazione_txt,
        c.id_categoria_txt,
        c.anno_convertito,
        c.quantita_convertita,
        c.versione_convertita,
        c.id_pubblicazione_convertito,
        c.id_categoria_convertito,
        c.duplicate_count,
        CASE
            WHEN c.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: '
                || '(ds_anno_pubblicazione, cd_codice_analisi, '
                || 'cd_articolo, cd_versione, nr_riga)'

            WHEN c.anno_txt IS NOT NULL
             AND c.anno_convertito IS NULL THEN
                'ds_anno_pubblicazione non convertibile in numeric(10,0)'

            WHEN c.quantita_txt IS NOT NULL
             AND c.quantita_convertita IS NULL THEN
                'nr_quantita non convertibile in numeric(24,6)'

            WHEN c.versione_txt IS NOT NULL
             AND c.versione_convertita IS NULL THEN
                'cd_versione non convertibile in smallint'

            WHEN c.id_pubblicazione_txt IS NOT NULL
             AND c.id_pubblicazione_convertito IS NULL THEN
                'id_sorgente_pubblicazione_analisi non convertibile in bigint'

            WHEN c.id_categoria_txt IS NOT NULL
             AND c.id_categoria_convertito IS NULL THEN
                'id_sorgente_categoria non convertibile in bigint'

            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata;

    INSERT INTO hcbi_ras.stg_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga
    )
    SELECT
        c.anno_convertito,
        c.codice_analisi_txt,
        c.quantita_convertita,
        c.articolo_txt,
        c.versione_convertita,
        c.id_pubblicazione_convertito,
        c.id_categoria_convertito,
        c.nr_riga
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_pubblicazione_analisi_rej (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        tx_motivo_scarto
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.cd_codice_analisi,
        c.nr_quantita,
        c.cd_articolo,
        c.cd_versione,
        c.id_sorgente_pubblicazione_analisi,
        c.id_sorgente_categoria,
        c.nr_riga,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    v_updated := 0;
    v_deleted := 0;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected,
                    v_inserted,
                    v_rec_errors
                ),
                DETAIL =
                    'Il numero di record letti non coincide con la somma '
                    || 'dei record caricati e scartati.',
                HINT =
                    'Verificare la classificazione e gli INSERT verso STG e REJ.';
    END IF;

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

    -- Pulizia della tabella di lavoro dopo l'uso.
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_STG_PUBBLICAZIONE_ANALISI: selected=%, inserted=%, rejected=%',
        v_selected,
        v_inserted,
        v_rec_errors;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        -- Pulizia best effort: non deve sostituire l'errore originario.
        BEGIN
            DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;
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
        'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
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

        -- Compatibilita' con la procedura originaria:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_stg_pubblicazione_analisi_prc_main. '
            'SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
