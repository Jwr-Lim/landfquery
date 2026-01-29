/* 
기안번호 : PM241007008 
기안구분 : 일반 
제목 : 원료투입시 이전 설비 자동 선택 
일자 : 24.10.18 
작업자 : 임종원 이사 
*/ 
 
  
  
ALTER PROC USP_POP_004_PROC_SPEC_EQP_INFO(      
--DECLARE       
     @DIV_CD       NVARCHAR(10)     = '01'      
    ,@PLANT_CD     NVARCHAR(10)     = '1140'      
    ,@ORDER_NO     NVARCHAR(50)     = 'PD240115001'      
    ,@REVISION     INT              = 1      
    ,@ORDER_TYPE   NVARCHAR(10)     = 'PP01'      
    ,@ORDER_FORM   NVARCHAR(10)     = '10'      
    ,@ROUT_NO      NVARCHAR(10)     = 'A01'      
    ,@ROUT_VER     INT              = '2'      
    ,@WC_CD        NVARCHAR(10)     = '14GA'      
    ,@LINE_CD      NVARCHAR(10)     = '14G07A'      
    ,@PROC_CD      NVARCHAR(10)     = 'RI'      
    ,@EQP_CD       NVARCHAR(50)     = ''       
    ,@SDATE        DATETIME         = NULL      
-- 해당 정보에 설비코드가 있는지를 확인한다.       
)      
AS       
      
SET NOCOUNT ON      
      
IF @SDATE IS NULL BEGIN SET @SDATE = GETDATE() END       
      
DECLARE     @SKIP        NVARCHAR(1)  = 'N'      
           ,@IN_CHK      NVARCHAR(1)  = 'N'      
           ,@OUT_CHK     NVARCHAR(1)  = 'N'      
           ,@MIN_CHK     NVARCHAR(1)  = 'N'      
           ,@GROUP_S     NVARCHAR(1)  = 'N'      
           ,@GROUP       NVARCHAR(1)  = 'N'      
           ,@GROUP_E     NVARCHAR(1)  = 'N'      
           ,@QC_CHK      NVARCHAR(1)  = 'N'      
           ,@S_CHK       NVARCHAR(1)  = 'N'      
           ,@PROC_SEQ    INT          =  0       
           ,@GROUP_YN    NVARCHAR(1)  = 'N'      
           ,@EQP_CHK     NVARCHAR(1)  = 'N'      
      
    SELECT @SKIP = A.SKIP, @IN_CHK = A.IN_CHK, @OUT_CHK = A.OUT_CHK, @MIN_CHK = A.MIN_CHK, @GROUP_S = A.GROUP_S, @GROUP =       
    dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_CD, 'N'),      
    @GROUP_E = A.GROUP_E, @QC_CHK = A.QC_CHK, @PROC_SEQ = A.PROC_SEQ, @S_CHK = A.S_CHK, @EQP_CHK = A.EQP_CHK      
    FROM PD_ORDER_PROC A WITH (NOLOCK)       
WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
  AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
      
DECLARE @DATA_TABLE TABLE (      
     CNT               INT IDENTITY(1,1)       
    ,WC_CD             NVARCHAR(10)       
    ,LINE_CD           NVARCHAR(10)      
    ,EQP_CD            NVARCHAR(50)       
    ,EQP_NM            NVARCHAR(50)      
    ,ENO_PROC_CD       NVARCHAR(10)       
    ,TP                NVARCHAR(10)        
    ,ITEM_CD           NVARCHAR(50)       
    ,SUB_NM            NVARCHAR(50)       
    ,REP_ITEM_CD       NVARCHAR(50)       
    ,USEM_ITEM_GROUP   NVARCHAR(50)       
    ,GBN               NVARCHAR(1)       
)      
      
-- 투입이고... 설비 선택이 체크가 되어 있으면, 품종이 아니라 대표 품목코드로 확인할것       
      
