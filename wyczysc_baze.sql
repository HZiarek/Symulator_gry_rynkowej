--usuwanie tabel
DROP TABLE przynaleznosci_do_grup;
DROP TABLE oceny_marek;
DROP TABLE ustawienia_poczatkowe;
DROP TABLE dostepy_producentow_his_zakup;
DROP TABLE zakupy_konsumentow;
DROP TABLE marketingi;
DROP TABLE badania_rynku;
DROP TABLE grupy_konsumentow;
DROP TABLE historie_cen;
DROP TABLE magazynowania;
DROP TABLE koszty_magazynowania;
DROP TABLE koszty_marketingu;
DROP TABLE koszty_produkcji_produktow;
DROP TABLE produkcje;
DROP TABLE marki;
DROP TABLE jakosci_marek;
DROP TABLE numery_rund;
DROP TABLE konsumenci;
DROP TABLE producenci;

drop view badania_rynku_p;
drop view dostep_do_his_zakupow_p;
drop view historie_cen_p;
drop view magazynowanie_p;
drop view marketing_p;
drop view marki_na_rynku_p;
drop view marki_p;
drop view oceny_marek_p;
drop view producenci_p;
drop view produkcje_p;
drop view sprzedaz_p;
drop view sprzedaz_producentow_p;

drop procedure generuj_grupy_konsumentow;
drop procedure POTRAC_KOSZTY_MAGAZYNOWANIA;
drop procedure LICZ_PRZYCHOD;
drop procedure ROZPOCZNIJ_RUNDE;
drop procedure ROZPOCZNIJ_GRE;
drop procedure RESTART_PARAMETROW_PRODUCENTOW;
drop procedure RESTART_SEKWENCJI;
drop procedure WYCZYSC_TABELE;
drop procedure ZRESTARTUJ_SEKWENCJE;
drop procedure GENERUJ_KONSUMENTOW;
drop procedure WSTAW_DOMYSLNE_JAKOSCI_MAREK;
drop procedure ZREALIZUJ_ZAKUPY;
drop procedure OCEN_MARKE;
drop FUNCTION POLICZ_WYMIAR_MPO;
drop FUNCTION POLICZ_MPO_WYBRANE_WYMIARY;
drop procedure SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
drop procedure STWORZ_CZASOMIERZ;

--sekwencje
DROP SEQUENCE ID_BADANIA_RYNKU_SEQ;
DROP SEQUENCE ID_GRUPY_KONSUMENTOW_SEQ;
DROP SEQUENCE ID_MARKETINGU_SEQ;
DROP SEQUENCE ID_MARKI_SEQ;
DROP SEQUENCE ID_PRODUKCJI_SEQ;
DROP SEQUENCE NR_ZESTAWU_USTAWIEN_POCZ_SEQ;



