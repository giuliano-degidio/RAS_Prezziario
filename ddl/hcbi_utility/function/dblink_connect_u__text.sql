CREATE OR REPLACE FUNCTION hcbi_utility.dblink_connect_u(text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT SECURITY DEFINER
AS '$libdir/dblink', $function$dblink_connect$function$
