CREATE OR REPLACE FUNCTION hcbi_utility.dblink_fetch(text, text, integer)
 RETURNS SETOF record
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_fetch$function$
