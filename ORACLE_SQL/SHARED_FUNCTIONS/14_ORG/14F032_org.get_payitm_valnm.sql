/* Formatted on 18/09/2014 09:05:15 (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_ORGFUNC_CRNCY_ID (P_ORGIDNO NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   L_RESULT := -1;

   SELECT   OPRTNL_CRNCY_ID
     INTO   L_RESULT
     FROM   ORG.ORG_DETAILS
    WHERE   ORG_ID = P_ORGIDNO;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/