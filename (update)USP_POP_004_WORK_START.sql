/*  
기안번호 : PM250912007	  
기안구분 : 일반  
제목 : 실적 관련 모든 테이블 LOG 적재
일자 : 2025-09-17
작업자 : 임종원 이사  
*/      
   
   
ALTER PROC USP_POP_004_WORK_START(           
--BEGIN TRAN            
--DECLARE            
        @DIV_CD        NVARCHAR(10)     = '01'           
       ,@PLANT_CD      NVARCHAR(10)     = '1140'           
       ,@ORDER_NO      NVARCHAR(50)     = 'PD240219014'           
       ,@REVISION      INT              = 1           
       ,@PROC_NO       NVARCHAR(50)     = 'OPL2402190047'           
       ,@ORDER_TYPE    NVARCHAR(10)     = 'PP01'           
       ,@ORDER_FORM    NVARCHAR(10)     = '10'           
       ,@ROUT_NO       NVARCHAR(10)     = 'B01'           
       ,@ROUT_VER      INT              = '1'           
       ,@WC_CD         NVARCHAR(10)     = '14BC'           
       ,@LINE_CD       NVARCHAR(10)     = '14G07B'           
       ,@PROC_CD       NVARCHAR(10)     = 'MX' --RK, S, EU, ED, P           
           
       ,@ITEM_CD       NVARCHAR(50)     = 'H004CB002'           
       ,@SDATE         NVARCHAR(50)     = ''--CONVERT(NVARCHAR(20), GETDATE(), 120)           
       ,@EQP_CD        NVARCHAR(20)     = ''           
       ,@J_CHK         NVARCHAR(1)      = 'N'           
       ,@J_VAL         NVARCHAR(10)     = '%'     
       ,@CYCLE_SEQ     INT              = 1           
       ,@RK_DATE       NVARCHAR(10)     = ''          
       ,@GROUP_SPEC_CD NVARCHAR(10)     = ''   
       ,@USER_ID       NVARCHAR(15)     = 'ADMIN'           
       ,@MSG_CD        NVARCHAR(4)      OUTPUT            
       ,@MSG_DETAIL    NVARCHAR(MAX)    OUTPUT            
)           
AS           
-- 작업 시작 처리            
           
           
           
SET NOCOUNT ON            
           
           
BEGIN TRY           

    DECLARE @UDI_DATE      NVARCHAR(20)  = '' 
            ,@UDI_SP        NVARCHAR(100) = 'USP_POP_004_WORK_START' 
            ,@UDI_REMARK    NVARCHAR(100) = '작업시작' 

    -- 체크         
    IF EXISTS(         
    SELECT *FROM PD_ORDER A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION > @REVISION          
    )          
    BEGIN          
        SET @MSG_CD = '0060'         
        SET @MSG_DETAIL = '시작할수 없습니다. 현재 Revision 보다 상위 Revision 이 있습니다. 지시 조회에서 재확인 하여 주십시오.'         
        RETURN 1         
    END         
         
    IF @RK_DATE = '' BEGIN SET @RK_DATE = CONVERT(NVARCHAR(10), CAST(@SDATE AS DATETIME), 120) END           
          
    -- LOT CHK 하는 프로세스를 추가 해야 된다. 추후에...            
    -- 일단 시작 부터 먼저 친다.            
    DECLARE @RESULT_SEQ INT = 0            
           
    -- 이거 그룹번호로 가지고 가야 된다. 조질뻔..            
           
    -- 그룹 시작인가?           
    -- 그룹 사이에 있는가?           
    -- 그룹 종료인가? 에 따라서 @LOT 번호가 달라져야 된다.            
    -- SEQ 에 따라서, 앞의 해당 LOT 를 가지고 와서 처리 하도록 하자.            
      DECLARE @SKIP        NVARCHAR(1)  = 'N'           
           ,@IN_CHK      NVARCHAR(1)  = 'N'           
           ,@OUT_CHK     NVARCHAR(1)  = 'N'           
           ,@MIN_CHK     NVARCHAR(1)  = 'N'           
           ,@GROUP_S     NVARCHAR(1)  = 'N'           
           ,@GROUP       NVARCHAR(1)  = 'N'           
           ,@GROUP_E     NVARCHAR(1)  = 'N'           
           ,@QC_CHK      NVARCHAR(1)  = 'N'           
           ,@S_CHK       NVARCHAR(1)  = 'N'           
           ,@PROC_SEQ    INT          = 0            
           ,@GROUP_YN    NVARCHAR(1)  = 'N'           
           ,@LOT_NO      NVARCHAR(50) = '*'           
           ,@J_SEQ       INT          = 0            
           ,@AP_CHK      NVARCHAR(1)  = 'N' -- 후일지 작성 추가            
           
     DECLARE @STR_DATE NVARCHAR(8) = CONVERT(NVARCHAR(8), CAST(@SDATE AS DATETIME), 112)           
