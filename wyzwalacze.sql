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

create or replace TRIGGER AUTOINKREMENTACJA_ID_PRODUCENTA 
BEFORE INSERT ON PRODUCENCI
for each row
BEGIN
    --autoinkrementacja id
    SELECT ID_PRODUCENTA_SEQ.NEXTVAL
    INTO :NEW.ID_PRODUCENTA
    FROM DUAL;
    
    SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
    select poczatkowe_fundusze into :new.fundusze from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';
    
    :new.czy_spasowal := 'n';
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
AFTER UPDATE OF runda_utworzenia ON MARKI
FOR EACH ROW
DECLARE
    koszt NUMBER;
    koszt_produkcji NUMBER;
    nr_rundy NUMBER;
BEGIN


    if :old.runda_utworzenia is null then
        SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
        select koszt_utworzenia_marki into koszt from ustawienia_poczatkowe where czy_aktywna = 'a';
        update producenci set fundusze = fundusze - koszt where id_producenta = :old.id_producenta;
        
        --wpisanie kosztu produkcji
        select max(numer_rundy) into nr_rundy from NUMERY_RUND;
        select ref_koszt_produkcji_sztuki into koszt_produkcji from JAKOSCI_MAREK where jakosc_marki = :old.jakosc_marki;
        insert into koszty_produkcji_produktow values (:old.id_marki, koszt_produkcji, nr_rundy);
    end if;
END;
/

create or replace TRIGGER POTRACENIE_KOSZTOW_MARKETINGU 
AFTER INSERT ON MARKETINGI
FOR EACH ROW
DECLARE
    koszt NUMBER;
    koszt_per_st_intensywnosci NUMBER;
    fundusze_producenta NUMBER;
    id_prod NUMBER;
BEGIN  
    select id_producenta into id_prod from marki where id_marki = :new.id_marki;
    
    select
        KOSZT_BAZOWY, koszt_per_st_intens
    into
        koszt, koszt_per_st_intensywnosci
    from(
        select 
            KOSZT_BAZOWY, koszt_per_st_intens
        from
            koszty_marketingu
        where
            id_producenta = id_prod
        order by
            numer_rundy desc)
    where
        rownum = 1;
        
    
    koszt := koszt + koszt_per_st_intensywnosci * :new.intensywnosc_marketingu;
    --potracenie kosztow
    update producenci set FUNDUSZE = FUNDUSZE - koszt where ID_PRODUCENTA = id_prod;
END;
/

create or replace TRIGGER REALIZUJ_PRODUKCJE
AFTER INSERT ON PRODUKCJE
for each row
DECLARE
    id_prod NUMBER;
    koszt NUMBER;
    KOSZT_PRODUKCJ_sztuki NUMBER;
BEGIN 
    select
        KOSZT_PRODUKCJI
    into
        KOSZT_PRODUKCJ_sztuki
    from(
        select 
            KOSZT_PRODUKCJI
        from
            KOSZTY_PRODUKCJI_PRODUKTOW
        where
            id_marki = :new.id_marki
        order by
            numer_rundy desc)
    where
        rownum = 1;
    
    koszt := KOSZT_PRODUKCJ_sztuki * :new.wolumen;

    select m.id_producenta into id_prod from marki m where m.id_marki = :new.id_marki;
    update producenci set FUNDUSZE = FUNDUSZE - koszt where ID_PRODUCENTA = id_prod;
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

