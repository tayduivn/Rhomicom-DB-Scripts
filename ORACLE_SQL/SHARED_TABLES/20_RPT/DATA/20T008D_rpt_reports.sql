/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_REPORTS --data-only --column-inserts psdc_live > RPT.RPT_REPORTS.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_REPORTS CASCADE;


INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (13, 'Profit & Loss Column Chart', 'Profit & Loss', 'SELECT a.accnt_id "_", a.accnt_num "Account No.    ", a.accnt_name "Account Name.    ", 

CASE WHEN a.accnt_type = ''R'' THEN accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'',

 ''{:toDate} 23:59:59'') ELSE -1*accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', 

''{:toDate} 23:59:59'') END "Amount   ", CASE WHEN a.accnt_type = ''R'' THEN 

accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'')  

ELSE -1*accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'') END 

"TOTALS ", a.is_prnt_accnt "_" FROM accb.accb_chart_of_accnts a WHERE ((a.org_id = {:orgID}) 

and (a.is_prnt_accnt=''0'' and accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate}

 23:59:59'') IS NOT NULL) and (a.accnt_type = ''R'' or a.accnt_type = ''EX'')) ORDER BY a.accnt_typ_id,

 a.accnt_num



', 'Accounting', 4, '2013-06-19 22:48:44', 4, '2013-06-22 21:14:15', 'SQL Report', '1', '800,500', '2,3', '', '', '', 'COLUMN CHART', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (9, 'Pay Items Weekly Summary Per Date Range', 'Internal  Payments Detail Per Date Range', 'SELECT a.item_id "3", b.item_code_name 

"Item Name   ", SUM(a.amount_paid) "Amount Paid", to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''W (Mon YYYY)'') "Week(Month Year)", to_char(to_timestamp

(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''WW'') "Week(1-53) of the Year",  to_char(to_timestamp

(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY (W)'') "_"

FROM (pay.pay_itm_trnsctns a LEFT OUTER JOIN org.org_pay_items b ON a.item_id = 

b.item_id) LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id 

WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 

c.other_names) ilike ''%'') and (b.org_id ={:orgID})

AND (b.item_code_name ilike ''{:itemNm}'') and 

(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

GROUP BY a.item_id, b.item_code_name, to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY (W)''),  to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''WW''),to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''W (Mon YYYY)'')

ORDER BY  to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY (W)''), to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''WW''),  b.item_code_name', 'Internal Payments', 1, '2013-06-17 16:46:48', 4, '2013-07-02 08:06:59', 'SQL Report', '1', '', '1', '2', '', '2', 'HTML', 'Landscape', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (3, 'Person Payment Item Balances', 'Person Payment Item Balances', 'SELECT distinct c.local_id_no "ID No.    ", trim(c.title || '' '' || c.sur_name ||

         '', '' || c.first_name || '' '' || c.other_names) "Full Name         ", b.item_code_name  "Pay Item                ",

         CASE WHEN b.item_maj_type=''Balance Item'' THEN b.item_maj_type ELSE b.item_min_type END "1", 

        coalesce( (CASE WHEN b.item_maj_type=''Balance Item'' THEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),''{:pay_dte}'') ELSE a.amount_paid END),0) "Amount  ",b.pay_run_priority " "

       FROM prs.prsn_names_nos c 

       LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (c.person_id = f.person_id and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 

       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id ) 

       LEFT OUTER JOIN pay.pay_itm_trnsctns a ON (a.item_id = b.item_id and a.person_id = c.person_id and (to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(''{:pay_dte} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(''{:pay_dte} 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')))    

       WHERE((b.org_id = {:orgID}) and (b.local_classfctn ilike ''{:clsfctn}'') 

AND (b.item_code_name ilike ''{:itmNm}'')

AND (c.local_id_no IN ({:id_num})) AND (b.item_maj_type=''Balance Item'')) 

       ORDER BY c.local_id_no,b.pay_run_priority LIMIT {:limit} OFFSET {:offst}











/* "Full Name                       " a.paymnt_date, a.paymnt_source,

            a.pay_trns_type, a.pymnt_desc, a.crncy_id 02-Feb-2013

 (coalesce((CASE WHEN b.item_maj_type=''Balance Item'' THEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),''{:pay_dte}'') ELSE a.amount_paid END),0)<>0)

 

AND  (coalesce((CASE WHEN b.item_maj_type=''Balance Item'' THEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),''{:pay_dte}'') ELSE a.amount_paid END),0)<>0)

*/', 'Internal Payments', 1, '2013-02-01 10:33:02', 4, '2013-07-02 08:14:52', 'SQL Report', '1', '0,1', '0', '', '', '4', 'HTML', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (5, 'Period Close Process', 'Period Close Process', 'select accb.close_period(''{:closing_dte}'', {:usrID}, to_char(now(),''YYYY-MM-DD HH24:MI:SS''), {:orgID}, {:msgID})', 'Accounting', 1, '2013-03-13 17:42:53', 1, '2013-03-13 17:42:53', 'System Process', '1', '', '', '', '', '', 'None', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (2, 'Person Divisions', 'Persons & Groups', 'select a.local_id_no "ID No.        ",(select j.div_code_name from org.org_divs_groups j 

where j.div_id = b.div_id) "Division/Group                           ", to_char(to_timestamp(b.valid_start_date ,''YYYY-MM-DD''),''DD-Mon-YYYY'')

"Start Date    ",

 to_char(to_timestamp(b.valid_end_date ,''YYYY-MM-DD''),''DD-Mon-YYYY'') "End Date      "

       from prs.prsn_names_nos a 

       LEFT OUTER JOIN pasn.prsn_divs_groups b ON a.person_id = b.person_id

       where a.org_id = {:orgID} order by a.local_id_no;', 'Basic Person Data', 1, '2013-01-27 11:26:19', 4, '2013-07-02 08:16:36', 'SQL Report', '1', '0', '0', '', '', '', 'HTML', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (6, 'Deletion of Unposted Period Close Process', 'Deletion of Unposted Period Close Process', 'select accb.rvrs_period_close(''{:closing_dte}'', {:usrID}, to_char(now(),''YYYY-MM-DD HH24:MI:SS''), {:orgID}, {:msgID})', 'Accounting', 1, '2013-03-14 16:34:53', 1, '2013-03-14 16:34:53', 'System Process', '1', '', '', '', '', '', 'None', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (14, 'Profit & Loss Pie Chart', 'Profit & Loss', 'SELECT a.accnt_id "_", a.accnt_num "Account No.    ", a.accnt_name "Account Name.    ", 

CASE WHEN a.accnt_type = ''R'' THEN accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'',

 ''{:toDate} 23:59:59'') ELSE -1*accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', 

''{:toDate} 23:59:59'') END "Amount   ", CASE WHEN a.accnt_type = ''R'' THEN 

accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'')  

ELSE -1*accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'') END 

"TOTALS ", a.is_prnt_accnt "_" FROM accb.accb_chart_of_accnts a WHERE ((a.org_id = {:orgID}) 

and (a.is_prnt_accnt=''0'' and accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 

23:59:59'') IS NOT NULL) and (a.accnt_type = ''R'' or a.accnt_type = ''EX'')) 

ORDER BY accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'') DESC LIMIT 5 OFFSET 0



