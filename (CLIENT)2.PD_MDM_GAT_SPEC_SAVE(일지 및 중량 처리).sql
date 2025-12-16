/*
----------------------------------------------------
MDM 실적 처리 Gathering 프로그램 중량처리 (SPEC)
----------------------------------------------------
작업일자 : 25.09.20 
작업자 : ljw

*/
ALTER PROC USP_PD_GAT_SPEC_SAVE_NEW(
     @PD_AUTO_NO   NVARCHAR(50)     
    ,@AUTO_NO      NVARCHAR(50)
    ,@DIV_CD       NVARCHAR(10) 
    ,@PLANT_CD     NVARCHAR(10)
    ,@ORDER_NO     NVARCHAR(50) 
    ,@REVISION     INT 
    ,@PROC_NO      NVARCHAR(50) 
    ,@ORDER_TYPE   NVARCHAR(10)
    ,@ORDER_FORM   NVARCHAR(10) 
    ,@ROUT_NO      NVARCHAR(10) 
    ,@ROUT_VER     INT 
    ,@WC_CD        NVARCHAR(10) 
    ,@LINE_CD      NVARCHAR(10) 
    ,@PROC_CD      NVARCHAR(10) 
    ,@S_CHK        NVARCHAR(1) 
    ,@RESULT_SEQ   INT 
    ,@EQP_CD       NVARCHAR(100 )
    ,@SPEC_CD      NVARCHAR(10) 
    ,@VALUE        NUMERIC(18,3) 
    ,@VALUE_STR    NVARCHAR(100) 
    ,@TAG_ID       NVARCHAR(1000) 
    ,@SEQ          INT 
    ,@VALUE_STEP   NVARCHAR(10) 
    ,@COL_CHK      NVARCHAR(10) 
    ,@ROTATION     INT 
    ,@GROUP_CHK    NVARCHAR(1) = ''
    ,@OUT_CHK      NVARCHAR(1) = ''
    ,@USER_ID      NVARCHAR(15)   = 'MDMGA'
    ,@MSG_CD       NVARCHAR(4)    OUTPUT 
    ,@MSG_DETAIL   NVARCHAR(MAX)  OUTPUT

)
AS 

SET NOCOUNT ON 

BEGIN TRY

DECLARE @SIL_DT   NVARCHAR(10) 
      ,@STR_DATE NVARCHAR(8)
      ,@RK_DATE  NVARCHAR(10) 
      ,@DAY_FLG  NVARCHAR(1)
      ,@ITEM_CD  NVARCHAR(50) 
      ,@LOT_NO   NVARCHAR(50) 

DECLARE @RK_SEQ INT = 0 

DECLARE @USEM_QTY     NUMERIC(18,3) = 0
       ,@PLC_USEM_QTY NUMERIC(18,3) = 0

DECLARE @TOP_LOT     NVARCHAR(50) = ''
       ,@BOT_LOT     NVARCHAR(100) = ''
       ,@MID_LOT     NVARCHAR(50) = ''
       ,@LOT_SEQ     NVARCHAR(10) = ''
       ,@CREATE_LOT  NVARCHAR(100) = ''


DECLARE @NOW_GROUP_SEQ INT = 0 
DECLARE @OUT_SEQ INT = 0 
DECLARE @MASTER_LOT NVARCHAR(50) = ''

DECLARE @FIFO_TABLE TABLE (
    ROWNUM INT --IDENTITY(1,1)                                
,GBN NVARCHAR(10)                                
,PROC_CD NVARCHAR(10)                           
,ITEM_CD NVARCHAR(50)                                
,LOT_NO NVARCHAr(50)                                
,CURQTY NUMERIC(18,4)                                
,BE_ORDER_NO NVARCHAR(50)                                
,BE_REVISION INT                                
,BE_WC_CD NVARCHAR(10)                               
,BE_LINE_CD NVARCHAR(10)                                
,BE_PROC_CD NVARCHAR(10)                             
,BE_RESULT_SEQ INT                                
,EQP_CD NVARCHAR(20)                              
                            
)                               
-- 최종 선입선출 테이블                               
DECLARE @BACK_TABLE TABLE (
    CNT INT                                
,PROC_CD NVARCHAR(10)                                
,ITEM_CD NVARCHAR(50)                                
,LOT_NO NVARCHAR(50)                                
,CURQTY NUMERIC(18,4)                                
,SUMQTY NUMERIC(18,4)                                
,M_QTY NUMERIC(18,4)                                
,QTY NUMERIC(18,4)     
,PLC_QTY NUMERIC(18,4)                           
,BE_ORDER_NO NVARCHAR(50)                                
,BE_REVISION INT                                
,BE_WC_CD NVARCHAR(10)                                
,BE_LINE_CD NVARCHAR(10)                               
,BE_PROC_CD NVARCHAR(10)                                
,BE_RESULT_SEQ INT    
)

DECLARE @USEM_INFO TABLE (
    CNT INT           
,ITEM_CD NVARCHAR(50)            
,LOT_NO NVARCHAR(50)            
,ITEM_CLASS NVARCHAR(10)            
,ITEM_TP NVARCHAR(10)            
,ITEM_GROUP NVARCHAR(10)            
,QTY NUMERIC(18,3)    
,LOT_INFO NVARCHAR(100)         
)
-- 재공 리스트를 가지고 와야지.. 일단 이건 
DECLARE @RESULT_PROC TABLE (
    WC_CD NVARCHAR(10) 
    ,LINE_CD NVARCHAR(10)
    ,PROC_CD NVARCHAR(50) 
    ,OUT_CHK NVARCHAR(1) 
)

DECLARE @EQP_TBL TABLE (
    EQP_CD NVARCHAR(50) 
)

-- MN_S 일때를 판단 

DECLARE @MN_S NVARCHAR(1) = 'N' -- 이부분은 시작 공정인지 판단할때 쓰이는 FLAG 이다. 

SET @MN_S = ISNULL((SELECT A.MN_S
FROM BA_EQP A WITH (NOLOCK)
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.EQP_CD = @EQP_CD and A.PROC_CD = @PROC_CD),'N')


