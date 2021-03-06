/* Formatted on 12-17-2018 9:39:03 AM (QP5 v5.126.903.23003) */
DROP TABLE SEC.SEC_MODULES  CASCADE CONSTRAINTS PURGE;

CREATE TABLE SEC.SEC_MODULES (MODULE_ID              NUMBER NOT NULL,
                              MODULE_NAME            VARCHAR2 (100 BYTE),
                              MODULE_DESC            VARCHAR2 (500 BYTE),
                              DATE_ADDED             VARCHAR2 (21 BYTE),
                              AUDIT_TRAIL_TBL_NAME   VARCHAR2 (100 BYTE))
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

CREATE UNIQUE INDEX SEC.IDX_MODULE_ID
   ON SEC.SEC_MODULES (MODULE_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE SEC.SEC_MODULES_SEQ;

CREATE SEQUENCE SEC.SEC_MODULES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

ALTER TABLE SEC.SEC_MODULES ADD (
CONSTRAINT PK_MODULE_ID
PRIMARY KEY (MODULE_ID));


CREATE UNIQUE INDEX SEC.IDX_MODULE_NAME
   ON SEC.SEC_MODULES (MODULE_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE OR REPLACE TRIGGER SEC.SEC_MODULES_TRG
   BEFORE INSERT
   ON SEC.SEC_MODULES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.MODULE_ID IS NULL)
DECLARE
   V_ID   SEC.SEC_MODULES.MODULE_ID%TYPE;
BEGIN
   SELECT   SEC.SEC_MODULES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.MODULE_ID := V_ID;
END SEC_MODULES_TRG;