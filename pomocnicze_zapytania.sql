--historia zakupow
select m.id_marki, k.id_konsumenta,
    (SELECT
        sum(CASE
        WHEN numer_rundy IN(4-1, 4-3)
            THEN 2
        WHEN numer_rundy = 4-2
            THEN 3
        WHEN numer_rundy IN(4-4, 4-5, 4-6)
            THEN 1
        ELSE 0
        END)/10 AS wartosc
    FROM zakupy_konsumentow
    where id_konsumenta = k.id_konsumenta and id_marki = m.id_marki
    ) as wart
from marki m, konsumenci k;

--marketing z ostatniej rundy
select m.id_producenta, avg(o.wplyw)
from
    (select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy = 4
    group by m.id_marki) o,
    marki m
where
    m.id_marki = o.id_marki
group by
    m.id_producenta;
    
--marketing z ostatniej rundy - calosc
with wplyw_reklamy_marki as(
    select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw_marka
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy = 4
    group by m.id_marki
),
wplyw_reklam_producenta as (
    select m.id_producenta, avg(o.wplyw_marka) as wplyw_producent
    from
        wplyw_reklamy_marki o,
        marki m
    where
        m.id_marki = o.id_marki
    group by
        m.id_producenta)
select
    m.id_marki, m.cena_za_sztuke, m.jakosc_marki, w.wplyw_marka, p.wplyw_producent
from 
    wplyw_reklam_producenta p, wplyw_reklamy_marki w, marki m
where
    m.id_marki = w.id_marki
    and m.id_producenta = p.id_producenta
    and m.czy_utworzona = 't'
    and aktualna_liczba_sztuk > 0;
    
    
    
--marketing z ostatniej rundy i historia + parametry
with reklama_marki_runda as(
    select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw_marka
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy = 4
    group by m.id_marki
),
reklama_marki_his as(
    select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw_marka_his
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy <= 4
    group by m.id_marki
),
reklama_producenta_runda as (
    select m.id_producenta, avg(o.wplyw_marka) as wplyw_producent
    from
        reklama_marki_runda o,
        marki m
    where
        m.id_marki = o.id_marki
    group by
        m.id_producenta),
reklama_producenta_his as (
    select m.id_producenta, avg(o.wplyw_marka_his) as wplyw_producent_his
    from
        reklama_marki_his o,
        marki m
    where
        m.id_marki = o.id_marki
    group by
        m.id_producenta)
select
    m.id_marki, m.cena_za_sztuke, m.jakosc_marki,
    (0.4*mr.wplyw_marka + 0.6*pr.wplyw_producent) as marketing_runda,
    (0.4*mh.wplyw_marka_his + 0.6*ph.wplyw_producent_his) as marketing_historia
from 
    reklama_producenta_runda pr, reklama_marki_runda mr, reklama_producenta_his ph, reklama_marki_his mh, marki m
where
    m.id_marki = mr.id_marki
    and m.id_producenta = pr.id_producenta
    and m.id_marki = mh.id_marki
    and m.id_producenta = ph.id_producenta
    and m.czy_utworzona = 't'
    and aktualna_liczba_sztuk > 0;
    
--zapytanie w petli
with reklama_marki_runda as(
    select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw_marka
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy = 4
    group by m.id_marki
),
reklama_marki_his as(
    select
        m.id_marki,
        sum(wplyw_na_docelowa_marke) as wplyw_marka_his
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy <= 4
    group by m.id_marki
),
reklama_producenta_runda as (
    select m.id_producenta, avg(o.wplyw_marka) as wplyw_producent
    from
        reklama_marki_runda o,
        marki m
    where
        m.id_marki = o.id_marki
    group by
        m.id_producenta),
reklama_producenta_his as (
    select m.id_producenta, avg(o.wplyw_marka_his) as wplyw_producent_his
    from
        reklama_marki_his o,
        marki m
    where
        m.id_marki = o.id_marki
    group by
        m.id_producenta)
