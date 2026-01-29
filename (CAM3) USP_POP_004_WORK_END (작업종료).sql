 
/* 
기안번호 : PM251114002 
기안구분 : 일반 
제목 : 주기샘플 프로그램 추가 등 
일자 : 2025-11-17 
작업자 : 정유영 차장 
*/ 
 
 
CREATE PROC [dbo].[USP_POP_004_WORK_END] (                             
    @DIV_CD          NVARCHAR(10)   = '01'                             
   ,@PLANT_CD        NVARCHAR(10)   = '1140'                             
   ,@PROC_NO         NVARCHAR(50)   = 'OPL2312180005'                             
   ,@ORDER_NO        NVARCHAR(50)   = 'PD231212003'                             
   ,@REVISION        INT            = '2'                             
   ,@ORDER_TYPE      NVARCHAR(10)   = 'PP01'                             
   ,@ORDER_FORM      NVARCHAR(10)   = '10'                             
   ,@ROUT_NO         NVARCHAR(10)   = 'C01'                             
   ,@ROUT_VER        INT            = '1'                             
   ,@WC_CD           NVARCHAR(10)   = '14GC'                             
   ,@LINE_CD         NVARCHAR(10)   = '14G05C'                             
   ,@PROC_CD         NVARCHAR(10)   = 'RI'                             
   ,@S_CHK           NVARCHAR(1)    = ''                             
   ,@RESULT_SEQ      INT            = 1                             
   ,@ITEM_CD         NVARCHAR(10)   = 'F004C005'                             
   ,@LOT_NO          NVARCHAR(50)   = 'G2311-TBC-TYB-WP-3189'                              
   ,@QTY             NUMERIC(18,4)  = 0                              
   ,@EDATE           DATETIME       = NULL                             
   ,@USER_ID         NVARCHAR(15)   = 'admin'                             
   ,@MSG_CD          NVARCHAR(4)        OUTPUT                              
   ,@MSG_DETAIL      NVARCHAR(MAX)      OUTPUT                              
)                             
AS                             
                             
--SELECT *FROM PD_RESULT                              
BEGIN TRY                              
                        
                        
                        
    -- 만약... S_CHK = 'Y' 이면?                              
    -- 건너뛰고 그냥 EDATE 만 없데이트 진행                              
                             
/*                             
UPDATE A SET A.S_CHK = 'N'                             
    FROM PD_ORDER_PROC A WITH (NOLOCK)                              
WHERE A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
*/                             
                        
                        
                        
                             
    IF NOT EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)                             
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                             
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                             
    AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.EDATE IS NULL                             
    )                            
    BEGIN                             
        SET @MSG_CD = '9999'                            
        SET @MSG_DETAIL = '현재 진행중인 작업 실적이 없습니다. 재조회 해서 현 상태를 확인하여 주십시오.'                            
        RETURN 1                            
    END                             
                       
                            
     DECLARE @SKIP        NVARCHAR(1)  = 'N'                             
           ,@IN_CHK      NVARCHAR(1)  = 'N'                             
           ,@OUT_CHK     NVARCHAR(1)  = 'N'                             
           ,@MIN_CHK     NVARCHAR(1)  = 'N'                             
           ,@GROUP_S     NVARCHAR(1)  = 'N'                             
           ,@GROUP       NVARCHAR(1)  = 'N'                             
           ,@GROUP_E     NVARCHAR(1)  = 'N'                             
           ,@QC_CHK      NVARCHAR(1)  = 'N'                             
           ,@PROC_SEQ    INT          = 0                              
           ,@GROUP_YN    NVARCHAR(1)  = 'N'              
           ,@PLC_QTY     NUMERIC(18,3) = 0       
           ,@AP_CHK      NVARCHAR(1)   = 'N'                              
           ,@SIL_DT      NVARCHAR(10) = ''                            
           ,@NS_CHK      NVARCHAR(1)  = 'N' -- 순번 미생성 항목                    
           ,@ADD_CHK     NVARCHAR(1)  = 'N'             
                             
    SET @SIL_DT = ISNULL((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)                       
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                             
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                             
    AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ), CONVERT(NVARCHAR(10),GETDATE(),120))                            
/*                             
UPDATE A SET A.S_CHK = 'N'                             
    FROM PD_ORDER_PROC A WITH (NOLOCK)                              
WHERE A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
*/           
    SELECT @SKIP = A.SKIP, @IN_CHK = A.IN_CHK, @OUT_CHK = A.OUT_CHK, @MIN_CHK = A.MIN_CHK, @GROUP_S = A.GROUP_S, @GROUP =                              
    dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),                             
    @GROUP_E = A.GROUP_E, @QC_CHK = A.QC_CHK, @PROC_SEQ = A.PROC_SEQ, @S_CHK = A.S_CHK, @AP_CHK = ISNULL(A.AP_CHK, 'N'), @NS_CHK = ISNULL(A.NS_CHK,'N')                    
    , @ADD_CHK = ISNULL(A.ADD_CHK, 'N')            
    FROM PD_ORDER_PROC A WITH (NOLOCK)                              
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                              
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                              
      
    -- 25.03.12 LJW 실적이고 투입이 아니면?       
    -- 같은 LOT 가 있으면 튕겨 내자.       
      
    IF @OUT_CHK = 'Y' AND @S_CHK = 'N' AND @IN_CHK = 'N' AND @ORDER_TYPE <> 'PP04'      
    BEGIN       
        IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)       
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD       
          AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ <> @RESULT_SEQ       
          AND A.LOT_NO = @LOT_NO      
        )      
        BEGIN       
            SET @MSG_CD = '9999'      
            SET @MSG_DETAIL = '해당 실적 공정에 중복 LOT 가 있습니다. 채번 및 중복 실적 확인이 필요합니다. Lot no : ' + @LOT_NO      
            RETURN 1      
        END       
    END       
      
    -- 투입된 내용이 하나도 없으면?                              
    -- 튕겨 내자. 완료 못한다.                          
                               
      
    IF @IN_CHK = 'Y' OR @OUT_CHK = 'Y'                              
    BEGIN                              
        IF NOT EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)                              
        INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
        AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                              
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                              
                             
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                              
        A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                              
        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                              
        )                             
        BEGIN          
            SET @MSG_CD = '9999'                             
            SET @MSG_DETAIL = '투입 재공 정보가 없습니다. 완료 할수 없습니다. 확인하여 주십시오.'                             
            RETURN 1                             
        END                              
                            
        -- 투입 정보와 일치하는게 있는가를 확인한다. 일지 정보에서 품종을 모두다 가지고 와서 해당 품종이 다 들어가 있나를 확인한다.                             
                            
        IF @OUT_CHK = 'Y'                             
        BEGIN                             
                            
            DECLARE @USEM_ITEM_GROUP TABLE                             
            (                            
                 CNT            INT IDENTITY(1,1)                             
                ,REP_ITEM_CD    NVARCHAR(50)                             
            )                            
                            
            INSERT INTO @USEM_ITEM_GROUP (REP_ITEM_CD)                            
            SELECT A.USEM_ITEM_GROUP                            
             FROM PD_ORDER_PROC_SPEC A  
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDEr_NO AND A.REVISION = @REVISION                             
              AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                             
              AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                             
              AND A.USEM_ITEM_GROUP <> ''                            
            GROUP BY A.USEM_ITEM_GROUP                            
                                        
            IF EXISTS(                    
            SELECT AA.REP_ITEM_CD                            
                FROM @USEM_ITEM_GROUP AA                            
                LEFT JOIN (                            
                SELECT C.REP_ITEM_CD FROM PD_RESULT A WITH (NOLOCK)                              
                INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
                AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                              
             AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                          
                INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD                             
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                              
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                              
                AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                          GROUP BY C.REP_ITEM_CD                            
                ) BB ON AA.REP_ITEM_CD = BB.REP_ITEM_CD                             
            WHERE BB.REP_ITEM_CD IS NULL                             
            )                             
            BEGIN                            
                DECLARE @EM_ITEM NVARCHAR(50)                             
                                 
                SET @EM_ITEM =   
                (                            
                   SELECT STRING_AGG(AA.REP_ITEM_CD,', ')                           
                    FROM @USEM_ITEM_GROUP AA                            
                    LEFT JOIN (                            
                    SELECT C.REP_ITEM_CD FROM PD_RESULT A WITH (NOLOCK)                              
                    INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
                    AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                    
                    AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                              
                    INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD                             
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                              
                    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                              
                    AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ               
                    GROUP BY C.REP_ITEM_CD                            
                    ) BB ON AA.REP_ITEM_CD = BB.REP_ITEM_CD                             
          WHERE BB.REP_ITEM_CD IS NULL                             
                )                            
                            
                            
               SET @MSG_CD = '9999'                            
                SET @MSG_DETAIL = '재공 투입 기준을 충족하지 않습니다. 투입 기준 리스트를 확인하여 주십시오.' + CHAR(10)                             
                + '대표품목 : ' + @EM_ITEM                            
                                            
                RETURN 1                             
            END                  
                   
            -- 1공장 PRE-BARE , 혼합에서 투입 품목이 PD_ORDER_USEM 에 있고 해당 품목이 없으면?                    
            -- 튕겨 낸다.  이거 FIXED 이므로 나중에 다시 재조정 할것...                    
                   
            IF @PLANT_CD = '1130' AND @WC_CD = '13GA' AND @PROC_CD = 'MX'                   
            BEGIN                    
                                   
                IF EXISTS(sELECT *FROM PD_ORDER_USEM A WITH (NOLOCK)                  
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                    
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                    
                AND A.PROC_CD = @PROC_CD                    
                 )                   
                BEGIN                    
                    DECLARE @USEM_ITEM_CD NVARCHAR(50) = ''                    
                   
                    SELECT @USEM_ITEM_CD =                    
                    A.ITEM_CD FROM PD_ORDER_USEM A WITH (NOLOCK)                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                    
                    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                    
                    AND A.PROC_CD = @PROC_CD                    
                   
                   
                    IF NOT EXISTS(                   
                        SELECT SUM(B.USEM_QTY) AS QTY FROM PD_RESULT A WITH (NOLOCK)         
                        INNER JOIN PD_USEM B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                       
                        AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                    
                        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                 
                        AND B.ITEM_CD = @USEM_ITEM_CD                    
                        INNER JOIN V_ITEM C WITH (NOLOCK) ON A.PLANT_CD = C.PLANT_CD AND B.ITEM_CD = C.ITEM_CD                             
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                      
                        A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                              
                        AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                              
                        HAVING SUM(B.USEM_QTY) > 0                   
                    )                   
                    BEGIN                    
                        SET @MSG_CD = '9999'                   
                        SET @MSG_DETAIL = '추가 투입을 진행하지 않았습니다. 종료할수 없습니다.' + CHAR(10)                    
                        + @USEM_ITEM_CD                    
                        RETURN 1                   
                    END                    
                END                    
                   
            END                      
                            
        END                             
                            
    END                              
                             
                             
    IF @EDATE IS NULL BEGIN SET @EDATE = GETDATE() END                              
                           
         
    IF @S_CHK = 'Y'                             
    BEGIN                              
        UPDATE A SET A.EDATE = CAST(@EDATE AS DATETIME), UPDATE_ID = @USER_ID, UPDATE_DT = GETDATE()                             
            FROM PD_RESULT A  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                                     
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK           
        AND A.RESULT_SEQ = @RESULT_SEQ                             
                             
    END                              
    ELSE                              
    BEGIN                              
    -- LOT 가 나왔으니                              
        -- PD_RESULT 를 조정 하고                              
                             
                             
        -- 수량 이거 나중에 없애야 됩니다. PLC 나 공정일지에서 등록할때 그 수량이 RESULT에 UPDATE 되면 됩니다.                              
        -- 지금은 테스트를 위해서 어쩔수 없이 진행 합니다.                             
                                     
        SET @QTY = ISNULL((SELECT SUM(A.USEM_QTY) FROM PD_USEM A WITH (NOLOCK)                              
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
        ),0)                             
                      
        -- PLC 데이터를 가지고 와서 넣어준다                             
                             
        SET @PLC_QTY = ISNULL((SELECT SUM(A.PLC_QTY) FROM PD_USEM A WITH (NOLOCK)                              
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                  
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
        ),0)                             
         
