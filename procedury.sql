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