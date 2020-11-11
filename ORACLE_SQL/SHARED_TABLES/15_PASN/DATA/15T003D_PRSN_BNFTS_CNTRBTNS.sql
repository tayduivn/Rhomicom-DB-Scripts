
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PASN.PRSN_BNFTS_CNTRBTNS --data-only --column-inserts psdc_live > PASN.PRSN_BNFTS_CNTRBTNS.sql
*/
set define off;
TRUNCATE TABLE PASN.PRSN_BNFTS_CNTRBTNS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'PRSN_BNFTS_CNTRBTNS_SEQ', 2 );
COMMIT;
