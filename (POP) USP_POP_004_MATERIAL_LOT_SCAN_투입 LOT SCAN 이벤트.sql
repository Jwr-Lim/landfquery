--BEGIN TRAN 

ALTER PROC USP_POP_004_MATERIAL_LOT_SCAN(
--DECLARE
    @DIV_CD         NVARCHAR(10)   = '01'
   ,@PLANT_CD       NVARCHAR(10)   = '1130'
   ,@WC_CD          NVARCHAR(20)   = '13GA'
   ,@LINE_CD        NVARCHAR(20)   = '13G01A'
   ,@PROC_CD        NVARCHAR(10)   = 'RI'
   ,@EQP_CD         NVARCHAR(50)   = 'LFG-MST-10-02'  -- LFG-MST-10-02,  LFG-MSTS-09-02
   ,@ORDER_NO       NVARCHAR(50)   = 'PD250113002'
   ,@REVISION       INT            = 1
   ,@ITEM_CD        NVARCHAR(50)   = ''
   ,@LOT_NO         NVARCHAR(50)   = ''
   ,@BARCODE        NVARCHAR(50)   = 'MHALB-250116-0060' -- MROH-240906-0126 ,MHALB-250116-0060
   ,@QTY            NUMERIC(18,3)  = 0
   ,@BATCH_CHK      NVARCHAR(1)    = 'N'
   ,@SIL_DT         NVARCHAR(10)   = ''  -- 실적일자, 소분에 필요할려고 넣었는데, 추후 확인이 필요하다. 아니면 시작 시간을 지정하기 위해서... DATETIME 으로 변경 여부 확인 필요

   ,@QTY_CHK        NVARCHAR(1)    = 'N'
   ,@USER_ID        NVARCHAR(15)   = 'admin'

   ,@MSG_CD         NVARCHAR(4)    OUTPUT 
   ,@MSG_DETAIL     NVARCHAR(MAX)  OUTPUT 
)
AS

