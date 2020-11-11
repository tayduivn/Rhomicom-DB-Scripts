/* Formatted on 12-20-2018 8:53:14 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_TYPE_DATE (P_PERSONID    NUMBER,
                                                    P_PRSNTYP     VARCHAR2)
   RETURN VARCHAR2
AS
   BID   VARCHAR2 (200) := '';
BEGIN
   SELECT   TBL1.TDATE
     INTO   BID
     FROM   (  SELECT   (CASE
                            WHEN LENGTH (COALESCE (A.VALID_START_DATE, '')) = 0
                            THEN
                               ''
                            ELSE
                               TO_CHAR (
                                  TO_TIMESTAMP (A.VALID_START_DATE,
                                                'YYYY-MM-DD'),
                                  'DD-Mon-YYYY'
                               )
                         END)
                           TDATE
                 FROM   PASN.PRSN_PRSNTYPS A
                WHERE   ( (A.PERSON_ID = P_PERSONID
                           AND UPPER (A.PRSN_TYPE) = UPPER (P_PRSNTYP))
                         AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                                 A.VALID_START_DATE,
                                                 'YYYY-MM-DD 00:00:00'
                                              )
                                          AND  TO_TIMESTAMP (
                                                  A.VALID_END_DATE,
                                                  'YYYY-MM-DD 23:59:59'
                                               )))
             ORDER BY   A.VALID_START_DATE ASC) TBL1
    WHERE   ROWNUM <= 1;

   RETURN COALESCE (BID, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (BID, '');
END;