/* Formatted on 12-19-2018 4:54:45 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PUBLC.CHARTONUMERIC (P_CHARPARAM VARCHAR2)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0;
BEGIN
   SELECT   CASE
               WHEN REGEXP_LIKE (TRIM (P_CHARPARAM),
                                 '[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?')
               THEN
                  CAST (TRIM (P_CHARPARAM) AS NUMBER)
               ELSE
                  0
            END
     INTO   L_RESULT
     FROM   DUAL;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RETURN 0;
END;

SELECT   PUBLC.CHARTONUMERIC ('679.8') FROM DUAL;