/* Formatted on 10/6/2014 7:40:57 PM (QP5 v5.126.903.23003) */
CREATE TABLE HOTL.CHECK_IN (CHECK_IN_ID              NUMBER NOT NULL,
                            CUSTOMER_ID              VARCHAR2 (50 BYTE),
                            CUSTOMER_NAME            VARCHAR2 (100 BYTE),
                            PHONE_NO                 VARCHAR2 (50 BYTE),
                            GENDER                   VARCHAR2 (1 BYTE),
                            IDENTIFICATION           VARCHAR2 (100 BYTE),
                            IDENTIFICATION_NO        VARCHAR2 (100 BYTE),
                            NATIONALITY              VARCHAR2 (100 BYTE),
                            EMAIL                    VARCHAR2 (100 BYTE),
                            ADDRESS                  VARCHAR2 (300 BYTE),
                            ACTUAL_CHECKIN_ROOM_NO   VARCHAR2 (100 BYTE),
                            CREATED_BY               VARCHAR2 (21 BYTE),
                            CREATION_DATE            VARCHAR2 (21 BYTE),
                            LAST_UPDATE_BY           VARCHAR2 (21 BYTE),
                            LAST_UPDATE_DATE         VARCHAR2 (21 BYTE),
                            REQ_SERV_TYPE_ID         NUMBER)
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

CREATE UNIQUE INDEX HOTL.IDX_CHECK_IN_ID
   ON HOTL.CHECK_IN (CHECK_IN_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE HOTL.CHECK_IN ADD (
  CONSTRAINT PK_CHECK_IN_ID
 PRIMARY KEY
 (CHECK_IN_ID));

CREATE SEQUENCE HOTL.CHECK_IN_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER HOTL.CHECK_IN_TRG
   BEFORE INSERT
   ON HOTL.CHECK_IN
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.CHECK_IN_ID IS NULL)
DECLARE
   V_ID   HOTL.CHECK_IN.CHECK_IN_ID%TYPE;
BEGIN
   SELECT   HOTL.CHECK_IN_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.CHECK_IN_ID := V_ID;
END CHECK_IN_TRG;