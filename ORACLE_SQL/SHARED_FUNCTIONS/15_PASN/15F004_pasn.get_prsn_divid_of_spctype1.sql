/* Formatted on 12-20-2018 8:28:48 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_DIVID_OF_SPCTYPE1 (
   P_PRSNID      NUMBER,
   P_DIVTYPE     VARCHAR2,
   P_TRNSDTE1    VARCHAR2,
   P_TRNSDTE2    VARCHAR2
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
                        AND (TO_TIMESTAMP (A.VALID_START_DATE || ' 00:00:00',
                                           'YYYY-MM-DD HH24:MI:SS') <=
                                TO_TIMESTAMP (P_TRNSDTE2,
                                              'DD-Mon-YYYY HH24:MI:SS')
                             AND TO_TIMESTAMP (A.VALID_END_DATE || ' 23:59:59',
                                               'YYYY-MM-DD H24:MI:SS') >=
                                   TO_TIMESTAMP (P_TRNSDTE1,
                                                 'DD-Mon-YYYY HH24:MI:SS'))
             ORDER BY   A.PRSN_DIV_ID DESC) TBL1
    WHERE   ROWNUM = 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/