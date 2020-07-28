--domyslne ustawienia poczatkowe
insert into ustawienia_poczatkowe values (null, 'a', --czy jest to aktywny zestaw
                                            't', --warunek zakonczenia rundy, 't' - czas
                                            null, --czas rundy
                                            null, --liczba rund
                                            90000000, --poczatkowe fundusze
                                            100000, --koszt wprowadzenia marki na rynek
                                            100000, --marketing - koszt bazowy
                                            50000, --marketingu - koszt per stopien intensywnosci
                                            0.5, --wplyw_marketingu_producenta
                                            1000, --liczba konsumentow
                                            10000, --maksymalna przewidywana cena produktu; wlasciwa cena bedzie podzielona przez 100
                                            1000, --minimalna przewidywana cena produktu; wlasciwa cena bedzie podzielona przez 100
                                            2000, 500, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji ceny
                                            2, 1, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji jakosci
                                            0.1, 1.0, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji historii zakupow
                                            20, 80,--maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji marketingu
                                            'm', --sposob naliczania kosztow magazynowania
                                            100000, --wielkosc powierzchni magazynowej - ma znaczenie tylko jesli koszt magazynowania jest potracany od wynajetego magazynu, nie od sztuki produktu
                                            100, --koszt zmagazynowania jednej sztuki produktu lub wynajecia jednego magazynu
                                            5, --upust za kazdy kolejny wynajety magazyn podany w %; upust sie sumuje, ale nie moze byc wyzszy niz 50%
                                            't',--czy maja zostac wygenerowane domyslne jakosci marek, 't' - tak, 'n' - nie
                                            'Ustawienia testowe'--opis
                                            );
commit;
