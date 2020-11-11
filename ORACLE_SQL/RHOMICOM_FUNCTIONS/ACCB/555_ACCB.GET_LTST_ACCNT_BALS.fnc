/* Formatted on 10/3/2014 3:15:46 PM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.GET_LTST_ACCNT_BALS(INTEGER, VARCHAR2, VARCHAR2)

-- DROP FUNCTION APLAPPS.GET_LTST_ACCNT_BALS(INTEGER, VARCHAR2, VARCHAR2);

CREATE OR REPLACE FUNCTION APLAPPS.GET_LTST_ACCNT_BALS (P_ACCNTID    NUMBER,
                                                     P_BALSDTE    VARCHAR2,
                                                     P_TYP        VARCHAR2)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0.00;
BEGIN
   IF P_TYP = 'dbt_amount'
   THEN
      SELECT   TBL1.DBT_BAL
        INTO   L_RESULT
        FROM   (  SELECT   A.DBT_BAL
                    FROM   ACCB.ACCB_ACCNT_DAILY_BALS A
                   WHERE   A.ACCNT_ID = P_ACCNTID
                           AND TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') <=
                                 TO_DATE (P_BALSDTE, 'YYYY-MM-DD')
                ORDER BY   TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') DESC) TBL1
       WHERE   ROWNUM = 1;
   ELSIF P_TYP = 'crdt_amount'
   THEN
      SELECT   TBL1.CRDT_BAL
        INTO   L_RESULT
        FROM   (  SELECT   A.CRDT_BAL
                    FROM   ACCB.ACCB_ACCNT_DAILY_BALS A
                   WHERE   A.ACCNT_ID = P_ACCNTID
                           AND TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') <=
                                 TO_DATE (P_BALSDTE, 'YYYY-MM-DD')
                ORDER BY   TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') DESC) TBL1
       WHERE   ROWNUM = 1;
   ELSE
      SELECT   TBL1.NET_BALANCE
        INTO   L_RESULT
        FROM   (  SELECT   A.NET_BALANCE
                    FROM   ACCB.ACCB_ACCNT_DAILY_BALS A
                   WHERE   A.ACCNT_ID = P_ACCNTID
                           AND TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') <=
                                 TO_DATE (P_BALSDTE, 'YYYY-MM-DD')
                ORDER BY   TO_DATE (A.AS_AT_DATE, 'YYYY-MM-DD') DESC) TBL1
       WHERE   ROWNUM = 1;
   END IF;

   RETURN NVL (L_RESULT, 0);
END;