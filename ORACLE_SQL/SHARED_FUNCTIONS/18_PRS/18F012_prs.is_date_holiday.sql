/* Formatted on 12-19-2018 5:47:46 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PRS.IS_DATE_HOLIDAY (P_DATE VARCHAR2)
   RETURN VARCHAR2
AS
   VALAMNT   NUMBER := 0;
BEGIN
   SELECT   DISTINCT 1
     INTO   VALAMNT
     FROM   GST.GEN_STP_LOV_NAMES A, GST.GEN_STP_LOV_VALUES B
    WHERE   ( (    A.VALUE_LIST_ID = B.VALUE_LIST_ID
               AND B.IS_ENABLED = '1'
               AND VALUE_LIST_NAME = 'Holiday Dates'))
            AND P_DATE =
                  TO_CHAR (TO_DATE (PSSBL_VALUE, 'DD-Mon-YYYY'),
                           'YYYY-MM-DD');

   IF VALAMNT > 0
   THEN
      RETURN 'TRUE';
   ELSE
      RETURN 'FALSE';
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RETURN 'FALSE';
END;
/