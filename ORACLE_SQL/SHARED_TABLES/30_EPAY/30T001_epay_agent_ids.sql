/* Formatted on 12-18-2018 10:19:59 AM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_AGENT_IDS CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_AGENT_IDS (
   ROW_ID             NUMBER NOT NULL,
   AGENT_NO           VARCHAR2 (10) NOT NULL,
   AGENT_NAME         VARCHAR2 (200),
   REGION             VARCHAR2 (100),
   CITY               VARCHAR2 (100),
   TELCO              VARCHAR2 (10),
   MSISDN             VARCHAR2 (50),
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (21),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (21),
   ID_TYPE            VARCHAR2 (50),
   ID_NUMBER          VARCHAR2 (100),
   AGENT_NO_REGNID    VARCHAR2 (20),
   SERIAL_NO          NUMBER DEFAULT -1 NOT NULL,
   STATUS             VARCHAR2 (10) DEFAULT 'ACTIVE' NOT NULL,
   DIGITAL_ADDRESS    VARCHAR2 (50),
   TELCO_MM_ID        NUMBER
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

ALTER TABLE EPAY.EPAY_AGENT_IDS
ADD(  CONSTRAINT PK_AGI_ROW_ID PRIMARY KEY (ROW_ID ));

DROP SEQUENCE EPAY.EPAY_AGENT_IDS_SEQ;

CREATE SEQUENCE EPAY.EPAY_AGENT_IDS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_AGENT_IDS_TRG
   BEFORE INSERT
   ON EPAY.EPAY_AGENT_IDS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ROW_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_AGENT_IDS.ROW_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_AGENT_IDS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ROW_ID := V_ID;
END EPAY_AGENT_IDS_TRG;