select
    m.id_marki, m.cena_za_sztuke, m.jakosc_marki,
    (0.4*mr.wplyw_marka + 0.6*pr.wplyw_producent) as marketing_runda,
    (0.4*mh.wplyw_marka_his + 0.6*ph.wplyw_producent_his) as marketing_historia,
    (SELECT
        sum(CASE
        WHEN numer_rundy IN(4-1, 4-3)
            THEN 2
        WHEN numer_rundy = 4-2
            THEN 3
        WHEN numer_rundy IN(4-4, 4-5, 4-6)
            THEN 1
        END)/10 AS wart
    FROM zakupy_konsumentow
    where id_konsumenta = 1 and id_marki = m.id_marki
    ) as wartosc_historii
from 
    reklama_producenta_runda pr, reklama_marki_runda mr, reklama_producenta_his ph, reklama_marki_his mh, marki m
where
    m.id_marki = mr.id_marki
    and m.id_producenta = pr.id_producenta
    and m.id_marki = mh.id_marki
    and m.id_producenta = ph.id_producenta
    and m.czy_utworzona = 't'
    and aktualna_liczba_sztuk > 0;
    
    
    
    
    
    
    
    
    --obliczenia przed reszta
select
    id_marki,
    --funkcja osiagniecia wartosc_f_osiagniecia := min(f1, f2, ...) + epsilon * (f1 + f2 + ...);
    least(
        POLICZ_WYMIAR_MPO(3, 4, cena_za_sztuke),
        POLICZ_WYMIAR_MPO(3, 4, jakosc_marki),
        POLICZ_WYMIAR_MPO(3, 4, marketing_runda),
        POLICZ_WYMIAR_MPO(3, 4, marketing_historia),
        POLICZ_WYMIAR_MPO(3, 4, historia_zakupow))
    + 0.01 * (
        POLICZ_WYMIAR_MPO(3, 4, cena_za_sztuke) +
        POLICZ_WYMIAR_MPO(3, 4, jakosc_marki) +
        POLICZ_WYMIAR_MPO(3, 4, marketing_runda) +
        POLICZ_WYMIAR_MPO(3, 4, marketing_historia) +
        POLICZ_WYMIAR_MPO(3, 4, historia_zakupow)
    ) as wart_f_osiagniecia
from(                  
with reklama_marki_runda as(
    select
        m.id_marki,
        NVL(sum(wplyw_na_docelowa_marke),0) as wplyw_marka
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy = 4
    group by m.id_marki
),
reklama_marki_his as(
    select
        m.id_marki,
        NVL(sum(wplyw_na_docelowa_marke), 0) as wplyw_marka_his
    from marketingi m, rodzaje_marketingu r
    where
        m.id_rodzaju_marketingu = r.id_rodzaju_marketingu
        and m.numer_rundy <= 4
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
    (0.4*mr.wplyw_marka + 0.6*pr.wplyw_producent) as marketing_runda,
    (0.4*mh.wplyw_marka_his + 0.6*ph.wplyw_producent_his) as marketing_historia,
    (SELECT
        NVL(sum(CASE
        WHEN numer_rundy IN(4-1, 4-3)
            THEN 2
        WHEN numer_rundy = 4-2
            THEN 3
        WHEN numer_rundy IN(4-4, 4-5, 4-6)
            THEN 1
        ELSE 0
        END), 0)/10 AS wart
    FROM zakupy_konsumentow
    where id_konsumenta = 1 and id_marki = m.id_marki
    ) as historia_zakupow
from 
    reklama_producenta_runda pr, reklama_marki_runda mr, reklama_producenta_his ph, reklama_marki_his mh, marki m
where
    m.id_marki = mr.id_marki
    and m.id_producenta = pr.id_producenta
    and m.id_marki = mh.id_marki
    and m.id_producenta = ph.id_producenta
    and m.czy_utworzona = 't'
    and aktualna_liczba_sztuk > 0);