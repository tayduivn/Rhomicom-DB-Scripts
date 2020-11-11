/* Formatted on 12-14-2018 6:04:16 PM (QP5 v5.126.903.23003) */
-- Function: gst.getgnrlrecnm1(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2)

-- DROP FUNCTION gst.getgnrlrecnm1(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2);

CREATE OR REPLACE FUNCTION gst.getgnrlrecnm1 (tblnm       VARCHAR2,
                                              srchcol     VARCHAR2,
                                              rtrncol     VARCHAR2,
                                              srchword    VARCHAR2)
   RETURN VARCHAR2
AS
   v_res   VARCHAR2 (500) := '';
   v_sql   CLOB := '';
BEGIN
   v_sql :=
         'SELECT '
      || rtrnCol
      || ' from '
      || tblNm
      || ' where lower('
      || srchcol
      || ') = lower('''
      || srchword
      || ''')';

   EXECUTE IMMEDIATE v_sql INTO   v_res;

   RETURN COALESCE (v_res, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (v_res, '');
END;