/* Formatted on 12-12-2018 4:10:09 PM (QP5 v5.126.903.23003) */
CREATE TABLE ALRT.ALRT_MSGS_SENT (
   msg_sent_id      NUMBER NOT NULL,
   to_list          CLOB,
   cc_list          CLOB,
   msg_body         CLOB,
   date_sent        VARCHAR2 (21),
   msg_sbjct        VARCHAR2 (400),
   report_id        NUMBER DEFAULT -1 NOT NULL,
   bcc_list         CLOB,
   person_id        NUMBER DEFAULT -1 NOT NULL,
   cstmr_spplr_id   NUMBER DEFAULT -1 NOT NULL,
   created_by       NUMBER DEFAULT -1 NOT NULL,
   creation_date    VARCHAR2 (21),
   alert_id         NUMBER DEFAULT -1 NOT NULL,
   sending_status   VARCHAR2 (1) DEFAULT '0' NOT NULL,
   err_msg          VARCHAR2 (400),
   attch_urls       CLOB,
   msg_type         VARCHAR2 (50)
)
TABLESPACE RHODB
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;

CREATE UNIQUE INDEX ALRT.IDX_MSG_SENT_ID
   ON ALRT.ALRT_MSGS_SENT (MSG_SENT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ALRT.ALRT_MSGS_SENT ADD (
  CONSTRAINT PK_MSG_SENT_ID
 PRIMARY KEY
 (MSG_SENT_ID));

CREATE SEQUENCE ALRT.ALRT_MSGS_SENT_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ALRT.ALRT_MSGS_SENT_TRG
   BEFORE INSERT
   ON ALRT.ALRT_MSGS_SENT
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.MSG_SENT_ID IS NULL)
DECLARE
   V_ID   ALRT.ALRT_MSGS_SENT.MSG_SENT_ID%TYPE;
BEGIN
   SELECT   ALRT.ALRT_MSGS_SENT_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.MSG_SENT_ID := V_ID;
END ALRT_MSGS_SENT_TRG;