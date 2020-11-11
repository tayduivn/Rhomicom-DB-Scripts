/* Formatted on 12-14-2018 6:07:41 PM (QP5 v5.126.903.23003) */
-- Function: gst.getlogmsg(NUMBER, VARCHAR2)

-- DROP FUNCTION gst.getlogmsg(NUMBER, VARCHAR2);

CREATE OR REPLACE FUNCTION gst.getlogmsg (p_msgid       NUMBER,
                                          p_logtblnm    VARCHAR2)
   RETURN CLOB
AS
   v_result   CLOB := '';
   v_sql      CLOB := '';
BEGIN
   v_sql :=
         'select  ''"''|| REPLACE(log_messages, '''', ''[]'')||''"'' from '
      || p_logTblNm
      || ' where msg_id = '
      || p_msgid;

   EXECUTE IMMEDIATE v_sql INTO   v_result;

   RETURN COALESCE (v_result, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;