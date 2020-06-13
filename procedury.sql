create or replace PROCEDURE POTRAC_KOSZTY_MAGAZYNOWANIA AS 
    koszt NUMBER (15, 0);
    nr_rundy NUMBER (5, 0);
    sposob_nalicz_kosztow CHAR(1);
    koszt_mag_sztuki NUMBER (15, 0);
    wielkosc_pow_mag NUMBER (12, 0);
    upust_per_magazyn NUMBER (2, 0);
    upust NUMBER;
    liczba_magazynow NUMBER (6, 0);
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;
    select SPOSOB_NALICZ_KOSZT_MAGAZYN into sposob_nalicz_kosztow from USTAWIENIA_POCZATKOWE where aktywna = 'a';
    select KOSZT_MAG_SZTUKI_LUB_MAGAZYNU into koszt_mag_sztuki from USTAWIENIA_POCZATKOWE where aktywna = 'a';

    if sposob_nalicz_kosztow = 'l' then
        FOR REC IN (SELECT m.id_marki, m.aktualna_liczba_sztuk, m.ID_PRODUCENTA from marki m where aktualna_liczba_sztuk > 0)
        LOOP
            --okreslenie kosztu magazyniwania
            koszt := rec.aktualna_liczba_sztuk * koszt_mag_sztuki;
            --obciazenie kosztami konta producenta
            UPDATE producenci SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.id_producenta;
            --dodanie wpisu do tabeli historii magazynowania
            insert into magazynowania values (rec.aktualna_liczba_sztuk, koszt, nr_rundy, rec.id_marki);
        END LOOP;
    else
        select WIELKOSC_POWIERZCHNI_MAG into wielkosc_pow_mag from USTAWIENIA_POCZATKOWE where aktywna = 'a';
        select UPUST_ZA_KOLEJNY_MAGAZYN into upust_per_magazyn from USTAWIENIA_POCZATKOWE where aktywna = 'a';
  
        FOR REC IN (select sum(aktualna_liczba_sztuk) as liczba_sztuk, ID_PRODUCENTA from marki where aktualna_liczba_sztuk > 0 group by ID_PRODUCENTA)
        LOOP
            --okreslenie jaki upust przysluguje za liczbe wynajetych magazynow; ostateczny upust nie moze byc wiekszy niz 50%
            liczba_magazynow := CEIL(rec.liczba_sztuk/wielkosc_pow_mag);
            upust := liczba_magazynow*upust_per_magazyn;
            if upust > 50 then
                upust := 50;
            end if;
            --okreslenie kosztu magazynowania wszystkich marek producenta; symuluje to sytuacje napelniania magzynow produktami roznych marek
            --liczenie kosztu oddzielnie dla kazdej marki oznaczaloby ze producent musi oddzielnie magazynowac produkty kazdej z marek i nie moze wykorzystac wolnej przestrzeni
            --oplaconej w ramach magazynowania innej marki
            koszt := CEIL(rec.liczba_sztuk/wielkosc_pow_mag) * koszt_mag_sztuki * (100-upust)/100;
            --obciazenie kosztami konta producenta
            UPDATE producenci SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.ID_PRODUCENTA;
            --dodanie wpisow do tabeli historii magazynowania
            FOR MAR IN (select id_marki, aktualna_liczba_sztuk, ID_PRODUCENTA from marki where ID_PRODUCENTA = rec.ID_PRODUCENTA)
            LOOP
                insert into magazynowania values (mar.aktualna_liczba_sztuk, koszt*(mar.aktualna_liczba_sztuk/rec.liczba_sztuk), nr_rundy, mar.id_marki);
            END LOOP;
         END LOOP;
    end if;
END POTRAC_KOSZTY_MAGAZYNOWANIA;
/

create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
--procedura uruchamiana rozpoczyna nowa runde poprzez zwiekszenie licznika rund
BEGIN
  --zwiekszenie licznika rund - ! czy z sekwencja ma to sens
  insert into numery_rund values (null);
  
  --przywrocenie producentom mozliwosci wykonywania dzialan
  update producenci set czy_spasowal = 'n';

  --realizacja zakupow klientow
  ZREALIZUJ_ZAKUPY;

  --koszty magazynowania na kolejna runde
  POTRAC_KOSZTY_MAGAZYNOWANIA;
END ROZPOCZNIJ_RUNDE;
/

create or replace PROCEDURE ROZPOCZNIJ_GRE AS
    czy_wstawic_jakosci char(1);
