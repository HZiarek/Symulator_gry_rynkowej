create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
--procedura uruchamiana rozpoczyna nowa runde poprzez zwiekszenie licznika rund
BEGIN
  --realizacja dzialan marketingowych
  --zwiekszenie licznika rund - ! czy z sekwencja ma to sens
  insert into licznik_rund values (null);
  --realizacja zakupow klientow
  --koszty magazynowania na kolejna runde
END ROZPOCZNIJ_RUNDE;


create or replace PROCEDURE GENERUJ_KONSUMENTOW
IS
    liczba_kons NUMERIC(10);
BEGIN
    select liczba_konsumentow into liczba_kons from ustawienia_poczatkowe where numer_opcji = 1;
    FOR i IN 1 ..liczba_kons LOOP
    insert into konsumenci values (null, DBMS_RANDOM.value(100, 10000), DBMS_RANDOM.value(100, 10000), DBMS_RANDOM.value(1, 10), 
                       DBMS_RANDOM.value(1, 10), DBMS_RANDOM.value(1, 10), DBMS_RANDOM.value(1, 10), DBMS_RANDOM.value(0, 0.99));
  END LOOP;
END GENERUJ_KONSUMENTOW;

create or replace PROCEDURE ROZPOCZNIJ_GRE (wybrana_opcja NUMBER) AS
BEGIN
    --sprawdzenie czy jest w oparciu o co startowac nowa runde
        --na razie opcja 1 - dodac pole aktywnej opcji w ustaiwniach pocz
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
    --stworzenie uzytkownikow i dodanie ich do tabeli producentow
    STWORZ_GRACZY(4, wybrana_opcja);
    --stworzenie konsumentow
    GENERUJ_KONSUMENTOW(wybrana_opcja);
    --uzupelnienie tabel zawierajacych jakosc marki i koszty magazynowania
END ROZPOCZNIJ_GRE;

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