-- Generated by Oracle SQL Developer Data Modeler 18.3.0.268.1156
--   at:        2019-06-03 23:29:10 CEST
--   site:      Oracle Database 11g
--   type:      Oracle Database 11g



CREATE TABLE badanie_rynku (
    producent_id_producenta    NUMBER(1, 8) NOT NULL,
    licznik_rund_numer_rundy   NUMBER(1, 2) NOT NULL
);

ALTER TABLE badanie_rynku ADD CONSTRAINT badanie_rynku_pk PRIMARY KEY ( producent_id_producenta,
                                                                        licznik_rund_numer_rundy );

CREATE TABLE konsument (
    id_konsumenta                    NUMBER(1, 8) NOT NULL,
    cena_poziom_aspiracji            NUMBER(2, 5) NOT NULL,
    cena_poziom_rezerwacji           NUMBER(2, 5) NOT NULL,
    jakosc_poziom_aspiracji          NUMBER(1, 3) NOT NULL,
    jakosc_poziom_rezerwacji         NUMBER(1, 3) NOT NULL,
    przywiazanie_poziom_aspiracji    NUMBER(4, 4) NOT NULL,
    przywiazanie_poziom_rezerwacji   NUMBER(4, 4) NOT NULL
);

ALTER TABLE konsument ADD CONSTRAINT konsument_pk PRIMARY KEY ( id_konsumenta );

CREATE TABLE koszt_magazynowania (
    nr_przedzialu   NUMBER(1, 4) NOT NULL,
    koszt           NUMBER(2, 10) NOT NULL
);

ALTER TABLE koszt_magazynowania ADD CONSTRAINT koszt_magazynowania_pk PRIMARY KEY ( nr_przedzialu );

CREATE TABLE licznik_rund (
    numer_rundy   NUMBER(1, 2) NOT NULL
);

ALTER TABLE licznik_rund ADD CONSTRAINT licznik_rund_pk PRIMARY KEY ( numer_rundy );

CREATE TABLE magazynowanie (
    ilosc           NUMBER(1, 12) NOT NULL,
    koszt           NUMBER(2, 12) NOT NULL,
    id_producenta   NUMBER(1, 8) NOT NULL,
    jakosc_marki    NUMBER(1, 3) NOT NULL,
    numer_rundy     NUMBER(1, 2) NOT NULL
);

ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_pk PRIMARY KEY ( id_producenta,
                                                  jakosc_marki,
                                                  numer_rundy );

CREATE TABLE marketing (
    id_producenta           NUMBER(1, 8) NOT NULL,
    jakosc_marki            NUMBER(1, 3) NOT NULL,
    numer_rundy             NUMBER(1, 2) NOT NULL,
    id_rodzaju_marketingu   NUMBER(1, 10) NOT NULL
);

ALTER TABLE marketing
    ADD CONSTRAINT marketing_pk PRIMARY KEY ( id_producenta,
                                              jakosc_marki,
                                              numer_rundy );

CREATE TABLE producent (
    id_producenta   NUMBER(1, 8) NOT NULL,
    fundusze        NUMBER(2, 12) NOT NULL
);

ALTER TABLE producent ADD CONSTRAINT producent_pk PRIMARY KEY ( id_producenta );

CREATE TABLE produkcja (
    ilosc           NUMBER(1, 12) NOT NULL,
    koszt           NUMBER(2, 12) NOT NULL,
    id_producenta   NUMBER(1, 8) NOT NULL,
    jakosc_marki    NUMBER(1, 3) NOT NULL,
    numer_rundy     NUMBER(1, 2) NOT NULL
);

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_pk PRIMARY KEY ( id_producenta,
                                              jakosc_marki,
                                              numer_rundy );

CREATE TABLE przywiazanie_do_marki (
    id_konsumenta               NUMBER(1, 8) NOT NULL,
    id_producenta               NUMBER(1, 8) NOT NULL,
    jakosc_marki                NUMBER(1, 3) NOT NULL,
    wspolczynnik_przywiazania   NUMBER(4, 4) NOT NULL
);

ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_pk PRIMARY KEY ( id_producenta,
                                                          jakosc_marki,
                                                          id_konsumenta );

CREATE TABLE rodzaj_marketingu (
    id_rodzaju_marketingu   NUMBER(1, 10) NOT NULL
);

ALTER TABLE rodzaj_marketingu ADD CONSTRAINT rodzaj_marketingu_pk PRIMARY KEY ( id_rodzaju_marketingu );

CREATE TABLE rodzaje_marek (
    jakosc_marki             NUMBER(1, 3) NOT NULL,
    koszt_utworzenia         NUMBER(2, 6) NOT NULL,
    koszt_produkcji_sztuki   NUMBER(2, 6) NOT NULL
);

ALTER TABLE rodzaje_marek ADD CONSTRAINT rodzaje_marek_pk PRIMARY KEY ( jakosc_marki );

CREATE TABLE sprzedaz (
    ilosc           NUMBER(1, 12) NOT NULL,
    przych�d        NUMBER(2, 12) NOT NULL,
    id_producenta   NUMBER(1, 8) NOT NULL,
    jakosc_marki    NUMBER(1, 3) NOT NULL,
    numer_rundy     NUMBER(1, 2) NOT NULL
);

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzeda�_pk PRIMARY KEY ( id_producenta,
                                             jakosc_marki,
                                             numer_rundy );

