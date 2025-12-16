USE FLEXMES_NEW
GO
--BEGIN TRAN 
ALTER PROC USP_POP_004_MATERIAL_START(
--DECLARE 
     @DIV_CD        NVARCHAR(10)   = '01'
    ,@PLANT_CD      NVARCHAR(10)   = '1130'
    ,@ORDER_NO      NVARCHAR(50)   = 'PD250113002'
    ,@REVISION      INT            = '1'
    ,@WC_CD         NVARCHAR(10)   = '13GA'
    ,@LINE_CD       NVARCHAR(10)   = '13G01A' 
    ,@PROC_CD       NVARCHAR(10)   = 'RI'
    ,@EQP_CD        NVARCHAR(50)   = 'LFG-MST-10-02'
    ,@USER_ID       NVARCHAR(15)   = 'admin'

    ,@MSG_CD        NVARCHAR(4)     OUTPUT 
    ,@MSG_DETAIL    NVARCHAR(MAX)   OUTPUT 
)
AS

/*

원료 투입쪽이라 크게 할건 없고 각 항목에 맞게 그냥 PD_RESULT, PD_USEM, PD_RESULT_PROC_SPEC 에 차근차근 넣어주기만 하면 된다.
설비코드도 기본적으로 지정되어 있으니.. 

0. 등록된 원자재 내역이 있는가? 체크
0-1. 작업이 하나인지도 체크한다.
0-2. 있으면 @RESULT_SEQ 가지고 온다.
1. 이미 시작이 있는가? 체크 
2. PD_RESULT 생성
3. PD_USEM 이관
4. PD_USEM_TEMP_MASTER, TEMP 완료 업데이트
5. PD_RESULT_SPEC_VALUE 이관

*/
BEGIN TRY 
    -- 변수 선언
    DECLARE 
         @PROC_NO        NVARCHAR(50) = ''
        ,@ORDER_TYPE     NVARCHAR(10) = ''
        ,@ORDER_FORM     NVARCHAR(10) = '' 
        ,@ROUT_NO        NVARCHAR(10) = '' 
        ,@ROUT_VER       INT = 0 
        ,@RESULT_SEQ     INT = 0
        ,@TEMP_SEQ       INT = 0
        ,@ITEM_CD        NVARCHAR(50) = ''

    -- 실적 등록 필요 변수
        ,@SDATE    DATETIME = GETDATE() 
        ,@LOT_NO   NVARCHAR(50) 
        ,@STR_DATE NVARCHAR(8)
        ,@RK_DATE  NVARCHAR(10) 
        ,@SIL_DT   NVARCHAR(10)
        ,@DAY_FLG  NVARCHAR(10)

    -- 0. 등록된 원자재 내역이 있는가? 체크

    IF NOT EXISTS(
        SELECT *FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
        A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND 
        A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND 
        A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_sEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND 
        A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.USEM_EQP = @EQP_CD AND A.PROC_CD = @PROC_CD 
        AND A.START_YN = 'N' 
    )
    BEGIN 
        SET @MSG_CD = '0060' 
        SET @MSG_DETAIL = '투입 내역이 없습니다. 작업을 시작할수 없습니다.'
        
        --SELECT @MSG_CD, @MSG_DETAIL --MSG
        
        RETURN 1
    END     
    ELSE 
    BEGIN 
    -- 0-1. 작업이 하나인지도 확인한다.


        IF (SELECT COUNT(*) FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        /*
            INNER JOIN PD_USEM_MAT_TEMP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
            A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND 
            A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND 
            A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_sEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
            */
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND 
            A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.USEM_EQP = @EQP_CD AND A.PROC_CD = @PROC_CD 
            AND A.START_YN = 'N' 
        ) > 1
        BEGIN
            SET @MSG_CD = '9999'
            SET @MSG_DETAIL = '작업 중복건이 있습니다. 데이터 오류입니다. 관리자에게 문의하여 주십시오.'
            
            --SELECT @MSG_CD, @MSG_DETAIL --MSG

            RETURN 1
        END 

    -- 0-2. 있으면 기준 정보 변수 리스트를 매칭 한다. 

        SELECT TOP 1 @PROC_NO = B.PROC_NO, @ORDER_TYPE = B.ORDER_TYPE, @ORDER_FORM = B.ORDER_FORM, @ROUT_NO = B.ROUT_NO, @ROUT_VER = B.ROUT_VER,
        @RESULT_SEQ = B.RESULT_SEQ, @TEMP_SEQ = B.TEMP_SEQ FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
        A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND 
        A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_cD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ
        AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND 
        A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.USEM_EQP = @EQP_CD AND A.PROC_CD = @PROC_CD 
        AND A.START_YN = 'N' 

    END
    --SELECT @ORDER_NO, @REVISION, @PROC_NO, @ORDER_TYPE, @ORDER_FORM, @ROUT_NO, @ROUT_VER, @WC_CD, @LINE_CD, @PROC_CD, @RESULT_SEQ --MSG

    -- 1. 이미 시작이 있는가? 체크, 설비까지 같이 체크를 해야 된다. 확인할것.

    IF EXISTS(
        SELECT *FROM PD_RESULT A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD AND A.EDATE IS NULL 
    )
    BEGIN 
        SET @MSG_CD = '0060' 
        SET @MSG_DETAIL = '작업 진행중인 내역이 있습니다. 확인하여 주십시오.'

    --    SELECT @MSG_CD, @MSG_DETAIL --MSG
        
        RETURN 1
    END 

    -- 1-1. PD_USEM_MAT_TEMP 에 두개의 품목이 있는지도 체크한다$. 
    IF @WC_CD NOT IN ('13GD')
    BEGIN 
        IF (SELECT COUNT(DISTINCT A.ITEM_CD) FROM PD_USEM_MAT_TEMP A WITH (NOLOCK) 
            INNER JOIN PD_USEM_MAT_TEMP_MASTER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
            A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND 
            A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND 
            A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_cD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD 
            AND A.TEMP_SEQ = @TEMP_SEQ 
            AND B.START_YN = 'N'
            --GROUP BY A.ITEM_CD
        ) > 1
        BEGIN 


            SET @MSG_CD = '0060'
            SET @MSG_DETAIL = '등록된 원료의 종류가 2가지 이상입니다. 확인하여 주십시오.' 

        --  SELECT @MSG_CD, @MSG_DETAIL --MSG 

            RETURN 1
        END 
        ELSE 
        BEGIN 
            -- 품목코드를 가지고 온다. 

            SELECT TOP 1 @ITEM_CD = A.ITEM_CD, @LOT_NO = A.LOT_NO FROM PD_USEM_MAT_TEMP A WITH (NOLOCK) 
            INNER JOIN PD_USEM_MAT_TEMP_MASTER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
            A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND 
            A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND 
            A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_cD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD AND A.TEMP_SEQ = @TEMP_SEQ 
            AND B.START_YN = 'N'
            ORDER BY A.USEM_SEQ ASC 
        END 
    END 
    ELSE 
    BEGIN 
        -- 수세 일 경우는 그냥 바로 체크 하자. 
        SELECT TOP 1 @ITEM_CD = A.ITEM_CD, @LOT_NO = A.LOT_NO FROM PD_USEM_MAT_TEMP A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP_MASTER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
        A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND 
        A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND 
        A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_cD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD AND A.TEMP_SEQ = @TEMP_SEQ 
        AND B.START_YN = 'N'
        ORDER BY A.USEM_SEQ ASC 
    end 
    --2. PD_RESULT 생성
    
    SET @STR_DATE = CONVERT(NVARCHAR(8), CAST(@SDATE AS DATETIME), 112)           

