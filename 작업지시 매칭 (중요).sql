-- 마지막 작업지시 정보를 가지고 온다.  
 
/* 
UPDATE A SET A.OUT_CHK = 'Y', A.GROUP_S = 'N' 
    FROM PD_ORDER_PROC A WITH (NOLOCK)  
WHERE A.ORDER_NO = 'PD250113002' 
  AND A.PROC_CD =  'RK' 
*/ 
ALTER PROC USP_MDM_WORK_ORDER_CREATE( 
        @DIV_CD      NVARCHAR(50) = '01' 
       ,@PLANT_CD    NVARCHAR(50) = '1130'  
       ,@WC_CD       NVARCHAR(10) = '13GA' 
       ,@LINE_CD     NVARCHAR(10) = '13G01A' 
       ,@PROC_CD     NVARCHAR(10) = 'MX' 
       ,@EQP_CD      NVARCHAR(50) = 'LFG01A-01A-RK-0701' 
       ,@VALUE       NUMERIC(18,3) = 3000 
       ,@ORDER_NO    NVARCHAR(50) OUTPUT  
       ,@REVISION    INT          OUTPUT  
       ,@RESULT_sEQ  INT          OUTPUT 
) 
AS 
 
SET NOCOUNT ON  
-- 투입은 상관없고, 혼합부터 작업지시를 먼저 보내줘야 된다.  
-- 현재 실적일때 앞에 재공을 바라보고, 재공 기준으로 선입선출을 해서 오더를 매칭한다.  
 
 
-- 지시번호 없이 앞 실적을 어떻게 찾는가?  
-- 공정 기준 정보를 가지고 찾아본다.  
 
IF OBJECT_ID('tempdb..#MDM_WO_FIFO') IS NOT NULL DROP TABLE #MDM_WO_FIFO; 
 
CREATE TABLE #MDM_WO_FIFO (                                
ROWNUM          INT --IDENTITY(1,1)                                 
,GBN            NVARCHAR(10)                                 
,PROC_CD        NVARCHAR(10)                            
,ITEM_CD        NVARCHAR(50)                                 
,LOT_NO         NVARCHAr(50)                                 
,CURQTY         NUMERIC(18,4)                                 
,BE_ORDER_NO    NVARCHAR(50)                                 
,BE_REVISION    INT                                 
,BE_WC_CD       NVARCHAR(10)                                
,BE_LINE_CD     NVARCHAR(10)                                 
,BE_PROC_CD     NVARCHAR(10)                              
,BE_RESULT_SEQ  INT                                 
,EQP_CD NVARCHAR(20)                               
                             
)                                
-- 최종 선입선출 테이블       
IF OBJECT_ID('tempdb..#MDM_WO_FIFO_BACK') IS NOT NULL DROP TABLE #MDM_WO_FIFO_BACK;                          
CREATE TABLE #MDM_WO_FIFO_BACK (                                
 CNT           INT                                 
,PROC_CD       NVARCHAR(10)                                 
,ITEM_CD       NVARCHAR(50)                                 
,LOT_NO        NVARCHAR(50)                                 
,CURQTY        NUMERIC(18,4)                                 
,SUMQTY        NUMERIC(18,4)                                 
,M_QTY         NUMERIC(18,4)                                 
,QTY           NUMERIC(18,4)                                 
,BE_ORDER_NO   NVARCHAR(50)                                 
,BE_REVISION   INT                                 
,BE_WC_CD      NVARCHAR(10)                                 
,BE_LINE_CD    NVARCHAR(10)                                
,BE_PROC_CD NVARCHAR(10)                                 
,BE_RESULT_SEQ INT     
) 
 
DECLARE @ACCT_TABLE TABLE ( 
    VAL NVARCHAR(10) 
) 
 
IF @WC_CD = '13GB' AND @PROC_CD IN ('MX','SE') 
BEGIN  
    INSERT INTO @ACCT_TABLE  
    SELECT '' 