', 'Accounting', 4, '2013-06-19 23:49:59', 4, '2013-07-02 12:02:02', 'SQL Report', '1', '1100,300', '2,3', '', '', '', 'PIE CHART', 'Portrait', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (1, 'Person Names', 'Person Names', 'SELECT a.local_id_no "ID No.     ", 

 trim(a.title || '' '' || a.sur_name || '', '' || 

a.first_name || '' '' || a.other_names) "Full Name      ",

       a.gender "Gender       ", a.marital_status "Marital Status   ", to_char(to_timestamp(a.date_of_birth,''YYYY-MM-DD''),''DD-Mon-YYYY'')  "Date of Birth     ", a.place_of_birth "Place of Birth        ", a.religion "Religion       ", 

       a.res_address "Residential Address     ", a.pstl_addrs "Postal Address     ", a.email "Email Address      ", a.cntct_no_tel "Tel No.                 ", a.cntct_no_mobl "Mobile No.           ", 

       a.cntct_no_fax "Fax No.          ", b.prsn_type "Person Type            ", b.prn_typ_asgnmnt_rsn "Person Type Assignment Reason     ", 

        b.further_details "Further Details         "

       FROM prs.prsn_names_nos a LEFT OUTER JOIN pasn.prsn_prsntyps b

       ON (a.person_id = b.person_id ) where ((a.org_id = {:orgID}

       ) and (to_timestamp(''{:as_at_dte}'',''YYYY-MM-DD HH24:MI:SS'') 

between to_timestamp(b.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

AND to_timestamp(b.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) ORDER BY a.local_id_no;

/*01-Jan-2013



 a.title "Title   ", a.first_name "First Name     ", a.sur_name "Surname          ", a.other_names "Other Names          ", 

*/', 'Basic Person Data', 1, '2013-01-17 20:42:51', 4, '2013-07-02 08:17:24', 'SQL Report', '1', '', '0', '', '', '', 'HTML', 'Landscape', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (7, 'Person Payments Detail', 'Internal  Payments Detail Per Date Range', 'SELECT a.pay_trns_id "1", a.person_id "2", a.item_id "3", 

c.local_id_no "ID No.         ", trim(c.title || '' '' || c.sur_name || '', '' || 

c.first_name || '' '' || c.other_names) "Full Name      ", b.item_code_name 

"Item Name                         ", a.amount_paid "Amount Paid", to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') 

"Payment Date", a.paymnt_source "4", a.pay_trns_type || '':'' || a.pymnt_desc "Description                            ", a.crncy_id "5" 

FROM (pay.pay_itm_trnsctns a LEFT OUTER JOIN org.org_pay_items b ON a.item_id = 

b.item_id) LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id 

WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 

c.other_names) ilike ''%'') and (b.org_id ={:orgID}) and 

(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

AND c.local_id_no IN ({:IDNos})

AND b.item_code_name ilike ''{:itemNm}''

ORDER BY  to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') ASC', 'Internal Payments', 1, '2013-06-12 19:59:48', 4, '2013-09-04 14:40:36', 'SQL Report', '1', '3,4', '3', '6', '', '6', 'HTML', 'Landscape', 'None', NULL, NULL, 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (17, 'Account Transactions Trend Chart', 'Account Transactions Trend Chart', 'SELECT  to_timestamp(a.as_at_date,''YYYY-MM-DD'') "_", to_char(to_timestamp(a.as_at_date,''YYYY-MM-DD''),''DD-Mon-YYYY'')  "Transaction Date       ", 

 COALESCE(accb.get_prd_usr_trns_sum(a.accnt_id, a.as_at_date || '' 00:00:00'', a.as_at_date || '' 

23:59:59''),0) "Amount     "  

from accb.accb_accnt_daily_bals a where a.accnt_id =(select b.accnt_id from 

accb.accb_chart_of_accnts b where b.accnt_name ilike ''{:accntNm}'' and b.org_id={:orgID} 

ORDER BY b.accnt_id LIMIT 1 OFFSET 0 ) 

and to_timestamp(a.as_at_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') and 

to_timestamp(a.as_at_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 

ORDER BY  to_timestamp(a.as_at_date,''YYYY-MM-DD'')

', 'Accounting', 4, '2013-06-22 09:20:02', 4, '2013-10-24 08:51:35', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'LINE CHART', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (16, 'Account Balance Trend Line Chart', 'Account Balance Trend Line Chart', 'SELECT  to_timestamp(a.as_at_date,''YYYY-MM-DD'') "_", a.as_at_date  "Balance Date       ",   

accb.get_ltst_accnt_bals(a.accnt_id, a.as_at_date) "Amount     " from accb.accb_accnt_daily_bals a 

where a.accnt_id =(select b.accnt_id from accb.accb_chart_of_accnts b where b.accnt_name ilike 

''{:accntNm}'' and b.org_id={:orgID} ORDER BY b.accnt_id LIMIT 1 OFFSET 0 ) and to_timestamp

(a.as_at_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') and  to_timestamp

(a.as_at_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 

ORDER BY  to_timestamp(a.as_at_date,''YYYY-MM-DD'')



/*SELECT a.accnt_id"Account ID.    ", a.accnt_num "Account No.    ", a.accnt_name "Account 

Name.    ", a.is_prnt_accnt FROM accb.accb_chart_of_accnts a WHERE ((a.org_id = 3) and 

(a.accnt_type = ''R'' or a.accnt_type = ''EX'')) ORDER BY a.accnt_typ_id, a.accnt_num*/', 'Accounting', 4, '2013-06-22 08:41:30', 4, '2013-10-24 08:51:59', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'LINE CHART', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (10, 'Trial Balance', 'Balance Sheet', 'SELECT a.accnt_id "m", a.accnt_num "Account Number  ", a.accnt_name "Account Name                               ", 

(SELECT c.dbt_bal FROM accb.accb_accnt_daily_bals c WHERE(to_timestamp(c.as_at_date,''YYYY-MM-DD'') <=  to_timestamp(''{:as_at_dte}'',''YYYY-MM-DD'') and a.accnt_id = c.accnt_id)  

ORDER BY to_timestamp(c.as_at_date,''YYYY-MM-DD'') DESC LIMIT 1 OFFSET 0) "Debit Balance", 

(SELECT d.crdt_bal FROM accb.accb_accnt_daily_bals d WHERE(to_timestamp(d.as_at_date,''YYYY-MM-DD'') <=  to_timestamp(''{:as_at_dte}'',''YYYY-MM-DD'') and a.accnt_id = d.accnt_id) 

 ORDER BY to_timestamp(d.as_at_date,''YYYY-MM-DD'') DESC LIMIT 1 OFFSET 0) " Credit Balance",

 (CASE WHEN a.accnt_type=''A'' or a.accnt_type = ''EX'' THEN (SELECT e.net_balance FROM 

accb.accb_accnt_daily_bals e WHERE(to_timestamp(e.as_at_date,''YYYY-MM-DD'') <=  to_timestamp

(''{:as_at_dte}'',''YYYY-MM-DD'') and a.accnt_id = e.accnt_id)  ORDER BY to_timestamp

(e.as_at_date,''YYYY-MM-DD'') DESC LIMIT 1 OFFSET 0) ELSE (SELECT -1 * e.net_balance FROM 

accb.accb_accnt_daily_bals e WHERE(to_timestamp(e.as_at_date,''YYYY-MM-DD'') <=  to_timestamp

(''{:as_at_dte}'',''YYYY-MM-DD'') and a.accnt_id = e.accnt_id)  ORDER BY to_timestamp

(e.as_at_date,''YYYY-MM-DD'') DESC LIMIT 1 OFFSET 0) END) "Net Balance", to_char(to_timestamp(b.as_at_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') 

"Balance Date             ", a.is_prnt_accnt "m" FROM accb.accb_chart_of_accnts a LEFT OUTER JOIN 

 accb.accb_accnt_daily_bals b ON (a.accnt_id = b.accnt_id) WHERE ((a.org_id = {:orgID}) and 

(a.is_net_income = ''0'') and (a.control_account_id<0) and (a.is_prnt_accnt=''1'' or (to_timestamp(b.as_at_date,''YYYY-MM-DD'')=

(SELECT MAX(to_timestamp(f.as_at_date,''YYYY-MM-DD'')) from accb.accb_accnt_daily_bals f where

 f.accnt_id = a.accnt_id and to_timestamp(f.as_at_date,''YYYY-MM-DD'')<=to_timestamp

(''{:as_at_dte}'',''YYYY-MM-DD''))))) ORDER BY a.accnt_typ_id, a.accnt_num







/*SELECT  b.accnt_num "Account No.    ", b.accnt_name  "Account Name.               ",  CASE WHEN b.accnt_type=''A'' or b.accnt_type = ''EX'' THEN a.net_balance ELSE -1 * a.net_balance END "Balance   ", b.is_prnt_accnt "1", b.accnt_type "2" FROM accb.accb_chart_of_accnts b LEFT OUTER JOIN accb.accb_accnt_daily_bals a ON (a.accnt_id = b.accnt_id)  WHERE ((b.org_id = {:orgID}) and (b.accnt_type != ''R'') and (b.accnt_type != ''EX'') and (b.is_prnt_accnt=''1'' or (to_timestamp(a.as_at_date,''DD-Mon-YYYY'')=(SELECT MAX(to_timestamp(f.as_at_date,''DD-Mon-YYYY'')) from accb.accb_accnt_daily_bals f where f.accnt_id = a.accnt_id and to_timestamp(f.as_at_date,''DD-Mon-YYYY'')<=to_timestamp(''{:as_at_dte} 23:59:59'',''DD-Mon-YYYY HH24:MI:SS''))))) ORDER BY b.accnt_typ_id, b.accnt_num*/



/*SELECT a.accnt_id"Account ID.    ", a.accnt_num "Account No.    ", a.accnt_name "Account Name.    ", a.is_prnt_accnt FROM accb.accb_chart_of_accnts a WHERE ((a.org_id = 3) and (a.accnt_type = ''R'' or a.accnt_type = ''EX'')) ORDER BY a.accnt_typ_id, a.accnt_num*/', 'Accounting', 1, '2013-06-17 20:15:35', 4, '2013-12-22 19:06:01', 'SQL Report', '1', '', '', '3,4,5', '', '3,4,5', 'HTML', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (26, 'Automatic Database Maintenance', '', 'VACUUM FULL FREEZE VERBOSE ANALYZE', 'System Administration', 4, '2014-05-05 13:52:59', 4, '2014-05-05 13:52:59', 'Database Function', '0', '', '', '', '', '', 'None', 'None', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (27, 'Automatic Re-indexing of Database', 'Automatic Re-indexing of Database', 'REINDEX DATABASE {:dbase_name}', 'System Administration', 4, '2014-05-05 20:10:54', 4, '2014-05-05 20:10:54', 'Database Function', '1', '', '', '', '', '', 'None', 'None', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (4, 'Balance Sheet', 'Balance Sheet', 'SELECT  b.accnt_num "ACCOUNT NO.         ", b.accnt_name  "ACCOUNT NAME                    ",   

CASE WHEN b.accnt_type=''A'' or b.accnt_type = ''EX'' THEN accb.get_ltst_accnt_bals(b.accnt_id, 

''{:as_at_dte} 23:59:59'') ELSE -1 * accb.get_ltst_accnt_bals(b.accnt_id, ''{:as_at_dte} 23:59:59'') END 

"BALANCE            ", b.is_prnt_accnt "1", b.accnt_type "2", 

CASE WHEN b.accnt_type=''A'' or b.accnt_type = ''EX'' THEN accb.get_rcsv_prnt_accnt_bals

(b.accnt_id, ''{:as_at_dte} 23:59:59'') ELSE -1 * accb.get_rcsv_prnt_accnt_bals(b.accnt_id, ''{:as_at_dte} 

23:59:59'') END "TOTALS               " FROM accb.accb_chart_of_accnts b WHERE ((b.org_id = {:orgID}) and 

(b.accnt_type != ''R'') and (b.accnt_type != ''EX'') and (b.control_account_id<0) and (b.is_prnt_accnt =''1'' or accb.get_ltst_accnt_bals

(b.accnt_id, ''{:as_at_dte} 23:59:59'') IS NOT NULL)) ORDER BY b.accnt_typ_id, b.accnt_num





/*SELECT a.accnt_id"Account ID.    ", a.accnt_num "Account No.    ", a.accnt_name "Account Name.    ", a.is_prnt_accnt FROM accb.accb_chart_of_accnts a WHERE ((a.org_id = 3) and (a.accnt_type = ''R'' or a.accnt_type = ''EX'')) ORDER BY a.accnt_typ_id, a.accnt_num*/', 'Accounting', 1, '2013-02-10 23:06:07', 4, '2013-12-22 18:02:06', 'SQL Report', '1', '0', '', '2', '', '2,5', 'HTML', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (19, 'Person Names-Detail Display', 'Person Names', 'SELECT a.local_id_no "ID No.     ", 

 trim(a.title || '' '' || a.sur_name || '', '' || 

a.first_name || '' '' || a.other_names) "Full Name      ",

       a.gender "Gender       ", a.marital_status "Marital Status   ", to_char(to_timestamp(a.date_of_birth,''YYYY-MM-DD''),''DD-Mon-YYYY'')  "Date of Birth     ", a.place_of_birth "Place of Birth        ",a.hometown, a.nationality, a.religion "Religion       ", 

       a.res_address "Residential Address     ", a.pstl_addrs "Postal Address     ", a.email "Email Address      ", a.cntct_no_tel "Tel No.                 ", a.cntct_no_mobl "Mobile No.           ", 

       a.cntct_no_fax "Fax No.          " , ''/Person/'' || a.img_location

       FROM prs.prsn_names_nos a  where ((a.org_id = {:orgID}

       )) ORDER BY a.local_id_no LIMIT {:limit} OFFSET {:offst};

/*01-Jan-2013



 a.title "Title   ", a.first_name "First Name     ", a.sur_name "Surname          ", a.other_names "Other Names          ", 

*/', 'Basic Person Data', 4, '2013-12-20 22:15:04', 4, '2013-12-27 23:00:19', 'SQL Report', '1', '', '0', '', '', '', 'PDF', 'Portrait', 'DETAIL', '15', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (20, 'Reversal of Posted Period Close Process', 'Reversal of Posted Period Close Process', 'select accb.rvrs_pstd_period_close(''{:closing_dte}'', {:usrID}, to_char(now(),''YYYY-MM-DD HH24:MI:SS''), {:orgID}, {:msgID})', 'Accounting', 4, '2014-01-10 12:28:22', 4, '2014-01-10 12:28:22', 'System Process', '1', '', '', '', '', '', 'None', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (22, 'Inventory Items Value Report', 'Inventory Items Value Report', 'select '''''''' || a.item_code "Item Code          ", 
a.item_desc "Description          ",
a.cat_name "Category  ",
a.subinv_name "Store  ", 
trim(to_char(a.totqty,''9999999999999999990D99'')) "QTY  ", 
a.uom_name "UOM ", 
trim(to_char(a.costprice*totqty,''9999999999999999990D99'')) "Total Cost Price     ",
trim(to_char(a.crnt_sllng_rpice*totqty,''9999999999999999990D99'')) "Total Selling Price"
FROM scm.get_inv_sllng_price({:orgID}, {:strID} , {:catID}, 10.00, ''2'') a, inv.inv_itm_list b
 WHERE a.item_id=b.item_id and (b.enabled_flag=''1'' or b.enabled_flag IS NULL);', 'Stores And Inventory Manager', 4, '2014-03-31 10:54:15', 1, '2014-06-11 10:10:32', 'SQL Report', '1', '', '0', '6,7', '', '4,6,7', 'MICROSOFT EXCEL', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (21, 'Inventory Items Stock Qty Report', 'Inventory Items Stock Qty Report', 'select '''''''' || a.item_code "Item Code     ", 
a.item_desc "Description          ",
a.cat_name "Category  ",
a.subinv_name "Store  ", 
trim(to_char(a.totqty,''9999999999999999990D99'')) "QTY  ", 
a.uom_name "UOM ", 
trim(to_char(a.costprice,''9999999999999999990D99'')) "Cost Price ", 
trim(to_char(a.crnt_sllng_rpice,''9999999999999999990D99'')) "Selling Price     ", 
trim(to_char(a.crnt_prft_mgn,''9999999999999999990D99'')) "Profit Margin (%)"
FROM scm.get_inv_sllng_price({:orgID}, {:strID} , {:catID}, 10.00, ''2'')  a, inv.inv_itm_list b
 WHERE a.item_id=b.item_id and (b.enabled_flag=''1'' or b.enabled_flag IS NULL)
 and a.totqty between {:qty1} and {:qty2} and a.crnt_prft_mgn between {:mrgn1} and {:mrgn2};', 'Stores And Inventory Manager', 4, '2014-03-30 21:49:50', 1, '2014-06-11 09:09:09', 'SQL Report', '1', '', '0', '6,7,10', '', '4,6,7,8,9,10', 'MICROSOFT EXCEL', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (56, 'Classes Details', 'Classes Details', 'select (select grade_code_name from org.org_grades og where og.grade_id = pg.grade_id ) "Grade           ", 
  '''''''' ||local_id_no as "ID No.       ", 
  title||'' ''||first_name||'' ''||other_names||'' ''||sur_name as "Full Name                    " 
  from prs.prsn_names_nos pnn, pasn.prsn_grades pg
  WHERE pnn.person_id = pg.person_id
  AND '''' || coalesce(pg.grade_id,-1) = coalesce(NULLIF(''{:grd_id}'',''''), '''' || coalesce(pg.grade_id,-1))
  order by 1', 'Basic Person Data', 1, '2015-05-29 05:07:19', 1, '2015-05-29 05:12:16', 'SQL Report', '1', '', '1', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (23, 'Post GL Transaction Batches', 'Post GL Transaction Batches', 'SELECT batch_id, batch_name, batch_source, batch_status mt, 
CASE WHEN batch_status=''1'' THEN ''POSTED'' ELSE ''NOT POSTED'' END "Posting Status", 
batch_description,  org_id m1, avlbl_for_postng m2, 
(select count(1) from accb.accb_trnsctn_details y where y.batch_id=a.batch_id)  "No. of Trns.  "
 FROM accb.accb_trnsctn_batches a 
WHERE org_id={:orgID} and batch_status=''0'' and avlbl_for_postng=''1'' 
and ((select count(1) from accb.accb_trnsctn_details y where y.batch_id=a.batch_id)>0 or batch_source=''Period Close Process'') 
and age(now(), 
to_timestamp(last_update_date,''YYYY-MM-DD HH24:MI:SS''))>= interval ''5 minute'' 
ORDER BY 1 ASC LIMIT 500 OFFSET 0;
', 'Accounting', 4, '2014-04-28 21:37:13', 4, '2014-06-12 12:19:59', 'Posting of GL Trns. Batches', '1', '', '0', '', '', '', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (30, 'Expiring Items Report', 'Expiring Items Report', 'SELECT distinct a.itm_id "m", a.consgmt_id "Consignment No.", 
 a.subinv_id "n", (select w.subinv_name from inv.inv_itm_subinventories w where w.subinv_id=a.subinv_id) "Store ",
 b.item_code "Item Code      ", b.item_desc "Description                    ", 
 a.cost_price "Unit Cost Price ", COALESCE(inv.get_csgmt_lst_tot_bls(a.consgmt_id),0) "QTY    ", 
 a.cost_price*COALESCE(inv.get_csgmt_lst_tot_bls(a.consgmt_id),0) "Total Cost    ",
 to_char(to_timestamp(a.expiry_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') "Date of Expiry  ", 
 extract(''years'' from age(CASE WHEN a.expiry_date IS NULL or expiry_date='''' THEN 
 to_timestamp(''4000-12-31 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') ELSE 
 to_timestamp(expiry_date || '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') END, now())) || '' yr(s) ''
 || extract(''months'' from age(CASE WHEN a.expiry_date IS NULL or expiry_date='''' THEN 
 to_timestamp(''4000-12-31 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') ELSE 
 to_timestamp(expiry_date || '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') END, now())) || '' mon(s) ''
 || extract(''days'' from age(CASE WHEN a.expiry_date IS NULL or expiry_date='''' THEN 
 to_timestamp(''4000-12-31 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') ELSE 
 to_timestamp(expiry_date || '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') END, now())) || '' day(s)'' "Time to Expire ",
 a.expiry_date "q"
 FROM inv.inv_consgmt_rcpt_det a, inv.inv_itm_list b
 WHERE a.itm_id=b.item_id and b.org_id={:orgID} and (b.enabled_flag=''1'' or b.enabled_flag IS NULL)
 and age(CASE WHEN a.expiry_date IS NULL or expiry_date='''' THEN 
 to_timestamp(''4000-12-31 23:59:59'',''YYYY-MM-DD HH24:MI:SS'') ELSE 
 to_timestamp(expiry_date || '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') END, now()) 
 between interval ''{:days1} Day'' and interval ''{:days2} Day'' 
 and COALESCE(inv.get_csgmt_lst_tot_bls(a.consgmt_id),0)>0
 ORDER BY a.expiry_date, b.item_desc, a.consgmt_id
', 'Stores And Inventory Manager', 4, '2014-06-17 08:26:15', 4, '2014-06-17 19:46:11', 'SQL Report', '1', '', '1', '8', '', '6,7,8', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (31, 'Pay Run Summary Report', 'Pay Run Summary Report', 'select tbl1.local_id_no "ID No.", tbl1.fullname "Full Name", 
round(tbl1.total_earnings,2) "Total Earnings", 
round(tbl1.total_employer_charges,2)  "Total Employer Charges", 
round(tbl1.total_bills_charges+ tbl1.total_deductions,2) "Deductions",
round(tbl1.total_earnings - tbl1.total_bills_charges- tbl1.total_deductions,2) "Take Home" 
from pay.get_payment_summrys({:orgID},''{:pay_run_name}'',''{:ordrBy}'') tbl1;', 'Internal Payments', 4, '2015-01-30 20:45:42', 4, '2015-01-30 21:15:11', 'SQL Report', '1', '', '0', '2,3,4,5', '', '2,3,4,5', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (33, 'VAT/TL Account Transaction Split Report', 'VAT/TL Account Transaction Split Report', 'SELECT row_number() OVER (ORDER BY a.trnsctn_date DESC) AS "No.  ", 
b.accnt_num ||''.''||b.accnt_name "Account Name/Number", 
a.transaction_desc "Description",
Round((17.5/18.5)*a.net_amount,2) "VAT Amount", 
Round((1/18.5)*a.net_amount,2) "Tourism Levy Amount", 
a.net_amount "Total Amount",
gst.get_pssbl_val(a.func_cur_id) "Currency",
to_char(to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') "Transaction Date"
FROM accb.accb_trnsctn_details a 
LEFT OUTER JOIN accb.accb_chart_of_accnts b on a.accnt_id = b.accnt_id 
WHERE(b.org_id = {:orgID} and trns_status = ''1'' AND (b.accnt_num ilike ''21070'' or accb.get_accnt_num(b.control_account_id) 
ilike ''21070'' or b.accnt_name ilike ''21070'' or accb.get_accnt_name(b.control_account_id) ilike ''21070'') 
AND (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(''{:strtDte}'',''DD-Mon-YYYY HH24:MI:SS'')
and to_timestamp(''{:endDte}'',''DD-Mon-YYYY HH24:MI:SS''))) 
ORDER BY a.trnsctn_date DESC', 'Accounting', 1, '2015-02-07 06:10:15', 1, '2015-02-07 06:24:51', 'SQL Report', '1', '', '', '3,4,5', '', '3,4,5', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (41, 'Gender Distribution', 'Gender Distribution', 'select gender, count(1) 

FROM prs.prsn_names_nos pnn 

left outer join pasn.prsn_prsntyps ppt
  on pnn.person_id = ppt.person_id
  

where '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
  

group by 1;', 'Basic Person Data', 1, '2015-05-19 07:23:03', 1, '2015-08-20 20:09:51', 'SQL Report', '1', '1100, 300', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (34, 'SSNIT/TIER2 Account Transaction Split Report', 'SSNIT Account Transaction Split Report', 'SELECT row_number() OVER (ORDER BY a.trnsctn_date DESC) AS "No.  ", 
b.accnt_num ||''.''||b.accnt_name "Account Name/Number", 
a.transaction_desc "Description",
Round((13.5/18.5)*a.net_amount,2) "SSNIT Amount", 
Round((5.5/18.5)*a.net_amount,2) "TIER2 Amount", 
a.net_amount "Total Amount",
gst.get_pssbl_val(a.func_cur_id) "Currency",
to_char(to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') "Transaction Date"
FROM accb.accb_trnsctn_details a 
LEFT OUTER JOIN accb.accb_chart_of_accnts b on a.accnt_id = b.accnt_id 
WHERE(b.org_id = {:orgID} and trns_status = ''1'' AND (b.accnt_num ilike ''21060'' or accb.get_accnt_num(b.control_account_id) 
ilike ''21060'' or b.accnt_name ilike ''21060'' or accb.get_accnt_name(b.control_account_id) ilike ''21060'') 
AND (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(''{:strtDte}'',''DD-Mon-YYYY HH24:MI:SS'')
and to_timestamp(''{:endDte}'',''DD-Mon-YYYY HH24:MI:SS''))) 
ORDER BY a.trnsctn_date DESC', 'Accounting', 1, '2015-02-07 06:21:52', 1, '2015-02-07 07:49:55', 'SQL Report', '1', '', '', '3,4,5', '', '3,4,5', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (32, 'Pay Run Bank Advice Report', 'Pay Run Bank Advice Report', 'select tbl1.local_id_no "ID No.", tbl1.fullname "Full Name", 
round(tbl1.total_earnings - tbl1.total_bills_charges- tbl1.total_deductions,2) "Take Home", 
tbl2.bank_name ||''/''|| tbl2.bank_branch "Bank", 
tbl2.account_name ||''/''|| tbl2.account_number ||''/''||  
tbl2.account_type "Account Details", 
tbl2.net_pay_portion "Net Pay Portion", 
tbl2.portion_uom "UOM ", 
CASE WHEN portion_uom=''Percent'' THEN round(chartonumeric(to_char((net_pay_portion/100.00) * 
(tbl1.total_earnings - tbl1.total_bills_charges- tbl1.total_deductions),''999999999999999999999999999999999999999999999D99'')),2) 
 ELSE net_pay_portion END "Amount to Transfer" 
from pay.get_payment_summrys({:orgID},''{:pay_run_name}'',''{:ordrBy}'') tbl1 
LEFT OUTER JOIN 
pasn.prsn_bank_accounts tbl2 ON (tbl1.person_id = tbl2.person_id and tbl2.net_pay_portion !=0);', 'Internal Payments', 4, '2015-01-30 21:15:27', 1, '2015-02-07 07:47:06', 'SQL Report', '1', '', '0', '10', '', '2,8,10', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (36, 'Outstanding Payables Invoices', 'Outstanding Payables Invoices', 'SELECT row_number() OVER (ORDER BY a.approval_status DESC, a.pybls_invc_date DESC, a.pybls_invc_hdr_id DESC
) AS "No.  ", 
a.pybls_invc_hdr_id mt, a.pybls_invc_number "Invoice Number", 
to_char(to_timestamp(a.pybls_invc_date,''YYYY-MM-DD HH24:MI:SS''),
''DD-Mon-YYYY HH24:MI:SS'') "Invoice Date", 
/*a.rcvbls_invc_type "Invoice Type",*/scm.get_cstmr_splr_name(a.supplier_id)||
'' ('' ||scm.get_cstmr_splr_site_name(a.supplier_site_id)||'')''  "Customer Name/Site", 
a.comments_desc ||'' (''|| scm.get_src_doc_num(a.src_doc_hdr_id, a.src_doc_type) || ''-''||a.src_doc_type ||'')'' "Invoice Description",
round(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''6Grand Total'') + 
abs(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''3Discount'')),2) "Invoice Amount", 
round(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''3Discount''),2)  "Discount Amount",
round(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''7Total Payments Made''),2)  "Payments Made", 
round(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''8Outstanding Balance''),2)  "Outstanding Amount",
 a.approval_status "Approval Status"
        FROM accb.accb_pybls_invc_hdr a 
        WHERE((a.org_id = {:orgID}) and a.approval_status!=''Cancelled'' and a.approval_status ilike ''{:apprvl_status}'' and (COALESCE(scm.get_cstmr_splr_name(a.supplier_id),'''') ilike ''{:sppplr_nm}'') 
        and round(accb.get_pybl_smry_typ_amnt(a.pybls_invc_hdr_id, a.pybls_invc_type, ''8Outstanding Balance''),2)>0
         AND (to_timestamp(a.pybls_invc_date,''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(''{:strtDte}'',''DD-Mon-YYYY HH24:MI:SS'')
and to_timestamp(''{:endDte}'',''DD-Mon-YYYY HH24:MI:SS''))) 
        ORDER BY a.approval_status DESC, a.pybls_invc_date DESC, a.pybls_invc_hdr_id DESC', 'Accounting', 1, '2015-02-07 06:49:57', 1, '2015-02-10 16:43:47', 'SQL Report', '1', '', '', '6,7,8,9', '', '6,7,8,9', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (35, 'Outstanding Receivables Invoices', 'Outstanding Receivables Invoices', 'SELECT row_number() OVER (ORDER BY a.approval_status DESC, a.rcvbls_invc_date DESC, a.rcvbls_invc_hdr_id DESC) AS "No.  ", 
rcvbls_invc_hdr_id mt, rcvbls_invc_number "Invoice Number", 
to_char(to_timestamp(a.rcvbls_invc_date,''YYYY-MM-DD HH24:MI:SS''),
''DD-Mon-YYYY HH24:MI:SS'') "Invoice Date", 
/*a.rcvbls_invc_type "Invoice Type",*/scm.get_cstmr_splr_name(a.customer_id)||
'' ('' ||scm.get_cstmr_splr_site_name(customer_site_id)||'')''  "Customer Name/Site", 
a.comments_desc ||'' (''|| scm.get_src_doc_num(a.src_doc_hdr_id, a.src_doc_type) || ''-''||a.src_doc_type ||'')'' "Invoice Description",
round(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''6Grand Total'') + 
abs(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''3Discount'')),2) "Invoice Amount", 
round(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''3Discount''),2)  "Discount Amount",
round(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''7Total Payments Made''),2)  "Payments Made", 
round(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''8Outstanding Balance''),2)  "Outstanding Amount",
 a.approval_status "Approval Status"
        FROM accb.accb_rcvbls_invc_hdr a 
        WHERE((a.org_id = {:orgID}) and a.approval_status!=''Cancelled'' and a.approval_status ilike ''{:apprvl_status}'' and (COALESCE(scm.get_cstmr_splr_name(a.customer_id),'''') ilike ''{:cstmr_nm}'') 
        and round(accb.get_rcvbl_smry_typ_amnt(a.rcvbls_invc_hdr_id, a.rcvbls_invc_type, ''8Outstanding Balance''),2)>0
        AND (to_timestamp(a.rcvbls_invc_date,''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(''{:strtDte}'',''DD-Mon-YYYY HH24:MI:SS'')
and to_timestamp(''{:endDte}'',''DD-Mon-YYYY HH24:MI:SS''))) 
        ORDER BY a.approval_status DESC, a.rcvbls_invc_date DESC, a.rcvbls_invc_hdr_id DESC', 'Accounting', 1, '2015-02-07 06:36:03', 1, '2015-02-10 16:44:05', 'SQL Report', '1', '', '', '6,7,8,9', '', '6,7,8,9', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (37, 'Inventory Trns Sum/Bals Mismatch', 'Inventory Trns. Sum/Bals Mismatch', 'SELECT tbl1.itm_id mt,tbl1.item_code "Item Code ",tbl1.item_desc "Description ",z.subinv_id m, 
 z.subinv_name "Store ",k.stock_id m,SUM(tbl1.qnty) "Transaction Total Qty ",
 scm.get_ltst_stock_avlbl_bals(k.stock_id, 
 to_char(now(),''YYYY-MM-DD'')) "System Stock Balance ", tbl1.uom  "UOM "
 FROM (SELECT a.invc_type,a.invc_number, a.comments_desc
        , c.item_code, 
        c.item_desc, 
        CASE WHEN a.invc_type=''Sales Return'' THEN 
 b.doc_qty ELSE  -1*b.doc_qty END qnty, 
        d.uom_name uom,
        a.last_update_date,  
        b.itm_id,
        b.store_id
        FROM scm.scm_sales_invc_hdr a, sec.sec_users y, scm.scm_sales_invc_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d
        WHERE ((a.invc_hdr_id = b.invc_hdr_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.approval_status ilike ''Approved'' or b.is_itm_delivered=''1'') AND (a.org_id ={:orgID}) AND 
        (a.created_by=y.user_id) and (a.invc_type IN 
(''Sales Invoice'',''Sales Order'',''Sales Return'',''Item Issue-Unbilled''))) 
 UNION
        select ''Receipt'',a.rcpt_id ||'''',a.description, c.item_code, 
        c.item_desc, 
        b.quantity_rcvd qnty, 
        d.uom_name uom,
        a.last_update_date,
        b.itm_id,
       b.subinv_id
         from inv.inv_consgmt_rcpt_hdr a, sec.sec_users y, inv.inv_consgmt_rcpt_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d
 WHERE ((a.rcpt_id = b.rcpt_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.approval_status ilike ''Received'' or a.approval_status ilike ''%Successful%'') AND (a.org_id = {:orgID}) AND 
        (a.created_by=y.user_id))
 UNION
        select distinct ''Quantity Adjustment'',a.adjstmnt_hdr_id ||'''',a.description, c.item_code, 
        c.item_desc, 
        (chartodouble(b.new_ttl_qty)-b.new_ttl_qty_old) qnty, 
        d.uom_name uom,
        a.last_update_date,
        f.itm_id,
       f.subinv_id
         from inv.inv_consgmt_adjstmnt_hdr a, sec.sec_users y, inv.inv_consgmt_adjstmnt_det b, 
         inv.inv_consgmt_rcpt_det f,
        inv.inv_itm_list c, inv.unit_of_measure d
 WHERE ((a.adjstmnt_hdr_id = b.adjstmnt_hdr_id and f.consgmt_id = b.consgmt_id AND f.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.status ilike ''Adjustment Successful'') AND (a.org_id = {:orgID}) AND 
        (a.created_by=y.user_id)) 
 UNION
        select ''Stock Transfer'',a.transfer_hdr_id ||'''',a.description, c.item_code, 
        c.item_desc, 
        -1*b.transfer_qty qnty, 
        d.uom_name uom,
        a.last_update_date,
        b.itm_id,
       b.src_store_id
         from inv.inv_stock_transfer_hdr a, sec.sec_users y, inv.inv_stock_transfer_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d
 WHERE ((a.transfer_hdr_id = b.transfer_hdr_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.status ilike ''Transfer Successful'') AND (a.org_id = {:orgID}) AND 
        (a.created_by=y.user_id))   
 UNION
        select ''Stock Transfer'',a.transfer_hdr_id ||'''',a.description, c.item_code, 
        c.item_desc, 
        b.transfer_qty qnty, 
        d.uom_name uom,
        a.last_update_date,
        b.itm_id,
       b.dest_subinv_id
         from inv.inv_stock_transfer_hdr a, sec.sec_users y, inv.inv_stock_transfer_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d
 WHERE ((a.transfer_hdr_id = b.transfer_hdr_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.status ilike ''Transfer Successful'') AND (a.org_id = {:orgID}) AND 
        (a.created_by=y.user_id)) 
 UNION
        select ''Receipt Return'',a.rcpt_rtns_id ||'''',a.description, c.item_code, 
        c.item_desc, 
        -1*b.qty_rtnd qnty, 
        d.uom_name uom,
        a.last_update_date,
        b.itm_id,
        b.subinv_id
         from inv.inv_consgmt_rcpt_rtns_hdr a, sec.sec_users y, inv.inv_consgmt_rcpt_rtns_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d, inv.inv_consgmt_rcpt_det e
 WHERE ((b.rcpt_line_id = e.line_id AND a.rcpt_rtns_id = b.rtns_hdr_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (a.approval_status != ''Incomplete'' or a.approval_status IS NULL) AND (a.org_id = {:orgID}) AND 
        (a.created_by=y.user_id))) tbl1 
        left outer join inv.inv_stock k on (tbl1.itm_id = k.itm_id and tbl1.store_id = k.subinv_id)
        /*left outer join inv.inv_stock_daily_bals m on (k.stock_id = m.stock_id and substr(tbl1.last_update_date,1,10)=m.bals_date)*/
        left outer join inv.inv_itm_subinventories z on (tbl1.store_id=z.subinv_id)
        WHERE tbl1.store_id>0 
        GROUP BY 1,2,3,4,5,6,8,9
        HAVING (SUM(tbl1.qnty) != scm.get_ltst_stock_avlbl_bals(k.stock_id, 
 to_char(now(),''YYYY-MM-DD'')))
         ORDER BY tbl1.item_code ASC, z.subinv_id ASC', 'Stores And Inventory Manager', 1, '2015-02-20 09:18:38', 1, '2015-02-20 20:55:06', 'SQL Report', '1', '', '1', '', '', '6,7', 'HTML', 'Portrait', 'TABULAR', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (55, 'Coorperate Membership Distribution (Chart)', 'Coorperate Membership Distribution (Chart)', 'select case when (select grade_code_name from org.org_grades og where og.grade_id = pg.grade_id ) IN (''Member (M)'',
 ''Member (M+)'', ''Fellow (F)'', ''Honoured Fellow (HF)'') then ''Corporate''
  else ''Non-Corporate'' end, count(1) from pasn.prsn_grades pg 
  group by 1', 'Basic Person Data', 1, '2015-05-29 05:02:42', 1, '2015-05-30 09:08:18', 'SQL Report', '1', '800,400', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (53, 'Monthly Visitor Traffic', 'Monthly Visitor Traffic', 'SELECT  to_char(to_timestamp(hdr.event_date,''YYYY-MM''),''YYYY-Mon'') "_", to_char(to_timestamp(hdr.event_date,''YYYY-MM''),''YYYY-Mon'') DATE,  
     /*det.visitor_classfctn,*/ count(attnd_rec_id) "Number Of Visitors"
  FROM attn.attn_attendance_recs_hdr hdr, attn.attn_attendance_recs det
  where  hdr.recs_hdr_id = det.recs_hdr_id
  and '''' || coalesce(det.visitor_classfctn ,''-1'') = coalesce(NULLIF(''{:visClas}'',''''), '''' || coalesce(det.visitor_classfctn,''-1''))
  and hdr.org_id = {:orgID}
  and to_timestamp(hdr.event_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
  and to_timestamp(hdr.event_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
  group by  to_char(to_timestamp(hdr.event_date,''YYYY-MM''),''YYYY-Mon''), to_char(to_timestamp(hdr.event_date,''YYYY-MM''),''YYYY-Mon'')/*,  
     det.visitor_classfctn*/
  order by 1', 'Events And Attendance', 1, '2015-05-29 04:51:58', 1, '2015-05-29 04:56:58', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'LINE CHART', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (25, 'Journal Import from Internal Payments Module', 'Journal Import from Internal Payments Module', 'SELECT a.accnt_id, 
to_char(to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') trnsdte
, SUM(a.dbt_amount) dbt_sum, SUM(a.crdt_amount) crdt_sum, SUM(a.net_amount) net_sum, 
a.func_cur_id FROM {:intrfc_tbl_name} a, accb.accb_chart_of_accnts b 
WHERE a.gl_batch_id = -1 and a.accnt_id = b.accnt_id and b.org_id={:orgID} and age(now(),
to_timestamp(a.last_update_date,''YYYY-MM-DD HH24:MI:SS'')) > interval ''5 minute'' /*and 
NOT EXISTS(select f.transctn_id from accb.accb_trnsctn_details f where f.batch_id IN 
(select g.batch_id from accb.accb_trnsctn_batches g where g.batch_name ilike ''{:glbatch_name}'' 
and to_timestamp(g.creation_date,''YYYY-MM-DD HH24:MI:SS'') between (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') 
- interval ''6 months'') and (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') + interval ''6 months'')) 
and f.source_trns_ids like ''%,'' || a.interface_id || '',%'' and f.trnsctn_date=a.trnsctn_date and f.accnt_id= a.accnt_id)*/  
GROUP BY a.accnt_id, a.trnsctn_date, func_cur_id 
ORDER BY to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'')
', 'Internal Payments', 4, '2014-04-28 23:17:34', 1, '2015-03-04 10:38:32', 'Journal Import', '1', '', '0', '', '', '', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (24, 'Journal Import from Stores & Inventory Module', 'Journal Import from Stores & Inventory Module', 'SELECT a.accnt_id, 
to_char(to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') trnsdte
, SUM(a.dbt_amount) dbt_sum, SUM(a.crdt_amount) crdt_sum, SUM(a.net_amount) net_sum, 
a.func_cur_id FROM {:intrfc_tbl_name} a, accb.accb_chart_of_accnts b 
WHERE a.gl_batch_id = -1 and a.accnt_id = b.accnt_id and b.org_id={:orgID} and age(now(),
to_timestamp(a.last_update_date,''YYYY-MM-DD HH24:MI:SS'')) > interval ''5 minute'' /*and 
NOT EXISTS(select f.transctn_id from accb.accb_trnsctn_details f where f.batch_id IN 
(select g.batch_id from accb.accb_trnsctn_batches g where g.batch_name ilike ''{:glbatch_name}'' 
and to_timestamp(g.creation_date,''YYYY-MM-DD HH24:MI:SS'') between (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') 
- interval ''6 months'') and (to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'') + interval ''6 months'')) 
and f.source_trns_ids like ''%,'' || a.interface_id || '',%'' and f.trnsctn_date=a.trnsctn_date and f.accnt_id= a.accnt_id)*/  
GROUP BY a.accnt_id, a.trnsctn_date, func_cur_id 
ORDER BY to_timestamp(a.trnsctn_date,''YYYY-MM-DD HH24:MI:SS'')', 'Stores And Inventory Manager', 4, '2014-04-28 22:56:00', 1, '2015-03-04 11:23:01', 'Journal Import', '1', '', '0', '', '', '', 'HTML', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (38, 'Portability Details', '', 'select title||'' ''||first_name||'' ''||other_names||'' ''||sur_name||'' (''||local_id_no||'')'' as "Full Name                          ", 
 case when (trim(email) != '''' AND trim(cntct_no_tel||''''||cntct_no_mobl) != '''') then ''Grade A''
 when trim(cntct_no_tel||''''||cntct_no_mobl) != '''' then ''Grade B''
 when trim(email) != '''' then ''Grade C''
 else ''Grade D'' end portability FROM prs.prsn_names_nos pnn left outer join pasn.prsn_prsntyps ppt
 on pnn.person_id = ppt.person_id
 where '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
 order by 2;', 'Basic Person Data', 1, '2015-05-17 17:46:32', 1, '2015-05-19 07:47:38', 'SQL Report', '1', '', '', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (42, 'Gender Distribution-Details', 'Gender Distribution-Details', 'select '''''''' || local_id_no, title||'' ''||first_name||'' ''||other_names||'' ''||sur_name as "Full Name", gender
          FROM prs.prsn_names_nos pnn left outer join pasn.prsn_prsntyps ppt
  on pnn.person_id = ppt.person_id
  where '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
  group by 1,2,3', 'Basic Person Data', 1, '2015-05-19 07:40:43', 1, '2015-05-19 08:09:51', 'SQL Report', '1', '1100, 300', '0,1', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (39, 'Portability', '', 'select case when (trim(res_address||''''||pstl_addrs) != '''' AND trim(email) != '''' AND trim(cntct_no_tel||''''||cntct_no_mobl) != '''') then ''Grade A''
 when (trim(email) != '''' AND trim(cntct_no_tel||''''||cntct_no_mobl) != '''') then ''Grade B''
 when trim(cntct_no_tel||''''||cntct_no_mobl) != '''' then ''Grade C''
 when trim(email) != '''' then ''Grade D''
 else ''Grade E'' end portability, count(1) FROM prs.prsn_names_nos pnn left outer join pasn.prsn_prsntyps ppt
 on pnn.person_id = ppt.person_id
 where '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
 group by 1', 'Basic Person Data', 1, '2015-05-17 17:48:40', 1, '2015-05-23 11:52:10', 'SQL Report', '1', '1100,300', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (44, 'Technical Division Distribution', 'Technical Distribution', 'select div_code_name division, count(1) count
  from pasn.prsn_divs_groups pdg inner join org.org_divs_groups odg 
  on pdg.div_id = odg.div_id
  WHERE (coalesce(pdg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pdg.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))
  /*AND UPPER(div_code_name) in (''CIVIL'',''ELECTRICAL'',''MECH/AGRIC'',''CHEM/MINING'')*/ 
  AND gst.get_pssbl_val(div_typ_id)=''Technical Division''
  group by 1
', 'Basic Person Data', 1, '2015-05-19 08:05:17', 1, '2015-05-23 11:38:13', 'SQL Report', '1', '1100, 500', '0,1', '', '', '', 'COLUMN CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (45, 'Specialization', '', 'select data_col2 specialization, count(*) from prs.prsn_extra_data ped, pasn.prsn_prsntyps ppt
 where ped.person_id = ppt.person_id
 and '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
 group by 1', 'Basic Person Data', 1, '2015-05-23 13:15:30', 1, '2015-05-23 13:18:35', 'SQL Report', '1', '1100,600', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (46, 'Practice', '', 'select data_col6 practice, count(*) from prs.prsn_extra_data ped, pasn.prsn_prsntyps ppt
 where ped.person_id = ppt.person_id
 and '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
 group by 1', 'Basic Person Data', 1, '2015-05-23 13:24:14', 1, '2015-05-23 13:35:18', 'SQL Report', '1', '1100,500', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (51, 'Good Standing Chart', 'Good Standing Chart', 'Select tbl1.status, count(tbl1.id_no) from (SELECT distinct c.local_id_no id_no, trim(c.title || '' '' || c.sur_name ||
         '', '' || c.first_name || '' '' || c.other_names) "Full Name         ", b.item_code_name  "Pay Item                ",
         CASE WHEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),to_char(now(), ''YYYY-MM-DD''))>0 
       THEN ''Not In Good Standing'' ELSE ''In Good Standing'' END status
       FROM prs.prsn_names_nos c 
       LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (c.person_id = f.person_id and 
       (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 
       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id ) 
       WHERE((b.org_id = {:orgID}) AND (b.item_code_name ilike ''{:itmNm}'') AND (b.item_maj_type=''Balance Item'')) 
        ORDER BY c.local_id_no) tbl1
       GROUP BY tbl1.status', 'Internal Payments', 1, '2015-05-28 17:53:11', 1, '2015-06-19 06:54:23', 'SQL Report', '1', '1100,500', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (54, 'Monthly Visitor Traffic Details', 'Monthly Visitor Traffic Details', 'SELECT  det.visitor_classfctn "Visitor Classification", 
  CASE WHEN det.customer_id <= 0 and det.person_id <= 0 THEN det.visitor_name_desc 
           WHEN det.person_id>0 THEN prs.get_prsn_surname(det.person_id) || '' ('' || prs.get_prsn_loc_id(det.person_id) || '')'' 
            ELSE scm.get_cstmr_splr_name(det.customer_id) END "Visitor               ", 
            CASE WHEN det.date_time_in != '''' THEN 
        to_char(to_timestamp(det.date_time_in,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') 
        ELSE to_char(to_timestamp(hdr.event_date,''YYYY-MM-DD  HH24:MI:SS''),''DD-Mon-YYYY  HH24:MI:SS'') END "Date In       ",
            CASE WHEN det.date_time_out != '''' THEN to_char(to_timestamp(det.date_time_out,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') ELSE '''' END "Date Out      "
  FROM attn.attn_attendance_recs_hdr hdr, attn.attn_attendance_recs det
  where  hdr.recs_hdr_id = det.recs_hdr_id
  and '''' || coalesce(det.visitor_classfctn ,''-1'') = coalesce(NULLIF(''{:visClas}'',''''), '''' || coalesce(det.visitor_classfctn,''-1''))
  and hdr.org_id = {:orgID}
  and to_timestamp(hdr.event_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
  and to_timestamp(hdr.event_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
  order by 1
', 'Events And Attendance', 1, '2015-05-29 04:57:57', 1, '2015-05-29 04:59:51', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (61, 'Members in Good Standing Chart', 'Members in Good Standing Chart', 'Select tbl1.status, count(tbl1.id_no) from (SELECT distinct c.local_id_no id_no, trim(c.title || '' '' || c.sur_name ||
         '', '' || c.first_name || '' '' || c.other_names) "Full Name         ", b.item_code_name  "Pay Item                ",
         CASE WHEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),to_char(now(), ''YYYY-MM-DD''))>0 
       THEN ''Not In Good Standing'' ELSE ''In Good Standing'' END status
       FROM prs.prsn_names_nos c 
       LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (c.person_id = f.person_id and 
       (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 
       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id ) 
       WHERE((b.org_id = {:orgID}) AND (b.item_code_name ilike ''{:itmNm}'') AND (b.item_maj_type=''Balance Item'')) 
        ORDER BY c.local_id_no) tbl1
       GROUP BY tbl1.status', 'Basic Person Data', 1, '2015-06-02 07:28:52', 1, '2015-06-04 07:54:06', 'SQL Report', '1', '1100,500', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (60, 'Members in Good Standing Details', 'Members in Good Standing Details', 'SELECT distinct '''''''' || c.local_id_no "ID No.             ", trim(c.title || '' '' || c.sur_name ||
         '', '' || c.first_name || '' '' || c.other_names) "Full Name         ",
 CASE WHEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),to_char(now(), ''YYYY-MM-DD''))>0
 THEN ''Not In Good Standing'' ELSE ''In Good Standing'' END status, ped.data_col6 practice,
(select org.get_grade_name(pg.grade_id)) Grade
       FROM prs.prsn_names_nos c  left outer join prs.prsn_extra_data ped on ped.person_id = c.person_id 
  left outer join pasn.prsn_grades pg on c.person_id = pg.person_id
       LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (c.person_id = f.person_id and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 
       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id ) 
       WHERE((b.org_id = {:orgID}) AND (b.item_code_name ilike ''{:itmNm}'') AND (b.item_maj_type=''Balance Item'')) 
        ORDER BY 1', 'Basic Person Data', 1, '2015-06-02 07:27:57', 1, '2015-06-09 07:53:37', 'SQL Report', '1', '', '0', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (28, 'Automatic Database Backup', 'Automatic Database Backup', ' @echo off
SET datestr=%Date:~0,4%%Date:~5,2%%Date:~8,2%%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,3% 
   echo datestr is %datestr%
    
   set BACKUP_FILE={:backup_dir}\{:dbase_name}_%datestr%.backup
   echo backup file name is %BACKUP_FILE%
   SET PGPASSWORD={:db_password}
   echo on
cd /D {:pg_dmp_dir}

pg_dump.exe --host {:host_name} --port {:portnum} --username postgres --format tar --blobs --verbose --file "%BACKUP_FILE%" {:dbase_name}

forfiles -p "{:backup_dir}" -s -m *.* -d -5 -c "cmd /c del @path"', 'System Administration', 4, '2014-05-06 16:53:47', 1, '2015-07-12 05:22:07', 'Command Line Script', '1', '', '', '', '', '', 'None', 'None', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (57, 'Technical Divisions Details', 'Technical Divisions Details', 'select div_code_name "division                  ", '''''''' || local_id_no as "ID No.       ",
  title||'' ''||first_name||'' ''||other_names||'' ''||sur_name as "Full Name                 ", gender,  data_col6 practice,
data_col9 "Work Place Name", data_col10 "Work Place Location",
(select org.get_grade_name(pg.grade_id)) Grade, res_address, pstl_addrs, email, cntct_no_tel, cntct_no_mobl, 
       cntct_no_fax                    
  from prs.prsn_names_nos pnn left outer join prs.prsn_extra_data ped on ped.person_id = pnn.person_id 
  left outer join pasn.prsn_grades pg on pnn.person_id = pg.person_id
  left outer join pasn.prsn_divs_groups pdg 
  on  pnn.person_id = pdg.person_id 
  inner join org.org_divs_groups odg on pdg.div_id = odg.div_id
  and (coalesce(pdg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and 
  (pdg.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))
  and gst.get_pssbl_val(odg.div_typ_id) = ''Technical Division''
  AND '''' || coalesce(pdg.div_id,-1) = coalesce(NULLIF(''{:dv_id}'',''''), '''' || coalesce(pdg.div_id,-1))
  order by 1
', 'Basic Person Data', 1, '2015-05-29 05:12:35', 1, '2015-06-04 09:52:23', 'SQL Report', '1', '', '1', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (62, 'Person Type Distribution', 'Person Type Distribution', 'SELECT (SELECT z.prsn_type FROM pasn.prsn_prsntyps z WHERE (z.person_id = a.person_id) 
ORDER BY z.valid_end_date DESC, z.valid_start_date DESC LIMIT 1 OFFSET 0), count(a.person_id)
  FROM prs.prsn_names_nos a 
  WHERE a.org_id=1
  GROUP BY 1
  ORDER BY 1;', 'Basic Person Data', 1, '2015-06-05 08:48:32', 1, '2015-06-05 08:48:32', 'SQL Report', '0', '1100, 500', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (15, 'Daily Sales Comparison', 'Sales Comparison Per Period', 'SELECT SUM( scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''5Grand Total'')) 

"Grand Total", a.invc_date "Document Date", to_timestamp(a.invc_date,''YYYY-MM-DD HH24:MI:SS'')

 "_" FROM scm.scm_sales_invc_hdr a, sec.sec_users y 

WHERE ((a.approval_status ilike ''Approved'') AND (a.org_id = {:orgID}) AND (a.created_by=y.user_id)

 and (y.user_name ilike ''{:userNm}'') and (a.invc_type ilike ''{:docTyp}'') 

and (to_timestamp(a.invc_date,''YYYY-MM-DD HH24:MI:SS'') between 

to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

GROUP BY to_timestamp(a.invc_date,''YYYY-MM-DD HH24:MI:SS''), a.invc_date 

ORDER BY to_timestamp(a.invc_date,''YYYY-MM-DD HH24:MI:SS'')', 'Stores And Inventory Manager', 4, '2013-06-21 20:53:45', 1, '2015-06-10 10:52:24', 'SQL Report', '1', '800,400', '1,0', '', '', '', 'LINE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (11, 'Sales Per Period', 'Sales Per Period', 'SELECT a.invc_hdr_id "_", a.invc_number "Document No.   ",

y.user_name "Sales Agent", scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''5Grand Total'') "Grand Total", 

scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''6Total Payments Received'') "Amount Received ", scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''7Change/Balance'') 

"Outstanding Amount", to_char(to_timestamp(a.invc_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') "Document Date" FROM scm.scm_sales_invc_hdr a, 

sec.sec_users y WHERE ((a.approval_status ilike ''Approved'') AND (a.org_id = {:orgID}) AND 

(a.created_by=y.user_id) and (y.user_name ilike ''{:userNm}'') and (a.invc_type ilike ''{:docTyp}'') 

and (to_timestamp(a.invc_date,''YYYY-MM-DD HH24:MI:SS'') between 

to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

ORDER BY a.invc_hdr_id ASC

/*

 a.invc_type "Document Type ", 

, scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''1Initial 

Amount'') "Basic Amount"

scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''2Taxl'') 

"Tax Amount",scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''3Discount'') 

"Discount",scm.get_doc_smry_typ_amnt(a.invc_hdr_id, a.invc_type, ''4Extra Charge'') "Special Charge 

",*/', 'Stores And Inventory Manager', 1, '2013-06-17 21:20:20', 1, '2015-06-10 10:52:32', 'SQL Report', '1', '', '', '3,4,5', '', '3,4,5', 'HTML', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (63, 'Auto-Convert Applicant to Registered Member', 'Auto-Convert Applicant to Registered Member', 'select pasn.auto_cnvrt_prsntype({:orgID},''Applicant'',''Registered Member'',''Admission'','''', {:msgID}, {:usrID})', 'Basic Person Data', 1, '2015-06-15 18:45:05', 1, '2015-06-16 11:06:15', 'SQL Report', '1', '', '0', '', '', '', 'None', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (64, 'Merge Trading Partners', 'Merge Trading Partners', 'select accb.merge_trade_partners({:prntpartner},{:childpartner},{:msgID},{:usrID},''data_col9'')', 'Accounting', 1, '2015-06-15 21:26:14', 1, '2015-06-17 14:36:36', 'SQL Report', '1', '', '0', '', '', '', 'None', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (8, 'Pay Items Monthly Summary Per Date Range', 'Internal  Payments Detail Per Date Range', 'SELECT a.item_id "3", b.item_code_name 
"Item Name   ", SUM(a.amount_paid) "Amount Paid", 
to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''Mon YYYY'') "Month         ", 
to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY'') "_",
 sec.get_usr_name(a.created_by) "Created By"
FROM (pay.pay_itm_trnsctns a LEFT OUTER JOIN org.org_pay_items b ON a.item_id = 
b.item_id) LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id 
WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 
c.other_names) ilike ''%'') and (b.org_id ={:orgID}) 
AND (b.item_code_name ilike ''{:itemNm}'') and 
(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 
to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 
to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')))
AND a.created_by=COALESCE(NULLIF({:rcvdBy},-1), a.created_by)
GROUP BY a.item_id, b.item_code_name, to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY''),  
to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),
''Mon YYYY''), a.paymnt_date, 6
 ORDER BY to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''MM YYYY''),  b.item_code_name', 'Internal Payments', 1, '2013-06-17 16:30:45', 1, '2015-06-16 14:31:24', 'SQL Report', '1', '', '1', '2', '', '2', 'HTML', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (40, 'Person Data', '', 'select '''''''' || local_id_no, title||'' ''||first_name||'' ''||other_names||'' ''||sur_name as "Full Name                                                ", 
(select org.get_grade_name(pg.grade_id)) Grade, 
(select org.get_job_name(pj.job_id)) job, ppt.prsn_type "Person Type", ppt.prn_typ_asgnmnt_rsn "Assignment Reason",
to_char(to_timestamp(ppt.valid_start_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') "Start Date ", (select org.get_div_name(pdg.div_id)) "Division",
 (org.get_pos_name(pstn.position_id)) "Position", gender, marital_status, date_of_birth, place_of_birth, religion, 
       res_address, pstl_addrs, email, '''''''' || cntct_no_tel, '''''''' || cntct_no_mobl, 
       '''''''' || cntct_no_fax, img_location, hometown, nationality/*, pnn.person_id, pg.grade_id, pdg.div_id,pstn.position_id, pj.job_id, ppt.prsntype_id*/
  FROM prs.prsn_names_nos pnn 
  left outer join pasn.prsn_grades pg on pnn.person_id = pg.person_id
  left outer join pasn.prsn_jobs pj on pnn.person_id = pj.person_id
  left outer join pasn.prsn_prsntyps ppt on pnn.person_id = ppt.person_id
  left outer join pasn.prsn_divs_groups pdg on pnn.person_id = pdg.person_id
  left outer join pasn.prsn_positions pstn on pnn.person_id = pstn.person_id
  left outer join prs.prsn_extra_data ped on ped.person_id = pnn.person_id 
  where coalesce('''' || pnn.local_id_no) = coalesce(NULLIF(''{:pers_id}'',''''), '''' || pnn.local_id_no)
  AND (coalesce('''' || ped.data_col9) = coalesce(NULLIF(''{:instu_nm}'',''''), '''' || ped.data_col9) 
or scm.get_cstmr_splr_name(pnn.lnkd_firm_org_id)=coalesce(NULLIF(''{:instu_nm}'',''''), scm.get_cstmr_splr_name(pnn.lnkd_firm_org_id)))
  AND '''' || coalesce(pg.grade_id,-1) = coalesce(NULLIF(''{:grd_id}'',''''), '''' || coalesce(pg.grade_id,-1))/*Grades*/
  AND (coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pg.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))
  AND '''' || coalesce(pj.job_id,-1) = coalesce(NULLIF(''{:jb_id}'',''''), '''' || coalesce(pj.job_id,-1))/*Jobs*/
  AND (coalesce(pj.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pj.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pj.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pj.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))  
  AND '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))/*Person Types*/
  AND (coalesce(ppt.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( ppt.valid_end_date is null 
  OR to_timestamp(COALESCE(NULLIF(''{:asAtDate}'',''''),to_char(NOW(),''YYYY-MM-DD'')),''YYYY-MM-DD'')
  between to_timestamp(ppt.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(ppt.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))   
AND (CASE WHEN ''{:fromDate}'' ='''' THEN 1 
          WHEN to_timestamp(COALESCE(NULLIF(''{:fromDate}'',''''),to_char(NOW(),''YYYY-MM-DD'')),''YYYY-MM-DD'')
    <=to_timestamp(ppt.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') THEN 1
    ELSE 0 END)=1
  AND '''' || coalesce(pdg.div_id,-1) = coalesce(NULLIF(''{:dv_id}'',''''), '''' || coalesce(pdg.div_id,-1))/*Divisions and Groups*/
  AND (coalesce(pdg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pdg.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))     
  AND '''' || coalesce(pstn.position_id,-1) = coalesce(NULLIF(''{:pstn_id}'',''''), '''' || coalesce(pstn.position_id,-1))/*Positions*/
  AND (coalesce(pstn.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pstn.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pstn.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pstn.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))     
  AND '''' || coalesce(ppt.prn_typ_asgnmnt_rsn ,''-1'') = coalesce(NULLIF(''{:pstntyp_rsn}'',''''), '''' || coalesce(ppt.prn_typ_asgnmnt_rsn,''-1''))
 ORDER BY 1
', 'Basic Person Data', 1, '2015-05-17 17:50:01', 1, '2015-06-23 10:09:26', 'SQL Report', '1', '', '0', '', '', '', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (65, 'Daily Volume of Sales', '', 'SELECT  tbl1.dte, tbl1.mnth "Day", SUM(tbl1.amnt) "Amount" 
 FROM (SELECT to_char(to_timestamp(a.invc_date,''YYYY-MM-DD''),''YYYY-MM-DD'') dte, 
 to_char(to_timestamp(a.invc_date,''YYYY-MM-DD''),''YYYY-MON-DD'') mnth, 
 sum((b.doc_qty * b.unit_selling_price)) amnt
 FROM scm.scm_sales_invc_hdr a, scm.scm_sales_invc_det b WHERE 
 a.invc_hdr_id = b.invc_hdr_id
 and a.approval_status=''Approved'' 
 and ((a.invc_number ilike ''%'') AND (a.org_id = {:orgID}) and invc_type = ''Sales Invoice'')
 and to_timestamp(a.invc_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
 and  to_timestamp(a.invc_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
 group by to_char(to_timestamp(a.invc_date,''YYYY-MM-DD''),''YYYY-MM-DD''), to_char(to_timestamp(a.invc_date,''YYYY-MM-DD''),''YYYY-MON-DD'')
 UNION
 SELECT to_char(to_timestamp(b.paymnt_date,''YYYY-MM-DD''),''YYYY-MM-DD'') dte, 
 to_char(to_timestamp(b.paymnt_date,''YYYY-MM-DD''),''YYYY-MON-DD'') mnth, 
 sum((b.amount_paid)) amnt 
 FROM org.org_pay_items a, pay.pay_itm_trnsctns b WHERE 
 a.item_id = b.item_id
 and b.pymnt_vldty_status = ''VALID'' and b.src_py_trns_id <=0 
 and b.pay_trns_id NOT IN (Select z.intnl_pay_trns_id FROM accb.accb_payments z WHERE z.intnl_pay_trns_id>0) 
 and ((a.item_code_name ilike ''%(Payment)%'') AND (a.org_id = {:orgID}) and a.item_min_type = ''Bills/Charges'')
 and to_timestamp(b.paymnt_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
 and  to_timestamp(b.paymnt_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
 group by to_char(to_timestamp(b.paymnt_date,''YYYY-MM-DD''),''YYYY-MM-DD''), to_char(to_timestamp(b.paymnt_date,''YYYY-MM-DD''),''YYYY-MON-DD'')) tbl1 
 GROUP BY 1,2
 ORDER BY 1', 'Stores And Inventory Manager', 1, '2015-06-16 10:30:11', 1, '2015-06-17 19:47:05', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'LINE CHART', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (47, 'Monthly Volume of Sales', '', 'SELECT  tbl1.dte, tbl1.mnth "Month", SUM(tbl1.amnt) "Amount" 
 FROM (SELECT to_char(to_timestamp(a.invc_date,''YYYY-MM''),''YYYY-MM'') dte, 
 to_char(to_timestamp(a.invc_date,''YYYY-MM''),''YYYY-MON'') mnth, 
 sum((b.doc_qty * b.unit_selling_price)) amnt
 FROM scm.scm_sales_invc_hdr a, scm.scm_sales_invc_det b WHERE 
 a.invc_hdr_id = b.invc_hdr_id
 and a.approval_status=''Approved'' 
 and ((a.invc_number ilike ''%'') AND (a.org_id = {:orgID}) and invc_type = ''Sales Invoice'')
 and to_timestamp(a.invc_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
 and  to_timestamp(a.invc_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
 group by to_char(to_timestamp(a.invc_date,''YYYY-MM''),''YYYY-MM''), to_char(to_timestamp(a.invc_date,''YYYY-MM''),''YYYY-MON'')
  UNION
 SELECT to_char(to_timestamp(b.paymnt_date,''YYYY-MM''),''YYYY-MM'') dte, 
 to_char(to_timestamp(b.paymnt_date,''YYYY-MM''),''YYYY-MON'') mnth, 
 sum((b.amount_paid)) amnt 
 FROM org.org_pay_items a, pay.pay_itm_trnsctns b WHERE 
 a.item_id = b.item_id
 and b.pymnt_vldty_status = ''VALID'' and b.src_py_trns_id <=0 
 and b.pay_trns_id NOT IN (Select z.intnl_pay_trns_id FROM accb.accb_payments z WHERE z.intnl_pay_trns_id>0) 
 and ((a.item_code_name ilike ''%(Payment)%'') AND (a.org_id = {:orgID}) and a.item_min_type = ''Bills/Charges'')
 and to_timestamp(b.paymnt_date,''YYYY-MM-DD'')>=to_timestamp(''{:fromDate}'',''YYYY-MM-DD'') 
 and  to_timestamp(b.paymnt_date,''YYYY-MM-DD'')<=to_timestamp(''{:toDate}'',''YYYY-MM-DD'') 
 group by to_char(to_timestamp(b.paymnt_date,''YYYY-MM''),''YYYY-MM''), to_char(to_timestamp(b.paymnt_date,''YYYY-MM''),''YYYY-MON'')) tbl1 
 GROUP BY 1,2
 ORDER BY 1', 'Stores And Inventory Manager', 1, '2015-05-23 15:42:21', 1, '2015-06-17 19:47:32', 'SQL Report', '1', '800,400', '1,2', '', '', '', 'LINE CHART', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (70, 'Import/Overwrite Customer Names', 'Import/Overwrite Customer Names', 'UPDATE scm.scm_cstmr_suplr SET 
 cust_sup_name = ''{:newValColB}''
 WHERE cust_sup_name = ''{:orgnValColA}'' and org_id={:orgID};

UPDATE gst.gen_stp_lov_values SET 
 pssbl_value = ''{:newValColB}''
 WHERE pssbl_value = ''{:orgnValColA}'' 
 and value_list_id = gst.get_lov_id(''Schools/Organisations/Institutions'');

UPDATE prs.prsn_extra_data SET data_col9 = ''{:newValColB}''
 WHERE data_col9  = ''{:orgnValColA}'';
', 'Accounting', 1, '2015-06-18 11:06:50', 1, '2015-06-18 11:35:35', 'Import/Overwrite Data from Excel', '1', '', '0', '', '', '', 'None', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (52, 'Good Standing Details', 'Good Standing Details', 'SELECT distinct '''''''' || c.local_id_no "ID No.             ", trim(c.title || '' '' || c.sur_name ||
         '', '' || c.first_name || '' '' || c.other_names) "Full Name         ",
 CASE WHEN pay.get_ltst_blsitm_bals(c.person_id,org.get_payitm_id(b.item_code_name),to_char(now(), ''YYYY-MM-DD''))>0
 THEN ''Not In Good Standing'' ELSE ''In Good Standing'' END status, ped.data_col6 practice,
(select org.get_grade_name(pg.grade_id)) Grade
       FROM prs.prsn_names_nos c  left outer join prs.prsn_extra_data ped on ped.person_id = c.person_id 
  left outer join pasn.prsn_grades pg on c.person_id = pg.person_id
       LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (c.person_id = f.person_id and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 
       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id ) 
       WHERE((b.org_id = {:orgID}) AND (b.item_code_name ilike ''{:itmNm}'') AND (b.item_maj_type=''Balance Item'')) 
        ORDER BY 1', 'Internal Payments', 1, '2015-05-28 18:13:13', 1, '2015-06-19 06:54:09', 'SQL Report', '1', '', '0', '', '', '', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (29, 'Items Sold Report', 'Items Sold Report', 'SELECT row_number() OVER (ORDER BY SUM(b.doc_qty) DESC, c.item_desc ASC) AS "No.  "
        , '''''''' || c.item_code "Item Code         ", 
        c.item_desc   "Item Description      ", 
        SUM(b.doc_qty) "QTY      ", 
        d.uom_name "UOM   ", 
        b.unit_selling_price "Selling Price", 
        SUM(b.doc_qty * b.unit_selling_price) "Total Amount     "
        FROM scm.scm_sales_invc_hdr a, sec.sec_users y, scm.scm_sales_invc_det b, 
        inv.inv_itm_list c, inv.unit_of_measure d
        WHERE ((a.invc_hdr_id = b.invc_hdr_id AND b.itm_id = c.item_id AND c.base_uom_id = d.uom_id) 
        AND (b.is_itm_delivered =''1'') AND (a.org_id = {:orgID}) AND 
        (b.created_by=y.user_id) and (a.invc_type ilike ''{:doctype}'') 
        and (to_timestamp(b.creation_date,''YYYY-MM-DD HH24:MI:SS'') between 
        to_timestamp(''{:strtDte}'',''DD-Mon-YYYY HH24:MI:SS'') AND 
        to_timestamp(''{:endDte}'',''DD-Mon-YYYY HH24:MI:SS''))) 
        GROUP BY c.item_desc, b.itm_id, c.item_code, d.uom_name, b.unit_selling_price
        ORDER BY SUM(b.doc_qty) DESC, c.item_desc ASC', 'Stores And Inventory Manager', 4, '2014-06-12 07:43:49', 1, '2015-07-12 05:22:43', 'SQL Report', '1', '', '', '6', '', '6', 'MICROSOFT EXCEL', 'Landscape', 'TABULAR', '', 'None', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (12, 'Profit & Loss', 'Profit & Loss', 'WITH RECURSIVE suborg(accnt_id, accnt_num, accnt_name, is_prnt_accnt, accnt_type, control_account_id, has_sub_ledgers, amount, totals, depth, path, cycle, space) AS 

      ( 

      SELECT e.accnt_id, e.accnt_num, e.accnt_name, e.is_prnt_accnt, e.accnt_type, 

      (CASE WHEN e.prnt_accnt_id<=0 THEN e.control_account_id ELSE e.prnt_accnt_id END) control_account_id, e.has_sub_ledgers,

 CASE WHEN e.accnt_type = ''R'' THEN 

accb.get_prd_usr_trns_sum(e.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

ELSE -1*accb.get_prd_usr_trns_sum(e.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

END amount, 

CASE WHEN e.accnt_type = ''R'' THEN 

accb.prnt_usr_trns_sum_rcsv(e.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'')  

ELSE -1*accb.prnt_usr_trns_sum_rcsv(e.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

END totals,1, ARRAY[e.accnt_id], false, '''' opad 

      FROM accb.accb_chart_of_accnts e 

      WHERE (CASE WHEN e.prnt_accnt_id<=0 THEN e.control_account_id ELSE e.prnt_accnt_id END) = -1 

      and (e.org_id = 1) and (e.accnt_type = ''R'' or e.accnt_type = ''EX'')

      UNION ALL        

      SELECT d.accnt_id, d.accnt_num, d.accnt_name, d.is_prnt_accnt, d.accnt_type, 

      (CASE WHEN d.prnt_accnt_id<=0 THEN d.control_account_id ELSE d.prnt_accnt_id END) control_account_id, d.has_sub_ledgers,

 CASE WHEN d.accnt_type = ''R'' THEN 

accb.get_prd_usr_trns_sum(d.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

ELSE -1*accb.get_prd_usr_trns_sum(d.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

END amount, 

CASE WHEN d.accnt_type = ''R'' THEN 

accb.prnt_usr_trns_sum_rcsv(d.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'')  

ELSE -1*accb.prnt_usr_trns_sum_rcsv(d.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 

END totals, sd.depth + 1, 

      path || d.accnt_id, 

      d.accnt_id = ANY(path), space || ''           '' 

      FROM 

      accb.accb_chart_of_accnts AS d, 

      suborg AS sd 

      WHERE (CASE WHEN d.prnt_accnt_id<=0 THEN d.control_account_id ELSE d.prnt_accnt_id END) = sd.accnt_id AND NOT cycle

       and (d.org_id = 1) and (d.accnt_type = ''R'' or d.accnt_type = ''EX'')) 

      SELECT accnt_id "_", space||accnt_num ||''.''|| accnt_name "Account Name.                                                               ",

 amount "Amount               ", totals "TOTALS                ", is_prnt_accnt "_", depth "_", path "_", cycle "_" 

      FROM suborg WHERE (COALESCE(amount,0) !=0 or COALESCE(totals,0) !=0)

      ORDER BY path

/*SELECT a.accnt_id "_", 
a.accnt_num "Account No.         ", 
a.accnt_name "Account Name.              ",
 

CASE WHEN a.accnt_type = ''R'' THEN 
accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 


ELSE -1*accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'',
 ''{:toDate} 23:59:59'') 
END "Amount             ", 


CASE WHEN a.accnt_type = ''R'' THEN 
accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'')  


ELSE -1*accb.prnt_usr_trns_sum_rcsv(a.accnt_id, ''{:fromDate} 
00:00:00'', ''{:toDate} 23:59:59'') 
END "TOTALS                ", 
a.is_prnt_accnt "_" 


FROM accb.accb_chart_of_accnts a 
WHERE ((a.org_id = {:orgID}) and (a.is_prnt_accnt=''1'' or 
accb.get_prd_usr_trns_sum(a.accnt_id, ''{:fromDate} 00:00:00'', ''{:toDate} 23:59:59'') IS NOT NULL) 
and (a.accnt_type = ''R'' or a.accnt_type = ''EX'')) 


ORDER BY a.accnt_typ_id, a.accnt_num

*/', 'Accounting', 4, '2013-06-18 16:59:08', 1, '2015-07-26 22:11:03', 'SQL Report', '1', '', '', '2', '', '2,3', 'HTML', 'Portrait', 'None', '', 'Pipe(|)', 'Standard Process Runner', '1');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (74, 'Seminar/Event Income/Expenditure', 'Seminar/Event Income/Expenditure', 'SELECT b.pssbl_value_desc "Major Category ", 

       a.cost_classfctn "Sub-Category ", 

       sum(a.no_of_persons) || '' x '' || MAX(a.unit_cost) "No. of Participants ", 

       (CASE WHEN b.pssbl_value_desc=''1Income'' THEN 1 ELSE -1 END)*SUM(a.no_of_persons*a.unit_cost) "Total Amount (GHS) "

       FROM attn.attn_attendance_costs a, gst.gen_stp_lov_values b 

       WHERE((a.recs_hdr_id = {:rgstr_id}) 

       AND (a.cost_comments ilike ''%'') 

       AND (a.cost_classfctn = b.pssbl_value and b.value_list_id = gst.get_lov_id(''Event Cost Categories''))) 

       GROUP BY 1,2

       ORDER BY 1,2', 'Events And Attendance', 1, '2015-08-06 15:54:38', 1, '2015-08-12 10:57:15', 'SQL Report', '1', '0', '', '3', '', '3', 'HTML', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (76, 'Pay Run SSF Returns Report', 'Pay Run SSF Returns Report', 'SELECT tbl1.* FROM 

(SELECT 

c.local_id_no id_num, 

prs.get_prsn_ntnl_id(c.person_id,''SSNIT'') ssnit_number,

trim(c.title || '' '' || 

c.first_name || '' '' || c.other_names || '' '' || c.sur_name) full_name, 

b.item_code_name item_name, SUM(a.amount_paid) amnt_paid, 

to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') 

payment_date, b.pay_run_priority 

FROM (pay.pay_itm_trnsctns a 

LEFT OUTER JOIN org.org_pay_items b ON a.item_id = b.item_id) 

LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id 

WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 

c.other_names) ilike ''%'') 

and (b.org_id ={:orgID}) 

and (to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

AND c.local_id_no IN ({:IDNos})

AND (b.item_code_name ilike ''{:itemNm}'' or b.item_code_name ilike ''%Basic%Salary%'') 

AND pay.get_blsitem_bals(c.person_id,org.get_payitm_id(''Total SSNIT Contribution''),substr(a.paymnt_date,1,10)) <> 0

GROUP BY 1,2,3,4,6,7

 
UNION
    

SELECT distinct c.local_id_no "ID No.    ", 

prs.get_prsn_ntnl_id(c.person_id,''SSNIT'') ssnit_number,

trim(c.title ||

 '' '' || c.first_name || '' '' || c.other_names || '' '' || c.sur_name) "Full Name         ", 

 b.item_code_name  "Pay Item                ",         

a.bals_amount "Amount  ",          

to_char(to_timestamp(a.bals_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') payment_date, b.pay_run_priority 
           

FROM prs.prsn_names_nos c 
           

LEFT OUTER JOIN pay.pay_balsitm_bals a ON (a.person_id = c.person_id and (to_timestamp(a.bals_date,''YYYY-MM-DD 00:00:00'') between to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')))              
           

LEFT OUTER JOIN org.org_pay_items b ON (a.bals_itm_id = b.item_id) 
           

WHERE((b.org_id = 1) and (b.item_code_name ilike ''%SSNIT%'') 
    

AND a.bals_amount<>0 

AND (c.local_id_no IN ({:IDNos})) AND (b.item_maj_type=''Balance Item'' and b.balance_type ilike ''Non%''))) tbl1
           

ORDER BY  1, 7, 4 ASC

', 'Internal Payments', 1, '2015-08-15 05:16:51', 1, '2015-08-15 13:58:26', 'SQL Report', '1', '', '0', '2,3,4,5,6,7,8,9,10', '', '2,3,4,5,6,7,8,9,10', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Customised Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (77, 'Pay Run PAYE Returns Report', 'Pay Run PAYE Returns Report', 'SELECT tbl1.full_name "Name of Employee (1)",

    tbl1.tax_number "Employee Tax I.D. No. (2)", 

    tbl1.basic_salary "Basic Wage or Salary Paid (3)",

    tbl1.total_allowances "Total Allowance Paid (4)",

    tbl1.basic_salary+tbl1.total_allowances "Total Emoluments (5)",

    tbl1.ssf_employee "Social Security Contribution (6)",

    tbl1.monthly_relief "Monthly Deductible Relief (7)",

    tbl1.basic_salary+tbl1.total_allowances-tbl1.ssf_employee-tbl1.monthly_relief "Net Taxable Pay (Col.5 less Col.6 & 7) (8)",

    tbl1.paye_val "Tax Deductible (9)",

    tbl1.paye_val "Tax Deducted and Paid to GRA (10)",

    '''' "Remarks (11)",

    tbl1.payment_date mt 

FROM (SELECT 

    c.local_id_no id_num, 

    trim(c.title || '' '' || c.first_name || '' '' || c.other_names || '' '' || c.sur_name) full_name,

    prs.get_prsn_ntnl_id(c.person_id,''TIN'') tax_number, 

    SUM(a.amount_paid) basic_salary, 

    (SELECT COALESCE(SUM(c.amount_paid),0) FROM pay.pay_itm_trnsctns c, org.org_pay_items d WHERE c.person_id = a.person_id     and c.item_id = 

    d.item_id and d.item_min_type=''Earnings'' and d.item_code_name NOT IN (''Basic Monthly Salary'') 

    and (to_timestamp(c.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

    to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

    to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) total_allowances,

    (SELECT COALESCE(SUM(c.amount_paid),0) FROM pay.pay_itm_trnsctns c, org.org_pay_items d WHERE c.person_id = a.person_id     and c.item_id = 

    d.item_id and d.item_code_name IN (''Old SSF Employee (5.0%)'',''SSF Employee (5.5%)'') 

    and (to_timestamp(c.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

    to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

    to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) ssf_employee,

    0 monthly_relief,

    (SELECT COALESCE(SUM(c.amount_paid),0) FROM pay.pay_itm_trnsctns c, org.org_pay_items d WHERE c.person_id = a.person_id     and c.item_id = 

    d.item_id and d.item_code_name IN (''PAYE Income Tax'') 

    and (to_timestamp(c.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

    to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

    to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) paye_val,

    to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''Mon-YYYY'') 

    payment_date

    FROM (pay.pay_itm_trnsctns a 

    LEFT OUTER JOIN org.org_pay_items b ON a.item_id = 

    b.item_id) 

    LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id  

WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 

    c.other_names) ilike ''%'') 

    and (b.org_id ={:orgID}) 

    and (to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 

    to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 

    to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 

    AND c.local_id_no IN (c.local_id_no)

    AND b.item_code_name ilike ''Basic Monthly Salary'' GROUP BY 1,2,3,5,6,7,8,9) tbl1

    WHERE tbl1.paye_val <>0 

    ORDER BY  tbl1.id_num ASC

', 'Internal Payments', 1, '2015-08-15 09:32:16', 1, '2015-08-15 18:37:57', 'SQL Report', '1', '', '0', '2,3,4,5,6,7,8,9', '', '2,3,4,5,6,7,8,9', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Customised Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (75, 'Event Attendance Register', 'Event Attendance Register', 'SELECT attnd_rec_id mt, recs_hdr_id m1, person_id m2, 

    '''''''' || prs.get_prsn_loc_id(a.person_id) "ID No.", 

      CASE WHEN a.customer_id <= 0 and a.person_id <= 0 THEN a.visitor_name_desc 

           WHEN a.person_id>0 THEN prs.get_prsn_surname(a.person_id) || '' ('' || prs.get_prsn_loc_id(a.person_id) || '')'' 

            ELSE scm.get_cstmr_splr_name(a.customer_id) END "Name of Participant ", 

      CASE WHEN a.date_time_in != '''' THEN to_char(to_timestamp(a.date_time_in,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY         HH24:MI:SS'') ELSE '''' END "Time In ", 

      CASE WHEN a.date_time_out != '''' THEN to_char(to_timestamp(a.date_time_out,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY         HH24:MI:SS'') ELSE '''' END "Time Out ",

      CASE WHEN a.is_present=''1'' THEN ''YES'' ELSE ''NO'' END "Present? ", 

    scm.get_cstmr_splr_name(a.sponsor_id) "Linked Firm",

      tbl1.invc_number "Invoice No.", 

    COALESCE(tbl1.invoice_amnt,0) "Inv. Ttl.", 

    COALESCE(tbl1.amnt_paid,0) "Amnt. Paid", 

    COALESCE(tbl1.amnt_left,0) "Balance", 

    a.attn_comments "Remarks",

      a.visitor_classfctn "Classification ", a.no_of_persons m3, 0 m4, a.customer_id m5, a.sponsor_id m6

  FROM attn.attn_attendance_recs a

  LEFT OUTER JOIN (SELECT DISTINCT w.check_in_id, w.doc_num, y.invc_number, w.customer_id, 

            scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''5Grand Total'') invoice_amnt,

            scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''6Total Payments Received'')+

        scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''8Deposits'') amnt_paid,

            scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''9Actual_Change/Balance'') amnt_left 

    FROM hotl.checkins_hdr w 

    LEFT OUTER JOIN hotl.service_types d ON (w.service_type_id=d.service_type_id )

    LEFT OUTER JOIN hotl.rooms b ON (w.service_det_id = b.room_id)

    LEFT OUTER JOIN scm.scm_sales_invc_hdr y ON ((w.check_in_id = y.other_mdls_doc_id or     (w.prnt_chck_in_id=y.other_mdls_doc_id and y.other_mdls_doc_id>0))

    and (w.doc_type=y.other_mdls_doc_type or (w.prnt_doc_typ=y.other_mdls_doc_type and w.prnt_doc_typ != ''''))) 

    WHERE (w.sponsor_id IN (select c.cust_sup_id from scm.scm_cstmr_suplr c where c.cust_sup_name ilike ''%'') or 

    w.customer_id IN (select c.cust_sup_id from scm.scm_cstmr_suplr c where c.cust_sup_name ilike ''%'')) 

    and COALESCE(d.org_id, 1)=1 and w.doc_type IN (''Booking'',''Check-In'') 

    and w.fclty_type IN (''Event'')) tbl1  ON (a.customer_id = tbl1.customer_id)

   WHERE((a.recs_hdr_id = {:rgstr_id}) AND ((CASE WHEN a.customer_id <= 0 and a.person_id <= 0 THEN a.visitor_name_desc 

           WHEN a.person_id>0 THEN prs.get_prsn_surname(a.person_id) || '' ('' || prs.get_prsn_loc_id(a.person_id) || '')'' 

            ELSE scm.get_cstmr_splr_name(a.customer_id)||scm.get_cstmr_splr_name(a.sponsor_id) END) ilike ''%'')) 

    ORDER BY 5, 4, 1



            ', 'Events And Attendance', 1, '2015-08-12 10:56:18', 1, '2015-08-15 19:57:20', 'SQL Report', '1', '', '0', '10,11,12', '', '10,11,12', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (78, 'Mass Bookings/Reservations Report', 'Mass Bookings/Reservations Report', 'SELECT DISTINCT  a.doc_num "Document No.  ", 

    b.room_name || '' ('' || d.service_type_name || '')'' "Facility No. ", 

    scm.get_cstmr_splr_name(a.customer_id) "Occupant / Participant (Sponsee) ",

    to_char(to_timestamp(a.start_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY'') "Start Date           ", 

    to_char(to_timestamp(a.end_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY'') "End Date         ",

    scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''5Grand Total'') "Invoice Amount ",

    scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''6Total Payments Received'')+

    scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''8Deposits'') "Amount Paid ",

    scm.get_doc_smry_typ_amnt(y.invc_hdr_id,''Sales Invoice'',''9Actual_Change/Balance'') "Amount Left ",

    a.doc_type "Remark        ",

    a.check_in_id mt,y.invc_number m1, a.start_date m2, a.sponsor_site_id m3,  

    scm.get_cstmr_splr_name(a.sponsor_id)|| '' ('' ||scm.get_cstmr_splr_site_name(a.sponsor_site_id)||'')'' m4,

    z.billing_address m5,

    z.ship_to_address m6,

    z.contact_person_name m7,

    z.contact_nos m8,

    z.email m9    

FROM hotl.checkins_hdr a  

LEFT OUTER JOIN hotl.service_types d ON (a.service_type_id=d.service_type_id ) 

LEFT OUTER JOIN hotl.rooms b ON (a.service_det_id = b.room_id) 

LEFT OUTER JOIN scm.scm_sales_invc_hdr y ON ((a.check_in_id = y.other_mdls_doc_id or 

(a.prnt_chck_in_id=y.other_mdls_doc_id and y.other_mdls_doc_id>0))

and (a.doc_type=y.other_mdls_doc_type or (a.prnt_doc_typ=y.other_mdls_doc_type and a.prnt_doc_typ != '''')))  

LEFT OUTER JOIN scm.scm_cstmr_suplr_sites z ON (a.sponsor_site_id = z.cust_sup_site_id) 

WHERE /*(a.doc_status=''Reserved'' or a.doc_status=''Checked-In'' or a.doc_status=''Ordered'')  

    and*/ d.org_id={:orgID} and a.doc_type IN (''Reservation'',''Check-In'') 

    and a.sponsor_id = {:cstmrID}

    and a.fclty_type IN (''Room/Hall'',''Field/Yard'',''Event'') 

    and (to_timestamp(a.start_date,''YYYY-MM-DD HH24:MI:SS'') between 

    to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND /*--{:fromDate}*/ 

    to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')) /*--{:toDate}*/  

ORDER BY a.start_date  ', 'Hospitality Management', 1, '2015-08-15 20:21:05', 1, '2015-08-17 16:43:07', 'SQL Report', '1', '', '0', '5,6,7', '', '5,6,7', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Customised Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (59, 'Pay Run Master Sheet Report', 'Pay Run Master Sheet Report', 'SELECT tbl1.* FROM 

(SELECT 

c.local_id_no id_num, 

trim(c.title || '' '' || 

c.first_name || '' '' || c.other_names || '' '' || c.sur_name) full_name, 

substring(b.local_classfctn, position(''.'' in b.local_classfctn)+1)

item_name, SUM(a.amount_paid) amnt_paid, 

to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY HH24:MI:SS'') 

payment_date, b.pay_run_priority 

FROM (pay.pay_itm_trnsctns a 

LEFT OUTER JOIN org.org_pay_items b ON a.item_id = 
b.item_id) 

LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id 


WHERE((trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || 
c.other_names) ilike ''%'') 

and (b.org_id ={:orgID}) 

and 
(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS'') between 
to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND 
to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))) 


AND c.local_id_no IN ({:IDNos})
AND b.local_classfctn ilike ''%Staff Payroll Item%'' GROUP BY 1,2,3,5,6 

 
UNION
    

SELECT distinct c.local_id_no "ID No.    ", 

trim(c.title ||

 '' '' || c.first_name || '' '' || c.other_names || '' '' || c.sur_name) "Full Name         ", 

 b.item_code_name  "Pay Item                ",         

a.bals_amount "Amount  ",          

to_char(to_timestamp(a.bals_date,''YYYY-MM-DD''),''DD-Mon-YYYY'') payment_date, b.pay_run_priority 
           

FROM prs.prsn_names_nos c 
           

LEFT OUTER JOIN pay.pay_balsitm_bals a ON (a.person_id = c.person_id and (to_timestamp(a.bals_date,''YYYY-MM-DD 00:00:00'') between to_timestamp(''{:fromDate} 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(''{:toDate} 23:59:59'',''YYYY-MM-DD HH24:MI:SS'')))              
           

LEFT OUTER JOIN org.org_pay_items b ON (a.bals_itm_id = b.item_id) 
           

WHERE((b.org_id = 1) and (b.local_classfctn ilike ''%Staff Balance Item%'') 
    

AND (c.local_id_no IN ({:IDNos})) AND (b.item_maj_type=''Balance Item'' and b.balance_type ilike ''Non%'')) 
           ) tbl1
           ORDER BY  1 DESC, 6, 3 ASC

', 'Internal Payments', 1, '2015-05-31 19:19:06', 1, '2015-08-18 21:52:36', 'SQL Report', '1', '', '0', '2,3,4,5,6,7,8,9,10', '', '2,3,4,5,6,7,8,9,10', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Customised Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (79, 'Company Bills (Dues/Levies) Report', 'Company Bills (Dues/Levies) Report', 'Select 

 tbl1.id_no, 

 tbl1.fullnm,

 tbl1.item_code_name,

 SUM(tbl1.amnt) amnt,

 600 " ",

 tbl1.Grade,

 tbl1.Division,

 tbl1.cmpny,

 b.billing_address

 from (select distinct pnn.local_id_no id_no, 

 pnn.title||'' ''||pnn.first_name||'' ''||pnn.other_names||'' ''||pnn.sur_name fullnm, 

 org.get_grade_name(pg.grade_id) Grade, 

 org.get_div_name(pdg.div_id) Division, 

       b.item_code_name,

       coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0) amnt,

       b.pay_run_priority, ped.data_col9 cmpny

  FROM prs.prsn_names_nos pnn 

  LEFT OUTER JOIN pasn.prsn_grades pg on pnn.person_id = pg.person_id

  LEFT OUTER JOIN pasn.prsn_divs_groups pdg on (pnn.person_id = pdg.person_id and (now()

    between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

  LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (pnn.person_id = f.person_id 

  and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 

  LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id)

  LEFT OUTER JOIN prs.prsn_extra_data ped ON (ped.person_id = pnn.person_id)

  where (coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pg.valid_end_date is null OR (now()

    between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

   and (b.org_id = 1)  

  AND (b.item_code_name ilike ''%'' || to_char(now(),''YYYY'')||''%'' or b.item_code_name IN(

''Welfare Fund Balance'',

''Professional Stamp Amount Balance'',

''Engineering Center, Emergency Power Fund Balance'',

''Building Levy Balance''))

  AND coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)>0

  AND (b.item_maj_type=''Balance Item'') AND b.local_classfctn ilike ''%Membership Balance Item'')

  UNION

  select distinct pnn.local_id_no, 

  pnn.title||'' ''||pnn.first_name||'' ''||pnn.other_names||'' ''||pnn.sur_name as "Full Name                                                ", 

  org.get_grade_name(pg.grade_id) Grade, 

 org.get_div_name(pdg.div_id) Division,

       ''Arreas from Previous Years''  "Pay Item                ", 

       SUM(coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)) "Amount  ",

       MAX(b.pay_run_priority) " ", ped.data_col9 cmpny

  FROM prs.prsn_names_nos pnn 

  left outer join pasn.prsn_grades pg on pnn.person_id = pg.person_id

  LEFT OUTER JOIN pasn.prsn_divs_groups pdg on (pnn.person_id = pdg.person_id and (now()

    between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

  LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (pnn.person_id = f.person_id and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 

       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id)

       LEFT OUTER JOIN prs.prsn_extra_data ped ON (ped.person_id = pnn.person_id)

  where (coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pg.valid_end_date is null OR (now()

    between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) and (b.org_id = 1)  

  AND (b.item_code_name NOT ilike ''%'' || to_char(now(),''YYYY'')||''%'' and b.item_code_name ilike ''Annual%Dues%'')

  AND coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)>0

  AND (b.item_maj_type=''Balance Item'') AND b.local_classfctn ilike ''%Membership Balance Item'')

  GROUP BY 1,2,3,4,5,8) tbl1 

  LEFT OUTER JOIN scm.scm_cstmr_suplr a ON (tbl1.cmpny = a.cust_sup_name)

  LEFT OUTER JOIN scm.scm_cstmr_suplr_sites b ON (a.cust_sup_id = b.cust_supplier_id 

  and b.cust_sup_site_id = (SELECT MIN(c.cust_sup_site_id) 

  FROM scm.scm_cstmr_suplr_sites c WHERE c.cust_supplier_id=b.cust_supplier_id))

  WHERE tbl1.cmpny = coalesce(NULLIF(''{:instu_nm}'',''''), tbl1.cmpny)

 GROUP BY 1, 2,3,5,6,7,8,9

 ORDER BY 1,3,5,6

', 'Basic Person Data', 1, '2015-08-17 15:06:45', 1, '2015-08-19 13:01:20', 'SQL Report', '1', '', '0', '', '', '', 'MICROSOFT EXCEL', 'Landscape', 'None', '', 'None', 'Customised Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (43, 'Class Distribution', 'Class Distribution', 'select (select grade_code_name from org.org_grades og where og.grade_id = pg.grade_id) grade, count(1) countt 
  

from pasn.prsn_grades pg
  

WHERE /*'''' || coalesce(pg.grade_id,-1) = '''' || coalesce(pg.grade_id,-1)Grades
  AND*/ 

(coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null 

and ( pg.valid_end_date is null OR ((SELECT NOW())
  between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))))
  group by 1;', 'Basic Person Data', 1, '2015-05-19 08:00:18', 1, '2015-08-20 20:11:15', 'SQL Report', '1', '1100, 500', '0,1', '', '', '', 'COLUMN CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (80, 'Person Distribution by Workplace (Top 20)', 'Person Distribution by Workplace (Top 20)

', 'select COALESCE(NULLIF(scm.get_cstmr_splr_name(pnn.lnkd_firm_org_id),''''),''Unknown Workplace'') "Workplace Name ", count(1) "No. of Persons" 

FROM prs.prsn_names_nos pnn 

left outer join pasn.prsn_prsntyps ppt
 on (pnn.person_id = ppt.person_id
  and now() between to_timestamp(ppt.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 
AND to_timestamp(ppt.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')) 

where '''' || coalesce(ppt.prsn_type,''-1'') = coalesce(NULLIF(''{:pstntyp}'',''''), '''' || coalesce(ppt.prsn_type,''-1''))
  

group by 1 order by 2 Desc LIMIT 20 offset 0;', 'Basic Person Data', 1, '2015-08-20 20:12:07', 1, '2015-08-20 20:47:22', 'SQL Report', '1', '1100, 600', '0,1', '', '', '', 'PIE CHART', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');
INSERT INTO rpt.rpt_reports (report_id, report_name, report_desc, rpt_sql_query, owner_module, created_by, creation_date, last_update_by, last_update_date, rpt_or_sys_prcs, is_enabled, cols_to_group, cols_to_count, cols_to_sum, cols_to_average, cols_to_no_frmt, output_type, portrait_lndscp, rpt_layout, imgs_col_nos, csv_delimiter, process_runner, is_seeded_rpt) VALUES (81, 'Top 20 Dues Debtors Distribution', 'Top 20 Dues Debtors Distribution', 'select row_number() over (order by round(SUM(tbl2.amnt),2) DESC) "No.", 

COALESCE(NULLIF(tbl2.cmpny,''''),''Unknown Company'') "Name of Company", 

round(SUM(tbl2.amnt),2) "Amount Owing" 

FROM (Select 

 tbl1.id_no, 

 tbl1.fullnm,

 tbl1.item_code_name,

 SUM(tbl1.amnt) amnt,

 600 " ",

 tbl1.Grade,

 tbl1.Division,

 tbl1.cmpny,

 b.billing_address

 from (select distinct pnn.local_id_no id_no, 

 pnn.title||'' ''||pnn.first_name||'' ''||pnn.other_names||'' ''||pnn.sur_name fullnm, 

 org.get_grade_name(pg.grade_id) Grade, 

 org.get_div_name(pdg.div_id) Division, 

       b.item_code_name,

       coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0) amnt,

       b.pay_run_priority, ped.data_col9 cmpny

  FROM prs.prsn_names_nos pnn 

  LEFT OUTER JOIN pasn.prsn_grades pg on pnn.person_id = pg.person_id

  LEFT OUTER JOIN pasn.prsn_divs_groups pdg on (pnn.person_id = pdg.person_id and (now()

    between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

  LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (pnn.person_id = f.person_id 

  and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 

  LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id)

  LEFT OUTER JOIN prs.prsn_extra_data ped ON (ped.person_id = pnn.person_id)

  where (coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pg.valid_end_date is null OR (now()

    between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

   and (b.org_id = 1)  

  AND (b.item_code_name ilike ''%'' || to_char(now(),''YYYY'')||''%'' or b.item_code_name IN(

''Welfare Fund Balance'',

''Professional Stamp Amount Balance'',

''Engineering Center, Emergency Power Fund Balance'',

''Building Levy Balance''))

  AND coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)>0

  AND (b.item_maj_type=''Balance Item'') AND b.local_classfctn ilike ''%Membership Balance Item'')

  UNION

  select distinct pnn.local_id_no, 

  pnn.title||'' ''||pnn.first_name||'' ''||pnn.other_names||'' ''||pnn.sur_name as "Full Name                                                ", 

  org.get_grade_name(pg.grade_id) Grade, 

 org.get_div_name(pdg.div_id) Division,

       ''Arreas from Previous Years''  "Pay Item                ", 

       SUM(coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)) "Amount  ",

       MAX(b.pay_run_priority) " ", ped.data_col9 cmpny

  FROM prs.prsn_names_nos pnn 

  left outer join pasn.prsn_grades pg on pnn.person_id = pg.person_id

  LEFT OUTER JOIN pasn.prsn_divs_groups pdg on (pnn.person_id = pdg.person_id and (now()

    between to_timestamp(pdg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pdg.valid_end_date,''YYYY-MM-DD HH24:MI:SS'')))

  LEFT OUTER JOIN pasn.prsn_bnfts_cntrbtns f ON (pnn.person_id = f.person_id and (now() between to_timestamp(f.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') AND to_timestamp(f.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) 

       LEFT OUTER JOIN org.org_pay_items b ON (b.item_id = f.item_id)

       LEFT OUTER JOIN prs.prsn_extra_data ped ON (ped.person_id = pnn.person_id)

  where (coalesce(pg.valid_start_date, to_char((select now()),''YYYY-MM-DD'')) is not null and ( pg.valid_end_date is null OR (now()

    between to_timestamp(pg.valid_start_date,''YYYY-MM-DD HH24:MI:SS'') 

  AND to_timestamp(pg.valid_end_date,''YYYY-MM-DD HH24:MI:SS''))) and (b.org_id = 1)  

  AND (b.item_code_name NOT ilike ''%'' || to_char(now(),''YYYY'')||''%'' and b.item_code_name ilike ''Annual%Dues%'')

  AND coalesce(pay.get_ltst_blsitm_bals(pnn.person_id,org.get_payitm_id(b.item_code_name),to_char(now(),''YYYY-MM-DD'')),0)>0

  AND (b.item_maj_type=''Balance Item'') AND b.local_classfctn ilike ''%Membership Balance Item'')

  GROUP BY 1,2,3,4,5,8) tbl1 

  LEFT OUTER JOIN scm.scm_cstmr_suplr a ON (tbl1.cmpny = a.cust_sup_name)

  LEFT OUTER JOIN scm.scm_cstmr_suplr_sites b ON (a.cust_sup_id = b.cust_supplier_id 

  and b.cust_sup_site_id = (SELECT MIN(c.cust_sup_site_id) 

  FROM scm.scm_cstmr_suplr_sites c WHERE c.cust_supplier_id=b.cust_supplier_id))

  WHERE tbl1.cmpny = coalesce(NULLIF(''{:instu_nm}'',''''), tbl1.cmpny)

 GROUP BY 1, 2,3,5,6,7,8,9

 ORDER BY 1,3,5,6) tbl2 group by 2 order by 3 DESC LIMIT 20 OFFSET 0

', 'Basic Person Data', 1, '2015-08-20 21:04:26', 1, '2015-08-20 21:52:21', 'SQL Report', '1', '1100,600', '1', '2', '', '2', 'MICROSOFT EXCEL', 'Portrait', 'None', '', 'None', 'Standard Process Runner', '0');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_REPORTS_REPORT_ID_SEQ', 85 );
COMMIT;