IF @IN_CHK = 'Y' AND @OUT_CHK = 'N' AND @EQP_CHK = 'Y'      
BEGIN      
 
    INSERT INTO @DATA_TABLE (      
        WC_CD, LINE_CD, EQP_CD, EQP_NM, ENO_PROC_CD, TP, ITEM_CD, SUB_NM, REP_ITEM_CD, USEM_ITEM_GROUP, GBN      
    )      
   SELECT A.WC_CD, A.LINE_CD, CASE WHEN A.PROC_CD IN ('SE','FG') THEN A.TP ELSE A.EQP_CD END , A.EQP_NM, A.PROC_CD, A.TP, C.ITEM_CD, B1.SUB_NM, C.REP_ITEM_CD, B2.USEM_ITEM_GROUP, 'N'      
  FROM BA_EQP A WITH (NOLOCK)       
 -- INNER JOIN POP_EQP_ENO B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.EQP_CD = B.EQP_CD AND B.ENO_PROC_CD = @PROC_CD       
  INNER JOIN BA_SUB_CD B1 WITH (NOLOCK) ON A.TP = B1.SUB_CD AND B1.MAIN_CD = 'BA205'      
  LEFT JOIN PD_ORDER_PROC_SPEC B2 WITH (NOLOCK) ON A.EQP_CD = B2.EQP_CD AND B2.DIV_CD = @DIV_CD AND B2.PLANT_CD = @PLANT_CD AND B2.ORDEr_NO = @ORDER_NO       
  AND B2.REVISION = @REVISION AND B2.ORDER_TYPE = @ORDER_TYPE AND B2.ORDER_FORM = @ORDER_FORM AND B2.ROUT_NO = @ROUT_NO AND B2.ROUT_VER = @ROUT_VER AND B2.WC_CD = @WC_CD       
  AND B2.LINE_CD = @LINE_CD AND B2.PROC_CD = @PROC_CD       
  LEFT JOIN (SELECT A1.WC_CD, A1.LINE_CD, A1.PROC_CD, A1.ITEM_CD, B1.REP_ITEM_CD FROM PD_ORDER_USEM A1 WITH (NOLOCK)       
  INNER JOIN V_ITEM B1 WITH (NOLOCK) ON A1.PLANT_CD = B1.PLANT_CD AND A1.ITEM_CD = B1.ITEM_CD       
  WHERE A1.DIV_CD = @DIV_CD AND A1.PLANT_CD = @PLANT_CD AND A1.ORDER_NO = @ORDER_NO AND A1.REVISION = @REVISION AND A1.ORDER_TYPE = @ORDER_TYPE       
  AND A1.ORDER_FORM = @ORDER_FORM AND A1.ROUT_NO = @ROUT_NO AND A1.ROUT_VER = @ROUT_VER AND A1.WC_CD = @WC_CD AND A1.LINE_CD = @LINE_CD AND A1.PROC_CD = @PROC_CD       
  ) C ON A.WC_CD = C.WC_CD AND A.LINE_CD = C.LINE_CD AND A.PROC_CD = C.PROC_CD AND B2.USEM_ITEM_GROUP = C.REP_ITEM_CD      
  WHERE A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
  GROUP BY A.WC_CD, A.LINE_CD, A.EQP_CD, A.EQP_NM, A.PROC_CD, A.TP, C.ITEM_CD, B1.SUB_NM, C.REP_ITEM_CD, B2.USEM_ITEM_GROUP      
      
END       
      
-- 실적이고 설비선택이면 설비구분이 있는것을 확인한다.       
      