/*           
UPDATE A SET A.S_CHK = 'N'           
    FROM PD_ORDER_PROC A WITH (NOLOCK)            
WHERE A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION            
*/           
           
    SELECT @SKIP = A.SKIP, @IN_CHK = A.IN_CHK, @OUT_CHK = A.OUT_CHK, @MIN_CHK = A.MIN_CHK, @GROUP_S = A.GROUP_S, @GROUP =            
    dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),           
    @GROUP_E = A.GROUP_E, @QC_CHK = A.QC_CHK, @PROC_SEQ = A.PROC_SEQ, @S_CHK = ISNULL(A.S_CHK,'N')           
               
    , @AP_CHK = ISNULL(A.AP_CHK,'N') -- 후일지 작성 추가            
           
    FROM PD_ORDER_PROC A WITH (NOLOCK)            
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE           
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
           
    --SELECT @SKIP, @IN_CHK, @OUT_CHK, @MIN_CHK, @GROUP_S, @GROUP, @GROUP_E, @QC_CHK, @S_CHK            
           
           
    IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)            
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD --AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
      --AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER            
      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
      AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL             
    )           
    BEGIN            
        SET @MSG_CD = '9999'           
        SET @MSG_DETAIL = '이미 작업중인 실적이 있습니다. 재조회 후 확인하여 주십시오.'           
        RETURN 1           
    END            
       
    -- 채번 규칙           
    -- 그룹 시작           
    SET @RESULT_SEQ = ISNULL((SELECT MAX(A.RESULT_SEQ) FROM PD_RESULT A WITH (NOLOCK)            
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO  -- AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION            
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK),0) + 1           
           
--    SELECT @RESULT_SEQ           
                 
    -- 잔여등 체크가 필요하면?            
           
    IF @J_CHK <> 'N'            
    BEGIN            
        -- 최신 시퀀스를 가지고 온다.            
        SET @J_SEQ =            
            (ISNULL((SELECT MAX(A.J_SEQ) FROM PD_RESULT A WITH (NOLOCK)            
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.SIL_DT = CONVERT(NVARCHAR(10), GETDATE(), 120) AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
            AND A.J_CHK = @J_CHK           
            ),0) + 1)           
    END            
