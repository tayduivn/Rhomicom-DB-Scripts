/* Formatted on 10/5/2014 7:21:24 PM (QP5 v5.126.903.23003) */
-- TABLE: PAY.PAY_GLOBAL_VALUES_DET
-- DROP TABLE PAY.PAY_GLOBAL_VALUES_DET;

CREATE TABLE PAY.PAY_GLOBAL_VALUES_DET (
   VALUE_DET_ID          NUMBER NOT NULL,
   GLOBAL_VALUE_HDR_ID   NUMBER,
   CRITERIA_VAL_ID       NUMBER,
   CRITERIA_TYPE         VARCHAR2 (100),
   NUM_VALUE             NUMBER,
   VALID_START_DATE      VARCHAR2 (21),
   VALID_END_DATE        VARCHAR2 (21),
   CREATED_BY            NUMBER NOT NULL,
   CREATION_DATE         VARCHAR2 (21),
   LAST_UPDATE_BY        NUMBER NOT NULL,
   LAST_UPDATE_DATE      VARCHAR2 (21) NOT NULL,
   CONSTRAINT PK_VAL_DET_ID PRIMARY KEY (VALUE_DET_ID)
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

CREATE INDEX PAY.IDX_GLBL_VAL_HDR_ID
   ON PAY.PAY_GLOBAL_VALUES_DET (GLOBAL_VALUE_HDR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE PAY.PAY_GLOBAL_VALUES_DET_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER PAY.PAY_GLOBAL_VALUES_DET_TRG
   BEFORE INSERT
   ON PAY.PAY_GLOBAL_VALUES_DET
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.VALUE_DET_ID IS NULL)
DECLARE
   V_ID   PAY.PAY_GLOBAL_VALUES_DET.VALUE_DET_ID%TYPE;
BEGIN
   SELECT   PAY.PAY_GLOBAL_VALUES_DET_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.VALUE_DET_ID := V_ID;
END PAY_GLOBAL_VALUES_DET_TRG;