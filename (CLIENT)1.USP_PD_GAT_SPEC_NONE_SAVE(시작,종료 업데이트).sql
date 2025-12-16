/*
----------------------------------------------------
MDM 실적 처리 Gathering 프로그램 시작,종료 처리 (NONE SPEC)
----------------------------------------------------
작업일자 : 25.09.20 
작업자 : ljw

*/
alter  PROC USP_PD_GAT_SPEC_NONE_SAVE(
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
    ,@EQP_CD       NVARCHAR(100)
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
    ,@USER_ID      NVARCHAR(15) = 'MDMGA'
    ,@MSG_CD       NVARCHAR(4)    OUTPUT 
    ,@MSG_DETAIL   NVARCHAR(MAX)  OUTPUT

)
AS 

SET NOCOUNT ON 


IF OBJECT_ID('tempdb..#MN_SE_TEMP') IS NOT NULL
DROP TABLE #MN_SE_TEMP;


DECLARE @SIL_DT  NVARCHAR(10) 
      ,@STR_DATE NVARCHAR(8)
      ,@RK_DATE  NVARCHAR(10) 
      ,@DAY_FLG  NVARCHAR(1)
      ,@ITEM_CD  NVARCHAR(50) 
      ,@LOT_NO   NVARCHAR(50) 

DECLARE @IDX_DT  NVARCHAR(10) 
        ,@IDX_SEQ INT = 0 
DECLARE @DEPARTMENT NVARCHAR(100) = ''
       ,@MN_S    NVARCHAR(1) = '' 

DECLARE @LAST_YN NVARCHAR(1) = 'Y' 
       ,@G_CHK   NVARCHAR(1) = 'N' -- GROUP TABLE 체크

BEGIN TRY 

SELECT @ITEM_CD = A.ITEM_CD
FROM PD_ORDER A WITH (NOLOCK)
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD
    AND A.LINE_CD = @LINE_CD --AND A.S_CHK = @S_CHK AND A.PROC_CD = @PROC_CD 

SELECT @MN_S = ISNULL(A.MN_S,'N')
FROM BA_EQP A WITH (NOLOCK)
WHERE A.EQP_CD = @EQP_CD AND A.PROC_CD = @PROC_CD 

IF EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK) 
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD 
AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL 
)
BEGIN 
    SET @G_CHK = 'Y'
END 

--SELECT @MN_S 
IF @COL_CHK IN ('N','B') AND @VALUE_STEP = 'SD' 
BEGIN
    IF EXISTS(SELECT *
    FROM PD_RESULT A WITH (NOLOCK)
    WHERE A.DIV_CD =@DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER =@ROUT_VER
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ
        AND A.EQP_CD = CASE WHEN @MN_S IN ('Y','E') THEN @EQP_CD ELSE A.EQP_CD END
        AND A.EDATE IS NULL
    ) AND @G_CHK = 'N'
    BEGIN
        IF NOT EXISTS(
        SELECT *
        FROM PD_MDM_RESULT_MASTER A WITH (NOLOCK)
        WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
            AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL
            AND A.EQP_CD = CASE WHEN @MN_S IN ('Y','E') THEN @EQP_CD ELSE A.EQP_CD END 
        )
        BEGIN
            UPDATE A SET A.SDATE = CAST(@VALUE_STR AS DATETIME) FROM PD_RESULT A WITH (NOLOCK)
            WHERE A.DIV_CD =@DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER =@ROUT_VER
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ
                AND A.EQP_CD = CASE WHEN @MN_S IN ('Y','E') THEN @EQP_CD ELSE A.EQP_CD END
                AND A.EDATE IS NULL
        END
    END 
    ELSE 
    BEGIN
        -- 작업 오더에 있는지 확인하고, 
        -- 마스터 설비를 체크하고 BA_EQP 에서 MN_FLAG = 'Y' 인것을 찾자. 일지 정보에서 
        
        IF EXISTS(
        SELECT *
        FROM PD_MDM_RESULT_MASTER A WITH (NOLOCK)
        WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
            AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL
            AND A.EQP_CD = CASE WHEN @MN_S IN ('Y','E') THEN @EQP_CD ELSE A.EQP_CD END 
        )
        BEGIN
            -- 작업 시작
            DECLARE @MASTER_EQP NVARCHAR(50) = ''
            
            IF @MN_S NOT IN ('Y','E')
            BEGIN
                -- 체분리네 이건 대체 왜이렇게???
                -- 그렇네 이걸 왜이렇게 했을까? 
                IF (@PROC_CD = 'RB') 
                BEGIN
                    SET @MASTER_EQP = @EQP_CD
                END 
                ELSE 
                BEGIN

                    SELECT DISTINCT @MASTER_EQP = B.EQP_CD
                    FROM PD_ORDER_PROC_SPEC_V2 A WITH (NOLOCK)
                        INNER JOIN BA_EQP B WITH (NOLOCK) ON A.DIV_cD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD
                            AND A.PROC_CD = B.PROC_CD AND A.EQP_CD = B.EQP_CD
                            AND B.MN_FLAG = 'Y'
                    WHERE A.DIV_CD =@DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION
                        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER =@ROUT_VER
                        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
                        AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                        WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 
                    -- 이거 나중에 없애자. 시브 테스트 때문에 넣어놓음
                   -- SELECT @EQP_CD
                    IF @EQP_CD IN ('LFG01A-01B-VS-0501','LFG01A-01B-VS-0502','LFG01A-02C-VS-0501','LFG01A-02C-VS-0502')
                    BEGIN
                        SET @MASTER_EQP = @EQP_CD
                    END 
                END
            --AND A.EQP_CD = CASE WHEN @MN_S IN ('Y','E') THEN @EQP_CD ELSE A.EQP_CD END 
            END 
            ELSE 
            BEGIN
                SET @MASTER_EQP = @EQP_CD
            END
            
