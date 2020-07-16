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

create or replace PROCEDURE LICZ_PRZYCHOD AS
aktualna_runda NUMBER;
BEGIN
    select max(numer_rundy) into aktualna_runda from numery_rund;
    FOR i IN (select id_producenta, sum(przychod) as przychod from SPRZEDAZ_P where numer_rundy = aktualna_runda group by id_producenta)
    LOOP
        update producenci set fundusze = fundusze + i.przychod where id_producenta = i.id_producenta;
    END LOOP;
END LICZ_PRZYCHOD;
/

create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
--procedura uruchamiana rozpoczyna nowa runde poprzez zwiekszenie licznika rund
BEGIN
  --przywrocenie producentom mozliwosci wykonywania dzialan
  update producenci set czy_spasowal = 'n';

  --realizacja zakupow klientow
  ZREALIZUJ_ZAKUPY;
  
  --przeliczanie i dodanie przychodu ze sprzedazy do kont producentow
  LICZ_PRZYCHOD;

  --koszty magazynowania na kolejna runde
  POTRAC_KOSZTY_MAGAZYNOWANIA;
  
  --zwiekszenie licznika rund - ! czy z sekwencja ma to sens
  insert into numery_rund values (null);
  --commit;
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
    --wstawienie domyslnych wartosci jakosci marki wraz z referencyjnymi kosztami produkcji jesli taka opcja zostala wybrana w ustawieniach poczatkowych
    select czy_jakosci_marek_domyslne into czy_wstawic_jakosci from ustawienia_poczatkowe where aktywna = 'a';
    if czy_wstawic_jakosci = 't' then
        DELETE FROM jakosci_marek CASCADE;
        WSTAW_DOMYSLNE_JAKOSCI_MAREK;
    end if;
    --stworzenie konsumentow
    GENERUJ_KONSUMENTOW;
    --stworzenie bazowych grup konsumentow
    GENERUJ_GRUPY_KONSUMENTOW;
    --restartowanie parametrow producentow, czyli graczy
    RESTART_PARAMETROW_PRODUCENTOW;
    --rozpocznij pierwsza runde
    insert into numery_rund values (1);
    commit;
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
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dostepy_producentow_his_zakup';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE oceny_marek';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE historie_cen';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE magazynowania';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE produkcje';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE przywiazania_do_marek';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE marketingi';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PRZYNALEZNOSCI_DO_GRUP';
    
    EXECUTE IMMEDIATE 'alter table badania_rynku disable constraint BADANIA_RYNKU_GR_KONSUM_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup disable constraint PRZYN_DO_GR_G_KONSUMENTOW_FK';
    EXECUTE IMMEDIATE 'truncate table GRUPY_KONSUMENTOW';
    EXECUTE IMMEDIATE 'alter table badania_rynku enable constraint BADANIA_RYNKU_GR_KONSUM_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup enable constraint PRZYN_DO_GR_G_KONSUMENTOW_FK';
    
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup disable constraint DOST_HIS_ZAKUPY_KONSUM_FK';
    EXECUTE IMMEDIATE 'truncate table zakupy_konsumentow';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup enable constraint DOST_HIS_ZAKUPY_KONSUM_FK';
    
    EXECUTE IMMEDIATE 'alter table oceny_marek disable constraint OCENY_MAREK_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup disable constraint DOST_HIS_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'truncate table badania_rynku';
    EXECUTE IMMEDIATE 'alter table oceny_marek enable constraint OCENY_MAREK_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup enable constraint DOST_HIS_BADANIA_RYNKU_FK';
    
    EXECUTE IMMEDIATE 'alter table oceny_marek disable constraint OCENY_MAREK_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table zakupy_konsumentow disable constraint ZAKUPY_KONSUM_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup disable constraint PRZYN_DO_GR_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table przywiazania_do_marek disable constraint PRZYW_DO_MAREK_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'truncate table konsumenci';
    EXECUTE IMMEDIATE 'alter table oceny_marek enable constraint OCENY_MAREK_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table zakupy_konsumentow enable constraint ZAKUPY_KONSUM_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup enable constraint PRZYN_DO_GR_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table przywiazania_do_marek enable constraint PRZYW_DO_MAREK_KONSUMENCI_FK';
    
    DELETE FROM marki CASCADE;
    DELETE FROM numery_rund CASCADE;
END WYCZYSC_TABELE;
/

