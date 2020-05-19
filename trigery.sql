create or replace TRIGGER DZIALANIE_BADANIA_RYNKU 
AFTER INSERT ON BADANIE_RYNKU
FOR EACH ROW
BEGIN
  OCEN_HIPOTETYCZNA_MARKE(:new.producent_id_producenta, :new.CZY_UWZGLEDNIC_PRODUCENTA, :new.ID_BADANIA_RYNKU, :new.LICZBA_KLIENTOW, :new.HORYZONT_CZASOWY);
END;
/


create or replace TRIGGER DZIALANIE_MARKETINGU 
AFTER INSERT ON MARKETING
FOR EACH ROW
DECLARE
id_prod NUMBER (3, 0);
wspolczynnik_modyfikacji NUMBER (5,3);
BEGIN
    --okreslenie id producenta
    select producent_id_producenta into id_prod from marka where id_marki = :new.marka_id_marki;

    --potracenie kosztow
    update producent set FUNDUSZE = FUNDUSZE - :new.koszt where ID_PRODUCENTA = id_prod;

    --modyfikacja wspolczynnikow przywiazania konsumentow do marek
    FOR REC IN (select id_konsumenta from konsument)
    LOOP
        select wplyw_na_docelowa_marke into wspolczynnik_modyfikacji from rodzaj_marketingu where ID_RODZAJU_MARKETINGU = :new.RODZ_MARKET_ID_RODZ_MARKETINGU;
        update przywiazanie_do_marki set wspolczynnik_przywiazania = wspolczynnik_przywiazania*wspolczynnik_modyfikacji
            where marka_id_marki = :new.marka_id_marki and konsument_id_konsumenta = REC.id_konsumenta;

        select wplyw_na_inne_marki_prod into wspolczynnik_modyfikacji from rodzaj_marketingu where ID_RODZAJU_MARKETINGU = :new.RODZ_MARKET_ID_RODZ_MARKETINGU;
        for CUR IN (select m.id_marki from marka m, producent p where p.id_producenta = m.producent_id_producenta and p.id_producenta = id_prod)
        loop
            update przywiazanie_do_marki set wspolczynnik_przywiazania = wspolczynnik_przywiazania*wspolczynnik_modyfikacji
            where marka_id_marki = CUR.id_marki and konsument_id_konsumenta = REC.id_konsumenta;
        end loop;
    end loop;
END;
/


create or replace TRIGGER fkntm_marka BEFORE
    UPDATE OF producent_id_producenta, rodzaje_marek_jakosc_marki ON marka
    FOR EACH ROW
BEGIN
    IF :NEW.producent_id_producenta <> :OLD.producent_id_producenta OR :NEW.rodzaje_marek_jakosc_marki <> :OLD.rodzaje_marek_jakosc_marki
    THEN
        raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKI is violated');
    END IF;
END;
/


create or replace TRIGGER fkntm_zakup_konsumenta BEFORE
    UPDATE OF konsument_id_konsumenta ON zakup_konsumenta
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table ZAKUP_KONSUMENTA is violated');
END;
/


create or replace TRIGGER ID_BADANIA_RYNKU_AUTOINC 
BEFORE INSERT ON BADANIE_RYNKU 
FOR EACH ROW
BEGIN
    --sprawdzic fundusze

  SELECT ID_BADANIA_RYNKU_SEQ.NEXTVAL
  INTO :NEW.ID_BADANIA_RYNKU
  FROM DUAL;

  --numer rundy
    SELECT max(numer_rundy)
    INTO :NEW.licznik_rund_numer_rundy
    FROM licznik_rund;
END;
/


create or replace TRIGGER ID_HIPOTETYCZNEJ_MARKI_AUTOINC
BEFORE INSERT ON HIPOTETYCZNA_MARKA
FOR EACH ROW
BEGIN
  SELECT ID_HIPOTETYCZNEJ_MARKI_SEQ.NEXTVAL
  INTO :NEW.ID_HIPOTETYCZNEJ_MARKI
  FROM DUAL;
END;
/


create or replace TRIGGER ID_MARKI_AUTOINC 
BEFORE INSERT ON MARKA
FOR EACH ROW
BEGIN
  SELECT ID_MARKI_SEQ.NEXTVAL
  INTO :NEW.ID_MARKI
  FROM DUAL;
END;
/


create or replace TRIGGER ID_RODZ_MARKET_AUTOINC 
BEFORE INSERT ON RODZAJ_MARKETINGU 
FOR EACH ROW
BEGIN
  SELECT ID_RODZAJU_MARKET_SEQ.NEXTVAL
  INTO :NEW.ID_RODZAJU_MARKETINGU
  FROM DUAL;
END;
/


create or replace TRIGGER KOSZT_UTWORZENIA_MARKI 
AFTER INSERT ON MARKA
FOR EACH ROW
DECLARE
koszt number (10, 0);
BEGIN
    --potracenie kosztu utworzenia marki
    select koszt_utworzenia into koszt from RODZAJE_MAREK where jakosc_marki = :NEW.rodzaje_marek_jakosc_marki;
    update producent set FUNDUSZE = FUNDUSZE - koszt where ID_PRODUCENTA = :NEW.producent_id_producenta;

    --ustalenie wspolczynnika przywiazania do marki dla kazdego z klientow
    FOR REC IN (SELECT id_konsumenta from konsument)
    LOOP
        insert into PRZYWIAZANIE_DO_MARKI values (rec.id_konsumenta, 1.0, :new.id_marki);
    END LOOP;
