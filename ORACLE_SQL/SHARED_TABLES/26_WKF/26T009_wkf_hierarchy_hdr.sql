/* Formatted on 12-18-2018 9:57:18 AM (QP5 v5.126.903.23003) */
DROP TABLE WKF.WKF_HIERARCHY_HDR CASCADE CONSTRAINTS PURGE;

CREATE TABLE WKF.WKF_HIERARCHY_HDR (HIERARCHY_ID       NUMBER NOT NULL,
                                    HIERARCHY_NAME     VARCHAR2 (100 BYTE),
                                    DESCRIPTION        VARCHAR2 (300 BYTE),
                                    IS_ENABLED         VARCHAR2 (1 BYTE),
                                    CREATED_BY         NUMBER,
                                    CREATION_DATE      VARCHAR2 (21 BYTE),
                                    LAST_UPDATE_BY     NUMBER,
                                    LAST_UPDATE_DATE   VARCHAR2 (21 BYTE),
                                    HIERCHY_TYPE       VARCHAR2 (50 BYTE), -- POSITION...
                                    SQL_SELECT_STMNT   CLOB)
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

ALTER TABLE WKF.WKF_HIERARCHY_HDR
ADD(  CONSTRAINT PK_HIERARCHY_ID PRIMARY KEY (HIERARCHY_ID ));

COMMENT ON COLUMN WKF.WKF_HIERARCHY_HDR.HIERCHY_TYPE IS
'Position
Manual
SQL';

DROP SEQUENCE WKF.WKF_PSTN_HIERARCHY_HDR_ID_SEQ;

CREATE SEQUENCE WKF.WKF_PSTN_HIERARCHY_HDR_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER WKF.WKF_PSTN_HIERARCHY_HDR_ID_TRG
   BEFORE INSERT
   ON WKF.WKF_HIERARCHY_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.HIERARCHY_ID IS NULL)
DECLARE
   V_ID   WKF.WKF_HIERARCHY_HDR.HIERARCHY_ID%TYPE;
BEGIN
   SELECT   WKF.WKF_PSTN_HIERARCHY_HDR_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.HIERARCHY_ID := V_ID;
END WKF_PSTN_HIERARCHY_HDR_ID_TRG;