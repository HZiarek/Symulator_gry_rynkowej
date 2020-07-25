--domyslne ustawienia poczatkowe
insert into ustawienia_poczatkowe values (1, 'a', --czy jest to aktywny zestaw
                                            't', --warunek zakonczenia rundy, 't' - czas
                                            null, --czas rundy
                                            null, --liczba rund
                                            90000000, --poczatkowe fundusze
                                            100000, --koszt wprowadzenia marki na rynek
                                            100000, 50000, --ceny marketingu, bazowy i per stopien intensywnosci
                                            0.5, --wplyw_marketingu_producenta
                                            1000, --liczba konsumentow
                                            10000, 1000, 2000, 500, --wymagania cena
                                            2, 1, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji jakosci
                                            0.1, 1.0, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji historii zakupow
                                            20, 80,--maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji marketingu
                                            'm', 100000, 100, 5,--magazynowanie
                                            't',--czy maja zostac wygenerowane domyslne jakosci marek, 't' - tak, 'n' - nie
                                            'Ustawienia testowe'--opis
                                            );
commit;
