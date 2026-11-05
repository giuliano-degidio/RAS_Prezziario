--TABELLE DWH ANAGRAFICHE
TRUNCATE TABLE hcbi_ras.dwh_anag_area_vasta;             
TRUNCATE TABLE hcbi_ras.dwh_anag_articolo;               
TRUNCATE TABLE hcbi_ras.dwh_anag_ateco_2002;             
TRUNCATE TABLE hcbi_ras.dwh_anag_capitolo;               
TRUNCATE TABLE hcbi_ras.dwh_anag_informatori;            
TRUNCATE TABLE hcbi_ras.dwh_anag_livello_codifica;       
TRUNCATE TABLE hcbi_ras.dwh_anag_macro_gruppo;           
TRUNCATE TABLE hcbi_ras.dwh_anag_provincia;              
TRUNCATE TABLE hcbi_ras.dwh_anag_sottocapitolo;          
TRUNCATE TABLE hcbi_ras.dwh_anag_tipo_utente;            
TRUNCATE TABLE hcbi_ras.dwh_anag_tipologia;              
TRUNCATE TABLE hcbi_ras.dwh_anag_unita_misura;           
TRUNCATE TABLE hcbi_ras.dwh_anag_utenti;                 
TRUNCATE TABLE hcbi_ras.dwh_anag_versione;
 
--TABELLE DWH FATTI            
TRUNCATE TABLE hcbi_ras.dwh_articoli_informatori;        
TRUNCATE TABLE hcbi_ras.dwh_firenze_analisi;             
TRUNCATE TABLE hcbi_ras.dwh_firenze_analisi_rej;   --rej supplementare dovuta a flusso proveniente da CSV che è sottoposto ad ulteriori raffinamenti      
TRUNCATE TABLE hcbi_ras.dwh_firenze_articoli;            
TRUNCATE TABLE hcbi_ras.dwh_firenze_articoli_rej;  --rej supplementare dovuta a flusso proveniente da CSV che è sottoposto ad ulteriori raffinamenti       
TRUNCATE TABLE hcbi_ras.dwh_prezzi_approvati;            
TRUNCATE TABLE hcbi_ras.dwh_prezzi_rilevati;             
TRUNCATE TABLE hcbi_ras.dwh_pubblicazione_albero;        
TRUNCATE TABLE hcbi_ras.dwh_pubblicazione_analisi;       
TRUNCATE TABLE hcbi_ras.dwh_pubblicazione_articoli; 

--TABELLE FATTI                                                         
TRUNCATE TABLE hcbi_ras.fct_articoli_informatori;                      
TRUNCATE TABLE hcbi_ras.fct_firenze_analisi;                           
TRUNCATE TABLE hcbi_ras.fct_prezzi_approvati;                           
TRUNCATE TABLE hcbi_ras.fct_prezzi_rilevati;                            
TRUNCATE TABLE hcbi_ras.fct_pubblicazione_albero;                       
TRUNCATE TABLE hcbi_ras.fct_pubblicazione_analisi;                      
--TRUNCATE TABLE hcbi_ras.fct_pubblicazione_articoli;  
DELETE FROM hcbi_ras.fct_pubblicazione_articoli; -- delete perchè è referenziata da una fk di fct_pubblicazione_articoli_fascia_prezzo
--TRUNCATE TABLE hcbi_ras.fct_output_match; --TABELLA GESTITA LATO FRONT END    NON TRONCARE                  
		  

--TABELLE DI FRONTIERA                                                  
TRUNCATE TABLE hcbi_ras.frontiera_anag_area_vasta;                      
TRUNCATE TABLE hcbi_ras.frontiera_anag_articolo;                               
TRUNCATE TABLE hcbi_ras.frontiera_anag_informatori;                            
TRUNCATE TABLE hcbi_ras.frontiera_anag_livello_codifica;                       
TRUNCATE TABLE hcbi_ras.frontiera_anag_macro_gruppo;                           
TRUNCATE TABLE hcbi_ras.frontiera_anag_provincia;                              
TRUNCATE TABLE hcbi_ras.frontiera_anag_unita_misura;                           
TRUNCATE TABLE hcbi_ras.frontiera_anag_utenti;                                 
TRUNCATE TABLE hcbi_ras.frontiera_anni;                                        
TRUNCATE TABLE hcbi_ras.frontiera_articoli_informatori;                        
TRUNCATE TABLE hcbi_ras.frontiera_prezzi_approvati;                            
TRUNCATE TABLE hcbi_ras.frontiera_prezzi_rilevati;                             
TRUNCATE TABLE hcbi_ras.frontiera_pubblicazione_albero;  
TRUNCATE TABLE hcbi_ras.frontiera_pubblicazione_analisi; 
TRUNCATE TABLE hcbi_ras.frontiera_pubblicazione_articoli;
--TRUNCATE TABLE hcbi_ras.frontiera_anag_ateco_2002;   --TABELLA STATICA NON TRONCARE     
--TRUNCATE TABLE hcbi_ras.frontiera_firenze_analisi;   --TABELLA STATICA NON TRONCARE        
--TRUNCATE TABLE hcbi_ras.frontiera_firenze_articoli;  --TABELLA STATICA NON TRONCARE  