create or replace TRIGGER SPR_MOZLIWOSC_BADANIA_RYNKU 
BEFORE INSERT ON BADANIA_RYNKU
FOR EACH ROW
DECLARE
koszt NUMBER (15, 0);
fundusze_producenta NUMBER;
licznosc_gr number;
BEGIN
    --wstawienie nr rundy
    select max(numer_rundy) into :new.numer_rundy from NUMERY_RUND;

    --sprawdzenie czy historia nie jest za dluga
    if :new.numer_rundy - :new.HIS_ZAKUPOW_LICZBA_RUND < 1 or :new.HIS_ZAKUPOW_LICZBA_RUND > 6 then
        raise_application_error(-20802, 'Proba uzyskania historii zakupow konsumentow ze zbyt wielu rund');
    end if;
    
    --sprawdzenie czy do wybranej grupy konsumentow nalezychoc jeden konsument
    select count(id_grupy_konsumentow) into licznosc_gr from przynaleznosci_do_grup where id_grupy_konsumentow = :new.id_grupy_konsumentow;
    if licznosc_gr < 1 then
        raise_application_error(-20803, 'Proba przeprowadzenia badania na pustej grupie konsumentow');
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
id_prod NUMBER;
BEGIN  
    select p.id_producenta into id_prod from producenci p, marki m where m.id_producenta = p.id_producenta and m.id_marki = :new.id_marki;
    
    select
        KOSZT_BAZOWY, koszt_per_st_intens
    into
        koszt, koszt_per_st_intensywnosci
    from(
        select 
            KOSZT_BAZOWY, koszt_per_st_intens
        from
            koszty_marketingu
        where
            id_producenta = id_prod
        order by
            numer_rundy desc)
    where
        rownum = 1;
        

    koszt := koszt + koszt_per_st_intensywnosci * :new.intensywnosc_marketingu;

    select p.fundusze into fundusze_producenta from producenci p where p.id_producenta = id_prod;
    if fundusze_producenta < koszt then
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
koszt NUMBER;
BEGIN
    --autoinkrementacja id
    SELECT ID_PRODUKCJI_SEQ.NEXTVAL
    INTO :NEW.ID_PRODUKCJI
    FROM DUAL;
    
    select
        KOSZT_PRODUKCJI
    into
        koszt
    from(
        select 
            KOSZT_PRODUKCJI
        from
            KOSZTY_PRODUKCJI_PRODUKTOW
        where
            id_marki = :NEW.id_marki
        order by
            numer_rundy desc)
    where
        rownum = 1;

    --ustawienie kosztu i sprawdzenie czy producent ma fundusze
    select p.fundusze into fund from producenci p, marki m where p.id_producenta = m.id_producenta and m.id_marki = :new.id_marki;
    
    koszt := koszt * :new.wolumen;
    if fund < koszt then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;

    --dodanie numeru rundy
    select max(numer_rundy) into :new.numer_rundy from numery_rund;
END;
/

create or replace TRIGGER SPR_WPROWADZENIE_MARKI_NA_RYNEK
BEFORE UPDATE OF RUNDA_UTWORZENIA ON MARKI
FOR EACH ROW
DECLARE
    koszt NUMBER;
    fundusze_producenta NUMBER;
BEGIN
    if :new.runda_utworzenia is null and :old.runda_utworzenia is not null then
        raise_application_error(-20808, 'Marka zostala wprowadzona na rynek i nie mozna tego zmienic!');
    end if;
    
    select koszt_utworzenia_marki into koszt from ustawienia_poczatkowe where czy_aktywna = 'a';
    select fundusze into fundusze_producenta from producenci where id_producenta = :old.id_producenta;

    if fundusze_producenta < koszt then
        raise_application_error(-20801, 'Niewystarczajce fundusze');
    end if;
    
    select max(numer_rundy) into :new.runda_utworzenia from numery_rund;
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
  
  :new.runda_utworzenia := null;
END;
/

create or replace TRIGGER UZUPELNIANIE_HISTORII_CEN 
AFTER INSERT OR UPDATE OF CENA_ZA_SZTUKE ON MARKI
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    if :new.cena_za_sztuke <= 0 then
        raise_application_error(-20950, 'Cena musi byc wieksza od 0.');
    end if;

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
    
    if :new.wym_kons_max_roznica_cena <= :new.wym_kons_min_roznica_cena or :new.wym_kons_max_roznica_cena > (:new.wym_max_cena - :new.wym_min_cena) then
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
    
    if :new.warunek_zakonczenia_rundy = 'c' and :new.czas_rundy is null then
        raise_application_error(-20905, 'Przy wybranym warunku zakonczenia rundy czas rundy jest wymagany');
    end if;
    
    if :new.ref_sposob_nalicz_koszt_mag = 'm' and (:new.ref_wielkosc_powierzchni_mag is null or :new.ref_upust_za_kolejny_magazyn is null) then
        raise_application_error(-20906, 'Przy wybranym warunku zakonczenia rundy czas rundy jest wymagany');
    end if;
