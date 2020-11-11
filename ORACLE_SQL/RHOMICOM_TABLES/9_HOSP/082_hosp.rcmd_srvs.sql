/* Formatted on 10/6/2014 7:35:43 PM (QP5 v5.126.903.23003) */
CREATE TABLE HOSP.RCMD_SRVS (RCMD_SRV_ID        NUMBER,
                             CNSLTN_ID          NUMBER,
                             SRV_TYPE_ID        NUMBER,
                             CREATED_BY         NUMBER,
                             CREATION_DATE      VARCHAR2 (21 BYTE),
                             LAST_UPDATE_BY     VARCHAR2 (21 BYTE),
                             LAST_UPDATE_DATE   VARCHAR2 (21 BYTE),
                             DOC_CMNTS          VARCHAR2 (500 BYTE),
                             SRVS_PRVDR_CMNTS   VARCHAR2 (500 BYTE),
                             DEST_APPNTMNT_ID   NUMBER)
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

CREATE UNIQUE INDEX HOSP.IDX_RCMD_SRV_ID
   ON HOSP.RCMD_SRVS (RCMD_SRV_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE HOSP.RCMD_SRVS ADD (
  CONSTRAINT PK_RCMD_SRV_ID
 PRIMARY KEY
 (RCMD_SRV_ID));

CREATE SEQUENCE HOSP.RCMD_SRVS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER HOSP.RCMD_SRVS_TRG
   BEFORE INSERT
   ON HOSP.RCMD_SRVS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.RCMD_SRV_ID IS NULL)
DECLARE
   V_ID   HOSP.RCMD_SRVS.RCMD_SRV_ID%TYPE;
BEGIN
   SELECT   HOSP.RCMD_SRVS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.RCMD_SRV_ID := V_ID;
END RCMD_SRVS_TRG;