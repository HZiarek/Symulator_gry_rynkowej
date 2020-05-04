create or replace TRIGGER fkntm_marka BEFORE
    UPDATE OF producent_id_producenta, rodzaje_marek_jakosc_marki ON marka
    FOR EACH ROW
BEGIN
    IF :NEW.producent_id_producenta <> :OLD.producent_id_producenta OR :NEW.rodzaje_marek_jakosc_marki <> :OLD.rodzaje_marek_jakosc_marki
    THEN
        raise_application_error(-20225, 'Non Transferable FK constraint  on table MARKI is violated');
    END IF;
END;



create or replace TRIGGER fkntm_zakup_konsumenta BEFORE
    UPDATE OF konsument_id_konsumenta ON zakup_konsumenta
BEGIN
    raise_application_error(-20225, 'Non Transferable FK constraint  on table ZAKUP_KONSUMENTA is violated');
END;



create or replace TRIGGER ID_MARKI_AUTOINC 
BEFORE INSERT ON MARKA
FOR EACH ROW
BEGIN
  SELECT ID_MARKI_SEQ.NEXTVAL
  INTO :NEW.ID_MARKI
  FROM DUAL;
END;



create or replace TRIGGER KOSZT_UTWORZENIA_MARKI 
AFTER INSERT ON MARKA
FOR EACH ROW
DECLARE
koszt number (10, 0);
BEGIN
    select koszt_utworzenia into koszt from RODZAJE_MAREK where jakosc_marki = :NEW.rodzaje_marek_jakosc_marki;
    update producent set FUNDUSZE = FUNDUSZE - koszt where ID_PRODUCENTA = :NEW.producent_id_producenta;
END;




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




create or replace TRIGGER UZUPELNIENIE_HISTORII_CEN 
AFTER INSERT OR UPDATE OF CENA_ZA_SZTUKE ON MARKA
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    insert into HISTORIA_CEN values (:new.cena_za_sztuke, :new.id_marki, nr_rundy);
END;
