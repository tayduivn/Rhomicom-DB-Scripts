/* FORMATTED ON 12-18-2018 10:33:51 AM (QP5 V5.126.903.23003) */
DROP TABLE EPAY.EPAY_CATEGORY_INDICATORS CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_CATEGORY_INDICATORS (
   CATIND_ID          NUMBER NOT NULL,
   CATEGORY_ID        NUMBER,
   INDICATOR_ID       NUMBER,
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (21),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (21),
   COMMENTS            CLOB,
   CONSTRAINT CATIND_ID_PK PRIMARY KEY (CATIND_ID)
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

DROP SEQUENCE EPAY.EPAY_CATEGORY_INDICATORS_SEQ;

CREATE SEQUENCE EPAY.EPAY_CATEGORY_INDICATORS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_CATEGORY_INDICATORS_TRG
   BEFORE INSERT
   ON EPAY.EPAY_CATEGORY_INDICATORS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.CATIND_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_CATEGORY_INDICATORS.CATIND_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_CATEGORY_INDICATORS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.CATIND_ID := V_ID;
END EPAY_CATEGORY_INDICATORS_TRG;