/* Formatted on 10/6/2014 7:36:58 PM (QP5 v5.126.903.23003) */
CREATE TABLE HOSP.SRVS_TYPES (TYPE_ID            NUMBER NOT NULL,
                              TYPE_NAME          VARCHAR2 (200 BYTE),
                              TYPE_DESC          VARCHAR2 (300 BYTE),
                              CREATED_BY         VARCHAR2 (21 BYTE),
                              CREATION_DATE      VARCHAR2 (21 BYTE),
                              LAST_UPDATE_BY     VARCHAR2 (21 BYTE),
                              LAST_UPDATE_DATE   VARCHAR2 (21 BYTE),
                              SYS_CODE           VARCHAR2 (100 BYTE),       --
                              ITM_ID             NUMBER)
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

CREATE UNIQUE INDEX HOSP.IDX_TYPE_ID
   ON HOSP.SRVS_TYPES (TYPE_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE HOSP.SRVS_TYPES ADD (
  CONSTRAINT PK_TYPE_ID
 PRIMARY KEY
 (TYPE_ID));

CREATE SEQUENCE HOSP.SRVS_TYPES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER HOSP.SRVS_TYPES_TRG
   BEFORE INSERT
   ON HOSP.SRVS_TYPES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.TYPE_ID IS NULL)
DECLARE
   V_ID   HOSP.SRVS_TYPES.TYPE_ID%TYPE;
BEGIN
   SELECT   HOSP.SRVS_TYPES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.TYPE_ID := V_ID;
END SRVS_TYPES_TRG;