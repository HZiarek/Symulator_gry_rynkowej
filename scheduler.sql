BEGIN
  DBMS_SCHEDULER.DROP_JOB(JOB_NAME => 'ROZPOCZNIJ_NOWA_RUNDE');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    JOB_NAME        => 'ROZPOCZNIJ_NOWA_RUNDE',
    JOB_TYPE        => 'STORED_PROCEDURE',
    JOB_ACTION      => 'hziarek.job_test',
    START_DATE      => SYSTIMESTAMP + interval '5' second,
    REPEAT_INTERVAL => 'FREQ=MINUTELY;INTERVAL=1;',
    ENABLED         => TRUE,
    auto_drop       => TRUE,
    --max_runs        => '1',
    COMMENTS        => 'Job rozpoczyna nowa runde');
END;
/

BEGIN
DBMS_SCHEDULER.SET_ATTRIBUTE (
   'ROZPOCZNIJ_NOWA_RUNDE',
   'max_runs',
   1);
END;

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
    JOB_NAME        => 'SPR_CZY_SPASOWALI_I_ROZPOCZNIJ_RUNDE',
    JOB_TYPE        => 'STORED_PROCEDURE',
    JOB_ACTION      => 'hziarek.job_test',
    REPEAT_INTERVAL => 'FREQ=DAILY',
    START_DATE      => systimestamp + interval '20' second,
    max_runs        => 1,
    auto_drop       => TRUE,
    ENABLED         => TRUE,
    COMMENTS        => 'Job rozpoczyna nowa runde');
END;
/

SELECT JOB_NAME FROM DBA_SCHEDULER_JOBS;