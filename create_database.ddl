-- Generated by Oracle SQL Developer Data Modeler 18.3.0.268.1156
--   at:        2020-05-04 13:42:42 CEST
--   site:      Oracle Database 11g
--   type:      Oracle Database 11g



CREATE TABLE badanie_rynku (
    id_badania_rynku            NUMBER(6) NOT NULL,
    typ_badania_rynku_id_typu   NUMBER(3) NOT NULL,
    producent_id_producenta     NUMBER(3) NOT NULL,
    licznik_rund_numer_rundy    NUMBER(5) NOT NULL,
    liczba_klientow             NUMBER(10) NOT NULL,
    horyzont_czasowy            NUMBER(5) NOT NULL,
    koszt                       NUMBER(15) NOT NULL
);

ALTER TABLE badanie_rynku ADD CONSTRAINT badanie_rynku_pk PRIMARY KEY ( id_badania_rynku );

CREATE TABLE dostep_producenta_his_zakup (
    producent_id_producenta          NUMBER(3) NOT NULL,
    zakup_konsumenta_id_konsumenta   NUMBER(10) NOT NULL,
    zakup_konsumenta_numer_rundy     NUMBER(5) NOT NULL
);

ALTER TABLE dostep_producenta_his_zakup
    ADD CONSTRAINT dostep_producenta_his_zakup_pk PRIMARY KEY ( producent_id_producenta,
                                                                zakup_konsumenta_id_konsumenta,
                                                                zakup_konsumenta_numer_rundy );

CREATE TABLE historia_cen (
    cena                       NUMBER(5) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL,
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL
);

ALTER TABLE historia_cen ADD CONSTRAINT historia_cen_pk PRIMARY KEY ( marka_id_marki,
                                                                      licznik_rund_numer_rundy );

CREATE TABLE konsument (
    id_konsumenta                    NUMBER(10) NOT NULL,
    cena_poziom_aspiracji            NUMBER(5) NOT NULL,
    cena_poziom_rezerwacji           NUMBER(5) NOT NULL,
    cena_niezadowolenie              NUMBER(4, 2) NOT NULL,
    cena_zadowolenie                 NUMBER(4, 2) NOT NULL,
    jakosc_poziom_aspiracji          NUMBER(2) NOT NULL,
    jakosc_poziom_rezerwacji         NUMBER(2) NOT NULL,
    jakosc_niezadowolenie            NUMBER(4, 2) NOT NULL,
    jakosc_zadowolenie               NUMBER(4, 2) NOT NULL,
    przywiazanie_poziom_aspiracji    NUMBER(4, 2) NOT NULL,
    przywiazanie_poziom_rezerwacji   NUMBER(4, 2) NOT NULL,
    przywiazanie_niezadowolenie      NUMBER(4, 2) NOT NULL,
    przywiazanie_zadowolenie         NUMBER(4, 2) NOT NULL,
    podatnosc_na_marketing           NUMBER(2, 2) NOT NULL
);

ALTER TABLE konsument ADD CONSTRAINT konsument_pk PRIMARY KEY ( id_konsumenta );

CREATE TABLE koszt_magazynowania (
    nr_przedzialu   NUMBER(3) NOT NULL,
    koszt           NUMBER(5) NOT NULL
);

ALTER TABLE koszt_magazynowania ADD CONSTRAINT koszt_magazynowania_pk PRIMARY KEY ( nr_przedzialu );

CREATE TABLE licznik_rund (
    numer_rundy   NUMBER(5) NOT NULL
);

ALTER TABLE licznik_rund ADD CONSTRAINT licznik_rund_pk PRIMARY KEY ( numer_rundy );

CREATE TABLE magazynowanie (
    ilosc                      NUMBER(8) NOT NULL,
    koszt                      NUMBER(10) NOT NULL,
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL
);

ALTER TABLE magazynowanie ADD CONSTRAINT magazynowanie_pk PRIMARY KEY ( licznik_rund_numer_rundy,
                                                                        marka_id_marki );

CREATE TABLE marka (
    id_marki                     NUMBER(6) NOT NULL,
    cena_za_sztuke               NUMBER(5) NOT NULL,
    producent_id_producenta      NUMBER(3) NOT NULL,
    rodzaje_marek_jakosc_marki   NUMBER(2) NOT NULL,
    nazwa                        VARCHAR2(20 CHAR) NOT NULL,
    aktualna_liczba_sztuk        NUMBER(15) DEFAULT 0 NOT NULL,
    tymczasowa_ocena_klienta     NUMBER(15, 10)
);

ALTER TABLE marka ADD CONSTRAINT marka_pk PRIMARY KEY ( id_marki );

ALTER TABLE marka ADD CONSTRAINT marka_nazwa_un UNIQUE ( nazwa );

CREATE TABLE marketing (
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL,
    id_rodzaju_marketingu      NUMBER(2) NOT NULL,
    liczba_klientow            NUMBER(10) NOT NULL,
    koszt                      NUMBER(15) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL
);

ALTER TABLE marketing ADD CONSTRAINT marketing_pk PRIMARY KEY ( licznik_rund_numer_rundy,
                                                                marka_id_marki );

