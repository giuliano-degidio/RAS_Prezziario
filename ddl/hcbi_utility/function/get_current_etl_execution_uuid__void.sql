CREATE OR REPLACE FUNCTION hcbi_utility.get_current_etl_execution_uuid()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $function$
DECLARE
    c_zero_uuid constant uuid := '00000000-0000-0000-0000-000000000000'::uuid;
    v_execution_uuid uuid := c_zero_uuid;
    v_run_table regclass;
    v_structure_valid boolean := false;
BEGIN
    ----------------------------------------------------------------------
    -- Verifica l'esistenza della tabella delle esecuzioni DWH.
    ----------------------------------------------------------------------
    v_run_table := to_regclass('hcbi_utility.etl_dwh_refresh_run');

    IF v_run_table IS NULL THEN
        RAISE WARNING
            'Tabella hcbi_utility.etl_dwh_refresh_run non trovata: restituito UUID zero';
        RETURN c_zero_uuid;
    END IF;

    ----------------------------------------------------------------------
    -- Verifica le colonne necessarie e i relativi tipi.
    ----------------------------------------------------------------------
    SELECT count(*) = 4
      INTO v_structure_valid
      FROM pg_catalog.pg_attribute a
     WHERE a.attrelid = v_run_table
       AND a.attnum > 0
       AND NOT a.attisdropped
       AND (
            (a.attname = 'run_id'
             AND a.atttypid = 'pg_catalog.int8'::regtype)
         OR (a.attname = 'execution_uuid'
             AND a.atttypid = 'pg_catalog.uuid'::regtype)
         OR (a.attname = 'ended_at'
             AND a.atttypid = 'pg_catalog.timestamptz'::regtype)
         OR (a.attname = 'status'
             AND a.atttypid IN (
                 'pg_catalog.varchar'::regtype,
                 'pg_catalog.text'::regtype,
                 'pg_catalog.bpchar'::regtype
             ))
       );

    IF NOT v_structure_valid THEN
        RAISE WARNING
            'Struttura di hcbi_utility.etl_dwh_refresh_run non valida: restituito UUID zero';
        RETURN c_zero_uuid;
    END IF;

    ----------------------------------------------------------------------
    -- Recupera l'UUID dell'ultima esecuzione DWH ancora RUNNING.
    ----------------------------------------------------------------------
    EXECUTE
        'SELECT execution_uuid
           FROM hcbi_utility.etl_dwh_refresh_run
          WHERE ended_at IS NULL
            AND status = $1
          ORDER BY run_id DESC
          LIMIT 1'
       INTO v_execution_uuid
      USING 'RUNNING';

    RETURN COALESCE(v_execution_uuid, c_zero_uuid);

EXCEPTION
    ----------------------------------------------------------------------
    -- La funzione e' non bloccante: qualsiasi errore restituisce UUID zero.
    ----------------------------------------------------------------------
    WHEN OTHERS THEN
        RAISE WARNING
            'Errore nel recupero dell''execution_uuid DWH. SQLSTATE=%, SQLERRM=%. Restituito UUID zero',
            SQLSTATE,
            SQLERRM;
        RETURN c_zero_uuid;
END;
$function$