END  
ELSE 
BEGIN  
    INSERT INTO @ACCT_TABLE  
    SELECT '2000' UNION ALL SELECT '3000' UNION ALL SELECT '4000' 
END  
 
--SELECT *FROM @ACCT_TABLE 
 
DECLARE @RESULT_PROC TABLE  
( 
     WC_CD     NVARCHAR(10)  
    ,LINE_CD   NVARCHAR(10)  
    ,PROC_CD   NVARCHAR(10)  
) 
 
 
--INSERT INTO @BACK_DATA  
;WITH VAL_PROC AS ( 
SELECT A.WC_CD, B.LINE_CD, A.PROC_CD, A.PROC_SEQ, C.ITEM_CD, C.LOT_NO, C.QTY, D.LOT_INFO, D.ITEM_ACCT  
FROM BA_PROC_MAIN A WITH (NOLOCK)  
INNER JOIN BA_LINE B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.WC_CD = B.WC_CD AND B.LINE_CD = @LINE_CD  
INNER JOIN ST_STOCK_NOW C WITH (NOLOCK) ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD AND A.WC_CD = C.WC_CD AND B.LINE_CD = C.LOCATION_NO  
AND A.PROC_CD = C.PROC_CD AND C.QTY > 0 AND C.BARCODE = '*' 
INNER JOIN V_ITEM D WITH (NOLOCK) ON C.PLANT_CD = D.PLANT_CD AND C.ITEM_CD = D.ITEM_CD AND D.ITEM_CLASS NOT IN (SELECT VAL FROM @ACCT_TABLE) 
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD --AND A.WC_CD = @WC_CD  
  AND A.PROC_SEQ < (SELECT AA.PROC_SEQ FROM BA_PROC_MAIN AA WITH (NOLOCK) WHERE AA.DIV_CD = @DIV_CD AND AA.PLANT_CD = @PLANT_CD 
  AND AA.WC_CD = @WC_CD AND AA.PROC_CD = @PROC_CD  
  ) 
), 
LASTPROC AS ( 
    SELECT MAX(PROC_SEQ) AS PROC_SEQ FROM VAL_PROC 
) 
, LAST_TABLE AS ( 
    SELECT WC_CD, LINE_CD, PROC_CD FROM VAL_PROC A WITH (NOLOCK)  
    WHERE A.PROC_SEQ = (SELECT PROC_SEQ FROM LASTPROC) 
    GROUP BY WC_CD, LINE_CD, PROC_CD  
) 
 
-- 자 이걸로 재공 현황을 파악 한다.  
INSERT INTO @RESULT_PROC 
SELECT WC_CD, LINE_CD, PROC_CD FROM LAST_TABLE  
 
