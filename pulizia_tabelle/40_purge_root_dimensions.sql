BEGIN;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT *
        FROM (VALUES
            ('dim_area_vasta', 'id_anag_area_vasta'),
            ('dim_ateco_2002', 'id_anag_ateco_2002'),
            ('dim_firenze_articoli', 'id_firenze_articolo'),
            ('dim_livello_codifica', 'id_anag_livello_codifica'),
            ('dim_macro_gruppo', 'id_anag_macro_gruppo'),
            ('dim_periodo', 'id_periodo'),
            ('dim_unita_misura', 'id_anag_unita_misura'),
            ('dim_utenti', 'id_anag_utente')
        ) AS t(table_name, pk_column)
    LOOP
        EXECUTE format(
            'DELETE FROM hcbi_ras.%I WHERE %I NOT IN (-1, 0)',
            r.table_name,
            r.pk_column
        );
    END LOOP;
END $$;

COMMIT;

/*genera i DELETE come testo, senza eseguirli
SELECT format(
           'DELETE FROM hcbi_ras.%I WHERE %I NOT IN (-1, 0);',
           table_name,
           pk_column
       ) AS sql_script
FROM (
    VALUES
        ('dim_area_vasta',          'id_anag_area_vasta'),
        ('dim_ateco_2002',          'id_anag_ateco_2002'),
        ('dim_firenze_articoli',    'id_firenze_articolo'),
        ('dim_livello_codifica',    'id_anag_livello_codifica'),
        ('dim_macro_gruppo',        'id_anag_macro_gruppo'),
        ('dim_periodo',             'id_periodo'),
        ('dim_unita_misura',        'id_anag_unita_misura'),
        ('dim_utenti',              'id_anag_utente')
) AS t(table_name, pk_column);
*/
