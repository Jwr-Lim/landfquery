/*    
기안번호 : PM250714009   
기안구분 : 불필   
제목 : 06A 혼합 LOT 채번 규칙 변경  
일자 : 2025-07-14    
작업자 : 임종원 이사   
*/    
     
      
CREATE PROC USP_POP_004_LOT_CREATE(               
               
--DECLARE                
        @DIV_CD          NVARCHAR(10) = '01'                
       ,@PLANT_CD        NVARCHAR(10) = '1140'               
       ,@ORDER_NO        NVARCHAR(50) = 'PD231212003'               
       ,@REVISION        INT = 2                
       ,@ORDER_TYPE      NVARCHAR(10) = 'PP01'                
       ,@ORDER_FORM      NVARCHAR(10) = '10'               
       ,@ROUT_NO         NVARCHAR(10) = 'C01'                
       ,@ROUT_VER        INT = 1                
       ,@WC_CD           NVARCHAR(10) = '14GC'               
       ,@LINE_CD         NVARCHAR(10) = '14G05C'               
       ,@PROC_CD         NVARCHAR(10) = 'M'               
       ,@RESULT_SEQ      INT          = '2'               
       ,@LOT_CHK         NVARCHAR(1)  = 'N'              
       ,@MSG_CD          NVARCHAR(4)    OUTPUT                
       ,@MSG_DETAIL      NVARCHAR(MAX)  OUTPUT                
       ,@LOT_CREATE      NVARCHAR(100)  OUTPUT                
)               
AS                
               
BEGIN TRY                
    DECLARE                
         @TOP_LOT        NVARCHAR(6)  = ''               
        ,@MID_LOT        NVARCHAR(50) = ''               
        ,@BOT_LOT        NVARCHAR(2)  = ''               
        ,@LOT_SEQ        NVARCHAR(10)  = ''               
        ,@ORD_ITEM       INT = 0           
               
    -- BA_LOT_SYS 에서 찾아서 온다.                
               
    -- 중입경 소입경 구분을 합시다.                
    DECLARE @USEM_INFO TABLE (               
         CNT          INT               
        ,ITEM_CD      NVARCHAR(50)                
        ,LOT_NO       NVARCHAR(50)                
        ,ITEM_CLASS   NVARCHAR(10)                
        ,ITEM_TP      NVARCHAR(10)                
        ,ITEM_GROUP   NVARCHAR(10)                
        ,QTY          NUMERIC(18,3)                
    )               
              
  DECLARE @IN_CHK     NVARCHAR(1)               
       ,@MIN_CHK        NVARCHAR(1)              
       ,@OUT_CHK        NVARCHAR(1)              
       ,@GROUP_S        NVARCHAR(1)              
       ,@GROUP          NVARCHAR(1)               
       ,@GROUP_E        NVARCHAR(1)               
       ,@RETURN_LOT_NO  NVARCHAR(50) = '' -- 최종 리턴 LOT               
       ,@NS_CHK         NVARCHAR(1)  = ''            
     --  ,@MASTER_LOT    NVARCHAR(50) = ''              
                  
    SELECT @IN_CHK = A.IN_CHK, @MIN_CHK = A.MIN_CHK, @OUT_CHK = A.OUT_CHK, @GROUP_S = A.GROUP_S, @GROUP = dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),              
    @GROUP_E = A.GROUP_E, @NS_CHK = ISNULL(A.NS_CHK,'N')              
    FROM PD_ORDER_PROC A WITH (NOLOCK)               
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND               
    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND               
    A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD              
           
           
    SELECT @ORD_ITEM = LEN(B.LOT_INFO)-LEN(REPLACE(B.LOT_INFO,'-',''))           
           
        FROM PD_ORDER A WITH (NOLOCK)            
        INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD            
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDEr_NO = @ORDER_NO AND A.REVISION = @REVISION            
    AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER            
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
           
    -- LOT 채번이 없을 경우는 자기 자신의 LOT 를 그대로 가지고 와야 된다. 처리 하자.           
    IF @NS_CHK = 'Y' OR (@NS_CHK = 'N' AND @WC_CD = '13P')     
    BEGIN            
        SET @LOT_CREATE = ISNULL((         
            SELECT TOP 1 A.MASTER_LOT     
                FROM PD_USEM A WITH (NOLOCK)            
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION            
  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
              AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ            
        ),'*')           
           
        UPDATE A SET A.LOT_NO = @LOT_CREATE FROM PD_RESULT A WITH (NOLOCK)            
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
          AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD            
          AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ            
                     
        RETURN 0           
           
    END            
     
               
    IF @OUT_CHK = 'Y'              
    BEGIN               
        IF (SELECT C.DAUAT FROM  PD_ORDER A WITH (NOLOCK)               
        INNER JOIN SAP_Z02MESF_P010_DTL B WITH (NOLOCK) ON A.PLANT_CD = B.WERKS AND A.ORDEr_NO = B.MES_ORDER_NO AND A.REVISION = B.MES_REVISION              
        INNER JOIN SAP_Z02MESF_P010_HDR C WITH (NOLOCK) ON B.WERKS = C.WERKS AND B.AUFNR = C.AUFNR              
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION               
          AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD               
          AND A.LINE_CD = @LINE_CD ) = 'PP04'               
        BEGIN          
                      
            -- 재처리 프로세스를 탑니다.               
            IF EXISTS(SELECT *FROM PD_USEM A WITH (NOLOCK)               
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION               
            AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER               
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ               
            )               
            BEGIN                  
                -- 선입선출은 이미 때려 졌으니              
                -- 대표 MASTER_LOT 를 가지고 와서 채번을 지정 해야 된다.               
                -- 이게 첫번째인가 아닌가? 를 판단하자.          
                -- 가장 큰것을R 가지고 와야겠지..         
        
                DECLARE @MASTER_LOT NVARCHAR(50) = ''              
                SET @MASTER_LOT = ISNULL((SELECT TOP 1 A.MASTER_LOT FROM PD_USEM A WITH (NOLOCK)               
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION               
                AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER               
                AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ               
                GROUP BY A.MASTER_LOT        
                 ORDER BY SUM(A.USEM_QTY) DESC         
        
                ),'')             
        
                   
