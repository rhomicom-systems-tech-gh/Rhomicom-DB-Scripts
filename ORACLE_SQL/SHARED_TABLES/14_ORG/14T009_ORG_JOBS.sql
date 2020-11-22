/* Formatted on 12-15-2018 8:05:10 AM (QP5 v5.126.903.23003) */
DROP TABLE ORG.ORG_JOBS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE ORG.ORG_JOBS (JOB_ID             NUMBER NOT NULL,
                           ORG_ID             NUMBER,
                           JOB_CODE_NAME      VARCHAR2 (200 BYTE),
                           JOB_COMMENTS       VARCHAR2 (500 BYTE),
                           IS_ENABLED         VARCHAR2 (1 BYTE),
                           CREATED_BY         NUMBER NOT NULL,
                           CREATION_DATE      VARCHAR2 (21 BYTE) NOT NULL,
                           LAST_UPDATE_BY     NUMBER NOT NULL,
                           LAST_UPDATE_DATE   VARCHAR2 (21 BYTE) NOT NULL,
                           PARNT_JOB_ID       NUMBER)
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

CREATE UNIQUE INDEX ORG.IDX_JOB_ID
   ON ORG.ORG_JOBS (JOB_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ORG.ORG_JOBS ADD (
  CONSTRAINT PK_JOB_ID
 PRIMARY KEY
 (JOB_ID));

CREATE INDEX ORG.IDX_JOB_CODE_NAME
   ON ORG.ORG_JOBS (JOB_CODE_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ORG.IDX_JOB_COMMENTS
   ON ORG.ORG_JOBS (JOB_COMMENTS)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE INDEX ORG.IDX_PARNT_JOB_ID
   ON ORG.ORG_JOBS (PARNT_JOB_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE ORG.ORG_JOBS_SEQ;

CREATE SEQUENCE ORG.ORG_JOBS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ORG.ORG_JOBS_TRG
   BEFORE INSERT
   ON ORG.ORG_JOBS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.JOB_ID IS NULL)
DECLARE
   V_ID   ORG.ORG_JOBS.JOB_ID%TYPE;
BEGIN
   SELECT   ORG.ORG_JOBS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.JOB_ID := V_ID;
END ORG_JOBS_TRG;