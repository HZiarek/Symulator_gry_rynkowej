create or replace FUNCTION POLICZ_MPO_WYBRANE_WYMIARY (
                    CENA NUMBER, CZY_UWZGL_CENE CHAR,
                    JAKOSC NUMBER, CZY_UWZGL_JAKOSC CHAR,
                    HISTORIA_ZAKUPOW NUMBER, CZY_UWZGL_HIS_ZAKUPOW CHAR,
                    MARKETING_RUNDA NUMBER, CZY_UWZGL_MARKETING_RUNDA CHAR,
                    MARKETING_HISTORIA NUMBER, CZY_UWZGL_MARKETING_HISTORIA CHAR)
                    /*
funkcja pozwalajaca na obliczenie ostatecznej oceny produktu za pomoca przedzialowej metody odniesienia, ale tylko
z uwzglednieniem wybranych wymiarow, a dokladniej wartosci wybranych indywidualnych funkcji osiagniecia;
jest niezbedna w badaniu rynku, gdzie to gracz wybiera w jakich wymiarach ma byc badana dana marka
*/
RETURN NUMBER
AS
    epsilon NUMBER := 0.01;
    wartosc_f_osiagniecia NUMBER;
    suma NUMBER := 0;
    minimum NUMBER := 999999999999999.99;
BEGIN
    if CZY_UWZGL_CENE = 't' then
        suma := suma + cena;
        minimum := least(cena, minimum); 
    end if;

    if CZY_UWZGL_JAKOSC = 't' then
        suma := suma + jakosc;
        minimum := least(jakosc, minimum); 
    end if;

    if CZY_UWZGL_HIS_ZAKUPOW = 't' then
        suma := suma + HISTORIA_ZAKUPOW;
        minimum := least(HISTORIA_ZAKUPOW, minimum); 
    end if;

    if CZY_UWZGL_MARKETING_RUNDA = 't' then
        suma := suma + MARKETING_RUNDA;
        minimum := least(MARKETING_RUNDA, minimum); 
    end if;

    if CZY_UWZGL_MARKETING_HISTORIA = 't' then
        suma := suma + MARKETING_HISTORIA;
        minimum := least(MARKETING_HISTORIA, minimum); 
    end if;

    wartosc_f_osiagniecia := minimum + epsilon * suma;

    return wartosc_f_osiagniecia;
END POLICZ_MPO_WYBRANE_WYMIARY;
/


create or replace FUNCTION POLICZ_WYMIAR_MPO (POZIOM_ASPIRACJI NUMBER, POZIOM_REZERWACJI NUMBER, WARTOSC_PARAMETRU NUMBER)
/*
funkcja pozwala na policzenie wartosci indywidualnej funkcji osiagniecia na podstawie podanych poziomow aspiracji i rezerwacji
oraz wartosci parametru zgodnie z przedzialowa metoda punktu odniesienia
wykorzystywana w zapytaniach w procedurach realizujacych zakupy konsumenta oraz badanie rynku
*/
RETURN NUMBER
AS
    zadowolenie NUMBER := 0.001;
    niezadowolenie NUMBER := 1000;
    wartosc_f_osiagniecia NUMBER;
    przedzial_1 NUMBER;
    przedzial_2 NUMBER;
    przedzial_3 NUMBER;
BEGIN
    przedzial_1 := zadowolenie*(wartosc_parametru - poziom_aspiracji)/(poziom_aspiracji - poziom_rezerwacji)+1;
    przedzial_2 := (wartosc_parametru - poziom_rezerwacji)/(poziom_aspiracji - poziom_rezerwacji);
    przedzial_3 := niezadowolenie*(wartosc_parametru - poziom_rezerwacji)/(poziom_aspiracji - poziom_rezerwacji);
    wartosc_f_osiagniecia := least (przedzial_1, przedzial_2, przedzial_3);
    return wartosc_f_osiagniecia;
END POLICZ_WYMIAR_MPO;
/

create or replace PROCEDURE SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN AS
/*
procedura sprawdza czy istnieje aktywny zestaw ustawien poczatkowych,
czyli taki z ktorego mozna pobrac niezbedne w danym momencie ustawienia;
w danym momencie moze byc ustawiony jako aktywny jeden zestaw lub moze nie byc ustawiony zaden,
co pozwala na ewentualna podmiane zestawu aktywnego;
jezeli w momencie wywolania procedury nie ma ustawionego zadnego zestawu aktywnego,
wowczas procedura ustawia jako aktywny zestaw o najmniejszym id;
prowadzacy jest informowany o braku aktywnego zestawu ustawien poczatkowych,
ale jedynie przed rozpoczeciem gry, w jej trakcie blad jest pomijany, aby nie
wstrzymywac rozgrywki
jezeli prowadzacy zdecyduje sie z jakiegos powowdu na zmiane aktywnego zestawu
ustawien poczatkowych w trakcie trwania rozgrywki, powinien to zrobic w ramach jednego
commita
*/
liczba_aktywnych_opcji number;
nr_zestawu number;
BEGIN
    select count(numer_zestawu) into liczba_aktywnych_opcji from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';
    if liczba_aktywnych_opcji <> 1 then
        select numer_zestawu into nr_zestawu
            from (select numer_zestawu from ustawienia_poczatkowe where rownum = 1 order by numer_zestawu);
        update USTAWIENIA_POCZATKOWE set czy_aktywna = 'a' where numer_zestawu = nr_zestawu;
    end if;
END SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
/

