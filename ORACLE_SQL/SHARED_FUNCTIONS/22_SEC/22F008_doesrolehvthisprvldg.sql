/* Formatted on 12-19-2018 12:18:29 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SEC.DOESROLEHVTHISPRVLDG (
   P_INP_PRVLDG_ID    INTEGER,
   P_INP_ROLE_ID      INTEGER
)
   RETURN INTEGER
AS
   L_RESULT   INTEGER := 0;
BEGIN
   SELECT   COUNT (ROLE_ID)
     INTO   L_RESULT
     FROM   SEC.SEC_ROLES_N_PRVLDGS
    WHERE   ( (PRVLDG_ID = P_INP_PRVLDG_ID) AND (ROLE_ID = P_INP_ROLE_ID)
             AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                     VALID_START_DATE || ' 00:00:00',
                                     'YYYY-MM-DD HH24:MI:SS'
                                  )
                              AND  TO_TIMESTAMP (
                                      VALID_END_DATE || ' 23:59:59',
                                      'YYYY-MM-DD HH24:MI:SS'
                                   )));

   RETURN COALESCE (L_RESULT, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/