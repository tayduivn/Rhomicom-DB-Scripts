/* Formatted on 10/5/2014 7:41:40 PM (QP5 v5.126.903.23003) */
-- TABLE: PAY.PAY_ITM_SETS_HDR

-- DROP TABLE PAY.PAY_ITM_SETS_HDR;

CREATE TABLE PAY.PAY_ITM_SETS_HDR (
   HDR_ID             NUMBER NOT NULL,
   ITM_SET_NAME       VARCHAR2 (100),
   ITM_SET_DESC       VARCHAR2 (200),
   IS_ENABLED         VARCHAR2 (1),
   CREATION_DATE      VARCHAR2 (21) NOT NULL,
   CREATED_BY         NUMBER NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21) NOT NULL,
   ORG_ID             NUMBER,
   IS_DEFAULT         VARCHAR2 (1) DEFAULT 0 NOT NULL,
   USES_SQL           VARCHAR2 (1) DEFAULT '0' NOT NULL,
   SQL_QUERY          CLOB,
   CONSTRAINT PK_HDR_ID PRIMARY KEY (HDR_ID)
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

CREATE INDEX PAY.IDX_ITM_SET_DESC
   ON PAY.PAY_ITM_SETS_HDR (ITM_SET_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PAY.IDX_ITM_SET_NAME
   ON PAY.PAY_ITM_SETS_HDR (ITM_SET_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE SEQUENCE PAY.PAY_ITM_SETS_HDR_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER PAY.PAY_ITM_SETS_HDR_TRG
   BEFORE INSERT
   ON PAY.PAY_ITM_SETS_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.HDR_ID IS NULL)
DECLARE
   V_ID   PAY.PAY_ITM_SETS_HDR.HDR_ID%TYPE;
BEGIN
   SELECT   PAY.PAY_ITM_SETS_HDR_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.HDR_ID := V_ID;
END PAY_ITM_SETS_HDR_TRG;