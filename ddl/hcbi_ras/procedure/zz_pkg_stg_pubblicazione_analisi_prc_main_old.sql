CREATE OR REPLACE PROCEDURE hcbi_ras.zz_pkg_stg_pubblicazione_analisi_prc_main_old(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    rec RECORD;

    v_id_log     bigint;
    v_selected   bigint := 0;
    v_inserted   bigint := 0;
    v_updated    bigint := 0;
    v_deleted    bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlerrm    text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Avvio PKG_STG_PUBBLICAZIONE_ANALISI per lo step %',
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

    FOR rec IN
        SELECT f.*
        FROM hcbi_ras.v_src_tmp_pubblicazione_analisi AS f
        INNER JOIN (
            SELECT
                ds_anno_pubblicazione,
                cd_codice_analisi,
                cd_articolo,
                cd_versione,
				nr_riga
            FROM hcbi_ras.v_src_tmp_pubblicazione_analisi
            GROUP BY
                ds_anno_pubblicazione,
                cd_codice_analisi,
                cd_articolo,
                cd_versione,
				nr_riga
            HAVING COUNT(*) = 1
        ) AS u
            ON  u.ds_anno_pubblicazione IS NOT DISTINCT FROM f.ds_anno_pubblicazione
            AND u.cd_codice_analisi IS NOT DISTINCT FROM f.cd_codice_analisi
            AND u.cd_articolo IS NOT DISTINCT FROM f.cd_articolo
            AND u.cd_versione IS NOT DISTINCT FROM f.cd_versione
			 AND u.nr_riga IS NOT DISTINCT FROM f.nr_riga
			
    LOOP
        BEGIN
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
            VALUES (
                NULLIF(TRIM(rec.ds_anno_pubblicazione), '')::NUMERIC(10,0),
                TRIM(rec.cd_codice_analisi),
                NULLIF(
                    REPLACE(TRIM(rec.nr_quantita), ',', '.'),
                    ''
                )::NUMERIC(24,6),
                TRIM(rec.cd_articolo),
                NULLIF(TRIM(rec.cd_versione), '')::SMALLINT,
                NULLIF(
                    TRIM(rec.id_sorgente_pubblicazione_analisi),
                    ''
                )::BIGINT,
                NULLIF(
                    TRIM(rec.id_sorgente_categoria),
                    ''
                )::BIGINT,
				rec.nr_riga
            );

            v_selected := v_selected + 1;
            v_inserted := v_inserted + 1;

        EXCEPTION
            WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS v_sqlerrm = MESSAGE_TEXT;

                v_selected := v_selected + 1;
                v_rec_errors := v_rec_errors + 1;

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
                VALUES (
                    rec.ds_anno_pubblicazione,
                    rec.cd_codice_analisi,
                    rec.nr_quantita,
                    rec.cd_articolo,
                    rec.cd_versione,
                    rec.id_sorgente_pubblicazione_analisi,
                    rec.id_sorgente_categoria,
					rec.nr_riga,
                    v_sqlerrm
                );
        END;
    END LOOP;

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

    p_result := 1;

EXCEPTION
    WHEN OTHERS THEN
        v_sqlerrm := SQLSTATE || ': ' || SQLERRM;
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_sqlerrm,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_pubblicazione_analisi_prc_main. SQLSTATE=%, errore=%',
            SQLSTATE,
            SQLERRM;
END;
$procedure$
