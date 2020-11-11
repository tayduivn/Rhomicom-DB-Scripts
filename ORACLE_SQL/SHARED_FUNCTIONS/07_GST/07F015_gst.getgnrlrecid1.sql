/* Formatted on 12-14-2018 6:01:31 PM (QP5 v5.126.903.23003) */
-- Function: gst.getgnrlrecid1(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2, integer)

-- DROP FUNCTION gst.getgnrlrecid1(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2, integer);

CREATE OR REPLACE FUNCTION gst.getgnrlrecid1 (tblnm       VARCHAR2,
                                              srchcol     VARCHAR2,
                                              rtrncol     VARCHAR2,
                                              recname     VARCHAR2,
                                              p_org_id    INTEGER)
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
      || ''' and org_id='
      || p_org_id;

   EXECUTE IMMEDIATE v_sql INTO   v_res;

   RETURN COALESCE (v_res, -1);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (v_res, -1);
END;