BEGIN TRY
/*

1. 체크 처리
1-0. 배정이면 가장 마지막 배정의 수량을 가지고 올수 있도록 한다. 
1-1. LOT 인지 아닌지 확인
1-2. 재고 확인 - 배정이 아닐때만
1-3. 검사 결과 및 개발품 체크 확인
1-4. 유효일 확인
1-5. 예외처리 진행

2. 배정 투입 처리
2-1. BATCH_CHK 에 따른 배정 투입부터 처리 진행
2-2. 현재 들어온 작업지시 및 LOT 가 순서에 맞는가 부터 확인한다.
2-3. 이전 미등록 배정 확인
2-4. 현재 lot 배정과 동일한 배정인지 확인 
2-5. 배정 수량이 동일한지 확인한다. 소분은 뒤에 다시 체크 한다. 
2-6. 임시 TEMP 에 넣는다.

3. 일반 투입 처리
3-1. 임시 TEMP 에 넣는다.
*/

    DECLARE @STOCK_QTY  NUMERIC(18,3) = 0   -- 현재 재고 수량
        ,@QC_CHK     NVARCHAR(1)   = ''  -- 검사 유무
        ,@QC_VALUE   NVARCHAR(10)  = ''  -- 검사 값
        ,@QC_NAME    NVARCHAR(10)  = ''  -- 검사 결과
        ,@PASS_CHK   NVARCHAR(1)   = 'N' -- 검사 패스 
        ,@DEV_CHK    NVARCHAR(1)   = 'N' -- 개발품 체크
        
        ,@REQ_DT     NVARCHAR(7)   = CONVERT(NVARCHAR(7),GETDATE(),120)
        ,@REQ_QTY    NUMERIC(18,3) = 0
        
        ,@REQ_NO        NVARCHAR(50)  = ''  -- 현재 투입가능한 가장 우선 배치 정보
        ,@BATCH_STR     NVARCHAR(20)  = ''  -- 현재 투입가능한 가장 우선 배치 번호 STRING
        ,@REQ_SEQ       NVARCHAR(10)  = ''  -- 배정 키 SEQ -> 이거 기본적으로 1이다.
        ,@PLAN_SEQ      NVARCHAR(10)  = ''  -- 배정 순번
        ,@BATCH_NO      NVARCHAR(10)  = ''  -- 배정 세부 순번
        ,@ITEM_TYPE     NVARCHAR(10)  = ''    

        ,@NOW_REQ_NO    NVARCHAR(50)  = ''  -- 현재 LOT 의 배치 정보
        ,@NOW_BATCH_STR NVARCHAR(50)  = ''  -- 현재 LOT 의 배치 번호 STRING
        ,@BE_REQ_NO     NVARCHAR(50)  = ''  -- 앞에 투입안된 배치 정보, 잘 없겠지만, 배정 잘못 때려박으면 생성될수 있음.
        ,@BE_BATCH_STR  NVARCHAR(50)  = ''  -- 앞에 투입안된 배치 번호 STRING


    -- TEMP 테이블에 넣기 위한 작업
    DECLARE  @PROC_NO        NVARCHAR(50) 
            ,@ORDER_TYPE     NVARCHAR(10) 
            ,@ORDER_FORM     NVARCHAR(10) 
            ,@ROUT_NO        NVARCHAR(10) 
            ,@ROUT_VER       NVARCHAR(10) 
            ,@RESULT_SEQ     INT 
            ,@USEM_SEQ       INT 
            ,@USEM_WC        NVARCHAR(10) 
            ,@USEM_PROC      NVARCHAR(10)
            ,@USEM_LOCATION  NVARCHAR(10) 
            ,@RACK_CD        NVARCHAR(10) 
            ,@IN_GBN         NVARCHAR(10)   = 'N' -- 소분일 경우 SU 가 들어가야 된다. 
            ,@STANDARD_DATE  NVARCHAR(10)

            ,@TEMP_SEQ       INT 
            ,@REP_ITEM_CD    NVARCHAR(50) 

    -- 0. 실적 체클르 위한 실적 및 TEMP 번호 최우선으로 매칭 진행
    -- 0-1. 그런데 지금 투입 진행되는 내역이 있으면? @RESULT_SEQ 는 제외하고 진행해야 된다. 
    IF EXISTS(SELECT *FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD 
    AND A.START_YN = 'N'
    )
    BEGIN 
        SET @RESULT_SEQ = ISNULL((
            SELECT A.RESULT_SEQ FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD 
            AND A.START_YN = 'N'
        ),0)
    END 
    else 
    begin 

        SET @RESULT_SEQ = ISNULL((
        SELECT MAX(AA.SEQ)
        FROM 
            (
            SELECT MAX(A.RESULT_SEQ) AS SEQ FROM PD_RESULT A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
            AND A.S_CHK = 'N'
            UNION ALL 
            SELECT MAX(A.RESULT_SEQ) AS SEQ FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.START_YN = 'N'
            ) AA
        ),0) + 1
    end 
    -- TEMP_SEQ 는 현재 등록 되고 있는게 있는지 부터 먼저 체크를 하고 없으면 하나 추가를 한다. 

    IF EXISTS(SELECT *FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD
        AND A.RESULT_SEQ = @RESULT_SEQ AND A.START_YN = 'N'
    )
    BEGIN 
        SET @TEMP_SEQ = (SELECT TOP 1 A.TEMP_SEQ FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD
        AND A.RESULT_SEQ = @RESULT_SEQ AND A.START_YN = 'N')
    END 
    ELSE 
    BEGIN 

        SET @TEMP_SEQ = ISNULL((
        SELECT MAX(A.TEMP_SEQ) FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD
        AND A.RESULT_SEQ = @RESULT_SEQ
        ),0) + 1

    END 

    -- 1.체크 처리

    -- 1-0. 배정이면 가장 마지막 배정의 내역을 가지고 올수 있도록 한다. 

    IF @BATCH_CHK = 'Y' 
    BEGIN 

        -- 추가적으로 해당 배정이 있는것은 제외를 해야 된다. 어디서?
        SELECT TOP 1 @REQ_NO = A.REQ_NO, @REQ_QTY = A.REQ_QTY - A.USE_QTY, @BATCH_STR = RIGHT(A.REQ_DT, 2) + '-' + CAST(A.PLAN_SEQ AS NVARCHAR),
        @REQ_SEQ = A.REQ_SEQ, @PLAN_SEQ = A.PLAN_SEQ, @ITEM_TYPE = A.ITEM_TYPE, @BATCH_NO = A.BATCH_NO, @REP_ITEM_CD = C.REP_ITEM_CD 

        FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
        INNER JOIN PD_ORDER_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.ITEM_CD = B.ITEM_CD AND B.EQP_CD = @EQP_CD 
        INNER JOIN V_ITEM C WITH (NOLOCK) ON B.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_DT = @REQ_DT
        AND A.USE_FLG = 'Y' AND A.CHG_RSN = '' AND A.ITEM_TYPE <> 'SU'
        AND A.REQ_QTY - A.USE_QTY > 0
        ORDER BY A.REQ_NO ASC 
        
    END 

