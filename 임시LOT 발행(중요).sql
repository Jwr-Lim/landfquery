DECLARE @DIV_CD     NVARCHAR(10) = '01'
       ,@PLANT_CD   NVARCHAR(10) = '1130' 
       ,@ORDER_NO   NVARCHAR(50) = 'PD250827001' 
       ,@REVISION   INT          = 1
       ,@WC_CD      NVARCHAR(10) = '13GA' 
       ,@LINE_CD    NVARCHAR(10) = '13G01A' 
       ,@PROC_CD    NVARCHAR(10) = 'RK' -- RK
       ,@EQP_CD     NVARCHAR(50) = 'LFG01A-01A-RK-0701' --LFG01A-01A-RK-0701
     --  ,@PROC_CD    NVARCHAR(10) = 'MX' -- RK
     --  ,@EQP_CD     NVARCHAR(50) = 'LFG01A-01A-TK-0701' --LFG01A-01A-RK-0701


-- 이번에는 작업지시의 공정 수순을 보고 
-- 그룹공정 데이터부터 먼저 가지고 와서 


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


DECLARE @USEM_BACK TABLE 
(
 CNT        INT IDENTITY(1,1) 
,ITEM_CD    NVARCHAR(50) 
,LOT_NO     NVARCHAR(100) 
,QTY        NUMERIC(18,3)
)


DECLARE @ITEM_GROUP TABLE (
 CNT               INT IDENTITY(1,1) 
,REP_ITEM_CD       NVARCHAR(50) 
,PROC_SPEC_CD      NVARCHAR(10) 
,PROC_SPEC_VALUE   NUMERIC(18,3)
)


DECLARE @USEM_INFO TABLE 
(
 CNT         INT 
,ITEM_CD     NVARCHAR(50) 
,LOT_NO      NVARCHAR(50) 
,ITEM_CLASS  NVARCHAR(50) 
,ITEM_TP     NVARCHAR(20) 
,ITEM_GROUP  NVARCHAR(20)
,QTY         NUMERIC(18,3) 
,LOT_INFO    NVARCHAR(20) 
)

DECLARE @PROC_NO    NVARCHAR(50) = ''
       ,@ORDER_TYPE NVARCHAR(10) = ''
       ,@ORDER_FORM NVARCHAR(10) = '' 
       ,@ROUT_NO    NVARCHAR(10) = '' 
       ,@ROUT_VER   INT          = 0
       ,@ITEM_CD    NVARCHAR(10) = '' 
       ,@CREATE_LOT NVARCHAR(100) = ''

DECLARE @OUT_CHK    NVARCHAR(1) = ''
       ,@S_CHK      NVARCHAR(1) = ''
       ,@MN_S       NVARCHAR(1) = '' 
       

SELECT @PROC_NO = A.PROC_NO, @ORDER_TYPE = A.ORDER_TYPE, @ORDER_FORM = A.ORDER_FORM, @ROUT_NO = A.ROUT_NO, @ROUT_VER = A.ROUT_VER, @ITEM_CD = A.ITEM_CD 
    FROM PD_ORDER A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION 
      AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 

SELECT @OUT_CHK = B.OUT_CHK, @S_CHK = B.S_CHK
    FROM PD_ORDER A WITH (NOLOCK) 
    INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION 
    AND A.PROC_NO = B.PROC_NO AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER 
    AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = @PROC_CD 
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND A.PROC_NO = @PROC_NO AND A.ORDER_TYPE = @ORDER_TYPE 
  AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 

SET @MN_S = ISNULL((SELECT A.MN_S 
    FROM BA_EQP A WITH (NOLOCK) 
    WHERE A.DIV_CD = @DIV_CD AND A.EQP_CD = @EQP_CD),'N')

--SELECT @OUT_CHK, @S_CHK, @MN_S -- CHK


