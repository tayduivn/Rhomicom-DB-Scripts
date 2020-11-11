/* Formatted on 12-14-2018 5:56:55 PM (QP5 v5.126.903.23003) */
-- Function: gst.getgnrlrecid(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2)

-- DROP FUNCTION gst.getgnrlrecid(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2);

CREATE OR REPLACE FUNCTION gst.getgnrlrecid (tblnm      VARCHAR2,
                                             srchcol    VARCHAR2,
                                             rtrncol    VARCHAR2,
                                             recname    VARCHAR2)
   RETURN NUMBER
AS
   v_res   NUMBER := -1;
   v_sql   CLOB := '';
BEGIN
   v_sql :=
         'select '
      || rtrnCol
      || ' from '
      || tblNm
      || ' where lower('
      || srchcol
      || ') = '''
      || LOWER (recname)
      || '''';

   EXECUTE IMMEDIATE v_sql INTO   v_res;

   RETURN COALESCE (v_res, -1);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (v_res, -1);
END;