/* Formatted on 10/6/2014 7:36:16 PM (QP5 v5.126.903.23003) */
CREATE TABLE HOSP.SRVS_PRVDRS (PRVDR_ID           NUMBER NOT NULL,
                               PRSN_ID            NUMBER,
                               SRVS_TYPE_ID       NUMBER,
                               START_DATE         VARCHAR (21 BYTE),
                               END_DATE           VARCHAR (21 BYTE),
                               CREATED_BY         VARCHAR (21 BYTE),
                               CREATION_DATE      VARCHAR (21 BYTE),
                               LAST_UPDATE_BY     VARCHAR (21 BYTE),
                               LAST_UPDATE_DATE   VARCHAR (21 BYTE),
                               PRVDR_GRP_ID       NUMBER)
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

CREATE UNIQUE INDEX HOSP.IDX_PRVDR_ID
   ON HOSP.SRVS_PRVDRS (PRVDR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE HOSP.SRVS_PRVDRS ADD (
  CONSTRAINT PK_PRVDR_ID
 PRIMARY KEY
 (PRVDR_ID));

CREATE SEQUENCE HOSP.SRVS_PRVDRS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER HOSP.SRVS_PRVDRS_TRG
   BEFORE INSERT
   ON HOSP.SRVS_PRVDRS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.PRVDR_ID IS NULL)
DECLARE
   V_ID   HOSP.SRVS_PRVDRS.PRVDR_ID%TYPE;
BEGIN
   SELECT   HOSP.SRVS_PRVDRS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.PRVDR_ID := V_ID;
END SRVS_PRVDRS_TRG;