CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_smallint(p_value text)
 RETURNS smallint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
SELECT CASE
    WHEN lower(btrim(p_value)) IN ('true','t','1','yes','y') THEN 1::smallint
    WHEN lower(btrim(p_value)) IN ('false','f','0','no','n') THEN 0::smallint
    ELSE NULL::smallint
END;
$function$
