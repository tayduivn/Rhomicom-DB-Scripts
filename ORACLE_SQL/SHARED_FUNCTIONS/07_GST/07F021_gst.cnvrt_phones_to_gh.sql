/* Formatted on 12-13-2018 11:57:32 AM (QP5 v5.126.903.23003) */
-- Function: gst.cnvrt_phones_to_gh(varchar2)

-- DROP FUNCTION gst.cnvrt_phones_to_gh(varchar2);
GRANT ALL ON sysadmin.comma_to_table TO GST;

CREATE OR REPLACE FUNCTION gst.cnvrt_phones_to_gh (p_phone_nos VARCHAR2)
   RETURN VARCHAR2
AS
   TYPE clobsarray IS VARRAY (5) OF CLOB;

   l_count          NUMBER := 0;
   v_dlmtrs         VARCHAR2 (1) := ',';
   daMobileNos      VARCHAR2 (500) := '';
   anodaMobileNos   VARCHAR2 (500) := '';
   tmpMobileNo      VARCHAR2 (100) := '';
   v_Msgs           CLOB := '';
BEGIN
   daMobileNos :=
      REPLACE (
         REPLACE (REPLACE (REPLACE (p_phone_nos, ' ', ','), ', ', ','),
                  ':',
                  ','),
         ';',
         ','
      );

   SELECT   COUNT (1)
     INTO   l_count
     FROM   TABLE (sysadmin.comma_to_table (daMobileNos));

   /*DBMS_UTILITY.comma_to_table (list     => daMobileNos,
                                tablen   => l_count,
                                tab      => tmpMobileNos);*/
   --tmpMobileNos := CAST(string_to_array(daMobileNos, v_dlmtrs)  AS  CLOB) [];
   anodaMobileNos := '';

   FOR j
   IN (SELECT   COLUMN_VALUE FROM TABLE (sysadmin.comma_to_table (daMobileNos)))
   LOOP
      tmpMobileNo := j.COLUMN_VALUE;

      --DBMS_OUTPUT.PUT_LINE (tmpMobileNo);
      --DBMS_OUTPUT.PUT_LINE (SUBSTR (tmpMobileNo, 1, 1));

      IF SUBSTR (tmpMobileNo, 1, 1) = '0'
      THEN
         tmpMobileNo := '+233' || SUBSTR (tmpMobileNo, 2);
      END IF;

      IF gst.isMobileNumValid (tmpMobileNo) > 0
      THEN
         anodaMobileNos := anodaMobileNos || tmpMobileNo || ', ';
      END IF;
   END LOOP;

   IF (LENGTH (anodaMobileNos) > 0)
   THEN
      daMobileNos := TRIM (BOTH ',' FROM TRIM (BOTH ' ' FROM anodaMobileNos));
   END IF;

   RETURN daMobileNos;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE (
         'ERROR ' || v_Msgs || SQLCODE || CHR (10) || SQLERRM
      );
      RETURN '';
END;


SELECT   gst.ismobilenumvalid ('+233544709501') FROM DUAL;

SELECT   gst.cnvrt_phones_to_gh ('0544709501,') FROM DUAL;

SELECT   gst.cnvrt_phones_to_gh ('0544709501,0203856645') FROM DUAL;