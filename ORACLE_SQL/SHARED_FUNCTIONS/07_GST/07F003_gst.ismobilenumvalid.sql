/* Formatted on 12-13-2018 11:57:25 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION gst.ismobilenumvalid (p_phone_no VARCHAR2)
   RETURN NUMBER
AS
   bid   NUMBER (10) := 0;
BEGIN
   SELECT   COUNT (1)
     INTO   bid
     FROM   DUAL
    WHERE   REGEXP_LIKE (p_phone_no, '^\+(\d+\s?)+$');

   RETURN COALESCE (bid, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (bid, 0);
END;