--                SELECT @MASTER_LOT          
                SET @MASTER_LOT = REPLACE(@MASTER_LOT, '(잔량)','') 
                 
                DECLARE @RSEQ INT = 0              
         
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
              
--                SELECT @LOT_CREATE, CHARINDEX('-R',@LOT_CREATE,LEN(@LOT_CREATE) - 4)              
                              
                              
              
                UPDATE A SET A.LOT_NO = @LOT_CREATE, A.J_CHK = 'R', A.J_SEQ = @RSEQ              
                FROM PD_RESULT A WITH (NOLOCK)                
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                
                AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                
              
                RETURN 0               
            END               
              
        END               
              
    END               
              
              
    IF @IN_CHK = 'Y' AND @OUT_CHK = 'Y'               
    BEGIN            
        INSERT INTO @USEM_INFO (               
        CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY                
        )               
                
        SELECT TOP 1 ROW_NUMBER() OVER (ORDER BY A.USEM_QTY DESC, A.USEM_SEQ) AS CNT,               
        A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, A.USEM_QTY AS QTY              
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
              
    END               ELSE               
    BEGIN             
        -- 자 여기서 어떻게 처리를 하느냐..           
        -- 현재 공정의 기준이 되어야 되는 부분을 찾아야 된다.. 즉...            
           
