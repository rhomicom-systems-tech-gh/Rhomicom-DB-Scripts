/* Formatted on 12-19-2018 2:04:43 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SCM.GET_CSTMR_SPLR_ADDRESS (P_CSTMRSPLRID NUMBER)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   SELECT   TBL1.BILLING_ADDRESS
     INTO   L_RESULT
     FROM   (  SELECT   BILLING_ADDRESS
                 FROM   SCM.SCM_CSTMR_SUPLR_SITES
                WHERE   CUST_SUPPLIER_ID = P_CSTMRSPLRID
             ORDER BY   CUST_SUP_SITE_ID ASC) TBL1
    WHERE   ROWNUM <= 1;

   RETURN COALESCE (L_RESULT, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/