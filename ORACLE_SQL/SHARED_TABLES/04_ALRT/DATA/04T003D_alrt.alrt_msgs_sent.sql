/* Formatted on 12-12-2018 4:27:24 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ALRT.ALRT_MSGS_SENT --data-only --column-inserts psdc_live > data.sql
*/

INSERT INTO alrt.alrt_msgs_sent (msg_sent_id,
                                 to_list,
                                 cc_list,
                                 msg_body,
                                 date_sent,
                                 msg_sbjct,
                                 report_id,
                                 bcc_list,
                                 person_id,
                                 cstmr_spplr_id,
                                 created_by,
                                 creation_date,
                                 alert_id,
                                 sending_status,
                                 err_msg,
                                 attch_urls,
                                 msg_type)
  VALUES   (1,
            'richarda.mensah@gmail.com',
            NULL,
            'Work on Workflow 12345',
            '2013-10-18 23:37:37',
            'Work on WorkFlow',
            1,
            NULL,
            -1,
            -1,
            -1,
            NULL,
            -1,
            '0',
            '',
            '',
            '');

INSERT INTO alrt.alrt_msgs_sent (msg_sent_id,
                                 to_list,
                                 cc_list,
                                 msg_body,
                                 date_sent,
                                 msg_sbjct,
                                 report_id,
                                 bcc_list,
                                 person_id,
                                 cstmr_spplr_id,
                                 created_by,
                                 creation_date,
                                 alert_id,
                                 sending_status,
                                 err_msg,
                                 attch_urls,
                                 msg_type)
  VALUES   (2,
            'ghana@gmail.com',
            'mark@yahoo.com',
            'Work on Workflow 12345',
            '2013-10-17 12:23:12',
            'Workflow 12345 requires your attention',
            1,
            NULL,
            -1,
            -1,
            -1,
            NULL,
            -1,
            '0',
            '',
            '',
            '');


COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ALRT', 'ALRT_MSGS_SENT_SEQ', 3 );
COMMIT;