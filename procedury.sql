create or replace PROCEDURE GENERUJ_JAKOSCI_MARKI AS 
BEGIN
  --temp version
    FOR i IN 1 ..99 LOOP
        insert into rodzaje_marek values (i, 1000*i, 100*i);
    END LOOP;
END GENERUJ_JAKOSCI_MARKI;



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



create or replace PROCEDURE GENERUJ_KOSZTY_MAGAZYNOWANIA AS
BEGIN
    FOR i IN 1 ..9 LOOP
        insert into KOSZT_MAGAZYNOWANIA values (i*100, i*10000);
    END LOOP;
END GENERUJ_KOSZTY_MAGAZYNOWANIA;



create or replace PROCEDURE POTRAC_KOSZTY_MAGAZYNOWANIA AS 
    tmp_koszt NUMBER (15, 0);
    nr_rundy NUMBER (5, 0);
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    FOR REC IN (SELECT m.id_marki, m.aktualna_liczba_sztuk, p.id_producenta, p.fundusze from marka m, producent p where m.producent_id_producenta = p.id_producenta)
    LOOP
        --okreslenie kosztu magazyniwania - tmp liniowo od liczby sztuk
        tmp_koszt := rec.aktualna_liczba_sztuk * 100;
        --obciazenie kosztami konta producenta
        UPDATE producent SET fundusze = fundusze - tmp_koszt WHERE ID_PRODUCENTA = REC.id_producenta;
        --dodanie wpisu dotabeli historii magazynowania
        insert into magazynowanie values (rec.aktualna_liczba_sztuk, tmp_koszt, nr_rundy, rec.id_marki);
    END LOOP;
END POTRAC_KOSZTY_MAGAZYNOWANIA;




create or replace PROCEDURE ROZPOCZNIJ_GRE (wybrana_opcja NUMBER) authid current_user AS
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
    --uzupelnienie tabeli koszty magazynowania
    GENERUJ_KOSZTY_MAGAZYNOWANIA;
    --stworzenie uzytkownikow i dodanie ich do tabeli producentow
    STWORZ_GRACZY(4, wybrana_opcja);
END ROZPOCZNIJ_GRE;




create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
--procedura uruchamiana rozpoczyna nowa runde poprzez zwiekszenie licznika rund
BEGIN
  --realizacja dzialan marketingowych  //badanie rynku - wyniki od razu
  --zwiekszenie licznika rund - ! czy z sekwencja ma to sens
  insert into licznik_rund values (null);
  --realizacja zakupow klientow
  --koszty magazynowania na kolejna runde
  POTRAC_KOSZTY_MAGAZYNOWANIA;
END ROZPOCZNIJ_RUNDE;




create or replace PROCEDURE STWORZ_GRACZY (liczba_graczy number, wybrana_opcja NUMBER) authid current_user AS
BEGIN
    if liczba_graczy > 99 then
        raise_application_error(-20806, 'Podana liczba graczy jest zbyt duza. Podaj liczbe ponizej 100');
    end if;
    
    declare
    command varchar(50);
    nazwa_gracza varchar(30);
    liczba_usun number (2,0);
    fundusze number (10, 0);
    begin
        --usun wszystkich graczy z poprzedniej rozgrywki
        select count(id_producenta) into liczba_usun from producent;
        FOR i IN 1..liczba_usun
        LOOP
            select max(nazwa) into nazwa_gracza from producent;
            command := 'DROP USER ' || nazwa_gracza ;
            EXECUTE IMMEDIATE command;
            delete from producent where nazwa = nazwa_gracza;
            commit;
        END LOOP;
        
        --stworz nowych graczy
        FOR j IN 1..liczba_graczy
        LOOP
            --stworz gracza
            nazwa_gracza := 'GRACZ_' || j;
            command := 'CREATE USER ' || nazwa_gracza || ' IDENTIFIED BY elka';
            EXECUTE IMMEDIATE command;
            --uprawnienia!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            --dodaj wpis w tabeli producentow
            select poczatkowe_fundusze into fundusze from ustawienia_poczatkowe where numer_opcji = wybrana_opcja;
            insert into producent values (j, nazwa_gracza, fundusze, 'n');
        END LOOP;
    end;
END STWORZ_GRACZY;




create or replace PROCEDURE WYCZYSC_TABELE AS 
BEGIN
  --czyszczenie
    BEGIN
        EXECUTE IMMEDIATE 'delete from koszt_magazynowania';
        EXECUTE IMMEDIATE 'delete from zakup_konsumenta';
        EXECUTE IMMEDIATE 'delete from marketing';
        EXECUTE IMMEDIATE 'delete from badania_rynku';
        EXECUTE IMMEDIATE 'delete from historia_cen';
        EXECUTE IMMEDIATE 'delete from magazynowanie';
        EXECUTE IMMEDIATE 'delete from produkcja';
        EXECUTE IMMEDIATE 'delete from sprzedaz';
        EXECUTE IMMEDIATE 'delete from przywiazanie_do_marki';
        EXECUTE IMMEDIATE 'delete from marka';
        EXECUTE IMMEDIATE 'delete from rodzaje_marek';
        EXECUTE IMMEDIATE 'delete from rodzaj_marketingu';
        EXECUTE IMMEDIATE 'delete from licznik_rund';
        EXECUTE IMMEDIATE 'delete from konsument';
        commit;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.put_line ('Czyszczenie tabel nie powiodlo sie');
    END;
