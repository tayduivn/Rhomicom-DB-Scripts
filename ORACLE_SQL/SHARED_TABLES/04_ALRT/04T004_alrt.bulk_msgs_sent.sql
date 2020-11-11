/* Formatted on 12-12-2018 4:41:48 PM (QP5 v5.126.903.23003) */
CREATE TABLE ALRT.BULK_MSGS_SENT (
   MSG_SENT_ID      NUMBER NOT NULL,
   BATCH_ID         NUMBER DEFAULT -1 NOT NULL,
   TO_LIST          CLOB,
   CC_LIST          CLOB,
   MSG_BODY         CLOB,
   DATE_SENT        VARCHAR2 (21),
   MSG_SBJCT        VARCHAR2 (400),
   BCC_LIST         CLOB,
   CREATED_BY       NUMBER DEFAULT -1 NOT NULL,
   CREATION_DATE    VARCHAR2 (21),
   SENDING_STATUS   VARCHAR2 (1) DEFAULT '0' NOT NULL,
   ERR_MSG          VARCHAR2 (400),
   ATTCH_URLS       CLOB,
   MSG_TYPE         VARCHAR2 (50)
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

CREATE UNIQUE INDEX ALRT.IDX_B_MSG_SENT_ID
   ON ALRT.BULK_MSGS_SENT (MSG_SENT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ALRT.BULK_MSGS_SENT ADD (
  CONSTRAINT PK_B_MSG_SENT_ID
 PRIMARY KEY
 (MSG_SENT_ID));

CREATE SEQUENCE ALRT.BULK_MSGS_SENT_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ALRT.BULK_MSGS_SENT_TRG
   BEFORE INSERT
   ON ALRT.BULK_MSGS_SENT
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.MSG_SENT_ID IS NULL)
DECLARE
   V_ID   ALRT.BULK_MSGS_SENT.MSG_SENT_ID%TYPE;
BEGIN
   SELECT   ALRT.BULK_MSGS_SENT_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.MSG_SENT_ID := V_ID;
END BULK_MSGS_SENT_TRG;