--    SELECT @REP_ITEM_CD 

    -- 1-1. LOT 인지 아닌지 확인
    IF @BARCODE <> '' AND @LOT_NO = '' 
    BEGIN 
        
        SELECT @LOT_NO = A.LOT_NO, @ITEM_CD = A.ITEM_CD FROM REAL_MES.FLEXMES.DBO.ST_sTOCK_NOW A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = '*' AND A.SL_CD = '3000' AND A.RACK_CD <> '*' AND A.BARCODE = @BARCODE 

       

        IF @LOT_NO = '' OR @ITEM_CD = '' 
        BEGIN 
            SET @MSG_CD = '0060'
            SET @MSG_DETAIL = 'Barcode Scan 진행시 LOT 및 품목 정보를 확인할수 없습니다.' + CHAR(10) 
            + 'Barcode : ' + @BARCODE + ', Lot No. : ' + @LOT_NO + ', 품목코드 : ' + @ITEM_CD 
            
--            SELECT @MSG_CD, @MSG_DETAIL --MSG
            RETURN 1
        END 

    END 

    IF @BARCODE = '' AND @LOT_NO <> '' 
    BEGIN 
        SELECT TOP 1 @BARCODE = A.BARCODE, @ITEM_CD = A.ITEM_CD FROM REAL_MES.FLEXMES.DBO.ST_STOCK_NOW A WITH (NOLOCK) 
        INNER JOIN PALLET_MASTER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO AND A.BARCODE = B.BARCODE 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = '*' AND A.SL_CD = '3000' AND A.RACK_CD <> '*' AND A.LOT_NO = @LOT_NO 
        AND A.QTY > 0
        ORDER BY ABS(A.QTY - @REQ_QTY), A.BARCODE ASC -- 근사치가 있어야 된다.

        IF @BARCODE = '' OR @ITEM_CD = ''
        BEGIN 
            SET @MSG_CD = '0060'
            SET @MSG_DETAIL = 'LOT 전체 투입 진행시 Barcode 및 품목 정보를 확인할수 없습니다.' + CHAR(10) 
            + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD 
            
--            SELECT @MSG_CD, @MSG_DETAIL --MSG
            RETURN 1
        END 
    END 


    -- 1-2. 재고 확인 - 배정이 아닐때만