IF @OUT_CHK = 'Y' 
BEGIN 

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

        SET @OUT_SEQ = ISNULL((SELECT TOP 1 A.GROUP_SEQ FROM PD_ORDER_PROC A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_NO = @PROC_NO AND A.GROUP_SEQ < @NOW_GROUP_SEQ 
            AND A.OUT_CHK = 'Y'
        ORDER BY A.GROUP_SEQ DESC),0)  
            -- 앞공정에 실적이 있는가? 
            -- 그러면 앞공정부터 현공정까지 실적 및 투입까지 다 가지고 온다. 

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
    END 
    IF @S_CHK <> 'Y' AND @MN_S <> 'Y'
    BEGIN 
    -- 와 이조건은 안맞는데 어떻게 해야 될까? 추후에 정리 다시 해야 된다.. 
    
        --    
        --SELECT *FROM @RESULT_PROC -- CHK


        
        -- PD_ORDER_PROC_SPEC 에서 대표품목 있는것들을 파악한뒤에 소팅


        INSERT INTO @ITEM_GROUP
        SELECT A.USEM_ITEM_GROUP, A.PROC_SPEC_CD, A.PROC_SPEC_VALUE
            FROM PD_ORDER_PROC_SPEC A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO 
        AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM 
        AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD 
        AND A.USEM_ITEM_GROUP <> ''
        
--            SELECT *FROM @ITEM_GROUP -- CHK

        DECLARE @CNT  INT = 0 
            ,@TCNT INT = 0

        SELECT @TCNT = COUNT(*) FROM @ITEM_GROUP

        
        WHILE @CNT <> @TCNT  
        BEGIN 
            SET @CNT = @CNT + 1 
            -- 대표 master 품목 및 LOT 들을 가지고 온다. 각 1개씩 중량도 체크 하자. 
            -- 선입선출 로직 구성 

            DECLARE @REP_ITEM_CD     NVARCHAR(20) = '' 
                    ,@PROC_SPEC_CD    NVARCHAR(10) = ''
                    ,@PROC_SPEC_VALUE NUMERIC(18,3) = 0
            
            SELECT @REP_ITEM_CD = A.REP_ITEM_CD, @PROC_SPEC_CD = A.PROC_SPEC_CD, @PROC_SPEC_VALUE = A.PROC_SPEC_VALUE
            FROM @ITEM_GROUP A 
            WHERE A.CNT = @CNT 
            
            -- 재공 현황을 파악한다. 
            DELETE @FIFO_TABLE 
            DELETE @BACK_TABLE

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

            INSERT INTO @BACK_TABLE
            SELECT AA.ROWNUM, AA.PROC_CD, AA.ITEM_CD, AA.LOT_NO, AA.CURQTY, AA.SUMQTY, AA.QTY, AA.QTY * (-1) AS QTY2,                               
                AA.BE_ORDER_NO, AA.BE_REVISION, AA.BE_WC_CD, AA.BE_LINE_CD, AA.BE_PROC_CD, AA.BE_RESULT_SEQ                               
                FROM (                               
                SELECT Z.PROC_CD, Z.ROWNUM, Z.ITEM_CD, Z.LOT_NO, Z.CURQTY, Z.SUMQTY,                               
                CASE WHEN (@PROC_SPEC_VALUE - Z.SUMQTY) >= 0 THEN (Z.CURQTY * -1)                               
                ELSE (Z.SUMQTY - @PROC_SPEC_VALUE) - Z.CURQTY   END  AS QTY                                
                    , Z.BE_ORDER_NO, Z.BE_REVISION, Z.BE_RESULT_SEQ,Z.BE_WC_CD, Z.BE_LINE_CD, Z.BE_PROC_CD                               
                FROM (                               
                SELECT Q.PROC_CD, Q.ROWNUM, Q.ITEM_CD, Q.LOT_NO, Q.CURQTY,                                
                (SELECT SUM(W.CURQTY) FROM @FIFO_TABLE W WHERE W.ROWNUM <= Q.ROWNUM  AND W.CURQTY > 0) SUMQTY,                               
                Q.BE_ORDER_NO, Q.BE_REVISION, Q.BE_RESULT_SEQ,Q.BE_WC_CD, Q.BE_LINE_CD,  Q.BE_PROC_CD                               
                FROM @FIFO_TABLE Q) Z                               
                WHERE CASE WHEN (@PROC_SPEC_VALUE - Z.SUMQTY) >= 0 THEN Z.CURQTY                                
                ELSE Z.CURQTY - (Z.SUMQTY - @PROC_SPEC_VALUE) END  > 0                               
            ) AA           

                                
