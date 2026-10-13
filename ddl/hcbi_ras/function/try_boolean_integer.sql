CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_integer(p_value text)
 RETURNS integer
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
 SET search_path TO 'pg_catalog'
AS $function$ SELECT CASE lower(btrim(p_value)) WHEN 'true' THEN 1 WHEN 't' THEN 1 WHEN '1' THEN 1 WHEN 'yes' THEN 1 WHEN 'y' THEN 1 WHEN 'false' THEN 0 WHEN 'f' THEN 0 WHEN '0' THEN 0 WHEN 'no' THEN 0 WHEN 'n' THEN 0 ELSE NULL::integer END; $function$
