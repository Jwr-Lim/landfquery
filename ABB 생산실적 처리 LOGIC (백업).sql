-- SP 로 가고 클라이언트에서 처리 하는걸로 진행 예정

BEGIN TRAN 

SET NOCOUNT ON 

/*
UPDATE A SET A.OUT_CHK = 'Y', A.GROUP_S = 'N'
    FROM PD_ORDER_PROC A WITH (NOLOCK) 
WHERE A.ORDER_NO = 'PD250827001'
  AND A.PROC_CD=  'RI'
*/
DECLARE 
 @WC_CD          NVARCHAR(10) = '13GA'
,@LINE_CD        NVARCHAR(10) = '13G01A'
,@PROC_CD        NVARCHAR(10) = 'RI'
,@USER_ID        NVARCHAR(15) = 'SCADA'

DECLARE 
  @DIV_CD        NVARCHAR(10)  = ''
 ,@PLANT_CD      NVARCHAR(10)  = ''
 ,@ORDER_NO      NVARCHAR(50)  = '' 
 ,@REVISION      INT           = 0
 ,@PROC_NO       NVARCHAR(50)  = '' 
 ,@ORDER_TYPE    NVARCHAR(10)  = ''
 ,@ORDER_FORM    NVARCHAR(10)  = '' 
 ,@ROUT_NO       NVARCHAR(10)  = '' 
 ,@ROUT_VER      INT           = 0 
 ,@S_CHK         NVARCHAR(1)   = '' 
 ,@RESULT_SEQ    INT           = 0 
 ,@EQP_CD        NVARCHAR(50)  = '' 
 ,@PROC_SPEC_CD  NVARCHAR(10)  = ''
 ,@VALUE         NUMERIC(18,3) = 0
 
 ,@TAG_ID        NVARCHAR(100) = ''
 ,@SEQ           INT           = 0
 ,@VALUE_STEP    NVARCHAR(2)   = ''
 ,@ROTATION      INT           = 0 
 ,@START_DT      DATETIME      = NULL

 ,@BASE_ITEM_CD   NVARCHAR(50) = '' -- 대표품목

DECLARE @SIL_DT   NVARCHAR(10) 
      ,@STR_DATE NVARCHAR(8)
      ,@RK_DATE  NVARCHAR(10) 
      ,@DAY_FLG  NVARCHAR(1)
      ,@ITEM_CD  NVARCHAR(50) 
      ,@LOT_NO   NVARCHAR(50) 

DECLARE @TOP_LOT     NVARCHAR(20) = ''
       ,@BOT_LOT     NVARCHAR(100) = ''
       ,@MID_LOT     NVARCHAR(10) = ''
       ,@LOT_SEQ     NVARCHAR(10) = ''
       ,@CREATE_LOT  NVARCHAR(100) = ''

DECLARE @USEM_QTY     NUMERIC(18,3) = 0
       ,@PLC_USEM_QTY NUMERIC(18,3) = 0

/*
DECLARE @INSERTED TABLE (
 ORDER_NO       NVARCHAR(50) 
,WC_CD          NVARCHAR(10)
,LINE_CD        NVARCHAR(10) 
,PROC_CD        NVARCHAR(10) 
,EQP_CD         NVARCHAR(50) 
,TAG_ID         NVARCHAR(100)
,SEQ            INT 
,VALUE_STEP     NVARCHAR(1) 
,VALUE          NUMERIC(18,4) 
,ROTATION       INT 
,REMARK         NVARCHAR(50) 
)

INSERT INTO @INSERTED
SELECT 
A.ORDER_NO, 
A.WC_CD, 
A.LINE_CD, 
A.PROC_CD, 
A.EQP_CD, 
A.TAG_ID, 
A.SEQ, 
A.VALUE_STEP,
A.VALUE,
A.ROTATION,
A.REMARK
FROM PD_MDM_RESULT_PROC_SPEC A WITH (NOLOCK) 
WHERE A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
A.END_DT IS NULL
*/
-- 1. 중량 계산으로 처리 진행 

