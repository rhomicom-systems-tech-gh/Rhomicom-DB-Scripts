/* Formatted on 12-19-2018 12:17:04 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SEC.GET_USER_TRNS_CODE (P_USRID NUMBER)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   SELECT   A.CODE_FOR_TRNS_NUMS
     INTO   L_RESULT
     FROM   SEC.SEC_USERS A
    WHERE   (A.USER_ID = P_USRID);

   RETURN COALESCE (L_RESULT, 'XX');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 'XX';
END;
/