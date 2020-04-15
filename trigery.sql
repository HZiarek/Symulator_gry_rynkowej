create or replace TRIGGER ID_KONSUMENTA_AUTOINC 
BEFORE INSERT ON KONSUMENCI
FOR EACH ROW
BEGIN
    SELECT ID_KONSUMENTA_SEQ.NEXTVAL
    INTO :NEW.ID_KONSUMENTA
    FROM DUAL;
END;


CREATE OR REPLACE TRIGGER ID_PRODUCENTA_AUTOINC
--wyzwalacz odpowiedzielny za przydzial producentowi unikatowego identyfikatora oraz funduszy o wielkosci okreslonej w ustawieniach poczatkowych
BEFORE INSERT ON PRODUCENCI 
FOR EACH ROW
BEGIN
    SELECT ID_PRODUCENTA_SEQ.NEXTVAL
    INTO :NEW.ID_PRODUCENTA
    FROM DUAL;
   
    select poczatkowe_fundusze into :NEW.fundusze from ustawienia_poczatkowe where numer_opcji = 1;
END;


create or replace TRIGGER fkntm_marki BEFORE
    UPDATE OF producent_id_producenta, rodzaje_marek_jakosc_marki ON marki
    FOR EACH ROW
BEGIN
    IF :NEW.producent_id_producenta <> :OLD.producent_id_producenta OR :NEW.rodzaje_marek_jakosc_marki <> :OLD.rodzaje_marek_jakosc_marki
    THEN
        raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKI is violated');
    END IF;
END;

CREATE OR REPLACE TRIGGER UZUPELNIENIE_HISTORII_CEN 
AFTER INSERT OR UPDATE OF CENA_ZA_SZTUKE ON MARKI
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    insert into HISTORIE_CEN values (:new.cena_za_sztuke, :new.id_marki, nr_rundy);
END;

create or replace TRIGGER POTRACENIE_KOSZTOW_PRODUKCJI 
AFTER INSERT ON PRODUKCJE
for each row
DECLARE
id_producenta number (3,0);
BEGIN
    select p.id_producenta into id_producenta from producenci p, marki m where p.ID_PRODUCENTA = m.PRODUCENT_ID_PRODUCENTA AND m.ID_MARKI = :NEW.marka_id_marki;
    update producenci set FUNDUSZE = FUNDUSZE - :new.koszt where ID_PRODUCENTA = id_producenta;
END;

CREATE OR REPLACE TRIGGER SPR_MOZLIWOSCI_PRODUKCJI 
BEFORE INSERT ON PRODUKCJE
for each row
DECLARE
fund number (10,0);
koszt_prod number (10, 0);
BEGIN
    --ustawienie kosztu i sprawdzenie czy producent ma fundusze
    select p.fundusze into fund from producenci p, marki m where p.ID_PRODUCENTA = m.PRODUCENT_ID_PRODUCENTA AND m.ID_MARKI = :NEW.marka_id_marki;
    select r.KOSZT_PRODUKCJI_SZTUKI into koszt_prod from RODZAJE_MAREK r, marki m where r.jakosc_marki = m.rodzaje_marek_jakosc_marki AND m.ID_MARKI = :NEW.marka_id_marki;
    koszt_prod := koszt_prod * :new.ilosc;
    if fund < koszt_prod then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;
    :new.koszt := koszt_prod;
    
    --dodanie numeru rundy
    select max(numer_rundy) into :new.licznik_rund_numer_rundy from licznik_rund;
END;

CREATE OR REPLACE TRIGGER KOSZT_UTWORZENIA_MARKI 
AFTER INSERT ON MARKI
FOR EACH ROW
DECLARE
koszt number (10, 0);
BEGIN
    select koszt_utworzenia into koszt from RODZAJE_MAREK where jakosc_marki = :NEW.rodzaje_marek_jakosc_marki;
    update producenci set FUNDUSZE = FUNDUSZE - koszt where ID_PRODUCENTA = :NEW.producent_id_producenta;
END;
