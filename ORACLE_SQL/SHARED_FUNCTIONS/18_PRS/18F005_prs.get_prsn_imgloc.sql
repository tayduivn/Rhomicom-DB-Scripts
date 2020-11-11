/* Formatted on 12-19-2018 5:33:25 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PRS.GET_PRSN_IMGLOC (P_PRSNID NUMBER)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   L_RESULT := '';

   SELECT   IMG_LOCATION
     INTO   L_RESULT
     FROM   PRS.PRSN_NAMES_NOS
    WHERE   PERSON_ID = P_PRSNID;

   RETURN COALESCE (L_RESULT, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/