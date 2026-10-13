CREATE OR REPLACE FUNCTION hcbi_ras.try_double_precision(p_value text)
 RETURNS double precision
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    RETURN p_value::double precision;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$
