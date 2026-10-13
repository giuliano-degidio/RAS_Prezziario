CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_6(p_value text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN RETURN p_value::numeric(24,6);
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;$function$
