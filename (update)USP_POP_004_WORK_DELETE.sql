/*  
기안번호 : PM250912007	  
기안구분 : 일반  
제목 : 실적 관련 모든 테이블 LOG 적재
일자 : 2025-09-17
작업자 : 임종원 이사  
*/    


ALTER  PROC USP_POP_004_WORK_DELETE(       
        @DIV_CD        NVARCHAR(10)       
       ,@PLANT_CD      NVARCHAR(10)        
       ,@ORDER_NO      NVARCHAR(50)        
       ,@REVISION      INT        
       ,@PROC_NO       NVARCHAR(50)        
       ,@ORDER_TYPE    NVARCHAR(10)        
       ,@ORDER_FORM    NVARCHAR(10)        
       ,@ROUT_NO       NVARCHAR(10)        
       ,@ROUT_VER      INT        
       ,@WC_CD         NVARCHAR(10)        
       ,@LINE_CD       NVARCHAR(10)        
       ,@PROC_CD       NVARCHAR(10)        
       ,@RESULT_SEQ    INT        
       ,@DEL_CHK       NVARCHAR(1) = 'Y'       
       ,@USER_ID       NVARCHAR(15)        
       ,@MSG_CD        NVARCHAR(4)      OUTPUT        
       ,@MSG_DETAIL    NVARCHAR(MAX)    OUTPUT        
)       
AS       
       
SET NOCOUNT ON        
       
BEGIN TRY        
    /* 선언부 */   
    DECLARE @UDI_DATE      NVARCHAR(20)  = ''  
           ,@UDI_SP        NVARCHAR(100) = 'USP_POP_004_WORK_DELETE'  
           ,@UDI_REMARK    NVARCHAR(100) = '작업취소'  
      
    IF @DEL_CHK = 'N'   
    BEGIN   
        SET @UDI_REMARK = 'FIFO 처리시 삭제'  
    END   
    
    DECLARE @SU_BATCH TABLE ( 
        CNT    INT IDENTITY(1,1) 
        ,REQ_NO NVARCHAR(50)  
 
    ) 
    DECLARE @GROUP_LOT   NVARCHAR(50) = ''        
       
    SELECT @GROUP_LOT = A.GROUP_LOT        
        FROM PD_RESULT A WITH (NOLOCK)        
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION        
      AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO        
      AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
      AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ       
       
    UPDATE B SET B.USE_QTY = 0, B.USE_FLG = 'Y'       
        FROM PD_USEM A WITH (NOLOCK)        
        INNER JOIN MT_ITEM_OUT_BATCH B WITH (NOLOCK)        
        ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD        
        AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO        
        AND A.REQ_DT = B.REQ_DT AND A.REQ_NO = B.REQ_NO AND A.REQ_SEQ = B.REQ_SEQ AND A.PLAN_SEQ = B.PLAN_SEQ AND A.BATCH_NO = B.BATCH_NO       
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
    AND A.RESULT_SEQ = @RESULT_SEQ        
        
    IF @DEL_CHK = 'Y'    
    BEGIN    
        INSERT INTO @SU_BATCH 
        SELECT A.REQ_NO         
          FROM PD_USEM A WITH (NOLOCK)       
            INNER JOIN MT_ITEM_OUT_BATCH_SU B WITH (NOLOCK)       
            ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD       
            AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO       
            AND A.REQ_DT = B.REQ_DT AND A.REQ_NO = B.REQ_NO AND A.REQ_SEQ = B.REQ_SEQ AND A.PLAN_SEQ = B.PLAN_SEQ AND A.BATCH_NO = B.BATCH_NO      
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
        AND A.RESULT_SEQ = @RESULT_SEQ       
 
        /* 
        UPDATE B SET B.USE_QTY = B.USE_QTY - A.USEM_QTY,     
        B.USE_FLG = CASE WHEN B.USE_QTY - A.USEM_QTY < B.REQ_QTY THEN 'Y' ELSE 'N' END,     
        B.BARCODE = CASE WHEN B.USE_QTY - A.USEM_QTY = 0 THEN '' ELSE B.BARCODE END      
            FROM PD_USEM A WITH (NOLOCK)       
            INNER JOIN MT_ITEM_OUT_BATCH_SU B WITH (NOLOCK)       
            ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD       
            AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO       
            AND A.REQ_DT = B.REQ_DT AND A.REQ_NO = B.REQ_NO AND A.REQ_SEQ = B.REQ_SEQ AND A.PLAN_SEQ = B.PLAN_SEQ AND A.BATCH_NO = B.BATCH_NO      
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
        AND A.RESULT_SEQ = @RESULT_SEQ       
 
 
        */ 
    END    
        /*       
        AND A.PROC_NO = B.PROC_NO        
        AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE        
        AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER        
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD        
        AND A.       
*/       
       
       
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
           ,@AP_CHK      NVARCHAR(1)  = 'N'       
       
       
