CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text)
 RETURNS bigint
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN RETURN p_value::bigint;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;$function$
