/* Formatted on 12-20-2018 8:30:05 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION pasn.GET_PRSN_GRDID (P_PERSONID NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   L_RESULT := -1;

   SELECT   TBL1.GRADE_ID
     INTO   L_RESULT
     FROM   (  SELECT   A.GRADE_ID
                 FROM   PASN.PRSN_GRADES A
                WHERE   ( (A.PERSON_ID = P_PERSONID)
                         AND (SYSDATE BETWEEN TO_DATE (A.VALID_START_DATE,
                                                       'YYYY-MM-DD 00:00:00')
                                          AND  TO_DATE (A.VALID_END_DATE,
                                                        'YYYY-MM-DD 23:59:59')))
             ORDER BY   TO_DATE (A.VALID_START_DATE, 'YYYY-MM-DD 00:00:00') DESC)
            TBL1
    WHERE   ROWNUM = 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/


--SELECT   APLAPPS.GET_PRSN_GRDID (1) FROM DUAL;