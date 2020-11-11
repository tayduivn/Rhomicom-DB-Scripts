/* Formatted on 21/08/2013 12:50:46 (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_USR_PRSN_ID (P_USRID NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   L_RESULT := -1;

   SELECT   PERSON_ID
     INTO   L_RESULT
     FROM   SEC.SEC_USERS
    WHERE   USER_ID = P_USRID;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/