/* Formatted on 12-19-2018 5:35:17 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PRS.GET_PRSN_NAME (P_PRSNID NUMBER)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   L_RESULT := '';

   SELECT   TRIM(   TITLE
                 || ' '
                 || FIRST_NAME
                 || ' '
                 || OTHER_NAMES
                 || ' '
                 || SUR_NAME)
     INTO   L_RESULT
     FROM   PRS.PRSN_NAMES_NOS
    WHERE   PERSON_ID = P_PRSNID;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/