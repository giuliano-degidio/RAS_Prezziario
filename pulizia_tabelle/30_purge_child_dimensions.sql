BEGIN;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT *
        FROM (VALUES
            ('dim_articolo', 'id_anag_articolo'),
            ('dim_capitolo', 'id_anag_capitolo'),
            ('dim_informatori', 'id_anag_informatore'),
            ('dim_provincia', 'id_anag_provincia'),
            ('dim_sottocapitolo', 'id_anag_sottocapitolo'),
            ('dim_tipologia', 'id_anag_tipologia'),
            ('dim_versione', 'id_anag_versione')
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
/* query genera i DELETE come testo senza eseguirli
SELECT format(
           'DELETE FROM hcbi_ras.%I WHERE %I NOT IN (-1, 0);',
           table_name,
           pk_column
       ) AS sql_script
FROM (
    VALUES
        ('dim_articolo',       'id_anag_articolo'),
        ('dim_capitolo',       'id_anag_capitolo'),
        ('dim_informatori',    'id_anag_informatore'),
        ('dim_provincia',      'id_anag_provincia'),
        ('dim_sottocapitolo',  'id_anag_sottocapitolo'),
        ('dim_tipologia',      'id_anag_tipologia'),
        ('dim_versione',       'id_anag_versione')
) AS t(table_name, pk_column);
`
*/
