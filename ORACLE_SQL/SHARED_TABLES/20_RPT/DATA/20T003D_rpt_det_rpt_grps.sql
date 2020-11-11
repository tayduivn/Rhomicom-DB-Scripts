/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_DET_RPT_GRPS --data-only --column-inserts psdc_live > RPT.RPT_DET_RPT_GRPS.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_DET_RPT_GRPS CASCADE;



INSERT INTO rpt.rpt_det_rpt_grps (group_id, title, col_nos, grp_width_desc, nof_cols_wthn, grp_order, report_id, grp_dsply_type, grp_min_height_px, column_hdr_names, delimiter_col_vals, delimiter_row_vals, created_by, creation_date, last_update_by, last_update_date, grp_border, label_max_width) VALUES (4, 'Image', '15', 'Half Page Width', 1, 5, 19, 'DETAIL', 150, '', '', '', 4, '2013-12-20 22:16:32', 4, '2013-12-28 20:56:31', 'Hide', 35);
INSERT INTO rpt.rpt_det_rpt_grps (group_id, title, col_nos, grp_width_desc, nof_cols_wthn, grp_order, report_id, grp_dsply_type, grp_min_height_px, column_hdr_names, delimiter_col_vals, delimiter_row_vals, created_by, creation_date, last_update_by, last_update_date, grp_border, label_max_width) VALUES (5, 'Basic Data', '0,1,2,3,4,5,6,7,8', 'Half Page Width', 2, 5, 19, 'DETAIL', 200, '', '', '', 4, '2013-12-20 22:17:51', 4, '2013-12-28 20:56:37', 'Hide', 35);
INSERT INTO rpt.rpt_det_rpt_grps (group_id, title, col_nos, grp_width_desc, nof_cols_wthn, grp_order, report_id, grp_dsply_type, grp_min_height_px, column_hdr_names, delimiter_col_vals, delimiter_row_vals, created_by, creation_date, last_update_by, last_update_date, grp_border, label_max_width) VALUES (7, 'Other Information', '9,10,11,12,13,14', 'Full Page Width', 4, 5, 19, 'DETAIL', 200, '', '', '', 4, '2013-12-22 19:39:37', 4, '2013-12-28 20:56:43', 'Hide', 35);


COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_DET_RPT_GRPS_GROUP_ID_SEQ', 11 );
COMMIT;
