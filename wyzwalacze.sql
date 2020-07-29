create or replace TRIGGER AUTOINKREMENTACJA_ID_GRUPY_KONSUMENTOW 
BEFORE INSERT ON GRUPY_KONSUMENTOW
for each row
BEGIN
    --autoinkrementacja id
    SELECT ID_GRUPY_KONSUMENTOW_SEQ.NEXTVAL
    INTO :NEW.ID_GRUPY_KONSUMENTOW
    FROM DUAL;
END;
/

create or replace TRIGGER AUTOINKREMENTACJA_LICZNIKA_RUND 
BEFORE INSERT ON NUMERY_RUND
FOR EACH ROW
BEGIN
    if :new.numer_rundy is null then
        SELECT max(numer_rundy)+1
        INTO :NEW.NUMER_RUNDY
        FROM NUMERY_RUND;
    end if;
END;
/

create or replace TRIGGER DZIALANIE_BADANIA_RYNKU 
AFTER INSERT ON BADANIA_RYNKU
FOR EACH ROW
DECLARE
    id_prod NUMBER (3, 0);
BEGIN
    OCEN_MARKE(:new.ID_BADANIA_RYNKU, :new.ID_MARKI, :new.ID_GRUPY_KONSUMENTOW, :new.HIS_ZAKUPOW_LICZBA_RUND,
                :new.UWZGLEDNIC_JAKOSC,
                :new.UWZGLEDNIC_CENE,
                :new.UWZGLEDNIC_HIS_ZAKUPOW,
                :new.UWZG_MARKETING_OST_RUNDA,
                :new.UWZGLEDNIC_MARKETING
                );

    --okreslenie id producenta
    select id_producenta into id_prod from marki where id_marki = :new.id_marki;

    --potracenie kosztow
    update producenci set FUNDUSZE = FUNDUSZE - :new.koszt_badania_rynku where ID_PRODUCENTA = id_prod;
END;
/

create or replace TRIGGER POTRAC_KOSZT_WPROWADZENIA_MARKI_NA_RYNEK
AFTER UPDATE OF CZY_UTWORZONA ON MARKI
FOR EACH ROW
DECLARE
    koszt NUMBER;
BEGIN
    if :new.CZY_UTWORZONA <> :old.CZY_UTWORZONA then
        select koszt_utworzenia_marki into koszt from ustawienia_poczatkowe where czy_aktywna = 'a';
        update producenci set fundusze = fundusze - koszt where id_producenta = :old.id_producenta;
    end if;
END;
/

create or replace TRIGGER POTRACENIE_KOSZTOW_MARKETINGU 
AFTER INSERT ON MARKETINGI
FOR EACH ROW
DECLARE
id_prod NUMBER (3, 0);
BEGIN
    --okreslenie id producenta
    select id_producenta into id_prod from marki where id_marki = :new.id_marki;
    --potracenie kosztow
    update producenci set FUNDUSZE = FUNDUSZE - :new.koszt_marketingu where ID_PRODUCENTA = id_prod;
END;
/

create or replace TRIGGER REALIZUJ_PRODUKCJE
AFTER INSERT ON PRODUKCJE
for each row
DECLARE
producent number (3,0);
BEGIN
    select p.id_producenta into producent from producenci p, marki m where p.ID_PRODUCENTA = m.ID_PRODUCENTA AND m.ID_MARKI = :NEW.id_marki;
    update producenci set FUNDUSZE = FUNDUSZE - :new.koszt_produkcji where ID_PRODUCENTA = producent;
    --uaktualnienie liczby dostepnych sztuk
    update marki set AKTUALNA_LICZBA_SZTUK = AKTUALNA_LICZBA_SZTUK + :new.WOLUMEN where ID_MARKI = :NEW.id_marki;
END;
/

create or replace TRIGGER SPR_CZY_JEST_1_AKTYWNY_ZESTAW
BEFORE INSERT OR UPDATE OF czy_aktywna ON USTAWIENIA_POCZATKOWE
for each row
DECLARE
    liczba_aktywnych_opcji number;
BEGIN
    select count(numer_zestawu) into liczba_aktywnych_opcji from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';
    if :new.czy_aktywna = 'a' and liczba_aktywnych_opcji <> 0 then
        raise_application_error(-20806, 'Moze byc maksymalnie jeden aktywny zestaw ustawien poczatkowych');
    end if;
END;
/

create or replace TRIGGER SPR_CZY_WSZYSCY_SPASOWALI 
AFTER UPDATE OF CZY_SPASOWAL ON PRODUCENCI
for each row
DECLARE
    nie_spasowali number (2,0);
BEGIN
    if :new.czy_spasowal = 't' then
        --select count(id_producenta) into nie_spasowali from producenci where CZY_SPASOWAL = 'n';
        --if nie_spasowali = 0 then
            --null;
            rozpocznij_runde;
        --end if;
    end if;
END;
/

