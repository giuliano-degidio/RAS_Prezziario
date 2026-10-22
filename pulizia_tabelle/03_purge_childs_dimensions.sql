                                                                 
----------------------------------------------------------------------------------
DELETE FROM hcbi_ras.dim_articolo WHERE id_anag_articolo NOT IN (-1, 0);          
DELETE FROM hcbi_ras.dim_capitolo WHERE id_anag_capitolo NOT IN (-1, 0);          
DELETE FROM hcbi_ras.dim_informatori WHERE id_anag_informatore NOT IN (-1, 0);    
DELETE FROM hcbi_ras.dim_provincia WHERE id_anag_provincia NOT IN (-1, 0);        
DELETE FROM hcbi_ras.dim_sottocapitolo WHERE id_anag_sottocapitolo NOT IN (-1, 0);
DELETE FROM hcbi_ras.dim_tipologia WHERE id_anag_tipologia NOT IN (-1, 0);        
DELETE FROM hcbi_ras.dim_versione WHERE id_anag_versione NOT IN (-1, 0);          