/*         
        IF @PLC_QTY = 0          
        BEGIN          
            SET @MSG_CD = '9999'         
            SET @MSG_DETAIL = '실중량이 0 으로 수집됩니다. 관리자에게 문의하여 주십시오.'         
            RETURN 1         
        END          
*/         
        -- 소분만 있으면,  수량을 일단 0 으로 처리 한다. 그룹안에 들어가있어야 되고..                             
        -- 왜???? 대채 왜???                             
 /*                            
        IF @GROUP = 'Y' AND @MIN_CHK = 'Y'                              
        BEGIN                              
            SET @QTY = 0                              
        END                              
 */                            
 
-- [SP PART 2/6]                       
        -- 체킹을 했을때 투입이면 자기 품목,                              
        -- 그게 아니면 그냥 ORDER 품목으로 가지고 가야 된다.                              
                                     
        IF @IN_CHK = 'Y' AND @OUT_CHK = 'N'                             
        BEGIN                              
                             
            SELECT @ITEM_CD = A.ITEM_CD FROM                              
            PD_USEM A WITH (NOLOCK)                              
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
                             
        END           
         
        IF @GROUP = 'Y' AND @IN_CHK  = 'N'                        
        BEGIN                 
        -- LOT 가 맞지 않으면?                        
        -- 튕겨 냅시다.                        
            IF (SELECT A.LOT_NO                         
                FROM PD_RESULT A WITH (NOLOCK)                    
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD                        
                  AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                         
                  AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                         
                  AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_sEQ) <> @LOT_NO                         
            BEGIN                         
                SET @MSG_CD = '9999'                        
                SET @MSG_DETAIL = '실적 LOT 매칭이 되지 않았습니다. 재조회후 LOT 확인 및 완료를 다시 진행하여 주십시오.'                        
                SET @MSG_DETAIL = @MSG_DETAIL + CHAR(10) + '등록 LOT : ' + @LOT_NO                         
                RETURN 1                         
                        
            END                         
        END                         
                 
        -- LOT 가 변경 되었는지 체크하기 위한 변수          
        -- 24.10.14 LJW         
        DECLARE @BE_EDIT_LOT_NO NVARCHAR(100) = ''          
         
        SELECT @BE_EDIT_LOT_NO = A.LOT_NO FROM PD_RESULT A WITH (NOLOCK)          
        WHERE A.DIV_cD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE          
          AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ         
                 
        ---------------------------------------         
         
                 
        UPDATE A SET A.RESULT_QTY = @QTY, A.GOOD_QTY = @QTY, A.EDATE = CAST(@EDATE AS DATETIME), A.LOT_NO = @LOT_NO, A.UPDATE_ID = @USER_ID,                        
        A.UPDATE_DT = GETDATE()                              
            FROM PD_RESULT A  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                           
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                             
       
       
        -- 그룹의 마지막 공정이면                              
        -- proc_cd = '*' 로 가지고 가야 된다.                              
                             
        -- 일단 FIXED                              
                             
      -- 포장이면, 일지 정보를 확인해서 루프돌아서 쪼개서 수불 발생시킨다.                              
        -- 그 조건은, 일지의 특정 항목을 바라보고 수량을 체크 해야 된다.                    
        -- 어떤 조건이냐... 포장 수량을 건드리는 항목이 먼지 파악을 하자.                              
                             
        IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' AND @PLANT_CD <> '1150'
        BEGIN                 


            -- 그룹 공정일때          
            -- 내부내역의 LOT 가 바뀌었을 경우          
            -- 그룹 공정내 PD_USEM, RESULT, ITEM_IN 까지 모두 UPDATE 를 해줘야 된다.         
            -- 24.10.14 LJW          
            -- LOT 변경 여부가 맞는지 부터 체크 한다.          
                                               
--        SELECT @BE_WC_CD, @BE_PROC_CD, @BE_SEQ                
            IF @BE_EDIT_LOT_NO <> @LOT_NO AND @GROUP_E = 'Y'         
            BEGIN          
                         
                DECLARE          
                 @SIL_PROC_INFO NVARCHAR(100) = ''                                    
                ,@CNT          INT = 0                                    
                ,@SIL_PROC_CD   NVARCHAR(10) = ''         
                ,@SIL_WC_CD     NVARCHAR(10) = ''                                   
                ,@SIL_SEQ       INT = 0                                   
                    
                SELECT @SIL_PROC_INFO = dbo.UFNR_GET_GROUP(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD, 'Y')                                  
         
                                            
                WHILE CHARINDEX('/', @SIL_PROC_INFO) <> 0                                    
                BEGIN                                    
                    SET @CNT = @CNT + 1                                   
          
                    IF @CNT = 1                                   
                    BEGIN                                    
                        SET @SIL_WC_CD = ISNULL(SUBSTRING(@SIL_PROC_INFO,0,CHARINDEX('/',@SIL_PROC_INFO)),'')                                    
                    END                                 
                                                       
                    IF @CNT = 2                                   
                    BEGIN                                    
                        SET @SIL_PROC_CD = ISNULL(SUBSTRING(@SIL_PROC_INFO,0,CHARINDEX('/',@SIL_PROC_INFO)),'')                                    
                        SET @SIL_SEQ =  ISNULL(SUBSTRING(@SIL_PROC_INFO,CHARINDEX('/',@SIL_PROC_INFO) + 1, LEN(@SIL_PROC_INFO)),0)                                   
                                           
                    END                                    
                                           
                    SET @SIL_PROC_INFO = SUBSTRING(@SIL_PROC_INFO,CHARINDEX('/',@SIL_PROC_INFO) + 1, LEN(@SIL_PROC_INFO))                                   
                                           
                END                                    
                 
                   -- PD_ITEM_IN UPDATE          
                UPDATE C SET C.LOT_NO = @LOT_NO          
             --   SELECT C.*         
                FROM PD_RESULT A  
                    INNER JOIN PD_RESULT B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD          
                    AND A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE          
                    AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_cD AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT          
                    AND B.PROC_CD <> @PROC_CD AND B.LOT_NO = @BE_EDIT_LOT_NO         
                    LEFT JOIN PD_ITEM_IN C ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION        
                    AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_fORM = C.ORDER_FORM AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD          
                    AND B.RESULT_SEQ = C.RESULT_sEQ          
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
                  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_cD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_cD AND A.S_CHK = @S_CHK          
                  AND A.RESULT_SEQ = @RESULT_SEQ          
         
         
                -- PD_USEM UPDATE          
         
                UPDATE C SET C.LOT_NO = @LOT_NO          
                --SELECT C.*         
                    FROM PD_RESULT A  
                    INNER JOIN PD_RESULT B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD          
                    AND A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE          
                    AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_cD AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT          
                    AND B.PROC_CD <> @SIL_PROC_CD AND B.LOT_NO IN (@BE_EDIT_LOT_NO, @LOT_NO)         
                    INNER JOIN PD_USEM C ON B.DIV_CD = C.DIV_cD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION          
                    AND B.PROC_NO = C.PROC_NO AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM          
                    AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD AND B.RESULT_SEQ = C.RESULT_SEQ          
                    AND C.LOT_NO = @BE_EDIT_LOT_NO          
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
                  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_cD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_cD AND A.S_CHK = @S_CHK          
                  AND A.RESULT_SEQ = @RESULT_SEQ          
         
                -- PD_RESULT UPDATE          
--                UPDATE A SET A.LOT_NO = @LOT_NO          
                UPDATE B SET B.LOT_NO = @LOT_NO          
                    FROM PD_RESULT A  
                    INNER JOIN PD_RESULT B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD          
                    AND A.PROC_NO = B.PROC_NO AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE          
                    AND A.ORDER_FORM = B.ORDER_FORM AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_cD AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT          
                    AND B.PROC_CD <> @PROC_CD AND B.LOT_NO = @BE_EDIT_LOT_NO         
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
                  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.WC_CD = @WC_cD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_cD AND A.S_CHK = @S_CHK          
                  AND A.RESULT_SEQ = @RESULT_SEQ          
         
                  
            END                       
                     
            IF EXISTS(                             
                SELECT                              
                *FROM PD_RESULT_PROC_SPEC_VALUE A  
                INNER JOIN PD_ORDER_PROC_SPEC B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
                AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                              
                AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.PROC_SPEC_CD = B.PROC_SPEC_CD AND  ISNULL(B.USEM_ITEM_GROUP,'') <> ''                             
                INNER JOIN BA_SUB_CD C ON A.PROC_SPEC_CD = C.SUB_CD AND C.MAIN_CD = 'P2001' AND C.TEMP_CD5 = 'R'                             
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                              
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                              
                AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND ISNULL(A.SPEC_VALUE,'') <> ''                              
            )                             
            BEGIN                              
                                             
                DECLARE @PACK_TABLE TABLE (                             
                     CNT            INT    IDENTITY(1,1)                             
                    ,CYCLE_SEQ      INT                               
                    ,QTY            NUMERIC(18,3)                              
                )                             
                             
                INSERT INTO @PACK_TABLE (CYCLE_SEQ, QTY)                             
                SELECT A.CYCLE_SEQ, A.SPEC_VALUE                              
                FROM PD_RESULT_PROC_SPEC_VALUE A  
                INNER JOIN PD_ORDER_PROC_SPEC B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
                AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                              
             AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.PROC_SPEC_CD = B.PROC_SPEC_CD AND  ISNULL(B.USEM_ITEM_GROUP,'') <> ''                             
               INNER JOIN BA_SUB_CD C ON A.PROC_SPEC_CD = C.SUB_CD AND C.MAIN_CD = 'P2001' AND C.TEMP_CD5= 'R'                             
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                              
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                              
                AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.SPEC_VALUE <> ''                             
                ORDER BY A.CYCLE_SEQ                
                               
                DECLARE @P_CNT    INT = 0                              
                       ,@P_TCNT   INT = 0                              
                             
                SELECT @P_TCNT = COUNT(*) FROM @PACK_TABLE                              
                         
                WHILE @P_CNT <> @P_TCNT                              
                BEGIN                              
                    SET @P_CNT = @P_CNT + 1                             
                    DECLARE @CYCLE_SEQ INT = 0                             
                           ,@CYCLE_QTY NUMERIC(18,3) = 0                              
                             
                    SELECT @CYCLE_SEQ = @P_CNT --A.CYCLE_SEQ               
                    , @CYCLE_QTY = A.QTY FROM @PACK_TABLE A WHERE A.CNT = @P_CNT                              
         
         
          -- 바코드를 생성해줍니다.                              
                    DECLARE                              
                           @B_QTY2      INT                             
                         , @P_SEQ       INT            =   1                             
                         , @BARCODE     NVARCHAR(20)                             
                         , @PALLET_SEQ  INT                                           
                         , @BAR_DT      NVARCHAR(6)                             
                         , @MAX_DT      NVARCHAR(6)                             
                         , @MTART       NVARCHAR(4)                             
                         , @TOTALCNT    INT            =   1                             
                         , @FUB_CNT     INT            =   1                 
                         , @USER_CNT    INT            =   1                             
                         , @MOVE_TYPE   NVARCHAR(10)   =   '109'                             
           
                   ---자재유형 가져옴                             
             --      SELECT @MTART = MTART FROM SAP_Z02MESF_D010 (NOLOCK) WHERE WERKS = @PLANT_CD AND  MATNR = @ITEM_CD                             
  /*                           
                   ---오늘 날짜 가져옴                             
                   SET @BAR_DT = CONVERT(NVARCHAR(6),GETDATE(),12)                             
                             
            --- 바코드 정보에서 최근의 날짜 가져옴.                             
                    SELECT @MAX_DT = ISNULL(MAX(BAR_DT), CONVERT(NVARCHAR(6),GETDATE(),12)) FROM PALLET_MASTER (NOLOCK)                             
                                                   
                   --- 시퀀스 초기화                              
                   IF (@BAR_DT <> @MAX_DT)                           
                   BEGIN                             
                      ALTER SEQUENCE BAR_SEQ                             
                      RESTART WITH 1                             
                      INCREMENT BY 1                             
                      MINVALUE 1                             
                      MAXVALUE 9999                             
                      NO CYCLE                             
                      CACHE 1                             
                   END                             
*/           
--                   WHILE @FUB_CNT > 0                             
  --                 BEGIN                             
            --   BEGIN TRY                             
                         -- 바코드 순번 가져옴                             
                         -- SELECT @PALLET_SEQ = NEXT VALUE FOR BAR_SEQ                             
                         -- SELECT @PALLET_SEQ = 1                             
                             
                   ---바코드정보 가져옴                             