END;
/


create or replace TRIGGER WPROWADZANIE_NOWEJ_CENY_PRODUKCJI 
BEFORE INSERT ON KOSZTY_PRODUKCJI_PRODUKTOW
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
zlecone_produkcje number;
BEGIN
    /*
    nie mozna wpisac nowej ceny produkcji marki jesli w danej rundzie producent zlecil juz jakas produkcje wybranej marki,
    poniewaz dla wszystkich produkcji produktow danej marki w jednej rundzie musi obowiazywac jedna cena
    ma to na celu przypisanie zmian parametrow do miary czasu, jaki w symulatorze stanowi runda - w danej rundzie obowiazuje taka cena,
    w nastepnej inna, ale przez cala runde ta sama
    proba monitorowania zmian na przestrzeni rundy pociagalaby za soba koniecznosc zapisywania czasu realizacji kazdej z operacji
    */
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    
    select count(id_marki) into zlecone_produkcje from produkcje where numer_rundy = nr_rundy and id_marki = :new.id_marki;
    if zlecone_produkcje > 0 then
        raise_application_error(-20881, 'W tej rundzie zlecono juz produkcje po poprzedniej cenie');
    end if;
    
    :new.numer_rundy := nr_rundy;

END;
/

create or replace TRIGGER AKTUALIZOWANIE_CENY_PRODUKCJI 
BEFORE UPDATE ON KOSZTY_PRODUKCJI_PRODUKTOW
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
zlecone_produkcje number;
BEGIN
    /*
    nie mozna wpisac nowej ceny produkcji marki jesli w danej rundzie producent zlecil juz jakas produkcje wybranej marki,
    poniewaz dla wszystkich produkcji produktow danej marki w jednej rundzie musi obowiazywac jedna cena
    ma to na celu przypisanie zmian parametrow do miary czasu, jaki w symulatorze stanowi runda - w danej rundzie obowiazuje taka cena,
    w nastepnej inna, ale przez cala runde ta sama
    proba monitorowania zmian na przestrzeni rundy pociagalaby za soba koniecznosc zapisywania czasu realizacji kazdej z operacji
    */
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    
    if :old.numer_rundy != nr_rundy then
        raise_application_error(-20882, 'Dozwolone jest tylko modyfikowanie wartosci odnoszacych sie do aktualnej rundy');
    end if;
    
    select count(id_marki) into zlecone_produkcje from produkcje where numer_rundy = nr_rundy and id_marki = :new.id_marki;
    if zlecone_produkcje > 0 then
        raise_application_error(-20881, 'W tej rundzie zlecono juz produkcje po poprzedniej cenie');
    end if;
    
    :new.numer_rundy := nr_rundy;
END;
/

create or replace TRIGGER WPROWADZANIE_NOWEJ_CENY_MARKETINGU 
BEFORE INSERT ON KOSZTY_MARKETINGU
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
przeprowadzone_kampanie number;
BEGIN
    /*
    nie mozna wpisac nowej ceny marketingu jesli w danej rundzie producent przeprowadzil juz jakas kampanie,
    poniewaz dla wszystkich kampanii w jednej rundzie musi obowiazywac jedna cena
    ma to na celu przypisanie zmian parametrow do miary czasu, jaki w symulatorze stanowi runda - w danej rundzie obowiazuje taka cena,
    w nastepnej inna, ale przez cala runde ta sama
    proba monitorowania zmian na przestrzeni rundy pociagalaby za soba koniecznosc zapisywania czasu realizacji kazdej z operacji
    */
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    
    select count(m.id_marketingu) into przeprowadzone_kampanie from marketingi m, marki p 
        where numer_rundy = nr_rundy and p.id_marki = m.id_marki and p.id_producenta = :new.id_producenta;
    
    if przeprowadzone_kampanie > 0 then
        raise_application_error(-20883, 'W tej rundzie przeprowadzono juz kampanie marketingowa po poprzedniej cenie');
    end if;
    
    :new.numer_rundy := nr_rundy;

