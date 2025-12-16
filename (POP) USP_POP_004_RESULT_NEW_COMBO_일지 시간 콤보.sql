ALTER PROC USP_POP_004_RESULT_NEW_COMBO_DR
(
--DECLARE 
        @DIV_CD    NVARCHAR(10) 
       ,@PLANT_CD  NVARCHAR(10) 
       ,@ORDER_NO  NVARCHAR(50) 
       ,@REVISION  INT 
       ,@WC_CD     NVARCHAR(10) 
       ,@LINE_CD   NVARCHAR(10) 
       ,@PROC_CD   NVARCHAR(10) 
       ,@SDATE     NVARCHAR(10) 
) 
AS 

IF @PROC_CD IN ('RK','RH')
BEGIN 
      DECLARE @ORDER_TYPE NVARCHAR(10)
            ,@ORDER_FORM NVARCHAR(10) 
            ,@ROUT_NO    NVARCHAR(10) 
            ,@ROUT_VER   INT 
            ,@S_CHK      NVARCHAR(1) = 'Y' 

      SELECT @ORDER_TYPE = A.ORDER_TYPE, @ORDER_FORM = A.ORDER_FORM, @ROUT_NO = A.ROUT_NO, @ROUT_VER = A.ROUT_VER 
      FROM PD_ORDER A WITH (NOLOCK) 
      WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION 
            

      IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK) WHERE       
      A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE       
      AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD       
      AND A.S_CHK = @S_CHK      
      )      
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
      --AND A.TEMP_NO1 = 0       
      

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
END 
ELSE 
BEGIN 
      SELECT '%' AS CODE, CONVERT(NVARCHAR(20), GETDATE(), 120) AS NAME 
END 