IF @IN_CHK = 'N' AND @OUT_CHK = 'Y' AND @EQP_CHK = 'Y'       
BEGIN       
      
  -- 해당 공정 정보와 BA_EQP 의 TP 를 확인해서 거기에 맞는 정보를 가지고 오자.       
  INSERT INTO @DATA_TABLE (      
        WC_CD, LINE_CD, EQP_CD, EQP_NM, ENO_PROC_CD, TP, ITEM_CD, SUB_NM, REP_ITEM_CD, USEM_ITEM_GROUP, GBN      
  )      
  SELECT A.WC_CD, A.LINE_CD, A.TP AS EQP_CD, C.SUB_NM AS EQP_NM, A.PROC_CD,A.TP,  '' AS ITEM_CD, '' AS SUB_NM, '' AS REP_ITEM_CD, '' AS USEM_ITEM_GROUP, 'Y'      
  FROM BA_EQP A WITH (NOLOCK)       
  INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON A.TP = C.SUB_CD AND C.MAIN_CD = 'BA205'      
  WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
  GROUP BY A.WC_CD, A.LINE_CD, A.EQP_CD, A.TP, C.SUB_NM, A.PROC_CD      
      
  IF @GROUP_E = 'N'       
  BEGIN       
    -- 공정을 합쳐서 하나 더 추가 한다.       
    INSERT INTO @DATA_TABLE (      
       WC_CD, LINE_CD, EQP_CD, EQP_NM, ENO_PROC_CD, TP, ITEM_CD, SUB_NM, REP_ITEM_CD, USEM_ITEM_GROUP, GBN      
    )      
    SELECT A.WC_CD, A.LINE_CD, 'Z' + STUFF((SELECT ',' + TP FROM @DATA_TABLE FOR XML PATH('')),1,1,'') AS EQP_CD, STUFF((SELECT ',' + EQP_NM FROM @DATA_TABLE FOR XML PATH('')),1,1,'') AS EQP_NM,      
    A.ENO_PROC_CD, STUFF((SELECT ',' + TP FROM @DATA_TABLE FOR XML PATH('')),1,1,''), A.ITEM_CD, A.SUB_NM, A.REP_ITEM_CD, A.USEM_ITEM_GROUP, A.GBN      
      FROM @DATA_TABLE A       
    GROUP BY A.WC_CD, A.LINE_CD, A.ENO_PROC_CD, A.ITEM_CD, A.SUB_NM, A.REP_ITEM_CD, A.USEM_ITEM_GROUP, A.GBN      
  END       
        
END       
    
IF @IN_CHK = 'Y' AND @OUT_CHK = 'Y' AND @EQP_CHK = 'Y'     
BEGIN     
  -- 해당 공정 정보와 BA_EQP 의 TP 를 확인해서 거기에 맞는 정보를 가지고 오자.       
     
 INSERT INTO @DATA_TABLE (      
        WC_CD, LINE_CD, EQP_CD, EQP_NM, ENO_PROC_CD, TP, ITEM_CD, SUB_NM, REP_ITEM_CD, USEM_ITEM_GROUP, GBN      
  )      
  SELECT A.WC_CD, A.LINE_CD, A.TP AS EQP_CD, C.SUB_NM AS EQP_NM, A.PROC_CD,A.TP,  '' AS ITEM_CD, '' AS SUB_NM, '' AS REP_ITEM_CD, '' AS USEM_ITEM_GROUP, 'Y'      
  FROM BA_EQP A WITH (NOLOCK)       
  INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON A.TP = C.SUB_CD AND C.MAIN_CD = 'BA205'      
  WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
  GROUP BY A.WC_CD, A.LINE_CD, A.EQP_CD, A.TP, C.SUB_NM, A.PROC_CD      
     
    
END     
    
IF @IN_CHK = 'N' AND (@GROUP_S = 'Y' OR @GROUP = 'Y') AND @EQP_CHK = 'Y'       
BEGIN       
    
  INSERT INTO @DATA_TABLE (      
        WC_CD, LINE_CD, EQP_CD, EQP_NM, ENO_PROC_CD, TP, ITEM_CD, SUB_NM, REP_ITEM_CD, USEM_ITEM_GROUP, GBN      
  )      
  SELECT A.WC_CD, A.LINE_CD, A.TP AS EQP_CD, C.SUB_NM AS EQP_NM, A.PROC_CD,A.TP,  '' AS ITEM_CD, '' AS SUB_NM, '' AS REP_ITEM_CD, '' AS USEM_ITEM_GROUP, 'Y'      
  FROM BA_EQP A WITH (NOLOCK)       
  INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON A.TP = C.SUB_CD AND C.MAIN_CD = 'BA205'      
  WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
  GROUP BY A.WC_CD, A.LINE_CD, A.EQP_CD, A.TP, C.SUB_NM, A.PROC_CD      
      
END       
      
