/* Formatted on 12-17-2018 9:22:14 AM (QP5 v5.126.903.23003) */
DROP TABLE SEC.SEC_ARTICLES  CASCADE CONSTRAINTS PURGE;

CREATE TABLE SEC.SEC_ARTICLES (
   ARTICLE_ID         NUMBER NOT NULL,
   ARTICLE_HEADER     CLOB,
   ARTICLE_BODY       CLOB,
   HEADER_URL         CLOB,
   CREATED_BY         NUMBER DEFAULT -1 NOT NULL,
   CREATION_DATE      VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY     NUMBER DEFAULT -1 NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21) NOT NULL,
   ARTICLE_CATEGORY   VARCHAR2 (200) DEFAULT 'News/Highlights' NOT NULL,
   CONSTRAINT PK_ARTICLE_ID PRIMARY KEY (ARTICLE_ID)
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

DROP SEQUENCE SEC.SEC_ARTICLES_SEQ;

CREATE SEQUENCE SEC.SEC_ARTICLES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE INDEX SEC.IDX_ARTICLE_CATEGORY
   ON SEC.SEC_ARTICLES (ARTICLE_CATEGORY)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE OR REPLACE TRIGGER SEC.SEC_ARTICLES_TRG
   BEFORE INSERT
   ON SEC.SEC_ARTICLES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ARTICLE_ID IS NULL)
DECLARE
   V_ID   SEC.SEC_ARTICLES.ARTICLE_ID%TYPE;
BEGIN
   SELECT   SEC.SEC_ARTICLES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ARTICLE_ID := V_ID;
END SEC_ARTICLES_TRG;