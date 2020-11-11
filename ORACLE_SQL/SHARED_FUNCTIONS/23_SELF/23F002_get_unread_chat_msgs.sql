/* Formatted on 12-19-2018 11:21:29 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SELF.GET_UNREAD_CHAT_MSGS (P_PERSON_ID NUMBER)
   RETURN INTEGER
AS
   BID   INTEGER := 0;
BEGIN
   SELECT   COUNT (1)
     INTO   BID
     FROM   SELF.SELF_ARTICLE_CMMNTS A,
            SEC.SEC_TRACK_USER_LOGINS B,
            SELF.SELF_ARTICLES E
    WHERE       A.ARTICLE_ID = E.ARTICLE_ID
            AND A.LOGIN_NUMBER = B.LOGIN_NUMBER
            AND SEC.GET_USR_PRSN_ID (B.USER_ID) != P_PERSON_ID
            AND A.ARTICLE_ID NOT IN
                     (SELECT   C.ARTICLE_ID
                        FROM   SELF.SELF_ARTICLES_HITS C,
                               SEC.SEC_TRACK_USER_LOGINS D
                       WHERE   C.LOGIN_NUMBER = D.LOGIN_NUMBER
                               AND SEC.GET_USR_PRSN_ID (D.USER_ID) =
                                     P_PERSON_ID)
            AND ORG.DOES_PRSN_HV_CRTRIA_ID (P_PERSON_ID,
                                            E.ALLOWED_GROUP_ID,
                                            E.ALLOWED_GROUP_TYPE) > 0
            AND E.ARTICLE_CATEGORY IN ('Forum Topic', 'Chat Room');

   RETURN COALESCE (BID, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/