IF @S_CHK = 'Y'       
BEGIN       
    SELECT 'Y' AS CHK      
      
    IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK) WHERE       
    A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
    AND A.S_CHK = @S_CHK      
    )      
    BEGIN       
      IF @WC_CD = '13P'     
      BEGIN      
       SELECT AA.CODE, AA.NAME, '' AS CHK FROM (SELECT TOP 1 '%' AS CODE, ('이전 작성된 공정일지 작성 시간은 ' + ISNULL(A.RK_DATE, CONVERT(NVARCHAR(10), A.SDATE, 120)) + ' ' + B.SUB_NM + ' 입니다.') AS NAME       
        FROM PD_RESULT A WITH (NOLOCK)       
        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.EQP_CD = B.SUB_CD AND B.MAIN_CD = 'POP52' AND B.USE_YN = 'Y'       
        WHERE       
        A.DIV_CD = @DIV_CD AND A.PLANT_CD = @plant_cd --AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD  AND A.PROC_CD = @PROC_CD      
        AND A.S_CHK = 'Y'      
        ORDER BY A.EDATE DESC) AA      
        
        UNION ALL      
        SELECT DISTINCT       
             A.SUB_CD AS CODE,      
             CONVERT(NVARCHAR(10), DATEADD(DAY, 0 --CAST(A.TEMP_NO1 AS TINYINT)      
             , CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME       
             , CASE WHEN EXISTS (SELECT *FROM PD_RESULT B WITH (NOLOCK)    
             WHERE B.DIV_CD = @DIV_CD AND B.PLANT_CD = @PLANT_CD AND B.WC_CD = @WC_CD AND B.LINE_CD = @LINE_CD AND B.PROC_CD =@PROC_CD AND B.S_CHK = 'Y'    
               AND B.RK_DATE = CONVERT(NVARCHAR(10), DATEADD(DAY, 0 , CAST(@SDATE AS DATE)), 120) AND B.EQP_CD = A.SUB_CD    
             ) THEN 'Y' ELSE 'N' END AS CHK   
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP52'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 <> 0       
        
        UNION ALL       
        SELECT DISTINCT       
       A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME    
             ,CASE WHEN EXISTS (SELECT *FROM PD_RESULT B WITH (NOLOCK)    
             WHERE B.DIV_CD = @DIV_CD AND B.PLANT_CD = @PLANT_CD AND B.WC_CD = @WC_CD AND B.LINE_CD = @LINE_CD AND B.PROC_CD =@PROC_CD AND B.S_CHK = 'Y'    
               AND B.RK_DATE = CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) AND B.EQP_CD = A.SUB_CD    
             ) THEN 'Y' ELSE 'N' END AS CHK          
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP52'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 = 0       
      END      
      ELSE      
      BEGIN      
        SELECT AA.CODE, AA.NAME,'' AS CHK        
        FROM (SELECT TOP 1 '%' AS CODE, ('이전 작성된 공정일지 작성 시간은 ' + ISNULL(A.RK_DATE, CONVERT(NVARCHAR(10), A.SDATE, 120)) + ' ' + B.SUB_NM + ' 입니다.') AS NAME           
        FROM PD_RESULT A WITH (NOLOCK)       
        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.EQP_CD = B.SUB_CD AND B.MAIN_CD = 'POP12' AND B.USE_YN = 'Y'       
        WHERE       
        A.DIV_CD = @DIV_CD AND A.PLANT_CD = @plant_cd --AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD  AND A.PROC_CD = @PROC_CD      
        AND A.S_CHK = 'Y'      
        ORDER BY A.EDATE DESC) AA   
        
        UNION ALL      
        SELECT DISTINCT       
             A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, 0 --CAST(A.TEMP_NO1 AS TINYINT)      
             , CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME      
             , CASE WHEN EXISTS (SELECT *FROM PD_RESULT B WITH (NOLOCK)    
             WHERE B.DIV_CD = @DIV_CD AND B.PLANT_CD = @PLANT_CD AND B.WC_CD = @WC_CD AND B.LINE_CD = @LINE_CD AND B.PROC_CD =@PROC_CD AND B.S_CHK = 'Y'    
               AND B.RK_DATE = CONVERT(NVARCHAR(10), DATEADD(DAY, 0 , CAST(@SDATE AS DATE)), 120) AND B.EQP_CD = A.SUB_CD    
        ) THEN 'Y' ELSE 'N' END AS CHK   
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP12'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 <> 0       
        
        UNION ALL       
        SELECT DISTINCT       
       A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME   
             ,CASE WHEN EXISTS (SELECT *FROM PD_RESULT B WITH (NOLOCK)    
             WHERE B.DIV_CD = @DIV_CD AND B.PLANT_CD = @PLANT_CD AND B.WC_CD = @WC_CD AND B.LINE_CD = @LINE_CD AND B.PROC_CD =@PROC_CD AND B.S_CHK = 'Y'    
               AND B.RK_DATE = CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) AND B.EQP_CD = A.SUB_CD    
             ) THEN 'Y' ELSE 'N' END AS CHK       
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP12'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 = 0       
      END      
     
    END       
    ELSE      
     
    IF @WC_CD = '13P'     
    BEGIN      
     
      SELECT '%' AS CODE,       
      '금일 작성된 공정일지가 없습니다. 공정일지 작성 시간을 선택해주십시오.' as NAME       
      UNION ALL      
        SELECT DISTINCT       
             A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, 0      
             --CAST(A.TEMP_NO1 AS TINYINT) * (-1)      
             , CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME       
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP52'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 <> 0       
        
      UNION ALL       
      SELECT DISTINCT       
             A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME       
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP52'       
         AND A.USE_YN = 'Y'       
    END      
    ELSE      
    BEGIN      
     
     
       SELECT '%' AS CODE,       
      '금일 작성된 공정일지가 없습니다. 공정일지 작성 시간을 선택해주십시오.' as NAME       
      UNION ALL      
        SELECT DISTINCT       
             A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, 0      
             --CAST(A.TEMP_NO1 AS TINYINT) * (-1)      
             , CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME       
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP12'       
         AND A.USE_YN = 'Y'       
         AND A.TEMP_NO1 <> 0       
        
      UNION ALL       
      SELECT DISTINCT       
             A.SUB_CD AS CODE,       
             CONVERT(NVARCHAR(10), DATEADD(DAY, CAST(A.TEMP_NO1 AS TINYINT), CAST(@SDATE AS DATE)), 120) + ' ' + a.SUB_NM AS NAME       
        FROM BA_SUB_CD A WITH (NOLOCK)       
       WHERE A.MAIN_CD = 'POP12'       
         AND A.USE_YN = 'Y'       
    END      
    SELECT *FROM @DATA_TABLE WHERE ITEM_CD <> ''      
