CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text)
 RETURNS smallint
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$ BEGIN RETURN p_value::SMALLINT; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$function$
