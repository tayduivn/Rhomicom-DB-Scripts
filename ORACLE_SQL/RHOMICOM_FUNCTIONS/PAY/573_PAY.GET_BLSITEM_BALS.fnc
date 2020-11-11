/* Formatted on 10/6/2014 2:25:49 AM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.GET_BLSITEM_BALS(BIGINT, BIGINT, CHARACTER VARYING)

-- DROP FUNCTION APLAPPS.GET_BLSITEM_BALS(BIGINT, BIGINT, CHARACTER VARYING);

CREATE OR REPLACE FUNCTION APLAPPS.GET_BLSITEM_BALS (
   P_PERSONID       NUMBER,
   P_BALS_ITM_ID    NUMBER,
   BALS_DATE        VARCHAR2
)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0;
BEGIN
   SELECT   A.BALS_AMOUNT
     INTO   L_RESULT
     FROM   PAY.PAY_BALSITM_BALS A
    WHERE       A.PERSON_ID = P_PERSONID
            AND A.BALS_ITM_ID = P_BALS_ITM_ID
            AND A.BALS_DATE = BALS_DATE;

   RETURN L_RESULT;
END;