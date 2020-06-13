-- Generated by Oracle SQL Developer Data Modeler 18.3.0.268.1156
--   at:        2020-06-09 11:56:24 CEST
--   site:      Oracle Database 11g
--   type:      Oracle Database 11g



CREATE TABLE badania_rynku (
    id_badania_rynku               NUMBER(6) NOT NULL,
    numer_rundy                    NUMBER(5) NOT NULL,
    his_zakupow_liczba_rund        NUMBER(5) DEFAULT 0 NOT NULL,
    id_marki                       NUMBER(6) NOT NULL,
    id_grupy_konsumentow           NUMBER(5) NOT NULL,
    koszt_badania_rynku            NUMBER(15) NOT NULL,
    uwzglednic_jakosc              CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
    uwzglednic_cene                CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
    uwzglednic_stosunek_do_marki   CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
    uwzg_stosunek_do_producenta    CHAR(1 CHAR) DEFAULT 'n' NOT NULL
);

ALTER TABLE badania_rynku
    ADD CHECK ( uwzglednic_jakosc IN (
        'n',
        't'
    ) );

ALTER TABLE badania_rynku
    ADD CHECK ( uwzglednic_cene IN (
        'n',
        't'
    ) );

ALTER TABLE badania_rynku
    ADD CHECK ( uwzglednic_stosunek_do_marki IN (
        'n',
        't'
    ) );

ALTER TABLE badania_rynku
    ADD CHECK ( uwzg_stosunek_do_producenta IN (
        'n',
        't'
    ) );

ALTER TABLE badania_rynku ADD CONSTRAINT badania_rynku_pk PRIMARY KEY ( id_badania_rynku );

CREATE TABLE dostepy_producentow_his_zakup (
    id_konsumenta      NUMBER(10) NOT NULL,
    numer_rundy        NUMBER(5) NOT NULL,
    id_badania_rynku   NUMBER(6) NOT NULL
);

ALTER TABLE dostepy_producentow_his_zakup
    ADD CONSTRAINT dost_his_zakup_pk PRIMARY KEY ( id_konsumenta,
                                                   numer_rundy,
                                                   id_badania_rynku );

CREATE TABLE grupy_konsumentow (
    id_grupy_konsumentow         NUMBER(5) NOT NULL,
    koszt_uzyskania_ocen         NUMBER(10) NOT NULL,
    koszt_his_zakup_jedna_tura   NUMBER(10) NOT NULL,
    opis                         VARCHAR2(200 CHAR)
);

ALTER TABLE grupy_konsumentow ADD CONSTRAINT grupy_konsumentow_pk PRIMARY KEY ( id_grupy_konsumentow );

CREATE TABLE historie_cen (
    cena          NUMBER(8) NOT NULL,
    id_marki      NUMBER(6) NOT NULL,
    numer_rundy   NUMBER(5) NOT NULL
);

ALTER TABLE historie_cen ADD CONSTRAINT historie_cen_pk PRIMARY KEY ( id_marki,
                                                                      numer_rundy );

CREATE TABLE jakosci_marek (
    jakosc_marki                 NUMBER(2) NOT NULL,
    ref_koszt_produkcji_sztuki   NUMBER(8) NOT NULL
);

ALTER TABLE jakosci_marek ADD CONSTRAINT jakosci_marek_pk PRIMARY KEY ( jakosc_marki );

CREATE TABLE konsumenci (
    id_konsumenta                    NUMBER(10) NOT NULL,
    cena_poziom_aspiracji            NUMBER(5) NOT NULL,
    cena_poziom_rezerwacji           NUMBER(5) NOT NULL,
    jakosc_poziom_aspiracji          NUMBER(2) NOT NULL,
    jakosc_poziom_rezerwacji         NUMBER(2) NOT NULL,
    przywiazanie_poziom_aspiracji    NUMBER(4, 2) NOT NULL,
    przywiazanie_poziom_rezerwacji   NUMBER(4, 2) NOT NULL,
    podatnosc_na_marketing           NUMBER(2, 2) NOT NULL
);

