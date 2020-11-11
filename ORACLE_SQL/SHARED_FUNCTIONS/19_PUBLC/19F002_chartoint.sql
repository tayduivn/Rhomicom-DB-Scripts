/* Formatted on 12-19-2018 4:48:52 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION publc.chartoint (p_charparam VARCHAR2)
   RETURN INTEGER
AS
   L_RESULT   INTEGER := 0;
BEGIN
   SELECT   CASE
               WHEN REGEXP_LIKE (TRIM (p_charparam), '[0-9]+')
               THEN
                  CAST (TRIM (p_charparam) AS integer)
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

SELECT   publc.chartoint ('679') FROM DUAL;