--    EXEC USP_CM_AUTO_NUMBERING 'PR', @STR_DATE, @USER_ID, @LOT_NO OUT                 
    SET @RK_DATE = CONVERT(NVARCHAR(10), CAST(@SDATE AS DATETIME), 120)
    SET @SIL_DT = dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'T')
    SET @DAY_FLG = dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'D') 

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
        'N',               @RK_DATE,             @SDATE,                 NULL,                    @SIL_DT, 
        @DAY_FLG,          'N',                  0,                      '%',                     @EQP_CD,
        @USER_ID,          GETDATE(),            @USER_ID,               GETDATE(),               ''
    

    --3. PD_USEM 이관
    INSERT INTO PD_USEM 
    (
        DIV_CD,            PLANT_CD,             PROC_NO,                ORDER_NO,                REVISION,      
        ORDER_TYPE,        ORDER_FORM,           ROUT_NO,                ROUT_VER,                WC_CD, 
        LINE_CD,           PROC_CD,              RESULT_SEQ,             USEM_SEQ,                USEM_WC, 
        USEM_PROC,         USEM_EQP,             ITEM_CD,                SL_CD,                   LOCATION_NO, 
        RACK_CD,           LOT_NO,               MASTER_LOT,             BARCODE,                 
        PLC_QTY,           USEM_QTY,             USE_CHK,                DEL_FLG,                 REWORK_FLG, 
        INSERT_ID,         INSERT_DT,            UPDATE_ID,              UPDATE_DT,               REQ_DT, 
        REQ_NO,            REQ_SEQ,              PLAN_SEQ,               BATCH_NO,                BE_ORDER_NO,
        BE_REVISION,       BE_RESULT_SEQ,        BE_PROC_CD,             ITEM_TYPE,               IN_GBN, 
        STANDARD_DATE,     QC_RESULT,            ZMESIFNO 
    )

    SELECT 
        B.DIV_CD,          B.PLANT_CD,           B.PROC_NO,              B.ORDER_NO,              B.REVISION, 
        B.ORDER_TYPE,      B.ORDER_FORM,         B.ROUT_NO,              B.ROUT_VER,              B.WC_CD, 
        B.LINE_CD,         B.PROC_CD,            B.RESULT_SEQ,           B.USEM_SEQ,              B.USEM_WC, 
        B.USEM_PROC,       B.USEM_EQP,           B.ITEM_CD,              B.SL_CD,                 B.LOCATION_NO, 
        B.RACK_CD,         B.LOT_NO,             B.MASTER_LOT,           B.BARCODE,           
        B.PLC_QTY,         B.USEM_QTY,           B.USE_CHK,              B.DEL_FLG,               B.REWORK_FLG, 
        @USER_ID,          GETDATE(),            @USER_ID,               GETDATE(),               B.REQ_DT, 
        B.REQ_NO,          B.REQ_SEQ,            B.PLAN_SEQ,             B.BATCH_NO,              B.BE_ORDER_NO, 
        B.BE_REVISION,     B.RESULT_SEQ,         B.BE_PROC_CD,           B.ITEM_TYPE,             B.IN_GBN, 
        B.STANDARD_DATE,   B.QC_RESULT,          ''
        FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP B WITH (NOLOCK) ON A.DIV_cD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND 
        A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND 
        A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ 
        AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.DIV_cD = @DIV_cD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDEr_NO = @ORDER_NO 
        AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_tYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM 
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_vER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_cD = @PROC_cD
        AND A.USEM_EQP = @EQP_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.TEMP_SEQ = @TEMP_SEQ 
        AND A.START_YN = 'N'
    
    -- 3-1 배정표에 있으면? 배정표 수량 업데이트 진행

    UPDATE AA SET AA.USE_QTY = BB.USE_QTY, AA.USE_FLG = 'N'
    FROM MT_ITEM_OUT_BATCH AA
    INNER JOIN 
    (
    SELECT B.DIV_CD, B.PLANT_CD, B.REQ_NO, SUM(B.USEM_QTY) AS USE_QTY FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP B WITH (NOLOCK) ON A.DIV_cD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND 
        A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND 
        A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.USEM_EQP = B.USEM_EQP AND A.RESULT_SEQ = B.RESULT_SEQ 
        AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.DIV_cD = @DIV_cD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDEr_NO = @ORDER_NO 
        AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_tYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM 
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_vER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_cD = @PROC_cD
        AND A.USEM_EQP = @EQP_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.TEMP_SEQ = @TEMP_SEQ 
        AND A.START_YN = 'N'
        GROUP BY B.DIV_CD, B.PLANT_CD, B.REQ_NO
    ) BB ON AA.DIV_CD = BB.DIV_cD AND AA.PLANT_CD = BB.PLANT_CD AND AA.REQ_NO = BB.REQ_NO

    --4. PD_USEM_TEMP_MASTER, TEMP 완료 업데이트
    UPDATE A SET A.START_YN = 'Y' 
    FROM PD_USEM_MAT_TEMP_MASTER A
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDEr_NO = @ORDER_NO 
        AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_tYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM 
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_vER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_cD = @PROC_cD
        AND A.USEM_EQP = @EQP_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.TEMP_SEQ = @TEMP_SEQ 

    --5. PD_RESULT_SPEC_VALUE 이관 : 나중에 진행

    -- 자 이제 시작하지. 25.08.29
    -- 원래 쿼리는 
    -- GROUP_SPEC_CD => 이거 분류이구나. AIR 관련 내용이다.
    -- 설비는 일단 설비코드가 있으니 그대로 가지고 가자. 
    -- CYCLE_SEQ 도 그냥 일단 그대로 간다. 뒤에 확인해야 함.
    
    IF NOT EXISTS(SELECT *FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDEr_NO = @ORDER_NO 
        AND A.REVISION = @REVISION AND A.ORDER_tYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM 
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_vER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_cD = @PROC_cD
        AND A.RESULT_SEQ = @RESULT_SEQ 
    )
    BEGIN 
        DECLARE @IN_SEQ    INT = 0            
               ,@CYCLE_SEQ INT = 1 -- 임시로 넣음
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
            @IN_SEQ,            @ORDER_NO,         @REVISION,          @RESULT_SEQ,         'N',         
            @CYCLE_SEQ,         @USER_ID,          GETDATE(),          @USER_ID,            GETDATE()           
           

        INSERT INTO PD_RESULT_PROC_SPEC_VALUE (           
            DIV_CD,              PLANT_CD,             ORDER_NO,              REVISION,              ORDER_TYPE,             ORDER_FORM,            
            ROUT_NO,             ROUT_VER,             WC_CD,                 LINE_CD,               PROC_CD,                S_CHK,           RESULT_SEQ,            
            CYCLE_SEQ,           SEQ,                  SPEC_VERSION,          PROC_SPEC_CD,          EQP_CD,                 SPEC_VALUE_TYPE,            
            SPEC_VALUE,          REMARK,               INSERT_ID,             INSERT_DT,             UPDATE_ID,              UPDATE_DT,           
            IN_DATE,             IN_SEQ,               GROUP_SPEC_CD           
        )           
           
        SELECT A.DIV_CD,         A.PLANT_CD,           A.ORDER_NO,            A.REVISION,            A.ORDER_TYPE,           A.ORDER_FORM,            
            A.ROUT_NO,           A.ROUT_VER,           A.WC_CD,               A.LINE_CD,             A.PROC_CD,              'N',            @RESULT_SEQ,           
            @CYCLE_SEQ,          A.SEQ,                A.SPEC_VERSION,        A.PROC_SPEC_CD,        A.EQP_CD,               CASE WHEN A.SPEC_VALUE_TYPE = '' THEN '20' ELSE A.SPEC_VALUE_TYPE END,            
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
            FROM PD_ORDER_PROC_SPEC_V2 A 
             LEFT JOIN POP_EQP_ENO BB ON BB.DIV_CD = @DIV_CD AND BB.PLANT_CD = @PLANT_CD          
    		AND A.EQP_CD = BB.EQP_CD AND BB.PROC_CD = @PROC_CD AND A.PROC_SPEC_CD = BB.PROC_SPEC_CD          
	        
        WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
          AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
          AND A.EQP_CD = @EQP_CD --IN (SELECT EQP_CD FROM @EQP_TBL)           
