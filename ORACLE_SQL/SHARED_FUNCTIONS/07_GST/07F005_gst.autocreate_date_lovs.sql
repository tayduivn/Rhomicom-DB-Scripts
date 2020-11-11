/* Formatted on 12-13-2018 12:11:15 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION gst.autocreate_date_lovs
   RETURN NUMBER
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   ln_result       NUMBER;
   ln_lov_id       NUMBER;
   ln_lov_val_id   NUMBER;
BEGIN
   ln_result := 0;
   ln_lov_id := COALESCE (gst.get_lov_id ('List of Dates'), -1);

   IF ln_lov_id <= 0
   THEN
      INSERT INTO gst.gen_stp_lov_names (value_list_name,
                                         value_list_desc,
                                         sqlquery_if_dyn,
                                         defined_by,
                                         created_by,
                                         creation_date,
                                         last_update_by,
                                         last_update_date,
                                         is_list_dynamic,
                                         is_enabled)
        VALUES   ('List of Dates',
                  'List of Dates',
                  '',
                  'SYS',
                  1,
                  TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                  1,
                  TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                  '0',
                  '1');

      ln_lov_id := COALESCE (gst.get_lov_id ('List of Dates'), -1);
   END IF;

   FOR i IN 1 .. 1000
   LOOP
      ln_lov_val_id :=
         COALESCE (
            gst.get_pssbl_val_id (
               TO_CHAR (SYSDATE - i, 'YYYY-MM-DD') || ' 00:00:00',
               ln_lov_id
            ),
            -1
         );

      IF ln_lov_val_id <= 0
      THEN
         INSERT INTO gst.gen_stp_lov_values (value_list_id,
                                             pssbl_value,
                                             pssbl_value_desc,
                                             created_by,
                                             creation_date,
                                             last_update_by,
                                             last_update_date,
                                             is_enabled,
                                             allowed_org_ids)
           VALUES   (ln_lov_id,
                     TO_CHAR (SYSDATE - i, 'YYYY-MM-DD') || ' 00:00:00',
                     TO_CHAR (SYSDATE - i, 'YYYY-MM-DD') || ' 00:00:00',
                     1,
                     TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                     1,
                     TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                     '1',
                     ',1,');
      END IF;

      ln_lov_val_id :=
         COALESCE (
            gst.get_pssbl_val_id (
               TO_CHAR (SYSDATE + i, 'YYYY-MM-DD') || ' 00:00:00',
               ln_lov_id
            ),
            -1
         );

      IF ln_lov_val_id <= 0
      THEN
         INSERT INTO gst.gen_stp_lov_values (value_list_id,
                                             pssbl_value,
                                             pssbl_value_desc,
                                             created_by,
                                             creation_date,
                                             last_update_by,
                                             last_update_date,
                                             is_enabled,
                                             allowed_org_ids)
           VALUES   (ln_lov_id,
                     TO_CHAR (SYSDATE + i, 'YYYY-MM-DD') || ' 00:00:00',
                     TO_CHAR (SYSDATE + i, 'YYYY-MM-DD') || ' 00:00:00',
                     1,
                     TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                     1,
                     TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS'),
                     '1',
                     ',1,');
      END IF;
   END LOOP;

   COMMIT;
   RETURN ln_result;
END;

SELECT   gst.autocreate_date_lovs () FROM DUAL;

SELECT   TO_CHAR (SYSDATE - 1, 'YYYY-MM-DD') || ' 00:00:00' FROM DUAL;


select trim(TO_CHAR (27)) from dual;