create or replace PROCEDURE GENERUJ_KONSUMENTOW
IS
    max_his_zakupow NUMBER := 1.0;
    min_his_zakupow NUMBER := 0.0;
    max_marketing NUMBER := 100;
    min_marketing NUMBER := 0;
    
    liczba_kons number(8, 0);
    cena_aspiracja number;
    jakosc_rezerwacja number (2, 0);
    his_zakupow_rezerwacja number;
    marketing_rezerwacja number;

    max_cena NUMBER;
    min_cena NUMBER;
    max_jakosc NUMBER;
    min_jakosc NUMBER;
    max_roznica_cena NUMBER;
    min_roznica_cena NUMBER;
    max_roznica_jakosc NUMBER;
    min_roznica_jakosc NUMBER;
    max_roznica_his_zakupow NUMBER;
    min_roznica_his_zakupow NUMBER;
    max_roznica_marketing NUMBER;
    min_roznica_marketing NUMBER;
    krok_cena NUMBER;
    krok_jakosc NUMBER;

BEGIN
    select
        liczba_konsumentow,
        wym_max_cena,
        wym_min_cena,
        wym_kons_max_roznica_cena,
        wym_kons_min_roznica_cena,
        wym_kons_max_roznica_jakosc,
        wym_kons_min_roznica_jakosc,
        wym_kons_max_roznica_his_zak,
        wym_kons_min_roznica_his_zak,
        wym_kons_max_roznica_marketing,
        wym_kons_min_roznica_marketing
    into
        liczba_kons,
        max_cena,
        min_cena,
        max_roznica_cena,
        min_roznica_cena,
        max_roznica_jakosc,
        min_roznica_jakosc,
        max_roznica_his_zakupow,
        min_roznica_his_zakupow,
        max_roznica_marketing,
        min_roznica_marketing
    from ustawienia_poczatkowe where czy_aktywna = 'a';

    select
        max(jakosc_marki),
        min(jakosc_marki)
    into
        max_jakosc,
        min_jakosc
    from jakosci_marek;

    --krok obliczany ze wzoru na sume ciagu arytmetycznego
    krok_cena := 2*(max_cena - min_cena)/(liczba_kons*(liczba_kons - 1));
    krok_jakosc := 2*(max_jakosc - min_jakosc)/(liczba_kons*(liczba_kons - 1));

    --czemu ma sluzyc liczenie od konca - dopisac
    FOR i IN reverse 1..liczba_kons LOOP
        cena_aspiracja := DBMS_RANDOM.value(min_cena + (i-1)*krok_cena, min_cena + (i-1)*krok_cena + max_roznica_cena - min_roznica_cena);
        jakosc_rezerwacja := DBMS_RANDOM.value(min_jakosc + (i-1)*krok_jakosc, min_jakosc + (i-1)*krok_jakosc + max_roznica_jakosc - min_roznica_jakosc);
        his_zakupow_rezerwacja := DBMS_RANDOM.value(min_his_zakupow, max_his_zakupow - min_roznica_his_zakupow);
        marketing_rezerwacja := DBMS_RANDOM.value(min_marketing, max_marketing - min_marketing);
        insert into konsumenci values (i,

                            cena_aspiracja,                                             --cena
                            DBMS_RANDOM.value(cena_aspiracja + min_roznica_cena, min_cena + (i-1)*krok_cena + max_roznica_cena),

                            DBMS_RANDOM.value(jakosc_rezerwacja + min_roznica_jakosc, min_jakosc + (i-1)*krok_jakosc + max_roznica_jakosc),--jakosc
                            jakosc_rezerwacja,

                            DBMS_RANDOM.value(his_zakupow_rezerwacja + min_roznica_his_zakupow, 
                                                least(max_his_zakupow, his_zakupow_rezerwacja + max_roznica_his_zakupow)),  --historia zakupow
                            his_zakupow_rezerwacja,

                            DBMS_RANDOM.value(marketing_rezerwacja + min_roznica_marketing,
                                                least(max_marketing, marketing_rezerwacja + max_roznica_marketing)),  --marketing
                            marketing_rezerwacja);
    END LOOP;
END GENERUJ_KONSUMENTOW;
/

create or replace PROCEDURE GENERUJ_GRUPY_KONSUMENTOW
/*
procedura tworzy podstawowe grupy konsumentow, ktore sa nastepnie wykorzystywane w badaniu rynku;
tworzenie grup ma glownie charakter testowy, ale stanowi tez swego rodzaju zabezpieczenie, gdyby prowadzacy
gre nie chcial lub nie mogl stworzyc innych grup; dzieki tym wygenerowanym grupom wciaz mozliwe jest przeprowadzenie
rynku przez graczy
---------------------------------------------------------------------------------------------------------
procedura zawsze genruje 5, rowno licznych grup; jesli liczba konsumentow nie jest podzielna przez 5, wowczas piata grupa
jest nieco mniejsza;
*/
IS
    liczebnosc_grupy NUMBER;
    liczebnosc_konsumentow NUMBER
    /*
    koszt uzyskania ocen od grupy konsumentow oraz koszt uzyskania historii zakupow z jednej rundy
    sa zalezne od liczbnosci grupy, co wynika z faktu, ze liczba konsumentow zalezy od ustawien poczatkowych;
    poniezej znalduja sie konkretne ceny za jednego konsumenta, przy czym ceny sa rozne w zaleznosci od grupy;
    parametry te nie znajduja sie w tabeli z ustawieniami poczatkowymi, poniewaz zalozenie jest takie,
    ze - jako testowe - grupy te zostana usuniete lub przynajmniej ceny beda zmodyfikowane przez prowadzacego gre
    */
    gr_1_ocena NUMBER := 1000; --cena w setnych czesciach waluty groszach, centach itp.
    gr_2_ocena NUMBER := 1000;
    gr_3_ocena NUMBER := 1100;
    gr_4_ocena NUMBER := 1200;
    gr_5_ocena NUMBER := 1300;
    gr_1_his_zakupow NUMBER := 500;
    gr_2_his_zakupow NUMBER := 550;
    gr_3_his_zakupow NUMBER := 650;
    gr_4_his_zakupow NUMBER := 850;
    gr_5_his_zakupow NUMBER := 1000;
