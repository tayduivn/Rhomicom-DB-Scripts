/* Formatted on 10/6/2014 7:37:32 PM (QP5 v5.126.903.23003) */
CREATE TABLE HOSP.VITALS (VTL_ID             NUMBER NOT NULL,
                          APPNTMNT_ID        NUMBER,
                          WEIGHT             NUMBER (*, 2),
                          HEIGHT             NUMBER (*, 2),
                          BP_SYSTLC          NUMBER (*, 2),
                          BP_DIASTLC         NUMBER (*, 2),
                          PULSE              NUMBER (*, 2),
                          RESPTN             NUMBER (*, 2),     -- RESPIRATION
                          BODY_TMP           NUMBER (*, 2),
                          OXGN_SATN          NUMBER (*, 2), -- OXYGEN SATURATION
                          HEAD_CIRCUM        NUMBER (*, 2), -- HEAD CIRCUMFERENCE
                          WAIST_CIRCUM       NUMBER (*, 2), -- WAIST CIRCUMFERENCE
                          BMI                NUMBER (*, 2), -- BODY MASS INDEX
                          BMI_STATUS         VARCHAR (20 BYTE),
                          BOWEL_ACTN         VARCHAR (500 BYTE), -- BOWEL ACTION
                          CMNTS              VARCHAR (500 BYTE),   -- COMMENTS
                          CREATED_BY         VARCHAR (21 BYTE),
                          CREATION_DATE      VARCHAR (21 BYTE),
                          LAST_UPDATE_BY     VARCHAR (21 BYTE),
                          LAST_UPDATE_DATE   VARCHAR (21 BYTE),
                          TMP_LOC            VARCHAR (50 BYTE))
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

CREATE UNIQUE INDEX HOSP.IDX_VTL_ID
   ON HOSP.VITALS (VTL_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE HOSP.VITALS ADD (
  CONSTRAINT PK_VTL_ID
 PRIMARY KEY
 (VTL_ID));

CREATE SEQUENCE HOSP.VITALS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER HOSP.VITALS_TRG
   BEFORE INSERT
   ON HOSP.VITALS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.VTL_ID IS NULL)
DECLARE
   V_ID   HOSP.VITALS.VTL_ID%TYPE;
BEGIN
   SELECT   HOSP.VITALS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.VTL_ID := V_ID;
END VITALS_TRG;