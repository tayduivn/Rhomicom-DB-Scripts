/* Formatted on 10/6/2014 6:54:51 PM (QP5 v5.126.903.23003) */
CREATE TABLE ACA.ACA_CRSRS_N_THR_SBJCTS (
   CRSE_SBJCT_ID          NUMBER NOT NULL,
   COURSE_ID              NUMBER,
   SUBJECT_ID             NUMBER NOT NULL,
   CORE_OR_ELECTIVE       VARCHAR2 (10 BYTE) NOT NULL,
   IS_ENABLED             VARCHAR2 (1 BYTE),
   CREATED_BY             NUMBER NOT NULL,
   CREATION_DATE          VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY         NUMBER NOT NULL,
   LAST_UPDATE_DATE       VARCHAR2 (21 BYTE),
   WEIGHT_OR_CREDIT_HRS   NUMBER
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

CREATE UNIQUE INDEX ACA.IDX_CRSE_SBJCT_ID
   ON ACA.ACA_CRSRS_N_THR_SBJCTS (CRSE_SBJCT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ACA.ACA_CRSRS_N_THR_SBJCTS ADD (
  CONSTRAINT PK_CRSE_SBJCT_ID
 PRIMARY KEY
 (CRSE_SBJCT_ID));

CREATE SEQUENCE ACA.ACA_CRSRS_N_THR_SBJCTS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACA.ACA_CRSRS_N_THR_SBJCTS_TRG
   BEFORE INSERT
   ON ACA.ACA_CRSRS_N_THR_SBJCTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.CRSE_SBJCT_ID IS NULL)
DECLARE
   V_ID   ACA.ACA_CRSRS_N_THR_SBJCTS.CRSE_SBJCT_ID%TYPE;
BEGIN
   SELECT   ACA.ACA_CRSRS_N_THR_SBJCTS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.CRSE_SBJCT_ID := V_ID;
END ACA_CRSRS_N_THR_SBJCTS;