END       
ELSE       
BEGIN       
  -- 투입이 아니고, 설비 선택이면       
  -- 그냥 설비만 보여 주고      
  -- 그 뭐냐 RK 처럼 시간 처리 면      
  -- 시간을 표시한다.       
  IF EXISTS(SELECT *FROM @DATA_TABLE) AND @EQP_CHK = 'Y'      
  BEGIN       
          -- 시작 상태인지를 체크 해야 된다. 이건.. 뒤에 하자.       
          -- POP       
          SELECT 'Y' AS CHK       
      
          IF (SELECT COUNT(*) FROM @DATA_TABLE A WHERE A.ITEM_CD <> '') = 1      
          BEGIN       
              SELECT A.EQP_CD AS CODE, A.EQP_NM AS NAME       
                    FROM @DATA_TABLE A       
                    WHERE A.ITEM_CD <> CASE WHEN A.GBN = 'N' THEN '' ELSE 'X' END      
                    GROUP BY A.EQP_CD, A.EQP_NM      
          END       
          ELSE       
          BEGIN       
            IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)       
            LEFT JOIN BA_EQP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.EQP_CD = B.EQP_CD       
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD )      
            BEGIN       
                      
                -- TP 코드이면?       
                IF EXISTS(SELECT TOP 1 *FROM PD_RESULT A WITH (NOLOCK)       
                INNER JOIN BA_EQP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.EQP_CD = B.TP       
                WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
                ORDER BY A.INSERT_DT DESC      
                )      
                BEGIN       
                  SELECT A1.CODE AS CODE, A1.NAME AS NAME       
                  FROM       
                  (      
      
                  SELECT TOP 1 '%' AS  CODE , CASE WHEN ISNULL(B.SUB_NM,'') = '' THEN '선택된 설비가 없습니다. 설비를 선택하여 주세요.'       
                  ELSE '이전 실적에 선택된 설비는 ' + B.SUB_NM + ' 입니다.' END AS NAME      
                  FROM PD_RESULT A WITH (NOLOCK)       
                  LEFT JOIN BA_SUB_CD B WITH (NOLOCK) ON A.EQP_CD = B.SUB_CD AND B.MAIN_CD = 'BA205'      
                  WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
                  ORDER BY A.INSERT_DT DESC ) A1      
                  UNION ALL       
                  SELECT A.EQP_CD AS CODE, A.EQP_NM AS NAME       
                      FROM @DATA_TABLE A WHERE A.ITEM_CD <> CASE WHEN A.GBN = 'N' THEN '' ELSE 'X' END      
                      GROUP BY A.EQP_CD, A.EQP_NM      
                END       
                ELSE       
                BEGIN       
                  IF @IN_CHK = 'Y'    
                  BEGIN    
                    SELECT A.EQP_CD AS CODE, A.EQP_NM AS NAME       
                    FROM @DATA_TABLE A WHERE A.ITEM_CD <> CASE WHEN A.GBN = 'N' THEN '' ELSE 'X' END      
                    GROUP BY A.EQP_CD, A.EQP_NM      
                  END    
                  ELSE    
                  BEGIN    
                    SELECT A1.CODE AS CODE, A1.NAME AS NAME       
                    FROM       
                    (      
                    SELECT TOP 1 '%' AS  CODE , CASE WHEN ISNULL(B.EQP_NM,'') = '' THEN '선택된 설비가 없습니다. 설비를 선택하여 주세요.'       
                    ELSE '이전 실적에 선택된 설비는 ' + B.EQP_NM + ' 입니다.' END AS NAME      
                    FROM PD_RESULT A WITH (NOLOCK)       
                    LEFT JOIN BA_EQP B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.EQP_CD = B.EQP_CD                         
                    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
                    ORDER BY A.INSERT_DT DESC ) A1      
                    UNION ALL       
                    SELECT A.EQP_CD AS CODE, A.EQP_NM AS NAME       
                        FROM @DATA_TABLE A WHERE A.ITEM_CD <> CASE WHEN A.GBN = 'N' THEN '' ELSE 'X' END      
                        GROUP BY A.EQP_CD, A.EQP_NM      
                   END    
                END       
            END       
            ELSE       
            BEGIN       
                SELECT '%' AS  CODE , '선택된 설비가 없습니다. 설비를 선택하여 주세요.'       
                 AS NAME      
                UNION ALL       
                SELECT A.EQP_CD AS CODE, A.EQP_NM AS NAME       
                    FROM @DATA_TABLE A       
                    WHERE A.ITEM_CD <> CASE WHEN A.GBN = 'N' THEN '' ELSE 'X' END      
                    GROUP BY A.EQP_CD, A.EQP_NM   
            END       
          END       
      
          SELECT *FROM @DATA_TABLE WHERE ITEM_CD <> ''      
  END       
      
  ELSE       
  BEGIN       
      -- 현재 해당 공정이 시작이고,       
      -- 공정코드가 있으면 그걸로 표시해줄까? 해보자       
      
      IF EXISTS(SELECT A.EQP_CD FROM PD_RESULT A WITH (NOLOCK)       
     INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.EQP_CD = B.SUB_CD AND B.MAIN_CD = 'BA205'      
      WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND       
      A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO       
      AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL AND A.EQP_CD <> '%'       
      )      
      BEGIN       
        SELECT 'Y' AS CHK       
      
        SELECT A.EQP_CD AS CODE, B.SUB_NM AS NAME FROM PD_RESULT A WITH (NOLOCK)       
        INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.EQP_CD = B.SUB_CD AND B.MAIN_CD = 'BA205'      
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDEr_NO AND A.REVISION = @REVISION       
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO       
        AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.EDATE IS NULL AND A.EQP_CD <> '%'       
              
      END       
      ELSE       
      BEGIN       
        SELECT 'N' AS CHK      
              
        SELECT '%' AS CODE, 'Empty' AS NAME      
      END       
            
      SELECT *FROM @DATA_TABLE WHERE ITEM_CD <> ''      
  END       
END 