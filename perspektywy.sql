CREATE OR REPLACE VIEW MARKI_P
AS SELECT 
    m.ID_MARKI,
    m.NAZWA_MARKI,
    TO_CHAR(
        (select koszt_produkcji from (
            select koszt_produkcji from koszty_produkcji_produktow where id_marki = m.id_marki
            order by numer_rundy desc)
         where rownum = 1
        )/100, '99999999999990.99') AS KOSZT_PRODUKCJI_SZTUKI,
    TO_CHAR(m.CENA_ZA_SZTUKE/100, '99999999999990.99') AS CENA_ZA_SZTUKE,
    m.JAKOSC_MARKI,
    m.RUNDA_UTWORZENIA,
    m.AKTUALNA_LICZBA_SZTUK
FROM
    MARKI m, PRODUCENCI p
WHERE
    m.id_producenta = p.id_producenta
    AND
    p.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW KOSZTY_MAGAZYNOWANIA_PRODUCENTA_P
AS SELECT 
    c.numer_rundy,
    (CASE
        WHEN c.sposob_naliczania_kosztow_mag = 'l'
            THEN 'LINIOWY'
        ELSE
            'MAGAZYNOWY'
    END) as sposob_naliczania_kosztow_mag,
    TO_CHAR(c.koszt_mag_sztuki_lub_magazynu/100, '99999999999990.99') AS KOSZT_MAGAZYNOWANIA_SZTUKI_LUB_MAGAZYNU,
    c.wielkosc_powierzchni_mag,
    c.upust_za_kolejny_magazyn
FROM
    KOSZTY_MAGAZYNOWANIA c, PRODUCENCI p
WHERE
    c.id_producenta = p.id_producenta
    AND
    p.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    )
order by numer_rundy desc
;

CREATE OR REPLACE VIEW KOSZTY_MARKETINGU_PRODUCENTA_P
AS SELECT 
    c.numer_rundy,
    TO_CHAR(c.koszt_bazowy/100, '99999999999990.99') AS KOSZT_BAZOWY,
    TO_CHAR(C.KOSZT_PER_ST_INTENS/100, '99999999999990.99') AS KOSZT_PER_ST_INTENS
FROM
    KOSZTY_MARKETINGU c, PRODUCENCI p
WHERE
    c.id_producenta = p.id_producenta
    AND
    p.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    )
order by numer_rundy desc
;
    