--                         SET @BARCODE = 'M' + @MTART + '-' + @BAR_DT + '-' + FORMAT(@PALLET_SEQ, '0000')                             
                    DECLARE @VAL INT      
     
                    EXEC @VAL = XM_BAR_LOT_CREATE_NEW @DIV_CD, @PLANT_CD, 'P', @ITEM_CD, @SIL_DT, @LINE_CD, @USER_ID, @MTART OUT, @BARCODE OUT, @PALLET_SEQ OUT          
                    IF @VAL = -1      
                    BEGIN      
                        SET @MSG_CD = '9999'     
                        SET @MSG_DETAIL = '바코드 채번 발생시 오류가 발생했습니다. 관리자에게 문의하여 주십시오.'     
                        RETURN 1     
                    END      
     
                    IF @BARCODE = ''          
                    BEGIN          
                        SET @MSG_CD = '9999'         
                        SET @MSG_DETAIL = '바코드 생성이 되지 않았습니다. 관리자에게 문의하여 주십시오.'         
                        RETURN 1         
                    END          
                     --SET @BAG_SIZE = CASE WHEN @FUB_CNT > 1 THEN @BAG_SIZE ELSE @B_QTY2 END                             
                --    SELECT @BARCODE         
                    IF EXISTS(	SELECT BARCODE          
						FROM PALLET_MASTER          
						WHERE BARCODE = @BARCODE)          
    				BEGIN          
    					SET @MSG_CD = '9999'                            
    					SET @MSG_DETAIL = '중복된 바코드가 있습니다.' + @BARCODE                
    					RETURN 1	          
    				END          
--                         SELECT  @BARCODE                             
                    INSERT INTO PALLET_MASTER (                             
                     PLANT,         BARCODE,         BAR_SEQ,      ITEM_CD,   LOT_NO,         BAG_SIZE,          REG_NUM,                              
                     MOVE_TYPE,      BAR_DT,         INSERT_ID,      INSERT_DT,      UPDATE_ID,      UPDATE_DT,         
                     DIV_CD,         LOT_GBN,        ITEM_TYPE,      DT,             SEQ          
                     --TEMP_CD1,      TEMP_CD2,      TEMP_CD3,      CON_NO,                    
                                                 
                    )                             
                    VALUES (                             
                     @PLANT_CD,      @BARCODE,      @CYCLE_SEQ,         @ITEM_CD,      @LOT_NO,      @CYCLE_QTY,         @USER_CNT,                              
                     @MOVE_TYPE,     CONVERT(NVARCHAR(6), CAST(@SIL_DT AS DATETIME), 12),  @USER_ID,      GETDATE(),          @USER_ID,      GETDATE(),                           
                     @DIV_CD,        'P',            @MTART,         @SIL_DT,        @PALLET_SEQ          
                     --@ZDEDN,         @NSEQ,         @TOTALCNT,      @ZCOTNO,                             
                                                 
                    )                             
                         
    --                    SET @P_SEQ = @P_SEQ + 1                             
      --                  SET @FUB_CNT = @FUB_CNT - 1                             
                             
        --            END                             
               
                    IF NOT EXISTS(               
                        SELECT *FROM PALLET_MASTER A WITH (NOLOCK)                
                        WHERE A.PLANT = @PLANT_CD AND A.BARCODE = @BARCODE AND A.BAR_SEQ = @CYCLE_SEQ AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO                
                    )               
                    BEGIN                
                        SET @MSG_CD = '9999'                            
                        SET @MSG_DETAIL = '바코드 번호 생성 누락입니다. 관리자에게 문의하여 주십시오.' + @BARCODE                
                        RETURN 1                            
                    END                
                    -- 이후 수불 정보에 넣어줍니다.  -- 라인정보를 확인합니다.                             
