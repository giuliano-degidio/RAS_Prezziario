CREATE OR REPLACE FUNCTION hcbi_utility.dblink_build_sql_update(text, int2vector, integer, text[], text[])
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_build_sql_update$function$