--    SELECT *FROM PD_RESULT WHERE PROC_CD = 'P'           
           
    IF @GROUP_S = 'Y'            
    BEGIN            
                   
        -- LOT 를 생성해야 된다. PR           
              
        EXEC USP_CM_AUTO_NUMBERING 'PR', @STR_DATE, @USER_ID, @LOT_NO OUT                 
                   
        IF @S_CHK = 'N'            
        BEGIN            
            SET @GROUP_YN = 'Y'            
        END            
    END            
           
           
    IF (@GROUP = 'Y' OR @GROUP_E = 'Y') AND @S_CHK = 'N' AND @IN_CHK = 'N'           
    BEGIN            
        -- 앞의 공정에 대한 실적 마지막 SEQ 를 가지고 와야 된다.            
        -- SKIP 이 아닌 공정을 찾아서...            
           
        -- 만약 앞에 공정의 S_CHK = 'Y' 라고 한다면..            
        -- 이건 그냥 채번 다시 해서, 앞에 실적도 같이 만들어준다. PD_ITEM_IN 까지 처리 한다.            
        -- 취소할때 이것도 같이 취소되어야 된다.            
                   
          DECLARE @BE_PROC_CD  NVARCHAR(10)            
                 ,@BE_ROUT_NO  NVARCHAR(10)            
                 ,@BE_ROUT_VER INT            
                 ,@BE_WC_CD    NVARCHAR(10)            
                 ,@BE_LINE_CD  NVARCHAR(10)            
                 ,@BE_ORDER_NO NVARCHAR(50)            
                 ,@BE_REVISION INT            
                 ,@BE_ITEM_CD  NVARCHAR(50)            
                  
        SELECT TOP 1 @BE_PROC_CD = A.PROC_CD, @BE_ROUT_NO = A.ROUT_NO, @BE_ROUT_VER = A.ROUT_VER, @BE_WC_CD = A.WC_CD,            
        @BE_LINE_CD = A.LINE_CD, @BE_ORDER_NO = A.ORDER_NO, @BE_REVISION = A.REVISION, @BE_ITEM_CD = B.ITEM_CD           
            FROM PD_ORDER_PROC A WITH (NOLOCK)            
            INNER JOIN PD_ORDER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD            
            AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM            
            AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD           
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE            
        AND A.ORDER_FORM = @ORDER_FORM --AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
        AND A.SKIP = 'N' AND A.IN_CHK = 'N' -- 그룹 중간에 투입이 있으면 별개로 가지고 가야 된다. PRE_bARE 소성 이후 BARE 투입 같은 경우...           
        AND CAST((REPLACE(A.ORDER_NO,'PD','') + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) AS BIGINT) < CAST((REPLACE(@ORDER_NO,'PD','') + CAST(@REVISION AS NVARCHAR) + CAST(@PROC_SEQ AS NVARCHAR)) AS BIGINT)         
        ORDER BY (A.ORDER_NO + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) DESC            
           