BEGIN
    select liczba_konsumentow into liczebnosc_konsumentow from ustawienia_poczatkowe where czy_aktywna = 'a';
    liczebnosc_grupy := ceil(liczebnosc_konsumentow / 5);

    insert into grupy_konsumentow values (null, liczebnosc_grupy*1000, liczebnosc_grupy*500, null);
    for i in 1..liczebnosc_grupy loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;

    insert into grupy_konsumentow values (null, liczebnosc_grupy*1000, liczebnosc_grupy*550, null);
    for i in liczebnosc_grupy+1..liczebnosc_grupy*2 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;

    insert into grupy_konsumentow values (null, liczebnosc_grupy*1100, liczebnosc_grupy*650, null);
    for i in liczebnosc_grupy*2+1..liczebnosc_grupy*3 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;

    insert into grupy_konsumentow values (null, liczebnosc_grupy*1200, liczebnosc_grupy*850, null);
    for i in liczebnosc_grupy*3+1..liczebnosc_grupy*4 loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;

    insert into grupy_konsumentow values (null, liczebnosc_grupy*1300, liczebnosc_grupy*1000, null);
    for i in liczebnosc_grupy*4+1..liczebnosc_konsumentow loop
        insert into PRZYNALEZNOSCI_DO_GRUP values (i, id_grupy_konsumentow_seq.CURRVAL);
    end loop;
    commit;
END GENERUJ_GRUPY_KONSUMENTOW;
/

create or replace PROCEDURE LICZ_PRZYCHOD AS
/*
funkcja sumuje sprzedaz kazdej marki na koniec rundy i dodaje przychod ze sprzdazy do kont producentow
*/
aktualna_runda NUMBER;
BEGIN
    select max(numer_rundy) into aktualna_runda from numery_rund;
    FOR i IN (select id_producenta, sum(przychod) as przychod from SPRZEDAZ_P where numer_rundy = aktualna_runda group by id_producenta)
    LOOP
        update producenci set fundusze = fundusze + i.przychod where id_producenta = i.id_producenta;
    END LOOP;
END LICZ_PRZYCHOD;
/