--            SELECT @MASTER_EQP
            -- 이거 이렇게 넣어도 되는건가? 
            -- 일번 공정은 문제가 없나? 
            IF ISNULL(@ROTATION,0) = 0 BEGIN SET @ROTATION = 1 END 

            IF NOT EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
            INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO 
            AND A.REVISION = B.REVISION AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.S_CHK = 'N'
            WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL
            ) 
            BEGIN 
               
                SET @STR_DATE = CONVERT(NVARCHAR(8), GETDATE(), 112)
                SET @SIL_DT = DBO.UFNSR_GET_DAYNIGHT(GETDATE(),'T')
                SET @DAY_FLG = DBO.UFNSR_GET_DAYNIGHT(GETDATE(),'D')

                -- 그룹공정의 그룹 LOT 를 찾는다. 

                IF EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
                INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO 
                AND A.REVISION = B.REVISION AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.S_CHK = 'N'
                WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.EDATE IS NULL
                )
                BEGIN
                    SET @LOT_NO = ISNULL((SELECT TOP 1 B.GROUP_LOT FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
                    INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO 
                    AND A.REVISION = B.REVISION AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.S_CHK = 'N'
                    WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.EDATE IS NULL),'')
                END
                ELSE
                BEGIN
                    EXEC USP_CM_AUTO_NUMBERING 'PR', @STR_DATE, @USER_ID, @LOT_NO OUT
                END 

                SET @RK_DATE = CONVERT(NVARCHAR(10), GETDATE(), 120)

                INSERT INTO PD_RESULT
                    (
                    DIV_CD, PLANT_CD, PROC_NO, ORDER_NO, REVISION,
                    ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD,
                    LINE_CD, PROC_CD, S_CHK, RESULT_SEQ, ITEM_CD,
                    LOT_NO, LOT_SEQ, RESULT_QTY, GOOD_QTY, GROUP_LOT,
                    GROUP_YN, RK_DATE, SDATE, EDATE, SIL_DT,
                    DAY_FLG, J_CHK, J_SEQ, J_VAL, EQP_CD,
                    INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT, ZMESIFNO, REMARK

                    )
                SELECT
                    @DIV_CD, @PLANT_CD, @PROC_NO, @ORDER_NO, @REVISION,
                    @ORDER_TYPE, @ORDER_FORM, @ROUT_NO, @ROUT_VER, @WC_CD,
                    @LINE_CD, @PROC_CD, 'N', @RESULT_SEQ, @ITEM_CD,
                    @LOT_NO, 0, 0, 0, @LOT_NO,
                    'N', @RK_DATE, GETDATE(), NULL, @SIL_DT,
                    @DAY_FLG, 'N', 0, '%', @MASTER_EQP,
                    @USER_ID, GETDATE(), @USER_ID, GETDATE(), ''      , @PD_AUTO_NO
            END 
            ELSE 
            BEGIN
                SET @ROTATION = (SELECT a.cycle 
                FROM PD_MDM_RESULT_GROUP a WITH (NOLOCK)
                where a.pd_auto_no = @pd_auto_no and a.proc_cd = @proc_cd )
            END
            -- 이제 어디에 집어넣어야 하는가?

            -- SPEC 이관 한다. 
            -- 일단 그냥 이관하자.
           
            IF NOT EXISTS(SELECT *
            FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
                AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @ROTATION
            )           
            BEGIN
                DECLARE @IN_SEQ INT = 0
                
                SET @IN_SEQ = ISNULL((SELECT MAX(A.IN_SEQ)
                FROM PD_RESULT_PROC_SPEC_VALUE_HIS A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IN_DATE = CONVERT(NVARCHAR(10), GETDATE(), 120)            
                ), 0) + 1

                INSERT INTO PD_RESULT_PROC_SPEC_VALUE_HIS
                    (
                    DIV_CD, PLANT_CD, WC_CD, LINE_CD, PROC_CD,
                    IN_DATE,
                    IN_SEQ, ORDER_NO, REVISION, RESULT_SEQ, S_CHK,
                    CYCLE_SEQ, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT
                    )
                SELECT
                    @DIV_CD, @PLANT_CD, @WC_CD, @LINE_CD, @PROC_CD,
                    CONVERT(NVARCHAR(10), GETDATE(), 120),
                    @IN_SEQ, @ORDER_NO, @REVISION, @RESULT_SEQ, @S_CHK,
                    @ROTATION, @USER_ID, GETDATE(), @USER_ID, GETDATE()

                INSERT INTO PD_RESULT_PROC_SPEC_VALUE
                    (
                    DIV_CD, PLANT_CD, ORDER_NO, REVISION, ORDER_TYPE, ORDER_FORM,
                    ROUT_NO, ROUT_VER, WC_CD, LINE_CD, PROC_CD, S_CHK, RESULT_SEQ,
                    CYCLE_SEQ, SEQ, SPEC_VERSION, PROC_SPEC_CD, EQP_CD, SPEC_VALUE_TYPE,
                    SPEC_VALUE, REMARK, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT,
                    IN_DATE, IN_SEQ, GROUP_SPEC_CD
                    )

                SELECT A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.ORDER_TYPE, A.ORDER_FORM,
                    A.ROUT_NO, A.ROUT_VER, A.WC_CD, A.LINE_CD, A.PROC_CD, @S_CHK, @RESULT_SEQ,
                    @ROTATION,--A.RECYCLE_NO,        
                    --A.SEQ, 
                     ROW_NUMBER() OVER (ORDER BY A.EQP_CD, A.PROC_SPEC_CD),
                   
                    A.SPEC_VERSION, A.PROC_SPEC_CD, A.EQP_CD, CASE WHEN A.SPEC_VALUE_TYPE = '' THEN '20' ELSE A.SPEC_VALUE_TYPE END,
                    CASE WHEN A.SET_FLAG = 'Y' AND
                        A.USEM_ITEM_GROUP = '' AND A.PROC_SPEC_VALUE <> '' THEN       
                    A.PROC_SPEC_VALUE ELSE     
                    CASE WHEN A.PLC_FLAG = 'Y' AND A.AUTO_PLC_FLAG  = 'Y'     
                    THEN dbo.USP_OPC_DATA_FMT_CONV_FUNC(A.DIV_CD, A.EQP_CD, BB.OPC_AS + '.' + BB.OPC_AS + '.' + BB.POP_IP_ENO_AS, BB.OPC_AS, BB.POP_IP_ENO)    
                    ELSE     
                    ''     
                    END     
                    END       
                        
                    , '', @USER_ID, GETDATE(), @USER_ID, GETDATE(), CONVERT(NVARCHAR(10), GETDATE(), 120),
                    @IN_SEQ, A.GROUP_SPEC_CD
                FROM PD_ORDER_PROC_SPEC_V2 A WITH (NOLOCK)
                    LEFT JOIN POP_EQP_ENO BB ON BB.DIV_CD = @DIV_CD AND BB.PLANT_CD = @PLANT_CD
                        AND A.EQP_CD = BB.EQP_CD AND BB.PROC_CD = @PROC_CD AND A.PROC_SPEC_CD = BB.PROC_SPEC_CD

                WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM
                    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
                      AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                        WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 

            END
        END

    END
