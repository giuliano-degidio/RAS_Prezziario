CREATE OR REPLACE PROCEDURE hcbi_utility.test_p(IN p_id integer, INOUT p_result integer)
 LANGUAGE plpgsql
AS $procedure$
BEGIN
    p_result := -999;
END;
$procedure$
