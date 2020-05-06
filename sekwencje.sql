--sekwencje
--autoinkrementacja id konsumenta
DROP SEQUENCE ID_KONSUMENTA_SEQ;
CREATE SEQUENCE ID_KONSUMENTA_SEQ INCREMENT BY 1 START WITH 1;

--autoinkrementacja licznika rund
DROP SEQUENCE LICZNIK_RUND_SEQ;
CREATE SEQUENCE LICZNIK_RUND_SEQ INCREMENT BY 1 START WITH 1;

--autoinkrementacja id marki
DROP SEQUENCE ID_MARKI_SEQ;
CREATE SEQUENCE ID_MARKI_SEQ INCREMENT BY 1 START WITH 1;

--autoinkrementacja id rodzaju marketingu
DROP SEQUENCE ID_RODZ_MARKETINGU_SEQ;
CREATE SEQUENCE ID_RODZ_MARKETINGU_SEQ INCREMENT BY 1 START WITH 1;

--autoinkrementacja id ustawien poczatkowych
DROP SEQUENCE NR_OPCJI_USTAWIEN_POCZ_SEQ;
CREATE SEQUENCE NR_OPCJI_USTAWIEN_POCZ_SEQ INCREMENT BY 1 START WITH 2;

--autoinkrementacja id ustawien poczatkowych
DROP SEQUENCE ID_RODZAJU_MARKET_SEQ;
CREATE SEQUENCE ID_RODZAJU_MARKET_SEQ INCREMENT BY 1 START WITH 4;

--domyslne ustawienia poczatkowe
insert into ustawienia_poczatkowe values (1, 1000, 4, 't', null, null, 100000, 1.1, 1, 0.99, 0.98);
commit;

--domyslne rodzaje marketingu
insert into rodzaj_marketingu values (1, 30000, 2500, 1.3, 1.03);
insert into rodzaj_marketingu values (2, 20000, 2000, 1.2, 1.02);
insert into rodzaj_marketingu values (3, 10000, 1500, 1.1, 1.01);
commit;