END 

IF @COL_CHK = 'N' AND @VALUE_STEP = 'ED' 
BEGIN
    -- 작업 종료
    --IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'N'     나중에 정리
    BEGIN
        -- 실적 작업 종료 처리
        -- PD_ITEM_IN 에 집어 넣으면서? 
        -- 순서 하나 추가 하자. 이게 필요하다. 
        -- 원료투입은 sap 처리가 필요하다. 

        SET @IDX_DT = CONVERT(NVARCHAR(10), GETDATE(), 120)

        SET @DEPARTMENT = ''

        IF @MN_S IN ('Y','E') 
        BEGIN 
            SET @IDX_SEQ = ISNULL((SELECT MAX(A.IDX_SEQ)
            FROM PD_ITEM_IN A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IDX_DT = @IDX_DT),0)
        END 
        ELSE 
        BEGIN 
            SET @IDX_SEQ = ISNULL((SELECT MAX(A.IDX_SEQ)
            FROM PD_ITEM_IN A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IDX_DT = @IDX_DT),0) + 1
        END

        -- PD_ITEM_IN 에 INSERT 
/*
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
*/
        -- 일단 배정 정보는 나중에 보자..
--        IF @DEPARTMENT = '' 
        BEGIN
            SET @DEPARTMENT = @EQP_CD
        END

        --SELECT @MN_S, @DEPARTMENT, @IDX_DT 
        
        IF @MN_S IN ('Y','E') 
        BEGIN
            DECLARE @LOSS_CHK NVARCHAR(1) = 'N' 

            SET @LOSS_CHK = ISNULL((SELECT A.SPECIPI_YN FROM PD_ORDER_PROC A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
              AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 
              AND A.PROC_CD = @PROC_CD),'N')

            -- PD_RESULT_MN_LOT 에 INSERT 를 먼저 진행한다.
            
