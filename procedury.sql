create or replace PROCEDURE GENERUJ_JAKOSCI_MARKI AS 
BEGIN
  --temp version
    FOR i IN 1 ..99 LOOP
        insert into rodzaje_marek values (i, 1000*i, 100*i);
    END LOOP;
END GENERUJ_JAKOSCI_MARKI;
/


create or replace PROCEDURE GENERUJ_KONSUMENTOW (wybrana_opcja number)
IS
    liczba_kons number(10, 0);
    cena_aspiracja number (5, 0);
    jakosc_aspiracja number (2, 0);
    przywiazanie_aspiracja number (4, 2); 
BEGIN
    select liczba_konsumentow into liczba_kons from ustawienia_poczatkowe where numer_opcji = wybrana_opcja;
    FOR i IN 1 ..liczba_kons LOOP
        cena_aspiracja := DBMS_RANDOM.value(100, 9999);
        jakosc_aspiracja := DBMS_RANDOM.value(10, 99);
        przywiazanie_aspiracja := DBMS_RANDOM.value(0.01, 99.99);
        insert into konsument values (i,
                            cena_aspiracja, DBMS_RANDOM.value(cena_aspiracja + 1, 10000), DBMS_RANDOM.value(1.01, 1.5), DBMS_RANDOM.value(0.5, 1), --cena
                            jakosc_aspiracja, DBMS_RANDOM.value(1, jakosc_aspiracja-1), DBMS_RANDOM.value(1.01, 1.5), DBMS_RANDOM.value(0.5, 1), --jakosc
                            przywiazanie_aspiracja, DBMS_RANDOM.value(0.01, przywiazanie_aspiracja), DBMS_RANDOM.value(1.01, 1.5), DBMS_RANDOM.value(0.5, 1), --przywiazanie do marki
                            DBMS_RANDOM.value(0.1, 0.99)); --podatnosc na marketing
    END LOOP;
END GENERUJ_KONSUMENTOW;
/


create or replace PROCEDURE OCEN_HIPOTETYCZNA_MARKE (ID_producenta NUMBER, CZY_UWZGLEDNIC_PRODUCENTA CHAR, ID_BADANIA_RYNKU NUMBER, LICZBA_KONSUMENTOW NUMBER, DLUGOSC_HIS_ZAKUPOW NUMBER) AS
    ocena_klienta NUMBER;
    nr_rundy NUMBER;
    f_cena NUMBER;
    f_cena_1 NUMBER;
    f_cena_2 NUMBER;
    f_cena_3 NUMBER;
    f_jakosc NUMBER;
    f_jakosc_1 NUMBER;
    f_jakosc_2 NUMBER;
    f_jakosc_3 NUMBER;
    stos_do_producenta NUMBER;
    f_stos_do_producenta NUMBER;
    f_stos_do_producenta_1 NUMBER;
    f_stos_do_producenta_2 NUMBER;
    f_stos_do_producenta_3 NUMBER;