--    SELECT @BARCODE, @LOT_NO, @ITEM_CD -- DCHK

  
    IF EXISTS(SELECT *FROM REAL_MES.FLEXMES.DBO.ST_STOCK_NOW A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = '*' AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.BARCODE = @BARCODE AND A.LOT_NO = @LOT_NO 
    AND A.SL_CD = '3000' AND A.RACK_CD <> '*'
    )
    BEGIN 
        -- 수량을 가지고 옵시다.
        SELECT @STOCK_QTY = A.QTY FROM REAL_MES.FLEXMES.DBO.ST_STOCK_NOW A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = '*' AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.BARCODE = @BARCODE AND A.LOT_NO = @LOT_NO 
        AND A.SL_CD = '3000' AND A.RACK_CD <> '*'
    END 

    IF @BATCH_CHK <> 'Y' 
    BEGIN 
        IF @QTY_CHK <> 'N'
        BEGIN 
            IF @QTY = 0 
            BEGIN
                SET @MSG_CD = '0060'
                SET @MSG_DETAIL = '투입 수량이 입력되지 않았습니다. 확인하여 주십시오.' + CHAR(10)
                + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD + ', 수량 : ' + CAST(@QTY AS NVARCHAR)
            
    --            SELECT @MSG_CD, @MSG_DETAIL --MSG
                RETURN 1
            END 
        END 
        ELSE 
        BEGIN 
            SET @QTY = @STOCK_QTY
        END 

        IF @QTY > @STOCK_QTY 
        BEGIN 
            SET @MSG_CD = '0060' 
            SET @MSG_DETAIL = '투입 수량보다 재고 수량이 작습니다. 확인하여 주십시오.' + CHAR(10)
            + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD + CHAR(10) 
            + '투입수량 : ' + CAST(@QTY AS NVARCHAR) + ', 재고수량 : ' + CAST(@STOCK_QTY AS NVARCHAR)

            --SELECT @MSG_CD, @MSG_DETAIL --MSG
            RETURN 1
        END 

    END 
    
    -- 임시 데이터에 등록이 되어 있는지 확인한다. : 공통임

    IF EXISTS
    (
        SELECT *FROM PD_USEM_MAT_TEMP A WITH (NOLOCK) 
        INNER JOIN PD_USEM_MAT_TEMP_MASTER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND 
        A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND 
        A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND 
        A.USEM_EQP = B.USEM_EQP AND 
        A.RESULT_SEQ = B.RESULT_SEQ AND A.TEMP_SEQ = B.TEMP_SEQ 
        WHERE A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.BARCODE = @BARCODE 
    )
    BEGIN 
        SET @MSG_CD = '0060' 
        SET @MSG_DETAIL = '동일 항목이 이미 등록되어 있습니다. 확인하여 주십시오.' + CHAR(10) 
        + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD + CHAR(10) 
        RETURN 1
    END 

    --1-3. 검사 결과 및 개발품 체크 확인
    SET @QC_CHK = ISNULL((         
    SELECT A.TEMP_CD1         
        FROM BA_SUB_CD A WITH (NOLOCK)          
    WHERE A.MAIN_CD = 'POP51' AND A.SUB_CD = @PLANT_CD          
    ),'N')         

    IF ISNULL((SELECT B.BASE_ITEM_CD FROM PD_ORDER A WITH (NOLOCK)    
    INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD    
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION),'') = 'ZD00'    
    BEGIN    
        SET @DEV_CHK = 'Y'    
    END    

    SET @QC_CHK = 'N'
    
    IF @QC_CHK = 'Y' AND @DEV_CHK = 'N'      -- 개발품 체크 추가   
    BEGIN          
        -- 품목별 검사 여부를 체크 한다.          
            
        DECLARE @IN_QC   NVARCHAR(1) = 'N'         
        
        SELECT @IN_QC = ISNULL(A.QCT_FLG,'N')      
            FROM V_ITEM A WITH (NOLOCK) WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD          
        
        IF @IN_QC = 'Y'       
        BEGIN       
            SET @QC_VALUE = ISNULL((SELECT TOP 1 AA.QC_RESULT FROM          
            (      
            SELECT TOP 1 A.QC_RESULT, A.ORDER_DT AS DT FROM REAL_MES.FLEXMES.DBO.QC_IQC_ORDER A WITH (NOLOCK)          
                WHERE A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO          
            UNION ALL       
            SELECT TOP 1 A.QC_RESULT, A.SIL_DT AS DT FROM REAL_MES.FLEXMES.DBO.QC_PQC_ORDER A WITH (NOLOCK)          
                WHERE A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO         
            ) AA      
            ORDER BY AA.DT DESC),'')     
        END       
            
        IF @IN_QC = 'N'       
        BEGIN          
            SET @QC_VALUE = 'Y'         
            SET @QC_NAME = '미검사품'         
            SET @PASS_CHK = 'Y'         
        END          
        ELSE          
        BEGIN         
            IF @QC_VALUE = ''          
            BEGIN          
                SET @MSG_CD = '0060'
                SET @MSG_DETAIL = '결과 없음(미검사 LOT) - 검사데이터 확인 필요' + CHAR(10)
                + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD 

