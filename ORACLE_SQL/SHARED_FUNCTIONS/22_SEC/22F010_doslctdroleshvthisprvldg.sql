/* Formatted on 12-19-2018 12:40:50 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SEC.DOSLCTDROLESHVTHISPRVLDG (
   P_INP_PRVLDG_ID    INTEGER,
   P_SSNROLES         VARCHAR2
)
   RETURN INTEGER
AS
   BID          INTEGER := 0;
   V_SSNROLES   VARCHAR2 (400);
   V_MSGS       CLOB := '';
BEGIN
   V_MSGS :=
         V_MSGS
      || 'IN ROLES..'
      || P_INP_PRVLDG_ID
      || '::'
      || P_SSNROLES
      || CHR (10);
   V_SSNROLES := ';' || P_SSNROLES || ';';

   --RAISE NOTICE 'ERROR %', V_MSGS;
   SELECT   COUNT (ROLE_ID)
     INTO   BID
     FROM   SEC.SEC_ROLES_N_PRVLDGS
    WHERE   ( (PRVLDG_ID = P_INP_PRVLDG_ID)
             AND (UPPER (TRIM (V_SSNROLES)) LIKE
                     UPPER (TRIM ('%;' || ROLE_ID || ';%')))
             AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                     VALID_START_DATE || ' 00:00:00',
                                     'YYYY-MM-DD HH24:MI:SS'
                                  )
                              AND  TO_TIMESTAMP (
                                      VALID_END_DATE || ' 23:59:59',
                                      'YYYY-MM-DD HH24:MI:SS'
                                   )));

   RETURN COALESCE (BID, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE (
         'ERROR ' || V_MSGS || SQLCODE || CHR (10) || SQLERRM
      );
      RETURN 0;
END;
/