--                SELECT *FROM @BACK_TABLE 
            INSERT INTO @USEM_BACK 
            -- MASTER LOT 및 품목을 확인한후에 USEM_TABLE 에 적재한다. 
            SELECT TOP 1 AA.ITEM_CD, AA.LOT_NO, AA.QTY                              
            FROM                               
            (                              
            SELECT MAX(CNT) AS CNT, ITEM_CD, LOT_NO, SUM(QTY) AS QTY                               
                FROM @BACK_TABLE                               
            GROUP BY ITEM_CD, LOT_NO                               
            ) AA                               
            ORDER BY AA.QTY DESC, AA.CNT ASC                               

            -- LOT 발생을 위한 적재 성공
        END 

        SELECT *FROM @USEM_BACK -- CHK
        
        DECLARE @TOP_LOT NVARCHAR(10) = ''
                ,@MID_LOT NVARCHAR(50) = ''
                ,@BOT_LOT NVARCHAR(10) = ''
                ,@LOT_SEQ NVARCHAR(20) = ''
        -- 앞에 실적 공정이 있으면? 앞 LOT 를 따라가야 되고, 아니면 새로 채번인것이다.
        IF NOT EXISTS(SELECT *FROM @RESULT_PROC WHERE OUT_CHK = 'Y')
        BEGIN 
            INSERT INTO @USEM_INFO (           
            CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY, LOT_INFO            
            )  
            -- 여기서 부터 LOT 발생을 진행해야 된다. 
            SELECT C.SEQ, D.ITEM_CD, D.LOT_NO, C.ITEM_CLASS, D.ITEM_TP, C.ITEM_GROUP_CD3, D.QTY, D.LOT_INFO
            FROM PD_ORDER A WITH (NOLOCK)        
            INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD        
            INNER JOIN BA_LOT_CREATE_SEQ C WITH (NOLOCK) ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD AND B.ITEM_ACCT = C.ITEM_ACCT        
            LEFT JOIN        
            (
                SELECT A.CNT AS SEQ, A.ITEM_CD, A.LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP, B.ITEM_GROUP_CD3 AS ITEM_GROUP, A.QTY, B.LOT_INFO
                FROM @USEM_BACK A 
                INNER JOIN V_ITEM B WITH (NOLOCK) ON B.PLANT_CD = @PLANT_CD AND A.ITEM_CD = B.ITEM_CD AND B.ITEM_CLASS <> '4000'
                INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON B.ITEM_CLASS = C.SUB_CD AND C.MAIN_CD = 'B0004'
            ) D ON C.ITEM_CLASS = CASE WHEN D.ITEM_CLASS = '3000' THEN '2000' ELSE D.ITEM_CLASS END  AND C.ITEM_GROUP_CD3 = D.ITEM_GROUP        
                
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION        
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD        
            AND A.LINE_CD = @LINE_CD    

            SELECT *FROM @USEM_INFO -- CHK
            DECLARE @LOT_CHK NVARCHAR(1) = 'N'

            SET @TOP_LOT = 'G' + CONVERT(NVARCHAR(4),CAST((dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')
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
                
            SELECT CONVERT(NVARCHAR(7), CAST((dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')   
            ) AS DATETIME), 120)            
            )           
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
            )           
            BEGIN            
                SELECT @LOT_SEQ = CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) + dbo.LPAD(A.LOT_SEQ + CASE WHEN @LOT_CHK = 'N' THEN 1 ELSE 0 END,3,0)           
                FROM PD_LOT_SEQ A WITH (NOLOCK)            
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (           
                
                SELECT CONVERT(NVARCHAR(7), CAST((dbo.UFNSR_GET_DAYNIGHT(GETDATE(),'T')       
                ) AS DATETIME), 120)            
                )           
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
            END            
            ELSE            
            BEGIN            
                SELECT @LOT_SEQ = CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) + dbo.LPAD(1,3,0)           
            END            
            -- 합체
            SET @CREATE_LOT = 
            --SELECT 
            @TOP_LOT + '-' + @MID_LOT + '-' + @BOT_LOT + '-' + @LOT_SEQ
        END 
        ELSE 
        BEGIN 
            -- 혼합 이후 실적 공정일 경우는 앞에 LOT 를 채번해서 같이 조합을 진행해야 된다. 
            -- 이건 뭐...
            SELECT '1'
        END 
    END
    
END 