/*  
기안번호 : PM250912007	  
기안구분 : 일반  
제목 : 실적 관련 모든 테이블 LOG 적재
일자 : 2025-09-17
작업자 : 임종원 이사  
*/    
          
             
-- 혼합투입시에 재공 선입선출                                   
ALTER PROC [dbo].[USP_POP_004_MAT_FIFO_SAVE](                                   
--DECLARE                                    
        @DIV_CD        NVARCHAR(10)   = '01'                                   
       ,@PLANT_CD      NVARCHAR(10)   = '1140'                                   
       ,@PROC_NO       NVARCHAR(50)   = 'OPL2312180005'                                   
       ,@ORDER_NO      NVARCHAr(50)   = 'PD231212003'                                   
       ,@REVISION      INT            = 2                                   
       ,@ORDER_TYPE    NVARCHAR(10)   = 'PP01'                                   
       ,@ORDER_FORM    NVARCHAR(10)   = '10'                                   
       ,@ROUT_NO       NVARCHAR(10)   = 'C01'                                   
       ,@ROUT_VER      INT            = 1                                   
       ,@WC_CD         NVARCHAr(10)   = '14GC'                                   
       ,@LINE_CD       NVARCHAR(10)   = '14G05C'                                   
       ,@PROC_CD       NVARCHAR(10)   = 'G'                                   
       ,@RESULT_SEQ    INT            = 1                                   
       ,@ITEM_CD       NVARCHAR(50)   = 'H004FB001'                                   
       ,@REQ_QTY       NUMERIC(18,4)  = '800'                                   
       ,@USER_ID       NVARCHAR(15)   = 'admin'                                   
                                   
       ,@BE_ORDER_NO   NVARCHAR(50)   = ''                                   
       ,@BE_REVISION   INT            = 0                                    
       ,@BE_RESULT_SEQ INT            = 0                                    
       ,@BE_PROC_CD    NVARCHAR(10)   = ''                                   
       ,@CHK           NVARCHAr(1)      -- 전구체, 리튬, 첨가제, 중입경, 소입경 구분해야 될것                                    
       ,@GBN           NVARCHAR(1)    = 'N'                                   
       ,@LOT_CHK       NVARCHAR(1)    = 'N'                                   
       ,@EX_EQP_CD     NVARCHAR(1)    = ''                        
       ,@EX_PROC       NVARCHAR(1)    = 'N'                        
       ,@MSG_CD        NVARCHAR(4)      OUTPUT                                    
       ,@MSG_DETAIL    NVARCHAR(MAX)    OUTPUT                                    
       ,@MASTER_LOT    NVARCHAR(50)     OUTPUT                                   
)                                   
AS                                    
                                   
SET NOCOUNT ON                                    
-- 해당 공정의 이전 투입 공정을 전부 찾자.                                    
                                   
BEGIN TRY                                
    DECLARE @UDI_DATE      NVARCHAR(20)  = ''  
    ,@UDI_SP        NVARCHAR(100) = 'USP_POP_004_MAT_FIFO_SAVE'  
    ,@UDI_REMARK    NVARCHAR(100) = 'FIFO 처리'      
                                   
    -- 해당 공정의 이전 투입 공정을 전부 찾자.                                    
 DECLARE @GROUP_ITEM NVARCHAR(50) = ''  -- 품종 정보를 가지고 온다.                                   
                                  
 SELECT @GROUP_ITEM = A.REP_ITEM_CD FROM V_ITEM A WITH (NOLOCK)                                   
 WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD                                   
                                  
 IF @GROUP_ITEM = ''                                   
 BEGIN                                   
    SET @MSG_CD = '9999'                                  
    SET @MSG_DETAIL = '대표품목이 정의되지 않았습니다. 관리자에게 문의하여 주십시오. 품목정보 : ' + @ITEM_CD                                   
    RETURN 1                                   
 END                                   
       -- 필요한 파라미터들 관리                                   
 DECLARE @IN_CHK        NVARCHAR(1)                                    
       ,@MIN_CHK        NVARCHAR(1)                                   
       ,@OUT_CHK        NVARCHAR(1)                             
       ,@GROUP_S        NVARCHAR(1)                                 
  ,@GROUP          NVARCHAR(1)          
       ,@GROUP_E        NVARCHAR(1)           
       ,@RETURN_LOT_NO  NVARCHAR(50) = '' -- 최종 리턴 LOT                            
     --  ,@MASTER_LOT    NVARCHAR(50) = ''                  
       ,@GROUP_LOT      NVARCHAR(50) = ''                             
       , @SU_QTY        NUMERIC(18,3) = 0                         
       , @GIN_QTY       NUMERIC(18,3) = 0                                   
       ,@LOSS_RATE      NUMERIC(18,3) = 100                                   
       ,@AP_CHK      NVARCHAR(1) = 'N'                           
       ,@J_VAL          NVARCHAR(10) = '%'                          
       ,@NS_CHK         NVARCHAR(1) = 'N'                 
                       
    -- FIFO 를 위한 재고 테이블                                   
    DECLARE @FIFO_TABLE TABLE (                                   
         ROWNUM         INT    --IDENTITY(1,1)                                    
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
    -- 이전 공정 리스트 (그룹시작, 중료 제외)                                   
    DECLARE @BE_PROC_TABLE AS TABLE (                                   
             CNT        INT IDENTITY(1,1)                                  
            ,PROC_CD    NVARCHAR(10)                                    
            ,PROC_SEQ   INT                                    
    )                                   
                                       
    -- 그룹시작 전체 공정 관리                                   
    DECLARE @PROC_RESULT_TBL TABLE (                                   
         CNT        INT IDENTITY(1,1)                                    
        ,ORDER_NO   NVARCHAR(50)                                    
        ,REVISION   INT                                    
        ,ROUT_NO    NVARCHAR(50)                                    
        ,ROUT_VER INT                                    
        ,WC_CD      NVARCHAR(10)                                    
        ,LINE_CD  NVARCHAR(10)                                    
        ,PROC_CD    NVARCHAR(10)                       
        ,RESULT_SEQ INT                                    
        ,GROUP_LOT  NVARCHAR(50)                                   
        ,LOSS_CHK   NVARCHAR(1)        
        ,AP_CHK     NVARCHAR(1)                                   
    )                                   
          
    SELECT @IN_CHK = A.IN_CHK, @MIN_CHK = A.MIN_CHK, @OUT_CHK = A.OUT_CHK, @GROUP_S = A.GROUP_S, @GROUP = dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),                                   
    @GROUP_E = A.GROUP_E, @AP_CHK = ISNULL(A.AP_CHK,'N'), @NS_CHK = ISNULL(A.NS_CHK,'N')                                  
    FROM PD_ORDER_PROC A WITH (NOLOCK)                             
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                                    
    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND                                    
    A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                   
                                  
                                   
    IF @IN_CHK = 'Y' AND @OUT_CHK = 'Y' AND @GROUP_S = 'N' AND @GROUP = 'N' AND @GROUP_E = 'N'                                    
    BEGIN                                                       
      RETURN 0                                  
                                  
    END                                   
