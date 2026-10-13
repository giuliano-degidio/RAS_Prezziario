CREATE OR REPLACE FUNCTION hcbi_utility.dblink_fdw_validator(options text[], catalog oid)
 RETURNS void
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/dblink', $function$dblink_fdw_validator$function$