create or replace PROCEDURE OCEN_MARKE(BADANIE_RYNKU NUMBER, MARKA NUMBER, GRUPA_KONSUMENTOW NUMBER, DLUGOSC_HIS_ZAKUPOW NUMBER,
                                        CZY_UWZGLEDNIC_JAKOSC CHAR,
                                        CZY_UWZGLEDNIC_CENE CHAR,
                                        CZY_UWZGL_HIS_ZAKUPOW CHAR,
                                        CZY_UWZGL_MARKETING_RUNDA CHAR,
                                        CZY_UWZGL_MARKETING_HISTORIA CHAR
) AS
    ocena_konsumenta NUMBER;
    nr_rundy NUMBER;
    czy_docelowa_marka_utworzona NUMBER;
    liczba_wszystkich_marek NUMBER;
    sr_market_prod NUMBER;
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;
    select count(id_marki) into liczba_wszystkich_marek from marki where czy_utworzona = 't';
    --badanie rynku odbywa sie jako porownanie pewnej marki (utworzonej lub nie) z pozostalymi markami dostepnymi na rynku, czyli utworzonymi
    --jesli badana marka nie zostala jeszcze utworzona to liczebnosc zbioru analizowanych marek musi zostac zwiekszona o 1
    select count(id_marki) into czy_docelowa_marka_utworzona from marki where czy_utworzona = 'n' and id_marki = marka;
    liczba_wszystkich_marek := liczba_wszystkich_marek + czy_docelowa_marka_utworzona;
    
    SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
    select wplyw_marketingu_producenta into sr_market_prod from ustawienia_poczatkowe where czy_aktywna = 'a';
    
    FOR REC IN ((
select
    id_konsumenta,
    count(id_marki) as liczba_gorszych_marek
from
(
            with reklama_marki_runda as(
                select
                    m.id_marki,
                    NVL(sum(intensywnosc_marketingu),0) as wplyw_marka
                from marketingi m
                where
                    m.numer_rundy = nr_rundy
                group by m.id_marki
            ),
            reklama_marki_his as(
                select
                    m.id_marki,
                    NVL(sum(intensywnosc_marketingu), 0) as wplyw_marka_his
                from marketingi m
                where
                    m.numer_rundy > nr_rundy - 6
                group by m.id_marki
            ),
            reklama_producenta_runda as (
                select m.id_producenta, NVL(avg(o.wplyw_marka), 0) as wplyw_producent
                from
                    reklama_marki_runda o,
                    marki m
                where
                    m.id_marki = o.id_marki
                group by
                    m.id_producenta),
            reklama_producenta_his as (
                select m.id_producenta, NVL(avg(o.wplyw_marka_his), 0) as wplyw_producent_his
                from
                    reklama_marki_his o,
                    marki m
                where
                    m.id_marki = o.id_marki
                group by
                    m.id_producenta),
            parametry_marek as (
                select
                    k.id_konsumenta,
                    k.cena_poziom_aspiracji,
                    k.cena_poziom_rezerwacji,
                    k.jakosc_poziom_aspiracji, 
                    k.jakosc_poziom_rezerwacji,
                    k.his_zakupow_poziom_aspiracji,
                    k.his_zakupow_poziom_rezerwacji,
                    k.marketing_poziom_aspiracji,
                    k.marketing_poziom_rezerwacji,
                    m.id_marki,
                    m.cena_za_sztuke,
                    m.jakosc_marki,
                    NVL(((1 - sr_market_prod)*mr.wplyw_marka + sr_market_prod*pr.wplyw_producent), 0) as marketing_runda,
                    NVL(((1 - sr_market_prod)*mh.wplyw_marka_his + sr_market_prod*ph.wplyw_producent_his), 0) as marketing_historia,
                    (SELECT
                        NVL(sum(CASE
                        WHEN numer_rundy IN(nr_rundy-1, nr_rundy-3)
                            THEN 2
                        WHEN numer_rundy = nr_rundy-2
                            THEN 3
                        WHEN numer_rundy IN(nr_rundy-4, nr_rundy-5, nr_rundy-6)
                            THEN 1
                        END), 0)/10 AS wart
                    FROM zakupy_konsumentow
                    where id_konsumenta = k.id_konsumenta and id_marki = m.id_marki
                    ) as historia_zakupow
                from
                    konsumenci k,
                    marki m
                    left join reklama_producenta_runda pr on m.id_producenta = pr.id_producenta
                    left join reklama_marki_runda mr on m.id_marki = mr.id_marki
                    left join reklama_producenta_his ph on m.id_producenta = ph.id_producenta
                    left join reklama_marki_his mh on m.id_marki = mh.id_marki
                where
                    m.czy_utworzona = 't'),
            oceny_marek as (
                 select
                    id_marki,
                    id_konsumenta,
                    --funkcja osiagniecia wartosc_f_osiagniecia := min(f1, f2, ...) + epsilon * (f1 + f2 + ...);
                    POLICZ_MPO_WYBRANE_WYMIARY(
                        POLICZ_WYMIAR_MPO(cena_poziom_aspiracji, cena_poziom_rezerwacji, cena_za_sztuke),  CZY_UWZGLEDNIC_CENE,
                        POLICZ_WYMIAR_MPO(jakosc_poziom_aspiracji, jakosc_poziom_rezerwacji, jakosc_marki), CZY_UWZGLEDNIC_JAKOSC,
                        POLICZ_WYMIAR_MPO(his_zakupow_poziom_aspiracji, his_zakupow_poziom_rezerwacji, historia_zakupow), CZY_UWZGL_HIS_ZAKUPOW,
                        POLICZ_WYMIAR_MPO(marketing_poziom_aspiracji, marketing_poziom_rezerwacji, marketing_runda), CZY_UWZGL_MARKETING_RUNDA,
                        POLICZ_WYMIAR_MPO(marketing_poziom_aspiracji, marketing_poziom_rezerwacji, marketing_historia), CZY_UWZGL_MARKETING_HISTORIA
                    ) as wart_f_osiagniecia
                from parametry_marek
            ),
            parametry_wybranej_marki as (
                select
                    k.id_konsumenta,
                    k.cena_poziom_aspiracji,
                    k.cena_poziom_rezerwacji,
                    k.jakosc_poziom_aspiracji, 
                    k.jakosc_poziom_rezerwacji,
                    k.his_zakupow_poziom_aspiracji,
                    k.his_zakupow_poziom_rezerwacji,
                    k.marketing_poziom_aspiracji,
                    k.marketing_poziom_rezerwacji,
                    m.id_marki,
                    m.cena_za_sztuke,
                    m.jakosc_marki,
                    NVL(((1 - sr_market_prod)*mr.wplyw_marka + sr_market_prod*pr.wplyw_producent), 0) as marketing_runda,
                    NVL(((1 - sr_market_prod)*mh.wplyw_marka_his + sr_market_prod*ph.wplyw_producent_his), 0) as marketing_historia,
                    (SELECT
                        NVL(sum(CASE
                        WHEN numer_rundy IN(nr_rundy-1, nr_rundy-3)
                            THEN 2
                        WHEN numer_rundy = nr_rundy-2
                            THEN 3
                        WHEN numer_rundy IN(nr_rundy-4, nr_rundy-5, nr_rundy-6)
                            THEN 1
                        END), 0)/10 AS wart
                    FROM zakupy_konsumentow
                    where id_konsumenta = k.id_konsumenta and id_marki = m.id_marki
                    ) as historia_zakupow
                from
                    konsumenci k,
                    marki m
                    left join reklama_producenta_runda pr on m.id_producenta = pr.id_producenta
                    left join reklama_marki_runda mr on m.id_marki = mr.id_marki
                    left join reklama_producenta_his ph on m.id_producenta = ph.id_producenta
                    left join reklama_marki_his mh on m.id_marki = mh.id_marki
                where
                    m.id_marki = marka),
            oceny_wybranej_marki as (
                 select
                    id_marki,
                    id_konsumenta,
                    --funkcja osiagniecia wartosc_f_osiagniecia := min(f1, f2, ...) + epsilon * (f1 + f2 + ...);
                    POLICZ_MPO_WYBRANE_WYMIARY(
                        POLICZ_WYMIAR_MPO(cena_poziom_aspiracji, cena_poziom_rezerwacji, cena_za_sztuke),  CZY_UWZGLEDNIC_CENE,
                        POLICZ_WYMIAR_MPO(jakosc_poziom_aspiracji, jakosc_poziom_rezerwacji, jakosc_marki), CZY_UWZGLEDNIC_JAKOSC,
                        POLICZ_WYMIAR_MPO(his_zakupow_poziom_aspiracji, his_zakupow_poziom_rezerwacji, historia_zakupow), CZY_UWZGL_HIS_ZAKUPOW,
                        POLICZ_WYMIAR_MPO(marketing_poziom_aspiracji, marketing_poziom_rezerwacji, marketing_runda), CZY_UWZGL_MARKETING_RUNDA,
                        POLICZ_WYMIAR_MPO(marketing_poziom_aspiracji, marketing_poziom_rezerwacji, marketing_historia), CZY_UWZGL_MARKETING_HISTORIA
                    ) as wart_f_osiagniecia
                from parametry_wybranej_marki
            )
            select
                oceny_marek.id_konsumenta,
                oceny_marek.id_marki
            from
                oceny_marek,
                oceny_wybranej_marki
            where
                oceny_marek.id_konsumenta = oceny_wybranej_marki.id_konsumenta
                and  oceny_marek.wart_f_osiagniecia < oceny_wybranej_marki.wart_f_osiagniecia    
)
group by id_konsumenta
))

    -------------------------------------------------------------------------------------
    --DZIALANIA W PETLI
    -------------------------------------------------------------------------------------- 
    
    LOOP
        --wpisanie oceny
        ocena_konsumenta := round((rec.liczba_gorszych_marek/liczba_wszystkich_marek)*10, 0);
        insert into oceny_marek values (rec.id_konsumenta, badanie_rynku, ocena_konsumenta);

        --udostepnienie producentowi historii zakupow konsumenta
        if DLUGOSC_HIS_ZAKUPOW > 0 then
            for i in 1..DLUGOSC_HIS_ZAKUPOW loop 
                BEGIN
                    insert into dostepy_producentow_his_zakup values (rec.id_konsumenta, nr_rundy - i, BADANIE_RYNKU);
                EXCEPTION
                --jesli gracz bedzie nierozwaznie planowal badanie rynku, to moze ponownie zakupic dostep do informacji o zakupie
                --danego klienta w danej rundzie; pojawia sie wowczas blad naruszenia wiezow integralnosci, ktory nalezy zignorowac
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        null;
                END;
            end loop;
            --commit;
        end if;
    end loop;
