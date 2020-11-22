/* Formatted on 12-15-2018 8:42:53 AM (QP5 v5.126.903.23003) */
DROP TABLE ORG.ORG_WRKN_HRS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE ORG.ORG_WRKN_HRS (
   WORK_HOURS_ID      NUMBER NOT NULL,
   ORG_ID             NUMBER,
   WORK_HOURS_NAME    VARCHAR2 (200 BYTE),
   WORK_HOURS_DESC    VARCHAR2 (300 BYTE),
   IS_ENABLED         VARCHAR2 (1 BYTE),
   CREATED_BY         NUMBER NOT NULL,
   CREATION_DATE      VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21 BYTE) NOT NULL
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

CREATE UNIQUE INDEX ORG.IDX_WORK_HOURS_ID
   ON ORG.ORG_WRKN_HRS (WORK_HOURS_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ORG.ORG_WRKN_HRS ADD (
  CONSTRAINT PK_WORK_HOURS_ID
 PRIMARY KEY
 (WORK_HOURS_ID));

CREATE INDEX ORG.IDX_WORK_HOURS_DESC
   ON ORG.ORG_WRKN_HRS (WORK_HOURS_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ORG.IDX_WORK_HOURS_NAME
   ON ORG.ORG_WRKN_HRS (WORK_HOURS_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE ORG.ORG_WRKN_HRS_SEQ;

CREATE SEQUENCE ORG.ORG_WRKN_HRS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ORG.ORG_WRKN_HRS_TRG
   BEFORE INSERT
   ON ORG.ORG_WRKN_HRS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.WORK_HOURS_ID IS NULL)
DECLARE
   V_ID   ORG.ORG_WRKN_HRS.WORK_HOURS_ID%TYPE;
BEGIN
   SELECT   ORG.ORG_WRKN_HRS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.WORK_HOURS_ID := V_ID;
END ORG_WRKN_HRS_TRG;