create or replace PROCEDURE ZRESTARTUJ_SEKWENCJE AS 
BEGIN
    RESTART_SEKWENCJI ('LICZNIK_RUND_SEQ');
    RESTART_SEKWENCJI ('ID_MARKI_SEQ');
    RESTART_SEKWENCJI ('ID_PRODUKCJI_SEQ');
    RESTART_SEKWENCJI ('ID_RODZAJU_MARKET_SEQ');
    RESTART_SEKWENCJI ('ID_GRUPY_KONSUMENTOW_SEQ');
END ZRESTARTUJ_SEKWENCJE;
/

create or replace PROCEDURE GENERUJ_GRUPY_KONSUMENTOW
IS
    liczebnosc_grupy NUMBER;
    liczebnosc_konsumentow NUMBER;
BEGIN
    select liczba_konsumentow into liczebnosc_konsumentow from ustawienia_poczatkowe where aktywna = 'a';
    liczebnosc_grupy := ceil(liczebnosc_konsumentow / 5);
    
    insert into grupy_konsumentow values (null, liczebnosc_grupy*1000, liczebnosc_grupy*500, null);
    for i in 1..liczebnosc_grupy loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    
    insert into grupy_konsumentow values (null, liczebnosc_grupy*1000, liczebnosc_grupy*550, null);
    for i in liczebnosc_grupy+1..liczebnosc_grupy*2 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    
    insert into grupy_konsumentow values (null, liczebnosc_grupy*1100, liczebnosc_grupy*650, null);
    for i in liczebnosc_grupy*2+1..liczebnosc_grupy*3 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    
    insert into grupy_konsumentow values (null, liczebnosc_grupy*1200, liczebnosc_grupy*850, null);
    for i in liczebnosc_grupy*3+1..liczebnosc_grupy*4 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    
    insert into grupy_konsumentow values (null, liczebnosc_grupy*1300, liczebnosc_grupy*1000, null);
    for i in liczebnosc_grupy*4+1..liczebnosc_konsumentow loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    commit;
END GENERUJ_GRUPY_KONSUMENTOW;
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
        cena_aspiracja := DBMS_RANDOM.value(100, 4900);
        jakosc_aspiracja := DBMS_RANDOM.value(3, 10);
        przywiazanie_aspiracja := DBMS_RANDOM.value(1.03, 1.99);
        insert into konsumenci values (i,
                            cena_aspiracja, DBMS_RANDOM.value(cena_aspiracja + 10, 5000), --cena
                            jakosc_aspiracja, DBMS_RANDOM.value(1, jakosc_aspiracja-1), --jakosc
                            przywiazanie_aspiracja, DBMS_RANDOM.value(1.00, przywiazanie_aspiracja-0.2), --przywiazanie do marki
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
    ZAKUP_WPLYW_NA_DOCELOWA_MARKE NUMBER;
    ZAKUP_WPLYW_NA_INNE_MARKI_PRO NUMBER;
    BRAK_ZAKUPU_WPLYW_NA_MARKE NUMBER;
    NIEZASPOKOJONY_POPYT_WPLYW NUMBER;
    flaga_zakupu CHAR(1) := 'n';
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;
    select
        u.ZAKUP_WPLYW_NA_DOCELOWA_MARKE,
        u.ZAKUP_WPLYW_NA_INNE_MARKI_PRO,
        u.BRAK_ZAKUPU_WPLYW_NA_MARKE,
        u.NIEZASPOKOJONY_POPYT_WPLYW
    into
        ZAKUP_WPLYW_NA_DOCELOWA_MARKE,
        ZAKUP_WPLYW_NA_INNE_MARKI_PRO,
        BRAK_ZAKUPU_WPLYW_NA_MARKE,
        NIEZASPOKOJONY_POPYT_WPLYW 
    from ustawienia_poczatkowe u where aktywna = 'a';

    
    FOR REC IN ((SELECT id_konsumenta from konsumenci))
    LOOP  
        FOR MAR IN (SELECT id_konsumenta, id_producenta, id_marki, aktualna_liczba_sztuk, POLICZ_MPO_WYBRANE_WYMIARY(
                cena, 't',
                jakosc, 't',
                przywiazanie_do_marki, 't',
                przywiazanie_do_producenta, 't'
            ) as f_osiagniecia_oc_marki from WARTOSCI_FUNKCJI_OSIAGNIECIA_MPO_P
            where id_konsumenta = rec.id_konsumenta and czy_utworzona = 't'
            order by f_osiagniecia_oc_marki desc)
        LOOP
            if mar.aktualna_liczba_sztuk > 0 then
                insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, mar.id_marki);
                update marki set aktualna_liczba_sztuk = aktualna_liczba_sztuk - 1 where id_marki = mar.id_marki;
                --zwiekszenie przywiazania konsumenta do marki wynikajace z zakupu produktu
                update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*ZAKUP_WPLYW_NA_DOCELOWA_MARKE
                    where ID_KONSUMENTA = rec.ID_KONSUMENTA and id_marki = mar.id_marki;
                --zwiekszenie przywiazania konsumenta do innych marek producenta wynikajace z zakupu produktu
                update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*ZAKUP_WPLYW_NA_INNE_MARKI_PRO
                    where ID_KONSUMENTA = rec.ID_KONSUMENTA and id_marki IN (select id_marki from marki
                                                                            where id_producenta = mar.id_producenta and id_marki != mar.id_marki);
                --zminiejszenie przywiazania konsumenta do pozosytalych marek wynikajace z odzwyczajania/zapominania o marce
                update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*BRAK_ZAKUPU_WPLYW_NA_MARKE
                    where ID_KONSUMENTA = rec.ID_KONSUMENTA and id_marki IN (select id_marki from marki
                                                                            where id_producenta != mar.id_producenta and id_marki != mar.id_marki);
                flaga_zakupu := 't';
                exit;
            else
                update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*NIEZASPOKOJONY_POPYT_WPLYW
                    where ID_KONSUMENTA = rec.ID_KONSUMENTA and id_marki = mar.id_marki;
            end if;

        END LOOP;
        
        if flaga_zakupu = 'n' then
            insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, null);
            --zminiejszenie przywiazania konsumenta do pozosytalych marek wynikajace z odzwyczajania/zapominania o marce
            update PRZYWIAZANIA_DO_MAREK set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*BRAK_ZAKUPU_WPLYW_NA_MARKE
                    where ID_KONSUMENTA = rec.ID_KONSUMENTA;
        end if;
        
        --commit;
    END LOOP;
