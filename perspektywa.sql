--------------------------------------------------------
--  File created - wtorek-maja-19-2020   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Materialized View SPRZEDAZ
--------------------------------------------------------

  CREATE MATERIALIZED VIEW "INZYNIERKA"."SPRZEDAZ" ("NUMER_RUNDY", "NAZWA_MARKI", "NAZWA_PRODUCENTA", "SUMA", "PRZYCHOD")
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "SYSTEM" 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH COMPLETE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE
  AS SELECT 
    z.numer_rundy, m.nazwa_marki, p.nazwa_producenta, z.suma, z.suma*m.cena_za_sztuke as przychod
FROM
    (select numer_rundy, id_marki, sum(id_marki) as suma
    from zakupy_konsumenta
    group by numer_rundy, id_marki) z,
    
    marki m, producenci p
WHERE z.id_marki = m.id_marki and p.id_producenta = m.id_producenta;

   COMMENT ON MATERIALIZED VIEW "INZYNIERKA"."SPRZEDAZ"  IS 'snapshot table for snapshot INZYNIERKA.SPRZEDAZ';
