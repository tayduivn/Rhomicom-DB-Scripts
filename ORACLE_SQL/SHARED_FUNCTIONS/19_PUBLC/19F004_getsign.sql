/* Formatted on 12-19-2018 4:56:35 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PUBLC.GETSIGN (P_INPTAMNT NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   IF (P_INPTAMNT != 0)
   THEN
      RETURN P_INPTAMNT / ABS (P_INPTAMNT);
   END IF;

   RETURN 0;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/