CREATE TABLE producent (
    id_producenta   NUMBER(3) NOT NULL,
    nazwa           VARCHAR2(30 CHAR) NOT NULL,
    fundusze        NUMBER(10) NOT NULL,
    czy_spasowal    CHAR(1 CHAR) DEFAULT 'n' NOT NULL
);

ALTER TABLE producent
    ADD CHECK ( czy_spasowal IN (
        'n',
        't'
    ) );

COMMENT ON COLUMN producent.czy_spasowal IS
    '''n'' - NIE
''t'' - TAK';

ALTER TABLE producent ADD CONSTRAINT producent_pk PRIMARY KEY ( id_producenta );

CREATE TABLE produkcja (
    ilosc                      NUMBER(10) NOT NULL,
    koszt                      NUMBER(10) NOT NULL,
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL
);

ALTER TABLE produkcja ADD CONSTRAINT produkcja_pk PRIMARY KEY ( licznik_rund_numer_rundy,
                                                                marka_id_marki );

CREATE TABLE przywiazanie_do_marki (
    konsument_id_konsumenta     NUMBER(10) NOT NULL,
    wspolczynnik_przywiazania   NUMBER(4, 2) NOT NULL,
    marka_id_marki              NUMBER(6) NOT NULL
);

ALTER TABLE przywiazanie_do_marki ADD CONSTRAINT przywiazanie_do_marki_pk PRIMARY KEY ( konsument_id_konsumenta,
                                                                                        marka_id_marki );

CREATE TABLE rodzaj_marketingu (
    id_rodzaju_marketingu      NUMBER(2) NOT NULL,
    koszt_staly                NUMBER(15) NOT NULL,
    koszta_per_klient          NUMBER(15) NOT NULL,
    wplyw_na_docelowa_marke    NUMBER(5, 3) NOT NULL,
    wplyw_na_inne_marki_prod   NUMBER(5, 3) NOT NULL
);

ALTER TABLE rodzaj_marketingu ADD CONSTRAINT rodzaj_marketingu_pk PRIMARY KEY ( id_rodzaju_marketingu );

CREATE TABLE rodzaje_marek (
    jakosc_marki             NUMBER(2) NOT NULL,
    koszt_utworzenia         NUMBER(5) NOT NULL,
    koszt_produkcji_sztuki   NUMBER(5) NOT NULL
);

ALTER TABLE rodzaje_marek ADD CONSTRAINT rodzaje_marek_pk PRIMARY KEY ( jakosc_marki );

CREATE TABLE sprzedaz (
    ilosc                      NUMBER(10) NOT NULL,
    przychod                   NUMBER(10) NOT NULL,
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL
);

ALTER TABLE sprzedaz ADD CONSTRAINT sprzedaz_pk PRIMARY KEY ( licznik_rund_numer_rundy,
                                                              marka_id_marki );

CREATE TABLE typ_badania_rynku (
    id_typu                      NUMBER(3) NOT NULL,
    koszt_bazowy                 NUMBER(15) NOT NULL,
    koszt_per_analizowany_wpis   NUMBER(13) NOT NULL,
    opis                         VARCHAR2(250 CHAR)
);

ALTER TABLE typ_badania_rynku ADD CONSTRAINT typ_badania_rynku_pk PRIMARY KEY ( id_typu );

CREATE TABLE ustawienia_poczatkowe (
    numer_opcji                     NUMBER(2) NOT NULL,
    liczba_konsumentow              NUMBER(10) NOT NULL,
    liczba_producentow              NUMBER(4),
    warunek_zakonczenia_rundy       CHAR(1 CHAR) NOT NULL,
    czas_rundy                      NUMBER(4),
    liczba_rund                     NUMBER(5),
    poczatkowe_fundusze             NUMBER(8) NOT NULL,
    zakup_wplyw_na_docelowa_marke   NUMBER(5, 3) NOT NULL,
    zakup_wplyw_na_inne_marki_pro   NUMBER(5, 3) NOT NULL,
    brak_zakupu_wplyw_na_marke      NUMBER(5, 3) NOT NULL,
    niezaspokojony_popyt_wplyw      NUMBER(5, 3) NOT NULL
);

COMMENT ON COLUMN ustawienia_poczatkowe.warunek_zakonczenia_rundy IS
    '''t'' - up�yn�� okre�lony czas
''m'' - wszyscy gracz wykonali ruch
''b'' - up�yn�� okre�lony czas lub wszyscy gracze wykonali ruch '
    ;

COMMENT ON COLUMN ustawienia_poczatkowe.czas_rundy IS
    'Czas w godzinach. Je�li jest wybrana opcja, w kt�rej warunkiem zako�czenia rundy jest ruch wszystkich graczy, w�wczas czas nie jest brany pod uwag�.'
    ;

COMMENT ON COLUMN ustawienia_poczatkowe.zakup_wplyw_na_docelowa_marke IS
    'Okresla jaki wplyw ma zakup produktu danej marki na wspolczynnik przywiazania konsumenta do tej marki.';