/* 
UPDATE A SET A.PROC_SEQ = A.PROC_SEQ -4 
FROM BA_PROC_MAIN A  
WHERE A.WC_CD IN ('13GB','13GB') 
*/ 
INSERT INTO #MDM_WO_FIFO(                                                            
    ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_RESULT_SEQ, BE_WC_CD, BE_LINE_CD, BE_PROC_CD                                
)      
SELECT  
ROW_NUMBER() OVER (ORDER BY AA.IDX_DT, AA.IDX_SEQ), 'N', AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.QTY, AA.ORDEr_NO, AA.REVISION, AA.RESULT_SEQ, AA.WC_CD, AA.LINE_CD, AA.PROC_CD 
FROM  
( 
    SELECT  
    A.ITEM_CD, 
    C.ITEM_NM, 
    A.LOT_NO, 
    '' AS SL_NM, 
    A.GOOD_QTY  
    -  
    ISNULL((SELECT SUM(USEM_QTY) FROM PD_USEM A1 WITH (NOLOCK)  
    WHERE A1.DIV_CD = A.DIV_CD AND A1.PLANT_CD = A.PLANT_CD AND A1.ITEM_CD = A.ITEM_CD AND A1.LOT_NO = A.LOT_NO  
        AND A1.BE_ORDER_NO = A.ORDER_NO AND A1.BE_REVISION = A.REVISION AND A1.BE_RESULT_SEQ = A.RESULT_SEQ AND A1.BE_PROC_CD = A.PROC_CD  
    ),0) 
    - (ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_IN AA WITH (NOLOCK)                                     
    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO                                     
    AND AA.ORDER_NO = A.ORDER_NO AND AA.ORDER_SEQ = A.REVISION AND AA.RESULTS_SEQ = A.RESULT_SEQ                                   
    AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                   
    ),0)  
    -                                     
    ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_OUT AA WITH (NOLOCK)                                     
    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND  AA.LOCATION_NO = A.LOCATION_NO                                   
    AND AA.ORDER_NO = A.ORDER_NO AND AA.ORDER_SEQ = A.REVISION AND AA.RESULTS_SEQ = A.RESULT_SEQ                                  
    AND AA.MOVE_TYPE IN ('SI','506','503','311','601')                                   
    ),0) 
    ) 
    AS QTY, -- 중요 부분  
    B.QTY AS STOCK_QTY, 
    A.ORDER_NO, 
    A.REVISION, 
    A.RESULT_SEQ,  
    A.WC_CD, 
    A.LINE_CD,  
    A.PROC_CD, 
    A.IDX_DT, A.IDX_SEQ 
    FROM  
    PD_ITEM_IN A WITH (NOLOCK)  
    INNER JOIN @RESULT_PROC A1 ON A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD  
 
    INNER JOIN ST_STOCK_NOW B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD  
    AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LOCATION_NO AND A.PROC_CD = B.PROC_CD AND B.QTY > 0 
    INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD AND C.ITEM_CLASS NOT IN (SELECT VAL FROM @ACCT_TABLE)             
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD  
     AND A.ORDER_NO <> 'PD250113003' 
) AA  
WHERE AA.QTY > 0 
ORDER BY AA.IDX_DT, AA.IDX_SEQ  
 
--SELECT *FROM #MDM_WO_FIFO 
 