END;
/

create or replace TRIGGER AKTUALIZOWANIE_CENY_MARKETINGU 
BEFORE UPDATE ON KOSZTY_MARKETINGU
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
przeprowadzone_kampanie number;
BEGIN
    /*
    nie mozna wpisac nowej ceny marketingu jesli w danej rundzie producent przeprowadzil juz jakas kampanie,
    poniewaz dla wszystkich kampanii w jednej rundzie musi obowiazywac jedna cena
    ma to na celu przypisanie zmian parametrow do miary czasu, jaki w symulatorze stanowi runda - w danej rundzie obowiazuje taka cena,
    w nastepnej inna, ale przez cala runde ta sama
    proba monitorowania zmian na przestrzeni rundy pociagalaby za soba koniecznosc zapisywania czasu realizacji kazdej z operacji
    */
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    
    if :old.numer_rundy != nr_rundy then
        raise_application_error(-20882, 'Dozwolone jest tylko modyfikowanie wartosci odnoszacych sie do aktualnej rundy');
    end if;
    
    select count(m.id_marketingu) into przeprowadzone_kampanie from marketingi m, marki p 
        where numer_rundy = nr_rundy and p.id_marki = m.id_marki and p.id_producenta = :new.id_producenta;
    
    if przeprowadzone_kampanie > 0 then
        raise_application_error(-20884, 'W tej rundzie przeprowadzono juz kampanie marketingowa po poprzedniej cenie');
    end if;
    
    :new.numer_rundy := nr_rundy;
END;
/

create or replace TRIGGER AKTUALIZOWANIE_KOSZTOW_MAGAZYNOWANIA 
BEFORE UPDATE ON KOSZTY_MAGAZYNOWANIA
FOR EACH ROW
DECLARE
nr_rundy number (5,0);
BEGIN
    select max(numer_rundy) into nr_rundy from NUMERY_RUND;
    
    if :old.numer_rundy != nr_rundy then
        raise_application_error(-20882, 'Dozwolone jest tylko modyfikowanie wartosci odnoszacych sie do aktualnej rundy');
    end if;
    
    :new.numer_rundy := nr_rundy;
END;
/


create or replace TRIGGER SPR_MOZLIWOSC_DODANIA_KONSUMENTA_DO_GR
--jezeli grupa zostala juz wykorzystana w badaniu rynku, wowczas nie mozna modyfikowac
--jej skladu, poniewaz uniemozliwiloby to efektywne porownywanie wynikow badania
BEFORE INSERT OR DELETE OR UPDATE ON PRZYNALEZNOSCI_DO_GRUP
FOR EACH ROW
DECLARE
    uzycia_gr number;
BEGIN  
    select count(id_grupy_konsumentow) into uzycia_gr from badania_rynku where id_grupy_konsumentow = :new.id_grupy_konsumentow;
    if uzycia_gr > 0 then
        raise_application_error(-20970, 'Nie mozna dodac konsumenta do grupy, poniewaz zostala ona juz wykorzystana w badaniu rynku');
    end if;
END;
/


create or replace TRIGGER SPR_MOZLIWOSC_USUNIECIA_GR_KONSUMENTOW
--jezeli grupa zostala juz wykorzystana w badaniu rynku, wowczas nie mozna jej usunac,
--poniewaz utracone zostalyby powiazania i informacje zdobyte podczas badania
BEFORE DELETE ON GRUPY_KONSUMENTOW
FOR EACH ROW
DECLARE
    uzycia_gr number;
BEGIN  
    select count(id_grupy_konsumentow) into uzycia_gr from badania_rynku where id_grupy_konsumentow = :new.id_grupy_konsumentow;
    if uzycia_gr > 0 then
        raise_application_error(-20971, 'Nie mozna usunac grupy, poniewaz zostala ona juz wykorzystana w badaniu rynku');
    end if;
END;
/