--          AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)   
          AND A.RECYCLE_NO IN (@CYCLE_SEQ, '')          
             AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
            WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 
    END 


    -- MDM Interface 에 데이터를 집어 넣는다. 

    IF NOT EXISTS(SELECT *FROM PD_MDM_WORK_SEND A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD 
    AND A.RESULT_SEQ = @RESULT_SEQ AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO 
    )
    BEGIN 

        DECLARE @ITEM_TYPE NVARCHAR(10) = ''
               ,@AUTO_NO   NVARCHAR(50) = ''
               ,@PD_AUTO_NO NVARCHAR(50) = ''
               ,@DEPARTMENT NVARCHAR(10) = ''
               ,@REQ_QTY    NUMERIC(18,3) = 0 
        SET @ITEM_TYPE = ISNULL((SELECT A.TP FROM BA_EQP A WITH (NOLOCK) WHERE A.EQP_CD = @EQP_CD AND A.PROC_CD = @PROC_CD),'')

        EXEC USP_CM_AUTO_NUMBERING 'MD', @STR_DATE, @USER_ID, @AUTO_NO OUT                 
        
        SET @PD_AUTO_NO = 'PD' + CAST(@AUTO_NO AS NVARCHAR)

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


        SET @REQ_qTY = ISNULL((SELECT A.USEM_QTY 
            FROM PD_USEM A WITH (NOLOCK)
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
                AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ
                AND ISNULL(A.REQ_NO,'') <> ''),0)
         
        INSERT INTO PD_MDM_WORK_SEND
        (
            PD_AUTO_NO,
            AUTO_NO, 
            DIV_CD,                   PLANT_CD, 
            ORDER_NO,                 WC_CD,               LINE_CD,               PROC_CD,                    EQP_CD, 
            RESULT_SEQ,               ITEM_CD,             LOT_NO,                ITEM_TYPE,                  REQ_QTY,
            REQ_DT,                   PLAN_SEQ,            BATCH_SEQ,             
            BATCH_STR, 
            START_DT,                   END_DT, 
            GBN
        )
        SELECT 
            @PD_AUTO_NO,
            @AUTO_NO,
            A.DIV_CD,                 A.PLANT_CD,
            A.ORDER_NO,               A.WC_CD,             A.LINE_CD,             A.PROC_CD,                  A.EQP_CD, 
            A.RESULT_SEQ,             A.ITEM_CD,           A.LOT_NO,              @ITEM_TYPE,                 @REQ_qTY, 
            '',                       '',                  '',                    
            @DEPARTMENT,
            GETDATE(),                  NULL,
            'S'
        
        FROM PD_RESULT A 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
          AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
          AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ 
          AND A.EDATE IS NULL



    END 

END TRY 
BEGIN CATCH 
    SET @MSG_CD = '9999'
    SET @MSG_DETAIL = ERROR_MESSAGE()
    RETURN 1
END CATCH   