BEGIN
    FOR REC IN (SELECT k.*, h.id_hipotetycznej_marki, h.rodzaje_marek_jakosc_marki as jakosc, h.cena_za_sztuke from hipotetyczna_marka h, 
                (SELECT * FROM   
                    (SELECT * FROM konsument
                    ORDER BY dbms_random.value)  
                    WHERE rownum <= LICZBA_KONSUMENTOW) k
                WHERE h.producent_id_producenta = ID_producenta and h.CZY_UWZGLEDNIC_W_BADANIU = 't')
        LOOP
            --wyznaczenie wartosci funkcji dla kazdego z parametrow
            --cena
            f_cena_1 := rec.cena_zadowolenie*(rec.cena_za_sztuke - rec.cena_poziom_aspiracji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji)+1;
            f_cena_2 := (rec.cena_za_sztuke - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena_3 := rec.cena_niezadowolenie*(rec.cena_za_sztuke - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena := least (f_cena_1, f_cena_2, f_cena_3);
            --jakosc
            f_jakosc_1 := rec.jakosc_zadowolenie*(rec.jakosc - rec.jakosc_poziom_aspiracji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji)+1;
            f_jakosc_2 := (rec.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc_3 := rec.jakosc_niezadowolenie*(rec.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc := least (f_jakosc_1, f_jakosc_2, f_jakosc_3);

            --stosunek_do_producenta
            -- tylko jesli producent bedzie tego chcial
            if CZY_UWZGLEDNIC_PRODUCENTA = 't' then
                select avg(p.WSPOLCZYNNIK_PRZYWIAZANIA) into stos_do_producenta from przywiazanie_do_marki p, marka m
                    where m.ID_MARKI = p.MARKA_ID_MARKI and m.PRODUCENT_ID_PRODUCENTA = ID_producenta and p.KONSUMENT_ID_KONSUMENTA = rec.id_konsumenta;

                f_stos_do_producenta_1 := rec.przywiazanie_zadowolenie*(stos_do_producenta - rec.przywiazanie_poziom_aspiracji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji)+1;
                f_stos_do_producenta_2 := (stos_do_producenta - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
                f_stos_do_producenta_3 := rec.przywiazanie_niezadowolenie*(stos_do_producenta - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
                f_stos_do_producenta := least (f_stos_do_producenta_1, f_stos_do_producenta_2, f_stos_do_producenta_3);

                ocena_klienta := round (least (f_cena, f_jakosc, f_stos_do_producenta) + 0.01*(f_cena + f_jakosc + f_stos_do_producenta), 10);
            else
                ocena_klienta := round (least (f_cena, f_jakosc) + 0.01*(f_cena + f_jakosc), 10);
            end if;

            insert into ocena_hipotetycznej_marki values (rec.id_konsumenta, id_badania_rynku, ocena_klienta, rec.id_hipotetycznej_marki);
            commit;
            --udostepnienie producentowi historii zakupow konsumenta
            if DLUGOSC_HIS_ZAKUPOW > 0 then
                select max(numer_rundy) into nr_rundy from licznik_rund;
                for i in 1..DLUGOSC_HIS_ZAKUPOW loop
                    insert into dostep_producenta_his_zakup values (rec.id_konsumenta, nr_rundy - i, ID_BADANIA_RYNKU);
                end loop;
                commit;
            end if;           
        END LOOP;
END OCEN_HIPOTETYCZNA_MARKE;
/


create or replace PROCEDURE POTRAC_KOSZTY_MAGAZYNOWANIA (nr_opcji_ustawien NUMBER) AS 
    koszt NUMBER (15, 0);
    nr_rundy NUMBER (5, 0);
    sposob_nalicz_kosztow CHAR(1);
    koszt_mag_sztuki NUMBER (15, 0);
    wielkosc_pow_mag NUMBER (12, 0);
    upust_per_magazyn NUMBER (2, 0);
    upust NUMBER;
    liczba_magazynow NUMBER (6, 0);
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    select SPOSOB_NALICZ_KOSZT_MAGAZYN into sposob_nalicz_kosztow from USTAWIENIA_POCZATKOWE where NUMER_OPCJI = nr_opcji_ustawien;
    select "KOSZT_MAG_SZTUKI/POWIERZCHNI" into koszt_mag_sztuki from USTAWIENIA_POCZATKOWE where NUMER_OPCJI = nr_opcji_ustawien;

    if sposob_nalicz_kosztow = 'l' then
        FOR REC IN (SELECT m.id_marki, m.aktualna_liczba_sztuk, m.PRODUCENT_ID_PRODUCENTA from marka m)
        LOOP
            --okreslenie kosztu magazyniwania
            koszt := rec.aktualna_liczba_sztuk * koszt_mag_sztuki;
            --obciazenie kosztami konta producenta
            UPDATE producent SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.producent_id_producenta;
            --dodanie wpisu do tabeli historii magazynowania
            insert into magazynowanie values (rec.aktualna_liczba_sztuk, koszt, nr_rundy, rec.id_marki);
        END LOOP;
    else
        select WIELKOSC_POWIERZCHNI_MAG into wielkosc_pow_mag from USTAWIENIA_POCZATKOWE where NUMER_OPCJI = nr_opcji_ustawien;
        select UPUST_ZA_KOLEJNA_PRZEST_MAG into upust from USTAWIENIA_POCZATKOWE where NUMER_OPCJI = nr_opcji_ustawien;
  
        FOR REC IN (select sum(aktualna_liczba_sztuk) as liczba_sztuk, PRODUCENT_ID_PRODUCENTA from marka group by PRODUCENT_ID_PRODUCENTA)
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
            UPDATE producent SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.producent_id_producenta;
            --dodanie wpisow do tabeli historii magazynowania
            FOR MAR IN (select id_marki, aktualna_liczba_sztuk, PRODUCENT_ID_PRODUCENTA from marka where PRODUCENT_ID_PRODUCENTA = rec.producent_id_producenta)
            LOOP
                insert into magazynowanie values (mar.aktualna_liczba_sztuk, koszt*(mar.aktualna_liczba_sztuk/rec.liczba_sztuk), nr_rundy, mar.id_marki);
            END LOOP;
         END LOOP;
    end if;
END POTRAC_KOSZTY_MAGAZYNOWANIA;
/


create or replace PROCEDURE RESTART_PARAMETROW_PRODUCENTOW (wybrana_opcja NUMBER) AS 
    pocz_fundusze number (10, 0);
BEGIN
    select poczatkowe_fundusze into pocz_fundusze from ustawienia_poczatkowe where numer_opcji = wybrana_opcja;
    update PRODUCENT set FUNDUSZE = pocz_fundusze, CZY_SPASOWAL = 'n';
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


create or replace PROCEDURE ROZPOCZNIJ_GRE (wybrana_opcja NUMBER) AS
BEGIN
    --sprawdzenie czy wybrana opcja istnieje
    declare
        aktywna_opcja number;
    BEGIN
        select count(numer_opcji) into aktywna_opcja from USTAWIENIA_POCZATKOWE where NUMER_OPCJI = wybrana_opcja;
        if aktywna_opcja <> 1 then
            raise_application_error(-20805, 'Wybrana opcja ustawien poczatkowych nie istnieje');
        end if;
    END;
    --czyszczenie zawartosci po poprzedniej grze
    WYCZYSC_TABELE;
    --restartowanie sekwencji
    ZRESTARTUJ_SEKWENCJE;
    --stworzenie konsumentow
    GENERUJ_KONSUMENTOW(wybrana_opcja);
    --uzupelnienie tabeli jakosc marki
    GENERUJ_JAKOSCI_MARKI;
    --stworzenie uzytkownikow i dodanie ich do tabeli producentow
    RESTART_PARAMETROW_PRODUCENTOW (wybrana_opcja);
    --rozpocznij pierwsza runde
    insert into licznik_rund values (null);
END ROZPOCZNIJ_GRE;
/


create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
--procedura uruchamiana rozpoczyna nowa runde poprzez zwiekszenie licznika rund
BEGIN
  --realizacja dzialan marketingowych i badanie rynku - wyniki od razu

  --zwiekszenie licznika rund - ! czy z sekwencja ma to sens
  insert into licznik_rund values (null);

  --realizacja zakupow klientow
  ZREALIZUJ_ZAKUPY;

  --koszty magazynowania na kolejna runde
  POTRAC_KOSZTY_MAGAZYNOWANIA (1);
END ROZPOCZNIJ_RUNDE;
/


create or replace PROCEDURE WYCZYSC_TABELE AS 
BEGIN
    --czyszczenie
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dostep_producenta_his_zakup';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ocena_hipotetycznej_marki';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE historia_cen';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE magazynowanie';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE produkcja';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE przywiazanie_do_marki';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE marketing';
            
    DELETE FROM hipotetyczna_marka CASCADE;
    DELETE FROM zakup_konsumenta CASCADE;
    DELETE FROM badanie_rynku CASCADE;
    DELETE FROM marka CASCADE;
    DELETE FROM rodzaje_marek CASCADE;
    DELETE FROM licznik_rund CASCADE;
    DELETE FROM konsument CASCADE;
    commit;
END WYCZYSC_TABELE;
/


create or replace PROCEDURE ZREALIZUJ_ZAKUPY AS
    nr_rundy NUMBER;
    wybrana_marka NUMBER;
    wspolczynnik_modyfikacji NUMBER;
    max_ocena NUMBER;
    ocena_klienta NUMBER;
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
    select max(numer_rundy) into nr_rundy from licznik_rund;

    FOR REC IN ((SELECT * from konsument))
    LOOP
        FOR MAR IN (SELECT m.id_marki, m.cena_za_sztuke as cena, m.RODZAJE_MAREK_JAKOSC_MARKI as jakosc,  m.AKTUALNA_LICZBA_SZTUK, p.WSPOLCZYNNIK_PRZYWIAZANIA as przywiazanie from marka m, PRZYWIAZANIE_DO_MARKI p
                        where m.ID_MARKI = p.MARKA_ID_MARKI and p.KONSUMENT_ID_KONSUMENTA = REC.id_konsumenta)
        LOOP
            --wyznaczenie wartosci funkcji dla kazdego z parametrow
            --cena
            f_cena_1 := rec.cena_zadowolenie*(mar.cena - rec.cena_poziom_aspiracji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji)+1;
            f_cena_2 := (mar.cena - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena_3 := rec.cena_niezadowolenie*(mar.cena - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena := least (f_cena_1, f_cena_2, f_cena_3);
            --jakosc
            f_jakosc_1 := rec.jakosc_zadowolenie*(mar.jakosc - rec.jakosc_poziom_aspiracji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji)+1;
            f_jakosc_2 := (mar.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc_3 := rec.jakosc_niezadowolenie*(mar.jakosc - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc := least (f_jakosc_1, f_jakosc_2, f_jakosc_3);
            --przywiazanie
            f_przywiazanie_1 := rec.przywiazanie_zadowolenie*(mar.przywiazanie - rec.przywiazanie_poziom_aspiracji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji)+1;
            f_przywiazanie_2 := (mar.przywiazanie - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
            f_przywiazanie_3 := rec.przywiazanie_niezadowolenie*(mar.przywiazanie - rec.przywiazanie_poziom_rezerwacji)/(rec.przywiazanie_poziom_aspiracji - rec.przywiazanie_poziom_rezerwacji);
            f_przywiazanie := least (f_przywiazanie_1, f_przywiazanie_2, f_przywiazanie_3);

            --ostateczna ocena
            ocena_klienta := round (least (f_cena, f_jakosc, f_przywiazanie) + 0.01*(f_cena + f_jakosc + f_przywiazanie), 10);
            update marka set tymczasowa_ocena_klienta = ocena_klienta where id_marki = mar.id_marki;
        END LOOP;

        select max(tymczasowa_ocena_klienta) into max_ocena from marka where AKTUALNA_LICZBA_SZTUK > 0;         
        --jesli nie ma produktow zadnej marki to konsument nabywa produkt socjalny, czyli w historii zakupow wpisywany jest null
        if max_ocena is not null then
            select id_marki into wybrana_marka from marka where tymczasowa_ocena_klienta = max_ocena;
            update marka set aktualna_liczba_sztuk = aktualna_liczba_sztuk - 1 where id_marki = wybrana_marka;
            insert into zakup_konsumenta values (nr_rundy, rec.id_konsumenta, wybrana_marka);
        else
            insert into zakup_konsumenta values (nr_rundy, rec.id_konsumenta, null);
        end if;
        commit;

        --wszystkie marki ktore byly ocenione wyzej niz produkt tej zakupionej nie zaspokoily oczekiwan klienta, wiec traca w jego oczach
        select niezaspokojony_popyt_wplyw into wspolczynnik_modyfikacji from USTAWIENIA_POCZATKOWE where numer_opcji = 3;
        FOR OC IN (select m.id_marki, p.konsument_id_konsumenta from marka m, PRZYWIAZANIE_DO_MARKI p
                    where m.ID_MARKI = p.MARKA_ID_MARKI and p.KONSUMENT_ID_KONSUMENTA = REC.id_konsumenta and m.tymczasowa_ocena_klienta > max_ocena)
        LOOP
            update PRZYWIAZANIE_DO_MARKI set WSPOLCZYNNIK_PRZYWIAZANIA = WSPOLCZYNNIK_PRZYWIAZANIA*wspolczynnik_modyfikacji
            where KONSUMENT_ID_KONSUMENTA = OC.KONSUMENT_ID_KONSUMENTA and marka_id_marki = oc.id_marki;
        END LOOP;
    END LOOP;
END ZREALIZUJ_ZAKUPY;
/


create or replace PROCEDURE ZRESTARTUJ_SEKWENCJE AS 
BEGIN
    RESTART_SEKWENCJI ('LICZNIK_RUND_SEQ');
    RESTART_SEKWENCJI ('ID_MARKI_SEQ');
    RESTART_SEKWENCJI ('ID_HIPOTETYCZNEJ_MARKI_SEQ');
    RESTART_SEKWENCJI ('ID_BADANIA_RYNKU_SEQ');
END ZRESTARTUJ_SEKWENCJE;
/