--                SELECT @MSG_CD, @MSG_DETAIL --MSG
                RETURN 1
            END          
            ELSE          
            BEGIN          
                SELECT @QC_NAME = A.SUB_NM, @PASS_CHK = ISNULL(A.TEMP_CD2,'N')         
                FROM BA_SUB_CD A WITH (NOLOCK) WHERE A.MAIN_CD = 'SAP08' AND A.SUB_CD = @QC_VALUE          
            END          
        END          
    END          
    ELSE          
    BEGIN          
        SET @QC_VALUE = 'Y'       
        SET @QC_NAME = '미검사 설정'         
        SET @PASS_CHK = 'Y'         
    END          

    SET @QC_VALUE = 'Y' 
    SET @PASS_CHK = 'Y'
--    SELECT @QC_VALUE, @QC_NAME, @PASS_CHK, @STOCK_QTY -- DCHK
    
    IF @PASS_CHK = 'N'
    BEGIN 
        SET @MSG_CD = '0060'
        SET @MSG_DETAIL = '검사 결과에 따른 투입이 불가능합니다. 확인하여 주십시오.' + CHAR(10) 
        + 'Lot No. : ' + @LOT_NO + ', Barcode : ' + @BARCODE + ', 품목코드 : ' + @ITEM_CD + CHAR(10)
        + '검사결과 : ' + @QC_NAME 

--        SELECT @MSG_CD, @MSG_DETAIL --MSG
        RETURN 1
    END 

    --1-4. 유효일 확인

    --SELECT @QC_VALUE 
    SET @DEV_CHK = 'Y'
    IF @QC_VALUE NOT IN ('Y', 'R','S') AND @DEV_CHK = 'N' -- 개발품 체크 추가   
    BEGIN     
            
        SET @SIL_DT = CONVERT(NVARCHAR(10), GETDATE(), 120)
        /*
        ISNULL((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)      
        WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION      
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD      
        AND A.PROC_CD = @PROC_cD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_sEQ ), CONVERT(NVARCHAR(10), GETDATE(), 120))     
        */                
        IF ISNULL((     
            SELECT TOP 1 A.ZEFLK FROM REAL_MES.FLEXMES.DBO.SAP_Z02MESF_D080 A WITH (NOLOCK)      
            WHERE A.MATNR = @ITEM_CD AND A.BEGDA <= @SIL_DT      
            ORDER BY A.BEGDA DESC     
        ),'') = 'X'     
        BEGIN      
            -- 유효일 확인을 하자      
            
            IF EXISTS(SELECT *FROM REAL_MES.FLEXMES.DBO.VIEW_VALID_DATE A WITH (NOLOCK)      
            WHERE A.MATNR = @ITEM_CD AND A.ZVLOT = @LOT_NO)     
            BEGIN      
            
                IF ISNULL((SELECT TOP 1 A.VFDAT FROM REAL_MES.FLEXMES.DBO.VIEW_VALID_DATE A WITH (NOLOCK)      
                WHERE A.MATNR = @ITEM_CD AND A.ZVLOT = @LOT_NO ORDER BY CHARG DESC), CONVERT(NVARCHAR(10), '1900-01-01', 120)) < @SIL_DT      
                BEGIN      
                    SET @MSG_CD = '0060'
                    SET @MSG_DETAIL = '유효일이 경과하였습니다. 투입할수 없습니다. 유효일을 확인하여 주십시오.' + CHAR(10)       
                    + '스캔한 내용 : ' + @LOT_NO + CHAR(10)      
                    + '투입일 : ' + @SIL_DT + CHAR(10)      
                    + '유효일 : ' + CONVERT(NVARCHAR(10), CAST((SELECT TOP 1 ISNULL(A.VFDAT, '') FROM REAL_MES.FLEXMES.DBO.VIEW_VALID_DATE A WITH (NOLOCK)      
                                    WHERE A.MATNR = @ITEM_CD AND A.ZVLOT = @LOT_NO ORDER BY CHARG DESC) AS DATETIME),120) + ' [1900-01-01 은 등록이 되지 않은 내역입니다.]'     

