
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_PAY_ITEMS --data-only --column-inserts psdc_live > ORG.ORG_PAY_ITEMS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_PAY_ITEMS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_PAY_ITEMS_SEQ', 2 );
COMMIT;
