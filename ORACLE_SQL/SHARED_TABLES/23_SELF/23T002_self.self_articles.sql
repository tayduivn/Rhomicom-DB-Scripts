/* Formatted on 12-17-2018 11:22:31 AM (QP5 v5.126.903.23003) */
DROP TABLE SELF.SELF_ARTICLES  CASCADE CONSTRAINTS PURGE;

CREATE TABLE SELF.SELF_ARTICLES (
   ARTICLE_ID             NUMBER NOT NULL,
   ARTICLE_CATEGORY       VARCHAR2 (200) DEFAULT 'News/Highlights' NOT NULL, -- NEWS/HIGHLIGHTS OR USEFUL RESOURCES
   ARTICLE_HEADER         CLOB,
   ARTICLE_BODY           CLOB,
   HEADER_URL             CLOB, -- USE {:ARTICLE_ID} TO MAKE AUTOMATIC REFERENCE TO ARTICLE ID
   IS_PUBLISHED           VARCHAR2 (1) DEFAULT '0' NOT NULL,
   PUBLISHING_DATE        VARCHAR2 (21) DEFAULT '0001-01-01 00:00:00' NOT NULL,
   AUTHOR_NAME            VARCHAR2 (200),
   AUTHOR_EMAIL           VARCHAR2 (200),
   AUTHOR_PRSN_ID         NUMBER DEFAULT -1 NOT NULL,
   CREATED_BY             NUMBER DEFAULT -1 NOT NULL,
   CREATION_DATE          VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY         NUMBER DEFAULT -1 NOT NULL,
   LAST_UPDATE_DATE       VARCHAR2 (21) NOT NULL,
   ARTICLE_INTRO_MSG      CLOB,
   ALLOWED_GROUP_TYPE     VARCHAR2 (200),
   ALLOWED_GROUP_ID       NUMBER DEFAULT -1 NOT NULL,
   LOCAL_CLASSIFICATION   VARCHAR2 (200),
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

CREATE INDEX SELF.IDX_SA_ARTICLE_CATEGORY
   ON SELF.SELF_ARTICLES (ARTICLE_CATEGORY)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE SELF.SELF_ARTICLES_SEQ;

CREATE SEQUENCE SELF.SELF_ARTICLES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER SELF.SELF_ARTICLES_TRG
   BEFORE INSERT
   ON SELF.SELF_ARTICLES
   FOR EACH ROW
   WHEN (NEW.ARTICLE_ID IS NULL)
DECLARE
   V_ID   SELF.SELF_ARTICLES.ARTICLE_ID%TYPE;
BEGIN
   SELECT   SELF.SELF_ARTICLES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ARTICLE_ID := V_ID;
END SELF_ARTICLES_TRG;