--                    SELECT @MSG_CD, @MSG_DETAIL --MSG     
            
                    RETURN 1
                END      
            
            END      
            ELSE      
            BEGIN      
                SET @MSG_CD = '0060'
                SET @MSG_DETAIL = '유효일자 정보가 없습니다. 관리자에게 문의하여 주십시오.' + CHAR(10)       
                + '스캔한 내용 : ' + @LOT_NO      

--                SELECT @MSG_CD, @MSG_DETAIL --MSG     
            
                RETURN 1
            END      
            
        END      
    END      

    --1-5. 예외처리 진행 : 특별한게 없다. 위에서 처리 다 했으므로...


    --2. 투입 처리
    --2-1. BATCH_CHK 에 따른 배정 투입부터 처리 진행

    IF @BATCH_CHK = 'Y' 
    BEGIN 

    --2-2. 현재 들어온 작업지시 및 LOT 가 순서에 맞는가 부터 확인한다.

        -- 현재 마지막 배치 : @REQ_NO 
        -- 현재 LOT 로 체크된 배치 : @NOW_REQ_NO 
        -- 이전에 이상한 배치 : @BE_REQ_NO
        -- 일단 이전 순서에 남은게 있는지 부터 확인

        SELECT TOP 1 @NOW_REQ_NO = A.REQ_NO, @NOW_BATCH_STR = RIGHT(A.REQ_DT, 2) + '-' + CAST(A.PLAN_SEQ AS NVARCHAR) FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_DT = @REQ_DT AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
        AND A.USE_FLG = 'Y' AND A.CHG_RSN = '' AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO 
        ORDER BY A.REQ_NO ASC 

        SELECT TOP 1 @BE_REQ_NO = A.REQ_NO, @BE_BATCH_STR = RIGHT(A.REQ_DT, 2) + '-' + CAST(A.PLAN_SEQ AS NVARCHAR) FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
        INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND B.REP_ITEM_CD = @REP_ITEM_CD 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_DT = @REQ_DT AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD
        AND A.USE_FLG = 'Y' AND A.CHG_RSN = '' 
        AND A.REQ_NO < @REQ_NO
        ORDER BY A.REQ_NO DESC 

        --SELECT @REQ_NO, @BATCH_STR, @REQ_SEQ, @PLAN_SEQ, @NOW_REQ_NO, @NOW_BATCH_STR, @BE_REQ_NO, @BE_BATCH_STR -- DCHK
        
        IF @BE_REQ_NO <> ''
        BEGIN 
    --2-3. 이전 미등록 배정 확인
            SET @MSG_CD = '0060' 
            SET @MSG_DETAIL = '이전 배정 내역이 있습니다. 확인하여 주십시오.' + CHAR(10) 
            + '현재 배정 : ' + @BATCH_STR + ', 이전 미등록 배정 : ' + @BE_BATCH_STR

--            SELECT @MSG_CD, @MSG_DETAIL --MSG

            RETURN 1
        END 

        IF @NOW_REQ_NO = '' 
        BEGIN 
            SET @MSG_CD = '0060' 
            SET @MSG_DETAIL = '해당 LOT 의 배정 내역이 없습니다. 확인하여 주십시오.' + CHAR(10) 
            + 'LOT NO : ' + @LOT_NO + ', Barcode : ' + @BARCODE + CHAR(10) 
           
