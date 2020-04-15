--dodawanie uprawnien dla graczy
--stworzenie odpowiedniej roli
CREATE ROLE SGR_GRACZ;
--przyznanie dostepu do tabel w ramach roli
grant INSERT, UPDATE, SELECT on "INZYNIERKA"."BADANIA_RYNKU" to "SGR_GRACZ" ;
grant SELECT on koszty_magazynowania to "SGR_GRACZ";
grant SELECT on zakupy_konsumentow to "SGR_GRACZ";
grant INSERT, SELECT on dzialania_marketingowe to "SGR_GRACZ" ;
grant INSERT, SELECT on badania_rynku to "SGR_GRACZ" ;
grant INSERT, SELECT on historie_cen to "SGR_GRACZ" ;
grant INSERT, SELECT on magazynowanie to "SGR_GRACZ" ;
grant INSERT, SELECT on produkcje to "SGR_GRACZ" ;
grant INSERT, SELECT on sprzedaze to "SGR_GRACZ" ;
grant INSERT, UPDATE, SELECT on marki to "SGR_GRACZ" ;
grant SELECT on rodzaje_marek to "SGR_GRACZ" ;
grant SELECT on rodzaje_marketingu to "SGR_GRACZ" ;
grant INSERT, UPDATE, SELECT on producenci to "SGR_GRACZ" ;

insert into producenci values (55, 'ALA', null);