ALTER TABLE konsumenci ADD CONSTRAINT konsumenci_pk PRIMARY KEY ( id_konsumenta );

CREATE TABLE magazynowania (
    wolumen               NUMBER(8) NOT NULL,
    koszt_magazynowania   NUMBER(12) NOT NULL,
    numer_rundy           NUMBER(5) NOT NULL,
    id_marki              NUMBER(6) NOT NULL
);

ALTER TABLE magazynowania ADD CONSTRAINT magazynowania_pk PRIMARY KEY ( numer_rundy,
                                                                        id_marki );

CREATE TABLE marketingi (
    id_marketingu           NUMBER(12) NOT NULL,
    numer_rundy             NUMBER(5) NOT NULL,
    id_rodzaju_marketingu   NUMBER(2) NOT NULL,
    liczba_klientow         NUMBER(10) NOT NULL,
    koszt_marketingu        NUMBER(12) NOT NULL,
    id_marki                NUMBER(6) NOT NULL
);

ALTER TABLE marketingi ADD CONSTRAINT marketingi_pk PRIMARY KEY ( id_marketingu );

CREATE TABLE marki (
    id_marki                   NUMBER(6) NOT NULL,
    id_producenta              NUMBER(3) NOT NULL,
    nazwa_marki                VARCHAR2(20 CHAR) NOT NULL,
    jakosc_marki               NUMBER(2) NOT NULL,
    koszt_produkcji_sztuki     NUMBER(8) NOT NULL,
    cena_za_sztuke             NUMBER(8) NOT NULL,
    czy_utworzona              CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
    aktualna_liczba_sztuk      NUMBER(15) DEFAULT 0 NOT NULL,
    tymczasowa_ocena_klienta   NUMBER(15, 10) DEFAULT 0 NOT NULL
);

ALTER TABLE marki
    ADD CHECK ( czy_utworzona IN (
        'n',
        't'
    ) );

COMMENT ON COLUMN marki.czy_utworzona IS
    '''t'' - tak
''n'' - nie';

ALTER TABLE marki ADD CONSTRAINT marki_pk PRIMARY KEY ( id_marki );

ALTER TABLE marki ADD CONSTRAINT marki_nazwa_marki_un UNIQUE ( nazwa_marki );

CREATE TABLE numery_rund (
    numer_rundy   NUMBER(5) NOT NULL
);

ALTER TABLE numery_rund ADD CONSTRAINT numery_rund_pk PRIMARY KEY ( numer_rundy );

CREATE TABLE oceny_marek (
    id_konsumenta      NUMBER(10) NOT NULL,
    id_badania_rynku   NUMBER(6) NOT NULL,
    ocena              NUMBER(8, 4) NOT NULL
);

ALTER TABLE oceny_marek ADD CONSTRAINT oceny_marek_pk PRIMARY KEY ( id_konsumenta,
                                                                    id_badania_rynku );

CREATE TABLE producenci (
    id_producenta      NUMBER(3) NOT NULL,
    nazwa_producenta   VARCHAR2(30 CHAR) NOT NULL,
    fundusze           NUMBER(14) NOT NULL,
    czy_spasowal       CHAR(1 CHAR) DEFAULT 'n' NOT NULL
);

ALTER TABLE producenci
    ADD CHECK ( czy_spasowal IN (
        'n',
        't'
    ) );

COMMENT ON COLUMN producenci.czy_spasowal IS
    '''n'' - NIE
''t'' - TAK';

ALTER TABLE producenci ADD CONSTRAINT producenci_pk PRIMARY KEY ( id_producenta );

ALTER TABLE producenci ADD CONSTRAINT producenci_nazwa_producenta_un UNIQUE ( nazwa_producenta );

CREATE TABLE produkcje (
    id_produkcji      NUMBER(12) NOT NULL,
    wolumen           NUMBER(10) NOT NULL,
    koszt_produkcji   NUMBER(12) NOT NULL,
    numer_rundy       NUMBER(5) NOT NULL,
    id_marki          NUMBER(6) NOT NULL
);