--TABELLE TEMPORANEE
TRUNCATE TABLE hcbi_ras.src_tmp_anag_area_vasta;         
TRUNCATE TABLE hcbi_ras.src_tmp_anag_articolo;           
TRUNCATE TABLE hcbi_ras.src_tmp_anag_ateco_2002;         
TRUNCATE TABLE hcbi_ras.src_tmp_anag_capitolo_vw;        
TRUNCATE TABLE hcbi_ras.src_tmp_anag_informatori;        
TRUNCATE TABLE hcbi_ras.src_tmp_anag_livello_codifica;   
TRUNCATE TABLE hcbi_ras.src_tmp_anag_macro_gruppo;       
TRUNCATE TABLE hcbi_ras.src_tmp_anag_provincia;          
TRUNCATE TABLE hcbi_ras.src_tmp_anag_sottocapitolo_vw;   
TRUNCATE TABLE hcbi_ras.src_tmp_anag_tipo_utente;        
TRUNCATE TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw;     
TRUNCATE TABLE hcbi_ras.src_tmp_anag_tipologia_vw;       
TRUNCATE TABLE hcbi_ras.src_tmp_anag_unita_misura;       
TRUNCATE TABLE hcbi_ras.src_tmp_anag_utenti;             
TRUNCATE TABLE hcbi_ras.src_tmp_anag_versione;           
TRUNCATE TABLE hcbi_ras.src_tmp_articoli_informatori;    
TRUNCATE TABLE hcbi_ras.src_tmp_firenze_analisi;         
TRUNCATE TABLE hcbi_ras.src_tmp_firenze_articoli;        
TRUNCATE TABLE hcbi_ras.src_tmp_prezzi_approvati;        
TRUNCATE TABLE hcbi_ras.src_tmp_prezzi_rilevati;         
TRUNCATE TABLE hcbi_ras.src_tmp_pubblicazione_albero;    
TRUNCATE TABLE hcbi_ras.src_tmp_pubblicazione_analisi;   
TRUNCATE TABLE hcbi_ras.src_tmp_pubblicazione_articoli;  

--TABELLE DI SERVIZIO
--TRUNCATE TABLE hcbi_ras.srv_controlli -- Tabella di servizio controlli; Attualmente non utilizzata

--TABELLE DI STAGING
TRUNCATE TABLE hcbi_ras.stg_anag_area_vasta;                      
TRUNCATE TABLE hcbi_ras.stg_anag_area_vasta_rej;                  
TRUNCATE TABLE hcbi_ras.stg_anag_articolo;                        
TRUNCATE TABLE hcbi_ras.stg_anag_articolo_rej;                    
TRUNCATE TABLE hcbi_ras.stg_anag_ateco_2002;                      
TRUNCATE TABLE hcbi_ras.stg_anag_ateco_2002_rej;                  
TRUNCATE TABLE hcbi_ras.stg_anag_capitolo;                        
TRUNCATE TABLE hcbi_ras.stg_anag_capitolo_rej;                    
TRUNCATE TABLE hcbi_ras.stg_anag_informatori;                     
TRUNCATE TABLE hcbi_ras.stg_anag_informatori_rej;                 
TRUNCATE TABLE hcbi_ras.stg_anag_livello_codifica;                
TRUNCATE TABLE hcbi_ras.stg_anag_livello_codifica_rej;            
TRUNCATE TABLE hcbi_ras.stg_anag_macro_gruppo;                    
TRUNCATE TABLE hcbi_ras.stg_anag_macro_gruppo_rej;                
TRUNCATE TABLE hcbi_ras.stg_anag_provincia;                       
TRUNCATE TABLE hcbi_ras.stg_anag_provincia_rej;                   
TRUNCATE TABLE hcbi_ras.stg_anag_sottocapitolo;                   
TRUNCATE TABLE hcbi_ras.stg_anag_sottocapitolo_rej;               
TRUNCATE TABLE hcbi_ras.stg_anag_tipo_utente;                     
TRUNCATE TABLE hcbi_ras.stg_anag_tipo_utente_rej;                 
TRUNCATE TABLE hcbi_ras.stg_anag_tipologia;                       
TRUNCATE TABLE hcbi_ras.stg_anag_tipologia_rej;                   
TRUNCATE TABLE hcbi_ras.stg_anag_unita_misura;                    
TRUNCATE TABLE hcbi_ras.stg_anag_unita_misura_rej;                
TRUNCATE TABLE hcbi_ras.stg_anag_utenti;                          
TRUNCATE TABLE hcbi_ras.stg_anag_utenti_rej;                      
TRUNCATE TABLE hcbi_ras.stg_anag_versione;                        
TRUNCATE TABLE hcbi_ras.stg_anag_versione_rej;                    
TRUNCATE TABLE hcbi_ras.stg_articoli_informatori;                 
TRUNCATE TABLE hcbi_ras.stg_articoli_informatori_rej;             
TRUNCATE TABLE hcbi_ras.stg_firenze_analisi;                      
TRUNCATE TABLE hcbi_ras.stg_firenze_analisi_rej;                  
TRUNCATE TABLE hcbi_ras.stg_firenze_articoli;                     
TRUNCATE TABLE hcbi_ras.stg_firenze_articoli_rej;                 
TRUNCATE TABLE hcbi_ras.stg_prezzi_approvati;                     
TRUNCATE TABLE hcbi_ras.stg_prezzi_approvati_rej;                 
TRUNCATE TABLE hcbi_ras.stg_prezzi_rilevati;                      
TRUNCATE TABLE hcbi_ras.stg_prezzi_rilevati_rej;                  
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_albero;                 
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_albero_rej;             
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_analisi;                
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_analisi_rej;            
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_articoli;               
TRUNCATE TABLE hcbi_ras.stg_pubblicazione_articoli_rej;           

