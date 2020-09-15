create or replace PROCEDURE TEST (l_marek number, l_kons number) AS 
    t_zakupy number := 0;
    t_badanie number := 0;
    tz1 number;
    tz2 number;
    tb1 number;
    tb2 number;
    badana_marka number;
BEGIN
    
    generuj_marki(l_marek);
    
    --puste przebiegi
    for i in 1..6 loop
        generuj_marketingi;
        update marki set aktualna_liczba_sztuk = l_kons/5;
        commit;
        rozpocznij_runde;
    end loop; 


create or replace PROCEDURE TEST2 (l_kons NUMBER) AS 
BEGIN
    rozpocznij_gre;
    commit;
    test (8, l_kons);
    
    rozpocznij_gre;
    commit;
    test (16, l_kons);
    
    rozpocznij_gre;
    commit;
    test (32, l_kons);
    
    rozpocznij_gre;
    commit;
    test (48, l_kons);
    
    rozpocznij_gre;
    commit;
    test (64, l_kons);

END TEST2;

create or replace PROCEDURE GENERUJ_MARKI (liczba NUMBER) AS 
tmp number;
st number;
BEGIN
    select max(id_marki) into tmp from marki;
    if tmp is null then
        st := 1;
    else
        st := tmp + 1;
    end if;
    
  FOR i IN st..st+liczba-1 LOOP
   insert into marki values (null, 1, i, DBMS_RANDOM.value(1, 5), 1000, 1, DBMS_RANDOM.value(10, 20)*100, 1500);
  END LOOP;
END GENERUJ_MARKI;


create or replace PROCEDURE GENERUJ_MARKETINGI AS 
BEGIN
    FOR rec IN (select id_marki from marki) LOOP
        insert into marketingi values (null, null, DBMS_RANDOM.value(20, 99), rec.id_marki);
    END LOOP;
END GENERUJ_MARKETINGI;