/*       
UPDATE A SET A.S_CHK = 'N'       
    FROM PD_ORDER_PROC A WITH (NOLOCK)        
WHERE A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION        
*/       
    SELECT @SKIP = A.SKIP, @IN_CHK = A.IN_CHK, @OUT_CHK = A.OUT_CHK, @MIN_CHK = A.MIN_CHK, @GROUP_S = A.GROUP_S, @GROUP =        
    dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),       
    @GROUP_E = A.GROUP_E, @QC_CHK = A.QC_CHK, @PROC_SEQ = A.PROC_SEQ, @S_CHK = ISNULL(A.S_CHK,'N'), @AP_CHK = ISNULL(A.AP_CHK, 'N')        
    FROM PD_ORDER_PROC A WITH (NOLOCK)        
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
       
    DECLARE @BE_PROC_CD  NVARCHAR(10) = ''        
           ,@BE_ROUT_NO  NVARCHAR(10) = ''       
           ,@BE_ROUT_VER INT = 0       
           ,@BE_WC_CD    NVARCHAR(10) = ''       
           ,@BE_LINE_CD  NVARCHAR(10) = ''       
           ,@BE_ORDER_NO NVARCHAR(50) = ''       
           ,@BE_REVISION INT = 0       
       
    -- 그룹 시작 공정이고, 뒤에 GROUP_LOT 의 실적이 있으면? 취소 금지..       
           
    -- 만약 이전 공정이 있는 내역이라면?        
    -- 앞에 공정이 S_CHK = 'Y' 이다.        
    -- 이러면 같이 삭제를 해줘야 된다.        
    SELECT TOP 1 @BE_PROC_CD = A.PROC_CD, @BE_ROUT_NO = A.ROUT_NO, @BE_ROUT_VER = A.ROUT_VER, @BE_WC_CD = A.WC_CD, @BE_LINE_CD = A.LINE_CD, @BE_ORDER_NO = A.ORDER_NO,       
    @BE_REVISION = A.REVISION        
            FROM PD_ORDER_PROC A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM --AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD        
        AND A.SKIP = 'N' AND A.IN_CHK = 'N' -- 그룹 중간에 투입이 있으면 별개로 가지고 가야 된다. PRE_bARE 소성 이후 BARE 투입 같은 경우...       
        AND CAST((REPLACE(A.ORDER_NO,'PD','') + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) AS BIGINT) < CAST((REPLACE(@ORDER_NO,'PD','') + CAST(@REVISION AS NVARCHAR) + CAST(@PROC_SEQ AS NVARCHAR)) AS BIGINT)       
       ORDER BY (A.ORDER_NO + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) DESC        
       
       
    IF ISNULL((SELECT A.S_CHK       
        FROM PD_ORDER_PROC A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD        
        AND A.PROC_CD = @BE_PROC_CD        
     ),'N') = 'Y'        
    BEGIN        
       
        IF @AP_CHK = 'Y'       
        BEGIN        
            IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD        
            AND A.PROC_CD NOT IN (@PROC_CD, @BE_PROC_CD) AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT        
            )       
            BEGIN        
                SET @MSG_CD = '9999'       
                SET @MSG_DETAIL = '그룹시작 공정은 후공정 실적이 있을경우 삭제가 불가능합니다. 후공정의 순차적인 삭제를 진행해주십시오.'       
                RETURN 1       
            END        
        END        
              
        IF @S_CHK = 'N'     
        BEGIN      
  
            SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  
            INSERT INTO PD_USEM_DEL_HISTORY   
            SELECT @UDI_DATE, ROW_NUMBER() OVER (ORDER BY A.ORDER_NO, A.RESULT_SEQ, A.USEM_SEQ), @UDI_SP, @UDI_REMARK + '-1',@USER_ID,  
            A.*  
            FROM PD_USEM A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD        
            --and A.S_CHK = 'N'       
            -- 이거 나중에 필요하면 필드를 넣어야 될것 같다..       
            AND A.RESULT_SEQ = @RESULT_SEQ        
  
            DELETE A       
            FROM PD_USEM A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD        
            --and A.S_CHK = 'N'       
            -- 이거 나중에 필요하면 필드를 넣어야 될것 같다..       
            AND A.RESULT_SEQ = @RESULT_SEQ        
        -- PD_ITEM_IN 까지 없애 줘야 된다. OUT_CHK = 'Y' GROUP_E = 'Y'       
        END     
        IF (@OUT_CHK = 'Y' AND @GROUP_E = 'Y') OR (@AP_CHK = 'Y')       
        BEGIN        
            BEGIN        
                IF @DEL_CHK = 'Y'        
                BEGIN        

                    SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  

                    INSERT INTO PD_ITEM_IN_DEL_HISTORY 
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-1', @USER_ID, B.*
                        FROM PD_RESULT A WITH (NOLOCK)        
                        INNER JOIN PD_ITEM_IN B WITH (NOLOCK) ON        
                        A.DIV_CD = B.DIV_cD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE        
                        AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ        
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
                    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD                           
                    AND A.S_CHK = 'N'       
                    AND A.RESULT_SEQ = @RESULT_SEQ                    
                    AND B.SEQ = 1        

                    DELETE B       
                        FROM PD_RESULT A WITH (NOLOCK)        
                        INNER JOIN PD_ITEM_IN B WITH (NOLOCK) ON        
                        A.DIV_CD = B.DIV_cD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE        
                        AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ        
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
                    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD                           
                    AND A.S_CHK = 'N'       
                    AND A.RESULT_SEQ = @RESULT_SEQ                    
                    AND B.SEQ = 1        
            END        
            END        
        END        
       
        IF @DEL_CHK = 'Y' -- 취소가 아니고 재공만 삭제하는거면 N 으로 해서 삭제를 하면 안된다.       
        BEGIN        
            DELETE A       
            FROM PD_RESULT A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD AND A.PROC_CD = @BE_PROC_CD        
            AND A.S_CHK = 'N'       
            AND A.RESULT_SEQ = @RESULT_SEQ        
        END        
    END        
       
       
    IF @OUT_CHK = 'Y' AND @GROUP_E = 'Y'        
    BEGIN        
        -- 앞에 내역을 전부 삭제를 해줘야 된다... 다시 돌아가야 된다는 이야기..        
        -- 앞에 공정을 찾읍시다.       
       
       -- 소분 투입된 내역에 대한 정보에서 USE_CHK 를 'N' 으로 바꿔야 된다.       
              
       -- 작업지시와 상관없이 그룹 lot 및 PROC_NO 기준으로 처리가 되어야 된다.....        
              
       -- 수세로 들어간 부분은, 기존대로 작업지시를 매칭해서 처리 해야 된다.        
       
       -- 그냥 이거... 그룹 되어 있는 그룹 정보를 모두 좀 가지고 오자 이게 맞을것 같다.        
       -- 이테이블은 다른 쿼리에서도 동일하게 사용될 가능성이 있으니..        
       
        DECLARE @GROUP_PROC_TABLE AS TABLE        
        (       
        --     CNT      INT IDENTITY(1,1)       
             DIV_CD      NVARCHAR(10)        
            ,PLANT_CD    NVARCHAR(10)        
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
        )       
    
        INSERT INTO @GROUP_PROC_TABLE (       
            DIV_CD, PLANT_CD, ORDER_NO, REVISION, ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD, LINE_CD, PROC_CD, RESULT_SEQ       
        )       
  
        SELECT B.DIV_CD, B.PLANT_CD,        
        B.ORDER_NO, B.REVISION, B.ORDER_TYPE,  B.ORDER_FORM, B.ROUT_NO, B.ROUT_VER, B.WC_CD, B.LINE_CD, B.PROC_CD, B.RESULT_SEQ       
        FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN PD_RESULT B WITH (NOLOCK) ON        
            A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO        
            AND A.GROUP_LOT = B.GROUP_LOT AND B.S_CHK = 'N'        
            INNER JOIN PD_ORDER_PROC C WITH (NOLOCK) ON        
            B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION        
            AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER        
            AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD        
          AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
          AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND        
          A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.GROUP_LOT = @GROUP_LOT       
        GROUP BY B.DIV_CD, B.PLANT_CD, B.ORDER_NO, B.REVISION, B.ORDER_TYPE, B.ORDER_FORM, B.ROUT_NO, B.ROUT_VER, B.WC_CD, B.LINE_CD, B.PROC_CD,   
        B.RESULT_SEQ, C.GROUP_SEQ  
        ORDER BY C.GROUP_SEQ        
               
