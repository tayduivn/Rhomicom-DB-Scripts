/* Formatted on 18/09/2014 08:56:29 (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_GHIE_ANL_DUES (P_PERSONID NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   L_RESULT := -1;

   SELECT   TO_NUMBER(APLAPPS.GET_PSSBL_VAL2 (
                         APLAPPS.GET_GRADE_NAME (
                            APLAPPS.GET_PRSN_GRDID (P_PERSONID)
                         ),
                         APLAPPS.GET_LOV_ID ('Ghie Class & Annual Dues Amounts')
                      ))
     INTO   L_RESULT
     FROM   DUAL;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/