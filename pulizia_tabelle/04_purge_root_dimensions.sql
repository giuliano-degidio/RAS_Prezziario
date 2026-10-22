
DELETE FROM hcbi_ras.dim_area_vasta WHERE id_anag_area_vasta NOT IN (-1, 0);            
DELETE FROM hcbi_ras.dim_ateco_2002 WHERE id_anag_ateco_2002 NOT IN (-1, 0);            
DELETE FROM hcbi_ras.dim_firenze_articoli WHERE id_firenze_articolo NOT IN (-1, 0);     
DELETE FROM hcbi_ras.dim_livello_codifica WHERE id_anag_livello_codifica NOT IN (-1, 0);
DELETE FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo NOT IN (-1, 0);        
--DELETE FROM hcbi_ras.dim_periodo WHERE id_periodo NOT IN (-1, 0);                       
DELETE FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura NOT IN (-1, 0);        
DELETE FROM hcbi_ras.dim_utenti WHERE id_anag_utente NOT IN (-1, 0);                    
