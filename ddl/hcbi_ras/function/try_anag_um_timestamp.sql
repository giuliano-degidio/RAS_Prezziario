CREATE OR REPLACE FUNCTION hcbi_ras.try_anag_um_timestamp(p_value text)
 RETURNS timestamp without time zone
 LANGUAGE plpgsql
 IMMUTABLE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
BEGIN
    RETURN p_value::TIMESTAMP WITHOUT TIME ZONE;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN RETURN NULL;
END;
$function$