--   SELECT @IN_CHK, @MIN_CHK, @OUT_CHK, @GROUP_S, @GROUP, @GROUP_E                                   
    IF @IN_CHK = 'N' AND @OUT_CHK = 'Y' AND @GROUP_S = 'N' AND @GROUP = 'N' AND @GROUP_E = 'N'                                    
    BEGIN                                    
        /*                                  
         IF EXISTS(SELECT                                   
     *FROM PD_USEM A WITH (NOLOCK)                                   
        INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD                                   
        AND B.REP_ITEM_CD = (SELECT REP_ITEM_CD FROM V_ITEM WITH (NOLOCK) WHERE PLANT_CD = @PLANT_CD AND ITEM_CD = @ITEM_CD)                                  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                                   
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD                                   
        AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                   
      )                                  
      BEGIN                                   
        SET @MSG_CD = '9999'                                  
        SET @MSG_DETAIL = '이미 등록되어 있습니다. 추후 프로그램 개선으로 수정 가능하게 변경 예정입니다. 재등록시 취소를 진행하십시오'                                  
        RETURN 1                                  
      END                                   
*/                                  
        -- 앞에 투입 공정을 찾는다. -- 이거 나중에 수정 해야 됩니다. 이상합니다.. ㅜㅜㅜ                                    
                                   
        INSERT INTO @BE_PROC_TABLE (PROC_CD, PROC_SEQ)                                   
        SELECT B.PROC_CD, B.PROC_SEQ  FROM PD_ORDER_PROC A WITH (NOLOCK)                                    
        INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON                                    
        A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDEr_NO AND A.REVISION = B.REVISION                                    
        AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                                    
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_SEQ > B.PROC_SEQ AND B.IN_CHK = 'Y' AND B.SKIP = 'N'  -- 24.08.12 LJW 추가 SKIP 부분              
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION                                    
                                   
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                                    
     AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                    
        ORDER BY B.PROC_SEQ                        
                                   
        INSERT INTO @FIFO_TABLE(                                    
                                   
            ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_RESULT_SEQ, BE_WC_CD, BE_LINE_CD, BE_PROC_CD                                   
        )                                   
                                       
        -- 해당 쿼리는 조회 화면 쿼리와 동일합니다. 수정이 필요하면, 해당 쿼리를 같이 수정 해야 됩니다.                                    
        -- 나중에 usem 에 들어갈수 있는 실적번호를 엮어야 합니다.                                    
    -- 이게 중요 할것 같음... 이 쿼리가 변경이 될수도 있는가? 확인할것..                                    
                                         
        SELECT ROW_NUMBER() OVER (ORDER BY B.IN_DATE, B.IN_SEQ), 'N', A.PROC_CD, A.ITEM_CD, A.LOT_NO,                                   
      B.QTY +                                    
        ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_IN AA WITH (NOLOCK)                                    
    	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO                                    
              AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                 
            AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                  
    	    ),0) -                                    
    	    ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_OUT AA WITH (NOLOCK)                                    
    	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND  AA.LOCATION_NO = A.LOCATION_NO                                    
              AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                                    
            AND AA.MOVE_TYPE IN ('SI','506','503','311','601')                                  
    	    ),0)                                        
        -                                   
        ISNULL((SELECT SUM(AA.USEM_QTY)                                   
            FROM PD_USEM AA WITH (NOLOCK)                                    
            WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.LINE_CD = B.LOCATION_NO AND AA.ITEM_CD = B.ITEM_CD AND AA.LOT_NO = B.LOT_NO                                    
        AND AA.WC_CD = A.WC_CD --AND AA.PROC_CD = @PROC_CD                                   
              AND AA.BE_ORDER_NO = B.ORDER_NO AND AA.BE_REVISION = B.ORDER_SEQ AND AA.BE_RESULT_SEQ = B.RESULTS_SEQ AND AA.BE_PROC_CD = B.PROC_CD                                   
                                   
        ),0)                                   
        AS QTY,                                    
                                          
        B.ORDER_NO,                                   
        B.ORDER_SEQ,                                    
        B.RESULTS_SEQ,                                    
     B.WC_CD,                                    
        B.LOCATION_NO,                                   
        B.PROC_CD          
                                          
        FROM ST_STOCK_NOW A WITH (NOLOCK)                                    
        INNER JOIN ST_ITEM_IN B WITH (NOLOCK) ON                                    
     A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.PROC_CD = B.PROC_CD            
        AND A.LOCATION_NO = B.LOCATION_NO AND B.MOVE_TYPE IN ('PR', '201') --AND B.ORDER_NO = @ORDER_NO AND B.ORDER_SEQ = @REVISION                                    
        INNER JOIN V_ITEM B1 WITH (NOLOCK) ON B.PLANT_CD = B1.PLANT_CD AND  B.ITEM_CD = B1.ITEM_CD                                    
        INNER JOIN BA_SUB_CD B2 WITH (NOLOCK) ON B1.BASE_ITEM_CD = B2.SUB_CD AND B2.MAIN_CD = 'BA206'                                   
                                          
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.PROC_CD IN (SELECT PROC_CD FROM @BE_PROC_TABLE) AND A.LOCATION_NO = @LINE_CD AND  A.QTY > 0                                   
          --AND A.ITEM_CD = @ITEM_CD                                   
 AND B1.REP_ITEM_CD = @GROUP_ITEM                                   
          AND A.RACK_CD = '*'                                  
          AND A.SL_CD = '3000'                                  
            
        ORDER BY B.IN_DATE, B.IN_SEQ                                  
                                   
  -- FIFO 를 진행합니다.                                   
                                          
        INSERT INTO @BACK_TABLE                            
        SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                                   
     AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                                   
        FROM (                                   
            SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                                   
       CASE WHEN (@REQ_QTY - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                                   
            ELSE (Z.SUMQTY - @REQ_QTY) - Z.CURQTY   END  AS QTY                                    
            , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                                   
            FROM (                                   
            SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                    
            (SELECT SUM(W.CURQTY) FROM @FIFO_TABLE W WHERE W.ROWNUM <= Q.ROWNUM  AND W.CURQTY > 0) SUMQTY,                                   
            Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                                   
            FROM @FIFO_TABLE Q) Z                                   
            WHERE CASE WHEN (@REQ_QTY - Z.SUMQTY) >= 0 THEN Z.CURQTY                                    
     ELSE Z.CURQTY - (Z.SUMQTY - @REQ_QTY) END  > 0                                   
        ) AA                                   
                                   
        -- 수량이 안맞으면 튕겨내야 된다.                                    
        IF @REQ_QTY <> ISNULL((SELECT SUM(QTY) FROM @BACK_TABLE),0)                                   
        BEGIN                                    
            SET @MSG_CD = '9999'                                   
            SET @MSG_DETAIL = '등록 수량대비 재공 수량이 부족합니다. 재공수량 확인이 필요합니다.' + char(10) + '대표품목 : ' + @GROUP_ITEM                                  
           -- SELECT @MSG_DETAIL                                    
            RETURN 1                                   
END                                   
        ELSE                                    
        BEGIN                                    
            -- PD_USEM 에 INSERT 를 합니다.                                    
            SET @MASTER_LOT = ''                   
 /*                                  
            SELECT TOP 1 @MASTER_LOT = LOT_NO                                   
                FROM @BACK_TABLE                           
            ORDER BY QTY DESC, CNT ASC         
*/                                  
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
                 INSERT_DT,           UPDATE_ID,          UPDATE_DT,               ITEM_TYPE,                                   
                 BE_ORDER_NO, BE_REVISION,           BE_RESULT_SEQ,           BE_PROC_CD                                   
                                                 
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
                                   
        END                                     
     END                                   
                                   
     IF @OUT_CHK = 'Y' AND @GROUP_E = 'Y'                    
     BEGIN                                    
                                        
        DECLARE @BE_PROC_INFO NVARCHAR(100) = ''                                    
        ,@CNT          INT = 0                    
               ,@BE_WC_CD     NVARCHAR(10) = ''                                   
               ,@BE_SEQ       INT = 0                                   
               ,@SIL_PROC_CD  NVARCHAR(10) = ''                                   
        ,@SIL_LINE_CD  NVARCHAR(10) = ''                                   
           --    ,@BE_PROC_CD   NVARCHAR(10) = ''                                                      
        -- 이정 공정의 정보를 가지고 온다. 그룹시작 공정을 찾아야 된다. (작업장/공정/공정순번) -> SPLIT 를 해서 각 변수에 집어 넣어준다.                                   
        -- 24.01.19                                    
        -- 여기서 부터 다시 생각하자                                   
        -- 1. 현재 프로세스                                   
        --    (1) 전에 실적 공정을 가지고 온다음에,         
        --    (2) 선입선출 리스트를 가지고 오고                                   
        --    (3) 적용 공정을 가지고  온다음                                   
        --    (4) 첫번째 공정은 감량율 계산하여 소분을 제외한 나머지 재고들만 처리                                    
        --    (5) 이후 공정은 소분 포함한 공정들로 모두 처리 한다.                                   
                              
        -- 2. 수정된 프로세스는?                                   
        --    (1) 그룹안에 투입공정이 있는가?                                   
        --    (2) 없으면 그대로 처리                                   
--    (3) 있으면?                                   
        --    (4) 현재 탱크가 투입인가? 혼합인가?                                   
        --    (5) 혼한일경우                                    
        --  (6) 전에 실적 공정을 가지고 온다음에                                   
        --    (7) 선입선출 리스트를 가지고 온다. -> 여기가 중요한것 같음..                                    
        --    그뒤에는 공통으로 가지고 가도 되는것 아닌가..                                   
    --    체킹하자..                                    
                                   
        -- 일단 현 그룹 안에 투입 공정이 있는가? 를 판단한다.                                   
        -- 그리고 현재 품목이 투입공정인가?                       
                                           
        -- 현재 파라미터가 투입공정 품목인가를 확인한다. 지르코늄도 생각을 해야 된다.                                    
              
--        SET @GBN = 'N'                                   
  --      SET @REQ_QTY = '200'                                   
--        SET @ITEM_CD = 'RL20012'                                   
                                  
                                  
       DECLARE  @BACKUP_QTY NUMERIC(18,0) = 0                             
               ,@BACKUP_ITEM NVARCHAR(50) = ''                     
                                   
        IF @GBN IN ('G')                                   
        BEGIN                                    
            IF @GBN = 'G'                                    
            BEGIN                                    
                -- 투입공정 재공 처리                                    
                IF NOT EXISTS(SELECT *FROM PD_USEM A WITH (NOLOCK)                                    
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                                    
                AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                    
                AND A.RESULT_SEQ = @RESULT_SEQ                                   
                AND A.ITEM_CD = @ITEM_CD                                    
       )                                   
                BEGIN                                    
                                   
                    INSERT INTO @FIFO_TABLE (                                   
                        ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_WC_CD, BE_LINE_CD, BE_PROC_CD, BE_RESULT_SEQ                                   
                    )                                   
                    SELECT ROW_NUMBER() OVER (ORDER BY D.IN_DATE, D.IN_SEQ) AS CNT, 'G' AS GBN, A.PROC_CD, C.ITEM_CD, C.LOT_NO,                
                    D.QTY-- AS QTY,          
         
                    -- 수량 체크          
         
                    + ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_IN AA WITH (NOLOCK)                                        
                    WHERE AA.DIV_CD = C.DIV_CD AND AA.PLANT_CD = C.PLANT_CD AND AA.ITEM_CD = C.ITEM_CD AND AA.LOT_NO = C.LOT_NO AND AA.WC_CD = C.WC_CD AND AA.PROC_CD = C.PROC_CD AND AA.LOCATION_NO = C.LOCATION_NO                                          
 
                    AND AA.ORDER_NO = D.ORDER_NO AND AA.ORDER_SEQ = D.ORDER_SEQ AND AA.RESULTS_SEQ = D.RESULTS_SEQ                                    
                    AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                                         
                    ),0)          
                    -                                          
                    ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_OUT AA WITH (NOLOCK)                                        
                    WHERE AA.DIV_CD = C.DIV_CD AND AA.PLANT_CD = C.PLANT_CD AND AA.ITEM_CD = C.ITEM_CD AND AA.LOT_NO = C.LOT_NO AND AA.WC_CD = C.WC_CD AND AA.PROC_CD = C.PROC_CD AND AA.LOCATION_NO = C.LOCATION_NO                                          
                    AND AA.ORDER_NO = D.ORDER_NO AND AA.ORDER_SEQ = D.ORDER_SEQ AND AA.RESULTS_SEQ = D.RESULTS_SEQ                                          
                    AND AA.MOVE_TYPE IN ('SI','506','503','311','601')                                        
                    ),0)                          
                    -                                         
                    ISNULL((SELECT SUM(AA.USEM_QTY)                                         
                    FROM PD_USEM AA WITH (NOLOCK)                                  
                    WHERE AA.DIV_CD = C.DIV_CD AND AA.PLANT_CD = C.PLANT_CD AND AA.WC_CD = C.WC_CD AND AA.LINE_CD = C.LOCATION_NO AND AA.ITEM_CD = C.ITEM_CD AND AA.LOT_NO = C.LOT_NO             
                    --AND AA.LINE_CD = @LINE_CD           
                    --AND AA.PROC_CD = @PROC_CD -- 24.08.12 LJW 삭제            
                    AND AA.BE_ORDER_NO = D.ORDER_NO AND AA.BE_REVISION = D.ORDER_SEQ AND AA.BE_RESULT_SEQ = D.RESULTS_SEQ AND AA.BE_PROC_CD = D.PROC_CD                     
         
                    ),0) AS QTY ,                
                    D.ORDER_NO,                                   
                    D.ORDER_SEQ AS REVISION,                                    
                    D.WC_CD,                                    
                    D.LOCATION_NO AS LINE_CD,                                   
                    D.PROC_CD,                                   
                    D.RESULTS_SEQ AS RESULT_SEQ                                   
                                                       
                      FROM PD_ORDER_PROC A WITH (NOLOCK)                                   
                      INNER JOIN PD_ORDER B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.PROC_NO = B.PROC_NO                                    
                      AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD                                    
         INNER JOIN PD_ORDER_PROC B1 WITH (NOLOCK) ON B.DIV_CD = B1.DIV_CD AND B.PLANT_CD = B1.PLANT_CD AND B.PROC_NO = B1.PROC_NO                                                      
                      INNER JOIN ST_STOCK_NOW C WITH (NOLOCK) ON B1.DIV_CD = C.DIV_CD AND B1.PLANT_CD = C.PLANT_CD AND C.SL_CD = '3000'                                    
               AND B1.WC_CD = C.WC_CD AND B1.PROC_CD = C.PROC_CD AND B1.LINE_CD = C.LOCATION_NO AND C.RACK_CD = '*' AND C.QTY > 0 --AND C.ITEM_CD = @ITEM_CD                               
                      AND C.RACK_CD = '*'                                  
                      INNER JOIN ST_ITEM_IN D WITH (NOLOCK) ON          
                      C.DIV_CD = D.DIV_CD AND C.PLANT_CD = D.PLANT_CD AND C.ITEM_CD = D.ITEM_CD AND C.LOT_NO = D.LOT_NO AND C.WC_CD = D.WC_CD          
                      AND C.PROC_CD = D.PROC_CD AND C.LOCATION_NO = D.LOCATION_NO AND D.MOVE_TYPE NOT IN ('SR','SI','506','503','311','601')         
         
                            
                      /*         
                      CROSS APPLY (SELECT TOP 1 *                                   
                      FROM ST_ITEM_IN D WITH (NOLOCK) WHERE D.DIV_CD = C.DIV_CD AND D.PLANT_CD = C.PLANT_CD AND D.ITEM_CD = C.ITEM_CD AND D.LOT_NO = C.LOT_NO AND         
                      D.WC_CD = C.WC_CD AND  D.SL_CD = C.SL_CD AND D.PROC_CD = C.PROC_CD AND D.LOCATION_NO = C.LOCATION_NO AND D.MOVE_TYPE NOT IN ('SR','SI','506','311','601')                                   
                      ORDER BY D.IN_DATE DESC, D.IN_SEQ DESC                                    
                      ) D                
                      */          
                      INNER JOIN V_ITEM E WITH (NOLOCK) ON B.PLANT_CD = E.PLANT_CD AND C.ITEM_CD = E.ITEM_CD AND E.REP_ITEM_CD = @GROUP_ITEM                                   
                      INNER JOIN BA_SUB_CD F WITH (NOLOCK) ON E.BASE_ITEM_CD = F.SUB_CD AND F.MAIN_CD = 'BA206'                                   
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE                                    
                    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                   
                    AND B1.IN_CHK = 'Y' AND dbo.UFNR_GET_GROUP(B1.DIV_CD, B1.PLANT_CD, B1.ORDER_NO, B1.REVISION, B1.PROC_CD, 'N') = 'Y'                                   
                                                       
                    ORDER BY D.IN_DATE ASC, D.IN_SEQ ASC             
         
         
                    INSERT INTO @BACK_TABLE                                    
                    SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                                   
                    AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                                   
                    FROM (                                   
                        SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                                   
                        CASE WHEN (@REQ_QTY - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                                   
                        ELSE (Z.SUMQTY - @REQ_QTY) - Z.CURQTY   END  AS QTY                                    
                      , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                                   
                        FROM (                                   
                        SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                    
                        (SELECT SUM(W.CURQTY) FROM @FIFO_TABLE W WHERE W.ROWNUM <= Q.ROWNUM  ) SUMQTY,                                   
                     Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                                   
                        FROM @FIFO_TABLE Q) Z                                   
                        WHERE CASE WHEN (@REQ_QTY - Z.SUMQTY) >= 0 THEN Z.CURQTY                                    
                        ELSE Z.CURQTY - (Z.SUMQTY - @REQ_QTY) END  > 0                                   
                    ) AA                                   
         
         
                    -- 수량이 안맞으면 튕겨내야 된다.                                    
                    IF @REQ_QTY <> ISNULL((SELECT SUM(QTY) FROM @BACK_TABLE),0)                                   
 BEGIN                                    
                        SET @MSG_CD = '9999'                                   
                        SET @MSG_DETAIL = '등록 수량대비 재공 수량이 부족합니다. 재공수량 확인이 필요합니다.' + char(10) + '대표품목 : ' + @GROUP_ITEM                                  
                      --  SELECT @MSG_DETAIL                                    
                        RETURN 1                                 
                    END                                   
                    ELSE                                    
                    BEGIN                                    
                        -- PD_USEM 에 INSERT 를 합니다.                                    
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
                             PLC_QTY,             USEM_QTY,              DEL_FLG,       REWORK_FLG,              INSERT_ID,                        
                             INSERT_DT,           UPDATE_ID,             UPDATE_DT,               ITEM_TYPE,               IN_GBN,                                   
                             BE_ORDER_NO,         BE_REVISION,           BE_RESULT_SEQ,           BE_PROC_CD                                   
                                                             
                        )                             
                                   
                        SELECT                                    
                             @DIV_CD,             @PLANT_CD,      @PROC_NO,                @ORDEr_NO,               @REVISION,  
                             @ORDER_TYPE,         @ORDER_FORM,           @ROUT_NO,                @ROUT_VER,               @WC_CD,                                    
                              @LINE_CD,            @PROC_CD,              @RESULT_SEQ,                                                
                             ISNULL((SELECT MAX(Z.USEM_SEQ) FROM PD_USEM Z WITH (NOLOCK)                                    
                  WHERE Z.DIV_CD = @DIV_CD AND Z.PLANT_CD = @PLANT_CD AND Z.ORDER_NO = @ORDER_NO AND Z.REVISION = @REVISION AND Z.ORDER_TYPE = @ORDER_TYPE                                    
                             AND Z.ORDER_FORM = @ORDER_FORM AND Z.ROUT_NO = @ROUT_NO AND Z.ROUT_VER = @ROUT_VER AND Z.WC_CD = @WC_CD AND Z.LINE_CD = @LINE_CD AND Z.PROC_CD = @PROC_CD AND Z.RESULT_SEQ = @RESULT_SEQ),0)                                   
                             + A.CNT,                                   
                             A.BE_WC_CD,          A.BE_PROC_CD,                                    
                             A.ITEM_CD,            '3000',                A.BE_LINE_CD,                '*',                     A.LOT_NO,                                    
                             @MASTER_LOT,                                    
                             A.QTY,               A.QTY,                 'N',                     'N',                     @USER_ID,                                    
                             GETDATE(),           @USER_ID,              GETDATe(),               'J',                     'G',                  
                             A.BE_ORDER_NO, A.BE_REVISION,         A.BE_RESULT_SEQ,         A.BE_PROC_CD                                   
                        FROM @BACK_TABLE A                                   
                    END                                    
                                   
                END                                    
                                   
         RETURN 0                                    
            END                                    
        END                                    
                                    
        SELECT @BE_PROC_INFO = dbo.UFNR_GET_GROUP(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD, 'Y')                                  
                                  
                                        
        WHILE CHARINDEX('/', @BE_PROC_INFO) <> 0                                    
       BEGIN                                    
            SET @CNT = @CNT + 1                                   
                                   
            IF @CNT = 1                                   
            BEGIN                                    
                SET @BE_WC_CD = ISNULL(SUBSTRING(@BE_PROC_INFO,0,CHARINDEX('/',@BE_PROC_INFO)),'')                                    
            END                                 
                   
            IF @CNT = 2                                   
            BEGIN                                    
                SET @BE_PROC_CD = ISNULL(SUBSTRING(@BE_PROC_INFO,0,CHARINDEX('/',@BE_PROC_INFO)),'')                                    
                SET @BE_SEQ =  ISNULL(SUBSTRING(@BE_PROC_INFO,CHARINDEX('/',@BE_PROC_INFO) + 1, LEN(@BE_PROC_INFO)),0)                                   
                                   
            END                                    
                                   
        SET @BE_PROC_INFO = SUBSTRING(@BE_PROC_INFO,CHARINDEX('/',@BE_PROC_INFO) + 1, LEN(@BE_PROC_INFO))                                   
                                   
        END                                    
                                           
       -- SELECT @BE_WC_CD, @BE_PROC_CD, @BE_SEQ                                    
        
                                           
        -- 파악한 작업 그룹 시작 공정에서 이 앞의 실적 공정을 찾아야 된다.                                            
        SELECT TOP 1 @SIL_PROC_CD = A.PROC_CD, @SIL_LINE_CD = A.LINE_CD                                   
            FROM PD_ORDER_PROC A WITH (NOLOCK)                                   
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                        
          --AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                                    
          AND A.WC_CD = @BE_WC_CD AND A.PROC_SEQ < @BE_SEQ AND A.OUT_CHK = 'Y'                                   
        ORDER BY A.PROC_SEQ DESC                                    
                                   
        -- 재고 현황을 파악 한다.                                    
        -- 이거 다시 만들어야 댐.. 젠장...                                   
        -- 진짜 다시 만들어야 된다... 24.01.19 무조건 다음주 월요일까지 검증한다.      
        -- GROUP_LOT 를 가지고 온다.                                   
                                           
 -- 만약에.. 앞에 공정 실적에 설비가 선택이 되어 있으면,                                   
        -- 해당 설비의 재고만 가지고 오자..                                   
        -- 일단 이번 SEQ 에서 그룹시작인 설비를 가지고 오고                  
        -- 그게 TP 에 있으면, TP                                   
                                  
        DECLARE @GROUP_EQP_CD  NVARCHAR(20) = ''                                  
        ,@GROUP_PROC_CD NVARCHAR(20) = ''                                  
                        
        SELECT TOP 1 @GROUP_EQP_CD = ISNULL(B.EQP_CD,''), @GROUP_PROC_CD = ISNULL(B.PROC_CD,'')                      
        FROM PD_RESULT A WITH (NOLOCK)                                   
        INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO AND A.GROUP_LOT = B.GROUP_LOT                      
     AND A.PROC_CD <> B.PROC_CD                                   
        INNER JOIN PD_ORDER_PROC C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION                                   
        AND B.PROC_NO = C.PROC_NO AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER AND B.WC_CD = C.WC_CD                             
        AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD                                   
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                                   
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                               
        ORDER BY C.PROC_SEQ ASC                                   
                                          
        IF NOT EXISTS(                                  
        SELECT *FROM BA_EQP A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @GROUP_PROC_CD AND A.TP = @GROUP_EQP_CD                                  
        )                                  
        BEGIN                         
          SET @GROUP_EQP_CD = '%'                                  
        END                                   
                             
        -- 아 이거 예상 LOT 에서 처리 되는것 때문에 이렇게 되는구나..                         
        IF ISNULL(@EX_EQP_CD,'') = '' AND @EX_PROC = 'Y'                       
        BEGIN                                  
          SET @GROUP_EQP_CD = @EX_EQP_CD                        
        END               
        
