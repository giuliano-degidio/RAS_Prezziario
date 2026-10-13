CREATE OR REPLACE FUNCTION hcbi_utility.dblink_get_pkey(text)
 RETURNS SETOF hcbi_utility.dblink_pkey_results
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_get_pkey$function$
