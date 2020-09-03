--domyslne ustawienia poczatkowe
insert into ustawienia_poczatkowe values (null, 'a', --czy jest to aktywny zestaw
                                            'p', --warunek zakonczenia rundy, 't' - czas
                                            null, --czas rundy
                                            null, --liczba rund
                                            90000000, --poczatkowe fundusze
                                            100000, --koszt wprowadzenia marki na rynek
                                            50000, --marketing - koszt bazowy
                                            5000, --marketingu - koszt per stopien intensywnosci
                                            0.5, --wplyw_marketingu_producenta
                                            1000, --liczba konsumentow
                                            3000, --maksymalna przewidywana cena produktu; wlasciwa cena bedzie podzielona przez 100
                                            1500, --minimalna przewidywana cena produktu; wlasciwa cena bedzie podzielona przez 100
                                            500, 100, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji ceny
                                            2, 1, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji jakosci
                                            1.0, 0.1, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji historii zakupow
                                            80, 20, --maksymalna i minimalna roznica miedzy poziomem apiracji a poziomem rezerwacji marketingu
                                            'm', --sposob naliczania kosztow magazynowania
                                            100, --wielkosc powierzchni magazynowej - ma znaczenie tylko jesli koszt magazynowania jest potracany od wynajetego magazynu, nie od sztuki produktu
                                            10000, --koszt zmagazynowania jednej sztuki produktu lub wynajecia jednego magazynu
                                            5, --upust za kazdy kolejny wynajety magazyn podany w %; upust sie sumuje, ale nie moze byc wyzszy niz 50%
                                            't',--czy maja zostac wygenerowane domyslne jakosci marek, 't' - tak, 'n' - nie
                                            'Ustawienia testowe'--opis
                                            );
commit;