--TABELLE DIMENSIONALI APPLICARE DELETE per conservare i tappi
DELETE FROM hcbi_ras.dim_articolo WHERE id_anag_articolo NOT IN (-1, 0);           
DELETE FROM hcbi_ras.dim_capitolo WHERE id_anag_capitolo NOT IN (-1, 0);       
DELETE FROM hcbi_ras.dim_informatori WHERE id_anag_informatore NOT IN (-1, 0); 
DELETE FROM hcbi_ras.dim_sottocapitolo WHERE id_anag_sottocapitolo NOT IN (-1, 0); 
DELETE FROM hcbi_ras.dim_tipologia WHERE id_anag_tipologia NOT IN (-1, 0); 
DELETE FROM hcbi_ras.dim_versione WHERE id_anag_versione NOT IN (-1, 0);   
DELETE FROM hcbi_ras.dim_provincia WHERE id_anag_provincia NOT IN (-1, 0);                
                                                                                     
                                                                                
-- TABELLE DIMENSIONALI ROOT APPLICARE DELETE per conservare i tappi
DELETE FROM hcbi_ras.dim_area_vasta WHERE id_anag_area_vasta NOT IN (-1, 0);            
DELETE FROM hcbi_ras.dim_ateco_2002 WHERE id_anag_ateco_2002 NOT IN (-1, 0);  
--DELETE FROM hcbi_ras.dim_fascia_prezzo WHERE id_fascia_prezzo NOT IN (-1, 0);   --TABELLA STATICA NON CANCELLARE I DATI             
DELETE FROM hcbi_ras.dim_firenze_articoli WHERE id_firenze_articolo NOT IN (-1, 0);     
DELETE FROM hcbi_ras.dim_livello_codifica WHERE id_anag_livello_codifica NOT IN (-1, 0);
DELETE FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo NOT IN (-1, 0);        
--DELETE FROM hcbi_ras.dim_periodo WHERE id_periodo NOT IN (-1, 0);  --TABELLA STATICA NON CANCELLARE I DATI   
--DELETE FROM hcbi_ras.dim_regione -- WHERE id_regione NOT IN (-1, 0);    non ci sono tappi --TABELLA STATICA NON CANCELLARE I DATI                       
DELETE FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura NOT IN (-1, 0);        
DELETE FROM hcbi_ras.dim_utenti WHERE id_anag_utente NOT IN (-1, 0);                                                                                

--TABELLE DI LOG  AUTENTICARSI COME hcbi_utility
TRUNCATE TABLE hcbi_utility.dwh_schedule_run;
TRUNCATE TABLE hcbi_utility.etl_dwh_refresh_run;
TRUNCATE TABLE hcbi_utility.etl_execution_log_event;
DELETE FROM hcbi_utility.etl_execution_log_ingestion;--delete perchè la etl_execution_log_event ha una fk su questa tabella
TRUNCATE TABLE hcbi_utility.etl_frontiere_execution_lock;--dovrebbe essere sempre vuota
DELETE FROM hcbi_utility.etl_frontiere_run; --delete perchè la etl_frontiere_execution_lock ha una fk su questa tabella
TRUNCATE TABLE hcbi_utility.log_chain;
TRUNCATE TABLE hcbi_utility.log_step;   
                                                                               
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                



