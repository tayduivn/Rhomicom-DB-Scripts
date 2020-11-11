/* Formatted on 25/09/2014 12:39:07 (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_POST_TRNS_MSGS

-- DROP TABLE ACCB.ACCB_POST_TRNS_MSGS;

CREATE TABLE ACCB.ACCB_POST_TRNS_MSGS (
   MSG_ID             NUMBER NOT NULL,
   LOG_MESSAGES       CLOB,
   PROCESS_TYP        VARCHAR2 (100),
   PROCESS_ID         NUMBER,
   CREATED_BY         NUMBER NOT NULL,
   CREATION_DATE      VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21) NOT NULL,
   CONSTRAINT PK_MSG_ID PRIMARY KEY (MSG_ID)
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


CREATE INDEX ACCB.IDX_PROCESS_ID_MSG
   ON ACCB.ACCB_POST_TRNS_MSGS (PROCESS_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PROCESS_TYP
   ON ACCB.ACCB_POST_TRNS_MSGS (PROCESS_TYP)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_POST_TRNS_MSGS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_POST_TRNS_MSGS_TRG
   BEFORE INSERT
   ON ACCB.ACCB_POST_TRNS_MSGS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.MSG_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_POST_TRNS_MSGS.MSG_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_POST_TRNS_MSGS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.MSG_ID := V_ID;
END ACCB_POST_TRNS_MSGS_TRG;