-- [SP PART 3/6]                            
                    DECLARE @RACK_CD NVARCHAR(50) = ''                            
                            
                    SELECT @RACK_CD = ISNULL(A.RACK_CD, '')                            
                    FROM BA_LINE A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
                   
                    IF @RACK_CD = ''                             
                    BEGIN                             
                        SET @MSG_CD = '9999'                            
                        SET @MSG_DETAIL = '라인 정보에 Rack 정보가 지정되지 않았습니다. 관리자에게 문의 하여 주십시오. Line : ' + @LINE_CD                             
                        RETURN 1                
                    END                             
                            
                    INSERT INTO PD_ITEM_IN                              
                    (                        
                        DIV_CD,              PLANT_CD,           PROC_NO,                ORDER_NO,                    REVISION,                 ORDER_TYPE,                                     
                        ORDER_FORM,          ROUT_NO,                  ROUT_VER,               WC_CD,                       LINE_CD,                  PROC_CD,                              
                       S_CHK,                              
                        RESULT_SEQ, SEQ,      ITEM_CD,                  LOT_NO,                    SL_CD,                       LOCATION_NO,              RACK_CD,                              
                        SIL_DT,                                           
                        GOOD_QTY,            INSERT_ID,                INSERT_DT,              UPDATE_ID,                   UPDATE_DT,                BARCODE                            
        
                            
                    )                             
                    SELECT                              
                        @DIV_CD,             @PLANT_CD,                @PROC_NO,               @ORDER_NO,                   @REVISION,                @ORDER_TYPE,                              
                        @ORDER_FORM,         @ROUT_NO,    @ROUT_VER,              @WC_CD,                      @LINE_CD,                                              
                        CASE WHEN dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' THEN '*' ELSE @PROC_CD END,-- CASE WHEN @PROC_CD = 'PA' THEN '*' ELSE @PROC_CD END ,                              
                        @S_CHK,                              
                        @RESULT_SEQ,         @CYCLE_SEQ,               @ITEM_CD,               @LOT_NO,   '3000',                      @LINE_CD,                 @RACK_CD,                              
                        @SIL_DT,                                      
                        @CYCLE_QTY,            @USER_ID,                 GETDATE(),              @USER_ID,                    GETDATE(),                @BARCODE                            
                            
         
                    -- 해당 LOT 의 배정정보가 있는가?                            
                    -- 마지막 순서를 찾는다.                             
                            
                    IF @WC_CD IN ('13GD','14GD')         
                    BEGIN                             
                        IF @P_TCNT = @P_CNT                             
                        BEGIN                             
                            IF EXISTS(SELECT *FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK)                             
                            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO                             
                              AND ISNULL(A.CHG_RSN,'') = '' AND A.REQ_QTY = 0 AND A.USE_FLG = 'Y' AND ISNULL(A.ORDER_NO,'') <> ''                             
             )                            
                            BEGIN                           
         
                                     
                                -- SAP INTERFACE 도 수량을 업데이트 해야 된다.       
                                UPDATE B SET B.ZREGQ = A.REQ_QTY                      
                                     FROM MT_ITEM_OUT_BATCH A    
                                    INNER JOIN SAP_Z02MESF_P020 B ON A.PLANT_CD = B.WERKS AND A.ZMESIFNO = B.ZMESIFNO                      
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO                             
                                  AND ISNULL(A.CHG_RSN,'') = '' AND A.REQ_QTY = 0 AND A.USE_FLG = 'Y' AND ISNULL(A.ORDER_NO,'') <> ''                          
                       
                                UPDATE A SET A.REQ_QTY = @CYCLE_QTY, A.UPDATE_ID = @USER_ID, A.UPDATE_DT = GETDATE()                             
                                    FROM MT_ITEM_OUT_BATCH A    
                                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO                             
                                  AND ISNULL(A.CHG_RSN,'') = '' AND A.REQ_QTY = 0 AND A.USE_FLG = 'Y' AND ISNULL(A.ORDER_NO,'') <> ''                             
                     
                            END                             
                        END                             
                    END             
                END                              
                             
            END                              
            ELSE                              
            BEGIN                              
                SET @MSG_CD = '9999'                             
                SET @MSG_DETAIL = '포장 등록을 진행할수 없습니다. 일지에 검증중량(재고) 항목의 수량이 등록되어 있는지 확인하여 주십시오.'                             
                --SELECT @MSG_DETAIL                              
                RETURN 1                            
            END                           
        END                              
                            
        ELSE                              
        BEGIN                 
                     
            IF @AP_CHK = 'N'                              
            BEGIN               
                INSERT INTO PD_ITEM_IN                              
                (                             
                    DIV_CD,              PLANT_CD,          PROC_NO,                ORDER_NO,                    REVISION,                 ORDER_TYPE,                                     
                    ORDER_FORM,          ROUT_NO,           ROUT_VER,               WC_CD,               LINE_CD,                  PROC_CD,                              
                   S_CHK,                              
                    RESULT_SEQ,          SEQ,               ITEM_CD,                LOT_NO,                    SL_CD,                       LOCATION_NO,              RACK_CD,                              
                    SIL_DT,                                           
                    GOOD_QTY,            INSERT_ID,         INSERT_DT,              UPDATE_ID,                   UPDATE_DT,                BARCODE                             
                )                             
                SELECT                              
                    @DIV_CD,             @PLANT_CD,                @PROC_NO,               @ORDER_NO,                   @REVISION,                @ORDER_TYPE,                              
                    @ORDER_FORM,         @ROUT_NO,                 @ROUT_VER,              @WC_CD,                      @LINE_CD,                              
                    CASE WHEN dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' THEN '*' ELSE @PROC_CD END,-- CASE WHEN @PROC_CD = 'PA' THEN '*' ELSE @PROC_CD END ,                              
                    @S_CHK,                              
                    @RESULT_SEQ,         '1',                      @ITEM_CD,               @LOT_NO,                     '3000',       @LINE_CD,                 '*',                              
                    @SIL_DT,                
                    @PLC_QTY,            @USER_ID,                 GETDATE(),              @USER_ID,                    GETDATE(),                ISNULL(@BARCODE,'*')                             
            END           
            /*         
            ELSE          
            BEGIN         
                -- 24.10.30 LJW 재처리, 즉 입고 실적인데 후일지 공정으로 지정되었을때.. PD_ITEM_IN 이 처리가 되지 않는다..         
         
                --SET @OUT_CHK = 'Y'          
                IF @IN_CHK = 'Y' AND @OUT_CHK = 'Y'          
           BEGIN      
                    IF EXISTS(SELECT *FROM PD_ITEM_IN A WITH (NOLOCK)          
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
                      AND A.ORDER_FORM = @ORDER_FORM AND A.ORDER_TYPE = @ORDER_TYPE AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD          
                      AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.GOOD_QTY = 0          
                    )         
                    BEGIN          
                        UPDATE A SET A.GOOD_QTY = @PLC_QTY, A.LOT_NO = @LOT_NO         
                     FROM PD_ITEM_IN A WITH (NOLOCK)          
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
                        AND A.ORDER_FORM = @ORDER_FORM AND A.ORDER_TYPE = @ORDER_TYPE AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD          
                        AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.GOOD_QTY = 0          
                    END          
                END          
            END         
            */                   
        END              
       
       
               
        -- 그룹의 끝일때       
        -- 앞에 공정의 재공과 현 실적과 다르다면        
        -- 메시지를 표기하고, 튕겨내도록 한다.       
        -- 25.02.26 LJW 임시작업이지만, 원인이 해결된다해도 해당 문구는 그대로 놔두는게 맞을것 같다.       
        -- 매번 그룹공정의 마지막 재고량은 맞는데, 앞 공정의 재공이 계속 뒤틀린다. 확인차 넣음.       
       
        -- 1.5 배로 지정함       
       
        IF @OUT_CHK = 'Y' AND @GROUP_E = 'Y' --AND @ORDER_NO <> 'PD250819001'    
        BEGIN        
            IF EXISTS(SELECT AA.PROC_CD, AA.GOOD_QTY, AA.STOCK_QTY, AA.PLC_QTY, AA.USEM_QTY       
                        FROM (        
                          SELECT B.PROC_CD, B.GOOD_QTY,        
                          (SELECT SUM(AA.GOOD_QTY)        
                          FROM PD_ITEM_IN AA WITH (NOLOCK)        
                          WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.ORDER_NO = B.ORDER_NO AND AA.REVISION = B.REVISION AND AA.PROC_NO = B.PROC_NO        
                            AND AA.ORDER_TYPE = B.ORDER_TYPE AND AA.ORDER_FORM = B.ORDER_FORM AND AA.ROUT_NO = B.ROUT_NO AND AA.ROUT_VER = B.ROUT_VER AND AA.WC_CD = B.WC_CD AND AA.LINE_CD = B.LINE_CD        
                            AND AA.PROC_CD = CASE WHEN dbo.FN_GET_LAST_PROC(B.DIV_CD, B.PLANT_CD, B.ORDER_NO, B.REVISION, B.PROC_CD) = 'Y' THEN '*' ELSE B.PROC_CD END       
                            AND AA.RESULT_SEQ = B.RESULT_SEQ        
                          ) AS STOCK_QTY,        
                          (SELECT SUM(AA.PLC_QTY)       
                          FROM PD_USEM AA WITH (NOLOCK)        
                          WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.ORDER_NO = B.ORDER_NO AND AA.REVISION = B.REVISION AND AA.PROC_NO = B.PROC_NO        
                            AND AA.ORDER_TYPE = B.ORDER_TYPE AND AA.ORDER_FORM = B.ORDER_FORM AND AA.ROUT_NO = B.ROUT_NO AND AA.ROUT_VER = B.ROUT_VER AND AA.WC_CD = B.WC_CD AND AA.LINE_CD = B.LINE_CD        
                            AND AA.PROC_CD = B.PROC_CD AND AA.RESULT_SEQ = B.RESULT_SEQ       
                          ) AS PLC_QTY,        
                          (SELECT SUM(AA.USEM_QTY)       
                         FROM PD_USEM AA WITH (NOLOCK)        
                          WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.ORDER_NO = B.ORDER_NO AND AA.REVISION = B.REVISION AND AA.PROC_NO = B.PROC_NO        
                       AND AA.ORDER_TYPE = B.ORDER_TYPE AND AA.ORDER_FORM = B.ORDER_FORM AND AA.ROUT_NO = B.ROUT_NO AND AA.ROUT_VER = B.ROUT_VER AND AA.WC_CD = B.WC_CD AND AA.LINE_CD = B.LINE_CD        
                            AND AA.PROC_CD = B.PROC_CD AND AA.RESULT_SEQ = B.RESULT_SEQ       
                          ) AS USEM_QTY       
                          FROM PD_RESULT A WITH (NOLOCK)        
                          INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD                                    
                              AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM                                    
                              AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                                   
                              AND A.GROUP_LOT = B.GROUP_LOT                      
                          INNER JOIN PD_ORDER_PROC C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO                                    
                            AND B.REVISION = C.REVISION AND B.PROC_NO = C.PROC_NO AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM                                    
                            AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD                                    
                            AND C.IN_CHK = 'N' AND C.SKIP = 'N'                                  
       
                          WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO                                   
                            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                                    
                            AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                                    
                          --ORDER BY C.PROC_SEQ        
                        ) AA        
                        WHERE AA.STOCK_QTY * 1.5 < AA.GOOD_QTY OR AA.STOCK_QTY * 1.5 < AA.PLC_QTY OR AA.STOCK_QTY * 1.5 < AA.USEM_QTY        
            )       
            BEGIN        
                SET @MSG_CD = '9999'       
                SET @MSG_DETAIL = '그룹공정의 재공 처리와 마지막 공정 재고와 1.5배 이상 상이합니다. 관리자 문의후 공정 처리 점검이 필요합니다.'       
                RETURN 1       
            END        
        END        
               
       
       
                             
        IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y'                              
        BEGIN                          
            -- 검사 요청에 넣는다.                             
                                    
            IF @S_CHK = 'N'                          
            BEGIN                           
                                  
                IF NOT EXISTS(SELECT *FROM PD_ITEM_IN A WITH (NOLOCK)                           
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                           
                  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                         
                  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = '*' AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ                           
                )                          
                BEGIN                           
                    SET @MSG_CD = '9999'                          
                    SET @MSG_DETAIL = '작업 종료 수불이 발생하지 않았습니다. 관리자에게 문의 하여 주십시오.' + char(10) + 'LOT NO : ' + @LOT_NO                           
                    RETURN 1                          
                END                          
            END                           
                                     
            IF NOT EXISTS(SELECT *FROM QC_PQC_ORDER A WITH (NOLOCK)                              
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER         
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                             
            )                             
            BEGIN                              
                DECLARE @SUM_QTY NUMERIC(18,3) = 0                  
                                  
                SELECT @SUM_QTY = ISNULL((SELECT SUM(A.GOOD_QTY)                   
                FROM PD_ITEM_IN A WITH (NOLOCK)                   
                 WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
               AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = '*' AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                             
                                  
                ),0)                  
                
                INSERT INTO QC_PQC_ORDER                       
                (                             
                    DIV_CD,            PLANT_CD,           ORDER_NO,   REVISION,             PROC_NO,          ORDER_TYPE,                              
                    ORDER_FORM,        ROUT_NO,            ROUT_VER,           WC_CD,                LINE_CD,                              
                    PROC_CD,           S_CHK,              RESULT_SEQ,            ITEM_CD,              LOT_NO,                              
                    LOT_SEQ,           QC_RESULT,          INSERT_ID,             INSERT_DT,            UPDATE_ID,                              
                    UPDATE_DT,         SIL_DT,          GOOD_QTY                   
                )                             
                SELECT                              
                    A.DIV_CD,          A.PLANT_CD,         A.ORDER_NO,            A.REVISION,           A.PROC_NO,        A.ORDER_TYPE,                              
                    A.ORDER_FORM,      A.ROUT_NO,          A.ROUT_VER,            A.WC_CD,              A.LINE_CD,                              
                    A.PROC_CD,         A.S_CHK,            A.RESULT_SEQ,          A.ITEM_CD,            A.LOT_NO,                              
                    A.LOT_SEQ,         '',     @USER_ID,              GETDATE(),            @USER_ID,                              
                    GETDATE(),         A.SIL_DT,           @SUM_QTY                   
                FROM PD_RESULT A  
                 WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                             
            END                          
         
            -- 유효일 관리를 위해서 계산후 추가 작업을 진행한다.         
            -- 24.12.11 LJW          
            -- 유효일 체크 여부가 맞는지를 체크한다.          
         
            IF ISNULL((         
                SELECT TOP 1 A.ZEFLK FROM SAP_Z02MESF_D080 A WITH (NOLOCK)          
                WHERE A.MATNR = @ITEM_CD AND A.DTYPE = 'GRD' AND A.BEGDA <= @SIL_DT          
                ORDER BY A.BEGDA DESC         
            ),'') = 'X'         
            BEGIN          
                IF EXISTS(SELECT *FROM SAP_Z02MESF_D080 A WITH (NOLOCK)          
                WHERE A.MATNR = @ITEM_CD AND A.ZDELF <> 'X' AND A.DTYPE = 'GRD'         
                )         
                BEGIN          
         
                    DECLARE @VFDAT NVARCHAR(10) = ''         
                           ,@BEGDA NVARCHAR(10) = ''         
                           ,@LONGD NVARCHAR(10) = ''         
                           ,@EFFED NVARCHAR(10) = ''         
                           ,@EXTED NVARCHAR(10) = ''         
                           ,@ZQMLK NVARCHAR(10) = ''         
                           ,@ZEFLK NVARCHAR(10) = ''          
         
                    --SET @VFDAT = ISNULL((         
                    SELECT TOP 1          
                         @VFDAT = CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.EFFED AS INT), CAST(@SIL_DT AS DATETIME)),120)         
                        ,@BEGDA = A.BEGDA          
                        ,@LONGD = A.LONGD          
                        ,@EFFED = A.EFFED          
                        ,@EXTED = A.EXTED          
                        ,@ZQMLK = A.ZQMLK          
                        ,@ZEFLK = A.ZEFLK          
                        FROM SAP_Z02MESF_D080 A WITH (NOLOCK)          
                    WHERE A.MATNR = @ITEM_cD AND  A.BEGDA <= @SIL_DT          
                    ORDER BY A.BEGDA DESC         
                    --),'')         
         
                    IF EXISTS(SELECT *FROM PD_LOT_EXP_DT A WITH (NOLOCK)          
                    WHERE A.DIV_CD = @DIV_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO         
                    )         
                    BEGIN          
                        UPDATE A SET A.PRDAT = @SIL_DT, A.VFDAT = @VFDAT,          
                        A.BEGDA = @BEGDA, A.LONGD = @LONGD, A.EFFED = @EFFED, A.EXTED = @EXTED, A.ZQMLK = @ZQMLK,          
                        A.ZEFLK = @ZEFLK,          
                        A.UPDATE_ID = @USER_ID, A.UPDATE_DT = GETDATE()         
                            FROM PD_LOT_EXP_DT A    
                        WHERE A.DIV_CD = @DIV_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO          
                                
                    END          
                    ELSE          
                    BEGIN          
                        INSERT INTO PD_LOT_EXP_DT          
                        (         
                            DIV_CD,          ITEM_CD,             LOT_NO,             DTYPE,          
                            PRDAT,           VFDAT,                   
         
                            BEGDA,           LONGD,         
                            EFFED,           EXTED,         
                            ZQMLK,           ZEFLK,         
         
                            INSERT_ID,       INSERT_DT,          
                            UPDATE_ID,       UPDATE_DT         
                        )         
                        SELECT          
                            @DIV_CD,         @ITEM_CD,            @LOT_NO,            'GRD',         
                            @SIL_DT,         @VFDAT,     
         
                            @BEGDA,          @LONGD,          
                            @EFFED,          @EXTED,          
                            @ZQMLK,          @ZEFLK,          
                                             
                            @USER_ID,        GETDATE(),          
                            @USER_ID,        GETDATE()         
                    END          
         
             END          
                ELSE          
                BEGIN          
                    SET @MSG_CD = '9999'         
                    SET @MSG_DETAIL = '유효일 기준 정보가 없습니다. 확인하여 주십시오. SAP Interface : D080, ' + @ITEM_CD         
                    RETURN 1          
                END          
            END    
 
