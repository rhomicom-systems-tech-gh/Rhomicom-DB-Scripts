/* Formatted on 12-15-2018 7:43:43 AM (QP5 v5.126.903.23003) */
DROP TABLE ORG.ORG_ACNT_SGMNTS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE ORG.ORG_ACNT_SGMNTS (
   SEGMENT_ID            NUMBER NOT NULL,
   SEGMENT_NUMBER        INTEGER,
   SEGMENT_NAME_PROMPT   VARCHAR2 (200),
   SYSTEM_CLSFCTN        VARCHAR2 (100) DEFAULT 'Other' NOT NULL,
   CREATED_BY            NUMBER DEFAULT -1 NOT NULL,
   CREATION_DATE         VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY        NUMBER DEFAULT -1 NOT NULL,
   LAST_UPDATE_DATE      VARCHAR2 (21) NOT NULL,
   ORG_ID                INTEGER,
   PRNT_SGMNT_NUMBER     INTEGER DEFAULT -1 NOT NULL
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

CREATE UNIQUE INDEX ORG.IDX_ACS_SEGMENT_ID
   ON ORG.ORG_ACNT_SGMNTS (SEGMENT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ORG.ORG_ACNT_SGMNTS ADD (
  CONSTRAINT PK_SEGMENT_ID
 PRIMARY KEY
 (SEGMENT_ID));

CREATE INDEX ORG.IDX_ACS_SEGMENT_NUMBER
   ON ORG.ORG_ACNT_SGMNTS (SEGMENT_NUMBER)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE ORG.ORG_ACNT_SGMNTS_SEQ;

CREATE SEQUENCE ORG.ORG_ACNT_SGMNTS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ORG.ORG_ACNT_SGMNTS_TRG
   BEFORE INSERT
   ON ORG.ORG_ACNT_SGMNTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.SEGMENT_ID IS NULL)
DECLARE
   V_ID   ORG.ORG_ACNT_SGMNTS.SEGMENT_ID%TYPE;
BEGIN
   SELECT   ORG.ORG_ACNT_SGMNTS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.SEGMENT_ID := V_ID;
END ORG_ACNT_SGMNTS_TRG;