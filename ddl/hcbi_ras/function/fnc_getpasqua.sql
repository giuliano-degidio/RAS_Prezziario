CREATE OR REPLACE FUNCTION hcbi_ras.fnc_getpasqua(p_anno integer)
 RETURNS date
 LANGUAGE plpgsql
AS $function$
	DECLARE
		a integer;
		b integer;
		c integer;
		d integer;
		e integer;
		f integer;
		g integer;
		h integer;
		i integer;
		j integer;
		k integer;
		l integer;
		m integer;
		mese integer;
		giorno integer;
	BEGIN
		a := mod(p_anno,19);
		b := trunc(p_anno / 100);
		c := mod(p_anno,100);
		d := trunc(b / 4);
		e := mod(b,4);
		f := trunc((b + 8) / 25);
		g := trunc((b - f + 1) / 3);
		h := mod((19 * a + b - d - g + 15),30);
		i := trunc(c / 4);
		j := mod(c,4);
		k := mod((32 + e + e + i + i - h - j),7);
		l := trunc((a + 11 * h + 22 * k) / 451);
		m := h + k - 7 * l + 114;

		giorno := mod(m,31) + 1;
		mese   := trunc(m / 31);

		RETURN make_date(p_anno, mese, giorno);
	END;
	$function$