--        SELECT @SIL_PROC_CD                  
        IF @WC_CD NOT IN ('13P', '14P','13R')        
        BEGIN         
          INSERT INTO @FIFO_TABLE(                                    
            ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_WC_CD, BE_LINE_CD, BE_PROC_CD, BE_RESULT_SEQ, EQP_CD                                  
                                               
          )                                   
                                  
          SELECT ROW_NUMBER() OVER (ORDER BY B.IN_DATE, B.IN_SEQ), 'N', A.PROC_CD, A.ITEM_CD, A.LOT_NO,                                   
          B.QTY +                                    
            ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_IN AA WITH (NOLOCK)     
      	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO                                    
             --   AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                                    
          AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                              
      	    ),0) -                                    
      	    ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_OUT AA WITH (NOLOCK)                                    
      	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND  AA.LOCATION_NO = A.LOCATION_NO                                    
             --   AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                                            
                AND AA.MOVE_TYPE IN ('SI','506','503','311','601')                                  
      	    ),0)                                        
           -                            
          ISNULL((SELECT SUM(AA.USEM_QTY)                                   
              FROM PD_USEM AA WITH (NOLOCK)                                    
              WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.LINE_CD = B.LOCATION_NO AND AA.ITEM_CD = B.ITEM_CD AND AA.LOT_NO = B.LOT_NO                                    
                AND AA.USEM_WC = A.WC_CD AND AA.PROC_CD = @BE_PROC_CD    -- 24.08.12 없애기 LJW                                
                AND AA.BE_ORDER_NO = B.ORDER_NO AND AA.BE_REVISION = B.ORDER_SEQ AND AA.BE_RESULT_SEQ = B.RESULTS_SEQ AND AA.BE_PROC_CD = B.PROC_CD                              
                                     
          ),0)                                   
          AS QTY,                            
                                     
          B.ORDER_NO,                                   
          B.ORDER_SEQ,                                    
          B.WC_CD,                               
          B.LOCATION_NO,                                    
          B.PROC_CD,                                   
          B.RESULTS_SEQ,                                  
          C.EQP_CD                                  
          FROM ST_STOCK_NOW A WITH (NOLOCK)                                    
              INNER JOIN ST_ITEM_IN B WITH (NOLOCK) ON                            
              A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.PROC_CD = B.PROC_CD                                   
              AND A.LOCATION_NO = B.LOCATION_NO AND B.MOVE_TYPE IN ('PR','201') --AND B.ORDER_NO = @ORDER_NO AND B.ORDER_SEQ = @REVISION                                    
              INNER JOIN V_ITEM B1 WITH (NOLOCK) ON B.PLANT_CD = B1.PLANT_CD AND  B.ITEM_CD = B1.ITEM_CD                
              INNER JOIN BA_SUB_CD B2 WITH (NOLOCK) ON B1.BASE_ITEM_CD = B2.SUB_CD AND B2.MAIN_CD = 'BA206'                                   
              LEFT JOIN PD_RESULT C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.WC_CD = C.WC_CD AND B.LOCATION_NO = C.LINE_CD AND B.PROC_CD = C.PROC_CD                                   
              AND B.ITEM_CD = C.ITEM_CD AND B.LOT_NO = C.LOT_NO AND B.ORDER_NO = C.ORDER_NO AND B.ORDER_SEQ = C.REVISION AND B.RESULTS_SEQ = C.RESULT_SEQ                                   
              AND C.EQP_CD LIKE '%' + @GROUP_EQP_CD + '%'                     
                                    
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @BE_WC_CD AND A.PROC_CD = @SIL_PROC_CD AND A.LOCATION_NO = @SIL_LINE_CD AND  A.QTY > 0                                   
           --     AND A.ITEM_CD = @ITEM_CD                                    
              AND A.RACK_CD = '*'                    
             -- AND A.PROC_CD <> '*'                      
              AND ISNULL(C.EQP_CD,'%') LIKE '%' + @GROUP_EQP_CD + '%'                                   
          ORDER BY B.IN_DATE, B.IN_SEQ                                   
        END        
        ELSE -- 첨가제 분쇄는 재고현황을 다르게 가지고 가야 된다.         
        BEGIN        
                
          INSERT INTO @FIFO_TABLE(                                    
            ROWNUM, GBN, PROC_CD, ITEM_CD, LOT_NO, CURQTY, BE_ORDER_NO, BE_REVISION, BE_WC_CD, BE_LINE_CD, BE_PROC_CD, BE_RESULT_SEQ, EQP_CD                                  
                                               
          )                                   
          SELECT ROW_NUMBER() OVER (ORDER BY B.IN_DATE, B.IN_SEQ), 'N', A.PROC_CD, A.ITEM_CD, A.LOT_NO,                                   
          B.QTY +                                    
            ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_IN AA WITH (NOLOCK)                                    
      	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND AA.LOCATION_NO = A.LOCATION_NO                                    
                AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                                    
          AND AA.MOVE_TYPE IN ('SR','506','503','311','601')                               
      	    ),0) -                                    
      	    ISNULL((SELECT SUM(AA.QTY) FROM ST_ITEM_OUT AA WITH (NOLOCK)                                    
      	    WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.ITEM_CD = A.ITEM_CD AND AA.LOT_NO = A.LOT_NO AND AA.PROC_CD = A.PROC_CD AND  AA.LOCATION_NO = A.LOCATION_NO                                    
                AND AA.ORDER_NO = B.ORDER_NO AND AA.ORDER_SEQ = B.ORDER_SEQ AND AA.RESULTS_SEQ = B.RESULTS_SEQ                                              
                AND AA.MOVE_TYPE IN ('SI','506','503','311','601')                                  
      	    ),0)                                 
           -                            
          ISNULL((SELECT SUM(AA.USEM_QTY)                                   
              FROM PD_USEM AA WITH (NOLOCK)                                    
              WHERE AA.DIV_CD = B.DIV_CD AND AA.PLANT_CD = B.PLANT_CD AND AA.LINE_CD = B.LOCATION_NO AND AA.ITEM_CD = B.ITEM_CD AND AA.LOT_NO = B.LOT_NO                                    
                AND AA.USEM_WC = A.WC_CD AND AA.PROC_CD = @BE_PROC_CD    -- 24.08.12 없애기 LJW                                
                AND AA.BE_ORDER_NO = B.ORDER_NO AND AA.BE_REVISION = B.ORDER_SEQ AND AA.BE_RESULT_SEQ = B.RESULTS_SEQ AND AA.BE_PROC_CD = B.PROC_CD                              
                                     
          ),0)                                   
          AS QTY,                                    
                                     
          B.ORDER_NO,                                   
          B.ORDER_SEQ,                                    
          B.WC_CD,                               
          B.LOCATION_NO,                                    
          B.PROC_CD,                                   
          B.RESULTS_SEQ,                                  
          C.EQP_CD                                  
          FROM ST_STOCK_NOW A WITH (NOLOCK)                                    
              INNER JOIN ST_ITEM_IN B WITH (NOLOCK) ON                                    
              A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND A.LOT_NO = B.LOT_NO AND A.WC_CD = B.WC_CD AND A.PROC_CD = B.PROC_CD                                   
              AND A.LOCATION_NO = B.LOCATION_NO AND B.MOVE_TYPE IN ('PR','201') --AND B.ORDER_NO = @ORDER_NO AND B.ORDER_SEQ = @REVISION                                    
              AND B.ORDER_NO <> 'PD241230005'         
              INNER JOIN V_ITEM B1 WITH (NOLOCK) ON B.PLANT_CD = B1.PLANT_CD AND  B.ITEM_CD = B1.ITEM_CD                                    
              INNER JOIN BA_SUB_CD B2 WITH (NOLOCK) ON B1.BASE_ITEM_CD = B2.SUB_CD AND B2.MAIN_CD = 'BA206'                                   
              LEFT JOIN PD_RESULT C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.WC_CD = C.WC_CD AND B.LOCATION_NO = C.LINE_CD AND B.PROC_CD = C.PROC_CD                                   
              AND B.ITEM_CD = C.ITEM_CD AND B.LOT_NO = C.LOT_NO AND B.ORDER_NO = C.ORDER_NO AND B.ORDER_SEQ = C.REVISION AND B.RESULTS_SEQ = C.RESULT_SEQ                                   
              AND C.EQP_CD LIKE '%' + @GROUP_EQP_CD + '%'                     
                                    
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @BE_WC_CD AND A.PROC_CD = @SIL_PROC_CD AND A.LOCATION_NO = @SIL_LINE_CD AND  A.QTY > 0                                   
           --     AND A.ITEM_CD = @ITEM_CD                                    
              AND A.RACK_CD = '*'                    
             -- AND A.PROC_CD <> '*'                      
              AND ISNULL(C.EQP_CD,'%') LIKE '%' + @GROUP_EQP_CD + '%'                                   
          ORDER BY B.IN_DATE, B.IN_SEQ                                   
        END                          
                                   
      --  SELECT *FROM @FIFO_TABLE                                   
      --  RETURN                                 
