/* Formatted on 12-20-2018 8:15:49 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_DIVID (P_PERSONID NUMBER)
   RETURN INTEGER
AS
   L_RESULT   INTEGER := -1;
BEGIN
   SELECT   TBL1.DIV_ID
     INTO   L_RESULT
     FROM   (  SELECT   A.DIV_ID
                 FROM   PASN.PRSN_DIVS_GROUPS A
                WHERE   ( (A.PERSON_ID = P_PERSONID)
                         AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                                 A.VALID_START_DATE,
                                                 'YYYY-MM-DD 00:00:00'
                                              )
                                          AND  TO_TIMESTAMP (
                                                  A.VALID_END_DATE,
                                                  'YYYY-MM-DD 23:59:59'
                                               )))
             ORDER BY   A.PRSN_DIV_ID DESC) TBL1
    WHERE   ROWNUM <= 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RETURN -1;
END;
/
select PASN.GET_PRSN_DIVID (1) from dual;