
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PRS.HR_ACCRUAL_PLANS --data-only --column-inserts psdc_live > PRS.HR_ACCRUAL_PLANS.sql
*/
set define off;
TRUNCATE TABLE PRS.HR_ACCRUAL_PLANS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PRS', 'HR_ACCRUAL_PLANS_SEQ', 2 );
COMMIT;

