/* Formatted on 12-14-2018 6:03:04 PM (QP5 v5.126.903.23003) */
-- Function: gst.getgnrlrecnm(VARCHAR2, VARCHAR2, VARCHAR2, NUMBER)

-- DROP FUNCTION gst.getgnrlrecnm(VARCHAR2, VARCHAR2, VARCHAR2, NUMBER);

CREATE OR REPLACE FUNCTION gst.getgnrlrecnm (tblnm      VARCHAR2,
                                             srchcol    VARCHAR2,
                                             rtrncol    VARCHAR2,
                                             recid      NUMBER)
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
      || ' where '
      || srchcol
      || ' = '
      || recid;

   EXECUTE IMMEDIATE v_sql INTO   v_res;

   RETURN COALESCE (v_res, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (v_res, '');
END;