COMMENT ON COLUMN ustawienia_poczatkowe.zakup_wplyw_na_inne_marki_pro IS
    'Okresla jaki wplyw ma zakup produktu danej marki na wspolczynnik przywazania konsumenta do innych marek nalezacych do producenta zakupionej marki.'
    ;

COMMENT ON COLUMN ustawienia_poczatkowe.brak_zakupu_wplyw_na_marke IS
    'Okresla jaki wplyw ma niezakupinie produktu danej marki nawspolczynnik przywazania konsumenta do tej marki.';

COMMENT ON COLUMN ustawienia_poczatkowe.niezaspokojony_popyt_wplyw IS
    'Okresla jaki wplyw na wspolczynnik przywiazania konsumenta do danej marki ma niezaspokojenie popytu przez producenta, tzn sytuacja w ktorej konsument decyduje sie na zakup produktu, ale nie moze go nabyc.'
    ;

ALTER TABLE ustawienia_poczatkowe ADD CONSTRAINT ustawienia_poczatkowe_pk PRIMARY KEY ( numer_opcji );

CREATE TABLE zakup_konsumenta (
    licznik_rund_numer_rundy   NUMBER(5) NOT NULL,
    konsument_id_konsumenta    NUMBER(10) NOT NULL,
    marka_id_marki             NUMBER(6) NOT NULL
);

ALTER TABLE zakup_konsumenta ADD CONSTRAINT zakup_konsumenta_pk PRIMARY KEY ( konsument_id_konsumenta,
                                                                              licznik_rund_numer_rundy );

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta )
            ON DELETE CASCADE;

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_typ_bad_ryn_fk FOREIGN KEY ( typ_badania_rynku_id_typu )
        REFERENCES typ_badania_rynku ( id_typu )
            ON DELETE CASCADE;

ALTER TABLE dostep_producenta_his_zakup
    ADD CONSTRAINT dost_prod_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta );

ALTER TABLE dostep_producenta_his_zakup
    ADD CONSTRAINT dost_prod_zakup_konsumenta_fk FOREIGN KEY ( zakup_konsumenta_id_konsumenta,
                                                               zakup_konsumenta_numer_rundy )
        REFERENCES zakup_konsumenta ( konsument_id_konsumenta,
                                      licznik_rund_numer_rundy );

ALTER TABLE historia_cen
    ADD CONSTRAINT historia_cen_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE historia_cen
    ADD CONSTRAINT historia_cen_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE marka
    ADD CONSTRAINT marka_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta )
            ON DELETE CASCADE;

ALTER TABLE marka
    ADD CONSTRAINT marka_rodzaje_marek_fk FOREIGN KEY ( rodzaje_marek_jakosc_marki )
        REFERENCES rodzaje_marek ( jakosc_marki )
            ON DELETE CASCADE;

ALTER TABLE marketing
    ADD CONSTRAINT marketing_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE marketing
    ADD CONSTRAINT marketing_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE marketing
    ADD CONSTRAINT marketing_rodzaj_marketingu_fk FOREIGN KEY ( id_rodzaju_marketingu )
        REFERENCES rodzaj_marketingu ( id_rodzaju_marketingu )
            ON DELETE CASCADE;

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przyw_do_mar_konsument_fk FOREIGN KEY ( konsument_id_konsumenta )
        REFERENCES konsument ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzedaz_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzedaz_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki );

ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsum_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_konsument_fk FOREIGN KEY ( konsument_id_konsumenta )
        REFERENCES konsument ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_marka_fk FOREIGN KEY ( marka_id_marki )
        REFERENCES marka ( id_marki )
            ON DELETE CASCADE;

CREATE OR REPLACE TRIGGER fkntm_marka BEFORE
    UPDATE OF producent_id_producenta, rodzaje_marek_jakosc_marki ON marka
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKA is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_zakup_konsumenta BEFORE
    UPDATE OF konsument_id_konsumenta ON zakup_konsumenta
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table ZAKUP_KONSUMENTA is violated');
END;
/



-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                            18
-- CREATE INDEX                             0
-- ALTER TABLE                             66
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                           2
-- ALTER TRIGGER                            0
-- CREATE COLLECTION TYPE                   0
-- CREATE STRUCTURED TYPE                   0
-- CREATE STRUCTURED TYPE BODY              0
-- CREATE CLUSTER                           0
-- CREATE CONTEXT                           0
-- CREATE DATABASE                          0
-- CREATE DIMENSION                         0
-- CREATE DIRECTORY                         0
-- CREATE DISK GROUP                        0
-- CREATE ROLE                              0
-- CREATE ROLLBACK SEGMENT                  0
-- CREATE SEQUENCE                          0
-- CREATE MATERIALIZED VIEW                 0
-- CREATE MATERIALIZED VIEW LOG             0
-- CREATE SYNONYM                           0
-- CREATE TABLESPACE                        0
-- CREATE USER                              0
-- 
-- DROP TABLESPACE                          0
-- DROP DATABASE                            0
-- 
-- REDACTION POLICY                         0
-- 
-- ORDS DROP SCHEMA                         0
-- ORDS ENABLE SCHEMA                       0
-- ORDS ENABLE OBJECT                       0
-- 
-- ERRORS                                   0
-- WARNINGS                                 0
