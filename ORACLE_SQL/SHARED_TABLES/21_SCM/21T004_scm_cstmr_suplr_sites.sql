
DROP TABLE SCM.SCM_CSTMR_SUPLR_SITES  CASCADE CONSTRAINTS PURGE;


CREATE TABLE SCM.SCM_CSTMR_SUPLR_SITES (
   CUST_SUPPLIER_ID      NUMBER,
   CONTACT_PERSON_NAME   VARCHAR2 (200 BYTE),
   CONTACT_NOS           VARCHAR2 (200 BYTE),
   EMAIL                 VARCHAR2 (100 BYTE),
   CREATED_BY            NUMBER,
   CREATION_DATE         VARCHAR2 (50 BYTE),
   LAST_UPDATE_BY        NUMBER,
   LAST_UPDATE_DATE      VARCHAR2 (50 BYTE),
   SITE_NAME             VARCHAR2 (200 BYTE),
   SITE_DESC             VARCHAR2 (200 BYTE),
   BANK_NAME             VARCHAR2 (200 BYTE),
   BANK_BRANCH           VARCHAR2 (200 BYTE),
   BANK_ACCNT_NUMBER     VARCHAR2 (200 BYTE),
   WTH_TAX_CODE_ID       NUMBER,
   DISCOUNT_CODE_ID      NUMBER,
   CUST_SUP_SITE_ID      NUMBER NOT NULL,
   BILLING_ADDRESS       VARCHAR2 (300 BYTE),
   SHIP_TO_ADDRESS       VARCHAR2 (300 BYTE),
   SWIFT_CODE            VARCHAR2 (100),
   NATIONALITY           VARCHAR2 (100),
   NATIONAL_ID_TYP       VARCHAR2 (100),
   ID_NUMBER             VARCHAR2 (100),
   DATE_ISSUED           VARCHAR2 (100),
   EXPIRY_DATE           VARCHAR2 (100),
   OTHER_INFO            VARCHAR2 (100),
   IS_ENABLED            VARCHAR2 (1) DEFAULT '1' NOT NULL,
   IBAN_NUMBER           VARCHAR2 (100),
   ACCNT_CUR_ID          INTEGER DEFAULT -1 NOT NULL,
   CONSTRAINT PK_CUST_SUP_SITE_ID PRIMARY KEY (CUST_SUP_SITE_ID)
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

CREATE INDEX SCM.IDX_SITE_DESC
   ON SCM.SCM_CSTMR_SUPLR_SITES (SITE_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX SCM.IDX_SITE_NAME
   ON SCM.SCM_CSTMR_SUPLR_SITES (SITE_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE SCM.SCM_CUSTMR_SUPLIER_SITE_ID_SEQ;

CREATE SEQUENCE SCM.SCM_CUSTMR_SUPLIER_SITE_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER SCM.SCM_CUSTMR_SUPLIER_SITE_ID_TRG
   BEFORE INSERT
   ON SCM.SCM_CSTMR_SUPLR_SITES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.CUST_SUP_SITE_ID IS NULL)
DECLARE
   V_ID   SCM.SCM_CSTMR_SUPLR_SITES.CUST_SUP_SITE_ID%TYPE;
BEGIN
   SELECT   SCM.SCM_CUSTMR_SUPLIER_SITE_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.CUST_SUP_SITE_ID := V_ID;
END SCM_CUSTMR_SUPLIER_SITE_ID_TRG;