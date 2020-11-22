/* Formatted on 12-15-2018 11:00:12 AM (QP5 v5.126.903.23003) */
DROP TABLE RPT.RPT_REPORT_PARAMETERS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE RPT.RPT_REPORT_PARAMETERS (
   PARAMETER_ID                 NUMBER NOT NULL,
   REPORT_ID                    NUMBER,
   PARAMETER_NAME               VARCHAR2 (200 BYTE),
   PARAMTR_RPRSTN_NM_IN_QUERY   VARCHAR2 (100 BYTE),
   CREATED_BY                   NUMBER NOT NULL,
   CREATION_DATE                VARCHAR2 (21 BYTE),
   LAST_UPDATE_BY               NUMBER NOT NULL,
   LAST_UPDATE_DATE             VARCHAR2 (21 BYTE) NOT NULL,
   DEFAULT_VALUE                VARCHAR2 (500 BYTE),
   IS_REQUIRED                  VARCHAR2 (1 BYTE) DEFAULT '0' NOT NULL,
   LOV_NAME_ID                  VARCHAR2 (300 BYTE),
   PARAM_DATA_TYPE              VARCHAR2 (100 BYTE) DEFAULT 'TEXT' NOT NULL,
   DATE_FORMAT                  VARCHAR2 (100 BYTE)
         DEFAULT 'yyyy-MM-dd' NOT NULL,
   lov_name                     VARCHAR2 (300),
   shd_be_dsplyd                VARCHAR2 (1) DEFAULT '1' NOT NULL,
   CONSTRAINT pk_parameter_id PRIMARY KEY (parameter_id)
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

CREATE INDEX RPT.IDX_P_REPORT_ID
   ON RPT.RPT_REPORT_PARAMETERS (REPORT_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX RPT.IDX_PARAMETER_NAME
   ON RPT.RPT_REPORT_PARAMETERS (PARAMETER_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE RPT.RPT_REPORT_PARAMETERS_ID_SEQ;

CREATE SEQUENCE RPT.RPT_REPORT_PARAMETERS_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER RPT.RPT_REPORT_PARAMETERS_ID_TRG
   BEFORE INSERT
   ON RPT.RPT_REPORT_PARAMETERS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.PARAMETER_ID IS NULL)
DECLARE
   V_ID   RPT.RPT_REPORT_PARAMETERS.PARAMETER_ID%TYPE;
BEGIN
   SELECT   RPT.RPT_REPORT_PARAMETERS_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.PARAMETER_ID := V_ID;
END RPT_REPORT_PARAMETERS_ID_TRG;