END ZREALIZUJ_ZAKUPY;
/

create or replace PROCEDURE OCEN_MARKE(BADANIE_RYNKU NUMBER, MARKA NUMBER, GRUPA_KONSUMENTOW NUMBER, DLUGOSC_HIS_ZAKUPOW NUMBER,
                                        UWZGLEDNIC_JAKOSC CHAR, UWZGLEDNIC_CENE CHAR, UWZGLEDNIC_STOSUNEK_DO_MARKI CHAR,
                                        UWZG_STOSUNEK_DO_PRODUCENTA CHAR
) AS
    ocena_konsumenta NUMBER;
    nr_rundy NUMBER;
    czy_docelowa_marka_utworzona NUMBER;
    liczba_wszystkich_marek NUMBER;
BEGIN
    select count(id_marki) into liczba_wszystkich_marek from marki where czy_utworzona = 't';
    --badanie rynku odbywa sie jako porownanie pewnej marki (utworzonej lub nie) z pozostalymi markami dostepnymi na rynku, czyli utworzonymi
    --jesli badana marka nie zostala jeszcze utworzona to liczebnosc zbioru analizowanych marek musi zostac zwiekszona o 1
    select count(id_marki) into czy_docelowa_marka_utworzona from marki where czy_utworzona = 'n' and id_marki = marka;
    liczba_wszystkich_marek := liczba_wszystkich_marek + czy_docelowa_marka_utworzona;
    
    FOR REC IN ((
    select id_konsumenta, sum(f_osiagniecia) as liczba_gorszych_marek from
    (
    select p.id_konsumenta, p.czy_utworzona, p.id_marki,
            CASE WHEN POLICZ_MPO_WYBRANE_WYMIARY(
                p.cena, UWZGLEDNIC_JAKOSC,
                p.jakosc, UWZGLEDNIC_CENE,
                p.przywiazanie_do_marki, UWZGLEDNIC_STOSUNEK_DO_MARKI,
                p.przywiazanie_do_producenta, UWZG_STOSUNEK_DO_PRODUCENTA
            ) < m.f_osiagniecia_oc_marki THEN 1 ELSE 0 END as f_osiagniecia
            from
        
        (
        --obliczenie funkcji osiagniecia badanej marki w celu pozniejszego stworzenia zlaczenia z analizowanymi rekordami
        select wart.id_konsumenta, przyn.id_grupy_konsumentow,
            --wyznaczenie wartosc funkcji osiagniecia na podstawie wartosci funkcji osiagniecia kazdego z parametrow
            --w zaleznosci od decyzji gracza
            POLICZ_MPO_WYBRANE_WYMIARY(
                wart.cena, UWZGLEDNIC_JAKOSC,
                wart.jakosc, UWZGLEDNIC_CENE,
                wart.przywiazanie_do_marki, UWZGLEDNIC_STOSUNEK_DO_MARKI,
                wart.przywiazanie_do_producenta, UWZG_STOSUNEK_DO_PRODUCENTA
            ) as f_osiagniecia_oc_marki
        from WARTOSCI_FUNKCJI_OSIAGNIECIA_MPO_P wart, przynaleznosci_do_grup przyn
        where wart.id_konsumenta = przyn.id_konsumenta and przyn.id_grupy_konsumentow = GRUPA_KONSUMENTOW and id_marki = marka
        ) m,
        
        WARTOSCI_FUNKCJI_OSIAGNIECIA_MPO_P p
    where
        p.ID_KONSUMENTA = m.id_konsumenta and p.czy_utworzona = 't'
    )
    group by id_konsumenta))
    LOOP
        --wpisanie oceny
        ocena_konsumenta := round((rec.liczba_gorszych_marek/liczba_wszystkich_marek)*10, 0);
        insert into oceny_marek values (rec.id_konsumenta, badanie_rynku, ocena_konsumenta);
        
        --udostepnienie producentowi historii zakupow konsumenta
        if DLUGOSC_HIS_ZAKUPOW > 0 then
            select max(numer_rundy) into nr_rundy from numery_rund;
            for i in 1..DLUGOSC_HIS_ZAKUPOW loop 
                BEGIN
                    insert into dostepy_producentow_his_zakup values (rec.id_konsumenta, nr_rundy - i, BADANIE_RYNKU);
                EXCEPTION
                --jesli gracz bedzie nierozwaznie planowal badanie rynku, to moze ponownie zakupic dostep do informacji o zakupie
                --danego klienta w danej rundzie; pojawia sie wowczas blad naruszenia wiezow integralnosci, ktory nalezy zignorowac
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        null;
                END;
            end loop;
            --commit;
        end if;
    end loop;
