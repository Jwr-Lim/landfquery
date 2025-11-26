ALTER PROC USP_POP_004_MAIN_EQP_QUERY(
--DECLARE 
     @DIV_CD     NVARCHAR(10)  = '01'
    ,@PLANT_CD   NVARCHAR(10)  = '1130'
    ,@WC_CD      NVARCHAR(10)  = '13GA'
    ,@LINE_CD    NVARCHAr(15)  = '13G01A'
    ,@PROC_CD    NVARCHAR(10)  = 'RI'
    ,@EQP_CD     NVARCHAR(50)  = 'LFG-MST-10-01'
)
AS 


-- 투입공정인지 부터 먼저 확인이 필요함.

DECLARE @IN_GBN       NVARCHAR(10) = ''
       ,@IN_GBN_NM    NVARCHAR(10) = ''
       ,@NOW_ST       NVARCHAR(1)  = ''  
       ,@RESULT_QTY   NUMERIC(18,3) = 0
       ,@GOOD_QTY     NUMERIC(18,3) = 0
       ,@LOT_NO       NVARCHAR(50) = ''
       ,@BATCH_INFO   NVARCHAR(50) = ''

SET @IN_GBN = ISNULL((SELECT A.IN_GBN FROM BA_PROC_MAIN A WITH (NOLOCK) 
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.PROC_CD = @PROC_CD 
),'')
-- 어 이거 중간에 소분이 있으면 소분도 추가 해야 될것 같다.

SELECT @IN_GBN_NM = A.SUB_NM
FROM BA_SUB_CD A WITH (NOLOCK) 
WHERE A.MAIN_CD = 'POP60'
  AND A.SUB_CD = @IN_GBN 

-- 현재 돌아가고 있는 실적이 있는가? 없는거를 판단한다. 
IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK) 
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
  AND A.EQP_CD = @EQP_CD AND A.EDATE IS NULL)
