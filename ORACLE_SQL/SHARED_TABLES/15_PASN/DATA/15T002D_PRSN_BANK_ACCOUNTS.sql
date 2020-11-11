
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PASN.PRSN_BANK_ACCOUNTS --data-only --column-inserts psdc_live > PASN.PRSN_BANK_ACCOUNTS.sql
*/
set define off;
TRUNCATE TABLE PASN.PRSN_BANK_ACCOUNTS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'PRSN_BANK_ACCOUNTS_SEQ', 2 );
COMMIT;