END WYCZYSC_TABELE;





create or replace PROCEDURE ZREALIZUJ_ZAKUPY AS
    nr_rundy NUMBER;
    wybrana_marka NUMBER;
    max_ocena NUMBER;
    dostepne_sztuki NUMBER;
    ocena_klienta NUMBER;
    cena_marki NUMBER;
    jakosc_marki NUMBER;
    przywiazanie_klienta NUMBER := 0;
    f_cena NUMBER;
    f_cena_1 NUMBER;
    f_cena_2 NUMBER;
    f_cena_3 NUMBER;
    f_jakosc NUMBER;
    f_jakosc_1 NUMBER;
    f_jakosc_2 NUMBER;
    f_jakosc_3 NUMBER;
    f_przywiazanie NUMBER := 0;
    f_przywiazanie_1 NUMBER;
    f_przywiazanie_2 NUMBER;
    f_przywiazanie_3 NUMBER;
BEGIN
    select max(numer_rundy) into nr_rundy from licznik_rund;
    FOR REC IN (SELECT * from konsument)
    LOOP
        FOR MAR IN (SELECT id_marki, cena_za_sztuke from marka)
        LOOP
            --sprawdzenie czy jest co kupic
            select aktualna_liczba_sztuk into dostepne_sztuki from marka where id_marki = mar.id_marki;
            if dostepne_sztuki <= 0 then
                update marka set tymczasowa_ocena_klienta = 0 where id_marki = mar.id_marki;
                continue;
            end if;
            --pobranie parametrow marki
            select cena_za_sztuke into cena_marki from marka where id_marki = mar.id_marki;
            select rodzaje_marek_jakosc_marki into jakosc_marki from marka where id_marki = mar.id_marki;
            --select cena_za_sztuke into cena_marki from marka where id_marki = 1;
            
            --wyznaczenie wartosci funkcji dla kazdego z parametrow
            --cena
            f_cena_1 := rec.cena_zadowolenie*(cena_marki - rec.cena_poziom_aspiracji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji)+1;
            f_cena_2 := (cena_marki - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena_3 := rec.cena_niezadowolenie*(cena_marki - rec.cena_poziom_rezerwacji)/(rec.cena_poziom_aspiracji - rec.cena_poziom_rezerwacji);
            f_cena := least (f_cena_1, f_cena_2, f_cena_3);
            --jakosc
            f_jakosc_1 := rec.jakosc_zadowolenie*(jakosc_marki - rec.jakosc_poziom_aspiracji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji)+1;
            f_jakosc_2 := (jakosc_marki - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc_3 := rec.jakosc_niezadowolenie*(jakosc_marki - rec.jakosc_poziom_rezerwacji)/(rec.jakosc_poziom_aspiracji - rec.jakosc_poziom_rezerwacji);
            f_jakosc := least (f_jakosc_1, f_jakosc_2, f_jakosc_3);
            --przywiazanie
            
            -- na pozniej
            ocena_klienta := round (least (f_cena, f_jakosc) + 0.01*(f_cena + f_jakosc + f_przywiazanie), 10);
            update marka set tymczasowa_ocena_klienta = ocena_klienta where id_marki = mar.id_marki;
        END LOOP;
        select max(tymczasowa_ocena_klienta) into max_ocena from marka;
        --jesli wszystkie marki maja ocene 0, to oznacza, ze nie ma dostepnych produktow od producentow, a wiec konsument nabywa produkt socjalny
        if max_ocena = 0 then
            continue;
        end if;
        select id_marki into wybrana_marka from marka where tymczasowa_ocena_klienta = max_ocena;
        update marka set aktualna_liczba_sztuk = aktualna_liczba_sztuk - 1 where id_marki = wybrana_marka;
        insert into zakup_konsumenta values (nr_rundy, rec.id_konsumenta, wybrana_marka);
        commit;
    END LOOP;
END ZREALIZUJ_ZAKUPY;




create or replace PROCEDURE ZRESTARTUJ_SEKWENCJE AS 
BEGIN
    --restartowanie sekwencji
    BEGIN
        --autoinkrementacja licznika rund
        EXECUTE IMMEDIATE ' SEQUENCE LICZNIK_RUND_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE LICZNIK_RUND_SEQ INCREMENT BY 1 START WITH 1';
        --autoinkrementacja id marki
        EXECUTE IMMEDIATE 'DROP SEQUENCE ID_MARKI_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ID_MARKI_SEQ INCREMENT BY 1 START WITH 1';
        --autoinkrementacja id rodzaju marketingu
        EXECUTE IMMEDIATE 'DROP SEQUENCE ID_RODZ_MARKETINGU_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ID_RODZ_MARKETINGU_SEQ INCREMENT BY 1 START WITH 1';
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.put_line ('Restartowanie sekwencji nie powiodlo sie.');
    END;
END ZRESTARTUJ_SEKWENCJE;