--SELECT @SPEC_CD, @MN_S, @COL_CHK 

IF @SPEC_CD <> '' AND @COL_CHK = 'V' OR (@SPEC_CD = '' AND @MN_S = 'Y' AND @COL_CHK = 'V')
OR (@SPEC_CD = '' AND @MN_S = 'N' AND @COL_CHK = 'B')
BEGIN

    --DECLARE @OUT_CHK NVARCHAR(1) = '' 
     -- 일지만 인지를 체크 한다.    
    DECLARE @S_CHK_LOOP NVARCHAR(1) = ''

    SELECT @OUT_CHK = B.OUT_CHK, @S_CHK_LOOP = B.S_CHK
    FROM PD_ORDER A WITH (NOLOCK)
        INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND
            A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND
            A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = @PROC_CD
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD



    IF @COL_CHK = 'V' OR @COL_CHK = 'B'
    BEGIN

        -- 실적 체크를 해야 된다. 

        -- 대표품목은 현재로서는 필요 없다. 
        -- 일단 앞공정의 실적이 있는지 체크를 한다. 

        -- 와 이조건은 안맞는데 어떻게 해야 될까? 추후에 정리 다시 해야 된다.. 
        -- rk 처리 방안을 마련

        IF EXISTS(
        SELECT B.*
        FROM PD_ORDER_PROC A WITH (NOLOCK)
            INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON 
        A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO AND A.GROUP_SEQ >= B.GROUP_SEQ
                AND B.OUT_CHK = 'Y'
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
            AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO
            AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
        ) 
        BEGIN
            -- 일지정보에 업데이트 부터 먼저             

            SELECT @NOW_GROUP_SEQ = A.GROUP_SEQ
            FROM PD_ORDER_PROC A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
            ORDER BY A.GROUP_SEQ

            SET @OUT_SEQ = ISNULL((SELECT TOP 1
                A.GROUP_SEQ
            FROM PD_ORDER_PROC A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ < @NOW_GROUP_SEQ
                AND A.OUT_CHK = 'Y'
            ORDER BY A.GROUP_SEQ DESC),0)
            -- 앞공정에 실적이 있는가? 
            -- 그러면 앞공정부터 현공정까지 실적 및 투입까지 다 가지고 온다. 

            -- 실적이 하나도 없으면 투입은 있는가? 
            IF @OUT_SEQ = 0
            BEGIN
                SET @OUT_SEQ = ISNULL((SELECT TOP 1
                    A.GROUP_SEQ
                FROM PD_ORDER_PROC A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ < @NOW_GROUP_SEQ
                    AND A.IN_CHK = 'Y'
                ORDER BY A.GROUP_SEQ),99)
            END


            IF @MN_S = 'E' 
            BEGIN
                INSERT INTO @RESULT_PROC
                SELECT TOP 1
                    A.WC_CD, A.LINE_CD, A.PROC_CD, A.OUT_CHK
                FROM PD_ORDER_PROC A
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ BETWEEN @OUT_SEQ AND @NOW_GROUP_SEQ
                ORDER BY A.PROC_SEQ DESC
            END 
            ELSE 
            BEGIN

                INSERT INTO @RESULT_PROC
                SELECT A.WC_CD, A.LINE_CD, A.PROC_CD, A.OUT_CHK
                FROM PD_ORDER_PROC A
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ BETWEEN @OUT_SEQ AND @NOW_GROUP_SEQ - 1

            END
            --SELECT *FROM @RESULT_PROC 
            --SELECT '재공처리'
            -- PD_USEM 에 넣는다. 
            -- 넣으면서 MASTER_LOT 를 구성한다.
            -- 그리고 LOT 를 채번한다. 

            -- 드디어 여기에 처리가 된다. 
            -- 중량에 따라서 선입선출을 때린다. 
            -- 선입선출 테이블을 만들자. 

            DECLARE @REP_ITEM_CD NVARCHAR(50) = ''

            SET @REP_ITEM_CD = ISNULL((SELECT A.USEM_ITEM_GROUP
            FROM PD_ORDER_PROC_SPEC_V2 A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO
                AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
                AND A.EQP_CD = @EQP_CD AND A.PROC_SPEC_CD = @SPEC_CD
                AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION
                )
                     AND ISNULL(A.USEM_ITEM_GROUP,'') <> ''
           
                ),'')

