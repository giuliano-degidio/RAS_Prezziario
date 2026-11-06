--Tabelle statiche
0)hcbi_ras.dim_periodo 
 caricata manualmente sino al 2026, va aggiornata ogni anno
1)hcbi_ras.dim_fascia_prezzo
  vedere create_popolate__dim_fascia_prezzo_all_ver_01.sql
2)hcbi_ras.dim_regione 
  tabella gestita da front end , probabilmente va aggiornata
3)hcbi_ras.frontiera_firenze_analisi
	caricati manualmente anni 2025 e 2026 
4)hcbi_ras.frontiera_firenze_articoli  
	caricati manualmente anni 2025 e 2026 
 

--DELETE FROM hcbi_ras.dim_fascia_prezzo WHERE id_fascia_prezzo NOT IN (-1, 0);   --TABELLA STATICA NON CANCELLARE I DATI 
--DELETE FROM hcbi_ras.dim_periodo WHERE id_periodo NOT IN (-1, 0);  --TABELLA STATICA NON CANCELLARE I DATI   
--DELETE FROM hcbi_ras.dim_regione -- WHERE id_regione NOT IN (-1, 0);    non ci sono tappi --TABELLA STATICA NON CANCELLARE I DATI

--TRUNCATE TABLE hcbi_ras.frontiera_anag_ateco_2002;   --TABELLA STATICA NON TRONCARE     
--TRUNCATE TABLE hcbi_ras.frontiera_firenze_analisi;   --TABELLA STATICA NON TRONCARE        
--TRUNCATE TABLE hcbi_ras.frontiera_firenze_articoli;  --TABELLA STATICA NON TRONCARE  