--            SELECT @MSG_CD, @MSG_DETAIL --MSG
            RETURN 1
        END 

        IF @NOW_REQ_NO <> @REQ_NO 
        BEGIN 
    --2-4. 현재 lot 배정과 동일한 배정인지 확인  
            SET @MSG_CD = '0060' 
            SET @MSG_DETAIL = '스캔 내역과 현재 내역이 맞지 않습니다. 확인하여 주십시오.' + CHAR(10) 
            + '현재 배정 : ' + @BATCH_STR + ', 스캔 LOT 배정 : ' + @NOW_BATCH_STR

--            SELECT @MSG_CD, @MSG_DETAIL --MSG

            RETURN 1
        END 

    --2-5. 배정 수량이 동일한지 확인한다. 소분은 뒤에 다시 체크 한다. 
        --SELECT @STOCK_QTY, @REQ_QTY  -- DCHK

        IF @STOCK_QTY <> @REQ_QTY 
        BEGIN 
            SET @MSG_CD = '0060' 
            SET @MSG_DETAIL = '배정 수량과 현재 LOT 및 바코드의 재고 수량이 맞지 않습니다.' + CHAR(10) 
            + 'LOT NO : ' + @LOT_NO + ', Barcode : ' + @BARCODE + CHAR(10) 
            + '현재 배정 수량 : ' + CAST(@REQ_QTY AS NVARCHAR) + ', 재고 수량 : ' + CAST(@STOCK_QTY AS NVARCHAR)

--            SELECT @MSG_CD, @MSG_DETAIL --MSG
            RETURN 1
        END  

    END 
    ELSE 
    BEGIN 
        SET @REQ_qTY = @QTY 
    END 

    --2-6. 임시 테이블에 넣기전에 현재 작업이 진행중인지부터 먼저 체크를 하자.

    -- 기준 정보를 먼저 매칭
    SELECT @PROC_NO = A.PROC_NO, @ORDER_TYPE = A.ORDER_TYPE, @ORDER_FORM = A.ORDER_FORM, @ROUT_NO = A.ROUT_NO, @ROUT_VER = A.ROUT_VER
        FROM PD_ORDER A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 

    -- 재고정보를 매칭

    SELECT @USEM_WC = A.WC_CD, @USEM_PROC = A.PROC_CD, @USEM_LOCATION = A.LOCATION_NO, @RACK_CD = A.RACK_CD
        FROM REAL_MES.FLEXMES.DBO.ST_STOCK_NOW A WITH (NOLOCK)
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.BARCODE = @BARCODE 
        AND A.PROC_CD = '*' AND A.SL_CD = '3000' AND A.RACK_CD <> '*'

    -- 유효일 정보를 매칭

    SELECT @STANDARD_DATE = A.VFDAT FROM REAL_MES.FLEXMES.DBO.VIEW_VALID_DATE A WITH (NOLOCK) 
    WHERE A.MATNR = @ITEM_CD AND A.ZVLOT = @LOT_NO

    
--    SELECT @RESULT_SEQ, @TEMP_SEQ -- DCHK

    IF EXISTS(
    SELECT *FROM PD_RESULT A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDEr_NO AND A.REVISION = @REVISION 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ 
        AND A.S_CHK = 'N'
    )
    BEGIN 
        SET @MSG_CD = '0060' 
        SET @MSG_DETAIL = '이미 시작진행이 된 실적 번호입니다. 확인하여 주십시오.' + CHAR(10) 
        + '실적번호 : ' + CAST(@RESULT_SEQ AS NVARCHAR)

