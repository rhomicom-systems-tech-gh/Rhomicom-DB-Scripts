/* Formatted on 12-15-2018 12:19:11 PM (QP5 v5.126.903.23003) */
DROP TABLE RPT.RPT_RUN_SCHDULES  CASCADE CONSTRAINTS PURGE;

CREATE TABLE RPT.RPT_RUN_SCHDULES (
   SCHEDULE_ID         NUMBER NOT NULL,
   REPORT_ID           NUMBER,
   CREATED_BY          NUMBER NOT NULL,
   CREATION_DATE       VARCHAR2 (21 BYTE),
   LAST_UPDATE_BY      NUMBER NOT NULL,
   LAST_UPDATE_DATE    VARCHAR2 (21 BYTE),
   START_DTE_TME       VARCHAR2 (21 BYTE),
   REPEAT_UOM          VARCHAR2 (50 BYTE),
   REPEAT_EVERY        NUMBER,
   RUN_AT_SPCFD_HOUR   VARCHAR2 (1) DEFAULT '0' NOT NULL,
   CONSTRAINT PK_SCHEDULE_ID PRIMARY KEY (SCHEDULE_ID)
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

CREATE INDEX RPT.IDX_SCHDL_CREATED_BY
   ON RPT.RPT_RUN_SCHDULES (CREATED_BY)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX RPT.IDX_SCHDL_REPORT_ID
   ON RPT.RPT_RUN_SCHDULES (REPORT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX RPT.IDX_START_DTE_TME
   ON RPT.RPT_RUN_SCHDULES (START_DTE_TME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE RPT.RPT_RUN_SCHDULES_ID_SEQ;

CREATE SEQUENCE RPT.RPT_RUN_SCHDULES_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER RPT.RPT_RUN_SCHDULES_ID_TRG
   BEFORE INSERT
   ON RPT.RPT_RUN_SCHDULES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.SCHEDULE_ID IS NULL)
DECLARE
   V_ID   RPT.RPT_RUN_SCHDULES.SCHEDULE_ID%TYPE;
BEGIN
   SELECT   RPT.RPT_RUN_SCHDULES_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.SCHEDULE_ID := V_ID;
END RPT_RUN_SCHDULES_ID_TRG;