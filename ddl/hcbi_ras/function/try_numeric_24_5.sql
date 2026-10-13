CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_5(p_value text)
 RETURNS numeric
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$ BEGIN RETURN p_value::NUMERIC(24,5); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$function$