--        SELECT @MSG_CD, @MSG_DETAIL -- MSG
        
        RETURN 1
        
    END 

    --2-6. 임시 TEMP 에 넣는다.

    IF NOT EXISTS(SELECT *FROM PD_USEM_MAT_TEMP_MASTER A WITH (NOLOCK)
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
        AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_CD 
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.TEMP_SEQ = @TEMP_SEQ 
    )
    BEGIN 
        INSERT INTO PD_USEM_MAT_TEMP_MASTER 
        (
            DIV_CD,              PLANT_CD,              PROC_NO,                 ORDER_NO,                REVISION,          
            ORDER_TYPE,          ORDER_FORM,            ROUT_NO,                 ROUT_VER,                WC_CD,           
            LINE_CD,             PROC_CD,               USEM_EQP,
            RESULT_SEQ,          TEMP_SEQ,              START_YN,
            INSERT_ID,           INSERT_DT,             UPDATE_ID,               UPDATE_DT                
        )
        SELECT 
            @DIV_CD,             @PLANT_CD,             @PROC_NO,                @ORDER_NO,               @REVISION, 
            @ORDER_TYPE,         @ORDER_FORM,           @ROUT_NO,                @ROUT_VER,               @WC_CD, 
            @LINE_CD,            @PROC_CD,              @EQP_CD,
            @RESULT_SEQ,         @TEMP_SEQ,             'N',
            @USER_ID,            GETDATE(),             @USER_ID,                GETDATE()
    END 


    -- 중복 정보가 있는지를 체크한다.
    -- 첨가제는 한번만 등록?? 

    -- USEM_SEQ 를 매칭

    SET @USEM_SEQ = ISNULL((SELECT MAX(USEM_sEQ) FROM PD_USEM_MAT_TEMP A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO 
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER 
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.USEM_EQP = @EQP_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.TEMP_SEQ = @TEMP_SEQ 
    ),0) + 1

    INSERT INTO PD_USEM_MAT_TEMP
    (          
        DIV_CD,              PLANT_CD,              PROC_NO,                 ORDER_NO,                REVISION,          
        ORDER_TYPE,          ORDER_FORM,            ROUT_NO,                 ROUT_VER,                WC_CD,           
        LINE_CD,             PROC_CD,               USEM_EQP,                RESULT_SEQ,              TEMP_SEQ,
        USEM_SEQ,            USEM_WC,               USEM_PROC,               
        ITEM_CD,             SL_CD,                 LOCATION_NO,             RACK_CD,                 LOT_NO,         MASTER_LOT,          
        PLC_QTY,             USEM_QTY,              DEL_FLG,                 REWORK_FLG,              INSERT_ID,           
        INSERT_DT,           UPDATE_ID,             UPDATE_DT,               REQ_DT,                  REQ_NO,           
        REQ_SEQ,             PLAN_SEQ,              BATCH_NO,                ITEM_TYPE,               IN_GBN,         BARCODE,  
        STANDARD_DATE,       QC_RESULT      
    )          
    SELECT           
        @DIV_CD,              @PLANT_CD,             @PROC_NO,                @ORDER_NO,               @REVISION,           
        @ORDER_TYPE,          @ORDER_FORM,           @ROUT_NO,                @ROUT_VER,               @WC_CD,          
        @LINE_CD,             @PROC_CD,              @EQP_CD,                 @RESULT_SEQ,             @TEMP_SEQ,             
        @USEM_SEQ,            @USEM_WC,              @USEM_PROC,              
        @ITEM_CD,             '3000',                @USEM_LOCATION,          @RACK_CD,                @LOT_NO,        @LOT_NO,          
        @REQ_QTY,             @REQ_QTY,              'N',                     'N',                     @USER_ID,           
        GETDATE(),            @USER_ID,              GETDATE(),               @REQ_DT,                 @REQ_NO,           
        @REQ_SEQ,             @PLAN_SEQ,             @BATCH_NO,               @ITEM_TYPE,              @IN_GBN,        @BARCODE,  
        @STANDARD_DATE,       @QC_VALUE   

--    SELECT *FROM PD_USEM_MAT_TEMP_MASTER -- DCHK
--    SELECT *FROM PD_USEM_MAT_TEMP -- DCHK

-- 마지막 배정 내역이면 배정의 USE_FLG 에 S 로 업데이트를 해주자.

IF @BATCH_CHK = 'Y'
BEGIN 
    UPDATE A SET A.USE_FLG = 'S'
        FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.REQ_NO = @REQ_NO
END 

END TRY 
BEGIN CATCH
    SET @MSG_CD = '9999'
    SET @MSG_DETAIL = ERROR_MESSAGE()
    RETURN 1
END CATCH
--ROLLBACK 

