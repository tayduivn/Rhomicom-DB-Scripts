/* Formatted on 10/6/2014 2:02:14 PM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.PRNT_USR_TRNS_SUM_RCSV(INTEGER, CHARACTER VARYING, CHARACTER VARYING)

-- DROP FUNCTION APLAPPS.PRNT_USR_TRNS_SUM_RCSV(INTEGER, CHARACTER VARYING, CHARACTER VARYING);

CREATE OR REPLACE FUNCTION APLAPPS.PRNT_USR_TRNS_SUM_RCSV (
   P_PRNT_ACCNTID    NUMBER,
   P_STRTDTE         VARCHAR2,
   P_ENDDTE          VARCHAR2
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
                           APLAPPS.GET_PRD_USR_TRNS_SUM (E.ACCNT_ID,
                                                         P_STRTDTE,
                                                         P_ENDDTE)
                              NETBAL
                    FROM   ACCB.ACCB_CHART_OF_ACCNTS E
              START WITH   E.PRNT_ACCNT_ID = P_PRNT_ACCNTID
              CONNECT BY   E.ACCNT_ID = PRIOR E.PRNT_ACCNT_ID)
   SELECT   SUM (NETBAL)
     INTO   L_RESULT
     FROM   SUBACCNT
    WHERE   ACCNT_NUM LIKE '%';

   RETURN L_RESULT;
END;