END OCEN_MARKE;
/

create or replace FUNCTION POLICZ_WYMIAR_MPO (POZIOM_ASPIRACJI NUMBER, POZIOM_REZERWACJI NUMBER, WARTOSC_PARAMETRU NUMBER)
RETURN NUMBER
AS
    zadowolenie NUMBER := 0.001;
    niezadowolenie NUMBER := 1000;
    wartosc_f_osiagniecia NUMBER;
    przedzial_1 NUMBER;
    przedzial_2 NUMBER;
    przedzial_3 NUMBER;
BEGIN
    przedzial_1 := zadowolenie*(wartosc_parametru - poziom_aspiracji)/(poziom_aspiracji - poziom_rezerwacji)+1;
    przedzial_2 := (wartosc_parametru - poziom_rezerwacji)/(poziom_aspiracji - poziom_rezerwacji);
    przedzial_3 := niezadowolenie*(wartosc_parametru - poziom_rezerwacji)/(poziom_aspiracji - poziom_rezerwacji);
    wartosc_f_osiagniecia := least (przedzial_1, przedzial_2, przedzial_3);
    return wartosc_f_osiagniecia;
END POLICZ_WYMIAR_MPO;
/

create or replace FUNCTION POLICZ_MPO_WYBRANE_WYMIARY (
                    CENA NUMBER, CZY_UWZGL_CENE CHAR,
                    JAKOSC NUMBER, CZY_UWZGL_JAKOSC CHAR,
                    PRZYWIAZANIE_DO_MARKI NUMBER, CZY_UWZGL_PRZYWIAZANIE_DO_MARKI CHAR,
                    PRZYWIAZANIE_DO_PRODUCENTA NUMBER, CZY_UWZGL_PRZYWIAZANIE_DO_PRODUCENTA CHAR)
RETURN NUMBER
AS
    epsilon NUMBER := 0.01;
    wartosc_f_osiagniecia NUMBER;
    suma NUMBER := 0;
    minimum NUMBER := 999999999999999.99;
BEGIN
    if CZY_UWZGL_CENE = 't' then
        suma := suma + cena;
        minimum := least(cena, minimum); 
    end if;
    
    if CZY_UWZGL_JAKOSC = 't' then
        suma := suma + jakosc;
        minimum := least(jakosc, minimum); 
    end if;
    
    if CZY_UWZGL_przywiazanie_do_marki = 't' then
        suma := suma + przywiazanie_do_marki;
        minimum := least(przywiazanie_do_marki, minimum); 
    end if;
    
    if CZY_UWZGL_przywiazanie_do_producenta = 't' then
        suma := suma + przywiazanie_do_producenta;
        minimum := least(przywiazanie_do_producenta, minimum); 
    end if;
    
    wartosc_f_osiagniecia := minimum + epsilon * suma;

    return wartosc_f_osiagniecia;
END POLICZ_MPO_WYBRANE_WYMIARY;
/