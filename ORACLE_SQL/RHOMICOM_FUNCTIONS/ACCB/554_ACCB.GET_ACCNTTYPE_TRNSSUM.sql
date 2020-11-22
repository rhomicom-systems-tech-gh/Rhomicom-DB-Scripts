/* Formatted on 10/6/2014 2:30:37 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_ACCNTTYPE_TRNSSUM (
   P_ORGID       INTEGER,
   P_ACCNTTYP    VARCHAR2,
   P_AMNTCOL     VARCHAR2,
   P_BALSDTE     VARCHAR2
)
   RETURN NUMBER
AS
   L_RESULT   NUMBER := 0.00;
BEGIN
   IF P_AMNTCOL = 'dbt_amount'
   THEN
      SELECT   SUM (A.DBT_AMOUNT)
        INTO   L_RESULT
        FROM   ACCB.ACCB_TRNSCTN_DETAILS A, ACCB.ACCB_CHART_OF_ACCNTS B
       WHERE   ( (A.ACCNT_ID = B.ACCNT_ID)
                AND (B.ACCNT_TYPE = P_ACCNTTYP AND B.ORG_ID = P_ORGID)
                AND (TO_DATE (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') <=
                        TO_DATE (P_BALSDTE, 'YYYY-MM-DD HH24:MI:SS'))
                AND (A.TRNS_STATUS = '1'));
   ELSIF P_AMNTCOL = 'crdt_amount'
   THEN
      SELECT   SUM (A.CRDT_AMOUNT)
        INTO   L_RESULT
        FROM   ACCB.ACCB_TRNSCTN_DETAILS A, ACCB.ACCB_CHART_OF_ACCNTS B
       WHERE   ( (A.ACCNT_ID = B.ACCNT_ID)
                AND (B.ACCNT_TYPE = P_ACCNTTYP AND B.ORG_ID = P_ORGID)
                AND (TO_DATE (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') <=
                        TO_DATE (P_BALSDTE, 'YYYY-MM-DD HH24:MI:SS'))
                AND (A.TRNS_STATUS = '1'));
   ELSE
      SELECT   SUM (A.NET_AMOUNT)
        INTO   L_RESULT
        FROM   ACCB.ACCB_TRNSCTN_DETAILS A, ACCB.ACCB_CHART_OF_ACCNTS B
       WHERE   ( (A.ACCNT_ID = B.ACCNT_ID)
                AND (B.ACCNT_TYPE = P_ACCNTTYP AND B.ORG_ID = P_ORGID)
                AND (TO_DATE (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') <=
                        TO_DATE (P_BALSDTE, 'YYYY-MM-DD HH24:MI:SS'))
                AND (A.TRNS_STATUS = '1'));
   END IF;


   RETURN COALESCE (L_RESULT, 0);
END;