BEGIN 

       IF @IN_GBN IN ('I') 
       BEGIN 
              -- 배정정보는 따로 처리 하자.
              IF EXISTS(
                     SELECT 
                     B.*FROM PD_RESULT A WITH (NOLOCK) 
                     INNER JOIN PD_USEM B WITH (NOLOCK) ON
                     A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
                     AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER 
                     AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ 
                     WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                     AND A.EQP_CD = @EQP_CD AND A.EDATE IS NULL
              )
              BEGIN 
                     SELECT @BATCH_INFO =  
                     STUFF(  
                     (SELECT ',' + RIGHT(B.REQ_DT,2) + '-' + dbo.LPAD(B.PLAN_SEQ, 3,0) + CASE WHEN ISNULL(B.BATCH_NO,'') = '' THEN '' ELSE '-' + CAST(B.BATCH_NO AS NVARCHAR) END
                     FROM PD_RESULT A WITH (NOLOCK) 
                     INNER JOIN PD_USEM B WITH (NOLOCK) ON
                     A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
                     AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER 
                     AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ 
                     WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                     AND A.EQP_CD = @EQP_CD AND A.EDATE IS NULL
                     GROUP BY B.REQ_DT, B.PLAN_SEQ, B.BATCH_NO  
                     FOR XML PATH('')),1,1,''  
                     )
              END 
              ELSE 
              BEGIN 
                     
                     -- 배정 정보를 가지고 온다. 
                     IF EXISTS(SELECT *FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
                     WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_DT = CONVERT(NVARCHAR(7),GETDATE(), 120) 
                       AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.USE_FLG = 'N' 
                     )
                     BEGIN 
                                          
                            SELECT @BATCH_INFO = 
                            RIGHT(A.REQ_DT,2) + '-' + dbo.LPAD(A.PLAN_SEQ, 3,0) + CASE WHEN ISNULL(A.BATCH_NO,'') = '' THEN '' ELSE '-' + CAST(A.BATCH_NO AS NVARCHAR) END
                            FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_DT = CONVERT(NVARCHAR(7),GETDATE(), 120) 
                            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.USE_FLG = 'N' 
                     END 
              END 
       END 

       SELECT 'Y' AS NOW_ST, @IN_GBN AS IN_GBN, @IN_GBN_NM AS IN_GBN_NM, 
              @DIV_CD AS DIV_CD, @PLANT_CD AS PLANT_CD, 
              @WC_CD AS WC_CD, 
              ISNULL((SELECT A.WC_NM FROM BA_WORK_CENTER A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD),'') AS WC_NM,
              @LINE_CD AS LINE_CD, 
              ISNULL((SELECT A.LINE_NM FROM BA_LINE A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD ),'') AS LINE_NM,
              @PROC_CD AS PROC_CD, 
              ISNULL((SELECT A.PROC_NM FROM BA_PROC A WITH (NOLOCK) WHERE A.PROC_CD = @PROC_CD),'') AS PROC_NM,
              @EQP_CD AS EQP_CD,
              ISNULL((SELECT A.EQP_NM FROM BA_EQP A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = @PROC_CD AND  A.EQP_CD = @EQP_CD),'') AS EQP_NM,
              A.LOT_NO,
              A.PROC_NO, A.ORDER_NO, A.REVISION, D.SUB_NM AS BASE_ITEM_NM, 
              A.ITEM_CD,
              C.ITEM_NM + CHAR(10) + '/ ' + C.LOT_INFO + CASE WHEN ISNULL(G.SUB_NM,'') = '' THEN '' ELSE ' / ' + G.SUB_NM END AS ITEM_NM,
              B.ORDER_FORM, E.SUB_NM AS ORDER_FORM_NM,
              B.ORDER_TYPE, F.SUB_NM AS ORDER_TYPE_NM,
              B.ORDER_QTY, 
              B1.SKIP,
              B.DIV_CD, 
              B.PLANT_CD, 
              B.ORDER_TYPE, 
              B.ORDER_FORM, 
              B.ROUT_NO, 
              B.ROUT_VER, 
              B1.WC_CD, 
              B1.LINE_CD, 
              B1.PROC_SEQ, 
              B1.CLOSE_FLG, 
              B1.ORDER_STATE,
              A.GOOD_QTY,
              -- 배정정보를 가지고 오자.
              -- 추후 소분도 정리해야 된다.
              @BATCH_INFO AS BATCH_INFO
              
              FROM PD_RESULT A WITH (NOLOCK) 
              INNER JOIN PD_ORDER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD 
              AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_FORM = B.ORDER_FORM AND A.ORDER_TYPE = B.ORDER_TYPE 
              AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD 
              INNER JOIN PD_ORDER_PROC B1 WITH (NOLOCK) ON B.DIV_CD = B1.DIV_CD AND B.PLANT_CD = B1.PLANT_CD AND 
              B.ORDER_NO = B1.ORDER_NO AND B.REVISION = B1.REVISION AND B.ORDER_FORM = B1.ORDER_FORM AND B.ORDER_TYPE = B1.ORDER_TYPE 
              AND B.ROUT_NO = B1.ROUT_NO AND B.ROUT_VER = B1.ROUT_VER AND B.WC_CD = B1.WC_CD AND B.LINE_CD = B1.LINE_CD AND B1.PROC_CD = @PROC_CD
              INNER JOIN V_ITEM C WITH (NOLOCK) ON B.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD 
              INNER JOIN BA_SUB_CD D WITH (NOLOCK) ON C.BASE_ITEM_CD = D.SUB_CD AND D.MAIN_CD = 'BA206'
              INNER JOIN BA_SUB_CD E WITH (NOLOCK) ON B.ORDER_FORM = E.SUB_CD AND E.MAIN_CD = 'P1005' 
              INNER JOIN BA_SUB_CD F WITH (NOLOCK) ON B.ORDER_TYPE = F.SUB_CD AND F.MAIN_CD = 'SAP01'
              LEFT JOIN BA_SUB_CD G WITH (NOLOCK) ON C.ITEM_GROUP_CD2 = G.SUB_CD AND G.MAIN_CD = 'B0002'

       WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
         AND A.EQP_CD = @EQP_CD AND A.EDATE IS NULL

            
END 
ELSE 
BEGIN 
       SELECT 'N' AS NOW_ST, @IN_GBN AS IN_GBN, @IN_GBN_NM AS IN_GBN_NM, 
       @DIV_CD AS DIV_CD, @PLANT_CD AS PLANT_CD, 
       @WC_CD AS WC_CD, 
       ISNULL((SELECT A.WC_NM FROM BA_WORK_CENTER A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD),'') AS WC_NM,
       @LINE_CD AS LINE_CD, 
       ISNULL((SELECT A.LINE_NM FROM BA_LINE A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD ),'') AS LINE_NM,
       @PROC_CD AS PROC_CD, 
       ISNULL((SELECT A.PROC_NM FROM BA_PROC A WITH (NOLOCK) WHERE A.PROC_CD = @PROC_CD),'') AS PROC_NM,
       @EQP_CD AS EQP_CD
       ,ISNULL((SELECT A.EQP_NM FROM BA_EQP A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD= @PROC_CD AND A.EQP_CD = @EQP_CD),'') AS EQP_NM

END 
