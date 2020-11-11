
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PRS.HR_ACCRUAL_PLAN_EXCTNS --data-only --column-inserts psdc_live > PRS.HR_ACCRUAL_PLAN_EXCTNS.sql
*/
set define off;
TRUNCATE TABLE PRS.HR_ACCRUAL_PLAN_EXCTNS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PRS', 'HR_ACCRUAL_PLAN_EXCTNS_SEQ', 2 );
COMMIT;