END OCEN_MARKE;


create or replace PROCEDURE POTRAC_KOSZTY_MAGAZYNOWANIA AS 
/*
procedura oblicza koszty magazynowania niesprzedanego towaru i potraca je z kont producentow
*/
    koszt NUMBER (15, 0);
    nr_rundy NUMBER (5, 0);
    sposob_nalicz_kosztow CHAR(1);
    koszt_mag_sztuki NUMBER (15, 0);
    wielkosc_pow_mag NUMBER (12, 0);
    upust_per_magazyn NUMBER (2, 0);
    upust NUMBER;
    liczba_magazynow NUMBER (6, 0);
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;

    /*
    sprawdzenie jaki sposob naliczania kosztow magazynowania zostal ustawiony w ustawieniach poczatkowych
    */
    SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
    select
        SPOSOB_NALICZ_KOSZT_MAGAZYN,
        KOSZT_MAG_SZTUKI_LUB_MAGAZYNU
    into
        sposob_nalicz_kosztow,
        koszt_mag_sztuki
    from
        USTAWIENIA_POCZATKOWE
    where
        czy_aktywna = 'a';

    --jesli obowiazuje liniowy sposob naliczania kosztow magazynowania, czyli producent placi niezalezna stawke za kazda sztuke zmagazynowanego produktu
    if sposob_nalicz_kosztow = 'l' then
        FOR REC IN (SELECT m.id_marki, m.aktualna_liczba_sztuk, m.ID_PRODUCENTA from marki m where aktualna_liczba_sztuk > 0)
        LOOP
            --okreslenie kosztu magazyniwania
            koszt := rec.aktualna_liczba_sztuk * koszt_mag_sztuki;
            --obciazenie kosztami konta producenta
            UPDATE producenci SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.id_producenta;
            --dodanie wpisu do tabeli historii magazynowania
            insert into magazynowania values (rec.aktualna_liczba_sztuk, koszt, nr_rundy, rec.id_marki);
        END LOOP;
    else
    --jesli koszt magazynowania jest potracany za przestrzen magazynowa niezbedna do przechowania niesprzedanych sztuk produktu
        select WIELKOSC_POWIERZCHNI_MAG into wielkosc_pow_mag from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';
        select UPUST_ZA_KOLEJNY_MAGAZYN into upust_per_magazyn from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';

        FOR REC IN (select sum(aktualna_liczba_sztuk) as liczba_sztuk, ID_PRODUCENTA from marki where aktualna_liczba_sztuk > 0 group by ID_PRODUCENTA)
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
            UPDATE producenci SET fundusze = fundusze - koszt WHERE ID_PRODUCENTA = REC.ID_PRODUCENTA;
            --dodanie wpisow do tabeli historii magazynowania
            FOR MAR IN (select id_marki, aktualna_liczba_sztuk, ID_PRODUCENTA from marki where ID_PRODUCENTA = rec.ID_PRODUCENTA)
            LOOP
                insert into magazynowania values (mar.aktualna_liczba_sztuk, koszt*(mar.aktualna_liczba_sztuk/rec.liczba_sztuk), nr_rundy, mar.id_marki);
            END LOOP;
         END LOOP;
    end if;
END POTRAC_KOSZTY_MAGAZYNOWANIA;


create or replace PROCEDURE RESTART_PARAMETROW_PRODUCENTOW AS 
/*
procedura ustawia wszystkim producentom te sama kwote funduszy, ktora pobiera z ustawien poczatkowych
dodatkowo gasi flage oznaczajaca czy producent spasowal
*/
    pocz_fundusze number (10, 0);