CREATE OR REPLACE VIEW KOSZTY_MARKETINGU_W_KOLEJNYCH_RUNDACH_P
AS select
    m.id_producenta,
    n.numer_rundy,
    (select koszt_bazowy from 
        (select koszt_bazowy from KOSZTY_MARKETINGU
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as koszt_bazowy,
    (select koszt_per_st_intens from 
        (select koszt_per_st_intens from KOSZTY_MARKETINGU
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as koszt_per_st_intensywnosci
from
    producenci m,
    numery_rund n
order by
    id_producenta, numer_rundy;
    
CREATE OR REPLACE VIEW KOSZTY_MAGAZYNOWANIA_W_KOLEJNYCH_RUNDACH_P
AS select
    m.id_producenta,
    n.numer_rundy,
    (select sposob_naliczania_kosztow_mag from 
        (select sposob_naliczania_kosztow_mag from KOSZTY_MAGAZYNOWANIA
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as sposob_naliczania_kosztow_mag,
    (select koszt_mag_sztuki_lub_magazynu from 
        (select koszt_mag_sztuki_lub_magazynu from KOSZTY_MAGAZYNOWANIA
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as koszt_mag_sztuki_lub_magazynu,
    (select wielkosc_powierzchni_mag from 
        (select wielkosc_powierzchni_mag from KOSZTY_MAGAZYNOWANIA
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as wielkosc_powierzchni_mag,
    (select upust_za_kolejny_magazyn from 
        (select upust_za_kolejny_magazyn from KOSZTY_MAGAZYNOWANIA
        where id_producenta = m.id_producenta and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as upust_za_kolejny_magazyn
from
    producenci m,
    numery_rund n
order by
    id_producenta, numer_rundy;

CREATE OR REPLACE VIEW KOSZTY_PRODUKCJI_PRODUKTOW_P
AS select
    m.id_marki,
    n.numer_rundy,
    (select koszt_produkcji from 
        (select koszt_produkcji from KOSZTY_PRODUKCJI_PRODUKTOW
        where id_marki = m.id_marki and numer_rundy <= n.numer_rundy
        order by numer_rundy desc)
        where rownum <= 1) as koszt_produkcji
from
    marki m,
    numery_rund n
order by
    id_marki, numer_rundy;

CREATE OR REPLACE VIEW PRODUCENCI_P
AS SELECT
    ID_PRODUCENTA,
    NAZWA_PRODUCENTA,
    TO_CHAR(FUNDUSZE/100, '99999999999990.99') AS FUNDUSZE,
    CZY_SPASOWAL
FROM
    PRODUCENCI
WHERE
    NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW PRODUKCJE_P
AS SELECT
    p.ID_PRODUKCJI,
    m.NAZWA_MARKI,
    p.NUMER_RUNDY,
    p.WOLUMEN, 
    TO_CHAR((c.KOSZT_PRODUKCJI*p.wolumen)/100, '99999999999990.99') AS KOSZT_PRODUKCJI
FROM
    PRODUKCJE p, MARKI m, PRODUCENCI r, KOSZTY_PRODUKCJI_PRODUKTOW_P c
WHERE
    p.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and c.id_marki = p.id_marki
    and c.numer_rundy = p.numer_rundy
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW HISTORIA_MAGAZYNOWANIA_P
AS SELECT
    m.NAZWA_MARKI,
    p.NUMER_RUNDY,
    p.WOLUMEN,
    c.sposob_naliczania_kosztow_mag,
    TO_CHAR((CASE
        WHEN c.sposob_naliczania_kosztow_mag = 'l'
            THEN p.wolumen*c.koszt_mag_sztuki_lub_magazynu
        ELSE
            CEIL(p.wolumen/C.WIELKOSC_POWIERZCHNI_MAG)*C.KOSZT_MAG_SZTUKI_LUB_MAGAZYNU
            *((100 - least(50, (CEIL(p.wolumen/C.WIELKOSC_POWIERZCHNI_MAG) - 1)*C.UPUST_ZA_KOLEJNY_MAGAZYN))/100)
        END)/100, '99999999999990.99') AS KOSZT_MAGAZYNOWANIA
FROM
    MAGAZYNOWANIA p, MARKI m, PRODUCENCI r, KOSZTY_MAGAZYNOWANIA_W_KOLEJNYCH_RUNDACH_P c
WHERE
    p.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and c.id_producenta = r.id_producenta
    and c.numer_rundy = p.numer_rundy
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW MARKETING_P
AS SELECT
    p.ID_MARKETINGU,
    p.NUMER_RUNDY,
    m.NAZWA_MARKI,
    p.INTENSYWNOSC_MARKETINGU,
    TO_CHAR((c.KOSZT_BAZOWY+C.KOSZT_PER_ST_INTENSYWNOSCI*P.INTENSYWNOSC_MARKETINGU)/100, '99999999999990.99') AS KOSZT_MARKETINGU
FROM
    MARKETINGI p, MARKI m, PRODUCENCI r, KOSZTY_MARKETINGU_W_KOLEJNYCH_RUNDACH_P c
WHERE
    p.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and c.id_producenta = r.id_producenta
    and c.numer_rundy = p.numer_rundy
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW BADANIA_RYNKU_P
AS SELECT
    b.ID_BADANIA_RYNKU,
    m.nazwa_marki,
    b.ID_GRUPY_KONSUMENTOW,
    b.numer_rundy,
    b.HIS_ZAKUPOW_LICZBA_RUND,
    TO_CHAR(b.KOSZT_BADANIA_RYNKU/100, '99999999999990.99') AS KOSZT_BADANIA_RYNKU,
    b.UWZGLEDNIC_JAKOSC,
    b.UWZGLEDNIC_CENE,
    b.UWZGLEDNIC_HIS_ZAKUPOW,
    b.UWZGLEDNIC_MARKETING,
    b.UWZG_MARKETING_OST_RUNDA
FROM
    BADANIA_RYNKU b, MARKI m, PRODUCENCI r
WHERE
    b.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );    

CREATE OR REPLACE VIEW OCENY_MAREK_P
AS SELECT
    b.ID_BADANIA_RYNKU,
    m.nazwa_marki,
    b.numer_rundy,
    o.ID_KONSUMENTA,
    b.UWZGLEDNIC_JAKOSC,
    b.UWZGLEDNIC_CENE,
    b.UWZGLEDNIC_HIS_ZAKUPOW,
    b.UWZGLEDNIC_MARKETING,
    b.UWZG_MARKETING_OST_RUNDA,
    o.ocena
FROM
    OCENY_MAREK o, BADANIA_RYNKU b, MARKI m, PRODUCENCI r
WHERE
    o.id_badania_rynku = b.id_badania_rynku
    and b.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW DOSTEP_DO_HIS_ZAKUPOW_P
AS SELECT
    b.ID_BADANIA_RYNKU,
    z.numer_rundy,
    z.ID_KONSUMENTA,
    m.nazwa_marki
FROM
    ZAKUPY_KONSUMENTOW z, DOSTEPY_PRODUCENTOW_HIS_ZAKUP d, BADANIA_RYNKU b, MARKI m, PRODUCENCI p
WHERE
    z.id_konsumenta = d.id_konsumenta and z.numer_rundy = d.numer_rundy
    and d.id_badania_rynku = b.id_badania_rynku
    and z.id_marki = m.id_marki
    and m.id_producenta = p.id_producenta
    and p.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW HISTORIE_CEN_P
AS SELECT
    m.nazwa_marki,
    c.numer_rundy,
    TO_CHAR(c.cena/100, '99999999999990.99') AS cena
FROM
    historie_cen c, MARKI m, PRODUCENCI r
WHERE
    c.id_marki = m.id_marki
    and m.id_producenta = r.id_producenta
    and r.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );

/*
CREATE OR REPLACE VIEW WARTOSCI_FUNKCJI_OSIAGNIECIA_MPO_P
AS 
SELECT 
    p.ID_KONSUMENTA,
    p.ID_MARKI,
    w.id_producenta,
    m.czy_utworzona,
    m.aktualna_liczba_sztuk,
    POLICZ_WYMIAR_MPO(k.CENA_POZIOM_ASPIRACJI, k.CENA_POZIOM_REZERWACJI, m.CENA_ZA_SZTUKE) AS CENA,
    POLICZ_WYMIAR_MPO(k.JAKOSC_POZIOM_ASPIRACJI, k.JAKOSC_POZIOM_REZERWACJI, m.JAKOSC_MARKI) AS JAKOSC,
    POLICZ_WYMIAR_MPO(k.PRZYWIAZANIE_POZIOM_ASPIRACJI, k.PRZYWIAZANIE_POZIOM_REZERWACJI, p.WSPOLCZYNNIK_PRZYWIAZANIA)
                AS PRZYWIAZANIE_DO_MARKI,
    POLICZ_WYMIAR_MPO(k.PRZYWIAZANIE_POZIOM_ASPIRACJI, k.PRZYWIAZANIE_POZIOM_REZERWACJI, w.PRZYW_DO_PROD)
                AS PRZYWIAZANIE_DO_PRODUCENTA
FROM 
    (select id_producenta, avg(p.WSPOLCZYNNIK_PRZYWIAZANIA) as PRZYW_DO_PROD
        from marki m, przywiazania_do_marek p
        where m.id_marki = p.id_marki
        group by id_producenta) w,
    PRZYWIAZANIA_DO_MAREK p, MARKI m, konsumenci k
WHERE
    m.id_marki = p.id_marki
    and k.id_konsumenta = p.id_konsumenta
    and m.id_producenta = w.id_producenta;
*/
    
CREATE OR REPLACE VIEW SPRZEDAZ_P
AS SELECT
    zak.numer_rundy, mar.NAZWA_MARKI, mar.id_producenta, zak.wolumen, (zak.wolumen*ceny.cena) as przychod
from
    (--zapytanie, ktore kazdej parze (marka, runda) przypisuje cene marki w danej rundzie
    select m.id_marki, n.numer_rundy,
        (select cena from 
            (select cena from historie_cen
            where id_marki = m.id_marki and numer_rundy <= n.numer_rundy
            order by numer_rundy desc)
                where rownum <= 1) as cena
    from  marki m, numery_rund n
    order by id_marki, numer_rundy) ceny,
    
    (--zapytanie, ktore sumuje zakupy konsumentow
    select id_marki, numer_rundy, count(id_marki) as wolumen
    from  ZAKUPY_KONSUMENTOW
    group by id_marki, numer_rundy) zak,
    marki mar
where
    ceny.id_marki = zak.id_marki and ceny.numer_rundy = zak.numer_rundy
    and mar.id_marki = zak.id_marki
;

CREATE OR REPLACE VIEW SPRZEDAZ_PRODUCENTOW_P
AS SELECT
    s.NUMER_RUNDY, s.NAZWA_MARKI, s.wolumen, TO_CHAR(s.przychod/100, '99999999999990.99') as przychod
FROM
    SPRZEDAZ_P s, PRODUCENCI p
WHERE
    s.id_producenta = p.id_producenta
    and p.NAZWA_PRODUCENTA = sys_context(
        'APEX$SESSION'
        ,'APP_USER'
    );
    
CREATE OR REPLACE VIEW MARKI_NA_RYNKU_P
AS SELECT
    m.nazwa_marki, p.nazwa_producenta, m.jakosc_marki, TO_CHAR((m.cena_za_sztuke)/100, '99999999999990.99') as cena_za_sztuke
from
    marki m, producenci p
where
    m.id_producenta = p.id_producenta
    and M.RUNDA_UTWORZENIA is not null;