--        SELECT @BE_PROC_CD, @BE_ROUT_NO, @BE_ROUT_VER, @BE_WC_CD, @BE_LINE_CD           
           
                  
           
        IF ISNULL((SELECT A.S_CHK           
            FROM PD_ORDER_PROC A WITH (NOLOCK)            
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD            
            AND A.PROC_CD = @BE_PROC_CD            
         ),'N') = 'Y'            
                   
        BEGIN            
            -- 시퀀스를 어떻게 해야 될까? 이거 전에랑 안 맞는데...            
            -- PK 를 변경 했다. S_CHK, RESULT_SEQ 순으로            
            -- 이렇게 되면 앞에 채번후에 앞에 실적도 같이 넣어줘야 될것 같다.            
            -- 앞에 실적도 동일하게 따준다.           
           
            -- lot 를 따야 됩니다.           
       
            EXEC USP_CM_AUTO_NUMBERING 'PR', @STR_DATE, @USER_ID, @LOT_NO OUT                 
           
            SET @GROUP_YN = 'Y'           
           
            INSERT INTO PD_RESULT (           
            DIV_CD,                PLANT_CD,          PROC_NO,                ORDER_NO,                   REVISION,            
            ORDER_TYPE,            ORDER_FORM,                  ROUT_NO,                ROUT_VER,                   WC_CD,            
            LINE_CD,               PROC_CD,                     RESULT_SEQ,           
            ITEM_CD,               LOT_NO,                      LOT_SEQ,            
            RESULT_QTY,            BAD_QTY,                     EQP_CD,                 SDATE,                      EDATE,            
            SIL_DT,                DAY_FLG,                     J_CHK,                  J_SEQ,                      J_VAL,     
            INSERT_ID,             INSERT_DT,                   UPDATE_ID,              UPDATE_DT,                  ZMESIFNO,           
            GROUP_LOT,             GROUP_YN,                    S_CHK,          
            RK_DATE   
            )           
            SELECT            
            @DIV_CD,               @PLANT_CD,                   @PROC_NO,               @BE_ORDER_NO,               @BE_REVISION,            
            @ORDER_TYPE,           @ORDER_FORM,                 @BE_ROUT_NO,            @BE_ROUT_VER,               @BE_WC_CD,            
            @BE_LINE_CD,           @BE_PROC_CD,                 @RESULT_SEQ,           
            @BE_ITEM_CD,           @LOT_NO,           0,            
            0,                     0,                           '',                     @SDATE,                     GETDATE(),           
            dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'T'),           
            dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'D'),           
            @J_CHK,                @J_SEQ,                      @J_VAL,     
            @USER_ID,              GETDATE(),                   @USER_ID,               GETDATE(),                  '',           
            @LOT_NO,               @GROUP_YN,                   @S_CHK ,          
            @RK_DATE   
           
              
            -- 앞에 실적은 PD_ITEM_IN 까지 제공을 해야 되는 상황이다.           
            -- 앞에 실적은 PD_ITEM_IN 까지 제공을 해야 되는 상황이다.           
            -- 근데 이거 조건이 걸릴때 진행해야 된다.. 만약 현재가 그롭마지막이고 실적 등록이라면?           
            -- 이건 미리 작업을 해줘야 하므로           
                       
            IF (@OUT_CHK = 'Y' AND @GROUP_E = 'Y') OR (@AP_CHK = 'Y')           
            BEGIN            
                -- 계속 중복이 생겨서, 일부러 삭제 구문 좀 넣습니다. 진짜 짜증난다.            
                IF EXISTS(SELECT *FROM PD_ITEM_IN A WITH (NOLOCK)            
                 WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.PROC_NO = @PROC_NO            
                    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD            
                    AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
                )           
                BEGIN

                    SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120) 

                    INSERT INTO PD_ITEM_DEL_IN_HISTORY 
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-1', @USER_ID, A.*
                    FROM PD_ITEM_IN A WITH (NOLOCK)            
                     WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.PROC_NO = @PROC_NO            
                    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD            
                    AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
    
                    DELETE A           
                        FROM PD_ITEM_IN A WITH (NOLOCK)            
                     WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.PROC_NO = @PROC_NO            
                    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD            
                    AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
                END            
           
                INSERT INTO PD_ITEM_IN            
                (           
                    DIV_CD,           PLANT_CD,                    PROC_NO,                 ORDER_NO,                  REVISION,            
                    ORDER_TYPE,       ORDER_FORM,                  ROUT_NO,                 ROUT_VER,                  WC_CD,            
                    LINE_CD,          PROC_CD,             RESULT_SEQ,              SEQ,                       ITEM_CD,                   LOT_NO,            
                    SL_CD,            LOCATION_NO,                 RACK_CD,                 SIL_DT,                    GOOD_QTY,            
                    INSERT_ID,        INSERT_DT,                   UPDATE_ID,               UPDATE_DT,                 BARCODE           
           
                )           
                SELECT            
                 @DIV_CD,          @PLANT_CD,                   @PROC_NO,                @BE_ORDER_NO,              @BE_REVISION,            
                    @ORDER_TYPE,      @ORDER_FORM,                 @BE_ROUT_NO,             @BE_ROUT_VER,              @BE_WC_CD,            
                    @BE_LINE_CD,      @BE_PROC_CD,                 @RESULT_SEQ,             1,                         @BE_ITEM_CD,               @LOT_NO,            
                    '3000',           @BE_LINE_CD,                 '*',                     dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'T'), 0,           
                    @USER_ID,         GETDATE(),                   @USER_ID,                GETDATe(),                 '*'           
            END            
        END            
        ELSE            
        BEGIN           
           
            IF NOT EXISTS(SELECT            
                *FROM PD_RESULT A WITH (NOLOCK)            
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
              AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_YN = 'Y'           
             -- AND A.EDATE IS NOT NULL            
            )           
            BEGIN            
                SET @MSG_CD = '9999'           
                SET @MSG_DETAIL = '이전 실적이 없습니다. 확인하여 주십시오. '           
           --     SELECT @MSG_DETAIL            
               -- RETURN           
                RETURN 1           
            END            
        ELSE            
            BEGIN            
                SELECT            
                @LOT_NO = ISNULL(A.GROUP_LOT,'') FROM PD_RESULT A WITH (NOLOCK)            
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
              AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_YN = 'Y'           
            --  AND A.EDATE IS NOT NULL           
            END            
            IF @LOT_NO = ''            
            BEGIN            
                SET @MSG_CD = '9999'           
                SET @MSG_DETAIL = '이전 실적이 없습니다. 확인하여 주십시오. '           
               -- SELECT @MSG_DETAIL            
                RETURN 1           
            END            
            SET @GROUP_YN = 'Y'          
        END            
           
    END            
               
      IF (@OUT_CHK = 'Y' AND @GROUP_E = 'Y') OR @GROUP = 'Y'            
    BEGIN            
        -- 그룹시작의 설비를 가지고 온다.            
              
        SET @EQP_CD = ISNULL(( SELECT TOP 1 CASE WHEN ISNULL(A.EQP_CD,'') = '' THEN @EQP_CD ELSE A.EQP_CD END  FROM PD_RESULT A WITH (NOLOCK)            
        INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE            
        AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD            
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM            
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.GROUP_LOT = @LOT_NO           
        AND A.EQP_CD NOT IN ('','%')          
        ORDER BY B.PROC_SEQ ASC),@EQP_CD)            
          
          
    END            
           
              
           
    -- 계속 중복이 생겨서, 일부러 삭제 구문 좀 넣습니다. 진짜 짜증난다.            
    IF EXISTS(SELECT *FROM PD_ITEM_IN A WITH (NOLOCK)            
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO            
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
    AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
    )           
    BEGIN            
        DELETE A           
            FROM PD_ITEM_IN A WITH (NOLOCK)            
         WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ        
    END            
           
    IF @S_CHK = 'Y'        
    BEGIN        
       
        IF EXISTS(SELECT        
        *FROM PD_RESULT A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
        AND A.S_CHK = 'Y'        
        AND A.RK_DATE = @RK_DATE AND A.EQP_CD = @EQP_CD        
        )       
        BEGIN        
            SET @MSG_CD = '9999'       
            SET @MSG_DETAIL = '이미 등록된 일지 정보가 있습니다. 등록 시간 정보를 확인하여 주십시오.'       
            RETURN 1       
        END        
    END        
           
    INSERT INTO PD_RESULT (           
        DIV_CD,                PLANT_CD,                    PROC_NO,                ORDER_NO,                   REVISION,            
        ORDER_TYPE,            ORDER_FORM,                  ROUT_NO,                ROUT_VER,                   WC_CD,            
        LINE_CD,               PROC_CD,                     RESULT_SEQ,           
        ITEM_CD,               LOT_NO,                      LOT_SEQ,            
        RESULT_QTY,            BAD_QTY,                     EQP_CD,                 SDATE,                      EDATE,            
        SIL_DT,                DAY_FLG,                     J_CHK,                  J_SEQ,                      J_VAL,     
        INSERT_ID,             INSERT_DT,                   UPDATE_ID,              UPDATE_DT,                  ZMESIFNO,           
        GROUP_LOT,             GROUP_YN,                    S_CHK,          
        RK_DATE,               GROUP_SPEC_CD          
    )           
    SELECT            
        @DIV_CD,      @PLANT_CD,                   @PROC_NO,               @ORDER_NO,                  @REVISION,            
        @ORDER_TYPE,           @ORDER_FORM,                 @ROUT_NO,               @ROUT_VER,                  @WC_CD,            
        @LINE_CD,              @PROC_CD,                    @RESULT_SEQ,           
        @ITEM_CD,              @LOT_NO,                    0,            
        0,                     0,                           @EQP_CD,                @SDATE,                     NULL,           
        dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'T'),           
        dbo.UFNSR_GET_DAYNIGHT(CAST(@SDATE AS DATETIME),'D'),           
        @J_CHK,                @J_SEQ,                      @J_VAL,     
        @USER_ID,              GETDATE(),                   @USER_ID,               GETDATE(),                  '',           
        @LOT_NO,               @GROUP_YN,                   @S_CHK,          
        @RK_DATE,              @GROUP_SPEC_CD          
           
              
    -- @AP_CHK = 'Y' 이면 PD_ITEM_IN 까지 넣어준다.            
    IF @AP_CHK = 'Y'            
    BEGIN            
        INSERT INTO PD_ITEM_IN            
        (           
            DIV_CD,            PLANT_CD,               PROC_NO,                ORDER_NO,                 REVISION,            
            ORDER_TYPE,        ORDER_FORM,             ROUT_NO,                ROUT_VER,                 WC_CD,            
            LINE_CD,           PROC_CD,                S_CHK,                  RESULT_SEQ,               SEQ,            
            ITEM_CD,           LOT_NO,                 SL_CD,                  LOCATION_NO,                         
            RACK_CD,           BARCODE, SIL_DT,                 GOOD_QTY,            
            INSERT_ID,         INSERT_DT,              UPDATE_ID,              UPDATE_DT            
        )           
        SELECT            
            A.DIV_CD,          A.PLANT_CD,             A.PROC_NO,              A.ORDER_NO,               A.REVISION,            
            A.ORDER_TYPE,      A.ORDER_FORM,           A.ROUT_NO,              A.ROUT_VER,               A.WC_CD,            
            A.LINE_CD,         A.PROC_CD,              A.S_CHK,                A.RESULT_SEQ,             '1',            
            A.ITEM_CD,         A.LOT_NO,               '3000',                 A.LINE_CD,           
            '*',               '*',                    A.SIL_DT,               A.RESULT_QTY,            
            @USER_ID,          GETDATE(),              @USER_ID,               GETDATE()           
           
        FROM PD_RESULT A WITH (NOLOCK)            
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
           
           
    END            
 
    -- 25.02.26 LJW  
    -- 그룹 실적에 PD_USEM 이 있다면? 시작할때 전부 삭제 해줘야 되나?  
    -- 아.. 소분 투입이 있어서 애매하다..  
    -- 자기실적만 보자.  
    IF @S_CHK = 'N'  
    BEGIN  
 
        -- 히스토리를 집어 넣습니다. 
 
        /* 선언부 */  
 
 
 
        /* 할당 */  
 
        SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120) 
        INSERT INTO PD_USEM_DEL_HISTORY  
        SELECT @UDI_DATE, ROW_NUMBER() OVER (ORDER BY B.ORDER_NO, B.RESULT_SEQ, B.USEM_SEQ), @UDI_SP, @UDI_REMARK,@USER_ID, 
        B.* 
 
        FROM PD_RESULT A WITH (NOLOCK)  
        INNER JOIN PD_USEM B WITH (NOLOCK) ON  
        A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO  
        AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER  
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
    
 
        DELETE  
        B FROM PD_RESULT A WITH (NOLOCK)  
        INNER JOIN PD_USEM B WITH (NOLOCK) ON  
        A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO  
        AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER  
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ            
    END  
    -- 24.02.23 자...            
    -- 어떤것을 작업하느냐 바로.. AP_CHK = 'Y' 이면은 PD_ITEM_IN            
    -- PD_USEM 은 나중에 넣을꺼야. 일단 시작부터 하자.            
           
    -- 작업일지를 등록합니다.            
       
    -- 이게.. 설비코드가            
           
    DECLARE @EQP_TBL TABLE (           
		EQP_CD    NVARCHAR(30)            
	)           
           
	IF EXISTS(SELECT *FROM BA_EQP A WITH (NOLOCK)            
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD            
	)           
	BEGIN            
           
		INSERT INTO @EQP_TBL            
		SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD            
        UNION ALL            
        SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = ''            
           
	END            
	ELSE            
	BEGIN            
		IF @EQP_CD = '%' OR @EQP_CD = ''            
		BEGIN            
			IF EXISTS(SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
			WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.PROC_CD = @PROC_CD AND A.TP <> '' )           
			BEGIN            
				INSERT INTO @EQP_TBL            
				SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
				WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD --AND A.TP <> ''            
			END            
			ELSE            
			BEGIN            
				INSERT INTO @EQP_TBL            
				SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
				WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD --AND A.TP = ''            
			END            
			           
		END            
		ELSE            
		BEGIN            
            IF EXISTS(SELECT *FROM BA_EQP A WITH (NOLOCK)            
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
                AND A.EQP_CD = @EQP_CD            
            )           
            BEGIN            
    			INSERT INTO @EQP_TBL            
    			SELECT @EQP_CD            
            END            
            ELSE            
            BEGIN            
                INSERT INTO @EQP_TBL            
				SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
				WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
            END            
		END            
	END          
   
    -- GROUP_SPEC_CD 임시 테이블   
   
	DECLARE @GROUP_SPEC_TBL TABLE (   
		GROUP_SPEC_CD NVARCHAR(10)   
	)     
   
	IF @GROUP_SPEC_CD <> ''    
	BEGIN    
		INSERT INTO @GROUP_SPEC_TBL    
		SELECT @GROUP_SPEC_CD    
	END    
   
	INSERT INTO @GROUP_SPEC_TBL    
	SELECT ''    
	   
           
    IF NOT EXISTS(SELECT *FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)           
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
    AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @CYCLE_SEQ           
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
            @CYCLE_SEQ,         @USER_ID,          GETDATE(),          @USER_ID,            GETDATE()           
           
        INSERT INTO PD_RESULT_PROC_SPEC_VALUE (           
            DIV_CD,              PLANT_CD,             ORDER_NO,              REVISION,              ORDER_TYPE,             ORDER_FORM,            
            ROUT_NO,             ROUT_VER,             WC_CD,                 LINE_CD,               PROC_CD,                S_CHK,           RESULT_SEQ,            
            CYCLE_SEQ,           SEQ,                  SPEC_VERSION,          PROC_SPEC_CD,          EQP_CD,                 SPEC_VALUE_TYPE,            
            SPEC_VALUE,          REMARK,               INSERT_ID,             INSERT_DT,             UPDATE_ID,              UPDATE_DT,           
            IN_DATE,             IN_SEQ,               GROUP_SPEC_CD           
        )           
           
        SELECT A.DIV_CD,         A.PLANT_CD,           A.ORDER_NO,            A.REVISION,            A.ORDER_TYPE,           A.ORDER_FORM,            
            A.ROUT_NO,           A.ROUT_VER,           A.WC_CD,               A.LINE_CD,             A.PROC_CD,              @S_CHK,          @RESULT_SEQ,           
            @CYCLE_SEQ,          A.SEQ,                A.SPEC_VERSION,        A.PROC_SPEC_CD,        A.EQP_CD,               A.SPEC_VALUE_TYPE,            
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
          AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)           
          AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)   
          AND A.RECYCLE_NO IN (@CYCLE_SEQ, '')          
           
    END            
           
END TRY            
BEGIN CATCH            
--    SELECT ERROR_MESSAGE()            
  --  RETURN            
    SET @MSG_CD = '9999'           
    SET @MSG_DETAIL = ERROR_MESSAGE()            
    RETURN 1           
           
END CATCH 