BEGIN
    select poczatkowe_fundusze into pocz_fundusze from ustawienia_poczatkowe where czy_aktywna = 'a';
    update PRODUCENCI set FUNDUSZE = pocz_fundusze, CZY_SPASOWAL = 'n';
    commit;
END RESTART_PARAMETROW_PRODUCENTOW;


create or replace PROCEDURE RESTART_SEKWENCJI ( NAZWA_SEKWENCJI varchar2 ) AS
/*
procedura restarutuje wskazana sekwencje, tak aby mogla byc ponownie wykorzystana w nowej rozgrywce
*/
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

create or replace PROCEDURE WSTAW_DOMYSLNE_JAKOSCI_MAREK
/*
procedura generuje standardowy zestaw jakosci marek wraz z referencyjnymi cenami produkcji;
ceny te moga nie byc adekwatne do skali cen obowiazujacych na symulowanym rynku
i dlatego powinny byc modyfikowane na potrzeby kazdej gry
*/
IS
BEGIN
   insert into jakosci_marek values (1, 1000);
   insert into jakosci_marek values (2, 1100);
   insert into jakosci_marek values (3, 1200);
   insert into jakosci_marek values (4, 1300);
   insert into jakosci_marek values (5, 1400);
   commit;
END WSTAW_DOMYSLNE_JAKOSCI_MAREK;
/

create or replace PROCEDURE WYCZYSC_TABELE AS
/*
funkcja usuwa wszystkie dane pozostale po porzedniej rozgrywce
*/
BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE dostepy_producentow_his_zakup';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE oceny_marek';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE historie_cen';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE magazynowania';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE produkcje';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE marketingi';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PRZYNALEZNOSCI_DO_GRUP';

    EXECUTE IMMEDIATE 'alter table badania_rynku disable constraint BADANIA_RYNKU_GRY_KONS_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup disable constraint PRZYN_DO_GRUP_GRY_KONS_FK';
    EXECUTE IMMEDIATE 'truncate table GRUPY_KONSUMENTOW';
    EXECUTE IMMEDIATE 'alter table badania_rynku enable constraint BADANIA_RYNKU_GRY_KONS_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup enable constraint PRZYN_DO_GRUP_GRY_KONS_FK';

    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup disable constraint DOST_PROD_ZAKUPY_KONS_FK';
    EXECUTE IMMEDIATE 'truncate table zakupy_konsumentow';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup enable constraint DOST_PROD_ZAKUPY_KONS_FK';

    EXECUTE IMMEDIATE 'alter table oceny_marek disable constraint OCENY_MAREK_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup disable constraint DOST_PROD_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'truncate table badania_rynku';
    EXECUTE IMMEDIATE 'alter table oceny_marek enable constraint OCENY_MAREK_BADANIA_RYNKU_FK';
    EXECUTE IMMEDIATE 'alter table dostepy_producentow_his_zakup enable constraint DOST_PROD_BADANIA_RYNKU_FK';

    EXECUTE IMMEDIATE 'alter table oceny_marek disable constraint OCENY_MAREK_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table zakupy_konsumentow disable constraint ZAKUPY_KONSUMENTOW_KONS_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup disable constraint PRZYN_DO_GRUP_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'truncate table konsumenci';
    EXECUTE IMMEDIATE 'alter table oceny_marek enable constraint OCENY_MAREK_KONSUMENCI_FK';
    EXECUTE IMMEDIATE 'alter table zakupy_konsumentow enable constraint ZAKUPY_KONSUMENTOW_KONS_FK';
    EXECUTE IMMEDIATE 'alter table przynaleznosci_do_grup enable constraint PRZYN_DO_GRUP_KONSUMENCI_FK';

    DELETE FROM marki CASCADE;
    DELETE FROM numery_rund CASCADE;
END WYCZYSC_TABELE;
/

create or replace PROCEDURE ZREALIZUJ_ZAKUPY AS
    epsilon NUMBER := 0.01;
    nr_rundy NUMBER;
    wybrana_marka NUMBER;
    liczba_produktow NUMBER;
    sr_market_prod NUMBER;
