/* Formatted on 10/6/2014 6:55:21 PM (QP5 v5.126.903.23003) */
CREATE TABLE ACA.ACA_PRSNS_AC_STTNGS_SBJCTS (
   AC_STTNGS_SBJCTS_ID   NUMBER NOT NULL,
   ACDMC_STTNGS_ID       NUMBER,
   SUBJECT_ID            NUMBER,
   CREATED_BY            NUMBER NOT NULL,
   CREATION_DATE         VARCHAR2 (21 BYTE) NOT NULL
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

CREATE UNIQUE INDEX ACA.IDX_AC_STTNGS_SBJCTS_ID
   ON ACA.ACA_PRSNS_AC_STTNGS_SBJCTS (AC_STTNGS_SBJCTS_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ACA.ACA_PRSNS_AC_STTNGS_SBJCTS ADD (
  CONSTRAINT PK_AC_STTNGS_SBJCTS_ID
 PRIMARY KEY
 (AC_STTNGS_SBJCTS_ID ));

CREATE SEQUENCE ACA.ACA_PRSNS_AC_STTNGS_SBJCTS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACA.ACA_PRSNS_AC_STTNGS_SBJCTS_TRG
   BEFORE INSERT
   ON ACA.ACA_PRSNS_AC_STTNGS_SBJCTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.AC_STTNGS_SBJCTS_ID IS NULL)
DECLARE
   V_ID   ACA.ACA_PRSNS_AC_STTNGS_SBJCTS.AC_STTNGS_SBJCTS_ID%TYPE;
BEGIN
   SELECT   ACA.ACA_PRSNS_AC_STTNGS_SBJCTS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.AC_STTNGS_SBJCTS_ID := V_ID;
END ACA_PRSNS_AC_STTNGS_SBJCTS_TRG;