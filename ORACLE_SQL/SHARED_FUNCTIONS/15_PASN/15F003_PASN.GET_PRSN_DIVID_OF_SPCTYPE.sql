/* Formatted on 12-20-2018 8:24:41 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_DIVID_OF_SPCTYPE (
   P_PRSNID     NUMBER,
   P_DIVTYPE    VARCHAR2
)
   RETURN NUMBER
AS
   L_RESULT    NUMBER;
   L_PRSNID    NUMBER;
   L_DIVTYPE   VARCHAR2 (200);
BEGIN
   L_RESULT := -1;
   L_PRSNID := P_PRSNID;
   L_DIVTYPE := P_DIVTYPE;

   SELECT   TBL1.DIV_ID
     INTO   L_RESULT
     FROM   (  SELECT   A.DIV_ID
                 FROM   PASN.PRSN_DIVS_GROUPS A
                WHERE   A.PERSON_ID = L_PRSNID
                        AND UPPER (ORG.GET_DIV_TYPE (A.DIV_ID)) =
                              UPPER (L_DIVTYPE)
                        AND (SYSDATE BETWEEN TO_DATE (A.VALID_START_DATE,
                                                      'YYYY-MM-DD 00:00:00')
                                         AND  TO_DATE (A.VALID_END_DATE,
                                                       'YYYY-MM-DD 23:59:59'))
             ORDER BY   A.PRSN_DIV_ID DESC) TBL1
    WHERE   ROWNUM = 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/