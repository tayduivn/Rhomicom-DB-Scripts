/* Formatted on 12-13-2018 12:44:04 PM (QP5 v5.126.903.23003) */
-- Function: gst.getlogmsgid(VARCHAR2, VARCHAR2, NUMBER)

-- DROP FUNCTION gst.getlogmsgid(VARCHAR2, VARCHAR2, NUMBER);

CREATE OR REPLACE FUNCTION gst.getlogmsgid (p_logtblnm    VARCHAR2,
                                            p_procstyp    VARCHAR2,
                                            p_procsid     NUMBER)
   RETURN NUMBER
AS
   v_result   NUMBER := -1;
   v_sql      CLOB := '';
BEGIN
   v_sql :=
         'select msg_id from '
      || p_logTblNm
      || ' where process_typ = '''
      || p_procstyp
      || ''' and process_id = '
      || p_procsID;

   EXECUTE IMMEDIATE v_sql INTO   v_result;

   RETURN COALESCE (v_result, -1);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;