-- [SP PART 4/6]                      
            -------------------------------------------------------------         
                                   
            -- 그룹공정이면은 앞에 공정 LOT 가 전부 맞는지를 확인을 해야 된다.             
            -- 24.08.16 LJW             
 /*           
            IF @GROUP_E = 'Y'             
            BEGIN             
                -- 이전 공정 리스트를 찾자             
                IF EXISTS(            
                SELECT             
                    *FROM PD_RESULT A WITH (NOLOCK)             
                   INNER JOIN PD_RESULT B WITH (NOLOCK) ON             
                    A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO AND             
 A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM             
                    AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD             
                    AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT             
                    --AND A.LOT_NO = B.LOT_NO             
                                
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION             
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER             
                  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ             
                  AND A.LOT_NO <> B.LOT_NO            
                )            
                BEGIN             
                    SET @MSG_CD = '9999'            
                    SET @MSG_DETAIL = '그룹 공정의 LOT 가 일치하지 않습니다. 관리자에게 문의하여 주십시오.'            
                    RETURN 1            
                END             
            END             
 */           
        END                              
            
     -- 실적 공정일때, 전체 재고 수량을 공정 정보에 체크, 소요량 총 수량을 공정 정보에 체크             
        -- 24.08.16 LJW            
            
        IF ISNULL((SELECT A.USE_YN FROM BA_SUB_CD A WITH (NOLOCK)         
        WHERE A.MAIN_CD = 'POP54' AND A.SUB_CD = '01'            
            
        ),'N') = 'Y'            
        BEGIN             
            IF @OUT_CHK = 'Y'             
            BEGIN             
                -- 재고 수량을 처리            
                -- 자 일단은 MAX, MIN 을 먼저 가지고 온다.             
                                
                DECLARE @MAX_WE     NUMERIC(18,3) = 0             
                       ,@MIN_WE     NUMERIC(18,3) = 0             
                       ,@MAX_WE_WIP NUMERIC(18,3) = 0             
                       ,@MIN_WE_WIP NUMERIC(18,3) = 0             
            
                SELECT @MAX_WE = A.MAX_WEIGHT, @MIN_WE = A.MIN_WEIGHT, @MAX_WE_WIP = A.MAX_WEIGHT_WIP, @MIN_WE_WIP = A.MIN_WEIGHT_WIP             
                FROM BA_ROUTING_DETAIL A WITH (NOLOCK)             
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ROUT_NO = @ROUT_NO AND A.[VERSION] = @ROUT_VER AND A.WC_CD = @WC_CD             
                AND A.PROC_CD = @PROC_CD                         
            
                -- 재고 중량중 하나라도 0 보다 큰게 있으면?            
                IF @MAX_WE > 0 OR @MIN_WE > 0            
                BEGIN             
                    IF NOT(@MAX_WE >= @SUM_QTY AND @MIN_WE <= @SUM_QTY)            
                    BEGIN             
                        SET @MSG_CD = '9999'            
                        SET @MSG_DETAIL = '재고 중량이 범위에 포함되어 있지 않습니다. ' + CHAR(10) +      
                        'MAX 중량 : ' + CAST(@MAX_WE AS NVARCHAR) + CHAR(10) +             
                        'MIN 중량 : ' + CAST(@MIN_WE AS NVARCHAR) + CHAR(10) +             
                        '현재 중량 : ' + CAST(@SUM_QTY AS NVARCHAR)            
            
                        RETURN 1            
                    END             
            
                END             
            
                -- 그룹인지 아닌지를 확인해야 된다.             
                -- 그룹이면? 제일 앞에 있는 재공 정보....            
                -- 그룹이 아니면? 자기자신의 재공 정보인데...            
                DECLARE @USEM_QTY NUMERIC(18,3) = 0             
            
                IF @GROUP_E = 'Y'             
                BEGIN             
                    -- 그룹일 경우 앞에 제일 처음 공정정보를 찾자.             
                    -- 그룹일 경우는 오더까지 다 매칭해줘도 된다.             
                    SET @USEM_QTY = ISNULL(( SELECT SUM(AA.USEM_QTY)            
                    FROM PD_USEM AA WITH (NOLOCK)             
                    INNER JOIN (            
                    SELECT TOP 1 B.*FROM PD_RESULT A WITH (NOLOCK)             
                    INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO            
                    AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER             
                    AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ             
                    AND A.GROUP_LOT = B.GROUP_LOT            
                    INNER JOIN PD_ORDER_PROC C WITH (NOLOCK) ON             
                    B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION             
                    AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER             
                    AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD             
                               
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION             
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER             
                      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_cD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_sEQ             
                    ORDER BY C.GROUP_SEQ            
                    ) BB ON AA.DIV_CD = BB.DIV_CD AND AA.PLANT_CD = BB.PLANT_CD             
                    AND AA.ORDER_NO = BB.ORDER_NO AND AA.REVISION = BB.REVISION AND AA.ORDER_TYPE = BB.ORDER_TYPE AND AA.ROUT_NO = BB.ROUT_NO             
                    AND AA.ROUT_VER = BB.ROUT_VER AND AA.WC_CD = BB.WC_CD AND AA.LINE_CD = BB.LINE_CD AND AA.PROC_CD = BB.PROC_CD AND AA.RESULT_SEQ = BB.RESULT_SEQ            
                    ),0)             
                END            
                ELSE             
                BEGIN             
            
                    -- 그룹이 아닐 경우는 자기 자신의 PD_USEM 의 합산을 가지고 오면 된다.            
            
                    SET @USEM_QTY = ISNULL((SELECT SUM(A.USEM_QTY)             
                        FROM PD_USEM A WITH (NOLOCK)             
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE             
                    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD             
                    AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ),0)             
            
                END              
                            
                IF @MAX_WE_WIP > 0 OR @MIN_WE_WIP > 0            
                BEGIN             
                    IF NOT(@MAX_WE_WIP >= @USEM_QTY AND @MIN_WE_WIP <= @USEM_QTY)            
                    BEGIN             
                        SET @MSG_CD = '9999'            
                        SET @MSG_DETAIL = '재공 중량이 범위에 포함되어 있지 않습니다. ' + CHAR(10) +             
                        'MAX 중량 : ' + CAST(@MAX_WE_WIP AS NVARCHAR) + CHAR(10) +             
                        'MIN 중량 : ' + CAST(@MIN_WE_WIP AS NVARCHAR) + CHAR(10) +             
                        '현재 중량 : ' + CAST(@USEM_QTY AS NVARCHAR)            
            
                        RETURN 1            
                    END             
                END              
            
            END             
        END             
        -- 이전 공정 체크 인데 현공정이 GROUP 안에 들어가 있고,                              
        -- 투입공정이 아닌 경우에만,                             
        -- 그리고 종료가 아닌 경우에만                              
                             
        IF @GROUP = 'Y' AND @IN_CHK = 'N'                              
        BEGIN                              
                        
            DECLARE                             
                    @BE_ORDER_NO NVARCHAR(50)                              
                   ,@BE_REVISION INT                              
                   ,@BE_ROUT_NO  NVARCHAR(10)                              
                   ,@BE_ROUT_VER INT                              
                   ,@BE_WC_CD    NVARCHAR(10)                              
                   ,@BE_LINE_CD  NVARCHAR(10)                              
                   ,@BE_PROC_CD  NVARCHAR(10)                              
            -- PROC 순번을 가지고 와야 된다.                              
                             
                                         
            SELECT TOP 1 @BE_ORDER_NO = A.ORDER_NO, @BE_REVISION = A.REVISION, @BE_ROUT_NO = A.ROUT_NO, @BE_ROUT_VER = A.ROUT_VER, @BE_WC_CD = A.WC_CD, @BE_LINE_CD = A.LINE_CD, @BE_PROC_CD = A.PROC_CD                             
                FROM PD_ORDER_PROC A WITH (NOLOCK)                              
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE                              
            AND A.ORDER_FORM = @ORDER_FORM --AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                              
            AND A.SKIP = 'N' AND A.IN_CHK = 'N' -- 그룹 중간에 투입이 있으면 별개로 가지고 가야 된다. PRE_bARE 소성 이후 BARE 투입 같은 경우...                             
            AND CAST((REPLACE(A.ORDER_NO,'PD','') + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) AS BIGINT) < CAST((REPLACE(@ORDER_NO,'PD','') + CAST(@REVISION AS NVARCHAR) + CAST(@PROC_SEQ AS NVARCHAR)) AS BIGINT)                        
 
  
   
    
     
      
                                  
            ORDER BY (A.ORDER_NO + CAST(A.REVISION AS NVARCHAR) + CAST(A.PROC_SEQ AS NVARCHAR)) DESC                              
                             
         --   SELECT @BE_ORDER_NO, @BE_REVISION, @BE_ROUT_NO ,@BE_ROUT_VER, @BE_WC_CD, @BE_LINE_CD, @BE_PROC_CD                  
            IF ISNULL((SELECT A.S_CHK                             
                FROM PD_ORDER_PROC A WITH (NOLOCK)                              
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @BE_ORDER_NO AND A.REVISION = @BE_REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE                              
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @BE_ROUT_NO AND A.ROUT_VER = @BE_ROUT_VER AND A.WC_CD = @BE_WC_CD AND A.LINE_CD = @BE_LINE_CD                
                AND A.PROC_CD = @BE_PROC_CD                              
             ),'N') = 'Y'                              
                                         
            BEGIN                              
                -- 이전 공정일때 같은 실적을 등록 똑같이 해준다.                              
                IF @AP_CHK = 'N'     
                BEGIN                              
                    INSERT INTO PD_ITEM_IN                              
                    (                             
                        DIV_CD,              PLANT_CD,                PROC_NO,                ORDER_NO,                    REVISION,                 ORDER_TYPE,                                     
                        ORDER_FORM,         ROUT_NO,     ROUT_VER,               WC_CD,                       LINE_CD,                  PROC_CD,                              
                        S_CHK,                              
                        RESULT_SEQ,          SEQ,                      ITEM_CD,                  LOT_NO,                 SL_CD,                       LOCATION_NO,              RACK_CD,                              
                        SIL_DT,                                           
                        GOOD_QTY,            INSERT_ID,                INSERT_DT,              UPDATE_ID,      UPDATE_DT,                BARCODE                             
                    )                             
                    SELECT                              
                        @DIV_CD,             @PLANT_CD,                @PROC_NO,               @BE_ORDER_NO,                @BE_REVISION,             @ORDER_TYPE,                              
                        @ORDER_FORM,         @BE_ROUT_NO,              @BE_ROUT_VER,           @BE_WC_CD,                   @BE_LINE_CD,              @BE_PROC_CD,                              
                        @S_CHK,                              
                        @RESULT_SEQ,         1,                        @ITEM_CD,           @LOT_NO,                '3000',   @BE_LINE_CD,              '*',                              
                        @SIL_DT,                            
                        0,                   @USER_ID,                 GETDATE(),              @USER_ID,        GETDATE(),                '*'                             
                END                             
                                         
                                          
            END                              
        END                              
                             
                             
        -- 만약 실적 공정이면 PD_LOT_SEQ 에 업데이트를 해야 될것 같다.                             
                  
        IF @NS_CHK = 'N' AND @WC_CD <> '13P'              
        BEGIN                     
          IF (SELECT A.OUT_CHK FROM PD_ORDER_PROC A WITH (NOLOCK)                              
             WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                              
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                   
            ) = 'Y'                             
            BEGIN                              
                                 
                IF (SELECT A.J_CHK FROM PD_RESULT A WITH (NOLOCK)                              
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                              
                  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                              
                  AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                      
                                 
                ) = 'N'                             
                BEGIN                              
                    DECLARE @LOT_SEQ   INT = 0                              
                                                 
                    --SET @LOT_SEQ = CAST(RIGHT(@LOT_NO,3) AS INT)                             
                                                  
    --                SET @LOT_SEQ = CAST(RIGHT(@LOT_NO,3) AS INT)                              
                                  
                    SELECT @SIL_DT = A.SIL_DT,@LOT_SEQ = A.LOT_SEQ FROM PD_RESULT A WITH (NOLOCK)                               
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                               
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                               
                      AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                              
                                                
                    IF ISNULL(@LOT_SEQ,0) = 0                             
                    BEGIN                             
                        SET @MSG_CD = '9999'                        
                        SET @MSG_DETAIL = '채번순번이 0 으로 조정되었습니다. 관리자에게 문의하여 주십시오.'                            
                        RETURN 1                            
                    END                             
                    
                    DECLARE @GDATE NVARCHAR(10) = ''                     
                    SELECT @GDATE = CONVERT(NVARCHAR(10), CAST('20' + SUBSTRING(@LOT_NO, 2,4) + '01' AS DATETIME), 120)                     
           
                    IF EXISTS(SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)                              
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = CONVERT(NVARCHAR(7), CAST(@GDATE AS DATETIME), 120)                              
                    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                              
                    )                             
                    BEGIN                              
                        UPDATE A SET A.LOT_SEQ = @LOT_SEQ, A.ORDER_NO = @ORDER_NO, A.REVISION = @REVISION, A.RESULT_SEQ = @RESULT_SEQ,                             
                        UPDATE_ID = @USER_ID, UPDATE_DT = GETDATE()                             
                            FROM PD_LOT_SEQ A    
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = CONVERT(NVARCHAR(7), CAST(@GDATE AS DATETIME), 120)                              
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
                            @DIV_CD,           @PLANT_CD,             CONVERT(NVARCHAR(7), CAST(@GDATE AS DATETIME), 120),             @WC_CD,                 @LINE_CD,                              
                            @PROC_CD,          @LOT_SEQ,              @ORDER_NO,           @REVISION,                                           
                            @RESULT_SEQ,       @USER_ID,              GETDATE(),           @USER_ID,               GETDATE()                   
                    END                              
                END                          
            END                          
        END                     
    END                              
                 
    -- SAP Interface 처리                             
                            
    -- 투입 공정이다.                            
                              
                               
    IF @IN_CHK = 'Y' OR @MIN_CHK = 'Y' OR (@OUT_CHK = 'Y' AND @ADD_CHK = 'Y')                     
    BEGIN                             
        DECLARE @ZMESIFNO NVARCHAR(100)  =''                  
                            
        -- 투입정보와 SAP 정보를 매칭 한다.                             
     -- 배정정보에 있는 품목인지를 확인해야 된다.                             
                            
        -- 일단 투입 품목 리스트를 가지고 온다.                             
