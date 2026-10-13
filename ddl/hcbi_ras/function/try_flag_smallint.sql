CREATE OR REPLACE FUNCTION hcbi_ras.try_flag_smallint(p_value text)
 RETURNS smallint
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
 SET search_path TO 'pg_catalog'
AS $function$
    SELECT CASE lower(btrim(p_value))
        WHEN 'true' THEN 1::smallint WHEN 'false' THEN 0::smallint
        WHEN '1' THEN 1::smallint WHEN '0' THEN 0::smallint
        ELSE NULL::smallint END;
$function$