--            SELECT @REP_ITEM_CD 

            IF @COL_CHK = 'B' 
            BEGIN 

                SET @VALUE = ISNULL((SELECT SUM(A.QTY)
                    FROM ST_STOCK_NOW A WITH (NOLOCK) 
                    INNER JOIN @RESULT_PROC B ON A.WC_CD = B.WC_CD AND A.LOCATION_NO = B.LINE_CD AND A.PROC_CD = B.PROC_CD 

                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
                AND A.QTY > 0 ),0)
                
                SET @REP_ITEM_CD = ISNULL((
                    SELECT C.REP_ITEM_CD 
                    FROM ST_STOCK_NOW A WITH (NOLOCK) 
                    INNER JOIN @RESULT_PROC B ON A.WC_CD = B.WC_CD AND A.LOCATION_NO = B.LINE_CD AND A.PROC_CD = B.PROC_CD 
                    INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD AND C.ITEM_CLASS = '1000'
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD
                ),'')

            END 
            
            -- mn_s 가 n 이면? 
            -- 설비코드의 공정 리스트를 가지고 온다. 
            -- MN_S = 'E' 인거는 이번 형태로 진행할것이다. 
            IF @MN_S IN ('E')
            BEGIN
                INSERT INTO @EQP_TBL 
                SELECT B.EQP_CD FROM BA_EQP A WITH (NOLOCK) 
                INNER JOIN BA_EQP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.TP = B.TP 
                AND B.MN_S = 'Y'
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.EQP_CD = @EQP_CD

                IF NOT EXISTS(SELECT *FROM @EQP_TBL)
                BEGIN
                    INSERT INTO @EQP_TBL
                    SELECT B.EQP_CD FROM @RESULT_PROC A 
                    INNER JOIN BA_EQP B WITH (NOLOCK) ON A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD 
                    AND B.MN_S = 'Y'
                END 
            END
            ELSE 
            BEGIN 
                -- 해당 공정에 설비가 없다.. 
                -- 이런경우 앞 재공 공정에서 찾아야 된는데.. ㅜㅜ

                -- 앞공정의 설비 리스트 
                
                IF EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
                AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                AND A.EDATE IS NULL 
                )
                BEGIN
                    INSERT INTO @EQP_TBL 
                    SELECT A.BE_EQP_CD FROM PD_MDM_RESULT_GROUP A WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
                    AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                    AND A.EDATE IS NULL 
                END
                ELSE
                BEGIN

                    INSERT INTO @EQP_TBL 
                    SELECT B.EQP_CD FROM @RESULT_PROC A 
                    INNER JOIN BA_EQP B WITH (NOLOCK) ON A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND ISNULL(B.MN_S,'N') IN ('N','E') 
                    WHERE ISNULL(B.TP,'') = '' AND A.LINE_CD = @LINE_CD 
                
                    IF EXISTS(
                    SELECT B.EQP_CD FROM @RESULT_PROC A 
                    INNER JOIN BA_EQP B WITH (NOLOCK) ON A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD 
                    WHERE B.EQP_CD = @EQP_CD 
                    )
                    BEGIN 
                        INSERT INTO @EQP_TBL
                        SELECT @EQP_CD 
                    END ;
                    
                    -- 실적 관련해서 앞공정 실적의 설비를 다 가지고 오자. 이게 맞다.. 
                    -- 이거 나중에 잘 되는지 계속 체크 해야 된다.
                    WITH RANKEDDATA AS (
                        SELECT B.PROC_CD, B.DEPARTMENT,C.MN_S,
                            ROW_NUMBER() OVER (PARTITION BY B.PROC_CD, B.DEPARTMENT -- PROC_CD와 DEPARTMENT 별로 그룹화
                            ORDER BY B.IDX_DT DESC, B.IDX_SEQ DESC -- 최신 데이터를 최우선 순위로 정렬
                            ) AS RN
                        FROM @RESULT_PROC A
                        INNER JOIN PD_ITEM_IN B WITH (NOLOCK) ON A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD
                        INNER JOIN BA_EQP C WITH (NOLOCK) ON B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD 
                        AND B.DEPARTMENT = C.EQP_CD 
                        AND ISNULL(C.MN_S,'N') IN ('N','E')
                        WHERE ISNULL(B.DEPARTMENT, '') <> ''
                    )
                    -- 행 번호가 1인 레코드(각 그룹의 최신 데이터)만 선택
                    INSERT INTO @EQP_TBL 
                    SELECT DEPARTMENT
                    FROM RANKEDDATA
                    WHERE RN = 1
                    ORDER BY PROC_CD, DEPARTMENT;
                end 
            END 
            
            IF @REP_ITEM_CD <> '' 
            BEGIN
            /*
                    SELECT A.EQP_CD, B.EQP_NM FROM @EQP_tBL A 
                    INNER JOIN BA_EQP B ON A.EQP_CD = B.EQP_CD AND B.PROC_CD IN (SELECT PROC_CD FROM @RESULT_PROC)

                SELECT *FROM @RESULT_PROC
                */
                -- 왜 fix 로 박아놨지? 이유가 뭘까? 앞에 result_proc 때문에 그런가?
               -- IF @WC_CD = '13GB' AND @PROC_CD IN ('MX')
                BEGIN
                    INSERT INTO @FIFO_TABLE
                        (
                            ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_RESULT_SEQ, BE_WC_CD, BE_LINE_CD, BE_PROC_CD, EQP_CD
                        )
                    SELECT
                        ROW_NUMBER() OVER (ORDER BY AAA.IDX_DT, AAA.IDX_SEQ), 
                        AAA.GBN, AAA.PROC_CD, AAA.ITEM_CD, AAA.LOT_NO, AAA.QTY, AAA.ORDER_NO, AAA.REVISION, AAA.RESULT_SEQ, AAA.WC_CD, AAA.LINE_CD, AAA.BE_PROC_CD, AAA.EQP_CD
                    
                    FROM (
                        SELECT DISTINCT 'N' AS GBN, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.QTY, AA.ORDEr_NO, AA.REVISION, AA.RESULT_SEQ, AA.WC_CD, AA.LINE_CD, AA.PROC_CD AS BE_PROC_CD,
                        AA.IDX_DT, AA.IDX_SEQ, AA.DEPARTMENT AS EQP_CD
                        FROM
                        (
                        SELECT
                            A.ITEM_CD,
                            C.ITEM_NM,
                            A.LOT_NO,
                            '' AS SL_NM,
                            A.GOOD_QTY 
                            - 
                            ISNULL((SELECT SUM(USEM_QTY)
                                    FROM PD_USEM A1
                                    WHERE A1.DIV_CD = A.DIV_CD AND A1.PLANT_CD = A.PLANT_CD AND A1.ITEM_CD = A.ITEM_CD AND A1.LOT_NO = A.LOT_NO
                                        AND A1.BE_ORDER_NO = A.ORDER_NO AND A1.BE_REVISION = A.REVISION AND A1.BE_RESULT_SEQ = A.RESULT_SEQ AND A1.BE_PROC_CD = A.PROC_CD 
                            ),0)
                            - (ISNULL((SELECT SUM(AA.QTY)
                                    FROM ST_ITEM_IN AA
                                    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
                                        AND AA.ORDER_NO = A.ORDER_NO AND AA.ORDER_SEQ = A.REVISION AND AA.RESULTS_SEQ = A.RESULT_SEQ
                                        AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                  
                            ),0) 
                            -                                    
                            ISNULL((SELECT SUM(AA.QTY)
                                    FROM ST_ITEM_OUT AA
                                    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
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
                                    A.IDX_DT, A.IDX_SEQ,
                                    A.DEPARTMENT
                                FROM
                                    PD_ITEM_IN A
                                    INNER JOIN @RESULT_PROC A1 ON A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD

                                    INNER JOIN ST_STOCK_NOW B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD
                                        AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LOCATION_NO AND A.PROC_CD = B.PROC_CD AND B.QTY > 0
                                    INNER JOIN V_ITEM C ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD AND C.REP_ITEM_CD = @REP_ITEM_CD
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DEPARTMENT IN (
                                    /*
                                    SELECT A.EQP_CD
                                    FROM PD_ORDER_PROC_SPEC A
                                    WHERE A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
                                        AND A.USEM_ITEM_GROUP <> ''
                                    */
                                    select eqp_cd from @eqp_tbl 
                            ) 
                            -- bare 혼합일때 설비코드를 집어 넣은 이유가?? 
                            -- 
                                    
                            UNION ALL
                            SELECT
                                    A.ITEM_CD,
                                    C.ITEM_NM,
                                    A.LOT_NO,
                                    '' AS SL_NM,
                                    A.GOOD_QTY 
                            - 
                            ISNULL((SELECT SUM(USEM_QTY)
                                    FROM PD_USEM A1
                                    WHERE A1.DIV_CD = A.DIV_CD AND A1.PLANT_CD = A.PLANT_CD AND A1.ITEM_CD = A.ITEM_CD AND A1.LOT_NO = A.LOT_NO
                                        AND A1.BE_ORDER_NO = A.ORDER_NO AND A1.BE_REVISION = A.REVISION AND A1.BE_RESULT_SEQ = A.RESULT_SEQ AND A1.BE_PROC_CD = A.PROC_CD 
                            ),0)
                            - (ISNULL((SELECT SUM(AA.QTY)
                                    FROM ST_ITEM_IN AA
                                    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
                                        AND AA.ORDER_NO = A.ORDER_NO AND AA.ORDER_SEQ = A.REVISION AND AA.RESULTS_SEQ = A.RESULT_SEQ
                                        AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                  
                            ),0) 
                            -                                    
                            ISNULL((SELECT SUM(AA.QTY)
                                    FROM ST_ITEM_OUT AA
                                    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
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
                                    A.IDX_DT, A.IDX_SEQ,
                                    A.DEPARTMENT
                                FROM
                                    PD_ITEM_IN A
                                    INNER JOIN @RESULT_PROC A1 ON A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD

                                    INNER JOIN ST_STOCK_NOW B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD
                                        AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LOCATION_NO AND A.PROC_CD = B.PROC_CD AND B.QTY > 0
                                    INNER JOIN V_ITEM C ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD AND C.REP_ITEM_CD = @REP_ITEM_CD
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
                                    --AND A.PROC_CD IN (SELECT PROC_CD FROM @RESULT_PROC) 
                                    AND 
                                    (
                                        NOT EXISTS (SELECT 1 FROM @EQP_TBL)
                                        AND A.DEPARTMENT IS NOT NULL  -- 전체 조회
                                    )
                                    OR
                                    (
                                        EXISTS (SELECT 1 FROM @EQP_TBL)
                                        AND A.DEPARTMENT IN (SELECT EQP_CD FROM @EQP_TBL)
                                    )
                                    AND A.ORDER_NO NOT IN ('PD250113003','PD250113004')
                        ) AA
                        WHERE AA.QTY > 0
                    ) AAA
                    ORDER BY AAA.IDX_DT, AAA.IDX_SEQ

                END 

                /*
                ELSE 
                BEGIN
                    INSERT INTO @FIFO_TABLE
                        (

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
                        ISNULL((SELECT SUM(USEM_QTY)
                            FROM PD_USEM A1
                            WHERE A1.DIV_CD = A.DIV_CD AND A1.PLANT_CD = A.PLANT_CD AND A1.ITEM_CD = A.ITEM_CD AND A1.LOT_NO = A.LOT_NO
                                AND A1.BE_ORDER_NO = A.ORDER_NO AND A1.BE_REVISION = A.REVISION AND A1.BE_RESULT_SEQ = A.RESULT_SEQ AND A1.BE_PROC_CD = A.PROC_CD 
                        ),0)
                        - (ISNULL((SELECT SUM(AA.QTY)
                            FROM ST_ITEM_IN AA
                            WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
                                AND AA.ORDER_NO = A.ORDER_NO AND AA.ORDER_SEQ = A.REVISION AND AA.RESULTS_SEQ = A.RESULT_SEQ
                                AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                  
                        ),0) 
                        -                                    
                        ISNULL((SELECT SUM(AA.QTY)
                            FROM ST_ITEM_OUT AA
                            WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.WC_CD = A.WC_CD AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO
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
                            PD_ITEM_IN A
                            INNER JOIN @RESULT_PROC A1 ON A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD

                            INNER JOIN ST_STOCK_NOW B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD
                                AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LOCATION_NO AND A.PROC_CD = B.PROC_CD AND B.QTY > 0
                            INNER JOIN V_ITEM C ON A.PLANT_CD = C.PLANT_CD AND A.ITEM_CD = C.ITEM_CD
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
                            --AND A.PROC_CD IN (SELECT PROC_CD FROM @RESULT_PROC)
                            AND C.REP_ITEM_CD = @REP_ITEM_CD
                            AND A.ORDER_NO <> 'PD250113003'
                    ) AA
                    WHERE AA.QTY > 0
                    ORDER BY AA.IDX_DT, AA.IDX_SEQ
                    
                END
*/

                INSERT INTO @BACK_TABLE
                SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2, 0,
                    AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ
                FROM (                               
                        SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,
                        CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                               
                        ELSE (Z.SUMQTY - @VALUE) - Z.CURQTY   END  AS QTY                                
                        , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ, Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD
                    FROM (                               
                        SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,
                            (SELECT SUM(W.CURQTY)
                            FROM @FIFO_TABLE W
                            WHERE W.ROWNUM <= Q.ROWNUM AND W.CURQTY > 0) SUMQTY,
                            Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ, Q.BE_WC_CD, Q.BE_LINE_CD, Q.BE_PROC_CD
                        FROM @FIFO_TABLE Q) Z
                    WHERE CASE WHEN (@VALUE - Z.SUMQTY) >= 0 THEN Z.CURQTY                                
                        ELSE Z.CURQTY - (Z.SUMQTY - @VALUE) END  > 0                               
                    ) AA
            END
/*
SELECT A.EQP_CD, B.EQP_NM FROM @EQP_tBL A 
INNER JOIN BA_EQP B ON A.EQP_CD = B.EQP_CD AND B.PROC_CD IN (SELECT PROC_CD FROM @RESULT_PROC)

SELECT *FROM @RESULT_PROC
select *from @fifo_table 
select *from @back_table 
*/
            -- 선입선출에서 소요재공량 보다 실적 재공량이 많으면, 마지막 ROW 에 합산해서 집어 넣는다. 10.21 LJW
            -- 추후에 필요없으면 뺀다.
            
            UPDATE A SET A.PLC_QTY = CASE WHEN (SELECT MAX(CNT) FROM @BACK_TABLE) > A.CNT THEN 
            A.QTY ELSE 
            CASE WHEN @VALUE > A.SUMQTY THEN 
            @VALUE - A.SUMQTY + (A.QTY)
            ELSE 
            A.QTY END 
            END 
            FROM @BACK_TABLE A
            -- 그냥 개산하자 진짜 짜증난다. 이거
            /*
            UPDATE A SET A.PLC_QTY =
            CASE 
            WHEN @VALUE > (SELECT SUMQTY FROM @BACK_TABLE WHERE CNT = (SELECT MAX(CNT) FROM @BACK_TABLE))
                AND A.CNT = (SELECT MAX(CNT) FROM @BACK_TABLE)
            THEN (SELECT SUMQTY FROM @BACK_TABLE
            WHERE CNT = (SELECT MAX(CNT) FROM @BACK_TABLE))
            + (@VALUE - (SELECT SUMQTY FROM @BACK_TABLE
            WHERE CNT = (SELECT MAX(CNT) FROM @BACK_TABLE)))
            ELSE C.M_QTY * (-1)
            END
            FROM @BACK_TABLE A
                JOIN @BACK_TABLE C ON A.CNT = C.CNT
            */

            SET @MASTER_LOT = ''

            SELECT TOP 1
                @MASTER_LOT = AA.LOT_NO
            FROM
                (                              
                SELECT MAX(CNT) AS CNT, LOT_NO, SUM(QTY) AS QTY
                FROM @BACK_TABLE
                GROUP BY LOT_NO                               
                ) AA
            ORDER BY AA.QTY DESC, AA.CNT ASC
 

            INSERT INTO PD_USEM
                (
                DIV_CD, PLANT_CD, PROC_NO, ORDER_NO, REVISION,
                ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD,
                LINE_CD, PROC_CD, RESULT_SEQ,
                USEM_SEQ,
                USEM_WC, USEM_PROC,
                ITEM_CD, SL_CD, LOCATION_NO, RACK_CD, LOT_NO,
                MASTER_LOT,
                PLC_QTY, USEM_QTY, DEL_FLG, REWORK_FLG, INSERT_ID,
                INSERT_DT, UPDATE_ID, UPDATE_DT, ITEM_TYPE,
                BE_ORDER_NO, BE_REVISION, BE_RESULT_SEQ, BE_PROC_CD, USEM_EQP

                )

            SELECT
                @DIV_CD, @PLANT_CD, @PROC_NO, @ORDEr_NO, @REVISION,
                @ORDER_TYPE, @ORDER_FORM, @ROUT_NO, @ROUT_VER, @WC_CD,
                @LINE_CD, @PROC_CD, @RESULT_SEQ,
                ISNULL((SELECT MAX(Z.USEM_SEQ)
                FROM PD_USEM Z WITH (NOLOCK)
                WHERE Z.DIV_CD = @DIV_CD AND Z.PLANT_CD = @PLANT_CD AND Z.ORDER_NO = @ORDER_NO AND Z.REVISION = @REVISION AND Z.ORDER_TYPE = @ORDER_TYPE
                    AND Z.ORDER_FORM = @ORDER_FORM AND Z.ROUT_NO = @ROUT_NO AND Z.ROUT_VER = @ROUT_VER AND Z.WC_CD = @WC_CD AND Z.LINE_CD = @LINE_CD AND Z.PROC_CD = @PROC_CD AND Z.RESULT_SEQ = @RESULT_SEQ),0)                               
                    + A.CNT,
                A.BE_WC_CD, A.BE_PROC_CD,
                A.ITEM_CD, '3000', A.BE_LINE_CD, '*', A.LOT_NO,
                @MASTER_LOT,
                A.PLC_QTY, A.QTY, 'N', 'N', @USER_ID,
                GETDATE(), @USER_ID, GETDATe(), 'J',
                A.BE_ORDER_NO, A.BE_REVISION, A.BE_RESULT_SEQ, A.BE_PROC_CD, @EQP_CD
            FROM @BACK_TABLE A

            --SELECT *FROM PD_USEM WHERE INSERT_DT >= '2025-09-04'
            -- LOT 를 만듭시다. 
            -- 앞에 실적이 없는 상태이면? 날짜 현날짜로 가지고 가고
            -- 앞에 실적이 있으면? 그 마스터 LOT 의 실적을 따라가야 된다. 
            
            IF NOT EXISTS(SELECT *
                FROM @RESULT_PROC
                WHERE OUT_CHK = 'Y') AND EXISTS(SELECT *
                FROM PD_USEM A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.PLANT_CD = @PLANT_CD
                    AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ
                )
                BEGIN
                SET @SIL_DT = dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')
                --                    SELECT @SIL_DT 

                DELETE @USEM_INFO

                IF @COL_CHK = 'B'
                BEGIN 
                    INSERT INTO @USEM_INFO
                    (
                    CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY, LOT_INFO
                    )
                    SELECT TOP 1 ROW_NUMBER() OVER (ORDER BY A.USEM_QTY DESC, A.USEM_SEQ) AS CNT,          
                    A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, A.USEM_QTY AS QTY, 
                    B.LOT_INFO          
                    FROM PD_USEM A          
                    INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD  AND B.ITEM_CLASS <> '4000'         
                    INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON B.ITEM_CLASS = C.SUB_CD AND C.MAIN_CD = 'B0004'          
                    INNER JOIN PD_ORDER C1 WITH (NOLOCK) ON A.DIV_CD = C1.DIV_CD AND A.PLANT_CD = C1.PLANT_CD AND A.ORDER_NO = C1.ORDER_NO AND A.REVISION = C1.REVISION          
                    AND A.PROC_NO = C1.PROC_NO AND A.ORDER_TYPE = C1.ORDER_TYPE AND A.ORDER_FORM = C1.ORDER_FORM AND A.ROUT_NO = C1.ROUT_NO AND A.ROUT_VER = C1.ROUT_VER AND A.WC_CD = C1.WC_CD AND          
                    A.LINE_CD = C1.LINE_CD          
                    INNER JOIN V_ITEM C2 WITH (NOLOCK) ON C1.PLANT_CD = C2.PLANT_CD AND C1.ITEM_CD = C2.ITEM_CD          
                        
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM           
                    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ          
                    ORDER BY A.USEM_QTY DESC, A.USEM_SEQ         

                END
                ELSE 
                BEGIN 
                
                    INSERT INTO @USEM_INFO
                        (
                        CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY, LOT_INFO
                        )
                    SELECT C.SEQ, D.ITEM_CD, D.LOT_NO, C.ITEM_CLASS, D.ITEM_TP, C.ITEM_GROUP_CD3, D.QTY, D.LOT_INFO
                    FROM PD_ORDER A
                        INNER JOIN V_ITEM B ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD
                        INNER JOIN BA_LOT_CREATE_SEQ C ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD AND B.ITEM_ACCT = C.ITEM_ACCT
                        LEFT JOIN
                        (       
                            SELECT AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, SUM(AA.QTY) AS QTY, AA.LOT_INFO--, BB.SEQ          
                        FROM
                            (           
                                SELECT ROW_NUMBER() OVER (ORDER BY MIN(D.SEQ)) AS CNT,
                                ROW_NUMBER() OVER (PARTITION BY B.ITEM_CLASS, B.ITEM_GROUP_CD3 ORDER BY B.ITEM_GROUP_CD3, SUM(A.USEM_QTY) DESC) AS RANK,

                                A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP, B.ITEM_GROUP_CD3 AS ITEM_GROUP, SUM(A.USEM_QTY) AS QTY, C2.ITEM_ACCT, C1.ITEM_CD AS PRNT_ITEM_CD,
                                B.LOT_INFO
                            FROM PD_USEM A
                                INNER JOIN V_ITEM B ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND B.ITEM_CLASS <> '4000'
                                INNER JOIN BA_SUB_CD C ON B.ITEM_CLASS = C.SUB_CD AND C.MAIN_CD = 'B0004'
                                INNER JOIN PD_ORDER C1 ON A.DIV_CD = C1.DIV_CD AND A.PLANT_CD = C1.PLANT_CD AND A.ORDER_NO = C1.ORDER_NO AND A.REVISION = C1.REVISION
                                    AND A.PROC_NO = C1.PROC_NO AND A.ORDER_TYPE = C1.ORDER_TYPE AND A.ORDER_FORM = C1.ORDER_FORM AND A.ROUT_NO = C1.ROUT_NO AND A.ROUT_VER = C1.ROUT_VER AND A.WC_CD = C1.WC_CD AND
                                    A.LINE_CD = C1.LINE_CD
                                INNER JOIN V_ITEM C2 ON C1.PLANT_CD = C2.PLANT_CD AND C1.ITEM_CD = C2.ITEM_CD
                                LEFT JOIN PD_LOT_SYS D ON A.DIV_CD = D.DIV_CD AND A.PLANT_CD = D.PLANT_CD AND A.WC_CD = D.WC_CD AND A.PROC_CD = D.PROC_CD AND C.TEMP_CD1 = D.ITEM_TP AND B.ITEM_GROUP_CD3 = D.ITEM_GROUP

                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM
                                AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ
                            GROUP BY A.ITEM_CD, A.MASTER_LOT, B.ITEM_CLASS, B.ITEM_GROUP_CD3, C.TEMP_CD1, D.ITEM_TP, D.ITEM_GROUP , C2.ITEM_ACCT, C1.ITEM_CD, B.LOT_INFO
                    
                            ) AA
                        WHERE AA.RANK = 1
                        GROUP BY AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, AA.ITEM_ACCT, AA.LOT_INFO     
                                
                        ) D ON C.ITEM_CLASS = CASE WHEN D.ITEM_CLASS = '3000' THEN '2000' ELSE D.ITEM_CLASS END AND C.ITEM_GROUP_CD3 = D.ITEM_GROUP

                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION
                        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD
                        AND A.LINE_CD = @LINE_CD

                END 
                --SELECT *FROM @USEM_INFO
                DECLARE @LOT_CHK NVARCHAR(1) = 'N'
                -- TOP LOT 날짜
                SET @TOP_LOT = 'G' + CONVERT(NVARCHAR(4),CAST((SELECT A.SIL_DT
                FROM PD_RESULT A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND
                    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND
                    A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ           
                    ) AS DATETIME  ), 12)
            
                -- 중간, 제일 중요
                
                DECLARE @LOT1 NVARCHAR(50), @LOT2 NVARCHAR(50);
                SELECT @LOT1 = (SELECT LOT_INFO
                    FROM @USEM_INFO
                    WHERE CNT = 1);
                SELECT @LOT2 = (SELECT LOT_INFO
                    FROM @USEM_INFO
                    WHERE CNT = 2);

                IF @COL_CHK = 'B' 
                BEGIN 
                    SET @MID_LOT = @LOT1
                END 
                ELSE 
                BEGIN 

--                    SELECT '1'
                    SELECT @MID_LOT =  
                    CASE 
                        WHEN @LOT2 IS NULL THEN 
                            CASE 
                                WHEN CHARINDEX('-', @LOT1) > 0 THEN @LOT1 + '-XXX-XXX'
                                ELSE @LOT1 + '-XXX'
                            END
                        ELSE 
                            ISNULL(@LOT1,'XXX') + '-' + @LOT2
                    END
                END 

                -- 마지막 UT 
                SET @BOT_LOT = 
                    CASE WHEN ISNULL((  
                    SELECT B.TEMP_CD5
                FROM V_ITEM A WITH (NOLOCK)
                    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'
                WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD   
                
                    ),'') = '' THEN   
                    ISNULL((                         
                    SELECT A.LOT_INITIAL
                FROM BA_ROUTING_HEADER A WITH (NOLOCK)
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
                    (SELECT B.TEMP_CD1
                FROM BA_SUB_CD A WITH (NOLOCK)
                    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.TEMP_CD3 = B.SUB_CD AND B.MAIN_CD = 'BA204'
                WHERE A.MAIN_CD = 'SAP01' AND A.SUB_CD = (           
                    SELECT ORDER_TYPE
                    FROM PD_ORDER A WITH (NOLOCK)
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION ))           
                            
                    ,'')
                -- 마지막 SEQ 

                IF EXISTS(SELECT *
                FROM PD_LOT_SEQ A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (           
                        
                    SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT
                        FROM PD_RESULT A WITH (NOLOCK)
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
                        
                        SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT
                            FROM PD_RESULT A WITH (NOLOCK)
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
                ELSE 
                BEGIN
                IF @MN_S IN ('Y')
                    BEGIN
                    -- 와 이거 어떻하지? 
                    -- SEQ 를 어떻게 할지 고민이다. 
                    -- 따로 관리 테이블을 넘겨야 되나? 
                    SET @RK_SEQ = ISNULL(( SELECT TOP 1
                        A.LOT_SEQ
                    FROM PD_RESULT_MN_LOT A WITH (NOLOCK)
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD
                        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND
                        A.PROC_CD = @PROC_CD AND A.MASTER_LOT = @MASTER_LOT
                    ORDER BY A.MASTER_LOT, A.LOT_SEQ DESC),0) + 1

                    -- 테이블을 따로 만들어서 관리하는수 밖에 없음.
                    -- 그리고 INSERT 처리를 한다. 
                    INSERT INTO PD_RESULT_MN_LOT 
                    (
                        DIV_CD,        PLANT_CD,       WC_CD,        LINE_CD,         PROC_CD, 
                        MASTER_LOT,    LOT_SEQ,        INSERT_ID,    INSERT_DT,       UPDATE_ID, 
                        UPDATE_DT
                    )
                    SELECT 
                        @DIV_CD,       @PLANT_CD,      @WC_CD,       @LINE_CD,        @PROC_CD, 
                        @MASTER_LOT,   @RK_SEQ,       'MDMGA',      GETDATE(),       'MDMGA',
                        GETDATE()


                    SET @CREATE_LOT = @MASTER_LOT + '-' + CAST(@RK_SEQ AS NVARCHAR)
                    END 
                    ELSE 
                    BEGIN
                    IF @MN_S = 'E' 
                        BEGIN
                        SET @CREATE_LOT = @MASTER_LOT
                        END 
                        ELSE 
                        BEGIN

                        DECLARE @CHILD_ITEM NVARCHAR(50) = ''

                        SELECT @CHILD_ITEM = ITEM_CD
                        FROM @FIFO_TABLE

                        IF (SELECT A.ITEM_CLASS
                        FROM V_ITEM A WITH (NOLOCK)
                        WHERE A.PLANT_CD = @PLANT_CD
                            AND A.ITEM_CD = @CHILD_ITEM) IN ('1000')
                            BEGIN
                            -- 새로운 LOT 를 만든다. 
                            --SELECT '1'
                            --SELECT *FROM V_ITEM A WITH (NOLOCK) WHERE A.REP_ITEM_CD = @REP_ITEM_CD 

                            DECLARE @GDATE NVARCHAR(7) = ''

                            SELECT @GDATE = CONVERT(NVARCHAR(7), CAST('20' + SUBSTRING(@MASTER_LOT, PATINDEX('%[0-9]%',@MASTER_LOT) ,4) + '01' AS DATETIME), 120)
                            -- 어... 여기는..                                 
                            -- 채번 규칙을 체인지 합시다..                                 

                            IF EXISTS(SELECT *
                            FROM PD_LOT_SEQ A WITH (NOLOCK)
                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = @GDATE
                                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                  
                                )                                 
                                BEGIN
                                SELECT @LOT_SEQ =    
                                    CASE WHEN @WC_CD = '14C' THEN    
                                    ISNULL((SELECT TOP 1
                                        LOT_INFO
                                    FROM BA_LINE WITH (NOLOCK)
                                    WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD
                                        AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE    
                                    CAST(                  
                                    CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END + dbo.LPAD(A.LOT_SEQ +                                 
                                    CASE WHEN @LOT_CHK = 'N' THEN  -- @LOT CHK 가 N 이면 증가고 아니면 예전 채번 그대로 가지고 간다.                                 
                                    1 ELSE 0 END ,3,0)
                                FROM PD_LOT_SEQ A WITH (NOLOCK)
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = @GDATE
                                    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD

                            END                                  
                                ELSE                                  
                                BEGIN
                                SELECT @LOT_SEQ =   
                                    CASE WHEN @WC_CD = '14C' THEN    
                                    ISNULL((SELECT TOP 1
                                        LOT_INFO
                                    FROM BA_LINE WITH (NOLOCK)
                                    WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD
                                        AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE    
                                    CAST(                  
                                    CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END + dbo.LPAD(1,3,0)

                            END

                            DECLARE @RESULT_LOT TABLE (
                                CNT INT IDENTITY(1,1)                                 
                                    ,
                                VALUE NVARCHAR(100)                                 
                                )

                            IF CHARINDEX('-', @MASTER_LOT) <> 0       
                                BEGIN
                                INSERT INTO @RESULT_LOT
                                    (VALUE)
                                SELECT VALUE
                                FROM string_split(@MASTER_LOT,'-')
                            END        
                                ELSE        
                                BEGIN
                                INSERT INTO @RESULT_LOT
                                    (VALUE)
                                 SELECT @MASTER_LOT
                                UNION ALL
                                SELECT @LOT_SEQ
                            END
                            --SELECT *FROM @RESULT_LOT 
                            SET @BOT_LOT =                                           
                                CASE WHEN ISNULL((          
                                SELECT B.TEMP_CD5
                            FROM V_ITEM A WITH (NOLOCK)
                                INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'
                            WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD           
                        
                                ),'') = '' THEN           
                                ISNULL((                   
                                SELECT A.LOT_INITIAL
                            FROM BA_ROUTING_HEADER A WITH (NOLOCK)
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
                                (SELECT B.TEMP_CD1
                            FROM BA_SUB_CD A WITH (NOLOCK)
                                INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.TEMP_CD3 = B.SUB_CD AND B.MAIN_CD = 'BA204'
                            WHERE A.MAIN_CD = 'SAP01' AND A.SUB_CD = (                                 
                                SELECT ORDER_TYPE
                                FROM PD_ORDER A WITH (NOLOCK)
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION ))                                  
                                ,'')

                            DECLARE @LOT_CNT INT  = 0                                 
                                        ,@LOT_TCNT INT = 0
                            IF @WC_CD IN ('13GA','13GB','13GD')
                                BEGIN
                                SELECT @LOT_TCNT = 3
                                FROM @RESULT_LOT
                            END 
                                ELSE 
                                BEGIN
                                SELECT @LOT_TCNT = 5
                                FROM @RESULT_LOT
                            END

                            WHILE @LOT_CNT <> @LOT_TCNT                                 
                                BEGIN
                                SET @LOT_CNT = @LOT_CNT + 1
                                SET @TOP_LOT = @TOP_LOT + (SELECT VALUE
                                FROM @RESULT_LOT
                                WHERE CNT = @LOT_CNT) + '-'
                                END
                            --        SELECT @TOP_LOT
                            --                                SELECT '1'
                                SET @CREATE_LOT = @TOP_LOT + @BOT_LOT + '-' + @LOT_SEQ
                            END 
                            ELSE 
                            BEGIN
                                SELECT @CREATE_LOT = A.LOT_NO
                                FROM PD_RESULT A WITH (NOLOCK)
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND
                                    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND
                                    A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ
                        END
                    END
                END
            END
            
            -- 실적에 업데이트 진행         

            -- 소요량 합계를 가지고 온다.

            SELECT @USEM_QTY = ISNULL(SUM(A.USEM_QTY),0), @PLC_USEM_QTY = ISNULL(SUM(A.PLC_QTY),0)
            FROM PD_USEM A
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND
                A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ

            -- 실적은 다르게 그냥 바로 들어가야 된다. PLC 값으로..
            -- 포장은 따로 이야기 해봐야 될것 같음. 10.21 LJW
            UPDATE A SET A.RESULT_QTY = @PLC_USEM_QTY, A.GOOD_QTY = @PLC_USEM_QTY, A.LOT_NO = @CREATE_LOT, A.LOT_SEQ = CAST(RIGHT(@LOT_SEQ,3) AS INT),
                A.EXP_LOT = CASE WHEN @MN_S = 'Y' THEN @MASTER_LOT ELSE '' END, 
                A.J_SEQ = CASE WHEN @MN_S = 'Y' THEN @RK_SEQ ELSE NULL END
                FROM PD_RESULT A 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND
                A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ

            -- 그룹이면 전부다 넣자 
            IF EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
            AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
            AND A.EDATE IS NULL)
            BEGIN

                UPDATE B SET B.RESULT_QTY = @PLC_USEM_QTY, B.GOOD_QTY = @PLC_USEM_QTY, B.LOT_NO = @CREATE_LOT, B.LOT_SEQ = CAST(RIGHT(@LOT_SEQ,3) AS INT),
                B.EXP_LOT = CASE WHEN @MN_S = 'Y' THEN @MASTER_LOT ELSE '' END, 
                B.J_SEQ = CASE WHEN @MN_S = 'Y' THEN @RK_SEQ ELSE NULL END 
                FROM PD_MDM_RESULT_GROUP A
                INNER JOIN PD_RESULT B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
                AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ 
                WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.PROC_CD <> @PROC_CD 

            END

        END 
        ELSE 
        BEGIN
            -- 자기것 업데이트 
            -- PD_USEM PLC_QTY 에 업데이트 진행 
            -- 두개가 들어갈 경우는 선입선출 처리 한다. 어쩔수 없음. 근데 PD_USEM 의 IN_CHK = 'N' 인것을 기준으로 처리한다.
            -- 수세 같은 경우 이런경우 어떻게 처리 해야 되는가? 
            -- 실중량 기준으로 실적을 다시 편성을 해야 되지 않나? 
            -- 수세일 경우 그냥 가자 어쩔수 없다. 
            UPDATE A SET A.PLC_QTY = @VALUE
            FROM PD_USEM A 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
                AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO
                AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ

            UPDATE A SET A.RESULT_QTY = @VALUE, A.GOOD_QTY = @VALUE 
            FROM PD_RESULT A 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
                AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO
                AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ
        END
    -- 실적의 마지막. 
    END

END 

 -- 일지 정보 UPDATE 
 UPDATE A SET A.SPEC_VALUE = @VALUE 
     FROM PD_RESULT_PROC_SPEC_VALUE A
 WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION --AND A.PROC_NO = @PROC_NO
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.PROC_SPEC_CD = @SPEC_CD
    AND A.EQP_CD = @EQP_CD
    AND ISNULL(A.SPEC_VALUE,'') = ''


UPDATE A SET A.END_DT = GETDATE() FROM PD_MDM_RESULT_PROC_SPEC A
WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.SEQ = @SEq AND A.ORDER_NO = @ORDER_NO AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD
    AND A.TAG_ID = @TAG_ID AND A.SEQ = @SEQ AND A.VALUE_STEP = @VALUE_STEP
    AND A.END_DT IS NULL

UPDATE A SET A.DEL_FLG = 'Y'
FROM PD_RESULT A
WHERE A.DIV_CD = @DIV_CD AND A.REVISION = @REVISION AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ
    AND A.EDATE IS NULL
    AND A.DEL_FLG = 'N'


END TRY 
BEGIN CATCH 
    SET @MSG_CD = '9999'
    SET @MSG_DETAIL = ERROR_MESSAGE()
    RETURN 1
END CATCH