-- [SP PART 5/6]                    
        DECLARE @IF_USEM_TABLE TABLE (                            
             CNT        INT IDENTITY(1,1)                             
            ,USEM_SEQ   INT                             
            ,ITEM_CD    NVARCHAR(50)           
            ,LOT_NO     NVARCHAR(50)     
            ,USEM_QTY   NUMERIC(18,3)                             
            ,REQ_DT     NVARCHAR(10)                             
            ,REQ_NO     NVARCHAR(50)                             
            ,REQ_SEQ    INT                             
            ,PLAN_SEQ   INT                             
            ,BATCH_NO   INT                             
            ,ITEM_TYPE  NVARCHAR(2)                       
        )                            
                                 
        IF @IN_CHK = 'Y' AND @MIN_CHK = 'N'                         
        BEGIN                          
            INSERT @IF_USEM_TABLE                             
            (                            
                USEM_SEQ,          ITEM_CD,           LOT_NO,           USEM_QTY,          REQ_DT,           REQ_NO,            REQ_SEQ,                                    
                PLAN_SEQ,          BATCH_NO,          ITEM_TYPE                             
            )                            
            SELECT                             
                A.USEM_SEQ,        A.ITEM_CD,         A.LOT_NO,         A.USEM_QTY,        A.REQ_DT,        A.REQ_NO,         A.REQ_SEQ,                             
                A.PLAN_SEQ,        A.BATCH_NO,        A.ITEM_TYPE                            
            FROM PD_USEM A  
            INNER JOIN PD_ORDER_USEM B  
            ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION                             
            AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                             
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD =B.PROC_CD AND A.ITEM_CD = B.ITEM_CD                             
            INNER JOIN SAP_Z02MESF_P010_DTL C  
            ON A.PLANT_CD = C.WERKS AND A.ORDER_NO = C.MES_ORDER_NO --AND A.REVISION = C.MES_REVISION                             
            INNER JOIN SAP_Z02MESF_P010_USEM D  
            ON              
            C.WERKS = D.WERKS AND C.AUFNR = D.AUFNR AND B.ITEM_CD = D.MATNR AND B.VORNR = D.VORNR AND B.RSNUM = D.RSNUM AND B.RSPOS = D.RSPOS AND B.BWART = D.BWART                              
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO                             
            AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                             
            AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
            AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
            AND A.IN_GBN IN ('N','G') -- 일반과 소분으로 구분한다.               
            
                      
                                      
        END                    
            
        IF @OUT_CHK = 'Y' AND @ADD_CHK = 'Y'            
        BEGIN             
            -- 지르코늄 데이터를 추가 한다.             
            -- 24.08.16 LJW             
            -- 지르코늄은 IN_GBN = 'E' 이고             
            -- 데이터가... 음... 첨가제일 경우?            
            INSERT @IF_USEM_TABLE                             
            (                            
                USEM_SEQ,          ITEM_CD,           LOT_NO,           USEM_QTY,          REQ_DT,           REQ_NO,            REQ_SEQ,                                    
                PLAN_SEQ,          BATCH_NO,        ITEM_TYPE                             
            )                
                        
            SELECT                             
                A.USEM_SEQ,        A.ITEM_CD,         A.LOT_NO,         A.USEM_QTY,        A.REQ_DT,        A.REQ_NO,         A.REQ_SEQ,                             
                A.PLAN_SEQ,        A.BATCH_NO,        A.ITEM_TYPE                            
            FROM PD_USEM A  
            INNER JOIN PD_ORDER_USEM B  
            ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION                      
            AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                             
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD =B.PROC_CD AND A.ITEM_CD = B.ITEM_CD                             
            INNER JOIN SAP_Z02MESF_P010_DTL C  
            ON A.PLANT_CD = C.WERKS AND A.ORDER_NO = C.MES_ORDER_NO --AND A.REVISION = C.MES_REVISION                             
            INNER JOIN SAP_Z02MESF_P010_USEM D  
            ON                             
            C.WERKS = D.WERKS AND C.AUFNR = D.AUFNR AND B.ITEM_CD = D.MATNR AND B.VORNR = D.VORNR AND B.RSNUM = D.RSNUM AND B.RSPOS = D.RSPOS AND B.BWART = D.BWART                              
            INNER JOIN V_ITEM E ON A.PLANT_CD = E.PLANT_CD AND A.ITEM_CD = E.ITEM_CD AND E.ITEM_CLASS = '4000'            
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO                             
            AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                             
            AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
            AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
            AND A.IN_GBN IN ('E') -- 일반과 소분으로 구분한다.               
                        
        END                   
                         
        IF @MIN_CHK = 'Y' AND @IN_CHK = 'N'                         
        BEGIN                      
            INSERT @IF_USEM_TABLE                             
            (                            
                USEM_SEQ,          ITEM_CD,           LOT_NO,           USEM_QTY,          REQ_DT,           REQ_NO,            REQ_SEQ,                                    
                PLAN_SEQ,          BATCH_NO,          ITEM_TYPE          
            )                            
           SELECT                             
                A.USEM_SEQ,        A.ITEM_CD,         A.LOT_NO,         A.USEM_QTY,        A.REQ_DT,        A.REQ_NO,         A.REQ_SEQ,                           
            A.PLAN_SEQ,        A.BATCH_NO,        A.ITEM_TYPE                           
            FROM PD_USEM A  
            INNER JOIN PD_ORDER_USEM B  
            ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION                             
            AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                             
            AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD =B.PROC_CD AND A.ITEM_CD = B.ITEM_CD                             
            INNER JOIN SAP_Z02MESF_P010_DTL C  
            ON A.PLANT_CD = C.WERKS AND A.ORDER_NO = C.MES_ORDER_NO --AND A.REVISION = C.MES_REVISION                             
            INNER JOIN SAP_Z02MESF_P010_USEM D  
            ON                             
            C.WERKS = D.WERKS AND C.AUFNR = D.AUFNR AND B.ITEM_CD = D.MATNR AND B.VORNR = D.VORNR AND B.RSNUM = D.RSNUM AND B.RSPOS = D.RSPOS AND B.BWART = D.BWART                              
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO                             
            AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                             
            AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
            AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
            AND A.IN_GBN IN ('SU') -- 일반과 소분으로 구분한다.                              
                         
        END                          
                                 
        DECLARE @IF_CNT  INT = 0                             
               ,@IF_TCNT INT = 0                        
                            
        SELECT @IF_TCNT = COUNT(*) FROM @IF_USEM_TABLE                             
                            
        WHILE @IF_CNT <> @IF_TCNT                             
        BEGIN                             
            SET @IF_CNT = @IF_CNT + 1                             
                            
            DECLARE @IF_ITEM_CD    NVARCHAR(50) = ''                            
                   ,@IF_LOT_NO     NVARCHAr(50) = ''                             
                   ,@IF_USEM_QTY   NUMERIC(18,3) = 0                             
                   ,@IF_REQ_DT     NVARCHAR(10) = ''                             
                   ,@IF_REQ_NO     NVARCHAR(50) = ''                          
                   ,@IF_PLAN_SEQ   INT = 0                             
                   ,@IF_BATCH_NO   INT = 0                             
                   ,@IF_USEM_SEQ   INT = 0                            
                   ,@IF_ITEM_TYPE  NVARCHAR(2) = ''                       
                                           
            SELECT @IF_ITEM_CD = A.ITEM_CD, @IF_LOT_NO = A.LOT_NO, @IF_USEM_QTY = A.USEM_QTY,                            
                   @IF_REQ_DT = A.REQ_DT, @IF_REQ_NO = A.REQ_NO, @IF_PLAN_SEQ = A.PLAN_SEQ, @IF_BATCH_NO = A.BATCH_NO,                            
                   @IF_USEM_SEQ = A.USEM_SEQ, @IF_ITEM_TYPE = A.ITEM_TYPE                             
            FROM @IF_USEM_TABLE A WHERE A.CNT = @IF_CNT                             
                            
            --SELECT *FROM @IF_USEM_TABLE                       
                      
            IF @IF_REQ_NO <> ''  -- 배정번호가 있으면? 배정 리스트로 I/F 를 구성한다.                             
            BEGIN                             
                --SELECT *FROM @IF_USEM_TABLE                      
                -- 소분일 경우                       
   -- 진배정을 만들어줘야 된다.         
                -- 그뒤에 I/F 까지 날려줘야 됩니다.                       
                IF @IF_ITEM_TYPE = 'SU'                      
                BEGIN                       
                    DECLARE @MAX_PLAN_SEQ INT = 0                       
                           ,@NEW_REQ_NO   NVARCHAR(50) = ''                      
                           ,@BASIC_UNIT   NVARCHAR(3)     = 'KG'     -- 단위                         
                           ,@PALLET_QTY   NUMERIC(15,4)   = 0                       
                      
                   SELECT @BASIC_UNIT = BASIC_UNIT, @PALLET_QTY = ISNULL(PALLET_QTY,0)                         
                      FROM V_ITEM (NOLOCK)                         
                    WHERE PLANT_CD = @PLANT_CD AND ITEM_CD = @ITEM_CD                         
                          
                      
                    SET @MAX_PLAN_SEQ = ISNULL((SELECT MAX(A.PLAN_SEQ) FROM MT_ITEM_OUT_BATCH A WITH (NOLOCK)                       
                    WHERE A.REQ_DT = @IF_REQ_DT AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.ITEM_TYPE = 'SU'),0) + 1                      
                                          
                --    SELECT @MAX_PLAN_SEQ                      
                      
                  --  SELECT @ITEM_CD, @IF_ITEM_CD                       
                    DECLARE @STR_DATE NVARCHAR(8) =  CONVERT(NVARCHAR(8), GETDATE(), 112)    			                    
                    EXEC USP_CM_AUTO_NUMBERING 'BC', @STR_DATE, @USER_ID, @NEW_REQ_NO OUT                         
                    -- 배정 I/F 를 넣는다.                       
                    DECLARE @BATCH_ZMESIFNO NVARCHAR(50) = ''                       
                    EXEC USP_SAP_MESIFNO_CREATE @DIV_CD, @PLANT_CD, 'P020', @USER_ID, @BATCH_ZMESIFNO OUT	                                       
                           
                    INSERT INTO MT_ITEM_OUT_BATCH                       
                    (                      
                        DIV_CD,           PLANT_CD,             REQ_DT,              REQ_NO,                REQ_SEQ,            WC_CD,              LINE_CD,                       
                        PLAN_SEQ,         BATCH_NO,             ITEM_TYPE,           PRNT_ITEM_CD,          LOT_NO,             ITEM_CD,                       
                        PALLET_QTY,       REQ_QTY,              USE_QTY,             USE_FLG,               ST_FLG,             BATCH_FORM,                       
                        ST_TYPE,          PROC_CD,              REMARK,              CHG_RSN,            TEMP_CD1,  INSERT_ID,                       
                        INSERT_DT,        UPDATE_ID,            UPDATE_DT,           ORDER_NO,              ZMESIFNO,           SU_REQ_NO                        
                    )                      
                    SELECT                       
                        @DIV_CD,          @PLANT_CD,            @IF_REQ_DT,          @NEW_REQ_NO,           1,                  @WC_CD,             @LINE_CD,                       
                        @MAX_PLAN_SEQ,    1,                    'SU',                @ITEM_CD,              @IF_LOT_NO,         @IF_ITEM_CD,                       
                        @PALLET_QTY,      @IF_USEM_QTY,         @IF_USEM_QTY,        'N',            'N',                '10',                       
                        'SM',             @PROC_CD,             '소분진배정등록',      '',                    'POP',              @USER_ID,                       
                        GETDATE(),        @USER_ID,             GETDATE(),           @ORDER_NO,             @BATCH_ZMESIFNO,   @IF_REQ_NO                       
             
                    INSERT INTO SAP_Z02MESF_P020                           
						  ( CSYST,          ZMESIFNO,       WERKS,          AUFNR,                           
							DAUAT,          VERID,         ARBPL,          PRODMAT,                           
							RSNUM,          RSPOS,          COMMAT,         ZLOTNO,                           
							CHARG,          ZREGQ,          MEINS,     BASEM,                           
							ZSEQL,          ZSEQA,          BGUBUN,         ZGIOP,                           
							ZVAART,         ZSTORN,         ZMESIFNO_C,     ZCRES,                           
							ZGI,            RETCD,          RETMG,                           
							MES_INS_DT,     MES_INS_ID,     MES_UPD_DT,    MES_UPD_ID )                           
                           
					SELECT DISTINCT                           
						   'MES'	   AS CSYST,                           
						   @BATCH_ZMESIFNO                                      AS ZMESIFNO,                           
						   A.WERKS,                           
						   A.AUFNR,                           
						   B.DAUAT,                           
						   B.VERID,                           
						   A.ARBPL,                           
						   B.MATNR                                              AS PRODMAT,                           
						   C.RSNUM,                           
						   C.RSPOS,                           
						   C.MATNR                                               AS COMMAT,                           
						   @IF_LOT_NO                                            AS ZLOTNO,                           
						   DBO.FN_GET_CHARG(@IF_ITEM_CD, @IF_LOT_NO)             AS CHARG,                           
						   @IF_USEM_QTY		                                     AS ZREGQ,                           
						   C.EINHEIT                                             AS MEINS,                           
						   REPLACE(@IF_REQ_DT, '-', '')                          AS BASEM,                           
						   RIGHT('0000' + CAST(@MAX_PLAN_SEQ AS NVARCHAR(4)), 4) AS ZSEQL,                           
						   RIGHT('0000' + CAST(1 AS NVARCHAR(4)), 4)	         AS ZSEQA,                           
						   'B'			  		                                 AS BGUBUN,                           
						   @PROC_CD	                                 AS ZGIOP,                           
						   'B'						                             AS ZVAART,                   
						   ''						                             AS ZSTORN,                           
						   ''						                             AS ZMESIFNO_C,                           
						   ''						                             AS ZCRES,                           
						   ''						                             AS ZGI,                           
						   NULL						                             AS RETCD,                           
						   NULL						                             AS RETMG,                           
						   GETDATE(),                           
						   @USER_ID,                           
						   NULL,                           
						   NULL                           
					  FROM SAP_Z02MESF_P010_DTL A  
				        INNER JOIN SAP_Z02MESF_P010_HDR B  
						ON A.AUFNR = B.AUFNR                           
					   AND A.WERKS = B.WERKS                           
				        INNER JOIN SAP_Z02MESF_P010_USEM C  
						ON A.AUFNR = C.AUFNR                           
					   AND A.WERKS = C.WERKS                           
					   AND A.VORNR = C.VORNR                           
					   AND C.MATNR = @IF_ITEM_CD                       
                       AND ISNULL(C.XLOEK,'') <> 'X'                  
					 WHERE A.WERKS = @PLANT_CD                           
					   AND A.MES_ORDER_NO = @ORDER_NO                       
                      
                    IF NOT EXISTS(SELECT *FROM                      
                        SAP_Z02MESF_P020 A WITH (NOLOCK)                       
                        WHERE A.WERKS = @PLANT_CD AND A.ZMESIFNO = @BATCH_ZMESIFNO                      
                      
              )                      
                    BEGIN          
                        SET @MSG_CD = '9999'                      
                        SET @MSG_DETAIL = '소분 진배정 데이터가 생성되지 않았습니다. 관리자에게 문의하여 주십시오.' + CHAR(10)                       
                    + 'Master Request No : ' + @IF_REQ_NO                      
                        + CHAR(10)                       
                    + 'Detail Request No : ' + @NEW_REQ_NO                      
                      
                        RETURN 1                      
                    END                       
                    -- PD_USEM 에 UPDATE 를 해준다.                       
                      
                    UPDATE A SET A.REQ_NO = @NEW_REQ_NO, A.PLAN_SEQ = @MAX_PLAN_SEQ, A.BATCH_NO = 1                      
                    FROM PD_USEM A  
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                       
                      AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO                       
                      AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                       
                      AND A.RESULT_SEQ = @RESULT_SEQ AND A.USEM_SEQ = @IF_USEM_SEQ AND A.ITEM_TYPE = 'SU'                      
                      
           -- 진배정에도 업데이트를 해줘야 된다.                       
                      
                END                       
                                      