INSERT INTO #MDM_WO_FIFO_BACK 
SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                                
AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                                
FROM (                          
        SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                                
        CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                                
        ELSE (Z.SUMQTY - @VALUE) - Z.CURQTY   END  AS QTY                                 
        , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                                
        FROM (                                
        SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                 
        (SELECT SUM(W.CURQTY) FROM #MDM_WO_FIFO W WHERE W.ROWNUM <= Q.ROWNUM  AND W.CURQTY > 0) SUMQTY,                                
        Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                                
        FROM #MDM_WO_FIFO Q) Z                                
        WHERE CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN Z.CURQTY                                 
        ELSE Z.CURQTY - (Z.SUMQTY - @VALUE) END  > 0                                
) AA                                
 
--SELECT *FROM #MDM_WO_FIFO_BACK  
 
DECLARE  
        @PROC_NO        NVARCHAR(50) = ''  
       ,@ORDER_TYPE     NVARCHAR(10) = '' 
       ,@ORDER_FORM     NVARCHAR(10) = '' 
       ,@ROUT_NO        NVARCHAR(10) = ''  
       ,@ROUT_VER       INT          = 0  
        
       ,@MASTER_LOT     NVARCHAR(50) = '' 
-- 마스터 LOT 및 ORDER_NO, REVISION 을 가지고 온다. 솔직히 MASTER LOT 는 의미 없는데..  
SELECT TOP 1 @ORDER_NO = AA.BE_ORDER_NO, @REVISION = AA.BE_REVISION, @MASTER_LOT = AA.LOT_NO                               
FROM                                
(                               
SELECT MAX(CNT) AS CNT, LOT_NO, BE_ORDER_NO, BE_REVISION, SUM(QTY) AS QTY                                
    FROM #MDM_WO_FIFO_BACK 
GROUP BY LOT_NO, BE_ORDER_NO, BE_REVISION                                
) AA                                
ORDER BY AA.QTY DESC, AA.CNT ASC    
 
-- RESULT_SEQ 를 구한다.  
 
SET @RESULT_SEQ = ISNULL((SELECT MAX(A.RESULT_SEQ) 
FROM PD_RESULT A WITH (NOLOCK)  
INNER JOIN PD_ORDER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION  
AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER  
AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD  
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD  
AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N'  
),0) + 1 
 
-- 체크해야 되는 플래그를 가지고 온다.  
DECLARE @OUT_CHK     NVARCHAR(1) = 'N'   -- 실적 체크 
       ,@S_CHK       NVARCHAR(1) = 'N'   -- 일지만 인지 확인 
       ,@MN_S        NVARCHAR(1) = 'N'   -- 설비코드에서 시작 코드인지 확인 
       ,@ITEM_CD     NVARCHAR(50) = ''   -- 품목코드 
       ,@LOT_SEQ     INT          = 0    -- 세부 LOT SEQ 
 
SELECT @OUT_CHK = B.OUT_CHK, @S_CHK = B.S_CHK, @ITEM_CD = A.ITEM_CD, @ORDER_TYPE = A.ORDER_TYPE, @ORDER_FORM = A.ORDER_FORM,  
    @ROUT_NO = A.ROUT_NO, @ROUT_VER = A.ROUT_VER   
    FROM PD_ORDER A WITH (NOLOCK)  
    INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO  
      AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM  
      AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = @PROC_CD  
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDEr_NO AND A.REVISION = @REVISION  
 
SELECT @MN_S = A.MN_S 
    FROM BA_EQP A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.EQP_CD = @EQP_CD  
 
--  
--SELECT @OUT_CHK, @S_CHK, @ITEM_CD, @MN_S, @ORDER_NO, @REVISION, @WC_CD, @LINE_CD, @PROC_CD  
-- LOT 체계를 구한다.  
 
/* 
IF @OUT_CHK = 'Y'  
BEGIN  
 
    IF @S_CHK = 'Y' AND @MN_S = 'Y' 
    BEGIN  
        -- 필요가 없네.. 일단 놔두자.  
        SET @LOT_SEQ = ISNULL((SELECT MAX(A.J_SEQ) FROM PD_RESULT A WITH (NOLOCK)  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE  
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD  
        AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N'),0) + 1 
 
        SET @MASTER_LOT = @MASTER_LOT + '-' + CAST(@LOT_SEQ AS NVARCHAR) 
    END  
 
    IF @OUT_CHK = 'Y' AND @S_CHK = 'N' AND @MN_S = 'N' 
    BEGIN  
        -- 앞 재공을 확인한후에 LOT 를 편성한다.  
        -- 앞 재공이 일반이면? 
 
    END  
END  
*/ 
/* 
-- AUTO_NO 만들기 
DECLARE @STR_DATE NVARCHAR(7)  = ''  
       ,@AUTO_NO  NVARCHAR(50) = '' 
SET @STR_DATE = CONVERT(NVARCHAR(8), GETDATE(), 112)            
 
EXEC USP_CM_AUTO_NUMBERING 'MD', @STR_DATE, 'admin', @AUTO_NO OUT                  
         
INSERT INTO PD_MDM_WORK_SEND  
( 
    AUTO_NO,    ORDER_NO,    WC_CD,    LINE_CD,    PROC_CD,     RESULT_SEQ,     EQP_CD,     ITEM_CD,     LOT_NO,     ITEM_TYPE,  
    REQ_QTY,    REQ_DT,      PLAN_SEQ, BATCH_SEQ,  GBN,         START_DT,       END_DT          
) 
SELECT  
    @AUTO_NO,   @ORDER_NO,   @WC_CD,   @LINE_CD,   @PROC_CD,    @RESULT_SEQ,    @EQP_CD,    @ITEM_CD,    @MASTER_LOT, '', 
    @VALUE,     '',          '',       '',         'R',         GETDATE(),      NULL 
 
 
SELECT *FROM PD_MDM_WORK_SEND 
*/ 
-- 테이블에 쏴준다.  
 
 
 