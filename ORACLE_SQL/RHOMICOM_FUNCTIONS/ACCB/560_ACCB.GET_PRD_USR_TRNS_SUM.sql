/* Formatted on 10/3/2014 3:35:33 PM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.GET_PRD_USR_TRNS_SUM(INTEGER, CHARACTER VARYING, CHARACTER VARYING)

-- DROP FUNCTION APLAPPS.GET_PRD_USR_TRNS_SUM(INTEGER, CHARACTER VARYING, CHARACTER VARYING);

CREATE OR REPLACE FUNCTION APLAPPS.GET_PRD_USR_TRNS_SUM (
   P_ACCNTID    NUMBER,
   P_STRTDTE    VARCHAR2,
   P_ENDDTE     VARCHAR2
)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0.00;
BEGIN
   SELECT   SUM (A.NET_AMOUNT)
     INTO   L_RESULT
     FROM   ACCB.ACCB_TRNSCTN_DETAILS A
    WHERE   A.TRNS_STATUS = '1'
            AND TO_TIMESTAMP (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') <=
                  TO_TIMESTAMP (P_STRTDTE, 'YYYY-MM-DD HH24:MI:SS')
            AND TO_TIMESTAMP (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') >=
                  TO_TIMESTAMP (P_ENDDTE, 'YYYY-MM-DD HH24:MI:SS')
            AND A.ACCNT_ID = P_ACCNTID
            AND A.TRANSCTN_ID NOT IN
                     (SELECT   B.TRANSCTN_ID
                        FROM   ACCB.ACCB_TRNSCTN_DETAILS B
                       WHERE   B.BATCH_ID IN
                                     (SELECT   C.BATCH_ID
                                        FROM   ACCB.ACCB_TRNSCTN_BATCHES C
                                       WHERE   C.BATCH_NAME LIKE
                                                  'Period Close Process%'
                                               AND C.BATCH_SOURCE =
                                                     'Period Close Process'));
   RETURN L_RESULT;
END;