-- [SP PART 6/6]                               
                SET @ZMESIFNO = ''                             
                EXEC USP_SAP_MESIFNO_CREATE @DIV_CD, @PLANT_CD, 'P030', @USER_ID, @ZMESIFNO OUT                                        
                            
                INSERT INTO SAP_Z02MESF_P030                            
                SELECT E.CSYST,                             
                @ZMESIFNO AS ZMESIFNO,       
                E.WERKS,                                        
				E.AUFNR,                                        
				F.SIL_DT  AS ZPROD,                                    
				E.VERID,                                        
				E.ARBPL,                  
				E.PRODMAT,                                        
				E.RSNUM,                                        
				E.RSPOS,                                        
				E.COMMAT,                                        
				E.ZLOTNO,                                        
				DBO.FN_GET_CHARG(A.ITEM_CD, A.LOT_NO),                                        
				A.USEM_QTY   AS ZGIQTY,                
				E.MEINS,                                        
				E.BASEM,                                        
				E.ZSEQL,                                        
				E.ZSEQA,                                        
				E.BGUBUN,                                        
				E.ZGIOP,                                        
				'B'          AS ZVAART,                                        
				''           AS ZSTORN,                                        
				''           AS ZMESINFO_C,                  
				D.BWART,                                        
				''           AS MBLNR,                                        
				''           AS MJAHR,                                       
				''           AS ZCRES,          
				''           AS ZCONF,                                        
				''           AS MESSAGE,                                        
				NULL         AS RETCD,                                        
				NULL         AS RETMG,                                        
				GETDATE()    AS MES_INS_DT,                                        
				@USER_ID     AS MES_INS_ID,                                        
				NULL,                                        
				NULL              
                                            
                FROM PD_USEM A  
                INNER JOIN PD_ORDER_USEM B  
                ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION                             
                AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                             
                AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD =B.PROC_CD AND A.ITEM_CD = B.ITEM_CD                             
                INNER JOIN SAP_Z02MESF_P010_DTL C  
                ON A.PLANT_CD = C.WERKS AND A.ORDER_NO = C.MES_ORDER_NO --AND A.REVISION = C.MES_REVISION                             
                INNER JOIN SAP_Z02MESF_P010_USEM D ON                             
                C.WERKS = D.WERKS AND C.AUFNR = D.AUFNR AND B.ITEM_CD = D.MATNR AND C.VORNR = D.VORNR                                  
                 CROSS APPLY (                            
                    SELECT TOP 1 AA.* FROM SAP_Z02MESF_P020 AA  
                    WHERE AA.WERKS = D.WERKS AND AA.AUFNR = D.AUFNR AND AA.RSNUM = D.RSNUM AND AA.RSPOS = D.RSPOS                             
                    AND AA.ZLOTNO = A.LOT_NO                            
                    AND AA.BASEM = REPLACE(A.REQ_DT, '-','')                            
                    AND CAST(AA.ZSEQL AS INT) = CAST(A.PLAN_SEQ AS INT)                            
                    AND CAST(AA.ZSEQA AS INT) = CAST(A.BATCH_NO AS INT)                            
                  AND AA.ZVAART = 'B'                            
                    ORDER BY AA.ZMESIFNO DESC                           
              ) E                            