/*           
        SELECT B1.*           
        FROM PD_ORDER A WITH (NOLOCK)            
        INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD            
        INNER JOIN PD_ORDER_USEM B1 WITH (NOLOCK) ON A.DIV_CD = B1.DIV_CD AND A.PLANT_CD = B1.PLANT_CD AND A.ORDER_NO = B1.ORDER_NO            
        AND A.REVISION = B1.REVISION AND A.ORDER_TYPE = B1.ORDER_TYPE AND A.ORDER_FORM = B1.ORDER_FORM            
        AND A.ROUT_NO = B1.ROUT_NO AND A.ROUT_VER = B1.ROUT_VER AND A.WC_CD = B1.WC_CD AND A.LINE_CD = B1.LINE_CD --AND B1.PROC_CD = @PROC_CD            
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD            
*/           
           
        INSERT INTO @USEM_INFO (               
        CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY                
        )               
              
        SELECT C.SEQ, D.ITEM_CD, D.LOT_NO, C.ITEM_CLASS, D.ITEM_TP, C.ITEM_GROUP_CD3, D.QTY            
        FROM PD_ORDER A WITH (NOLOCK)            
        INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD            
        INNER JOIN BA_LOT_CREATE_SEQ C WITH (NOLOCK) ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD AND B.ITEM_ACCT = C.ITEM_ACCT            
        LEFT JOIN            
        (           
            SELECT AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, SUM(AA.QTY) AS QTY--, BB.SEQ              
            FROM                
            (               
                 SELECT ROW_NUMBER() OVER (ORDER BY MIN(D.SEQ)) AS CNT,              
                ROW_NUMBER() OVER (PARTITION BY B.ITEM_CLASS, B.ITEM_GROUP_CD3 ORDER BY B.ITEM_GROUP_CD3, SUM(A.USEM_QTY) DESC) AS RANK,                
                  
                A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, SUM(A.USEM_QTY) AS QTY, C2.ITEM_ACCT, C1.ITEM_CD AS PRNT_ITEM_CD              
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
     GROUP BY A.ITEM_CD, A.MASTER_LOT, B.ITEM_CLASS, B.ITEM_GROUP_CD3, C.TEMP_CD1, D.ITEM_TP, D.ITEM_GROUP , C2.ITEM_ACCT, C1.ITEM_CD            
           
            ) AA               
            WHERE AA.RANK = 1              
            GROUP BY AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, AA.ITEM_ACCT           
                       
        ) D ON C.ITEM_CLASS = CASE WHEN D.ITEM_CLASS = '3000' THEN '2000' ELSE D.ITEM_CLASS END  AND C.ITEM_GROUP_CD3 = D.ITEM_GROUP            
           
 WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION            
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD            
        AND A.LINE_CD = @LINE_CD            
           
