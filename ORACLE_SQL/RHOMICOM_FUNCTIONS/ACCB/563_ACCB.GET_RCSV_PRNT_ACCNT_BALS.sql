/* Formatted on 10/6/2014 2:30:53 PM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.GET_RCSV_PRNT_ACCNT_BALS(INTEGER, CHARACTER VARYING)

-- DROP FUNCTION APLAPPS.GET_RCSV_PRNT_ACCNT_BALS(INTEGER, CHARACTER VARYING);

CREATE OR REPLACE FUNCTION APLAPPS.GET_RCSV_PRNT_ACCNT_BALS (
   P_ACCNTID    NUMBER,
   P_BALSDTE    VARCHAR2
)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0.00;
BEGIN
   WITH SUBACCNT
          AS (    SELECT   E.ACCNT_ID,
                           E.PRNT_ACCNT_ID,
                           E.ACCNT_NUM,
                           E.ACCNT_NAME,
                           APLAPPS.GET_LTST_ACCNT_BALS1 (E.ACCNT_ID, P_BALSDTE)
                              NETBAL
                    FROM   ACCB.ACCB_CHART_OF_ACCNTS E
              START WITH   E.PRNT_ACCNT_ID = P_ACCNTID
              CONNECT BY   E.ACCNT_ID = PRIOR E.PRNT_ACCNT_ID)
   SELECT   SUM (NETBAL)
     INTO   L_RESULT
     FROM   SUBACCNT
    WHERE   ACCNT_NUM LIKE '%';


   RETURN L_RESULT;
END;