/*                            
                INNER JOIN SAP_Z02MESF_P020 E WITH (NOLOCK) ON D.WERKS = E.WERKS AND D.AUFNR = E.AUFNR AND D.RSNUM = E.RSNUM AND D.RSPOS = E.RSPOS                            
                AND A.LOT_NO = E.ZLOTNO                             
                AND REPLACE(A.REQ_DT, '-','') = E.BASEM                             
                AND CAST(A.PLAN_SEQ AS INT) = CAST(E.ZSEQL AS INT)                         
                AND CAST(A.BATCH_NO AS INT) = CAST(E.ZSEQA AS INT)         
                */                            
                INNER JOIN PD_RESULT F ON                             
                A.DIV_CD = F.DIV_CD AND A.PLANT_CD = F.PLANT_CD AND A.ORDER_NO = F.ORDER_NO AND A.REVISION = F.REVISION                             
                AND A.ORDER_TYPE = F.ORDER_TYPE AND A.ORDER_FORM = F.ORDER_FORM AND A.ROUT_NO = F.ROUT_NO AND A.ROUT_VER = F.ROUT_VER                             
                AND A.WC_CD = F.WC_CD AND A.LINE_CD = F.LINE_CD AND A.PROC_CD = F.PROC_CD AND F.S_CHK = 'N' AND A.RESULT_SEQ = F.RESULT_SEQ                             
                    
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO                        
                AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                             
                AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
                AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.USEM_SEQ = @IF_USEM_sEQ                            
                            
                IF NOT EXISTS(SELECT *FROM SAP_Z02MESF_P030 A WITH (NOLOCK)                             
                WHERE A.ZMESIFNO = @ZMESIFNO              
                )                
                BEGIN                             
                    SET @MSG_CD = '9999'                            
                    SET @MSG_DETAIL = 'SAP Interface 배정투입 소요량 정보가 생성되지 않았습니다. 관리자에게 문의하여 주십시오.'                            
                    RETURN 1                            
                END                             
                            
                UPDATE A SET A.ZMESIFNO = @ZMESIFNO                             
                    FROM PD_USEM A  
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                             
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER           
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                     
                AND A.USEM_SEQ = @IF_USEM_SEQ  AND A.ITEM_CD = @IF_ITEM_CD AND A.LOT_NO = @IF_LOT_NO                  
                            
            END                             
            ELSE                             
            BEGIN                             
                -- 배정 번호가 없는 것을 처리합니다.                             
                SET @ZMESIFNO = ''                             
                EXEC USP_SAP_MESIFNO_CREATE @DIV_CD, @PLANT_CD, 'P030', @USER_ID, @ZMESIFNO OUT                                        
                            
                INSERT INTO SAP_Z02MESF_P030                            
                SELECT 'MES',                             
                @ZMESIFNO AS ZMESIFNO,                             
                D.WERKS,                                        
				D.AUFNR,                                        
				F.SIL_DT  AS ZPROD,                                        
				E.VERID,                                        
				C.ARBPL,                                        
				E.MATNR,                                        
				D.RSNUM,                                        
				D.RSPOS,                                        
				D.MATNR,                                        
				A.LOT_NO,                                      
				DBO.FN_GET_CHARG(A.ITEM_CD, A.LOT_NO),                                        
				A.USEM_QTY   AS ZGIQTY,                                        
				D.EINHEIT,                                        
				'000000',                                        
				'0000',                                        
				'0000',                                        
				'C',                                        
				'',                                        
				'B'         AS ZVAART,                        
				''           AS ZSTORN,                                        
				''           AS ZMESINFO_C,                                        
				D.BWART,                
				''           AS MBLNR,                                        
				''           AS MJAHR,                        
				''           AS ZCRES,                                        
				''           AS ZCONF,                                        
				''           AS MESSAGE,                                        
				NULL         AS RETCD,                                        
				NULL         AS RETMG,                                        
				GETDATE()    AS MES_INS_DT,                                        
				@USER_ID     AS MES_INS_ID,                                        
				NULL,                                        
				NULL                         
                                            
         FROM PD_USEM A  
                INNER JOIN PD_ORDER_USEM B  
                ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDEr_NO = B.ORDER_NO AND A.REVISION = B.REVISION                             
                AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                             
                AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD =B.PROC_CD AND A.ITEM_CD = B.ITEM_CD                             
                INNER JOIN SAP_Z02MESF_P010_DTL C  
                ON A.PLANT_CD = C.WERKS AND A.ORDER_NO = C.MES_ORDER_NO --AND A.REVISION = C.MES_REVISION                             
                INNER JOIN SAP_Z02MESF_P010_USEM D  
                ON                             
                C.WERKS = D.WERKS AND C.AUFNR = D.AUFNR AND B.ITEM_CD = D.MATNR AND C.VORNR = D.VORNR                           
                INNER JOIN SAP_Z02MESF_P010_HDR E  
                ON C.WERKS = E.WERKS AND C.AUFNR = E.AUFNR                             
                INNER JOIN PD_RESULT F  
                ON                             
                A.DIV_CD = F.DIV_CD AND A.PLANT_CD = F.PLANT_CD AND A.ORDER_NO = F.ORDER_NO AND A.REVISION = F.REVISION                             
                AND A.ORDER_TYPE = F.ORDER_TYPE AND A.ORDER_FORM = F.ORDER_FORM AND A.ROUT_NO = F.ROUT_NO AND A.ROUT_VER = F.ROUT_VER                             
                AND A.WC_CD = F.WC_CD AND A.LINE_CD = F.LINE_CD AND A.PROC_CD = F.PROC_CD AND F.S_CHK = 'N' AND A.RESULT_SEQ = F.RESULT_SEQ                             
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO                             
                AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                             
                AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                             
               AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.USEM_SEQ = @IF_USEM_SEQ                          
                            
                IF NOT EXISTS(SELECT *FROM SAP_Z02MESF_P030 A WITH (NOLOCK)                             
                WHERE A.ZMESIFNO = @ZMESIFNO                            
                )                            
                BEGIN                             
                    SET @MSG_CD = '9999'                            
                    SET @MSG_DETAIL = 'SAP Interface 일반투입 소요량 정보가 생성되지 않았습니다. 관리자에게 문의하여 주십시오.'                            
                    RETURN 1                            
                END                             
                            
                UPDATE A SET A.ZMESIFNO = @ZMESIFNO                             
                    FROM PD_USEM A  
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                             
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                             
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                             
            AND A.USEM_SEQ = @IF_USEM_SEQ  AND A.ITEM_CD = @IF_ITEM_CD AND A.LOT_NO = @IF_LOT_NO                             
                                            
            END                             
                            
    END                             
                            
                            
                                    
    END                                        
    -- 마지막 공정이다.  실적 체크                             
     IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y'                          
     BEGIN                             
        IF @S_CHK <> 'Y'                             
        BEGIN                             
            SET @ZMESIFNO = ''                             
            EXEC USP_SAP_MESIFNO_CREATE @DIV_CD, @PLANT_CD, 'P060', @USER_ID, @ZMESIFNO OUT                                        
                            
            INSERT INTO SAP_Z02MESF_P060                            
            SELECT                             
             'MES'                            
            ,@ZMESIFNO                            
            ,C.WERKS                             
            ,C.AUFNR                            
            ,A.SIL_DT                             
            ,B.LOT_NO               
            ,''                             
            ,D.VERID                            
            ,B.ITEM_CD                             
            ,SUM(B.GOOD_QTY)                        
            ,CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END                     
            ,CASE WHEN ISNULL(E.ZLOT,0) = 0 THEN F.PALLET_QTY ELSE E.ZLOT END                     
        --    ,CASE WHEN CAST(ROUND(SUM(B.GOOD_QTY) / CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END, 0) AS INT) = 0 THEN 1                            
          --                  ELSE CAST(ROUND(SUM(B.GOOD_QTY) / CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END , 0) AS INT) END      
            ,COUNT(B.SEQ)        
            ,SUM(B.GOOD_QTY) - (COUNT(B.SEQ) - 1) * CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END AS FBAG                           
                      
            ,E.MEINS                            
            ,CASE WHEN ISNULL(A.J_CHK,'N') = 'J'                             
            THEN 'X' ELSE '' END                             
            ,dbo.UFNSR_GET_USER_NAME(a.DIV_CD, a.INSERT_ID)                                       
            ,'B'                            
            ,'','','','','','','','',NULL,NULL,GETDATE(),@USER_ID, NULL,NULL                            
            FROM PD_RESULT A  
            INNER JOIN PD_ITEM_IN B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD                             
            AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM                             
            AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = '*'                            
            AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                             
            INNER JOIN SAP_Z02MESF_P010_DTL C ON                             
            B.PLANT_CD = C.WERKS AND B.ORDER_NO = C.MES_ORDER_NO --AND B.REVISION = C.MES_REVISION                              
            INNER JOIN SAP_Z02MESF_P010_HDR D ON                             
            C.WERKS = D.WERKS AND B.ITEM_CD = D.MATNR AND C.AUFNR = D.AUFNR                             
            INNER JOIN SAP_Z02MESF_D010 E ON                             
            D.WERKS = E.WERKS AND D.MATNR = E.MATNR                       
            INNER JOIN V_ITEM F ON A.PLANT_CD = F.PLANT_CD AND A.ITEM_CD = F.ITEM_CD                           
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                             
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                             
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                             
            GROUP BY                             
             C.WERKS                             
            ,C.AUFNR                            
            ,A.SIL_DT               
            ,B.LOT_NO                            
            ,D.VERID                            
            ,B.ITEM_CD                             
            ,E.ZBAG                            
            ,E.ZLOT                            
            ,E.MEINS                            
            ,A.J_CHK                            
            ,A.DIV_CD, A.INSERT_ID                            
            ,F.SNP_QTY, F.PALLET_qTY                    
                            
            IF NOT EXISTS(SELECT *FROM SAP_Z02MESF_P060 A WITH (NOLOCK)                             
            WHERE A.ZMESIFNO = @ZMESIFNO                            
            )                            
            BEGIN                             
   SET @MSG_CD = '9999'                            
                SET @MSG_DETAIL = 'SAP Interface 포장량 정보가 생성되지 않았습니다. 관리자에게 문의하여 주십시오.'                            
                RETURN 1      
            END                  
                            
         UPDATE A SET A.ZMESIFNO = @ZMESIFNO                             
                FROM PD_RESULT A  
         WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                             
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                             
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                                     
        END                                    
    END        
                            
    -- 마이너스 수량이 들어오면 튕겨 낸다      
      
    IF EXISTS(SELECT *FROM PD_ITEM_IN A WITH (NOLOCK)       
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION       
    AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER       
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD       
    AND A.PROC_CD = CASE WHEN dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y' THEN '*' ELSE @PROC_CD END       
    AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ       
    AND A.GOOD_QTY < 0      
    )                       
    BEGIN       
        SET @MSG_CD = '9999'      
        SET @MSG_DETAIL = '음수 (-) 수량이 등록되었습니다. 관리자에게 문의하여 주십시오. '      
        RETURN 1      
    END       
      
    -- 25.03.13 ljw      
    -- 배정이 있으면 배정 정보를 PD_ITEM_IN 에 집어 넣어준다 필드는 DEPARTMENT      
      
    DECLARE @DEPARTMENT NVARCHAR(50) = ''       
      
    SET @DEPARTMENT = ISNULL((SELECT STUFF(      
    (SELECT ',' + RIGHT(A.REQ_DT,2) + '-' + dbo.LPAD(A.PLAN_SEQ, 3,0) + CASE WHEN ISNULL(A.BATCH_NO,'') = '' THEN '' ELSE '-' + CAST(A.BATCH_NO AS NVARCHAR) END FROM PD_USEM A WITH (NOLOCK)       
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO       
      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD       
      AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ       
      AND ISNULL(A.REQ_NO,'') <> ''      
    GROUP BY A.REQ_DT, A.PLAN_SEQ, A.BATCH_NO      
    FOR XML PATH('')),1,1,''      
    )),'')       
      
    UPDATE A SET A.DEPARTMENT = CASE WHEN TRIM(@DEPARTMENT) = '-000' THEN '' ELSE TRIM(@DEPARTMENT) END       
        FROM PD_ITEM_IN A    
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION       
      AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER       
      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ       
   
    --25.09.20 LJW    
    -- 마지막 공정일때 PD_ITEM 수량 기준으로 재고가 맞지 않으면 튕겨 낸다.    
  
    IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y'                              
    BEGIN                 
  
        IF NOT EXISTS(   
            SELECT A.ITEM_CD, A.LOT_NO, A.GOOD_QTY, SUM(B.GOOD_QTY) AS IN_QTY, SUM(C.BAG_SIZE) AS BAR_QTY, SUM(D.QTY) AS ST_QTY FROM PD_RESULT A WITH (NOLOCK)    
            LEFT JOIN PD_ITEM_IN B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION    
            AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD    
            AND A.LINE_CD = B.LINE_CD AND A.RESULT_SEQ = B.RESULT_SEQ AND B.PROC_CD = '*'   
            LEFT JOIN PALLET_MASTER C WITH (NOLOCK) ON B.ITEM_CD = C.ITEM_CD AND B.LOT_NO = C.LOT_NO AND B.BARCODE = C.BARCODE    
            LEFT JOIN ST_STOCK_NOW D WITH (NOLOCK) ON B.DIV_CD = D.DIV_CD AND B.PLANT_CD = D.PLANT_CD AND B.ITEM_CD = D.ITEM_CD AND B.LOT_NO = D.LOT_NO    
            AND B.WC_CD = D.WC_CD AND B.LINE_CD = D.LOCATION_NO AND B.PROC_CD = D.PROC_CD AND B.BARCODE = D.BARCODE AND D.SL_CD = '3000'   
               
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION       
            AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER       
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = @S_CHK AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ       
            GROUP BY A.ITEM_CD, A.LOT_NO, A.GOOD_QTY    
            HAVING    
                SUM(B.GOOD_QTY)  = SUM(C.BAG_SIZE)   
            AND SUM(B.GOOD_QTY)  = SUM(D.QTY)   
        )   
        BEGIN    
            SET @MSG_CD = '9999'      
            SET @MSG_DETAIL = '포장 수불, 재고, 팔레트 수량이 일치하지 않습니다. 종료할수 없습니다. 관리자에게 문의하여 주십시오.'     
            RETURN 1      
        END    
    END    
	 
	-----샘플 정보등록 
	DECLARE   @DC_QC_TYPE		NVARCHAR(15) 
			 ,@DC_LOT_SEQ		INT 
	 
	IF @PROC_CD = 'PA' OR @PROC_CD = 'CP' 
	BEGIN 
		SET @DC_QC_TYPE = 'CQC' 
	END 
	ELSE 
	BEGIN 
		SET @DC_QC_TYPE = 'PQC' 
	END 
	 
	SELECT @DC_LOT_SEQ = LOT_SEQ 
	FROM PD_RESULT (NOLOCK) 
	WHERE DIV_CD = @DIV_CD 
	  AND PLANT_CD = @PLANT_CD 
	  AND PROC_NO = @PROC_NO 
	  AND ORDER_NO = @ORDER_NO 
	  AND REVISION = @REVISION 
	  AND ORDER_TYPE = @ORDER_TYPE 
	  AND ORDER_FORM = @ORDER_FORM 
	  AND ROUT_NO = @ROUT_NO 
	  AND ROUT_VER = @ROUT_VER 
	  AND WC_CD = @WC_CD 
	  AND LINE_CD = @LINE_CD 
	  AND PROC_CD = @PROC_CD 
	  AND S_CHK = @S_CHK 
	  AND RESULT_SEQ = @RESULT_SEQ 
	 
	 
	IF ISNULL(@DC_LOT_SEQ,0) > 0 
	BEGIN 
		INSERT INTO QC_SAMPLE_REQUEST 
		( 
			 DIV_CD			,PLANT_CD			,QC_DT				,QC_CK 
			,QC_SEQ			,QC_SAMPLE_SEQ		,QC_TYPE			,REP_ITEM_CODE 
			,ITEM_CD		,QC_LOT_NO			,QC_LOT_SEQ			,PURPOSE_CD 
			,QC_QTY			,WC_CD				,LINE_CD			,PROC_CD 
			,ORDER_NO		,ORDER_SEQ			,RESULT_SEQ			,LOT_NO 
			,CAPA_CODE		,CAPA_NAME			,SAMPLING_TYPE		,SAMPLING_TYPE_NAME 
			,MP_TYPE		,MP_TYPE_NAME		,REMARK_NOTE		,SAMPLING_MST_SEQ 
			,SAMPLING_SEQ	,ActType_ApiAutoCreate 
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
			,C.SAMPLING_SEQ	,'U' 
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
		  AND A.QC_LOT_SEQ = @DC_LOT_SEQ 
		  AND B.IF_REQUEST_YN = 'Y' 
		 
		--샘플 마스터 업데이트 
		UPDATE QC_SAMPLE_MASTER 
		SET  PROC_NO = @PROC_NO 
			,ORDER_NO = @ORDER_NO 
			,REVISION = @REVISION 
			,ORDER_TYPE = @ORDER_TYPE 
			,ORDER_FORM = @ORDER_FORM 
			,ROUT_NO = @ROUT_NO 
			,ROUT_VER = @ROUT_VER 
			,WC_CD = @WC_CD 
			,LINE_CD = @LINE_CD 
			,PROC_CD = @PROC_CD 
			,S_CHK = @S_CHK 
			,RESULT_SEQ = @RESULT_SEQ 
			,LOT_NO = @LOT_NO 
			,ITEM_CD = @ITEM_CD 
			,UPDATE_DT = GETDATE() 
		WHERE DIV_CD = @DIV_CD 
		  AND PLANT_CD = @PLANT_CD 
		  AND LEFT(CONVERT(VARCHAR,QC_DT,23),7) = LEFT(CONVERT(VARCHAR,@SIL_DT,23),7) 
		  AND WC_CD = @WC_CD 
		  AND LINE_CD = @LINE_CD 
		  AND PROC_CD = @PROC_CD 
		  AND QC_LOT_SEQ = @DC_LOT_SEQ 
	END 
	-----샘플 정보등록 끝 
 
END TRY      
BEGIN CATCH                              
    SET @MSG_CD = '9999'                             
    SET @MSG_DETAIL = ERROR_MESSAGE()                              
    --SELECT @MSG_DETAIL                              
    RETURN 1                             
END CATCH 