DECLARE @FIFO_TABLE TABLE (                               
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
DECLARE @BACK_TABLE TABLE (                               
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

DECLARE @USEM_INFO TABLE (           
CNT          INT           
,ITEM_CD      NVARCHAR(50)            
,LOT_NO       NVARCHAR(50)            
,ITEM_CLASS   NVARCHAR(10)            
,ITEM_TP      NVARCHAR(10)            
,ITEM_GROUP   NVARCHAR(10)            
,QTY          NUMERIC(18,3)    
,LOT_INFO     NVARCHAR(100)         
)

DECLARE @UPDATE_TABLE TABLE(
     CNT          INT IDENTITY(1,1)
    ,DIV_CD       NVARCHAR(10) 
    ,PLANT_CD     NVARCHAR(10)
    ,ORDER_NO     NVARCHAR(50)
    ,REVISION     INT 
    ,PROC_NO      NVARCHAR(50)  
    ,ORDER_TYPE   NVARCHAR(10) 
    ,ORDER_FORM   NVARCHAR(10) 
    ,ROUT_NO      NVARCHAR(10) 
    ,ROUT_VER     INT 
    ,WC_CD        NVARCHAR(10) 
    ,LINE_CD      NVARCHAR(10) 
    ,PROC_CD      NVARCHAR(10) 
    ,S_CHK        NVARCHAR(1) 
    ,RESULT_SEQ   INT 
    ,EQP_CD       NVARCHAR(50) 
    ,PROC_SPEC_CD NVARCHAR(10) 
    ,VALUE        NUMERIC(18,4)

    ,TAG_ID       NVARCHAR(100) 
    ,SEQ          INT 
    ,VALUE_STEP   NVARCHAR(10)
    ,ROTATION     INT 
    ,START_DT     DATETIME 
)

INSERT INTO @UPDATE_TABLE
SELECT DISTINCT 
    D.DIV_CD, D.PLANT_CD, D.ORDER_NO, D.REVISION, D.PROC_NO, D.ORDER_TYPE, D.ORDER_FORM, D.ROUT_NO, D.ROUT_VER, 
    D.WC_CD, D.LINE_CD, D.PROC_CD, D.S_CHK, D.RESULT_SEQ, E.EQP_CD,
    CASE WHEN CHARINDEX('-',F.TEMP_CD4) = 0 THEN E.PROC_SPEC_CD ELSE 
    CASE WHEN CHARINDEX(E.PROC_SPEC_CD,F.TEMP_CD4) = 0 THEN E.PROC_SPEC_CD ELSE 
    CASE WHEN A.VALUE_STEP = 'S' THEN 
        REPLACE(REPLACE(REPLACE(SUBSTRING(F.TEMP_CD4,0,CHARINDEX('-',F.TEMP_CD4)),' ' ,''),'[',''),']','')
         WHEN A.VALUE_STEP = 'E' THEN 
        REPLACE(REPLACE(REPLACE(SUBSTRING(F.TEMP_CD4,CHARINDEX('-',F.TEMP_CD4) + 1, LEN(F.TEMP_CD4)),' ',''),'[',''),']','')
    END 
    END 
END 
, A.VALUE
, A.TAG_ID
, A.SEQ, A.VALUE_STEP, A.ROTATION, A.START_DT 
FROM PD_MDM_RESULT_PROC_SPEC A
INNER JOIN BA_EQP B WITH (NOLOCK) ON A.EQP_CD = B.EQP_CD 
INNER JOIN POP_EQP_ENO C WITH (NOLOCK) ON A.PROC_CD = C.PROC_CD AND B.EQP_CD = C.EQP_CD AND A.TAG_ID =  C.OPC_AS + '.' + C.OPC_AS + '.' + C.POP_IP_ENO_AS
INNER JOIN PD_RESULT D WITH (NOLOCK) ON A.ORDER_NO = D.ORDER_NO AND A.WC_CD = D.WC_CD AND A.LINE_CD = D.LINE_CD AND 
A.PROC_CD = D.PROC_CD AND D.EDATE IS NULL AND D.S_CHK = 'N'
LEFT JOIN PD_RESULT_PROC_SPEC_VALUE E WITH (NOLOCK) ON D.DIV_CD = E.DIV_CD AND D.PLANT_CD = E.PLANT_CD AND 
D.ORDER_NO = E.ORDER_NO AND D.REVISION = E.REVISION AND D.ORDER_TYPE = E.ORDER_TYPE AND D.ORDER_FORM = E.ORDER_FORM AND 
D.ROUT_NO = E.ROUT_NO AND D.ROUT_VER = E.ROUT_VER AND D.WC_CD = E.WC_CD AND D.LINE_CD = E.LINE_CD AND 
D.PROC_CD = E.PROC_CD AND D.RESULT_SEQ = E.RESULT_SEQ AND E.CYCLE_SEQ = A.ROTATION AND A.EQP_CD = E.EQP_CD AND C.PROC_SPEC_CD = E.PROC_SPEC_CD 
LEFT JOIN BA_SUB_CD F WITH (NOLOCK) ON E.PROC_SPEC_CD = F.SUB_CD AND F.MAIN_CD = 'P2001'
WHERE A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
      A.END_DT IS NULL AND A.VALUE_STEP <> 'SW'
UNION ALL 
SELECT B.DIV_CD, B.PLANT_CD, A.ORDER_NO, B.REVISION, B.PROC_NO, B.ORDER_TYPE, B.ORDER_FORM, B.ROUT_NO, B.ROUT_VER, 
A.WC_CD, A.LINE_CD, A.PROC_CD, 'N' AS S_CHK, 

ISNULL((SELECT A1.RESULT_SEQ FROM PD_RESULT A1 WITH (NOLOCK) WHERE A1.DIV_CD = B.DIV_CD AND A1.PLANT_CD = B.PLANT_CD
AND A1.ORDER_NO = A.ORDER_NO AND A1.WC_CD = A.WC_CD AND A1.LINE_CD = A.LINE_CD AND A1.PROC_CD = A.PROC_CD AND A1.EQP_CD = A.EQP_CD AND A1.EDATE IS NULL)
,0)
 AS RESULT_SEQ, A.EQP_CD, '', A.VALUE, A.TAG_ID, A.SEQ, A.VALUE_STEP, A.ROTATION, A.START_DT 

    FROM PD_MDM_RESULT_PROC_SPEC A WITH (NOLOCK) 
    INNER JOIN PD_ORDER B WITH (NOLOCK) ON A.ORDER_NO = B.ORDER_NO AND B.CFM_FLG = 'Y' AND B.CLOSE_FLG = 'N'
WHERE A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.END_DT IS NULL 
  AND A.VALUE_STEP NOT IN ('S','E','D')
ORDER BY A.START_DT

/*
SELECT *FROM @UPDATE_TABLE 
ROLLBACK 
RETURN 
*/
-- PD_RESULT_PROC_SPEC_VALUE 에 없데이트 진행

-- LOOP 돌아야 되네... 
DECLARE @PROC_SPEC_CNT    INT = 0
       ,@PROC_SPEC_TCNT   INT = 0 

SET @PROC_SPEC_TCNT = ISNULL((SELECT COUNT(*) FROM @UPDATE_TABLE),0)

WHILE @PROC_SPEC_CNT <> @PROC_SPEC_TCNT 
BEGIN 

    SET @PROC_SPEC_CNT = @PROC_SPEC_CNT + 1

    SELECT 
    @DIV_CD = A.DIV_CD, @PLANT_CD = A.PLANT_CD, @ORDER_NO = A.ORDER_NO, @REVISION = A.REVISION, @PROC_NO = A.PROC_NO, 
    @ORDER_NO = A.ORDER_NO, @REVISION = A.REVISION, @ORDER_TYPE = A.ORDER_TYPE, @ORDER_FORM = A.ORDER_FORM, @ROUT_NO = A.ROUT_NO, 
    @ROUT_VER = A.ROUT_VER, @WC_CD = A.WC_CD, @LINE_CD = A.LINE_CD, @PROC_CD = A.PROC_CD, @S_CHK = A.S_CHK, @RESULT_SEQ = A.RESULT_SEQ, 
    @EQP_CD = A.EQP_CD, @PROC_SPEC_CD = A.PROC_SPEC_CD, @VALUE = A.VALUE, 
    @TAG_ID = A.TAG_ID,
    @SEQ = A.SEQ, @VALUE_STEP = A.VALUE_STEP, 
    @ROTATION = A.ROTATION, @START_DT = A.START_DT 
    FROM @UPDATE_TABLE A WHERE A.CNT = @PROC_SPEC_CNT 

    -- 실적공정일때 작업 시작이 이루어져야 한다.
    DECLARE @OUT_CHK NVARCHAR(1) = '' 
    -- 일지만 인지를 체크 한다. 
            ,@S_CHK_LOOP NVARCHAR(1) = ''

    SELECT @OUT_CHK = B.OUT_CHK, @S_CHK_LOOP = B.S_CHK FROM PD_ORDER A WITH (NOLOCK) 
    INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND 
    A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND 
    A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = @PROC_CD 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 

    -- 해당 오더 정보의 RESULT_SEQ 를 가지고 온다.
    SELECT @OUT_CHK, @S_CHK_LOOP

    DECLARE @MN_S NVARCHAR(1) = 'N' -- 이부분은 시작 공정인지 판단할때 쓰이는 FLAG 이다. 

    SET @MN_S = ISNULL((SELECT A.MN_S FROM BA_EQP A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.EQP_CD = @EQP_CD ),'N')

    IF @VALUE_STEP = 'D'
    BEGIN 
        -- 실적 체크를 해야 된다. 

        -- 대표품목은 현재로서는 필요 없다. 
        -- 일단 앞공정의 실적이 있는지 체크를 한다. 
        
        -- 와 이조건은 안맞는데 어떻게 해야 될까? 추후에 정리 다시 해야 된다.. 
        IF EXISTS(
        SELECT B.* FROM PD_ORDER_PROC A WITH (NOLOCK) 
        INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON 
        A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO AND A.GROUP_SEQ >= B.GROUP_SEQ
        AND B.OUT_CHK = 'Y'
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
          AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO 
          AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
        ) 
        BEGIN 

            -- 일지정보에 업데이트 부터 먼저             

            DECLARE @NOW_GROUP_SEQ INT = 0 

            SELECT @NOW_GROUP_SEQ = A.GROUP_SEQ FROM PD_ORDER_PROC A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
            ORDER BY A.GROUP_SEQ 

            -- 재공 리스트를 가지고 와야지.. 일단 이건 
            DECLARE @RESULT_PROC TABLE (
                 WC_CD   NVARCHAR(10) 
                ,LINE_CD NVARCHAR(10)
                ,PROC_CD NVARCHAR(50) 
                ,OUT_CHK NVARCHAR(1) 
            )
            
            DECLARE @OUT_SEQ INT = 0 

            IF @VALUE_STEP = 'D' 
            BEGIN 
                SET @OUT_SEQ = ISNULL((SELECT TOP 1 A.GROUP_SEQ FROM PD_ORDER_PROC A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ < @NOW_GROUP_SEQ 
                    AND A.OUT_CHK = 'Y'
                ORDER BY A.GROUP_SEQ DESC),0)  
                -- 앞공정에 실적이 있는가? 
                -- 그러면 앞공정부터 현공정까지 실적 및 투입까지 다 가지고 온다. 
            END 

            -- 실적이 하나도 없으면 투입은 있는가? 
            IF @OUT_SEQ = 0
            BEGIN 
                SET @OUT_SEQ = ISNULL((SELECT TOP 1 A.GROUP_SEQ FROM PD_ORDER_PROC A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ < @NOW_GROUP_SEQ
                AND A.IN_CHK = 'Y'
                ORDER BY A.GROUP_SEQ),99)
            END 

            INSERT INTO @RESULT_PROC 
            SELECT A.WC_CD, A.LINE_CD, A.PROC_CD, A.OUT_CHK FROM PD_ORDER_PROC A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ BETWEEN @OUT_SEQ AND @NOW_GROUP_SEQ - 1
            
            --SELECT *FROM @RESULT_PROC 
            --ROLLBACK 
            --RETURN 
            --SELECT '재공처리'
            -- PD_USEM 에 넣는다. 
            -- 넣으면서 MASTER_LOT 를 구성한다.
            -- 그리고 LOT 를 채번한다. 

            -- 드디어 여기에 처리가 된다. 
            -- 중량에 따라서 선입선출을 때린다. 
            -- 선입선출 테이블을 만들자. 

            DECLARE @REP_ITEM_CD NVARCHAR(50) = '' 

            SET @REP_ITEM_CD = ISNULL((SELECT A.USEM_ITEM_GROUP FROM PD_ORDER_PROC_SPEC A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
              AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO 
              AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
              AND A.EQP_CD = @EQP_CD AND A.PROC_SPEC_CD = @PROC_SPEC_CD),'')

            IF @REP_ITEM_CD <> '' 
            BEGIN

                DELETE FROM @FIFO_TABLE 
                DELETE FROM @BACK_TABLE
                INSERT INTO @FIFO_TABLE(                                
                               
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
                    AND AA.MOVE_TYPE IN ('SI' ,'506','503','311','601')                                  
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
                    INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD             
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 
                    --AND A.PROC_CD IN (SELECT PROC_CD FROM @RESULT_PROC)
                    AND C.REP_ITEM_CD = @REP_ITEM_CD 
                ) AA 
                WHERE AA.QTY > 0
                ORDER BY AA.IDX_DT, AA.IDX_SEQ 

                --SELECT *FROM @FIFO_TABLE 
                INSERT INTO @BACK_TABLE
                SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                               
                AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                               
                    FROM (                               
                        SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                               
                CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                               
                        ELSE (Z.SUMQTY - @VALUE) - Z.CURQTY   END  AS QTY                                
                        , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                               
                        FROM (                               
                        SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                
                        (SELECT SUM(W.CURQTY) FROM @FIFO_TABLE W WHERE W.ROWNUM <= Q.ROWNUM  AND W.CURQTY > 0) SUMQTY,                               
                        Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                               
                        FROM @FIFO_TABLE Q) Z                               
                        WHERE CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN Z.CURQTY                                
                        ELSE Z.CURQTY - (Z.SUMQTY - @VALUE) END  > 0                               
                    ) AA                               
                END 

                DECLARE @MASTER_LOT NVARCHAR(50) = ''
                SET @MASTER_LOT = ''                                
                        
                SELECT TOP 1 @MASTER_LOT = AA.LOT_NO                              
                FROM                               
                (                              
                SELECT MAX(CNT) AS CNT, LOT_NO, SUM(QTY) AS QTY                               
                    FROM @BACK_TABLE                               
                GROUP BY LOT_NO                               
                ) AA                               
                ORDER BY AA.QTY DESC, AA.CNT ASC                               
                                
                INSERT INTO PD_USEM  
                (                               
                    DIV_CD,              PLANT_CD,              PROC_NO,                 ORDER_NO,                REVISION,                               
                    ORDER_TYPE,          ORDER_FORM,            ROUT_NO,                 ROUT_VER,                WC_CD,                                
                    LINE_CD,             PROC_CD,               RESULT_SEQ,                                             
                    USEM_SEQ,                
                    USEM_WC,             USEM_PROC,                                
                    ITEM_CD,             SL_CD,                 LOCATION_NO,             RACK_CD,                 LOT_NO,         
                    MASTER_LOT,                                
                    PLC_QTY,             USEM_QTY,              DEL_FLG,                 REWORK_FLG,              INSERT_ID,                                
                    INSERT_DT,           UPDATE_ID,             UPDATE_DT,               ITEM_TYPE,                               
                    BE_ORDER_NO,         BE_REVISION,           BE_RESULT_SEQ,           BE_PROC_CD                               
                                                
                )                               
                                
                SELECT                                
                    @DIV_CD,             @PLANT_CD,             @PROC_NO,                @ORDEr_NO, @REVISION,                                
                    @ORDER_TYPE,         @ORDER_FORM,           @ROUT_NO,                @ROUT_VER,               @WC_CD,                                
                    @LINE_CD,            @PROC_CD,              @RESULT_SEQ,                                            
                    ISNULL((SELECT MAX(Z.USEM_SEQ) FROM PD_USEM Z WITH (NOLOCK)                                
                    WHERE Z.DIV_CD = @DIV_CD AND Z.PLANT_CD = @PLANT_CD AND Z.ORDER_NO = @ORDER_NO AND Z.REVISION = @REVISION AND Z.ORDER_TYPE = @ORDER_TYPE                                
                    AND Z.ORDER_FORM = @ORDER_FORM AND Z.ROUT_NO = @ROUT_NO AND Z.ROUT_VER = @ROUT_VER AND Z.WC_CD = @WC_CD AND Z.LINE_CD = @LINE_CD AND Z.PROC_CD = @PROC_CD AND Z.RESULT_SEQ = @RESULT_SEQ),0)                               
                    + A.CNT,                               
                    @WC_CD,              A.PROC_CD,                                
                    A.ITEM_CD,            '3000',            @LINE_CD,                '*',                     A.LOT_NO,                                
                    @MASTER_LOT,                                
                    A.QTY,               A.QTY,                 'N',                     'N',                     @USER_ID,                                
                    GETDATE(),           @USER_ID,              GETDATe(),          'J',                               
                    A.BE_ORDER_NO,       A.BE_REVISION,         A.BE_RESULT_SEQ,         A.BE_PROC_CD                               
                FROM @BACK_TABLE A     
                
                --SELECT *FROM PD_USEM WHERE INSERT_DT >= '2025-09-04'
                -- LOT 를 만듭시다. 
                -- 앞에 실적이 없는 상태이면? 날짜 현날짜로 가지고 가고
                -- 앞에 실적이 있으면? 그 마스터 LOT 의 실적을 따라가야 된다. 

                IF NOT EXISTS(SELECT *FROM @RESULT_PROC WHERE OUT_CHK = 'Y')
                BEGIN 
                    SET @SIL_DT = dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')
--                    SELECT @SIL_DT 
           
                    DELETE @USEM_INFO 


                    INSERT INTO @USEM_INFO (           
                    CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY, LOT_INFO            
                    )  
                    SELECT C.SEQ, D.ITEM_CD, D.LOT_NO, C.ITEM_CLASS, D.ITEM_TP, C.ITEM_GROUP_CD3, D.QTY, D.LOT_INFO
                    FROM PD_ORDER A WITH (NOLOCK)        
                    INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD        
                    INNER JOIN BA_LOT_CREATE_SEQ C WITH (NOLOCK) ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD AND B.ITEM_ACCT = C.ITEM_ACCT        
                    LEFT JOIN        
                    (       
                        SELECT AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, SUM(AA.QTY) AS QTY, AA.LOT_INFO--, BB.SEQ          
                        FROM            
                        (           
                            SELECT ROW_NUMBER() OVER (ORDER BY MIN(D.SEQ)) AS CNT,          
                            ROW_NUMBER() OVER (PARTITION BY B.ITEM_CLASS, B.ITEM_GROUP_CD3 ORDER BY B.ITEM_GROUP_CD3, SUM(A.USEM_QTY) DESC) AS RANK,            
                        
                            A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, SUM(A.USEM_QTY) AS QTY, C2.ITEM_ACCT, C1.ITEM_CD AS PRNT_ITEM_CD,
                            B.LOT_INFO           
                            FROM PD_USEM A WITH (NOLOCK)            
                            INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD  AND B.ITEM_CLASS <> '4000'          
                            INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON B.ITEM_CLASS = C.SUB_CD AND C.MAIN_CD = 'B0004'           
                            INNER JOIN PD_ORDER C1 WITH (NOLOCK) ON A.DIV_CD = C1.DIV_CD AND A.PLANT_CD = C1.PLANT_CD AND A.ORDER_NO = C1.ORDER_NO AND A.REVISION = C1.REVISION           
                            AND A.PROC_NO = C1.PROC_NO AND A.ORDER_TYPE = C1.ORDER_TYPE AND A.ORDER_FORM = C1.ORDER_FORM AND A.ROUT_NO = C1.ROUT_NO AND A.ROUT_VER = C1.ROUT_VER AND A.WC_CD = C1.WC_CD AND           
                            A.LINE_CD = C1.LINE_CD           
                            INNER JOIN V_ITEM C2 WITH (NOLOCK) ON C1.PLANT_CD = C2.PLANT_CD AND C1.ITEM_CD = C2.ITEM_CD           
                            LEFT JOIN PD_LOT_SYS D WITH (NOLOCK) ON A.DIV_CD = D.DIV_CD AND A.PLANT_CD = D.PLANT_CD AND A.WC_CD = D.WC_CD AND A.PROC_CD = D.PROC_CD AND C.TEMP_CD1 = D.ITEM_TP AND B.ITEM_GROUP_CD3 = D.ITEM_GROUP           
                            
                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
                            AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ           
                            GROUP BY A.ITEM_CD, A.MASTER_LOT, B.ITEM_CLASS, B.ITEM_GROUP_CD3, C.TEMP_CD1, D.ITEM_TP, D.ITEM_GROUP , C2.ITEM_ACCT, C1.ITEM_CD, B.LOT_INFO
                
                        ) AA           
                        WHERE AA.RANK = 1          
                        GROUP BY AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, AA.ITEM_ACCT, AA.LOT_INFO     
                            
                    ) D ON C.ITEM_CLASS = CASE WHEN D.ITEM_CLASS = '3000' THEN '2000' ELSE D.ITEM_CLASS END  AND C.ITEM_GROUP_CD3 = D.ITEM_GROUP        
                
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION        
                    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD        
                    AND A.LINE_CD = @LINE_CD        
                    

                    DECLARE @LOT_CHK NVARCHAR(1) = 'N' 
                    -- TOP LOT 날짜
                    SET @TOP_LOT = 'G' + CONVERT(NVARCHAR(4),CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)           
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND            
                    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND            
                    A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ           
                    ) AS DATETIME  ), 12)           
                    
                    -- 중간, 제일 중요

                    SELECT @MID_LOT = STRING_AGG(ISNULL(LOT_INFO,'XXX'), '-') 
                    FROM @USEM_INFO
                    -- 마지막 UT 
                    SET @BOT_LOT = 
                    CASE WHEN ISNULL((  
                    SELECT B.TEMP_CD5   
                        FROM V_ITEM A WITH (NOLOCK)   
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'  
                        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD   
                
                    ),'') = '' THEN   
                    ISNULL((                         
                    SELECT A.LOT_INITIAL FROM  BA_ROUTING_HEADER A WITH (NOLOCK)                          
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ROUT_NO = @ROUT_NO AND A.[VERSION] = @ROUT_VER ),'')   
                    ELSE   
                    ISNULL((  
                        SELECT B.TEMP_CD5   
                        FROM V_ITEM A WITH (NOLOCK)   
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'  
                        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD   
                        
                    ),'')  
                    END   
                    +            
                    ISNULL(           
                    (SELECT B.TEMP_CD1 FROM BA_SUB_CD A WITH (NOLOCK)            
                    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.TEMP_CD3 = B.SUB_CD AND B.MAIN_CD = 'BA204'            
                    WHERE A.MAIN_CD = 'SAP01' AND A.SUB_CD = (           
                    SELECT ORDER_TYPE FROM PD_ORDER A WITH (NOLOCK)            
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION ))           
                            
                    ,'')           
                    -- 마지막 SEQ 

                    IF EXISTS(SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)            
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (           
                        
                    SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)           
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND            
                    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND            
                    A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ           
                    ) AS DATETIME), 120)            
                    )           
                    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
                    )           
                    BEGIN            
                        SELECT @LOT_SEQ = CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) + dbo.LPAD(A.LOT_SEQ + CASE WHEN @LOT_CHK = 'N' THEN 1 ELSE 0 END,3,0)           
                        FROM PD_LOT_SEQ A WITH (NOLOCK)            
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (           
                        
                        SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)           
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND            
                        A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND            
                        A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ           
                        ) AS DATETIME), 120)            
                        )           
                        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
                    END            
                    ELSE            
                    BEGIN            
                        SELECT @LOT_SEQ = CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) + dbo.LPAD(1,3,0)           
                    END            
                    -- 합체
                    
                    SET @CREATE_LOT = @TOP_LOT + '-' + @MID_LOT + '-' + @BOT_LOT + '-' + @LOT_SEQ

                    
                END 

                -- 실적에 업데이트 진행         
                -- 소요량 합계를 가지고 온다.

                SELECT @USEM_QTY = ISNULL(SUM(A.USEM_QTY),0), @PLC_USEM_QTY = ISNULL(SUM(A.PLC_QTY),0)
                FROM PD_USEM A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND            
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND            
                A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ           
                
                
                UPDATE A SET A.RESULT_QTY = @USEM_QTY, A.GOOD_QTY = @PLC_USEM_QTY, A.LOT_NO = @CREATE_LOT, A.LOT_SEQ = CAST(RIGHT(@LOT_SEQ,3) AS INT)
                FROM PD_RESULT A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND            
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND            
                A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ           
                    
        END 
        ELSE 
        BEGIN 
            -- 자기것 업데이트 
            -- PD_USEM PLC_QTY 에 업데이트 진행 
            -- 두개가 들어갈 경우는 선입선출 처리 한다. 어쩔수 없음. 근데 PD_USEM 의 IN_CHK = 'N' 인것을 기준으로 처리한다.

            UPDATE A SET A.PLC_QTY = @VALUE
            FROM PD_USEM A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
              AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO 
              AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ

            UPDATE A SET A.RESULT_QTY = @VALUE, A.GOOD_QTY = @VALUE 
            FROM PD_RESULT A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
              AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO 
              AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ
        END
    -- 실적의 마지막. 
    END 

    -- 와 작업종료다.
    IF @VALUE_STEP = 'W'
    BEGIN 
        -- 마지막 실적이 아니면?
        -- 실적만 생성하고 마무리 한다. 
        IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'N'                          
        BEGIN 
            -- 실적 작업 종료 처리
            -- PD_ITEM_IN 에 집어 넣으면서? 
            -- 순서 하나 추가 하자. 이게 필요하다. 
            -- 원료투입은 sap 처리가 필요하다. 

            DECLARE @IDX_DT  NVARCHAR(10) = CONVERT(NVARCHAR(10), GETDATE(), 120) 
                   ,@IDX_SEQ INT = 0 
            
            DECLARE @DEPARTMENT NVARCHAR(100) = ''
                 
            SET @IDX_SEQ = ISNULL((SELECT MAX(A.IDX_SEQ) FROM PD_ITEM_IN A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IDX_DT = @IDX_DT),0) + 1

            -- PD_ITEM_IN 에 INSERT 

            SET @DEPARTMENT = ISNULL((SELECT STUFF(  
            (SELECT ',' + RIGHT(A.REQ_DT,2) + '-' + dbo.LPAD(A.PLAN_SEQ, 3,0) + CASE WHEN ISNULL(A.BATCH_NO,'') = '' THEN '' ELSE '-' + CAST(A.BATCH_NO AS NVARCHAR) END 
            FROM PD_USEM A WITH (NOLOCK)   
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO   
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD   
            AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ   
            AND ISNULL(A.REQ_NO,'') <> ''  
            GROUP BY A.REQ_DT, A.PLAN_SEQ, A.BATCH_NO  
            FOR XML PATH('')),1,1,''  
            )),'')   


            INSERT INTO PD_ITEM_IN 
            (
                DIV_CD,          PLANT_CD,            PROC_NO,              ORDER_NO,            REVISION, 
                ORDER_TYPE,      ORDER_FORM,          ROUT_NO,              ROUT_VER,            WC_CD, 
                LINE_CD,         PROC_CD,             S_CHK,                RESULT_SEQ,          SEQ, 
                ITEM_CD,         LOT_NO,              SL_CD,                LOCATION_NO,         RACK_CD, 
                BARCODE,         SIL_DT,              DEPARTMENT,           IDX_DT,              IDX_SEQ, 
                GOOD_QTY,        INSERT_ID,           INSERT_DT,            UPDATE_ID,           UPDATE_DT
            )

            SELECT 
                A.DIV_CD,        A.PLANT_CD,          A.PROC_NO,            A.ORDER_NO,          A.REVISION, 
                A.ORDER_TYPE,    A.ORDER_FORM,        A.ROUT_NO,            A.ROUT_VER,          A.WC_CD, 
                A.LINE_CD,       A.PROC_CD,           A.S_CHK,              A.RESULT_SEQ,        1,
                A.ITEM_CD,       A.LOT_NO,            '3000',               A.LINE_CD,           '*',
                '*',             A.SIL_DT,            @DEPARTMENT,          @IDX_DT,             @IDX_SEQ, 
                A.GOOD_QTY,      @USER_ID,            GETDATE(),            @USER_ID,            GETDATE()
                
                FROM PD_RESULT A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND 
            A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND 
            A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
            A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD 


            -- 이후 PD_RESULT EDATE 에 종료 
            UPDATE A SET A.EDATE = GETDATE()
                FROM PD_RESULT A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND 
            A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND 
            A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
            A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD 

            -- SAP Interface 를 날려야 되나요?

            IF EXISTS(
                SELECT *FROM PD_RESULT A WITH (NOLOCK) 
                INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO AND 
                A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND 
                A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND 
                A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND 
            A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND 
            A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
            A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD 
            )
            BEGIN 
                -- SAMPLE 테이블 처리 

                
                -- SAP 처리 진행
                SELECT 'SAP 처리'
            END 

            UPDATE B SET B.LOT_NO = A.LOT_NO, B.RESULT_SEQ = A.RESULT_SEQ 
               FROM PD_RESULT A WITH (NOLOCK) 
               INNER JOIN FlexAPI_NEW.DBO.IFM422_Master B WITH (NOLOCK) ON 
               A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDEr_NO AND A.REVISION = B.ORDER_SEQ AND A.WC_CD = B.WC_CD 
               AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD 
               AND LEFT(A.LOT_NO,5) + RIGHT(A.LOT_NO,3) = LEFT(B.QC_LOT_NO,5) + RIGHT(B.QC_LOT_NO,3)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND 
            A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND 
            A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND 
            A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD 

            



        END 
        ELSE 
        BEGIN 
            SELECT '포장 작업 종료'
        END 
        
    END 

    -- 작업시작 
    IF @VALUE_STEP = 'SW'
    BEGIN 


        IF @OUT_CHK = 'Y'
        BEGIN 
            IF @S_CHK_LOOP = 'N' 
            BEGIN 
                SET @RESULT_SEQ = ISNULL((
                    SELECT MAX(A.RESULT_SEQ) FROM PD_RESULT A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD 
                AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.PROC_CD = @PROC_CD 
                ),0) + 1
                
                -- 작업시작 생성 


                SELECT @ITEM_CD = A.ITEM_CD FROM PD_ORDER A WITH (NOLOCK) 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD 
                AND A.LINE_CD = @LINE_CD --AND A.S_CHK = @S_CHK AND A.PROC_CD = @PROC_CD 
            
                SET @STR_DATE = CONVERT(NVARCHAR(8), GETDATE(), 112)           

                EXEC USP_CM_AUTO_NUMBERING 'PR', @STR_DATE, @USER_ID, @LOT_NO OUT                 
                SET @RK_DATE = CONVERT(NVARCHAR(10), GETDATE(), 120)
                SET @SIL_DT = dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')
                SET @DAY_FLG = dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'D') 
                
                INSERT INTO PD_RESULT 
                (
                    DIV_CD,            PLANT_CD,             PROC_NO,                ORDER_NO,                REVISION,      
                    ORDER_TYPE,        ORDER_FORM,           ROUT_NO,                ROUT_VER,                WC_CD, 
                    LINE_CD,           PROC_CD,              S_CHK,                  RESULT_SEQ,              ITEM_CD, 
                    LOT_NO,            LOT_SEQ,              RESULT_QTY,             GOOD_QTY,                GROUP_LOT, 
                    GROUP_YN,          RK_DATE,              SDATE,                  EDATE,                   SIL_DT, 
                    DAY_FLG,           J_CHK,                J_SEQ,                  J_VAL,                   EQP_CD,                   
                    INSERT_ID,         INSERT_DT,            UPDATE_ID,              UPDATE_DT,               ZMESIFNO
                    
                )
                SELECT 
                    @DIV_CD,           @PLANT_CD,            @PROC_NO,               @ORDER_NO,               @REVISION, 
                    @ORDER_TYPE,       @ORDER_FORM,          @ROUT_NO,               @ROUT_VER,               @WC_CD, 
                    @LINE_CD,          @PROC_CD,             'N',                    @RESULT_SEQ,             @ITEM_CD, 
                    @LOT_NO,           0,                    0,                      0,                       @LOT_NO, 
                    'N',               @RK_DATE,             GETDATE(),              NULL,                    @SIL_DT, 
                    @DAY_FLG,          'N',                  0,                      '%',                     @EQP_CD,
                    @USER_ID,          GETDATE(),            @USER_ID,               GETDATE(),               ''
            
                -- 이제 어디에 집어넣어야 하는가?

                -- SPEC 이관 한다. 
                -- 일단 그냥 이관하자.
                IF NOT EXISTS(SELECT *FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)           
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
                AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ --AND A.CYCLE_SEQ = @CYCLE_SEQ           
                )           
                BEGIN            
                
                    DECLARE @IN_SEQ INT = 0            
                
                    SET @IN_SEQ = ISNULL((SELECT MAX(A.IN_SEQ) FROM PD_RESULT_PROC_SPEC_VALUE_HIS A WITH (NOLOCK)           
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IN_DATE = CONVERT(NVARCHAR(10), GETDATE(), 120)            
                    ), 0) + 1           
                    
                    INSERT INTO PD_RESULT_PROC_SPEC_VALUE_HIS           
                    (           
                        DIV_CD,             PLANT_CD,          WC_CD,              LINE_CD,             PROC_CD,            
                        IN_DATE,                       
                        IN_SEQ,             ORDER_NO,          REVISION,           RESULT_SEQ,          S_CHK,        
                        CYCLE_SEQ,          INSERT_ID,         INSERT_DT,          UPDATE_ID,           UPDATE_DT            
                    )           
                    SELECT            
                        @DIV_CD,            @PLANT_CD,         @WC_CD,             @LINE_CD,            @PROC_CD,            
                        CONVERT(NVARCHAR(10), GETDATE(), 120),            
                        @IN_SEQ,            @ORDER_NO,         @REVISION,          @RESULT_SEQ,         @S_CHK,         
                        1,                  @USER_ID,          GETDATE(),          @USER_ID,            GETDATE()           
                    
                    INSERT INTO PD_RESULT_PROC_SPEC_VALUE (           
                        DIV_CD,              PLANT_CD,             ORDER_NO,              REVISION,              ORDER_TYPE,             ORDER_FORM,            
                        ROUT_NO,             ROUT_VER,             WC_CD,                 LINE_CD,               PROC_CD,                S_CHK,           RESULT_SEQ,            
                        CYCLE_SEQ,           SEQ,                  SPEC_VERSION,          PROC_SPEC_CD,          EQP_CD,                 SPEC_VALUE_TYPE,            
                        SPEC_VALUE,          REMARK,               INSERT_ID,             INSERT_DT,             UPDATE_ID,              UPDATE_DT,           
                        IN_DATE,             IN_SEQ,               GROUP_SPEC_CD           
                    )           
                    
                    SELECT A.DIV_CD,         A.PLANT_CD,           A.ORDER_NO,            A.REVISION,            A.ORDER_TYPE,           A.ORDER_FORM,            
                        A.ROUT_NO,           A.ROUT_VER,           A.WC_CD,               A.LINE_CD,             A.PROC_CD,              @S_CHK,          @RESULT_SEQ,           
                        1,--A.RECYCLE_NO,        
                        A.SEQ,                A.SPEC_VERSION,        A.PROC_SPEC_CD,        A.EQP_CD,               A.SPEC_VALUE_TYPE,            
                        CASE WHEN A.SET_FLAG = 'Y' AND       
                        A.USEM_ITEM_GROUP = '' AND A.PROC_SPEC_VALUE <> '' THEN       
                        A.PROC_SPEC_VALUE ELSE     
                        CASE WHEN A.PLC_FLAG = 'Y' AND A.AUTO_PLC_FLAG  = 'Y'     
                        THEN dbo.USP_OPC_DATA_FMT_CONV_FUNC(A.DIV_CD, A.EQP_CD, BB.OPC_AS + '.' + BB.OPC_AS + '.' + BB.POP_IP_ENO_AS, BB.OPC_AS, BB.POP_IP_ENO)    
                        ELSE     
                        ''     
                        END     
                        END       
                            
                        ,                  '',                   @USER_ID,              GETDATE(),             @USER_ID,               GETDATE(),                 CONVERT(NVARCHAR(10), GETDATE(), 120),           
                        @IN_SEQ, A.GROUP_SPEC_CD           
                        FROM PD_ORDER_PROC_SPEC A WITH (NOLOCK)           
                        LEFT JOIN POP_EQP_ENO BB WITH (NOLOCK) ON BB.DIV_CD = @DIV_CD AND BB.PLANT_CD = @PLANT_CD          
                        AND A.EQP_CD = BB.EQP_CD AND BB.PROC_CD = @PROC_CD AND A.PROC_SPEC_CD = BB.PROC_SPEC_CD          
                        
                    WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
                    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
                    --AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)           
                    --AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)   
                    --AND A.RECYCLE_NO IN (@CYCLE_SEQ, '')          
                END             
            END   
        END 
    END 

    -- 일지 정보 UPDATE 
    UPDATE A SET A.SPEC_VALUE = @VALUE 
        FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION --AND A.PROC_NO = @PROC_NO
      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.PROC_SPEC_CD = @PROC_SPEC_CD 
      AND A.EQP_CD = @EQP_CD 
      AND ISNULL(A.SPEC_VALUE,'') = ''

    -- 마지막 종료.
    UPDATE A SET A.END_DT = GETDATE() FROM PD_MDM_RESULT_PROC_SPEC A WITH (NOLOCK) 
    WHERE A.ORDER_NO = @ORDER_NO AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD 
      AND A.TAG_ID = @TAG_ID AND A.SEQ = @SEQ AND A.VALUE_STEP = @VALUE_STEP AND A.VALUE = @VALUE AND A.ROTATION = @ROTATION 
      AND A.START_DT = @START_DT AND A.END_DT IS NULL
    

-- 루프의 마지막
END 


SELECT *FROM PD_RESULT A WITH (NOLOCK) 
INNER JOIN PD_RESULT_PROC_SPEC_VALUE B WITH (NOLOCK) ON 
A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND 
A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND 
A.LINE_CD = B.LINE_CD AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ AND B.SPEC_VALUE <> '' AND A.EQP_CD = B.EQP_CD 
WHERE A.EDATE IS NULL


-- 작업중이면 DEL_YN 을 Y로 업데이트 친다.

UPDATE A SET A.DEL_FLG = 'Y'
    FROM PD_RESULT A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.REVISION = @REVISION AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ 
      AND A.EDATE IS NULL 
      AND A.DEL_FLG = 'N'


SELECT *FROM PD_RESULT A WITH (NOLOCK) 
WHERE A.ORDER_NO = 'PD250827001'

SELECT *FROM PD_ITEM_IN A WITH (NOLOCK) 
WHERE A.ORDER_NO = 'PD250827001'

ROLLBACK 