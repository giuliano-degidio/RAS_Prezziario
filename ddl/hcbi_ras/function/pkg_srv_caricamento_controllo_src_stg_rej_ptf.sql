CREATE OR REPLACE FUNCTION hcbi_ras.pkg_srv_caricamento_controllo_src_stg_rej_ptf()
 RETURNS TABLE(table_name_src character varying, count_src bigint, table_name_stg character varying, count_stg bigint, table_name_rej character varying, count_rej bigint, esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $function$
DECLARE
    rec record;

    v_last_load_date timestamp without time zone;

    v_count_src bigint;
    v_count_stg bigint;
    v_count_rej bigint;

    v_sql text;
BEGIN
    /* ================================================================
       Recupero del timestamp dell'ultimo caricamento del modulo RAS.

       In Oracle il package usa PLSQL_UNIT_OWNER per individuare
       dinamicamente lo schema proprietario. Nel porting lo schema
       Oracle HCBI_PS è sostituito dal modulo PostgreSQL HCBI_RAS.
       ================================================================ */

    SELECT
        max(l.dt_start)::timestamp(0)
    INTO
        v_last_load_date
    FROM hcbi_utility.srv_config_chain c
    JOIN hcbi_utility.log_chain l
      ON l.id_chain = c.id_chain
    WHERE c.ds_chain_name ILIKE '%HCBI_RAS%';


    /* ================================================================
       Individuazione dinamica degli oggetti.

       Vengono estratti i nomi logici eliminando:

           SRC_TMP_  dalla tabella sorgente
           STG_      dalla tabella staging
           STG_      e _REJ dalla tabella reject

       Esempio:

           src_tmp_anag_azienda
           stg_anag_azienda
           stg_anag_azienda_rej

       hanno tutti il nome logico:

           anag_azienda
       ================================================================ */

    FOR rec IN
        WITH object_inventory AS
        (
            SELECT
                t.tablename AS physical_table_name,

                CASE
                    WHEN t.tablename LIKE 'src\_tmp\_%' ESCAPE '\'
                    THEN substring(t.tablename FROM 9)
                END AS src_core_name,

                CASE
                    WHEN t.tablename LIKE 'stg\_%' ESCAPE '\'
                     AND t.tablename NOT LIKE '%\_rej' ESCAPE '\'
                    THEN substring(t.tablename FROM 5)
                END AS stg_core_name,

                CASE
                    WHEN t.tablename LIKE 'stg\_%\_rej' ESCAPE '\'
                    THEN substring(
                             t.tablename
                             FROM 5
                             FOR char_length(t.tablename) - 8
                         )
                END AS rej_core_name
            FROM pg_catalog.pg_tables t
            WHERE t.schemaname = 'hcbi_ras'
              AND
              (
                    t.tablename LIKE 'src\_tmp\_%' ESCAPE '\'
                 OR t.tablename LIKE 'stg\_%' ESCAPE '\'
              )
        ),
        normalized_inventory AS
        (
            SELECT
                physical_table_name,
                coalesce(
                    src_core_name,
                    stg_core_name,
                    rej_core_name
                ) AS core_name,

                CASE
                    WHEN src_core_name IS NOT NULL
                    THEN physical_table_name
                END AS src_table_name,

                CASE
                    WHEN stg_core_name IS NOT NULL
                    THEN physical_table_name
                END AS stg_table_name,

                CASE
                    WHEN rej_core_name IS NOT NULL
                    THEN physical_table_name
                END AS rej_table_name
            FROM object_inventory
        )
        SELECT
            n.core_name,

            max(n.src_table_name)
                FILTER (WHERE n.src_table_name IS NOT NULL)
                AS src_table_name,

            max(n.stg_table_name)
                FILTER (WHERE n.stg_table_name IS NOT NULL)
                AS stg_table_name,

            max(n.rej_table_name)
                FILTER (WHERE n.rej_table_name IS NOT NULL)
                AS rej_table_name

        FROM normalized_inventory n
        WHERE n.core_name IS NOT NULL
        GROUP BY n.core_name
        ORDER BY n.core_name
    LOOP
        v_count_src := NULL;
        v_count_stg := NULL;
        v_count_rej := NULL;

        /* ============================================================
           Conteggio SRC_TMP
           ============================================================ */

        IF rec.src_table_name IS NOT NULL THEN
            v_sql := format(
                'SELECT count(*) FROM %I.%I',
                'hcbi_ras',
                rec.src_table_name
            );

            EXECUTE v_sql
               INTO v_count_src;
        END IF;


        /* ============================================================
           Conteggio STG
           ============================================================ */

        IF rec.stg_table_name IS NOT NULL THEN
            v_sql := format(
                'SELECT count(*) FROM %I.%I',
                'hcbi_ras',
                rec.stg_table_name
            );

            EXECUTE v_sql
               INTO v_count_stg;
        END IF;


        /* ============================================================
           Conteggio STG_REJ

           Vengono conteggiati soltanto gli scarti prodotti a partire
           dall'ultimo caricamento della chain del modulo RAS.
           ============================================================ */

        IF rec.rej_table_name IS NOT NULL THEN

            /* Verifica della presenza della colonna dt_scarto. */
            IF EXISTS
            (
                SELECT 1
                FROM information_schema.columns c
                WHERE c.table_schema = 'hcbi_ras'
                  AND c.table_name = rec.rej_table_name
                  AND c.column_name = 'dt_scarto'
            ) THEN
                v_sql := format(
                    'SELECT count(*) ' ||
                    'FROM %I.%I r ' ||
                    'WHERE r.dt_scarto >= $1',
                    'hcbi_ras',
                    rec.rej_table_name
                );

                EXECUTE v_sql
                   INTO v_count_rej
                  USING v_last_load_date;

            ELSE
                /*
                 * La struttura standard Oracle delle reject prevede
                 * DT_SCARTO. Se la colonna non esiste, la tabella viene
                 * comunque mostrata, ma il conteggio reject e l'esito
                 * rimangono NULL.
                 */
                v_count_rej := NULL;

                RAISE WARNING
                    'La tabella hcbi_ras.% non contiene la colonna dt_scarto',
                    rec.rej_table_name;
            END IF;
        END IF;


        /* ============================================================
           Produzione della riga di risultato
           ============================================================ */

        table_name_src := rec.src_table_name;
        count_src      := v_count_src;

        table_name_stg := rec.stg_table_name;
        count_stg      := v_count_stg;

        table_name_rej := rec.rej_table_name;
        count_rej      := v_count_rej;


        /* ============================================================
           Calcolo dell'esito.

           L'esito è significativo soltanto quando esistono tutti
           gli elementi necessari alla quadratura.
           ============================================================ */

        IF rec.src_table_name IS NULL THEN
            /*
             * STG derivata senza SRC_TMP.
             */
            esito := NULL;

        ELSIF rec.stg_table_name IS NULL THEN
            /*
             * Caso anomalo: SRC_TMP presente ma STG mancante.
             */
            esito := NULL;

        ELSIF rec.rej_table_name IS NULL THEN
            /*
             * Caso senza tabella reject.
             * Il comportamento replica il package Oracle, che non
             * produce un esito quando uno degli elementi è assente.
             */
            esito := NULL;

        ELSIF v_count_rej IS NULL THEN
            /*
             * La reject esiste ma non può essere conteggiata, ad
             * esempio perché manca la colonna dt_scarto.
             */
            esito := NULL;

        ELSIF v_count_src = v_count_stg + v_count_rej THEN
            esito := 'OK';

        ELSE
            esito := 'KO';
        END IF;


        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$function$
