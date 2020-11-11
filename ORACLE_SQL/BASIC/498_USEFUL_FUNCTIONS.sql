/* Formatted on 12-19-2018 11:42:02 AM (QP5 v5.126.903.23003) */
CREATE TYPE sysadmin.rho_dt_type AS TABLE OF VARCHAR2 (500);

CREATE OR REPLACE FUNCTION sysadmin.comma_to_table (p_list IN VARCHAR2)
   RETURN sysadmin.rho_dt_type
AS
   l_string        VARCHAR2 (32767) := p_list || ',';
   l_comma_index   PLS_INTEGER;
   l_index         PLS_INTEGER := 1;
   l_tab           sysadmin.rho_dt_type := sysadmin.rho_dt_type ();
BEGIN
   LOOP
      l_comma_index := INSTR (l_string, ',', l_index);
      EXIT WHEN l_comma_index = 0;
      l_tab.EXTEND;
      l_tab (l_tab.COUNT) :=
         SUBSTR (l_string, l_index, l_comma_index - l_index);
      l_index := l_comma_index + 1;
   END LOOP;

   RETURN l_tab;
END comma_to_table;

SELECT   *
  FROM   TABLE (sysadmin.comma_to_table ('+ac_Abc.88,ac_Abc.99,ac_Abc.77'));





CREATE OR REPLACE FUNCTION sysadmin.dlmtr_to_table (p_list    IN VARCHAR2,
                                                    p_dlmtr      VARCHAR2)
   RETURN sysadmin.rho_dt_type
AS
   l_string        VARCHAR2 (32767) := p_list || p_dlmtr;
   l_comma_index   PLS_INTEGER;
   l_index         PLS_INTEGER := 1;
   l_tab           sysadmin.rho_dt_type := sysadmin.rho_dt_type ();
BEGIN
   LOOP
      l_comma_index := INSTR (l_string, p_dlmtr, l_index);
      EXIT WHEN l_comma_index = 0;
      l_tab.EXTEND;
      l_tab (l_tab.COUNT) :=
         SUBSTR (l_string, l_index, l_comma_index - l_index);
      l_index := l_comma_index + 1;
   END LOOP;

   RETURN l_tab;
END dlmtr_to_table;


SELECT   *
  FROM   TABLE (
            sysadmin.dlmtr_to_table ('+233544709501,123456|0544709501.77','|')
         );