END;
/


create or replace TRIGGER LICZNIK_RUND_AUTOINC 
BEFORE INSERT ON LICZNIK_RUND
FOR EACH ROW
BEGIN
    SELECT LICZNIK_RUND_SEQ.NEXTVAL
    INTO :NEW.NUMER_RUNDY
    FROM DUAL;
END;
/


create or replace TRIGGER POTRACENIE_KOSZTOW_PRODUKCJI 
AFTER INSERT ON PRODUKCJA
for each row
DECLARE
id_producenta number (3,0);
BEGIN
    select p.id_producenta into id_producenta from producent p, marka m where p.ID_PRODUCENTA = m.PRODUCENT_ID_PRODUCENTA AND m.ID_MARKI = :NEW.marka_id_marki;
    update producent set FUNDUSZE = FUNDUSZE - :new.koszt where ID_PRODUCENTA = id_producenta;
    --uaktualnienie liczby dostepnych sztuk
    update marka set AKTUALNA_LICZBA_SZTUK = AKTUALNA_LICZBA_SZTUK - :new.ilosc where ID_MARKI = :NEW.marka_id_marki;
END;
/


create or replace TRIGGER SPR_CZY_ISTNIEJE_UZYTKOWNIK 
BEFORE INSERT ON PRODUCENT
FOR EACH ROW
DECLARE
    czy_istnieje number;
BEGIN
    select count(username) into czy_istnieje from all_users where username = :new.nazwa;
    if czy_istnieje = 0 then
        raise_application_error(-20880, 'Brak uzytkownika o nazwie pasujacej do podanej');
    end if;
END;
/


create or replace TRIGGER SPR_CZY_MOZLIWY_MARKETING 
BEFORE INSERT ON MARKETING
FOR EACH ROW
DECLARE
koszt NUMBER (15, 0);
koszt_per_klient NUMBER (15, 0);
BEGIN
    --wstawienie nr rundy
    select max(numer_rundy) into :new.licznik_rund_numer_rundy from licznik_rund;

    --obliczenie kosztu
    select koszt_staly into koszt from RODZAJ_MARKETINGU where ID_RODZAJU_MARKETINGU = :new.RODZ_MARKET_ID_RODZ_MARKETINGU;
    select koszt_per_klient into koszt_per_klient from RODZAJ_MARKETINGU where ID_RODZAJU_MARKETINGU = :new.RODZ_MARKET_ID_RODZ_MARKETINGU;
    :new.koszt := koszt + koszt_per_klient*:new.liczba_klientow;
END;
/


create or replace TRIGGER SPR_CZY_WSZYSCY_SPASOWALI 
AFTER UPDATE OF CZY_SPASOWAL ON PRODUCENT 
DECLARE
    nie_spasowali number (2,0);
BEGIN
    select count(id_producenta) into nie_spasowali from producent where CZY_SPASOWAL = 'n';
    if nie_spasowali = 0 then
        rozpocznij_runde;
    end if;
END;
/


create or replace TRIGGER SPR_MOZLIWOSCI_PRODUKCJI 
BEFORE INSERT ON PRODUKCJA
for each row
DECLARE
fund number (10,0);
koszt_prod number (10, 0);
BEGIN
    --ustawienie kosztu i sprawdzenie czy producent ma fundusze
    select p.fundusze into fund from producent p, marka m where p.ID_PRODUCENTA = m.PRODUCENT_ID_PRODUCENTA AND m.ID_MARKI = :NEW.marka_id_marki;
    select r.KOSZT_PRODUKCJI_SZTUKI into koszt_prod from RODZAJE_MAREK r, marka m where r.jakosc_marki = m.rodzaje_marek_jakosc_marki AND m.ID_MARKI = :NEW.marka_id_marki;
    koszt_prod := koszt_prod * :new.ilosc;
    if fund < koszt_prod then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;
    :new.koszt := koszt_prod;

    --dodanie numeru rundy
    select max(numer_rundy) into :new.licznik_rund_numer_rundy from licznik_rund;
END;
/


create or replace TRIGGER USTAWIENIA_POCZ_AUTOINC 
BEFORE INSERT ON USTAWIENIA_POCZATKOWE 
FOR EACH ROW
BEGIN
  SELECT  NR_OPCJI_USTAWIEN_POCZ_SEQ.NEXTVAL
  INTO :NEW.NUMER_OPCJI
  FROM DUAL;
END;
/


create or replace TRIGGER UZUPELNIENIE_HISTORII_CEN 
AFTER INSERT OR UPDATE OF CENA_ZA_SZTUKE ON MARKA
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    insert into HISTORIA_CEN values (:new.cena_za_sztuke, :new.id_marki, nr_rundy);
END;
/