BEGIN
    --sprawdzenie czy wybrana opcja istnieje
    declare
        aktywna_opcja number;
    BEGIN
        select count(numer_zestawu) into aktywna_opcja from USTAWIENIA_POCZATKOWE where aktywna = 'a';
        if aktywna_opcja <> 1 then
            raise_application_error(-20805, 'Brak aktywnego zestawu ustawien poczatkowych');
        end if;
    END;
    --czyszczenie zawartosci po poprzedniej grze
    WYCZYSC_TABELE;
    --restartowanie sekwencji
    ZRESTARTUJ_SEKWENCJE;
    --stworzenie konsumentow
    GENERUJ_KONSUMENTOW;
    --wstawienie domyslnych wartosci jakosci marki wraz z referencyjnymi kosztami produkcji jesli taka opcja zostala wybrana w ustawieniach poczatkowych
    select czy_jakosci_marek_domyslne into czy_wstawic_jakosci from ustawienia_poczatkowe where aktywna = 'a';
    if czy_wstawic_jakosci = 't' then
        WSTAW_DOMYSLNE_JAKOSCI_MAREK;
    end if;
    --stworzenie uzytkownikow i dodanie ich do tabeli producentow
    RESTART_PARAMETROW_PRODUCENTOW;
    --rozpocznij pierwsza runde
    insert into numery_rund values (null);
END ROZPOCZNIJ_GRE;
/

create or replace PROCEDURE RESTART_PARAMETROW_PRODUCENTOW AS 
    pocz_fundusze number (10, 0);
BEGIN
    select poczatkowe_fundusze into pocz_fundusze from ustawienia_poczatkowe where aktywna = 'a';
    update PRODUCENCI set FUNDUSZE = pocz_fundusze, CZY_SPASOWAL = 'n';
    commit;
END RESTART_PARAMETROW_PRODUCENTOW;
/


create or replace PROCEDURE RESTART_SEKWENCJI ( NAZWA_SEKWENCJI varchar2 ) AS
    tmp number;
BEGIN
    execute immediate
    'select ' || NAZWA_SEKWENCJI || '.nextval from dual' INTO tmp;

    execute immediate
    'alter sequence ' || NAZWA_SEKWENCJI || ' increment by -' || tmp || ' minvalue 0';

    execute immediate
    'select ' || NAZWA_SEKWENCJI || '.nextval from dual' INTO tmp;

    execute immediate
    'alter sequence ' || NAZWA_SEKWENCJI || ' increment by 1 minvalue 0';
    
END RESTART_SEKWENCJI;
/

create or replace PROCEDURE WYCZYSC_TABELE AS 
BEGIN
    --czyszczenie
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dostepy_producentow_his_zakup';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE oceny_marek';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE historie_cen';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE magazynowania';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE produkcje';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE przywiazania_do_marek';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE marketingi';
    
    DELETE FROM PRZYNALEZNOSCI_DO_GRUP CASCADE;
    DELETE FROM GRUPY_KONSUMENTOW CASCADE;
    DELETE FROM zakupy_konsumentow CASCADE;
    DELETE FROM badania_rynku CASCADE;
    DELETE FROM marki CASCADE;
    DELETE FROM jakosci_marek CASCADE;
    DELETE FROM numery_rund CASCADE;
    DELETE FROM konsumenci CASCADE;
    commit;
END WYCZYSC_TABELE;
/

create or replace PROCEDURE ZRESTARTUJ_SEKWENCJE AS 
BEGIN
    RESTART_SEKWENCJI ('LICZNIK_RUND_SEQ');
    RESTART_SEKWENCJI ('ID_MARKI_SEQ');
    RESTART_SEKWENCJI ('ID_PRODUKCJI_SEQ');
    RESTART_SEKWENCJI ('ID_RODZAJU_MARKET_SEQ');
END ZRESTARTUJ_SEKWENCJE;
/

create or replace PROCEDURE GENERUJ_KONSUMENTOW
IS
    liczba_kons number(10, 0);
    cena_aspiracja number (5, 0);
    jakosc_aspiracja number (2, 0);
    przywiazanie_aspiracja number (4, 2); 
BEGIN
    select liczba_konsumentow into liczba_kons from ustawienia_poczatkowe where aktywna = 'a';
    FOR i IN 1 ..liczba_kons LOOP
        cena_aspiracja := DBMS_RANDOM.value(100, 9999);
        jakosc_aspiracja := DBMS_RANDOM.value(10, 99);
        przywiazanie_aspiracja := DBMS_RANDOM.value(0.01, 99.99);
        insert into konsumenci values (i,
                            cena_aspiracja, DBMS_RANDOM.value(cena_aspiracja + 1, 10000), --cena
                            jakosc_aspiracja, DBMS_RANDOM.value(1, jakosc_aspiracja-1), --jakosc
                            przywiazanie_aspiracja, DBMS_RANDOM.value(0.01, przywiazanie_aspiracja), --przywiazanie do marki
                            DBMS_RANDOM.value(0.1, 0.99)); --podatnosc na marketing
    END LOOP;
END GENERUJ_KONSUMENTOW;
/