ALTER TABLE produkcje ADD CONSTRAINT produkcje_pk PRIMARY KEY ( id_produkcji );

CREATE TABLE przynaleznosci_do_grup (
    id_konsumenta          NUMBER(10) NOT NULL,
    id_grupy_konsumentow   NUMBER(5) NOT NULL
);

ALTER TABLE przynaleznosci_do_grup ADD CONSTRAINT przynaleznosci_do_grup_pk PRIMARY KEY ( id_konsumenta,
                                                                                          id_grupy_konsumentow );

CREATE TABLE przywiazania_do_marek (
    id_konsumenta               NUMBER(10) NOT NULL,
    wspolczynnik_przywiazania   NUMBER(4, 2) NOT NULL,
    id_marki                    NUMBER(6) NOT NULL
);

ALTER TABLE przywiazania_do_marek ADD CONSTRAINT przywiazania_do_marek_pk PRIMARY KEY ( id_konsumenta,
                                                                                        id_marki );

CREATE TABLE rodzaje_marketingu (
    id_rodzaju_marketingu      NUMBER(2) NOT NULL,
    koszt_bazowy               NUMBER(15) NOT NULL,
    koszta_per_klient          NUMBER(15) NOT NULL,
    wplyw_na_docelowa_marke    NUMBER(5, 3) NOT NULL,
    wplyw_na_inne_marki_prod   NUMBER(5, 3) NOT NULL
);

ALTER TABLE rodzaje_marketingu ADD CONSTRAINT rodzaje_marketingu_pk PRIMARY KEY ( id_rodzaju_marketingu );

CREATE TABLE ustawienia_poczatkowe (
    numer_zestawu                   NUMBER(2) NOT NULL,
    aktywna                         CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
    liczba_konsumentow              NUMBER(10) NOT NULL,
    warunek_zakonczenia_rundy       CHAR(1 CHAR) NOT NULL,
    czas_rundy                      NUMBER(4),
    liczba_rund                     NUMBER(5),
    poczatkowe_fundusze             NUMBER(8) NOT NULL,
    koszt_utworzenia_marki          NUMBER(8) NOT NULL,
    zakup_wplyw_na_docelowa_marke   NUMBER(5, 3) NOT NULL,
    zakup_wplyw_na_inne_marki_pro   NUMBER(5, 3) NOT NULL,
    brak_zakupu_wplyw_na_marke      NUMBER(5, 3) NOT NULL,
    niezaspokojony_popyt_wplyw      NUMBER(5, 3) NOT NULL,
    sposob_nalicz_koszt_magazyn     CHAR(1 CHAR) DEFAULT 'm' NOT NULL,
    koszt_mag_sztuki_lub_magazynu   NUMBER(15) NOT NULL,
    wielkosc_powierzchni_mag        NUMBER(12),
    upust_za_kolejny_magazyn        NUMBER(2),
    czy_jakosci_marek_domyslne      CHAR(1 CHAR) NOT NULL,
    opis                            VARCHAR2(200 CHAR)
);

ALTER TABLE ustawienia_poczatkowe
    ADD CHECK ( aktywna IN (
        'a',
        'n'
    ) );

ALTER TABLE ustawienia_poczatkowe
    ADD CHECK ( sposob_nalicz_koszt_magazyn IN (
        'l',
        'm'
    ) );

COMMENT ON COLUMN ustawienia_poczatkowe.aktywna IS
    '''a'' - aktywna. Ustawiona flaga aktywnosci oznacza, ze z tego zestawu beda pobierane ustawienia na rzecz rozgrywki; tylko jednen zestaw ustawien poczatkowych moze miec ustawiona te flage. Jesli nie ma zaden, wowczas gra pobiera dane z pierwszego zestawu'
    ;

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

COMMENT ON COLUMN ustawienia_poczatkowe.sposob_nalicz_koszt_magazyn IS
    '''l'' - liniowy
''m'' - producent placi za magazyn o okreslonej wielkosci, niezaleznie od stopnia zapelnienia';

