/* Formatted on 10/6/2014 8:54:12 PM (QP5 v5.126.903.23003) */
-- TABLE: SCM.SCM_RCVBL_AMNT_SMMRYS

-- DROP TABLE SCM.SCM_RCVBL_AMNT_SMMRYS;

CREATE TABLE SCM.SCM_RCVBL_AMNT_SMMRYS (
   RCVBL_SMMRY_ID          NUMBER NOT NULL,
   RCVBL_SMMRY_TYPE        VARCHAR2 (100 BYTE) NOT NULL, -- 1INITIAL AMOUNT (INCREASE REVENUE/CUSTMR ADVANCE PAYMENTS - INCREASE RECEIVABLE)...
   RCVBL_SMMRY_DESC        VARCHAR2 (200 BYTE),
   RCVBL_SMMRY_AMNT        NUMBER,
   CODE_ID_BEHIND          NUMBER,
   SRC_RCVBL_TYPE          VARCHAR2 (100 BYTE),
   SRC_RCVBL_HDR_ID        NUMBER,
   CREATED_BY              NUMBER,
   CREATION_DATE           VARCHAR2 (21 BYTE),
   LAST_UPDATE_BY          NUMBER,
   LAST_UPDATE_DATE        VARCHAR2 (21 BYTE),
   AUTO_CALC               VARCHAR2 (1 BYTE) DEFAULT '1' NOT NULL,
   INCRS_DCRS1             VARCHAR2 (15),
   RVNU_ACNT_ID            NUMBER,
   INCRS_DCRS2             VARCHAR2 (15),
   RCVBL_ACNT_ID           NUMBER,
   APPLD_PREPYMNT_DOC_ID   NUMBER,
   ORGNL_LINE_ID           NUMBER DEFAULT -1 NOT NULL,
   VALIDTY_STATUS          VARCHAR2 (10 BYTE) DEFAULT '1' NOT NULL,
   ENTRD_CURR_ID           NUMBER,
   FUNC_CURR_ID            NUMBER,
   ACCNT_CURR_ID           NUMBER,
   FUNC_CURR_RATE          NUMBER,
   ACCNT_CURR_RATE         NUMBER,
   FUNC_CURR_AMOUNT        NUMBER,
   ACCNT_CURR_AMNT         NUMBER
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

ALTER TABLE SCM.SCM_RCVBL_AMNT_SMMRYS
ADD(  CONSTRAINT PK_RCVBL_SMMRY_ID PRIMARY KEY (RCVBL_SMMRY_ID ));


COMMENT ON COLUMN SCM.SCM_RCVBL_AMNT_SMMRYS.RCVBL_SMMRY_TYPE IS
'1Initial Amount (Increase Revenue/Custmr Advance Payments - Increase Receivable)
2Tax (Increase Sales Taxes Payable - Increase Receivable)
3Discount (Increase Sales Discounts Decrease Receivable)
4Extra Charge (Increase Extra Revenue Increase Receivable)
5Applied Prepayment (Decrease Customer Advance Payments Decrease Receivable)
6Grand Total (No Accounting)';


-- INDEX: SCM.SCM.IDX_R_CODE_ID_BEHIND

-- DROP INDEX SCM.SCM.IDX_R_CODE_ID_BEHIND;

CREATE INDEX SCM.IDX_R_CODE_ID_BEHIND
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (CODE_ID_BEHIND)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: SCM.SCM.IDX_RCVBL_SMMRY_DESC

-- DROP INDEX SCM.SCM.IDX_RCVBL_SMMRY_DESC;

CREATE INDEX SCM.IDX_RCVBL_SMMRY_DESC
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (RCVBL_SMMRY_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

   /*
-- INDEX: SCM.SCM.IDX_RCVBL_SMMRY_ID

-- DROP INDEX SCM.SCM.IDX_RCVBL_SMMRY_ID;

CREATE UNIQUE INDEX SCM.IDX_RCVBL_SMMRY_ID
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (RCVBL_SMMRY_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;
*/

-- INDEX: SCM.SCM.IDX_RCVBL_SMMRY_TYPE

-- DROP INDEX SCM.SCM.IDX_RCVBL_SMMRY_TYPE;

CREATE INDEX SCM.IDX_RCVBL_SMMRY_TYPE
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (RCVBL_SMMRY_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: SCM.SCM.IDX_SMRY_SRC_RCVBL_HDR_ID

-- DROP INDEX SCM.SCM.IDX_SMRY_SRC_RCVBL_HDR_ID;

CREATE INDEX SCM.IDX_SMRY_SRC_RCVBL_HDR_ID
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (SRC_RCVBL_HDR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: SCM.SCM.IDX_SMRY_SRC_RCVBL_TYPE

-- DROP INDEX SCM.SCM.IDX_SMRY_SRC_RCVBL_TYPE;

CREATE INDEX SCM.IDX_SMRY_SRC_RCVBL_TYPE
   ON SCM.SCM_RCVBL_AMNT_SMMRYS (SRC_RCVBL_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE SEQUENCE SCM.SCM_RCVBL_AMNT_SMMRYS_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER SCM.SCM_RCVBL_AMNT_SMMRYS_ID_TRG
   BEFORE INSERT
   ON SCM.SCM_RCVBL_AMNT_SMMRYS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.RCVBL_SMMRY_ID IS NULL)
DECLARE
   V_ID   SCM.SCM_RCVBL_AMNT_SMMRYS.RCVBL_SMMRY_ID%TYPE;
BEGIN
   SELECT   SCM.SCM_RCVBL_AMNT_SMMRYS_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.RCVBL_SMMRY_ID := V_ID;
END SCM_RCVBL_AMNT_SMMRYS_ID_TRG;