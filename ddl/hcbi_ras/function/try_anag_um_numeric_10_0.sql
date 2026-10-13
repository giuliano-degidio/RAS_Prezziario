CREATE OR REPLACE FUNCTION hcbi_ras.try_anag_um_numeric_10_0(p_value text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    RETURN p_value::NUMERIC(10,0);
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$