CREATE TABLE ustawienia_poczatkowe (
    numer_opcji                 NUMBER(1, 2) NOT NULL,
    liczba_klientow             NUMBER(1, 5) NOT NULL,
    warunek_zakonczenia_rundy   CHAR(1 CHAR) NOT NULL,
    czas_rundy                  NUMBER(1, 9) NOT NULL,
    liczba_rund                 NUMBER(1, 5) NOT NULL,
    poczatkowe_fundusze         NUMBER(2, 6)
);

COMMENT ON COLUMN ustawienia_poczatkowe.warunek_zakonczenia_rundy IS
    '''t'' - up�yn�� okre�lony czas
''m'' - wszyscy gracz wykonali ruch
''b'' - up�yn�� okre�lony czas lub wszyscy gracze wykonali ruch '
    ;

COMMENT ON COLUMN ustawienia_poczatkowe.czas_rundy IS
    'Czas w godzinach. Je�li jest wybrana opcja, w kt�rej warunkiem zako�czenia rundy jest ruch wszystkich graczy, w�wczas czas nie jest brany pod uwag�.'
    ;

ALTER TABLE ustawienia_poczatkowe ADD CONSTRAINT ustawienia_poczatkowe_pk PRIMARY KEY ( numer_opcji );

CREATE TABLE utworzona_marka (
    cena_za_sztuke               NUMBER(2, 6) NOT NULL,
    producent_id_producenta      NUMBER(1, 8) NOT NULL,
    rodzaje_marek_jakosc_marki   NUMBER(1, 3) NOT NULL,
    nazwa                        VARCHAR2(20 CHAR) NOT NULL
);

ALTER TABLE utworzona_marka ADD CONSTRAINT utworzona_marka_pk PRIMARY KEY ( producent_id_producenta,
                                                                            rodzaje_marek_jakosc_marki );

ALTER TABLE utworzona_marka ADD CONSTRAINT utworzona_marka_nazwa_un UNIQUE ( nazwa );

CREATE TABLE zakup_konsumenta (
    numer_rundy     NUMBER(1, 2) NOT NULL,
    id_producenta   NUMBER(1, 8) NOT NULL,
    jakosc_marki    NUMBER(1, 3) NOT NULL,
    id_konsumenta   NUMBER(1, 8) NOT NULL
);

ALTER TABLE zakup_konsumenta ADD CONSTRAINT zakup_konsumenta_pk PRIMARY KEY ( id_konsumenta,
                                                                              numer_rundy );

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta );

ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                  jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_rodzaj_marketingu_fk FOREIGN KEY ( id_rodzaju_marketingu )
        REFERENCES rodzaj_marketingu ( id_rodzaju_marketingu );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                              jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                              jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_konsument_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsument ( id_konsumenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                          jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzeda�_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzeda�_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                             jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE utworzona_marka
    ADD CONSTRAINT utworzona_marka_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE utworzona_marka
    ADD CONSTRAINT utworzona_marka_rodzaje_marek_fk FOREIGN KEY ( rodzaje_marek_jakosc_marki )
        REFERENCES rodzaje_marek ( jakosc_marki );

ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_konsument_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsument ( id_konsumenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                     jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_licznik_rund_fk FOREIGN KEY ( licznik_rund_numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE badanie_rynku
    ADD CONSTRAINT badanie_rynku_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta );

ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE magazynowanie
    ADD CONSTRAINT magazynowanie_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                  jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_rodzaj_marketingu_fk FOREIGN KEY ( id_rodzaju_marketingu )
        REFERENCES rodzaj_marketingu ( id_rodzaju_marketingu );

ALTER TABLE marketing
    ADD CONSTRAINT marketing_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                              jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE produkcja
    ADD CONSTRAINT produkcja_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                              jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_konsument_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsument ( id_konsumenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE przywiazanie_do_marki
    ADD CONSTRAINT przywiazanie_do_marki_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                          jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzeda�_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

ALTER TABLE sprzedaz
    ADD CONSTRAINT sprzeda�_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                             jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

ALTER TABLE utworzona_marka
    ADD CONSTRAINT utworzona_marka_producent_fk FOREIGN KEY ( producent_id_producenta )
        REFERENCES producent ( id_producenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE utworzona_marka
    ADD CONSTRAINT utworzona_marka_rodzaje_marek_fk FOREIGN KEY ( rodzaje_marek_jakosc_marki )
        REFERENCES rodzaje_marek ( jakosc_marki );

ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_konsument_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsument ( id_konsumenta );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_licznik_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES licznik_rund ( numer_rundy );

--  ERROR: FK name length exceeds maximum allowed length(30) 
ALTER TABLE zakup_konsumenta
    ADD CONSTRAINT zakup_konsumenta_utworzona_marka_fk FOREIGN KEY ( id_producenta,
                                                                     jakosc_marki )
        REFERENCES utworzona_marka ( producent_id_producenta,
                                     rodzaje_marek_jakosc_marki );

CREATE OR REPLACE TRIGGER fkntm_utworzona_marka BEFORE
    UPDATE OF producent_id_producenta, rodzaje_marek_jakosc_marki ON utworzona_marka
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table UTWORZONA_MARKA is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_zakup_konsumenta BEFORE
    UPDATE OF id_konsumenta ON zakup_konsumenta
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table ZAKUP_KONSUMENTA is violated');
END;
/



-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                            15
-- CREATE INDEX                             0
-- ALTER TABLE                             52
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
-- ERRORS                                  12
-- WARNINGS                                 0
