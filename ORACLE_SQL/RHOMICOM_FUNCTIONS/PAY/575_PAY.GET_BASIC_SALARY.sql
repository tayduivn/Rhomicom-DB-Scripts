/* Formatted on 10/6/2014 2:27:43 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_BASIC_SALARY (P_PERSONID NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER (20, 2);
BEGIN
   L_RESULT := 0;

   SELECT   (TO_NUMBER(APLAPPS.GET_PSSBL_VAL(APLAPPS.GET_DIV_NAME(APLAPPS.GET_PRSN_DIVID_OF_SPCTYPE (
                                                                     P_PERSONID,
                                                                     'Pay/Remuneration'
                                                                  ))))
             / 12)
     INTO   L_RESULT
     FROM   DUAL;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/