BEGIN
    select max(numer_rundy) into nr_rundy from numery_rund;
    select sum(aktualna_liczba_sztuk) into liczba_produktow from marki where czy_utworzona = 't';
    SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
    select wplyw_marketingu_producenta into sr_market_prod from ustawienia_poczatkowe where czy_aktywna = 'a';


    FOR REC IN ((SELECT
                    id_konsumenta,
                    CENA_POZIOM_ASPIRACJI,
                    CENA_POZIOM_REZERWACJI,
                    JAKOSC_POZIOM_ASPIRACJI,
                    JAKOSC_POZIOM_REZERWACJI,
                    HIS_ZAKUPOW_POZIOM_ASPIRACJI,
                    HIS_ZAKUPOW_POZIOM_REZERWACJI,
                    MARKETING_POZIOM_ASPIRACJI,
                    MARKETING_POZIOM_REZERWACJI
                from
                    konsumenci))
    LOOP

    if liczba_produktow = 0 then
        insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, null);
    else

    select id_marki into wybrana_marka from (
        select
            id_marki,
            --funkcja osiagniecia wartosc_f_osiagniecia := min(f1, f2, ...) + epsilon * (f1 + f2 + ...);
            least(
                POLICZ_WYMIAR_MPO(rec.cena_poziom_aspiracji, rec.cena_poziom_rezerwacji, cena_za_sztuke),
                POLICZ_WYMIAR_MPO(rec.jakosc_poziom_aspiracji, rec.jakosc_poziom_rezerwacji, jakosc_marki),
                POLICZ_WYMIAR_MPO(rec.marketing_poziom_aspiracji, rec.marketing_poziom_rezerwacji, marketing_runda),
                POLICZ_WYMIAR_MPO(rec.marketing_poziom_aspiracji, rec.marketing_poziom_rezerwacji, marketing_historia),
                POLICZ_WYMIAR_MPO(rec.his_zakupow_poziom_aspiracji, rec.his_zakupow_poziom_rezerwacji, historia_zakupow))
            + epsilon * (
                POLICZ_WYMIAR_MPO(rec.cena_poziom_aspiracji, rec.cena_poziom_rezerwacji, cena_za_sztuke) +
                POLICZ_WYMIAR_MPO(rec.jakosc_poziom_aspiracji, rec.jakosc_poziom_rezerwacji, jakosc_marki) +
                POLICZ_WYMIAR_MPO(rec.marketing_poziom_aspiracji, rec.marketing_poziom_rezerwacji, marketing_runda) +
                POLICZ_WYMIAR_MPO(rec.marketing_poziom_aspiracji, rec.marketing_poziom_rezerwacji, marketing_historia) +
                POLICZ_WYMIAR_MPO(rec.his_zakupow_poziom_aspiracji, rec.his_zakupow_poziom_rezerwacji, historia_zakupow)
            ) as wart_f_osiagniecia
        from(                  
        with reklama_marki_runda as(
            select
                m.id_marki,
                NVL(sum(intensywnosc_marketingu),0) as wplyw_marka
            from marketingi m
            where
                m.numer_rundy = nr_rundy
            group by m.id_marki
        ),
        reklama_marki_his as(
            select
                m.id_marki,
                NVL(sum(intensywnosc_marketingu), 0) as wplyw_marka_his
            from marketingi m
            where
                m.numer_rundy > nr_rundy - 6
            group by m.id_marki
        ),
        reklama_producenta_runda as (
            select m.id_producenta, NVL(avg(o.wplyw_marka), 0) as wplyw_producent
            from
                reklama_marki_runda o,
                marki m
            where
                m.id_marki = o.id_marki
            group by
                m.id_producenta),
        reklama_producenta_his as (
            select m.id_producenta, NVL(avg(o.wplyw_marka_his), 0) as wplyw_producent_his
            from
                reklama_marki_his o,
                marki m
            where
                m.id_marki = o.id_marki
            group by
                m.id_producenta)
        select
            m.id_marki,
            m.cena_za_sztuke,
            m.jakosc_marki,
            NVL(((1 - sr_market_prod)*mr.wplyw_marka + sr_market_prod*pr.wplyw_producent), 0) as marketing_runda,
            NVL(((1 - sr_market_prod)*mh.wplyw_marka_his + sr_market_prod*ph.wplyw_producent_his), 0) as marketing_historia,
            (SELECT
                NVL(sum(CASE
                WHEN numer_rundy IN(4-1, 4-3)
                    THEN 2
                WHEN numer_rundy = 4-2
                    THEN 3
                WHEN numer_rundy IN(4-4, 4-5, 4-6)
                    THEN 1
                END), 0)/10 AS wart
            FROM zakupy_konsumentow
            where id_konsumenta = rec.id_konsumenta and id_marki = m.id_marki
            ) as historia_zakupow
        from 
            marki m
            left join reklama_producenta_runda pr on m.id_producenta = pr.id_producenta
            left join reklama_marki_runda mr on m.id_marki = mr.id_marki
            left join reklama_producenta_his ph on m.id_producenta = ph.id_producenta
            left join reklama_marki_his mh on m.id_marki = mh.id_marki
        where
            m.czy_utworzona = 't'
            and m.aktualna_liczba_sztuk > 0)
        where rownum = 1
        order by wart_f_osiagniecia desc);

        insert into zakupy_konsumentow values (nr_rundy, rec.id_konsumenta, wybrana_marka);
        update marki set aktualna_liczba_sztuk = aktualna_liczba_sztuk - 1 where id_marki = wybrana_marka;
        liczba_produktow := liczba_produktow - 1;

        end if;

        --commit;
    END LOOP;
END ZREALIZUJ_ZAKUPY;
/

CREATE OR REPLACE PROCEDURE STWORZ_CZASOMIERZ AS
/*
procedura tworzy job'a, ktory regularnie sprawdza czy zostal spelniony warunek zakonczenia rundy i rozpoczecia nastepnej
*/
INTERWAL NUMBER;
CZY_ISTNIEJE_ZADANIE NUMBER;
WAR_ZAKONCZENIA_RUNDY CHAR;
BEGIN
    --usuniecie poprzednio utworzonego joba (jesli taki istnial)
    SELECT count(JOB_NAME) into czy_istnieje_zadanie FROM ALL_SCHEDULER_JOBS where JOB_NAME = 'ROZPOCZNIJ_NOWA_RUNDE';
    if CZY_ISTNIEJE_ZADANIE > 0 then
        BEGIN
            DBMS_SCHEDULER.DROP_JOB(JOB_NAME => 'ROZPOCZNIJ_NOWA_RUNDE');
        END;
    end if;
    
    --sprawdzenie czy istnieje potrzeba stworzenia czasomierza; jesli kolejne rundy maja byc uruchamiane recznie, wowczas czasomierz jest niepotrzebny
    --od razu, zeby ograniczyc zapytania, pobierany jest czas rundy jako interwal dla czasomierza
    select
        warunek_zakonczenia_rundy,
        czas_rundy
    into
        WAR_ZAKONCZENIA_RUNDY,
        interwal
    from
        ustawienia_poczatkowe where czy_aktywna = 'a';
    
    if WAR_ZAKONCZENIA_RUNDY = 'r' then
        return;
    end if;
    
    /*
    czas rundy moze byc null jesli warunkiem zakonczenia rundy jest pas wszystkich graczy
    jednak w takiej sytuacji czasomierz (i interwal) wciaz jest potrzebny i sluzy do cyklicznego sprawdzania czy wszyscy spasowali
                                zrealizowanie rozpoczynania kolejnej rundy na bazie wyzwalacza podpietego pod tabele PRODUCENCI i pole CZY_SPASOWAL
                                prowadzilo do mutacji tabeli PRODUCENCI
    interwal zostaje ustawiony na 1 minute jako najmniejsza wartosc, a wiec baza co minute sprawdza czy wszyscy spasowali; jesli tak, rozpoczyna nastepna runde
    */
    if INTERWAL is null then
        interwal := 1;
    end if;
    
    BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        JOB_NAME        => 'ROZPOCZNIJ_NOWA_RUNDE',
        JOB_TYPE        => 'STORED_PROCEDURE',
        JOB_ACTION      => 'hziarek.rozpocznij_runde',
        START_DATE      => SYSTIMESTAMP,
        REPEAT_INTERVAL => 'FREQ=MINUTELY;INTERVAL='||interwal||';',
        ENABLED         => TRUE,
        COMMENTS        => 'Job rozpoczyna nowa runde');
    END;