--            DECLARE #MN_SE_TEMP TABLE (
            CREATE TABLE #MN_SE_TEMP (
                 CNT         INT IDENTITY(1,1) 
                ,DIV_CD      NVARCHAR(10) 
                ,PLANT_CD    NVARCHAR(10) 
                ,PROC_NO     NVARCHAR(50) 
                ,ORDER_NO    NVARCHAR(50)
                ,REVISION    INT 
                ,ORDER_TYPE  NVARCHAR(10) 
                ,ORDER_FORM  NVARCHAR(10)
                ,ROUT_NO     NVARCHAR(10) 
                ,ROUT_VER    INT 
                ,WC_CD       NVARCHAR(10)
                ,LINE_CD     NVARCHAR(10) 
                ,PROC_CD     NVARCHAR(10) 
                ,RESULT_SEQ  INT 
                ,USEM_SEQ    INT 
                ,ITEM_CD     NVARCHAR(50) 
                ,LOT_NO      NVARCHAR(50) 
                ,MASTER_LOT  NVARCHAR(50) 
                ,SL_CD       NVARCHAR(10) 
                ,LOCATION_NO NVARCHAR(10) 
                ,RACK_CD     NVARCHAR(10) 
                ,BARCODE     NVARCHAR(10) 
                ,SIL_DT      NVARCHAR(10) 
                ,DEPARTMENT  NVARCHAR(100) 
                ,GOOD_QTY    NUMERIC(18,3) 
                ,RESULT_QTY  NUMERIC(18,3) 
                ,LOSS_RATE   NUMERIC(18,3) 
                
            )
            CREATE INDEX IX_TEMP_MASTER_LOT ON #MN_SE_TEMP(MASTER_LOT);
            CREATE INDEX IX_TEMP_USEM_SEQ ON #MN_SE_TEMP(USEM_SEQ);
            CREATE INDEX IX_TEMP_LOT_NO ON #MN_SE_TEMP(LOT_NO);

            INSERT INTO #MN_SE_TEMP (
                DIV_CD,          PLANT_CD,          PROC_NO,          ORDER_NO,            REVISION, 
                ORDER_TYPE,      ORDER_FORM,        ROUT_NO,          ROUT_VER,            WC_CD, 
                LINE_CD,         PROC_CD,           RESULT_SEQ,       USEM_SEQ,            ITEM_CD, 
                LOT_NO,          MASTER_LOT,        SL_CD,            LOCATION_NO,         RACK_CD, 
                BARCODE,         SIL_DT,            DEPARTMENT,       
                GOOD_QTY,        RESULT_QTY,        LOSS_RATE
            )
            SELECT  A.DIV_CD, A.PLANT_CD, A.PROC_NO, A.ORDER_NO, A.REVISION,
                A.ORDER_TYPE, A.ORDER_FORM, A.ROUT_NO, A.ROUT_VER, A.WC_CD,
                A.LINE_CD, A.PROC_CD, A.RESULT_SEQ, B.USEM_SEQ,
                A.ITEM_CD, CASE WHEN A.EXP_LOT = B.LOT_NO THEN A.LOT_NO ELSE 
                B.LOT_NO 
                END , 
                B.LOT_NO AS MASTER_LOT
                , '3000', A.LINE_CD, '*',
                '*', A.SIL_DT, @DEPARTMENT, 
                B.PLC_QTY,
                CASE WHEN @MN_S = 'Y' AND @LOSS_CHK = 'Y' THEN 
                B.PLC_QTY * C.LOSS_RATE / 100 ELSE 
                B.PLC_QTY END, C.LOSS_RATE
                FROM PD_RESULT A WITH (NOLOCK)
                INNER JOIN PD_USEM B WITH (NOLOCK) ON
                A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
                AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD 
                AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND A.EQP_CD = B.USEM_EQP
                INNER JOIN V_ITEM C WITH (NOLOCK) ON B.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND
                A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
                A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD
                -- 감량율 확인후에 PD_RESULT 를 재조정한다. 
         --SELECT *FROM #MN_SE_TEMP       
                
                IF @MN_S = 'Y' 
                BEGIN 
                    IF EXISTS(SELECT *FROM #MN_SE_TEMP A WHERE A.LOT_NO = A.MASTER_LOT)
                    BEGIN 
                      
                        DECLARE @MN_LOT_LOOP TABLE (
                            CNT         INT IDENTITY(1,1) 
                            ,DIV_CD      NVARCHAR(10) 
                            ,PLANT_CD    NVARCHAR(10) 
                            ,WC_CD       NVARCHAR(10) 
                            ,LINE_CD     NVARCHAR(10) 
                            ,PROC_CD     NVARCHAR(10) 
                            ,MASTER_LOT  NVARCHAR(50) 
                            ,USEM_SEQ    INT 
                        )

                        INSERT INTO @MN_LOT_LOOP 
                        (DIV_CD, PLANT_CD, WC_CD, LINE_CD, PROC_CD, MASTER_LOT, USEM_SEQ)
                        SELECT A.DIV_CD, A.PLANT_CD, A.WC_CD, A.LINE_CD, A.PROC_CD, A.MASTER_LOT, A.USEM_SEQ
                        FROM #MN_SE_TEMP A
                        WHERE A.LOT_NO = A.MASTER_LOT
                        
                        DECLARE @MN_LOT_CNT  INT = 0
                            ,@MN_LOT_TCNT INT = 0

                        SET @MN_LOT_TCNT = isnull((SELECT COUNT(*) FROM @MN_LOT_LOOP),0)
                       
                        WHILE @MN_LOT_CNT <> @MN_LOT_TCNT 
                        BEGIN 
                            SET @MN_LOT_CNT = @MN_LOT_CNT + 1 

                            DECLARE @LOT_SEQ INT = 0 
                                ,@MASTER_LOT NVARCHAR(50) = ''
                                ,@USEM_SEQ INT = 0

                            SELECT @MASTER_LOT = A.MASTER_LOT, @USEM_SEQ = A.USEM_SEQ FROM @MN_LOT_LOOP A WHERE A.CNT = @MN_LOT_CNT 

--                            SELECT *FROM @MN_LOT_LOOP

                            IF NOT EXISTS(SELECT *FROM PD_RESULT_MN_LOT A WITH (NOLOCK)
                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                            AND A.MASTER_LOT = @MASTER_LOT
                            )
                            BEGIN 
                                SET @LOT_SEQ = ISNULL((SELECT TOP 1 A.LOT_SEQ FROM PD_RESULT_MN_LOT A WITH (NOLOCK) 
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
                                AND A.MASTER_LOT = @MASTER_LOT
                                ORDER BY A.LOT_SEQ
                                ),0) + 1

                                INSERT INTO PD_RESULT_MN_LOT 
                                (
                                    DIV_CD, PLANT_CD, WC_CD, LINE_CD, PROC_CD, MASTER_LOT, LOT_SEQ, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT
                                )

                                SELECT 
                                @DIV_CD, @PLANT_CD, @WC_CD, @LINE_CD, @PROC_CD, @MASTER_LOT, @LOT_SEQ, @USER_ID, GETDATE(), @USER_ID, GETDATE()
                            END 
                            UPDATE A SET A.LOT_NO = @MASTER_LOT + '-' +  CAST(@LOT_SEQ AS NVARCHAR)
                                FROM #MN_SE_TEMP A
                            WHERE A.MASTER_LOT = @MASTER_LOT AND A.USEM_SEQ = @USEM_SEQ 

                        END 
                    END 
                END 

                --SELECT *FROM #MN_SE_TEMP

                -- 마지막으로 PD_ITEM_IN 을 만듭니다. 

                -- @idx_dt, @idx_seq 때문에 loop 를 돌아야 한다.
                -- 혹시나 중복되는게 있으면 안되기 때문에

                DECLARE @MN_SE_CNT INT = 0
                       ,@MN_SE_TCNT INT = 0 

                SET @MN_SE_TCNT = ISNULL((SELECT COUNT(*) FROM #MN_SE_TEMP),0)

                WHILE @MN_SE_CNT <> @MN_SE_TCNT 
                BEGIN 
                    SET @MN_SE_CNT = @MN_SE_CNT + 1 
                    SET @IDX_SEQ = ISNULL((SELECT MAX(A.IDX_SEQ)
                    FROM PD_ITEM_IN A WITH (NOLOCK)
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IDX_DT = @IDX_DT),0) + 1

                    INSERT INTO PD_ITEM_IN
                    (
                    DIV_CD, PLANT_CD, PROC_NO, ORDER_NO, REVISION,
                    ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD,
                    LINE_CD, PROC_CD, S_CHK, RESULT_SEQ, SEQ,
                    ITEM_CD, LOT_NO, SL_CD, LOCATION_NO, RACK_CD,
                    BARCODE, SIL_DT, DEPARTMENT, IDX_DT, IDX_SEQ,
                    GOOD_QTY, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT
                    )
                    SELECT 
                    A.DIV_CD, A.PLANT_CD, A.PROC_NO, A.ORDER_NO, A.REVISION, A.ORDER_TYPE, A.ORDER_FORM, 
                    A.ROUT_NO, A.ROUT_VER, A.WC_CD, A.LINE_CD, A.PROC_CD, 'N', A.RESULT_SEQ, A.USEM_SEQ, 
                    A.ITEM_CD, A.LOT_NO, A.SL_CD, A.LOCATION_NO, '*','*',A.SIL_DT, A.DEPARTMENT, @IDX_DT, @IDX_SEQ,
                    A.RESULT_QTY, @USER_ID, GETDATE(), @USER_ID, GETDATE()
                    FROM #MN_SE_TEMP A WHERE A.CNT = @MN_SE_CNT 

                END

        END 
        ELSE 
        BEGIN 
            -- 그룹공정의 SEQ 를 봐야 하기 때문에 PD_ITEM_IN SEQ 를 채번한다. 
            -- 그룹안에 있고, 아웃이 아니면? 생성할 필요가 없다. 

            
            IF (SELECT B.OUT_CHK FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
            INNER JOIN PD_ORDER_PROC B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO 
            AND A.REVISION = B.REVISION AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL) = 'N' 
            BEGIN            
                SET @LAST_YN = 'N'
            END 

            IF @LAST_YN = 'Y' 
            BEGIN 

                DECLARE @PD_IN_SEQ INT = 0

                SET @PD_IN_SEQ = ISNULL((SELECT MAX(SEQ) FROM PD_ITEM_IN A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 
                AND A.PROC_CD =  CASE WHEN DBO.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' THEN '*' ELSE @PROC_CD END 
                AND A.RESULT_SEQ = @RESULT_SEQ 
                ),0) + 1

                -- BARCODE 생성 한다. 

                DECLARE @LAST_QTY NUMERIC(18,3) = 0 

                DECLARE @VAL        INT   
                       ,@MTART      NVARCHAR(20)
                       ,@BARCODE    NVARCHAR(50) 
                       ,@PALLET_SEQ INT 
                
                SET @SIL_DT = DBO.UFNSR_GET_DAYNIGHT(GETDATE(),'T')

                IF DBO.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' 
                BEGIN 
             
                EXEC @VAL = XM_BAR_LOT_CREATE_NEW @DIV_CD, @PLANT_CD, 'P', @ITEM_CD, @SIL_DT, @LINE_CD, @USER_ID, @MTART OUT, @BARCODE OUT, @PALLET_SEQ OUT       

                SET @LAST_QTY = ISNULL((SELECT SUM(AA.GOOD_QTY) FROM PD_ITEM_IN AA WITH (NOLOCK)
                WHERE AA.DIV_CD = @DIV_CD AND AA.PLANT_CD = @PLANT_CD AND AA.ORDER_NO = @ORDER_NO AND AA.REVISION = @REVISION AND 
                AA.ORDER_TYPE = @ORDER_TYPE AND AA.ORDER_FORM = @ORDER_FORM AND AA.ROUT_NO = @ROUT_NO AND AA.ROUT_VER = @ROUT_VER AND 
                AA.WC_CD = @WC_CD AND AA.LINE_CD = @LINE_CD AND AA.PROC_CD = '*' AND AA.RESULT_SEQ = @RESULT_SEQ AND AA.DEPARTMENT = @DEPARTMENT
                AND AA.SEQ <> @PD_IN_SEQ),0) 
                
                SELECT @LOT_NO = A.LOT_NO FROM PD_RESULT A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND 
                    A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                    A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
                    A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD

                     INSERT INTO PALLET_MASTER (                          
                        DIV_CD,         BARCODE,        BAR_SEQ,        ITEM_CD,        LOT_NO,         BAG_SIZE,        
                        MOVE_TYPE,      BAR_DT,         INSERT_ID,      INSERT_DT,      UPDATE_ID,      UPDATE_DT,      
                        ORDER_NO,       ORDER_SEQ,      NSEQ,           CREATE_SYS,     USE_FLAG,       PRINT_CNT, 
                        LOT_GBN,        ITEM_TYPE,      DT,             SEQ        
                        --TEMP_CD1,      TEMP_CD2,      TEMP_CD3,      CON_NO,                 
                                                
                    )                          
                    VALUES (                          
                        @DIV_CD,      @BARCODE,       @PD_IN_SEQ,       @ITEM_CD,      @LOT_NO,         @LAST_QTY,         
                        
                        '201',          CONVERT(NVARCHAR(6), CAST(@SIL_DT AS DATETIME), 12),  @USER_ID,      GETDATE(),          @USER_ID,      GETDATE(),                        
                        @ORDER_NO,      @REVISION,      @RESULT_SEQ,   'POP',          'N',             0,
                        'P',            @MTART,         @SIL_DT,        @PD_IN_SEQ
                        --@ZDEDN,         @NSEQ,         @TOTALCNT,      @ZCOTNO,                          
                                                
                    )                          
                END 
                ELSE 
                BEGIN
                    SET @BARCODE = '*'
                END 
                INSERT INTO PD_ITEM_IN
                (
                DIV_CD, PLANT_CD, PROC_NO, ORDER_NO, REVISION,
                ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD,
                LINE_CD, PROC_CD, S_CHK, RESULT_SEQ, SEQ,
                ITEM_CD, LOT_NO, SL_CD, LOCATION_NO, RACK_CD,
                BARCODE, SIL_DT, DEPARTMENT, IDX_DT, IDX_SEQ,
                GOOD_QTY, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT
                )

                SELECT
                    A.DIV_CD, A.PLANT_CD, A.PROC_NO, A.ORDER_NO, A.REVISION,
                    A.ORDER_TYPE, A.ORDER_FORM, A.ROUT_NO, A.ROUT_VER, A.WC_CD,
                    A.LINE_CD, --A.PROC_CD
                    CASE WHEN DBO.FN_GET_LAST_PROC(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD) = 'Y' THEN '*' ELSE A.PROC_CD END 
                    , A.S_CHK, A.RESULT_SEQ, @PD_IN_SEQ,
                    A.ITEM_CD, A.LOT_NO, '3000', A.LINE_CD, '*',
                    @BARCODE, A.SIL_DT, @DEPARTMENT, @IDX_DT, @IDX_SEQ,
                    A.GOOD_QTY
                    - @LAST_QTY
                    , @USER_ID, GETDATE(), @USER_ID, GETDATE()

                FROM PD_RESULT A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND 
                    A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                    A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
                    A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD
            END 
        END 

        -- 그룹공정안에 있으면 처리하면 안된다.

        SET @LAST_YN = 'Y'
       
        IF EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL)
        BEGIN

        
                IF NOT EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL
                AND A.CYCLE_SEQ = A.CYCLE)
                BEGIN 
                    SET @LAST_YN ='N'
                END 
        END 


        IF @LAST_YN = 'Y' 
        BEGIN 
            -- 이후 PD_RESULT EDATE 에 종료 
            UPDATE A SET A.EDATE = CAST(@VALUE_STR AS DATETIME)
                FROM PD_RESULT A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND
                A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
                A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD


            -- LOT_SEQ UPDATE 
            -- OUT_CHK

            IF (SELECT A.OUT_CHK FROM PD_ORDER_PROC A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND
                A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD
            ) = 'Y'
            BEGIN 
                DECLARE @SIL_LOT_SEQ INT = 0 
                       
                SELECT @SIL_LOT_SEQ = ISNULL(A.LOT_SEQ,0), @SIL_DT =A.SIL_DT FROM PD_RESULT A 
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND
                    A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
                    A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
                    A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD

                IF ISNULL(@SIL_dT,'') = '' 
                begin
                    SET @SIL_dT = CONVERT(NVARCHAR(10),GETDATE(), 120)
                END

                IF EXISTS(SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)                         
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = CONVERT(NVARCHAR(7), CAST(@SIL_DT AS DATETIME), 120)                         
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                         
                )                        
                BEGIN    
                                         
                    UPDATE A SET A.LOT_SEQ = CASE WHEN ISNULL(@SIL_LOT_SEQ,0) = 0 THEN A.LOT_SEQ ELSE @SIL_LOT_SEQ END , A.ORDER_NO = @ORDER_NO, A.REVISION = @REVISION, A.RESULT_SEQ = @RESULT_SEQ,                        
                    UPDATE_ID = @USER_ID, UPDATE_DT = GETDATE()                        
                        FROM PD_LOT_SEQ A WITH (NOLOCK)                         
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = CONVERT(NVARCHAR(7), CAST(@SIL_DT AS DATETIME), 120)                         
                    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                         
                END                         
                ELSE                         
                BEGIN                         
                    INSERT INTO PD_LOT_SEQ (                        
                        DIV_CD,            PLANT_CD,              DT,                  WC_CD,                  LINE_CD,                                       
                        PROC_CD,           LOT_SEQ,               ORDER_NO,            REVISION,                                       
                        RESULT_SEQ,        INSERT_ID,             INSERT_DT,           UPDATE_ID,              UPDATE_DT                         
                    )                        
                    SELECT                         
                        @DIV_CD,           @PLANT_CD,             CONVERT(NVARCHAR(7), CAST(@SIL_DT AS DATETIME), 120),             @WC_CD,                 @LINE_CD,                         
                        @PROC_CD,          @SIL_LOT_SEQ,          @ORDER_NO,           @REVISION,                                      
                        @RESULT_SEQ,       @USER_ID,              GETDATE(),           @USER_ID,               GETDATE()              
                END                     
            END 
            -- SAP Interface 를 날려야 되나요?


            IF EXISTS(
                SELECT *
            FROM PD_RESULT A WITH (NOLOCK)
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
                SET @MSG_CD = 'SAP 처리'
            END

            /*
            -- 품질 샘플 LOT 업데이트 
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
            */
            --샘플 정보등록
            /*
            DECLARE @DC_QC_TYPE		NVARCHAR(15)

            IF @PROC_CD = 'PA'
            BEGIN
                SET @DC_QC_TYPE = 'PQC'
            END
            ELSE
            BEGIN
                SET @DC_QC_TYPE = 'CQC'
            END

            INSERT INTO QC_SAMPLE_REQUEST
            (
                DIV_CD			,PLANT_CD			,QC_DT				,QC_CK
                ,QC_SEQ			,QC_SAMPLE_SEQ		,QC_TYPE			,REP_ITEM_CODE
                ,ITEM_CD		,QC_LOT_NO			,QC_LOT_SEQ			,PURPOSE_CD
                ,QC_QTY			,WC_CD				,LINE_CD			,PROC_CD
                ,ORDER_NO		,ORDER_SEQ			,RESULT_SEQ			,LOT_NO
                ,CAPA_CODE		,CAPA_NAME			,SAMPLING_TYPE		,SAMPLING_TYPE_NAME
                ,MP_TYPE		,MP_TYPE_NAME		,REMARK_NOTE		,SAMPLING_MST_SEQ
                ,SAMPLING_SEQ
                ,INSERT_ID		,INSERT_DT			,UPDATE_ID			,UPDATE_DT
                
            )
            SELECT
                A.DIV_CD		,A.PLANT_CD			,A.QC_DT			,A.QC_CK
                ,A.QC_SEQ		,B.QC_SAMPLE_SEQ	,@DC_QC_TYPE		,A.REP_ITEM_CD
                ,@ITEM_CD		,A.QC_LOT_NO		,A.QC_LOT_SEQ		,C.PURPOSE_CODE
                ,B.QC_QTY		,A.WC_CD			,A.LINE_CD			,A.PROC_CD
                ,@ORDER_NO		,@REVISION			,@RESULT_SEQ		,@LOT_NO
                ,C.CAPA_CODE	,C.CAPA_NAME		,C.SAMPLING_TYPE	,C.SAMPLING_TYPE_NAME
                ,C.MP_TYPE		,C.MP_TYPE_NAME		,C.REMARK_NOTE		,C.SAMPLING_MST_SEQ
                ,C.SAMPLING_SEQ
                ,@USER_ID		,GETDATE()			,@USER_ID			,GETDATE()
              
            FROM QC_SAMPLE_MASTER A (NOLOCK)
            INNER JOIN QC_SAMPLE_DETAIL B (NOLOCK)
            ON A.DIV_CD = B.DIV_CD
            AND A.PLANT_CD = B.PLANT_CD
            AND A.QC_DT = B.QC_DT
            AND A.QC_CK = B.QC_CK
            AND A.QC_SEQ = B.QC_SEQ
            LEFT OUTER JOIN VIEW_QC_SAMPLE_PERIOD C (NOLOCK)
            ON B.DIV_CD = C.DIV_CD
            AND B.PLANT_CD = C.PLANT_CD
            AND B.PERIOD_NO = C.PERIOD_NO
            WHERE A.DIV_CD = @DIV_CD
            AND A.PLANT_CD = @PLANT_CD
            AND LEFT(CONVERT(VARCHAR,A.QC_DT,23),7) = LEFT(CONVERT(VARCHAR,@SIL_DT,23),7)
            AND A.WC_CD = @WC_CD
            AND A.LINE_CD = @LINE_CD
            AND A.PROC_CD = @PROC_CD
            AND A.QC_LOT_SEQ = @LOT_SEQ
            AND B.IF_REQUEST_YN = 'Y'
            */
        END 
    END

    IF EXISTS(SELECT *
    FROM PD_MDM_RESULT_MASTER A WITH (NOLOCK)
    WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.EDATE IS NULL  
    )
    BEGIN


        SELECT @LOT_NO = A.LOT_NO

        FROM PD_RESULT A WITH (NOLOCK)
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND
            A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND
            A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND
            A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.EQP_CD = @EQP_CD

        UPDATE A SET A.EDATE = GETDATE(), A.ITEM_CD = @ITEM_CD, A.LOT_NO = ISNULL(@LOT_NO,'')
            FROM PD_MDM_RESULT_MASTER A WITH (NOLOCK)
        WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.WC_CD = @WC_CD
            AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.EDATE IS NULL

        UPDATE A SET A.LOT_NO = @LOT_NO 
        FROM FlexAPI_NEW.DBO.IFM705_Master A WITH (NOLOCK)
        WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.ORDER_NO = @ORDER_NO AND A.WC_CD = @WC_CD
            AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.PLAN_SEQ = @RESULT_SEQ

    END

    UPDATE A SET A.END_DT = GETDATE() 
    FROM PD_MDM_WORK_SEND A 
    WHERE A.PD_AUTO_NO = @PD_AUTO_NO

END 

-- 그룹공정 체크후 다 완료 되었으면 마무리 한다.

IF NOT EXISTS(SELECT *FROM PD_MDM_RESULT_GROUP A WITH (NOLOCK)
INNER JOIN PD_RESULT B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.EDATE IS NULL
WHERE A.PD_AUTO_NO = @PD_AUTO_NO)
BEGIN

    UPDATE A SET A.EDATE = GETDATE() 
    FROM PD_MDM_RESULT_GROUP A
    WHERE A.PD_AUTO_NO = @PD_AUTO_NO 

END

UPDATE A SET A.END_DT = GETDATE() FROM PD_MDM_RESULT_PROC_SPEC A WITH (NOLOCK)
WHERE A.PD_AUTO_NO = @PD_AUTO_NO AND A.SEQ = @SEq AND A.ORDER_NO = @ORDER_NO AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD
    AND A.TAG_ID = @TAG_ID AND A.SEQ = @SEQ AND A.VALUE_STEP = @VALUE_STEP
    AND A.END_DT IS NULL

-- 화면 업데이트를 위함.
UPDATE A SET A.DEL_FLG = 'Y'
FROM PD_RESULT A WITH (NOLOCK) 
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



