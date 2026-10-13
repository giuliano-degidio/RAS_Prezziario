CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_copy_data_src_dynamic_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    rec record;

    v_id_log bigint;

    v_source_name_original text;
    v_target_name_original text;

    v_source_name_normalized text;
    v_target_name_normalized text;

    v_source_parts text[];
    v_target_parts text[];

    v_source_schema text;
    v_source_table  text;

    v_target_schema text;
    v_target_table  text;

    v_source_qualified text;
    v_target_qualified text;

    v_target_regclass regclass;

    v_sql text;

    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_errors   bigint := 0;

    v_error_message text;
BEGIN
    /*
     * La procedura parte in stato positivo.
     * Un errore su almeno una tabella imposta p_result a -1.
     */
    p_result := 1;

    FOR rec IN
        SELECT
            ds_source_name,
            ds_target_tmp_table
        FROM hcbi_utility.srv_metadata_copy_src
        WHERE fl_active = 'Y'
          AND id_chain = p_id_chain
        ORDER BY id_config
    LOOP
        v_id_log := NULL;
        v_selected := 0;
        v_inserted := 0;

        BEGIN
            /*
             * Conservazione dei valori configurati originali.
             */
            v_source_name_original := btrim(rec.ds_source_name);
            v_target_name_original := btrim(rec.ds_target_tmp_table);

            IF v_source_name_original IS NULL
               OR v_source_name_original = '' THEN
                RAISE EXCEPTION
                    'DS_SOURCE_NAME non valorizzato per ID_CHAIN %',
                    p_id_chain;
            END IF;

            IF v_target_name_original IS NULL
               OR v_target_name_original = '' THEN
                RAISE EXCEPTION
                    'DS_TARGET_TMP_TABLE non valorizzato per ID_CHAIN %',
                    p_id_chain;
            END IF;

            /*
             * Sostituzione obbligatoria dello schema Oracle HCBI_PS
             * con lo schema PostgreSQL hcbi_ras.
             *
             * I nomi vengono trasformati in lowercase secondo le
             * convenzioni stabilite per il progetto.
             */
            v_source_name_normalized :=
                lower
                (
                    regexp_replace
                    (
                        v_source_name_original,
                        '^HCBI_PS\.',
                        'hcbi_ras.',
                        'i'
                    )
                );

            v_target_name_normalized :=
                lower
                (
                    regexp_replace
                    (
                        v_target_name_original,
                        '^HCBI_PS\.',
                        'hcbi_ras.',
                        'i'
                    )
                );

            /*
             * Scomposizione sicura dei nomi degli oggetti.
             *
             * Sono ammessi:
             *
             *   nome_tabella
             *   schema.nome_tabella
             */
            v_source_parts :=
                pg_catalog.parse_ident
                (
                    v_source_name_normalized,
                    true
                );

            v_target_parts :=
                pg_catalog.parse_ident
                (
                    v_target_name_normalized,
                    true
                );

            /*
             * Determinazione dello schema e della tabella sorgente.
             */
            IF cardinality(v_source_parts) = 1 THEN
                v_source_schema := 'hcbi_ras';
                v_source_table  := v_source_parts[1];

            ELSIF cardinality(v_source_parts) = 2 THEN
                v_source_schema := v_source_parts[1];
                v_source_table  := v_source_parts[2];

            ELSE
                RAISE EXCEPTION
                    'Nome sorgente non valido: %',
                    v_source_name_original;
            END IF;

            /*
             * Determinazione dello schema e della tabella target.
             */
            IF cardinality(v_target_parts) = 1 THEN
                v_target_schema := 'hcbi_ras';
                v_target_table  := v_target_parts[1];

            ELSIF cardinality(v_target_parts) = 2 THEN
                v_target_schema := v_target_parts[1];
                v_target_table  := v_target_parts[2];

            ELSE
                RAISE EXCEPTION
                    'Nome target non valido: %',
                    v_target_name_original;
            END IF;

            /*
             * Protezione dello schema target.
             *
             * Il package PostgreSQL può creare o caricare oggetti
             * esclusivamente nello schema hcbi_ras.
             */
            IF v_target_schema <> 'hcbi_ras' THEN
                RAISE EXCEPTION
                    'Schema target non consentito: %. Lo schema previsto è hcbi_ras',
                    v_target_schema;
            END IF;

            /*
             * Costruzione dei nomi qualificati SQL con quoting sicuro.
             */
            v_source_qualified :=
                format
                (
                    '%I.%I',
                    v_source_schema,
                    v_source_table
                );

            v_target_qualified :=
                format
                (
                    '%I.%I',
                    v_target_schema,
                    v_target_table
                );

            /*
             * Verifica dell'esistenza della sorgente.
             *
             * to_regclass restituisce NULL se la relazione non esiste.
             */
            IF to_regclass(v_source_qualified) IS NULL THEN
                RAISE EXCEPTION
                    'La sorgente configurata % non esiste',
                    v_source_qualified;
            END IF;

            /*
             * Apertura del log relativo alla singola tabella target.
             */
            SELECT hcbi_utility.pkg_log_fnc_insert_log
            (
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
             * Conteggio delle righe sorgenti.
             */
            v_sql :=
                format
                (
                    'SELECT count(*) FROM %s',
                    v_source_qualified
                );

            EXECUTE v_sql
               INTO v_selected;

            /*
             * Ricerca della tabella target.
             */
            v_target_regclass := to_regclass(v_target_qualified);

            IF v_target_regclass IS NULL THEN
                /*
                 * Prima esecuzione:
                 * creazione della tabella target tramite CTAS.
                 */
                v_sql :=
                    format
                    (
                        'CREATE TABLE %s AS ' ||
                        'SELECT * FROM %s',
                        v_target_qualified,
                        v_source_qualified
                    );

                RAISE NOTICE '%', v_sql;

                EXECUTE v_sql;

                GET DIAGNOSTICS v_inserted = ROW_COUNT;

                /*
                 * Assegnazione dell'owner anche alle SRC_TMP_*
                 * create dinamicamente.
                 */
                v_sql :=
                    format
                    (
                        'ALTER TABLE %s OWNER TO hcbi_ras',
                        v_target_qualified
                    );

                EXECUTE v_sql;

                RAISE NOTICE
                    'Tabella % creata con % righe provenienti da %',
                    v_target_qualified,
                    v_inserted,
                    v_source_qualified;

            ELSE
                /*
                 * Esecuzioni successive:
                 * si mantiene la tabella esistente per non eliminare
                 * le viste PostgreSQL che dipendono da essa.
                 */
                v_sql :=
                    format
                    (
                        'TRUNCATE TABLE %s',
                        v_target_qualified
                    );

                RAISE NOTICE '%', v_sql;

                EXECUTE v_sql;

                v_sql :=
                    format
                    (
                        'INSERT INTO %s ' ||
                        'SELECT * FROM %s',
                        v_target_qualified,
                        v_source_qualified
                    );

                RAISE NOTICE '%', v_sql;

                EXECUTE v_sql;

                GET DIAGNOSTICS v_inserted = ROW_COUNT;

                /*
                 * L'owner viene comunque riallineato ad ogni esecuzione.
                 */
                v_sql :=
                    format
                    (
                        'ALTER TABLE %s OWNER TO hcbi_ras',
                        v_target_qualified
                    );

                EXECUTE v_sql;

                RAISE NOTICE
                    'Tabella % ricaricata con % righe provenienti da %',
                    v_target_qualified,
                    v_inserted,
                    v_source_qualified;
            END IF;

            /*
             * Chiusura positiva del log.
             */
            CALL hcbi_utility.pkg_log_prc_update_log
            (
                v_id_log,
                v_selected,
                v_inserted,
                0,
                0,
                0,
                'SUCCESS',
                clock_timestamp()::timestamp,
                p_ds_step_name
            );

        EXCEPTION
            WHEN OTHERS THEN
                p_result := -1;
                v_errors := v_errors + 1;

                v_error_message :=
                    coalesce(v_target_name_original, '<target non definito>')
                    || ': '
                    || SQLSTATE
                    || ': '
                    || SQLERRM;

                RAISE WARNING
                    'Errore nella copia da % a %. SQLSTATE=%, errore=%',
                    coalesce(v_source_name_original, '<sorgente non definita>'),
                    coalesce(v_target_name_original, '<target non definito>'),
                    SQLSTATE,
                    SQLERRM;

                IF v_id_log IS NOT NULL THEN
                    BEGIN
                        CALL hcbi_utility.pkg_log_prc_error_update_log
                        (
                            v_id_log,
                            'FAILED',
                            left(v_error_message, 4000),
                            clock_timestamp()::timestamp,
                            p_ds_step_name
                        );
                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE WARNING
                                'Errore durante la registrazione del log per %: %',
                                coalesce(
                                    v_target_name_original,
                                    '<target non definito>'
                                ),
                                SQLERRM;
                    END;
                END IF;
        END;
    END LOOP;

    IF v_errors = 0 THEN
        p_result := 1;
    ELSE
        p_result := -1;
    END IF;
END;
$procedure$
