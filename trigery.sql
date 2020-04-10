create or replace TRIGGER ID_KONSUMENTA_AUTOINC 
BEFORE INSERT ON KONSUMENCI
FOR EACH ROW
BEGIN
    SELECT ID_KONSUMENTA_SEQ.NEXTVAL
    INTO :NEW.ID_KONSUMENTA
    FROM DUAL;
END;


CREATE OR REPLACE TRIGGER ID_PRODUCENTA_AUTOINC
--wyzwalacz odpowiedzielny za przydzial producentowi unikatowego identyfikatora oraz funduszy o wielkosci okreslonej w ustawieniach poczatkowych
BEFORE INSERT ON PRODUCENCI 
FOR EACH ROW
BEGIN
    SELECT ID_PRODUCENTA_SEQ.NEXTVAL
    INTO :NEW.ID_PRODUCENTA
    FROM DUAL;
   
    select poczatkowe_fundusze into :NEW.fundusze from ustawienia_poczatkowe where numer_opcji = 1;
END;