--        SELECT @DIV_CD, @PLANT_CD, @ORDER_NO, @LINE_CD, @PROC_CD, @RESULT_SEQ       
       
        UPDATE B SET B.USE_CHK = 'N'       
        FROM @GROUP_PROC_TABLE A        
  INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO        
            AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER       
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD  AND A.RESULT_SEQ = B.RESULT_SEQ AND B.ITEM_TYPE = 'SU'       
       
       
        --        INSERT INTO @PROC_RESULT_TBL ( PROC_CD, RESULT_SEQ, GROUP_LOT )       
       
        -- GROUP 실적을 0 으로 돌리는 부분은 작업지시가 엮이면 안된다.        
       
        UPDATE A SET A.LOT_NO = @GROUP_LOT, A.RESULT_QTY = 0, A.GOOD_QTY = 0       
            FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN @GROUP_PROC_TABLE B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO        
        AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER       
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD  AND A.RESULT_SEQ = B.RESULT_SEQ --AND B.ITEM_TYPE = 'SU'       
  
        SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  
        INSERT INTO PD_USEM_DEL_HISTORY   
        SELECT @UDI_DATE, ROW_NUMBER() OVER (ORDER BY B.ORDER_NO, B.RESULT_SEQ, B.USEM_SEQ), @UDI_SP, @UDI_REMARK + '-2',@USER_ID,  
        B.*  
            FROM @GROUP_PROC_TABLE A       
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO        
            AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER       
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD  AND A.RESULT_SEQ = B.RESULT_SEQ AND B.ITEM_TYPE <> 'SU' AND B.USEM_PROC <> '*'       
       
      --  SELECT *FROM @GROUP_PROC_TABLE   
       
        DELETE B       
            FROM @GROUP_PROC_TABLE A       
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO        
            AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER       
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD  AND A.RESULT_SEQ = B.RESULT_SEQ AND B.ITEM_TYPE <> 'SU' AND B.USEM_PROC <> '*'       
       
        UPDATE B SET B.LOT_NO = @GROUP_LOT, B.GOOD_QTY = 0        
            FROM @GROUP_PROC_TABLE A       
            INNER JOIN PD_ITEM_IN B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO        
            AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER       
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.SEQ = 1        
               
              
    END        
       
    -- 제일 마지막에 현재 내역을 삭제 해줘야 된다.        
    -- 시작이고, AP_CHK = 'Y' 일때 뒤에 다른 실적이 있으면 체크한다.       
    IF @GROUP_S = 'Y' AND @AP_CHK = 'Y'       
    BEGIN        
        IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD        
        AND A.PROC_CD NOT IN (@PROC_CD, @BE_PROC_CD) AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT        
        )       
        BEGIN        
            SET @MSG_CD = '9999'       
            SET @MSG_DETAIL = '그룹시작 공정은 후공정 실적이 있을경우 삭제가 불가능합니다. 후공정의 순차적인 삭제를 진행해주십시오.'       
            RETURN 1       
        END        
    END        
          
          
      
    IF @DEL_CHK = 'Y'       
    BEGIN       
        IF @S_CHK = 'N'     
        BEGIN      
  
            SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  
            INSERT INTO PD_USEM_DEL_HISTORY   
            SELECT @UDI_DATE, ROW_NUMBER() OVER (ORDER BY B.ORDER_NO, B.RESULT_SEQ, B.USEM_SEQ), @UDI_SP, @UDI_REMARK + '-3',@USER_ID,  
            B.*  
            FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION        
            AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER        
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  --AND B.IN_GBN <> CASE WHEN @DEL_CHK = 'Y' THEN '' ELSE 'G' END       
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
            AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK    
  
            DELETE B       
            FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION        
            AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER        
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  --AND B.IN_GBN <> CASE WHEN @DEL_CHK = 'Y' THEN '' ELSE 'G' END       
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
            AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK    
        END      
    END       
    ELSE       
    BEGIN       
        IF @S_CHK = 'N'     
        BEGIN      
            SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  
            INSERT INTO PD_USEM_DEL_HISTORY   
            SELECT @UDI_DATE, ROW_NUMBER() OVER (ORDER BY B.ORDER_NO, B.RESULT_SEQ, B.USEM_SEQ), @UDI_SP, @UDI_REMARK + '-4',@USER_ID,  
            B.*  
            FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION        
            AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER        
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  AND ISNULL(B.IN_GBN,'') NOT IN ('E')      
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
            AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK AND B.ITEM_TYPE <> 'SU'           
     
            DELETE B       
            FROM PD_RESULT A WITH (NOLOCK)        
            INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION        
            AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER        
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.RESULT_SEQ = B.RESULT_SEQ  AND ISNULL(B.IN_GBN,'') NOT IN ('E')      
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
            AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK AND B.ITEM_TYPE <> 'SU'           
        END      
    END       
      
    IF @DEL_CHK = 'Y'       
    BEGIN        
        DELETE A       
        FROM PD_RESULT A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
        AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK        
       
        -- 일지도 같이 삭제 한다       
        -- 히스토리 삭제       
        DELETE B 
            FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)        
            INNER JOIN PD_RESULT_PROC_SPEC_VALUE_HIS B WITH (NOLOCK) ON        
            A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD        
            AND A.IN_DATE = B.IN_DATE AND A.IN_SEQ = B.IN_SEQ AND A.ORDER_NO = B.ORDEr_NO AND A.REVISION = B.REVISION AND A.RESULT_SEQ = B.RESULT_SEQ        
            AND A.CYCLE_SEQ = B.CYCLE_SEQ       
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
        AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK        
            
        -- 그리고 원천 일지 삭제        
               
        DELETE A 
        FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)        
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE        
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD        
        AND A.RESULT_SEQ = @RESULT_SEQ AND A.S_CHK = @S_CHK        
       
        IF @AP_CHK = 'Y'        
        BEGIN        
            IF (SELECT A.GOOD_QTY FROM PD_ITEM_IN A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND        
            A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND        
            A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ        
                   
            ) > 0        
            BEGIN        
                   
                SET @MSG_CD = '9999'       
                SET @MSG_DETAIL = '이미 후공정 실적이 등록 되었습니다. 취소할수 없습니다. 순차적인 취소가 필요합니다.'       
                RETURN 1       
            END        

            SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  
          
            INSERT INTO PD_ITEM_IN_DEL_HISTORY 
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-1', @USER_ID, A.*
                FROM PD_ITEM_IN A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND        
            A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND        
            A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ        

            DELETE A        
                FROM PD_ITEM_IN A WITH (NOLOCK)        
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND        
            A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND        
            A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ        
        END        
    END        
 
    IF @DEL_CHK = 'Y' 
    BEGIN  
        UPDATE A SET A.USE_QTY = A.REQ_QTY - B.QTY FROM MT_ITEM_OUT_BATCH_SU A WITH (NOLOCK) 
        INNER JOIN ST_STOCK_NOW B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO AND A.BARCODE = B.BARCODE 
        AND B.SL_CD = '3000' AND B.PROC_CD = '*' 
        WHERE A.REQ_NO IN (SELECT REQ_NO FROM @SU_BATCH) 
 
        UPDATE A SET A.USE_FLG = CASE WHEN A.USE_QTY = A.REQ_QTY THEN 'N' ELSE 'Y' END, 
        A.BARCODE = CASE WHEN A.USE_QTY = 0 THEN '' ELSE A.BARCODE END  
        FROM MT_ITEM_OUT_BATCH_SU A WITH (NOLOCK) 
        WHERE A.REQ_NO IN (SELECT REQ_NO FROM @SU_BATCH) 
 
    END  
END TRY        
BEGIN CATCH        
    SET @MSG_CD = '9999'       
    set @MSG_DETAIL = ERROR_MESSAGE()        
    RETURN 1       
END CATCH  