create or replace TRIGGER STWORZ_MARKE
BEFORE INSERT ON MARKI
FOR EACH ROW
DECLARE
    koszt_produkcji NUMBER;
BEGIN
  SELECT ID_MARKI_SEQ.NEXTVAL
  INTO :NEW.ID_MARKI
  FROM DUAL;
  
  select ref_koszt_produkcji_sztuki into :new.koszt_produkcji_sztuki from JAKOSCI_MAREK where jakosc_marki = :new.jakosc_marki;
END;
/

create or replace TRIGGER SPR_MOZLIWOSCI_PRODUKCJI 
BEFORE INSERT ON PRODUKCJE
for each row
DECLARE
fund number;
BEGIN
    --autoinkrementacja id
    SELECT ID_PRODUKCJI_SEQ.NEXTVAL
    INTO :NEW.ID_PRODUKCJI
    FROM DUAL;
    
    --ustawienie kosztu i sprawdzenie czy producent ma fundusze
    select p.fundusze into fund from producenci p, marki m where p.ID_PRODUCENTA = m.ID_PRODUCENTA AND m.ID_MARKI = :NEW.id_marki;
    select KOSZT_PRODUKCJI_SZTUKI into :new.koszt_produkcji from marki where ID_MARKI = :NEW.id_marki;
    :new.koszt_produkcji := :new.koszt_produkcji * :new.wolumen;
    if fund < :new.koszt_produkcji then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;

    --dodanie numeru rundy
    select max(numer_rundy) into :new.numer_rundy from numery_rund;
END;
/

create or replace TRIGGER REALIZUJ_PRODUKCJE
AFTER INSERT ON PRODUKCJE
for each row
DECLARE
id_producenta number (3,0);
BEGIN
    select p.id_producenta into id_producenta from producenci p, marki m where p.ID_PRODUCENTA = m.ID_PRODUCENTA AND m.ID_MARKI = :NEW.id_marki;
    update producenci set FUNDUSZE = FUNDUSZE - :new.koszt_produkcji where ID_PRODUCENTA = id_producenta;
    --uaktualnienie liczby dostepnych sztuk
    update marki set AKTUALNA_LICZBA_SZTUK = AKTUALNA_LICZBA_SZTUK + :new.WOLUMEN where ID_MARKI = :NEW.id_marki;
END;
/


create or replace TRIGGER AUTOINKREMENTACJA_LICZNIKA_RUND 
BEFORE INSERT ON NUMERY_RUND
FOR EACH ROW
BEGIN
    SELECT LICZNIK_RUND_SEQ.NEXTVAL
    INTO :NEW.NUMER_RUNDY
    FROM DUAL;
END;
/

create or replace TRIGGER SPR_CZY_WSZYSCY_SPASOWALI 
AFTER UPDATE OF CZY_SPASOWAL ON PRODUCENCI 
DECLARE
    nie_spasowali number (2,0);
BEGIN
    select count(id_producenta) into nie_spasowali from producenci where CZY_SPASOWAL = 'n';
    if nie_spasowali = 0 then
        rozpocznij_runde;
    end if;
END;
/

create or replace TRIGGER SPR_MOZLIWOSC_MARKETINGU 
BEFORE INSERT ON MARKETINGI
FOR EACH ROW
DECLARE
koszt NUMBER (15, 0);
koszt_per_konsument NUMBER (15, 0);
BEGIN
    --wstawienie id z sekwencji
    SELECT ID_RODZAJU_MARKET_SEQ.NEXTVAL
    INTO :NEW.ID_MARKETINGU
    FROM DUAL;
    
    --wstawienie nr rundy
    select max(numer_rundy) into :new.numer_rundy from NUMERY_RUND;

    --obliczenie kosztu
    select KOSZT_BAZOWY into koszt from RODZAJE_MARKETINGU where ID_RODZAJU_MARKETINGU = :new.ID_RODZAJU_MARKETINGU;
    select koszta_per_klient into koszt_per_konsument from RODZAJE_MARKETINGU where ID_RODZAJU_MARKETINGU = :new.ID_RODZAJU_MARKETINGU;
    :new.koszt_marketingu := koszt + koszt_per_konsument * :new.liczba_klientow;
END;
/