/*           
        SELECT AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, SUM(AA.QTY) AS QTY--, BB.SEQ              
        FROM                
        (               
            SELECT ROW_NUMBER() OVER (ORDER BY MIN(D.SEQ)) AS CNT,              
            ROW_NUMBER() OVER (PARTITION BY A.MASTER_LOT ORDER BY B.ITEM_GROUP_CD3, SUM(A.USEM_QTY) DESC) AS RANK,                
              
            A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, SUM(A.USEM_QTY) AS QTY, C2.ITEM_ACCT, C1.ITEM_CD AS PRNT_ITEM_CD              
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
            GROUP BY A.ITEM_CD, A.MASTER_LOT, B.ITEM_CLASS, B.ITEM_GROUP_CD3, C.TEMP_CD1, D.ITEM_TP, D.ITEM_GROUP , C2.ITEM_ACCT, C1.ITEM_CD              
                     
        ) AA               
        WHERE AA.RANK = 1           
        GROUP BY AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, AA.ITEM_ACCT           
                   
        INSERT INTO @USEM_INFO (               
        CNT, ITEM_CD, LOT_NO, ITEM_CLASS, ITEM_TP, ITEM_GROUP, QTY                
        )               
        SELECT ROW_NUMBER() OVER (ORDER BY ISNULL(BB.SEQ,MIN(AA.CNT))) AS CNT, AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, SUM(AA.QTY) AS QTY--, BB.SEQ              
        FROM                
        (               
            SELECT ROW_NUMBER() OVER (ORDER BY MIN(D.SEQ)) AS CNT,              
            ROW_NUMBER() OVER (PARTITION BY A.MASTER_LOT ORDER BY B.ITEM_GROUP_CD3, SUM(A.USEM_QTY) DESC) AS RANK,                
              
            A.ITEM_CD, A.MASTER_LOT AS LOT_NO, B.ITEM_CLASS, C.TEMP_CD1 AS ITEM_TP,  B.ITEM_GROUP_CD3 AS ITEM_GROUP, SUM(A.USEM_QTY) AS QTY, C2.ITEM_ACCT, C1.ITEM_CD AS PRNT_ITEM_CD     
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
            GROUP BY A.ITEM_CD, A.MASTER_LOT, B.ITEM_CLASS, B.ITEM_GROUP_CD3, C.TEMP_CD1, D.ITEM_TP, D.ITEM_GROUP , C2.ITEM_ACCT, C1.ITEM_CD              
                     
        ) AA               
        LEFT JOIN BA_LOT_CREATE_SEQ BB WITH (NOLOCK) ON AA.ITEM_ACCT = BB.ITEM_ACCT AND AA.ITEM_CLASS = BB.ITEM_CLASS AND AA.ITEM_GROUP = BB.ITEM_GROUP_CD3              
        WHERE AA.RANK = 1              
        GROUP BY AA.ITEM_CD, AA.LOT_NO, AA.ITEM_CLASS, AA.ITEM_TP, AA.ITEM_GROUP, AA.ITEM_ACCT, BB.SEQ              
        ORDER BY ISNULL(BB.SEQ,99) ASC              
           
   */           
              
    END               
           
    --ORDER BY B.ITEM_GROUP_CD3 DESC -- 이거 나중에 기준정보로 가지고 와야 된다.  -- 중입경 소입경 전구체 리튬 구분이 필요하다. 순서가...               
    --SELECT *FROM BA_LOT_SYS A WITH (NOLOCK)                
    --WHERE A.DIV_CD = @DIV_CD AND ITEM_CD = @ITEM_CD                
               
    --SELECT *FROM @USEM_INFO           
           
    DECLARE @LOT_CREATE_TBL AS TABLE (               
         CNT        INT                
        ,COL_TP     NVARCHAR(10)                
        ,HYPHEN_YN  NVARCHAR(10)                
        ,VAL        NVARCHAR(10)                
    )               
               
    -- 중입경, 소입경 구분으로                
               
    DECLARE @CNT     INT = 0               
           ,@TCNT    INT = 0               
               
    SELECT @TCNT = COUNT(*) FROM @USEM_INFO                
               
    WHILE @CNT <> @TCNT                
    BEGIN                
        SET @CNT = @CNT + 1                
        DECLARE @ITEM_CD       NVARCHAR(50) = ''              
               ,@LOT_NO        NVARCHAR(50) = ''                
               ,@ITEM_CLASS    NVARCHAR(10) = ''                
               ,@ITEM_TP       NVARCHAR(10) = ''                
               ,@ITEM_GROUP    NVARCHAR(10) = ''                
               ,@QTY           NUMERIC(18,4) = 0                
  
        SELECT @ITEM_CD = ITEM_CD, @LOT_NO = LOT_NO, @ITEM_CLASS = ITEM_CLASS, @ITEM_TP = ITEM_TP, @ITEM_GROUP = ITEM_GROUP, @QTY = QTY FROM @USEM_INFO WHERE CNT = @CNT                
               
        -- BA_LOT_SYS 에 있는지부터 확인해야 된다.                
               
                      
                     INSERT INTO @LOT_CREATE_TBL                
        (               
            CNT,         COL_TP,            HYPHEN_YN               
        )               
        SELECT ROW_NUMBER() OVER (ORDER BY A.SEQ) AS CNT, A.COL_TP, A.HYPHEN_YN                
        FROM PD_LOT_SYS A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = @PROC_CD AND A.ITEM_TP = @ITEM_TP AND                
        A.ITEM_GROUP = @ITEM_GROUP               
              
              
        IF NOT EXISTS(   SELECT ROW_NUMBER() OVER (ORDER BY A.SEQ) AS CNT, A.COL_TP, A.HYPHEN_YN                
        FROM PD_LOT_SYS A WITH (NOLOCK) WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.PROC_CD = @PROC_CD AND A.ITEM_TP = @ITEM_TP AND                
        A.ITEM_GROUP = @ITEM_GROUP)              
        BEGIN               
            -- 자리수 만큼 잘라야 된다.               
            DECLARE @LOT_INFO NVARCHAR(50) = ''               
                   ,@ITEM_UT  NVARCHAR(1)  = ''              
              
            SELECT @LOT_INFO = A.LOT_INFO, @ITEM_UT = B.TEMP_CD1              
                FROM V_ITEM A WITH (NOLOCK)               
                INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'              
                WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD               
              
            IF @LOT_INFO = ''            
            BEGIN            
                IF @ORD_ITEM = 3            
                BEGIN            
             SET @LOT_INFO = 'XXX-XXX'           
                END            
                ELSE            
                BEGIN            
                    SET @LOT_INFO = 'XXX'           
                END            
            END            
                       
            DECLARE @BA_SPLIT_TBL TABLE (              
                 CNT     INT               
                ,V       NVARCHAR(10)                
            )              
              
            DELETE @BA_SPLIT_TBL               
                          
            INSERT INTO @BA_SPLIT_TBL              
            SELECT ROW_NUMBER() OVER (ORDER BY VALUE) * 2 AS CNT, VALUE AS V FROM string_split(@LOT_INFO,'-')              
            -- 하이푼이 중요하다. 하이푼에 따라서 잘라낸다.               
            --SELECT *FROM @BA_SPLIT_TBL            
           
            INSERT INTO @LOT_CREATE_TBL (              
                CNT, COL_TP, HYPHEN_YN              
            )                          
            SELECT ROW_NUMBER() OVER (ORDER BY AA.C) AS CNT, AA.COL_TP, AA.HYPHEN_YN              
            FROM (              
                SELECT CNT - 1 AS C ,'UT_TP' + CAST(@CNT AS NVARCHAR) AS COL_TP,  @ITEM_UT AS V, 'N' AS HYPHEN_YN FROM @BA_SPLIT_TBL               
                UNION ALL               
                SELECT CNT AS C ,'MAKER' + CAST(@CNT AS NVARCHAR) AS COL_TP, V,'Y' AS HYPHEN_YN FROM @BA_SPLIT_TBL              
                              
            ) AA               
            ORDER BY AA.C ASC                      
        END               
                   
        DECLARE @L_CNT    INT = 0                
               ,@L_TCNT   INT = 0     
        SET @L_CNT  = 0               
        SET @L_TCNT = ISNULL((SELECT COUNT(*) FROM @LOT_CREATE_TBL),0)               
           
        IF NOT EXISTS(SELECT *FROM BA_LOT_SYS A WITH (NOLOCK)                
        WHERE A.DIV_CD = @DIV_CD AND A.ITEM_CD= @ITEM_CD)               
        BEGIN                
            --  없으면?               
            --  품목코드에서 잘라와야지..                
            --  LOT 에서 잘라와야지 -> 두개가 맞는질를                
           
    
            WHILE @L_CNT <> @L_TCNT                
            BEGIN                
                SET @L_CNT = @L_CNT + 1                
                               
                IF @L_CNT = 1                
                BEGIN                
                    UPDATE A SET A.VAL = ISNULL((SELECT LEFT(A.LOT_INFO,1)              
                        FROM V_ITEM A WITH (NOLOCK)               
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ),'X')               
                        FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT  AND A.VAL IS NULL              
                END                
               
                IF @L_CNT = 2                
 BEGIN                
                                  
                    UPDATE A SET A.VAL = ISNULL((SELECT CASE WHEN LEN(A.LOT_INFO) = 7 THEN SUBSTRING(A.LOT_INFO, 2,2) ELSE RIGHT(A.LOT_INFO,2) END              
                        FROM V_ITEM A WITH (NOLOCK)               
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ),'XX')               
                        FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL              
                END                
               
                IF @L_CNT = 3                
                BEGIN                
                    UPDATE A SET A.VAL = ISNULL((SELECT CASE WHEN LEN(A.LOT_INFO) = 7 THEN SUBSTRING(A.LOT_INFO,5,1) ELSE LEFT(A.LOT_INFO,1) END              
    FROM V_ITEM A WITH (NOLOCK)               
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'X')               
                        FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL               
                END                
               
                IF @L_CNT = 4               
           BEGIN                
                                  
                    UPDATE A SET A.VAL = ISNULL((SELECT RIGHT(A.LOT_INFO,2)                
                        FROM V_ITEM A WITH (NOLOCK)               
                        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                    WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'XX')               
                        FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL              
                END                
            END                
    --        SELECT SUBSTRING(@LOT_NO, 7,7)               
              
        END                     
         ELSE                
        BEGIN                
            DECLARE @LOT_SYS_TBL TABLE (               
             SEQ        INT                
            ,ITEM_TP    NVARCHAR(10)                 
            ,CHAR       NVARCHAR(10)                
            ,CHAR_IDX   INT                
            ,START_CHAR NVARCHAR(10)                
            ,UT_TP      NVARCHAR(10)                
            ,MAKER      NVARCHAR(10)                
            ,CHK        NVARCHAR(1)                
            ,STR        NVARCHAR(10)         
            )               
            -- LOT_SYS 에 전체 데이터를 가지고 와야 된다.                
                           
            INSERT INTO @LOT_SYS_TBL (               
                SEQ, ITEM_TP, CHAR, CHAR_IDX, START_CHAR, UT_TP, MAKER               
            )               
            SELECT SEQ, ITEM_TP, CHAR, CHAR_IDX, START_CHAR, UT_TP, MAKER FROM BA_LOT_SYS A WITH (NOLOCK)                
            WHERE A.DIV_CD = @DIV_CD AND A.ITEM_CD = @ITEM_CD                
               
            UPDATE A SET A.CHK =                
            CASE WHEN RIGHT(SUBSTRING(@LOT_NO, CHARINDEX(A.START_CHAR, @LOT_NO), A.CHAR_IDX), LEN(A.CHAR)) = A.CHAR THEN 'Y' ELSE 'N' END               
            , A.STR = A.UT_TP + A.MAKER               
            FROM @LOT_SYS_TBL A               
                        
            -- 두자리가 아니라면?                
            IF (SELECT COUNT(*) FROM @LOT_SYS_TBL A WHERE A.CHK = 'Y') <> 2               
            BEGIN         
                SET @L_CNT = 0               
                SET @L_TCNT = ISNULL((SELECT COUNT(*) FROM @LOT_CREATE_TBL WHERE VAL IS NULL),0)               
                -- 품목 정보에서 가지고 온다.               
                WHILE @L_CNT <> @L_TCNT                
                BEGIN                
                    SET @L_CNT = @L_CNT + 1                
                                   
                    IF @L_CNT = 1                
                    BEGIN                
                        UPDATE A SET A.VAL = ISNULL((SELECT LEFT(A.LOT_INFO,1)              
                            FROM V_ITEM A WITH (NOLOCK)               
                            INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'X')               
                            FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT  AND A.VAL IS NULL              
                    END                
           
                    IF @L_CNT = 2                
                    BEGIN                
                                      
                        UPDATE A SET A.VAL = ISNULL((SELECT CASE WHEN LEN(A.LOT_INFO) = 7 THEN SUBSTRING(A.LOT_INFO, 2,2) ELSE RIGHT(A.LOT_INFO,2) END              
                            FROM V_ITEM A WITH (NOLOCK)               
                            INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                            WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'XX')               
                            FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL              
                    END                
                   
                    IF @L_CNT = 3                
                    BEGIN                
                        UPDATE A SET A.VAL = ISNULL((SELECT CASE WHEN LEN(A.LOT_INFO) = 7 THEN SUBSTRING(A.LOT_INFO,5,1) ELSE LEFT(A.LOT_INFO,1) END              
                            FROM V_ITEM A WITH (NOLOCK)               
                            INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
                        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'X')               
                            FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL               
                    END                
                   
                    IF @L_CNT = 4               
                    BEGIN                
                                      
                        UPDATE A SET A.VAL = ISNULL((SELECT RIGHT(A.LOT_INFO,2)                
                            FROM V_ITEM A WITH (NOLOCK)               
                            INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.ITEM_GROUP_CD2 = B.SUB_CD AND B.MAIN_CD = 'B0002'               
  WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD ), 'XX')               
                            FROM @LOT_CREATE_TBL A WHERE A.CNT = @L_CNT AND A.VAL IS NULL              
                    END                
                END                
               
            END                
            ELSE                
            BEGIN                
                               
                SET @L_CNT = 0                
                SET @L_TCNT = ISNULL((SELECT COUNT(*) FROM @LOT_CREATE_TBL WHERE VAL IS NULL),0)               
               
                WHILE @L_CNT <> @L_TCNT                
                BEGIN                
                    SET @L_CNT = @L_CNT + 1               
               
                    DECLARE @VAL NVARCHAR(10)                
               
                    IF @L_CNT = 1 BEGIN SET @VAL = (SELECT TOP 1 UT_TP FROM @LOT_SYS_TBL WHERE CHK = 'Y' ORDER BY SEQ) END                
                    IF @L_CNT = 2 BEGIN SET @VAL = (SELECT TOP 1 MAKER FROM @LOT_SYS_TBL WHERE CHK = 'Y' ORDER BY SEQ) END                
                    IF @L_CNT = 3 BEGIN SET @VAL = (SELECT TOP 1 UT_TP FROM @LOT_SYS_TBL WHERE CHK = 'Y' ORDER BY SEQ DESC) END                
                    IF @L_CNT = 4 BEGIN SET @VAL = (SELECT TOP 1 MAKER FROM @LOT_SYS_TBL WHERE CHK = 'Y' ORDER BY SEQ DESC) END                
               
                    UPDATE A SET A.VAL = @VAL                
                    FROM @LOT_CREATE_TBL A                
                    WHERE A.CNT = @L_CNT AND A.VAL IS NULL               
                           
                END               
            END                
        END       
               
    END                
               
           
    DECLARE @LAST_TBL AS TABLE                
    (              CNT       INT    IDENTITY(1,1)                
        ,COL_TP    NVARCHAR(10)                
        ,HYPHEN_YN NVARCHAR(10)               
        ,VAL       NVARCHAR(10)                
    )               
               
    INSERT INTO @LAST_TBL(COL_TP, HYPHEN_YN, VAL)               
    SELECT COL_TP, HYPHEN_YN, VAL FROM @LOT_CREATE_TBL                
               
    DECLARE @LAST_CNT    INT = 0               
           ,@LAST_TCNT   INT = 0                
            
    SET @LAST_TCNT = ISNULL((SELECT COUNT(*) FROM @LAST_TBL),0)                
               
    WHILE @LAST_CNT <> @LAST_TCNT               
    BEGIN                
               
        SET @LAST_CNT = @LAST_CNT + 1                
               
        SET @MID_LOT = @MID_LOT + (SELECT VAL + CASE WHEN HYPHEN_YN = 'Y' THEN '-' ELSE '' END FROM @LAST_TBL WHERE CNT = @LAST_CNT)               
    END                
               
    SET @TOP_LOT = 'G' + CONVERT(NVARCHAR(4),CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)               
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                
    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                
    A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                
    ) AS DATETIME  ), 12)               
                   
    DECLARE @P_ITEM_CD NVARCHAR(50) = ''      
      
    SELECT @P_ITEM_CD = ITEM_CD FROM PD_ORDER A WITH (NOLOCK)       
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION       
      
    SET @BOT_LOT =       
          
    CASE WHEN ISNULL((      
      SELECT B.TEMP_CD5       
        FROM V_ITEM A WITH (NOLOCK)       
        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'      
        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @P_ITEM_CD       
      
    ),'') = '' THEN       
    ISNULL((  
                  SELECT A.PROC_INITIAL  
                FROM BA_LINE A WITH (NOLOCK)   
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD   AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD)  
                    ,(     
                                   
      SELECT A.LOT_INITIAL FROM  BA_ROUTING_HEADER A WITH (NOLOCK)                              
      WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ROUT_NO = @ROUT_NO AND A.[VERSION] = @ROUT_VER ))  
    ELSE       
      ISNULL((      
        SELECT B.TEMP_CD5       
        FROM V_ITEM A WITH (NOLOCK)       
        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.REP_ITEM_CD = B.SUB_CD AND B.MAIN_CD = 'BA211'      
        WHERE A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @P_ITEM_CD       
            
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
           
    --SELECT *FROM BA_SUB_CD WHERE MAIN_CD = 'SAP01'               
               
    -- 채번 진행               
               
               
    IF EXISTS(SELECT *FROM PD_LOT_SEQ A WITH (NOLOCK)                
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (               
               
    SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)               
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                
    A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                
    A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ               
    ) AS DATETIME), 120)                
    )               
    AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                
    )               
    BEGIN                
     SELECT @LOT_SEQ = --CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR)     
        CASE WHEN '14C' IN ('14C') THEN       
        ISNULL((SELECT TOP 1 LOT_INFO FROM BA_LINE WITH (NOLOCK) WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD       
        AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE       
        CAST(                     
        CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END    
    
        + dbo.LPAD(A.LOT_SEQ + CASE WHEN @LOT_CHK = 'N' THEN 1 ELSE 0 END,3,0)               
        FROM PD_LOT_SEQ A WITH (NOLOCK)                
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.DT = (               
               
        SELECT CONVERT(NVARCHAR(7), CAST((SELECT A.SIL_DT FROM PD_RESULT A WITH (NOLOCK)               
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND                
       A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND                
        A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ               
        ) AS DATETIME), 120)                
        )               
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                
    END                
    ELSE                
    BEGIN                
        SELECT @LOT_SEQ = --CAST(CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR)     
        CASE WHEN '14C' IN ('14C') THEN       
        ISNULL((SELECT TOP 1 LOT_INFO FROM BA_LINE WITH (NOLOCK) WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD       
        AND WC_CD = @WC_CD AND LINE_CD = @LINE_CD),@LINE_CD) ELSE       
        CAST(                     
        CAST(SUBSTRING(@LINE_CD,4,2) AS INT) AS NVARCHAR) END    
            
        + dbo.LPAD(1,3,0)               
    END                
    --SELECT *FROM PD_ORDER              
              
    SELECT @LOT_CREATE = @TOP_LOT + '-' + @MID_LOT + @BOT_LOT + '-' + @LOT_SEQ  
               
    UPDATE A SET A.LOT_NO = @LOT_CREATE, LOT_SEQ = CAST(RIGHT(@LOT_CREATE,3) AS INT)               
        FROM PD_RESULT A WITH (NOLOCK)                
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                
    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                
              
    IF @LOT_CHK IN ('J','F')               
    BEGIN               
        SET @LOT_SEQ = @LOT_SEQ + '-' +               
        (SELECT A.J_CHK + CAST(A.J_SEQ AS NVARCHAR)              
        FROM PD_RESULT A WITH (NOLOCK)               
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION               
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD               
        AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ)              
    END               
              
    -- 마지막 공정일 경우               
IF EXISTS(SELECT               
        B.*FROM PD_ORDER_PROC A WITH (NOLOCK)               
        INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.PROC_NO = B.PROC_NO               
        AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER               
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_SEQ < B.PROC_SEQ               
        WHERE A.DIV_CD = @DIV_cD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_FORM = @ORDER_FORM               
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD              
    )              
    BEGIN               
        SELECT @LOT_CREATE = @TOP_LOT + '-' + @MID_LOT + @BOT_LOT + '-' + @LOT_SEQ               
END               
    ELSE               
    BEGIN               
        SELECT @LOT_CREATE = @TOP_LOT + '-' + @MID_LOT + @BOT_LOT + '-' + @LOT_SEQ               
    END               
              
    UPDATE A SET A.LOT_NO = @LOT_CREATE              
        FROM PD_RESULT A WITH (NOLOCK)                
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM                
    AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ                
              
              
END TRY                
BEGIN CATCH                
    SET @MSG_CD = '9999'               
    SET @MSG_DETAIL = ERROR_MESSAGE()                
    RETURN 1               
END CATCH                
--SELECT *FROM PD_LOT_SEQ WITH (NOLOCK) 