CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN RETURN p_value::integer;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;$function$