COMMENT ON COLUMN ustawienia_poczatkowe.koszt_mag_sztuki_lub_magazynu IS
    'Koszt zmagazynowania jednej sztuki (jesli obowiazuje liniowe naliczanie oplat) lub calego przedzialu (jesli obowiazuje naliczanie oplat zwiazane z powierzchnia magazynowa).'
    ;

COMMENT ON COLUMN ustawienia_poczatkowe.wielkosc_powierzchni_mag IS
    'Okre�la wielkosc powierzchni magazynowej, czyli ile maksymalnie sztuk towaru zmiesci sie na powierzchni magazynowej.';

COMMENT ON COLUMN ustawienia_poczatkowe.upust_za_kolejny_magazyn IS
    'Jaki upust (w %) dostanie gracz za kazda kolejna (poza pierwsza) wykorzystana przestrzenia magazynowa.';

COMMENT ON COLUMN ustawienia_poczatkowe.czy_jakosci_marek_domyslne IS
    '''t'' - TAK
''n'' - NIE';

ALTER TABLE ustawienia_poczatkowe ADD CONSTRAINT ustawienia_poczatkowe_pk PRIMARY KEY ( numer_zestawu );

CREATE TABLE zakupy_konsumentow (
    numer_rundy     NUMBER(5) NOT NULL,
    id_konsumenta   NUMBER(10) NOT NULL,
    id_marki        NUMBER(6) NOT NULL
);

ALTER TABLE zakupy_konsumentow ADD CONSTRAINT zakupy_konsumentow_pk PRIMARY KEY ( id_konsumenta,
                                                                                  numer_rundy );

ALTER TABLE badania_rynku
    ADD CONSTRAINT badania_rynku_gr_konsum_fk FOREIGN KEY ( id_grupy_konsumentow )
        REFERENCES grupy_konsumentow ( id_grupy_konsumentow )
            ON DELETE CASCADE;

ALTER TABLE badania_rynku
    ADD CONSTRAINT badania_rynku_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki );

ALTER TABLE badania_rynku
    ADD CONSTRAINT badania_rynku_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE dostepy_producentow_his_zakup
    ADD CONSTRAINT dost_his_badania_rynku_fk FOREIGN KEY ( id_badania_rynku )
        REFERENCES badania_rynku ( id_badania_rynku )
            ON DELETE CASCADE;

ALTER TABLE dostepy_producentow_his_zakup
    ADD CONSTRAINT dost_his_zakupy_konsum_fk FOREIGN KEY ( id_konsumenta,
                                                           numer_rundy )
        REFERENCES zakupy_konsumentow ( id_konsumenta,
                                        numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE historie_cen
    ADD CONSTRAINT historie_cen_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE historie_cen
    ADD CONSTRAINT historie_cen_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE magazynowania
    ADD CONSTRAINT magazynowania_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE magazynowania
    ADD CONSTRAINT magazynowania_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE marketingi
    ADD CONSTRAINT marketingi_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE marketingi
    ADD CONSTRAINT marketingi_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE marketingi
    ADD CONSTRAINT marketingi_rodz_marketingu_fk FOREIGN KEY ( id_rodzaju_marketingu )
        REFERENCES rodzaje_marketingu ( id_rodzaju_marketingu )
            ON DELETE CASCADE;

ALTER TABLE marki
    ADD CONSTRAINT marki_jakosci_marek_fk FOREIGN KEY ( jakosc_marki )
        REFERENCES jakosci_marek ( jakosc_marki )
            ON DELETE CASCADE;

ALTER TABLE marki
    ADD CONSTRAINT marki_producenci_fk FOREIGN KEY ( id_producenta )
        REFERENCES producenci ( id_producenta )
            ON DELETE CASCADE;

ALTER TABLE oceny_marek
    ADD CONSTRAINT oceny_marek_badania_rynku_fk FOREIGN KEY ( id_badania_rynku )
        REFERENCES badania_rynku ( id_badania_rynku )
            ON DELETE CASCADE;

ALTER TABLE oceny_marek
    ADD CONSTRAINT oceny_marek_konsumenci_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsumenci ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE produkcje
    ADD CONSTRAINT produkcje_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE produkcje
    ADD CONSTRAINT produkcje_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

ALTER TABLE przynaleznosci_do_grup
    ADD CONSTRAINT przyn_do_gr_g_konsumentow_fk FOREIGN KEY ( id_grupy_konsumentow )
        REFERENCES grupy_konsumentow ( id_grupy_konsumentow )
            ON DELETE CASCADE;

ALTER TABLE przynaleznosci_do_grup
    ADD CONSTRAINT przyn_do_gr_konsumenci_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsumenci ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE przywiazania_do_marek
    ADD CONSTRAINT przyw_do_marek_konsumenci_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsumenci ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE przywiazania_do_marek
    ADD CONSTRAINT przyw_do_marek_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE zakupy_konsumentow
    ADD CONSTRAINT zakupy_konsum_konsumenci_fk FOREIGN KEY ( id_konsumenta )
        REFERENCES konsumenci ( id_konsumenta )
            ON DELETE CASCADE;

ALTER TABLE zakupy_konsumentow
    ADD CONSTRAINT zakupy_konsum_marki_fk FOREIGN KEY ( id_marki )
        REFERENCES marki ( id_marki )
            ON DELETE CASCADE;

ALTER TABLE zakupy_konsumentow
    ADD CONSTRAINT zakupy_konsum_numery_rund_fk FOREIGN KEY ( numer_rundy )
        REFERENCES numery_rund ( numer_rundy )
            ON DELETE CASCADE;

CREATE OR REPLACE TRIGGER fkntm_badania_rynku BEFORE
    UPDATE OF numer_rundy, id_marki, id_grupy_konsumentow ON badania_rynku
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table BADANIA_RYNKU is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_dostepy_producentow_his_ BEFORE
    UPDATE OF id_konsumenta, numer_rundy, id_badania_rynku ON dostepy_producentow_his_zakup
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table DOSTEPY_PRODUCENTOW_HIS_ZAKUP is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_historie_cen BEFORE
    UPDATE OF id_marki, numer_rundy ON historie_cen
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table HISTORIE_CEN is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_magazynowania BEFORE
    UPDATE OF numer_rundy, id_marki ON magazynowania
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table MAGAZYNOWANIA is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_marketingi BEFORE
    UPDATE OF numer_rundy, id_rodzaju_marketingu, id_marki ON marketingi
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKETINGI is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_marki BEFORE
    UPDATE OF id_producenta, jakosc_marki ON marki
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKI is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_oceny_marek BEFORE
    UPDATE OF id_konsumenta, id_badania_rynku ON oceny_marek
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table OCENY_MAREK is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_produkcje BEFORE
    UPDATE OF numer_rundy, id_marki ON produkcje
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table PRODUKCJE is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_przynaleznosci_do_grup BEFORE
    UPDATE OF id_konsumenta, id_grupy_konsumentow ON przynaleznosci_do_grup
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table PRZYNALEZNOSCI_DO_GRUP is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_przywiazania_do_marek BEFORE
    UPDATE OF id_konsumenta, id_marki ON przywiazania_do_marek
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table PRZYWIAZANIA_DO_MAREK is violated');
END;
/

CREATE OR REPLACE TRIGGER fkntm_zakupy_konsumentow BEFORE
    UPDATE OF id_marki, id_konsumenta, numer_rundy ON zakupy_konsumentow
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table ZAKUPY_KONSUMENTOW is violated');
END;
/



-- Oracle SQL Developer Data Modeler Summary Report: 
-- 
-- CREATE TABLE                            18
-- CREATE INDEX                             0
-- ALTER TABLE                             78
-- CREATE VIEW                              0
-- ALTER VIEW                               0
-- CREATE PACKAGE                           0
-- CREATE PACKAGE BODY                      0
-- CREATE PROCEDURE                         0
-- CREATE FUNCTION                          0
-- CREATE TRIGGER                          11
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