create or replace TRIGGER SPR_MOZLIWOSC_BADANIA_RYNKU 
BEFORE INSERT ON BADANIA_RYNKU
FOR EACH ROW
DECLARE
koszt NUMBER (15, 0);
fundusze_producenta NUMBER;
BEGIN
    --wstawienie nr rundy
    select max(numer_rundy) into :new.numer_rundy from NUMERY_RUND;

    --sprawdzenie czy historia nie jest za dluga
    if :new.numer_rundy - :new.HIS_ZAKUPOW_LICZBA_RUND < 1 or :new.HIS_ZAKUPOW_LICZBA_RUND > 6 then
        raise_application_error(-20802, 'Proba uzyskania historii zakupow konsumentow ze zbyt wielu rund');
    end if;

    --obliczenie kosztu
    select KOSZT_UZYSKANIA_OCEN into :new.koszt_badania_rynku from GRUPY_KONSUMENTOW where ID_GRUPY_KONSUMENTOW = :new.ID_GRUPY_KONSUMENTOW;
    select KOSZT_HIS_ZAKUP_JEDNA_TURA into koszt from GRUPY_KONSUMENTOW where ID_GRUPY_KONSUMENTOW = :new.ID_GRUPY_KONSUMENTOW;
    :new.koszt_badania_rynku := :new.koszt_badania_rynku + koszt * :new.HIS_ZAKUPOW_LICZBA_RUND;

    select p.fundusze into fundusze_producenta from producenci p, marki m where m.id_producenta = p.id_producenta and m.id_marki = :new.id_marki;
    if fundusze_producenta < :new.koszt_badania_rynku then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;

    --wstawienie id z sekwencji
    SELECT ID_BADANIA_RYNKU_SEQ.NEXTVAL
    INTO :NEW.ID_BADANIA_RYNKU
    FROM DUAL;
END;
/

create or replace TRIGGER SPR_MOZLIWOSC_MARKETINGU 
BEFORE INSERT ON MARKETINGI
FOR EACH ROW
DECLARE
koszt NUMBER (15, 0);
koszt_per_st_intensywnosci NUMBER (15, 0);
fundusze_producenta NUMBER;
BEGIN  
    --obliczenie kosztu
    select
        marketing_KOSZT_BAZOWY,
        marketing_koszt_per_st_intens
    into
        koszt,
        koszt_per_st_intensywnosci
    from
        ustawienia_poczatkowe
    where
        czy_aktywna = 'a';

    :new.koszt_marketingu := koszt + koszt_per_st_intensywnosci * :new.intensywnosc_marketingu;

    select p.fundusze into fundusze_producenta from producenci p, marki m where m.id_producenta = p.id_producenta and m.id_marki = :new.id_marki;
    if fundusze_producenta < :new.koszt_marketingu then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;

    --wstawienie id z sekwencji
    SELECT ID_MARKETINGU_SEQ.NEXTVAL
    INTO :NEW.ID_MARKETINGU
    FROM DUAL;

    --wstawienie nr rundy
    select max(numer_rundy) into :new.numer_rundy from NUMERY_RUND;
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

create or replace TRIGGER SPR_WPROWADZENIE_MARKI_NA_RYNEK
BEFORE UPDATE OF CZY_UTWORZONA ON MARKI
FOR EACH ROW
DECLARE
    koszt NUMBER;
    fundusze_producenta NUMBER;
BEGIN
    select koszt_utworzenia_marki into koszt from ustawienia_poczatkowe where czy_aktywna = 'a';
    select fundusze into fundusze_producenta from producenci where id_producenta = :old.id_producenta;

    if fundusze_producenta < koszt then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;
END;
/

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

create or replace TRIGGER UZUPELNIANIE_HISTORII_CEN 
AFTER INSERT OR UPDATE OF CENA_ZA_SZTUKE ON MARKI
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    BEGIN
        insert into HISTORIE_CEN values (:new.cena_za_sztuke, :new.id_marki, nr_rundy);
    EXCEPTION
    --przechwycenie wyjatku naruszenia wiezow integralnosci
    --taki blad moze sie pojawic w sytuacji gdy w danej rundzie cena zostala juz raz zmieniona,
    --poniewaz kluczem glownym tabeli historia cen jest para numer_rundy oraz id_marki
    --nie ma sensu tworzyc oddzielnego identyfikatora i zapamietywac wszystkich zmiany, poniewaz ostatecznie
    --znaczenie ma tylko ostatnia zmiana ceny w danej rundzie, ta ktora bedzie wplywala na zakup konsumenta
        WHEN DUP_VAL_ON_INDEX
        THEN
            UPDATE HISTORIE_CEN set cena = :new.cena_za_sztuke where id_marki = :new.id_marki and numer_rundy = nr_rundy;
        END;
END;
/

CREATE OR REPLACE TRIGGER AUTOINKREMENTACJA_NR_ZESTAWU_UST_POCZ 
BEFORE INSERT ON USTAWIENIA_POCZATKOWE 
FOR EACH ROW
BEGIN
    select NR_ZESTAWU_USTAWIEN_POCZ_SEQ.NEXTVAL
    into :new.numer_zestawu
    from dual;
    
    if :new.wym_max_cena <= :new.wym_min_cena then
        raise_application_error(-20900, 'Maksymalna przewidywana cena produktu jest mniejsza lub rowna minimalnej przewidywanej cenie produktu');
    end if;
    
    if :new.wym_kons_max_roznica_cena <= :new.wym_kons_min_roznica_cena then
        raise_application_error(-20901, 'Maksymalna roznica miedzy poziomem apiracji a poziomem rezerwacji ceny jest mniejsza lub rowna minimalnej');
    end if;
    
    if :new.wym_kons_max_roznica_jakosc <= :new.wym_kons_min_roznica_jakosc then
        raise_application_error(-20902, 'Maksymalna roznica miedzy poziomem apiracji a poziomem rezerwacji jakosci jest mniejsza lub rowna minimalnej');
    end if;
    
    if :new.wym_kons_max_roznica_his_zak <= :new.wym_kons_min_roznica_his_zak then
        raise_application_error(-20903, 'Maksymalna roznica miedzy poziomem apiracji a poziomem rezerwacji w odniesieniu do historii zakupow konsumenta jest mniejsza lub rowna minimalnej');
    end if;
    
    if :new.wym_kons_max_roznica_marketing <= :new.wym_kons_min_roznica_marketing then
        raise_application_error(-20904, 'Maksymalna roznica miedzy poziomem apiracji a poziomem rezerwacji w odniesieniu do marketingu jest mniejsza lub rowna minimalnej');
    end if;
    
END;
/