END STWORZ_CZASOMIERZ;
/

create or replace PROCEDURE ROZPOCZNIJ_GRE AS
/*
procedura wywolywana na poczatku w celu uruchomienia nowej gry;
jej wywolanie powoduje usuniecia wszystkich danych zwiazanych z poprzednia gra
oraz wygenerowanie nowego zbioru konsumentow
*/
    czy_wstawic_jakosci char(1);
BEGIN
    --sprawdzenie czy istnieje aktywny zestaw ustawien poczatkowych, aby pobrac z niego niezbedne parametry
    declare
        czy_aktywna_opcja number;
    BEGIN
        select count(numer_zestawu) into czy_aktywna_opcja from USTAWIENIA_POCZATKOWE where czy_aktywna = 'a';
        if czy_aktywna_opcja <> 1 then
            raise_application_error(-20805, 'Brak aktywnego zestawu ustawien poczatkowych');
        end if;
    END;
    --czyszczenie danych pozostalych po poprzedniej grze
    WYCZYSC_TABELE;
    --restartowanie sekwencji
    ZRESTARTUJ_SEKWENCJE;
    --wstawienie domyslnych wartosci jakosci marki wraz z referencyjnymi kosztami produkcji jesli taka opcja zostala wybrana w ustawieniach poczatkowych
    select czy_jakosci_marek_domyslne into czy_wstawic_jakosci from ustawienia_poczatkowe where czy_aktywna = 'a';
    if czy_wstawic_jakosci = 't' then
        DELETE FROM jakosci_marek CASCADE;
        WSTAW_DOMYSLNE_JAKOSCI_MAREK;
    end if;
    --stworzenie konsumentow
    GENERUJ_KONSUMENTOW;
    --stworzenie bazowych grup konsumentow
    GENERUJ_GRUPY_KONSUMENTOW;
    --restartowanie parametrow producentow, czyli graczy
    RESTART_PARAMETROW_PRODUCENTOW;
    --rozpoczecie pierwszej rundy
    insert into numery_rund values (1);
    --uruchmienie czasomierza
    STWORZ_CZASOMIERZ;
    commit;
END ROZPOCZNIJ_GRE;
/

create or replace PROCEDURE ROZPOCZNIJ_RUNDE AS
/*
procedura rozpoczyna nowa runde poprzez zwiekszenie licznika rund
*/
warunek_zakonczenia CHAR;
nie_spasowali number;
max_liczba_rund number;
aktualna_runda number;
BEGIN
  SPR_CZY_ISTNIEJE_AKTYWNY_ZES_USTAWIEN;
  
  select
    warunek_zakonczenia_rundy,
    liczba_rund
  into
    warunek_zakonczenia,
    max_liczba_rund
  from
    ustawienia_poczatkowe where czy_aktywna = 'a';
  
  select max(numer_rundy) into aktualna_runda from numery_rund;
  
  --sprawdzenie czy nie zostala osiagnieta maksymalna liczba rund
  if max_liczba_rund is not null and max_liczba_rund <= aktualna_runda then
    BEGIN
    DBMS_SCHEDULER.SET_ATTRIBUTE (
       'ROZPOCZNIJ_NOWA_RUNDE',
       'ENABLED',
       FALSE);
    END;
    raise_application_error(-20950, 'Osiagnieto maksymalna liczbe rund');
  end if;
  
  --jesli warunkiem zakonczenia rundy i rozpoczecia nastepnej jest pas wszystkich graczy,
  --to runda nie powinna zostac zakonczona, jesli wszyscy nie spasowali
  if warunek_zakonczenia = 'p' then
        select count(id_producenta) into nie_spasowali from producenci where CZY_SPASOWAL = 'n';
        if nie_spasowali != 0 then
            return;
        end if;
    end if;

  --realizacja zakupow klientow
  ZREALIZUJ_ZAKUPY;

  --przeliczanie i dodanie przychodu ze sprzedazy do kont producentow
  LICZ_PRZYCHOD;

  --potracenie kosztow magazynowania za towar nie sprzedany w danej rundzie
  POTRAC_KOSZTY_MAGAZYNOWANIA;

  --zwiekszenie licznika rund
  insert into numery_rund values (null);

  --przywrocenie producentom mozliwosci wykonywania dzialan
  update producenci set czy_spasowal = 'n';
  --commit;
END ROZPOCZNIJ_RUNDE;
/
