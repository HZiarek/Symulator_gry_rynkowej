create or replace PROCEDURE STWORZ_GRACZA (liczba_graczy number, wybrana_opcja NUMBER) authid current_user AS
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
END STWORZ_GRACZA;