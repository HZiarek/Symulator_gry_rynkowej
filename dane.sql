--domyslne ustawienia poczatkowe
insert into ustawienia_poczatkowe values (1, 'a', 't', null, null, 90000000, 100000, 1.1, 1, 0.99, 0.98,
                                            1000, 10000, 1000, 2000, 500, 2, 1, 0.4, 0.1,
                                            'm', 100000, 100, 5, 't', 'Ustawienia testowe');
commit;

--domyslne rodzaje marketingu
insert into rodzaje_marketingu values (1, 30000, 2500, 1.3, 1.03);
insert into rodzaje_marketingu values (2, 20000, 2000, 1.2, 1.02);
insert into rodzaje_marketingu values (3, 10000, 1500, 1.1, 1.01);
commit;
