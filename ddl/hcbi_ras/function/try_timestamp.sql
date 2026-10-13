CREATE OR REPLACE FUNCTION hcbi_ras.try_timestamp(p_value text)
 RETURNS timestamp without time zone
 LANGUAGE plpgsql
 STABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN RETURN p_value::timestamp;
EXCEPTION WHEN invalid_text_representation OR datetime_field_overflow THEN RETURN NULL;
END;$function$