--      SELECT @BE_WC_CD, @SIL_PROC_CD, @SIL_LINE_CD                                    
                                   
        -- 중간에 소분이 있는지를 먼저 체크한후 전체 수량을 조정한다. 감량율 체킹해야 됩니다.                                   
        -- 선입선출시에 수량은 그대로 가지고 간다.                                    
                                   
        -- 소분 투입수량을 가지고 온다.                                    
        -- 내보다 밑의 채번을 가지고 오자..                         
                        
        SELECT @SU_QTY = ISNULL((SELECT SUM(ISNULL(C.USEM_QTY,0)) AS USEM_QTY                                   
        FROM PD_RESULT A WITH (NOLOCK)                                    
        INNER JOIN PD_ORDER_PROC A1 WITH (NOLOCK) ON                         
        A.DIV_CD = A1.DIV_CD AND A.PLANT_CD = A1.PLANT_CD AND A.ORDER_NO = A1.ORDER_NO AND A.REVISION = A1.REVISION                         
        AND A.ORDER_TYPE = A1.ORDER_TYPE AND A.ORDER_FORM = A1.ORDER_FORM AND A.ROUT_NO = A1.ROUT_NO AND A.ROUT_VER = A1.ROUT_VER                         
        AND A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD                         
                        
        INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE                                   
        AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD --AND A.PROC_CD <> B.PROC_CD                                    
        AND B.S_CHK = 'N' AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT                                    
    INNER JOIN PD_ORDER_PROC B1 WITH (NOLOCK) ON                         
        B.DIV_CD = B1.DIV_CD AND B.PLANT_CD = B1.PLANT_CD AND B.ORDER_NO = B1.ORDER_NO AND B.REVISION = B1.REVISION                         
        AND B.ORDER_TYPE = B1.ORDER_TYPE AND B.ORDER_FORM = B1.ORDER_FORM AND B.ROUT_NO = B1.ROUT_NO AND B.ROUT_VER = B1.ROUT_VER                         
        AND B.WC_CD = B1.WC_CD AND B.LINE_CD = B1.LINE_CD AND B.PROC_CD = B1.PROC_CD AND A1.GROUP_SEQ >= B1.GROUP_SEQ                         
                        
        INNER JOIN PD_USEM C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION AND B.ORDER_TYPE = C.ORDER_TYPE                                
        AND B.ORDER_FORM  = C.ORDER_FORM AND B.ROUT_NO =  C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD AND                                    
        C.IN_GBN IN ('SU') AND C.USE_CHK = 'N' AND B.RESULT_SEQ = C.RESULT_SEQ                                    
                                           
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                                    
   AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                                    
       ),0)                                   
                                           
        IF @SU_QTY > 0                                    
        BEGIN                                    
            -- 소분 투입 내역에서 실적에 사용되었다는것을 UPDATE 하자                                   
            -- USE_CHK 필드를 Y 로한다.                                   
            -- 이거 나중에 실적 삭제할때도 다시 N 으로 돌려줘야 된다.                                    
            UPDATE C SET C.USE_CHK = 'Y'                                   
            FROM PD_RESULT A WITH (NOLOCK)                                    
            INNER JOIN PD_ORDER_PROC A1 WITH (NOLOCK) ON                         
            A.DIV_CD = A1.DIV_CD AND A.PLANT_CD = A1.PLANT_CD AND A.ORDER_NO = A1.ORDER_NO AND A.REVISION = A1.REVISION                         
            AND A.ORDER_TYPE = A1.ORDER_TYPE AND A.ORDER_FORM = A1.ORDER_FORM AND A.ROUT_NO = A1.ROUT_NO AND A.ROUT_VER = A1.ROUT_VER                         
            AND A.WC_CD = A1.WC_CD AND A.LINE_CD = A1.LINE_CD AND A.PROC_CD = A1.PROC_CD                        
                        
            INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE                                   
            AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD --AND A.PROC_CD <> B.PROC_CD                     
            AND B.S_CHK = 'N' AND A.RESULT_SEQ = B.RESULT_SEQ AND A.GROUP_LOT = B.GROUP_LOT                                    
            INNER JOIN PD_ORDER_PROC B1 WITH (NOLOCK) ON                         
            B.DIV_CD = B1.DIV_CD AND B.PLANT_CD = B1.PLANT_CD AND B.ORDER_NO = B1.ORDER_NO AND B.REVISION = B1.REVISION                         
            AND B.ORDER_TYPE = B1.ORDER_TYPE AND B.ORDER_FORM = B1.ORDER_FORM AND B.ROUT_NO = B1.ROUT_NO AND B.ROUT_VER = B1.ROUT_VER                         
            AND B.WC_CD = B1.WC_CD AND B.LINE_CD = B1.LINE_CD AND B.PROC_CD = B1.PROC_CD AND A1.GROUP_SEQ >= B1.GROUP_SEQ                         
                        
            INNER JOIN PD_USEM C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO AND B.REVISION = C.REVISION AND B.ORDER_TYPE = C.ORDER_TYPE                                    
            AND B.ORDER_FORM  = C.ORDER_FORM AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD AND                                    
            C.IN_GBN IN ('SU') AND C.USE_CHK = 'N' AND B.RESULT_SEQ = C.RESULT_SEQ                                    
                                               
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                  
              AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                                    
            
        END                                    
                                   
        -- 투입 수량을 가지고 온다. 앞에 공정이 있으면...                                    
        -- 이전 공정에서 감량율을 체크하는 공정이 있는지 확인하다.                                    
                                   
        -- 이전 실적정보를 저장합시다.                                   
                        
        INSERT INTO @PROC_RESULT_TBL ( ORDER_NO, REVISION, ROUT_NO, ROUT_VER, WC_CD, LINE_CD, PROC_CD, RESULT_SEQ, GROUP_LOT,  LOSS_CHK, AP_CHK)                                   
        SELECT B.ORDER_NO, B.REVISION, B.ROUT_NO, B.ROUT_VER, B.WC_CD, B.LINE_CD, B.PROC_CD, B.RESULT_SEQ, B.GROUP_LOT, ISNULL(D.SPECIPI_YN,'N'), ISNULL(C.AP_CHK,'N')                                  
            FROM PD_RESULT A WITH (NOLOCK)                                    
            INNER JOIN PD_RESULT B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD                                    
            AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM                                    
            AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ                                   
            AND A.GROUP_LOT = B.GROUP_LOT                                   
           INNER JOIN PD_ORDER_PROC C WITH (NOLOCK) ON B.DIV_CD = C.DIV_CD AND B.PLANT_CD = C.PLANT_CD AND B.ORDER_NO = C.ORDER_NO                                    
            AND B.REVISION = C.REVISION AND B.PROC_NO = C.PROC_NO AND B.ORDER_TYPE = C.ORDER_TYPE AND B.ORDER_FORM = C.ORDER_FORM                                    
            AND B.ROUT_NO = C.ROUT_NO AND B.ROUT_VER = C.ROUT_VER AND B.WC_CD = C.WC_CD AND B.LINE_CD = C.LINE_CD AND B.PROC_CD = C.PROC_CD                                    
            AND C.IN_CHK = 'N' AND C.SKIP = 'N'                                  
            LEFT JOIN BA_ROUTING_DETAIL D WITH (NOLOCK) ON C.DIV_CD = D.DIV_CD AND C.PLANT_CD = D.PLANT_CD AND C.ROUT_NO = D.ROUT_NO AND C.ROUT_VER = D.[VERSION] AND C.PROC_CD = D.PROC_CD                                    
                                   
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO                                   
          AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD                                    
          AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ                                    
                                   
        ORDER BY C.GROUP_SEQ                                   
                                  
        -- 추가 프로세스                                  
        -- 만약 앞에 공정에 @AP_CHK = 'Y' 인게 있는데, 그룹 실적이 없으면?                                  
        -- 튕겨 내야 된다.                                   
        -- 마지막 공정일때                           
        IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y'                                   
        BEGIN                                   
          IF @EX_PROC = 'N'                        
          BEGIN                         
            IF EXISTS(                                  
            SELECT A.*                       
              FROM dbo.FN_GET_GROUP_PROC_TBL(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @LINE_CD, @PROC_CD) A                                   
              LEFT JOIN @PROC_RESULT_TBL B ON A.PROC_CD = B.PROC_CD                                   
            WHERE B.PROC_CD IS NULL                                   
            )                                  
            BEGIN                                   
              SET @MSG_CD = '9999'                                  
              SET @MSG_DETAIL = '실적 등록이 되지 않은 그룹 공정이 있습니다. 확인하여 주십시오. '                        
              RETURN 1                                  
   END                          
          END                              
       END                                   
        -- 가장 상위에 있는 공정의 LOSS_CHK 가 Y 이면?                                   
     -- 투입 이후에 실적을 가지고 가야 되는거니...                                    
        -- 감량율을 가지고 온다.                                   
        DECLARE @FIFO_QTY NUMERIC(18,3) = 0                                    
                                   
        IF (SELECT LOSS_CHK FROM @PROC_RESULT_TBL A WHERE A.CNT = 1) = 'Y'                                   
        BEGIN                                    
          
            SELECT @LOSS_RATE = ISNULL(A.LOSS_RATE,100)                                   
            FROM V_ITEM A WITH (NOLOCK) WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD                                    
                  
            IF @LOSS_RATE = 0                   
            BEGIN                   
              SET @MSG_CD = '9999'                  
              SET @MSG_DETAIL = '감량율 값이 0 입니다. 품목기준정보 확인이 필요합니다. 관리자에게 문의하여 주십시오. 품목코드 : ' + @ITEM_CD                   
              RETURN 1                   
            END                   
                  
         --   SELECT @REQ_QTY, @SU_QTY, @LOSS_RATE                                           
                                           
        -- 선입선출 수량은 소분 투입을 뺀 수량으로 선입선출 ex) 3000 - 200 = 2800                                    
            SET @FIFO_QTY = ISNULL((SELECT (@REQ_QTY - @SU_QTY) / @LOSS_RATE * 100), @REQ_QTY - @SU_QTY)                                   
            --SET @FIFO_QTY = ISNULL((SELECT (@REQ_QTY - @SU_QTY) + ((@REQ_QTY - @SU_QTY) * ((100 - @LOSS_RATE) * 0.01))), @REQ_QTY - @SU_QTY)                                   
          -- SET @FIFO_QTY = ISNULL((SELECT (@REQ_QTY - @SU_QTY) + ((@REQ_QTY - @SU_QTY) / @LOSS_RATE)), @REQ_QTY - @SU_QTY)                                   
           -- SET @FIFO_QTY = ISNULL((SELECT (@REQ_QTY - @SU_QTY) + (@REQ_QTY - @SU_QTY) - ((@REQ_QTY - @SU_QTY) * @LOSS_RATE / 100)), @REQ_QTY - @SU_QTY)                                   
            -- 실적은 300                                   
            -- 공정에 RK 가 있는가? 를 찾아야 된다. 감량율 체킹 표기..                                  
            -- ((포장 수량 - 소분 수량) * 감량율 / 100) + 소분 수량                              
            -- 포장수량 * 감량율 / 100                                    
                                  
        END                                   
        ELSE                                    
        BEGIN                                    
           SET @FIFO_QTY = @REQ_qTY - ISNULL(@SU_QTY,0)                                  
        END                                    
                                         
        IF @FIFO_QTY < 0             
        BEGIN                                  
          SET @MSG_CD = '9999'                                 
          SET @MSG_DETAIL = '계산 수량이 음수(-)로 판정 되었습니다. 관리자에게 문의하여 주십시오. Qty : ' +  CAST(@FIFO_QTY AS NVARCHAR(10))                                 
          RETURN 1                                 
                                 
        END                                  
                                           
        INSERT INTO @BACK_TABLE                        
        SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                                   
        AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                                   
        FROM (                
            SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                                   
            CASE WHEN (@FIFO_QTY - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                                   
            ELSE (Z.SUMQTY - @FIFO_QTY) - Z.CURQTY   END  AS QTY                                    
            , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                
            FROM (                                   
            SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                    
            (SELECT SUM(W.CURQTY) FROM @FIFO_TABLE W WHERE W.ROWNUM <= Q.ROWNUM  AND W.CURQTY > 0) SUMQTY,                                
            Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                                   
            FROM @FIFO_TABLE Q) Z                                   
            WHERE CASE WHEN (@FIFO_QTY - Z.SUMQTY) >= 0 THEN Z.CURQTY                                    
            ELSE Z.CURQTY - (Z.SUMQTY - @FIFO_QTY) END  > 0                                   
        ) AA                                   
                      
                      
        IF NOT EXISTS(SELECT *FROM @BACK_TABLE)                                 
        BEGIN                                  
          SET @MSG_CD = '9999'                                 
          SET @MSG_DETAIL = '재공 선입선출 자료가 없습니다. 오류 사항입니다. 관리자에게 문의하여 주십시오.'                                  
          RETURN 1                                 
     END                                  
                        
        IF @FIFO_QTY > ISNULL((SELECT SUM(QTY) FROM @BACK_TABLE),0)                                   
        BEGIN                                    
            SET @MSG_CD = '9999'                                   
  SET @MSG_DETAIL = '등록 수량대비 재공 수량이 부족합니다. 재공수량 확인이 필요합니다.' + CHAR(10) +CHAR(10)                                  
            + '처리에정 수량 : ' + CAST(@FIFO_QTY AS NVARCHAR) + CHAR(10)                                  
            + '감량율 : ' + CAST(@LOSS_RATE AS NVARCHAR) + CHAR(10)                                  
            + '재고수량 : ' + CAST(ISNULL((SELECT SUM(QTY) FROM @BACK_TABLE),0) AS NVARCHAR)                                   
                                              
           -- SELECT @MSG_DETAIL                                    
            RETURN 1                       
        END                                   
        ELSE                                    
        BEGIN                           
           -- PD_USEM 에 INSERT 를 합니다.                                 
            SET @MASTER_LOT = ''                                    
           
            SELECT TOP 1 @MASTER_LOT = AA.LOT_NO                                  
            FROM                                   
            (                                  
              SELECT MAX(CNT) AS CNT, LOT_NO, SUM(QTY) AS QTY                                   
                FROM @BACK_TABLE                                   
              GROUP BY LOT_NO                                   
            ) AA                                   
            ORDER BY AA.QTY DESC, AA.CNT ASC                                   
                      
            DECLARE @LOT_SEQ NVARCHAR(10) = ''                                  
                                         DECLARE @GDATE NVARCHAR(7) = ''                          
                      
            IF @WC_CD NOT IN ('13P', '14P')                        
            BEGIN                     
              SELECT @GDATE = CONVERT(NVARCHAR(7), CAST('20' + SUBSTRING(@MASTER_LOT, PATINDEX('%[0-9]%',@MASTER_LOT) ,4) + '01' AS DATETIME), 120)                          
              -- 어... 여기는..                                    
              -- 채번 규칙을 체인지 합시다..                                    
                                    
              IF EXISTS(SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)                                     
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = @GDATE                         
              /*                         
              (                                    
                   
              SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)                                    
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                                     
              A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                                     
              A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                    
              ) AS DATETIME), 120)                   
              )                                    
              */                         
              AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                     
            )                                    
              BEGIN                                 
                SELECT @LOT_SEQ =       
                CASE WHEN '14C' IN ('14C') THEN       
                ISNULL((SELECT TOP 1 LOT_INFO FROM BA_LINE WITH (NOLOCK) WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD       
                AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE       
                CAST(                     
                CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END + dbo.LPAD(A.LOT_SEQ +                                    
                CASE WHEN @LOT_CHK = 'N' THEN  -- @LOT CHK 가 N 이면 증가고 아니면 예전 채번 그대로 가지고 간다.                                    
                1 ELSE 0 END ,3,0)                                    
                FROM PD_LOT_SEQ A WITH (NOLOCK)               
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = @GDATE                          
      
/*(                                    
                                     
                SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)                                    
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                                     
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                                     
                A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                    
       ) AS DATETIME), 120)                                     
               )                          
                */                                   
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                                     
                                     
              END                                     
              ELSE                                     
              BEGIN                 
                SELECT @LOT_SEQ =      
                CASE WHEN '14C' = '14C' THEN       
                ISNULL((SELECT TOP 1 LOT_INFO FROM BA_LINE WITH (NOLOCK) WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD       
                AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE       
                CAST(                     
                CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END + dbo.LPAD(1,3,0)     
--                CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) + dbo.LPAD(1,3,0)                                    
              END                                      
            END                       
                      
-- 여기다가 @LOT_CHK = 'J', 'F' 이면                                    
            -- 뒤에다가 체번 규칙을 추가 한다.                          
            -- J 는 나올일이 없을것 같은데..                                    
                                    
            DECLARE @J_LOT NVARCHAR(10) = ''                                   
                               
            IF @LOT_CHK IN ('J','F')                                    
            BEGIN                    
                   
                                 
              SET @J_VAL = ISNULL((SELECT A.J_VAL FROM PD_RESULT A WITH (NOLOCK)                    
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION                    
              AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                    
              AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.S_CHK = 'N' AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ),'%')                   
                   
              SET @J_LOT = '-' + ISNULL((SELECT A.SUB_CD FROM BA_SUB_CD A WITH (NOLOCK)                    
              WHERE A.MAIN_CD = 'POP53' AND A.SUB_CD = @J_VAL),'1'                   
              )     
              /*                   
      				DECLARE @DC_J_SEQ		INT                    
                          
      				SELECT TOP 1 @DC_J_SEQ = A.J_SEQ               
      				FROM PD_RESULT A WITH (NOLOCK)                                    
      				WHERE A.DIV_CD = @DIV_CD                    
      				  AND A.PLANT_CD = @PLANT_CD                                   
                        AND A.WC_CD = @WC_CD                    
      			      AND A.LINE_CD = @LINE_CD                    
      				  AND A.PROC_CD = @PROC_CD                    
      				  AND A.LOT_SEQ = CAST(SUBSTRING(@LOT_SEQ,2,3) AS INT)                    
      				  AND A.J_CHK = 'J'                              
                        AND A.RESULT_SEQ <> @RESULT_SEQ                    
      				                    
      				IF @DC_J_SEQ = 1                    
      				BEGIN                    
      					SET @J_LOT = '-1'                    
      				END                    
      				ELSE IF @DC_J_SEQ = 2                    
      				BEGIN                    
      					SET @J_LOT = '-1-1'                    
      				END                    
      				ELSE IF @DC_J_SEQ = 3                    
      				BEGIN                    
      					SET @J_LOT = '-1-1-1'                    
      				END                    
      				ELSE IF @DC_J_SEQ = 4                    
      				BEGIN                    
      					SET @J_LOT = '-1-1-1-1'                    
      				END                    
              */                   
                   
              --SET @J_LOT = '-' +                                    
              --ISNULL((SELECT CAST(ISNULL(A.J_SEQ,0) + 1 AS NVARCHAR) FROM PD_RESULT A WITH (NOLOCK)                                    
              --    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD --AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                                    
              ----A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND                 
              --AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.LOT_SEQ = CAST(SUBSTRING(@LOT_SEQ,2,3) AS INT) AND A.J_CHK = 'J'                              
              --AND A.RESULT_SEQ <> @RESULT_SEQ),'1')                              
                                  
            END                                   
                                    
            -- 분쇄 LOT 처리 이거 FIXED 입니다.... 나중에 기준정보 재확인이 필요합니다.                         
                        
            IF @WC_CD IN ('13P', '14P')                        
            BEGIN                         
              -- 분쇄 LOT 처리시에는?                         
              -- 어떻게 처리를 해야 되는가?                        
             -- SELECT @MASTER_LOT                     
              SET @LOT_SEQ = ISNULL((SELECT TOP 1 A.LOT_SEQ                        
                FROM PD_RESULT A WITH (NOLOCK)                         
              WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.PROC_CD = @PROC_CD                         
                AND A.LOT_NO LIKE @MASTER_LOT + '%' --AND A.RESULT_SEQ <> @RESULT_SEQ                         
                               
                ORDER BY A.INSERT_DT DESC ),0) + 1                        
                                    
              SET @J_LOT = '-' +                         
                                      
              CAST (@LOT_SEQ AS NVARCHAR) + '-A'                        
                        
            END                          
                      
           -- SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)                                    
            --SELECT @MASTER_LOT, @LOT_SEQ                                    
                           
            DECLARE @RESULT_LOT TABLE (                                   
               CNT      INT IDENTITY(1,1)                                    
              ,VALUE    NVARCHAR(100)    
            )                                   
                      
                      
            IF CHARINDEX('-', @MASTER_LOT) <> 0          
            BEGIN           
              INSERT INTO @RESULT_LOT (VALUE)                       
              SELECT VALUE FROM string_split(@MASTER_LOT,'-')                                  
            END           
            ELSE           
            BEGIN           
              INSERT INTO @RESULT_LOT (VALUE)                       
              SELECT @MASTER_LOT           
              UNION ALL           
              SELECT @LOT_sEQ           
            END           
                                  
            UPDATE A SET A.VALUE = @LOT_SEQ                                   
              FROM @RESULT_LOT A                                    
            WHERE A.CNT = (SELECT MAX(CNT) FROM @RESULT_LOT)                                   
                                  
            IF @WC_CD NOT IN ('13P','14P')                      
            BEGIN                       
              UPDATE A SET A.VALUE = 'G' + CONVERT(NVARCHAR(4),                                   
                CAST(                                  
              '20' + SUBSTRING(@MASTER_LOT,  PATINDEX('%[0-9]%',@MASTER_LOT),4) + '01'                         
              /*                                    
               ISNULL((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)                               
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                                     
                A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                               
                A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ) ,GETDATE())                                  
                  */                              
                                                
              AS DATETIME), 12)                                                          
              FROM @RESULT_LOT A                                                           
              WHERE A.CNT = 1                                   
            END                       
                     
-- 소성 부터 먼저 USEM 에 등록 한후에                                    
            -- 그 뒤에는 차례대로 소성 실적 LOT 를 이어 붙여서 처리한다.                                    
            -- 계속 포장 까지...                                   
-- PD_ITEM_IN 에 UPDATE 해주고 RESULT 에 없데이트 해주고                                   
            -- PD_USEM 을 집어 넣는다.                                    
                                   
            --SELECT *FROM @PROC_RESULT_TBL                                    
                 
            DECLARE @L_CNT        INT = 0                                    
                   ,@L_TCNT       INT = 0                                   
                   ,@L_ORDER_NO   NVARCHAR(50)                                    
                   ,@L_REVISION   INT                                    
                   ,@L_ROUT_NO    NVARCHAR(10)    
                   ,@L_ROUT_VER   INT               
                   ,@L_WC_CD      NVARCHAR(50)                              
                   ,@L_LINE_CD    NVARCHAR(10)                                    
                   ,@L_PROC_CD    NVARCHAR(10)                                    
                                   
                   ,@L_BE_ORDER_NO   NVARCHAR(50)                           
                   ,@L_BE_REVISION   INT                                    
                   ,@L_BE_ROUT_NO    NVARCHAR(10)                                    
                   ,@L_BE_ROUT_VER   INT                                    
                   ,@L_BE_WC_CD      NVARCHAR(50)                                    
                   ,@L_BE_LINE_CD    NVARCHAR(10)                                    
                   ,@L_BE_PROC_CD    NVARCHAR(10)                                   
                   ,@TOP_LOT         NVARCHAR(100) = ''                                  
                   ,@BOT_LOT         NVARCHAR(10) = ''                                   
                   ,@RESULT_NEW_LOT  NVARCHAR(100) = ''                                   
                                   
            DECLARE @LOT_CNT INT  = 0                                    
                    ,@LOT_TCNT INT = 0                       
                            
            SELECT @LOT_TCNT = COUNT(*) - 2 FROM @RESULT_LOT                                    
                                   
            WHILE @LOT_CNT <> @LOT_TCNT                                    
            BEGIN                                    
              SET @LOT_CNT = @LOT_CNT + 1                                   
              SET @TOP_LOT = @TOP_LOT + (SELECT VALUE FROM @RESULT_LOT WHERE CNT = @LOT_CNT) + '-'                                   
            END                                  
                                               
            SELECT @L_TCNT = COUNT(*) FROM @PROC_RESULT_TBL                                    
                                    
            WHILE @L_CNT <> @L_TCNT                                    
            BEGIN                                    
              SET @L_CNT = @L_CNT + 1                                   
                SELECT @L_ORDEr_NO = ORDER_NO, @L_REVISION = REVISION, @L_ROUT_NO = ROUT_NO, @L_ROUT_VER = ROUT_VER,                                    
                @L_WC_CD = WC_CD, @L_LINE_CD = LINE_CD,                                    
                @L_PROC_CD = PROC_CD, @GROUP_LOT = GROUP_LOT FROM @PROC_RESULT_TBL WHERE CNT = @L_CNT                                    
                --SELECT FROM @PROC_RESULT_TBL WHERE CNT = @L_CNT                                    
                SELECT                                    
                @L_BE_ORDEr_NO = ORDER_NO, @L_BE_REVISION = REVISION, @L_BE_ROUT_NO = ROUT_NO, @L_BE_ROUT_VER = ROUT_VER,                                    
                @L_BE_WC_CD = WC_CD, @L_BE_LINE_CD = LINE_CD,                                   
                @L_BE_PROC_CD = PROC_CD                                    
                FROM @PROC_RESULT_TBL WHERE CNT = @L_CNT - 1                                   
                                                   
                -- 여기서 문제가 생기는게 ROUT_VER 로 원래는 체크 하는데, 이게 안되다 보니, 문제가 발생 Pre-bare RK                            
                SET @BOT_LOT =                                    
             
                CASE WHEN ISNULL((             
                  SELECT B.TEMP_CD5              
                    FROM V_ITEM A WITH (NOLOCK)              
                    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'             
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD              
             
                ),'') = '' THEN              
                  ISNULL((  
                  SELECT A.PROC_INITIAL  
                    FROM BA_LINE A WITH (NOLOCK)   
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @L_WC_CD AND A.LINE_CD = @L_LINE_CD)  
                    ,(                      
                        SELECT A.LOT_INITIAL FROM  BA_ROUTING_HEADER A WITH (NOLOCK)                                     
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ROUT_NO = @L_ROUT_NO AND A.[VERSION] = @L_ROUT_VER )            
                     )  
                ELSE              
                  ISNULL((             
                    SELECT B.TEMP_CD5              
                    FROM V_ITEM A WITH (NOLOCK)              
                    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'             
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD          
                               
                  ),'')             
                END              
/*             
                ISNULL((                                    
                SELECT A.LOT_INITIAL FROM  BA_ROUTING_HEADER A WITH (NOLOCK)                                     
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ROUT_NO = @L_ROUT_NO AND A.[VERSION] = @L_ROUT_VER ),'')              
  */                           
                             
                +                                     
                ISNULL(                                    
                (SELECT B.TEMP_CD1 FROM BA_SUB_CD A WITH (NOLOCK)                                     
                INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.TEMP_CD3 = B.SUB_CD AND B.MAIN_CD = 'BA204'                                     
                WHERE A.MAIN_CD = 'SAP01' AND A.SUB_CD = (                                    
                SELECT ORDER_TYPE FROM PD_ORDER A WITH (NOLOCK)                                     
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDEr_NO AND A.REVISION = @L_REVISION ))                                     
                ,'')                                                     
                              
                                            
                IF ISNULL(@L_BE_PROC_CD,'') = ''                              
                BEGIN                       
                  SET @RESULT_NEW_LOT = @TOP_LOT + @BOT_LOT + '-' + @LOT_SEQ + @J_LOT                                   
             END                                   
                ELSE                                   
                BEGIN                                   
                  IF @WC_CD NOT IN ('13P', '14P')                        
                  SET @RESULT_NEW_LOT = @TOP_LOT + @BOT_LOT + '-' + @LOT_SEQ + @J_LOT                                   
                END                            
                        
                -- 첨가제 분쇄 공정이면 그 LOT 그대로 가지고 가야지... @MASTER_LOT 이다. 이것도 FIXED 로 처리 한다.                         
             
                IF ISNULL(@L_BE_PROC_CD,'') = '' AND @WC_CD IN ('13P','14P')                        
                BEGIN                         
                  --SELECT @MASTER_LOT                        
                  SET @RESULT_NEW_LOT = @MASTER_LOT + @J_LOT                        
                  --SELECT @RESULT_NEW_LOT                        
              END                         
         
                -- 자기 LOT 그대로 가지고 올때는 @MASTER_LOT           미자믹 공정이 아니면 처리        
         
                IF @NS_CHK = 'Y'                 
                BEGIN                  
                  IF dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'N' AND        
                  @ORDER_TYPE IN ('PP04')        
                  BEGIN          
                    DECLARE @RSEQ INT = 0                  
                            ,@LOT_CREATE NVARCHAR(100)         
         
                    IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)                   
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.LOT_NO = @MASTER_LOT AND A.J_CHK = 'R' AND A.J_SEQ > 0)                  
                    BEGIN                  
                        SELECT @RSEQ = A.J_SEQ + 1 FROM PD_RESULT A WITH (NOLOCK)                   
                        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.LOT_NO = @MASTER_LOT  AND A.J_CHK = 'R' AND A.J_SEQ > 0                  
                      
                        SET @LOT_CREATE =  SUBSTRING(@MASTER_LOT,0,CHARINDEX('-R',@MASTER_LOT,LEN(@MASTER_LOT) - 4)) + '-R' + CAST(@RSEQ AS NVARCHAR)                  
                      
                    END                   
                    ELSE                   
                    BEGIN                
                        DECLARE @LOT_INFO_R TABLE(             
                             CNT      INT IDENTITY(1,1)                  
                            ,LOT      NVARCHAR(50)                  
                        )                 
                        INSERT INTO @LOT_INFO_R                  
                        SELECT '-' + VALUE FROM string_split(@MASTER_LOT,'-')                 
                    
                      --  SELECT *FROM  @LOT_INFO_R                  
    
                        DECLARE @MAX_CNT INT = 0                  
                
                        SELECT @MAX_CNT = COUNT(*) FROM @LOT_INFO_R                  
                                      
                        IF EXISTS(SELECT *FROM @LOT_INFO_R WHERE CNT = @MAX_CNT AND LEFT(LOT,2) = '-R' AND ISNUMERIC(REPLACE(LOT,'-R','')) = 1)                 
                        BEGIN                  
                            SET @RSEQ = ISNULL((SELECT CAST(REPLACE(LOT,'-R','') AS INT) FROM @LOT_INFO_R WHERE CNT = @MAX_CNT AND LEFT(LOT,2) = '-R'),0) + 1                 
                            SET @LOT_CREATE =  SUBSTRING(@MASTER_LOT,0,CHARINDEX('-R',@MASTER_LOT,LEN(@MASTER_LOT) - 4)) + '-R' + CAST(@RSEQ AS NVARCHAR)                 
                     
                        END                  
                        ELSE                  
                        BEGIN                  
                            SET @RSEQ = 1                 
                            SET @LOT_CREATE = @MASTER_LOT + '-R' + CAST(@RSEQ AS NVARCHAR)                 
                        END                 
         
                    END          
         
                    SET @RESULT_NEW_LOT = @LOT_CREATE          
                    --SELECT @RESULT_NEW_LOT                  
         
                  END          
                  ELSE          
                  BEGIN          
                    SET @RESULT_NEW_LOT = @MASTER_LOT                 
                  END          
                END                  
         
                -- LOT 를 다시 구성 한다.          
         
                         
    
                IF @L_CNT = 1                                    
                BEGIN                                    
                    -- 공정과                                    
                      -- CAPA를 확인하여 조합한다.                                    
                                   
                    INSERT INTO PD_USEM                                    
                    (                                   
                         DIV_CD,              PLANT_CD,              PROC_NO,                 ORDER_NO,                REVISION,                                   
                         ORDER_TYPE,          ORDER_FORM,            ROUT_NO,             ROUT_VER,                WC_CD,                                    
                         LINE_CD,             PROC_CD,               RESULT_SEQ,                                                 
                         USEM_SEQ,                                                   
                         USEM_WC,             USEM_PROC,                         
                         ITEM_CD,             SL_CD,                 LOCATION_NO,             RACK_CD,  LOT_NO,                                    
                         MASTER_LOT,                                    
                         PLC_QTY,             USEM_QTY,              DEL_FLG,                 REWORK_FLG,              INSERT_ID,                                    
                         INSERT_DT,           UPDATE_ID,             UPDATE_DT,               ITEM_TYPE,                                   
                         BE_ORDER_NO,         BE_REVISION,           BE_RESULT_SEQ,           BE_PROC_CD                                   
                                                         
                    )                                   
                                   
                    SELECT                                    
                         @DIV_CD,             @PLANT_CD,             @PROC_NO,                @L_ORDER_NO,               @L_REVISION,                                  
                         @ORDER_TYPE,         @ORDER_FORM,           @L_ROUT_NO,                @L_ROUT_VER,               @L_WC_CD,                                    
                         @L_LINE_CD,            @L_PROC_CD,            @RESULT_SEQ,                                                
      ISNULL((SELECT MAX(Z.USEM_SEQ) FROM PD_USEM Z WITH (NOLOCK)                                    
                         WHERE Z.DIV_CD = @DIV_CD AND Z.PLANT_CD = @PLANT_CD AND Z.ORDER_NO = @L_ORDER_NO AND Z.REVISION = @L_REVISION AND Z.ORDER_TYPE = @ORDER_TYPE                                    
                         AND Z.ORDER_FORM = @ORDER_FORM AND Z.ROUT_NO = @ROUT_NO AND Z.ROUT_VER = @L_ROUT_VER AND Z.WC_CD = @L_WC_CD AND Z.LINE_CD = @L_LINE_CD AND Z.PROC_CD = @L_PROC_CD AND Z.RESULT_SEQ = @RESULT_SEQ),0)                                 
 
  
   
                         + A.CNT,                                   
                         A.BE_WC_CD,          A.PROC_CD,                                    
                         A.ITEM_CD,            '3000',                A.BE_LINE_CD,            '*',                     A.LOT_NO,                                    
                         @MASTER_LOT,                    
                         A.QTY,               A.QTY,                 'N',                     'N',                     @USER_ID,                                    
                         GETDATE(),           @USER_ID,              GETDATe(),               'J',                                   
                         A.BE_ORDER_NO,       A.BE_REVISION,         A.BE_RESULT_SEQ,         A.BE_PROC_CD                                   
                    FROM @BACK_TABLE A                      
                                   
                    -- RESULT 및 PD_ITEM_IN 에 넣는다.                                    
                                         
                    -- 소분 투입량을 제외하고, 실적을 생성할수 있도록 한다.                                    
                    -- 대신에 실적은 감량율을 적용하지 않은, 실제 포장 실적 - 소분 투입 수량으로 진행한다.                                   
                                                
                    DECLARE @RESULT_QTY NUMERIC(18,3) = 0                 
                            
                    IF (SELECT ISNULL(A.MIN_CHK,'N') FROM PD_ORDER_PROC A WITH (NOLOCK)                             
                      WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                                    
                    AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD) = 'Y'                             
                    BEGIN                             
                            
                        SET @RESULT_QTY = @REQ_QTY                             
                            
                    END                             
                    ELSE                             
                    BEGIN                             
                        SET @RESULT_QTY = @REQ_QTY - ISNULL(@SU_QTY,0)                            
                    END                             

                    SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  

                    INSERT INTO PD_RESULT_UPD_HISTORY   
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-전',@USER_ID, A.*
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                          
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    

                    
                    UPDATE A SET A.LOT_NO = @RESULT_NEW_LOT, A.GOOD_QTY = @RESULT_QTY, A.RESULT_QTY = @RESULT_QTY,                                   
                    --A.J_CHK = @LOT_CHK,                                   
                    A.LOT_SEQ = CAST(RIGHT(@LOT_SEQ,3) AS INT)                                    
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                          
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    
                                   
                    UPDATE A SET A.LOT_NO = @RESULT_NEW_LOT, A.GOOD_QTY = @RESULT_QTY                            
                    FROM PD_ITEM_IN A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                                    
                    AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                      

                    INSERT INTO PD_RESULT_UPD_HISTORY   
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-후',@USER_ID,  A.*
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                          
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    
                    
               END                                    
                ELSE                                    
                BEGIN                                    
                    -- 다음 공정부터는 앞공정의 실적을 PD_USEM 에 넣어야 된다.                                    
                    INSERT INTO PD_USEM                                    
                    (            
                         DIV_CD,              PLANT_CD,              PROC_NO,                 ORDER_NO,                REVISION,                          
                         ORDER_TYPE,    ORDER_FORM,            ROUT_NO,                 ROUT_VER,                WC_CD,                                    
                         LINE_CD,             PROC_CD,               RESULT_SEQ,                                            
                         USEM_SEQ,                                                   
                         USEM_WC,             USEM_PROC,                                    
                         ITEM_CD,             SL_CD,                 LOCATION_NO,             RACK_CD,               LOT_NO,                                    
                         MASTER_LOT,                                    
                         PLC_QTY,             USEM_QTY,         DEL_FLG,                 REWORK_FLG,              INSERT_ID,                                    
                         INSERT_DT,           UPDATE_ID,           UPDATE_DT,               ITEM_TYPE,                                   
                         BE_ORDER_NO,         BE_REVISION,    BE_RESULT_SEQ,           BE_PROC_CD                                   
                                                         
                    )                                   
                    SELECT                                    
                 A.DIV_CD,             A.PLANT_CD,            A.PROC_NO,     @L_ORDER_NO,               @L_REVISION,                                    
                        @ORDER_TYPE,          @ORDER_FORM,           @L_ROUT_NO,              @L_ROUT_VER,               @L_WC_CD,                                    
                                                 
                        @L_LINE_CD,            @L_PROC_CD,            A.RESULT_SEQ,                                    
                        -- 앞공정 PD_USEM 에 있으면 MAX 값을 가지고 와야 된다...                                    
                        ISNULL((SELECT MAX(Z.USEM_SEQ) FROM PD_USEM Z WITH (NOLOCK)                                    
                         WHERE Z.DIV_CD = @DIV_CD AND Z.PLANT_CD = @PLANT_CD AND Z.ORDER_NO = @L_ORDER_NO AND Z.REVISION = @L_REVISION AND Z.ORDER_TYPE = @ORDER_TYPE                                    
                        AND Z.ORDER_FORM = @ORDER_FORM AND Z.ROUT_NO = @L_ROUT_NO AND Z.ROUT_VER = @L_ROUT_VER AND Z.WC_CD = @L_WC_CD AND Z.LINE_CD = @L_LINE_CD AND Z.PROC_CD = @L_PROC_CD AND Z.RESULT_SEQ = @RESULT_SEQ),0)                                 
 
   
   
    
                         + 1,                                   
                        A.WC_CD,              A.PROC_CD,                                   
                 A.ITEM_CD,             A.SL_CD,               A.LOCATION_NO,           A.RACK_CD,               A.LOT_NO,                                    
                        A.LOT_NO,                                       
                        A.GOOD_QTY,      A.GOOD_QTY,            'N',                     'N',                     @USER_ID,                                    
                        GETDATE(),            @USER_ID,              GETDATe(),               'J',                                   
                        A.ORDER_NO,           A.REVISION,            A.RESULT_SEQ,            A.PROC_CD                                   
                    FROM                                    
                        PD_ITEM_IN A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_BE_ORDER_NO AND A.REVISION = @L_BE_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_BE_ROUT_NO AND A.ROUT_VER = @L_BE_ROUT_VER AND A.WC_CD = @L_BE_WC_CD                                    
                      AND A.LINE_CD = @L_BE_LINE_CD AND A.PROC_CD = @L_BE_PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                    
                                   
                    SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  

                    INSERT INTO PD_RESULT_UPD_HISTORY   
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-전',@USER_ID,  A.*
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                          
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    


                    UPDATE A SET A.LOT_NO = @RESULT_NEW_LOT, A.GOOD_QTY = @REQ_QTY, A.RESULT_QTY = @REQ_QTY,-- A.J_CHK = @LOT_CHK,                                    
                    A.LOT_SEQ = CAST(RIGHT(@LOT_SEQ,3) AS INT)                                     
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                                    
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    
                                        
                    UPDATE A SET A.LOT_NO = @RESULT_NEW_LOT, A.GOOD_QTY = @REQ_QTY                                   
                    FROM PD_ITEM_IN A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                            
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                                    
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                                    

                    SET @UDI_DATE = CONVERT(VARCHAR(20),GETDATE(),120)  

                    INSERT INTO PD_RESULT_UPD_HISTORY   
                    SELECT @UDI_DATE, 1, @UDI_SP, @UDI_REMARK + '-후',@USER_ID,  A.*
                    FROM PD_RESULT A WITH (NOLOCK)                                    
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @L_ORDER_NO AND A.REVISION = @L_REVISION AND A.PROC_NO = @PROC_NO                                    
                      AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @L_ROUT_NO AND A.ROUT_VER = @L_ROUT_VER AND A.WC_CD = @L_WC_CD                          
                      AND A.LINE_CD = @L_LINE_CD AND A.PROC_CD = @L_PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ AND A.GROUP_LOT = @GROUP_LOT                                    
               
                END                                    
                IF @ORDER_TYPE NOT IN ('PP04')         
                BEGIN         
                  SET @MASTER_LOT = @RESULT_NEW_LOT                                  
                END          
            END                                    
              
            IF @ORDER_TYPE IN ('PP04')         
            BEGIN         
              SET @MASTER_LOT = @RESULT_NEW_LOT         
            END          
            -- 자 이제는 자기 자신의 정보를 집어넣어야 됩니다.                                   
            -- PD_USEM 에만 넣으면 될듯                                   
                                   
            IF @L_BE_PROC_CD = ''                                    
            BEGIN                                    
                SET @MSG_CD = '9999'                                   
                SET @MSG_DETAIL = '공정 실적 등록시 문제가 발생했습니다. 관리자에게 문의 하여 주십시오.'                         
--   SELECT @MSG_DETAIL         
                RETURN 1                                   
                                                   
   END                                    
                                         
        END                                   
     END                                     
                              
                                   
END TRY                                    
BEGIN CATCH                                    
    SET @MSG_CD = '9999'                                   
    SET @MSG_DETAIL = ERROR_MESSAGE()                         
    RETURN 1          
END CATCH 