create or replace PROCEDURE WSTAW_DOMYSLNE_JAKOSCI_MAREK
IS
BEGIN
   insert into jakosci_marek values (1, 1000);
   insert into jakosci_marek values (2, 1100);
   insert into jakosci_marek values (3, 1200);
   insert into jakosci_marek values (4, 1300);
   insert into jakosci_marek values (5, 1400);
   commit;
END WSTAW_DOMYSLNE_JAKOSCI_MAREK;
/

create or replace PROCEDURE ZREALIZUJ_ZAKUPY AS
    nr_rundy NUMBER;
    wybrana_marka NUMBER;
    wspolczynnik_modyfikacji NUMBER;
    max_ocena NUMBER;
    ocena_klienta NUMBER;
    zadowolenie NUMBER := 0.001;
    niezadowolenie NUMBER := 1000;
    f_cena NUMBER;
    f_cena_1 NUMBER;
    f_cena_2 NUMBER;
    f_cena_3 NUMBER;
    f_jakosc NUMBER;
    f_jakosc_1 NUMBER;
    f_jakosc_2 NUMBER;
    f_jakosc_3 NUMBER;
    f_przywiazanie NUMBER;
    f_przywiazanie_1 NUMBER;
    f_przywiazanie_2 NUMBER;
    f_przywiazanie_3 NUMBER;
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;

    FOR REC IN ((SELECT * from konsumenci))
    LOOP
        FOR MAR IN (SELECT m.id_marki, m.cena_za_sztuke as cena, m.JAKOSC_MARKI as jakosc,  m.AKTUALNA_LICZBA_SZTUK, p.WSPOLCZYNNIK_PRZYWIAZANIA as przywiazanie from marki m, PRZYWIAZANIA_DO_MAREK p
                        where m.ID_MARKI = p.ID_MARKI and p.ID_KONSUMENTA = REC.id_konsumenta)
        LOOP
            --wyznaczenie wartosci funkcji dla kazdego z parametrow
            --cena
            f_cena_1 := zadowolenie*(mar.cena - rec.cena_poziom_aspiracji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji)+1;
            f_cena_2 := (mar.cena - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena_3 := niezadowolenie*(mar.cena - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena := least (f_cena_1, f_cena_2, f_cena_3);
            --jakosc
            f_jakosc_1 := zadowolenie*(mar.jakosc - rec.jakosc_poziom_aspiracji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji)+1;
            f_jakosc_2 := (mar.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc_3 := niezadowolenie*(mar.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc := least (f_jakosc_1, f_jakosc_2, f_jakosc_3);
            --przywiazanie
            f_przywiazanie_1 := zadowolenie*(mar.przywiazanie - rec.przywiazanie_poziom_aspiracji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji)+1;
            f_przywiazanie_2 := (mar.przywiazanie - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
            f_przywiazanie_3 := niezadowolenie*(mar.przywiazanie - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
            f_przywiazanie := least (f_przywiazanie_1, f_przywiazanie_2, f_przywiazanie_3);

            --ostateczna ocena
            ocena_klienta := round (least (f_cena, f_jakosc, f_przywiazanie) + 0.01*(f_cena + f_jakosc + f_przywiazanie), 10);
            update marki set tymczasowa_ocena_klienta = ocena_klienta where id_marki = mar.id_marki;
        END LOOP;

        select max(tymczasowa_ocena_klienta) into max_ocena from marki where AKTUALNA_LICZBA_SZTUK > 0;         
        --jesli nie ma produktow zadnej marki to konsument nabywa produkt socjalny, czyli w historii zakupow wpisywany jest null
        if max_ocena is not null then
            select id_marki into wybrana_marka from marki where tymczasowa_ocena_klienta = max_ocena;
            update marki set aktualna_liczba_sztuk = aktualna_liczba_sztuk - 1 where id_marki = wybrana_marka;
            insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, wybrana_marka);
        else
            insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, null);
        end if;
        commit;

        --wszystkie marki ktore byly ocenione wyzej niz produkt tej zakupionej nie zaspokoily oczekiwan klienta, wiec traca w jego oczach
        select niezaspokojony_popyt_wplyw into wspolczynnik_modyfikacji from USTAWIENIA_POCZATKOWE where aktywna = 'a';
        FOR OC IN (select m.id_marki, p.id_konsumenta from marki m, PRZYWIAZANIA_DO_MAREK p
                    where m.ID_MARKI = p.ID_MARKI and p.ID_KONSUMENTA = REC.id_konsumenta and m.tymczasowa_ocena_klienta > max_ocena)
        LOOP
            update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*wspolczynnik_modyfikacji
            where ID_KONSUMENTA = OC.ID_KONSUMENTA and id_marki = oc.id_marki;
        END LOOP;
    END LOOP;
END ZREALIZUJ_ZAKUPY;
/