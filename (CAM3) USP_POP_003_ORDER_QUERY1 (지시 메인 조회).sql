/*==============================================================================                              
+ PROCEDURE 명 : USP_POP_003_ORDER_QUERY1    
+ 관 련  업 무 : POP 작업지시 - 지시조회    
+ 작   업   자 : 정유영    
+ 작 업  일 자 : 2023.11.21    
+ 비        고 :     
==============================================================================*/    
ALTER PROCEDURE [dbo].[USP_POP_003_ORDER_QUERY1]    
(    
	  @DIV_CD			NVARCHAR(10)    = ''    
	 ,@PLANT_CD			NVARCHAR(20)	= ''    
	 ,@ORDER_DT			DATE			= NULL 
	 ,@WC_CD			NVARCHAR(10)	= ''    
	 ,@LINE_CD			NVARCHAR(10)	= ''    
	 ,@PROC_CD			NVARCHAR(10)	= ''    
	 ,@ORDER_FORM       NVARCHAR(10)    = ''  
	 ,@ORDER_TYPE       NVARCHAR(10)    = ''  
	 ,@CLOSE_FLG        NVARCHAR(10)    = ''  
     ,@EQP_CD           NVARCHAR(50)    = ''
) AS    
BEGIN   
	IF @ORDER_DT IS NULL BEGIN SET @ORDER_DT = GETDATE() END  
	

    IF @EQP_CD = '' 
    BEGIN 
        SELECT PROC_NO 
            ,ORDER_NO 
            ,REVISION 
            ,BASE_ITEM_NM 
            ,ITEM_CD 
            ,ITEM_NM 
            ,ORDER_FORM_NM 
            ,ORDER_TYPE_NM 
            ,ORDER_QTY 
            ,SKIP 
            ,DIV_CD 
            ,PLANT_CD 
            ,ORDER_TYPE 
            ,ORDER_FORM 
            ,ROUT_NO 
            ,ROUT_VER 
            ,WC_CD 
            ,LINE_CD 
            ,PROC_CD 
            ,PROC_SEQ 
            ,'' AS EQP_CD 
            ,'' AS EQP_NM
            ,ST 
            ,CLOSE_FLG 
            ,BTN_CLOSE 
            ,ORDER_STATE 
            ,ORDER_STATE AS BTN 
            ,(SELECT TOP 1 LOT_NO 
                FROM PD_RESULT AA (NOLOCK) 
                WHERE AA.DIV_CD = A.DIV_CD 
                AND AA.PLANT_CD = A.PLANT_CD 
                AND AA.ORDER_NO = A.ORDER_NO 
                --AND AA.REVISION = A.REVISION 
                AND AA.WC_CD = A.WC_CD 
                AND AA.LINE_CD = A.LINE_CD 
                AND AA.PROC_CD = A.PROC_CD 
                AND AA.EDATE IS NOT NULL 
                AND AA.S_CHK = 'N' 
                ORDER BY SDATE DESC) AS LOT_NO 
        FROM 
        ( 
            SELECT ORDER_M.PROC_NO    
                ,ORDER_M.ORDER_NO    
                ,ORDER_M.REVISION    
                ,BASE_ITEM.SUB_NM AS BASE_ITEM_NM    
                ,ORDER_M.ITEM_CD   
                ,ITEM.ITEM_NM + CHAR(10) + '/ ' + ITEM.LOT_INFO + CASE WHEN ISNULL(CC.SUB_NM,'') = '' THEN '' ELSE ' / ' + CC.SUB_NM END AS ITEM_NM  
                ,ORDER_FORM.SUB_NM AS ORDER_FORM_NM    
                ,ORDER_TYPE.SUB_NM AS ORDER_TYPE_NM    
                ,ORDER_M.ORDER_QTY    
                ,ORDER_PROC.SKIP    
                ,ORDER_M.DIV_CD    
                ,ORDER_M.PLANT_CD    
                ,ORDER_M.ORDER_TYPE    
                ,ORDER_M.ORDER_FORM    
                ,ORDER_M.ROUT_NO    
                ,ORDER_M.ROUT_VER    
                ,ORDER_PROC.WC_CD    
                ,ORDER_PROC.LINE_CD    
                ,ORDER_PROC.PROC_CD    
                ,ORDER_PROC.PROC_SEQ    
                ,CASE WHEN EXISTS (	SELECT DIV_CD  
                                        FROM PD_RESULT A WITH (NOLOCK)   
                                        WHERE A.DIV_CD = ORDER_M.DIV_CD  
                                        AND A.PLANT_CD = ORDER_M.PLANT_CD  
                                        AND A.WC_CD = ORDER_M.WC_CD  
                                        AND A.LINE_CD = ORDER_M.LINE_CD   
                                        AND A.PROC_CD = ORDER_PROC.PROC_CD  
                                        AND A.ORDER_NO = ORDER_M.ORDER_NO  
                                        AND A.REVISION = ORDER_M.REVISION  
                                        AND A.EDATE IS NULL)  
                THEN 'Y' ELSE 'N' END AS ST 
                ,ORDER_PROC.CLOSE_FLG  
                ,'' AS BTN_CLOSE 
                ,ISNULL(ORDER_PROC.ORDER_STATE,'O') AS ORDER_STATE 
            FROM PD_ORDER ORDER_M (NOLOCK)    
            INNER JOIN PD_ORDER_PROC ORDER_PROC (NOLOCK)    
            ON ORDER_M.DIV_CD = ORDER_PROC.DIV_CD    
            AND ORDER_M.PLANT_CD = ORDER_PROC.PLANT_CD    
            AND ORDER_M.ORDER_NO = ORDER_PROC.ORDER_NO    
            AND ORDER_M.REVISION = ORDER_PROC.REVISION    
            INNER JOIN V_ITEM ITEM (NOLOCK)    
            ON ORDER_M.PLANT_CD = ITEM.PLANT_CD    
            AND ORDER_M.ITEM_CD = ITEM.ITEM_CD    
            INNER JOIN BA_SUB_CD ORDER_FORM (NOLOCK)    
            ON ORDER_FORM.MAIN_CD = 'P1005'    
            AND ORDER_FORM.SUB_CD = ORDER_M.ORDER_FORM    
            INNER JOIN BA_SUB_CD BASE_ITEM (NOLOCK)    
            ON BASE_ITEM.MAIN_CD = 'BA206'    
            AND BASE_ITEM.SUB_CD = ITEM.BASE_ITEM_CD    
            INNER JOIN BA_SUB_CD ORDER_TYPE (NOLOCK)    
            ON ORDER_TYPE.MAIN_CD = 'SAP01'    
            AND ORDER_TYPE.SUB_CD = ORDER_M.ORDER_TYPE    
            LEFT JOIN BA_SUB_CD CC WITH (NOLOCK)   
            ON ITEM.ITEM_GROUP_CD2 = CC.SUB_CD AND CC.MAIN_CD = 'B0002'  
            WHERE LEFT(ORDER_M.ORDER_DT,7) BETWEEN LEFT((DATEADD(MONTH,-1, CAST(@ORDER_DT AS DATETIME))),7) AND  LEFT(@ORDER_DT,7)    
            AND ORDER_PROC.WC_CD = @WC_CD    
            AND ORDER_PROC.LINE_CD = @LINE_CD    
            AND ORDER_PROC.PROC_CD = @PROC_CD 
            AND ORDER_PROC.ORDER_FORM LIKE @ORDER_FORM 
            AND ORDER_PROC.ORDER_TYPE LIKE @ORDER_TYPE 
            AND ((@CLOSE_FLG = '%' AND ORDER_PROC.CLOSE_FLG <> '%') OR (@CLOSE_FLG <> '%' AND ORDER_PROC.CLOSE_FLG = @CLOSE_FLG)) 
        ) A 
        ORDER BY ST DESC, ORDER_NO, REVISION 
    END 
    ELSE 
    BEGIN 
        SELECT PROC_NO 
            ,ORDER_NO 
            ,REVISION 
            ,BASE_ITEM_NM 
            ,ITEM_CD 
            ,ITEM_NM 
            ,ORDER_FORM_NM 
            ,ORDER_TYPE_NM 
            ,ORDER_QTY 
            ,SKIP 
            ,DIV_CD 
            ,PLANT_CD 
            ,ORDER_TYPE 
            ,ORDER_FORM 
            ,ROUT_NO 
            ,ROUT_VER 
            ,WC_CD 
            ,LINE_CD 
            ,PROC_CD 
            ,PROC_SEQ 
            ,EQP_CD
            ,EQP_NM
            ,ST 
            ,CLOSE_FLG 
            ,BTN_CLOSE 
            ,ORDER_STATE 
            ,ORDER_STATE AS BTN 
            ,(SELECT TOP 1 LOT_NO 
                FROM PD_RESULT AA (NOLOCK) 
                WHERE AA.DIV_CD = A.DIV_CD 
                AND AA.PLANT_CD = A.PLANT_CD 
                AND AA.ORDER_NO = A.ORDER_NO 
                --AND AA.REVISION = A.REVISION 
                AND AA.WC_CD = A.WC_CD 
                AND AA.LINE_CD = A.LINE_CD 
                AND AA.PROC_CD = A.PROC_CD 
                AND AA.EDATE IS NOT NULL 
                AND AA.S_CHK = 'N' 
                ORDER BY SDATE DESC) AS LOT_NO 
        FROM 
        ( 
            SELECT ORDER_M.PROC_NO    
                ,ORDER_M.ORDER_NO    
                ,ORDER_M.REVISION    
                ,BASE_ITEM.SUB_NM AS BASE_ITEM_NM    
                ,ORDER_M.ITEM_CD   
                ,ITEM.ITEM_NM + CHAR(10) + '/ ' + ITEM.LOT_INFO + CASE WHEN ISNULL(CC.SUB_NM,'') = '' THEN '' ELSE ' / ' + CC.SUB_NM END AS ITEM_NM  
                ,ORDER_FORM.SUB_NM AS ORDER_FORM_NM    
                ,ORDER_TYPE.SUB_NM AS ORDER_TYPE_NM   
                ,@EQP_CD AS EQP_CD 
                ,(SELECT EQP_NM FROM BA_EQP WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND LINE_CD = @LINE_CD AND PROC_CD = @PROC_CD AND TP = @EQP_CD) AS EQP_NM 
                ,ORDER_M.ORDER_QTY    
                ,ORDER_PROC.SKIP    
                ,ORDER_M.DIV_CD    
                ,ORDER_M.PLANT_CD    
                ,ORDER_M.ORDER_TYPE    
                ,ORDER_M.ORDER_FORM    
                ,ORDER_M.ROUT_NO    
                ,ORDER_M.ROUT_VER    
                ,ORDER_PROC.WC_CD    
                ,ORDER_PROC.LINE_CD    
                ,ORDER_PROC.PROC_CD    
                ,ORDER_PROC.PROC_SEQ    
                ,CASE WHEN EXISTS (	SELECT DIV_CD  
                                        FROM PD_RESULT A WITH (NOLOCK)   
                                        WHERE A.DIV_CD = ORDER_M.DIV_CD  
                                        AND A.PLANT_CD = ORDER_M.PLANT_CD  
                                        AND A.WC_CD = ORDER_M.WC_CD  
                                        AND A.LINE_CD = ORDER_M.LINE_CD   
                                        AND A.PROC_CD = ORDER_PROC.PROC_CD  
                                        AND A.ORDER_NO = ORDER_M.ORDER_NO  
                                        AND A.REVISION = ORDER_M.REVISION  
                                        AND A.EDATE IS NULL
                                        AND A.EQP_CD = @EQP_CD 
                                        )  
                THEN 'Y' ELSE 'N' END AS ST 
                ,ORDER_PROC.CLOSE_FLG  
                ,'' AS BTN_CLOSE 
                ,ISNULL(ORDER_PROC.ORDER_STATE,'O') AS ORDER_STATE 
            FROM PD_ORDER ORDER_M (NOLOCK)    
            INNER JOIN PD_ORDER_PROC ORDER_PROC (NOLOCK)    
            ON ORDER_M.DIV_CD = ORDER_PROC.DIV_CD    
            AND ORDER_M.PLANT_CD = ORDER_PROC.PLANT_CD    
            AND ORDER_M.ORDER_NO = ORDER_PROC.ORDER_NO    
            AND ORDER_M.REVISION = ORDER_PROC.REVISION    
            INNER JOIN V_ITEM ITEM (NOLOCK)    
            ON ORDER_M.PLANT_CD = ITEM.PLANT_CD    
            AND ORDER_M.ITEM_CD = ITEM.ITEM_CD    
            INNER JOIN BA_SUB_CD ORDER_FORM (NOLOCK)    
            ON ORDER_FORM.MAIN_CD = 'P1005'    
            AND ORDER_FORM.SUB_CD = ORDER_M.ORDER_FORM    
            INNER JOIN BA_SUB_CD BASE_ITEM (NOLOCK)    
            ON BASE_ITEM.MAIN_CD = 'BA206'    
            AND BASE_ITEM.SUB_CD = ITEM.BASE_ITEM_CD    
            INNER JOIN BA_SUB_CD ORDER_TYPE (NOLOCK)    
            ON ORDER_TYPE.MAIN_CD = 'SAP01'    
            AND ORDER_TYPE.SUB_CD = ORDER_M.ORDER_TYPE    
            LEFT JOIN BA_SUB_CD CC WITH (NOLOCK)   
            ON ITEM.ITEM_GROUP_CD2 = CC.SUB_CD AND CC.MAIN_CD = 'B0002'  
            WHERE LEFT(ORDER_M.ORDER_DT,7) BETWEEN LEFT((DATEADD(MONTH,-1, CAST(@ORDER_DT AS DATETIME))),7) AND  LEFT(@ORDER_DT,7)    
            AND ORDER_PROC.WC_CD = @WC_CD    
            AND ORDER_PROC.LINE_CD = @LINE_CD    
            AND ORDER_PROC.PROC_CD = @PROC_CD 
            AND ORDER_PROC.ORDER_FORM LIKE @ORDER_FORM 
            AND ORDER_PROC.ORDER_TYPE LIKE @ORDER_TYPE 
            AND ((@CLOSE_FLG = '%' AND ORDER_PROC.CLOSE_FLG <> '%') OR (@CLOSE_FLG <> '%' AND ORDER_PROC.CLOSE_FLG = @CLOSE_FLG)) 
        ) A 
        ORDER BY ST DESC, ORDER_NO, REVISION 

    END 
 
 
------------------------------------------------------------------------------ 
 --   DECLARE @TEMP_ORDER_MAX TABLE    
 --   (   
	--	 DIV_CD      NVARCHAR(10)   
	--	,PLANT_CD    NVARCHAR(10)    
	--	,ORDER_NO    NVARCHAR(50)    
	--	,REVISION    INT    
 --   )   
   
 --   INSERT INTO @TEMP_ORDER_MAX 
	--(   
	--	DIV_CD		,PLANT_CD	,ORDER_NO	,REVISION    
 --   ) 
	--SELECT AA.DIV_CD, AA.PLANT_CD, AA.ORDER_NO, AA.REVISION 
	--FROM 
	--(   
	--	SELECT A.DIV_CD 
	--		  ,A.PLANT_CD 
	--		  ,A.ORDER_NO 
	--		  ,MAX(A.REVISION) AS REVISION    
	--	FROM PD_ORDER A (NOLOCK)    
	--	LEFT JOIN PD_RESULT B WITH (NOLOCK)   
	--	 ON A.DIV_CD = B.DIV_CD 
	--	 AND A.PLANT_CD = B.PLANT_CD 
	--	 AND A.ORDER_NO = B.ORDER_NO 
	--	 AND A.REVISION = B.REVISION   
	--	 AND A.ORDER_TYPE = B.ORDER_TYPE 
	--	 AND A.ORDER_FORM = B.ORDER_FORM 
	--	 AND A.ROUT_NO = B.ROUT_NO 
	--	 AND A.ROUT_VER = B.ROUT_VER   
	--	 AND A.WC_CD = B.WC_CD 
	--	 AND A.LINE_CD = B.LINE_CD 
	--	 AND B.PROC_CD = @PROC_CD 
	--	 AND B.EDATE IS NULL   
	--	WHERE A.CLOSE_FLG = 'N' 	 
	--	GROUP BY A.DIV_CD, A.PLANT_CD, A.ORDER_NO    
	--	UNION ALL  
	--	SELECT A.DIV_CD 
	--		  ,A.PLANT_CD 
	--		  ,A.ORDER_NO 
	--		  ,MAX(A.REVISION) AS REVISION    
	--	FROM PD_ORDER A (NOLOCK) 
	--	INNER JOIN PD_RESULT B WITH (NOLOCK)   
	--	ON A.DIV_CD = B.DIV_CD 
	--	AND A.PLANT_CD = B.PLANT_CD  
	--	AND A.ORDEr_NO = B.ORDER_NO  
	--	AND A.REVISION = B.REVISION   
	--	AND A.ORDER_TYPE = B.ORDER_TYPE  
	--	AND A.ORDER_FORM = B.ORDER_FORM  
	--	AND A.ROUT_NO = B.ROUT_NO  
	--	AND A.ROUT_VER = B.ROUT_VER   
	--	AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND B.PROC_CD = @PROC_CD AND B.EDATE IS NULL   
	--	GROUP BY A.DIV_CD, A.PLANT_CD, A.ORDER_NO    
	--) AA  
	--GROUP BY AA.DIV_CD, AA.PLANT_CD, AA.ORDER_NO, AA.REVISION  
	--ORDER BY DIV_CD, PLANT_CD, ORDER_NO, REVISION  
	 
	----최종조회	    
	--SELECT ORDER_M.PROC_NO    
	--	  ,ORDER_M.ORDER_NO    
	--	  ,ORDER_M.REVISION    
	--	  ,BASE_ITEM.SUB_NM AS BASE_ITEM_NM    
	--	  ,ORDER_M.ITEM_CD   
	--	  ,ITEM.ITEM_NM + CHAR(10) + '/ ' + ITEM.LOT_INFO + CASE WHEN ISNULL(CC.SUB_NM,'') = '' THEN '' ELSE ' / ' + CC.SUB_NM END AS ITEM_NM  
	--	  ,ORDER_FORM.SUB_NM AS ORDER_FORM_NM    
	--	  ,ORDER_TYPE.SUB_NM AS ORDER_TYPE_NM    
	--	  ,ORDER_M.ORDER_QTY    
	--	  ,ORDER_PROC.SKIP    
	--	  ,ORDER_M.DIV_CD    
	--	  ,ORDER_M.PLANT_CD    
	--	  ,ORDER_M.ORDER_TYPE    
	--	  ,ORDER_M.ORDER_FORM    
	--	  ,ORDER_M.ROUT_NO    
	--	  ,ORDER_M.ROUT_VER    
	--	  ,ORDER_PROC.WC_CD    
	--	  ,ORDER_PROC.LINE_CD    
	--	  ,ORDER_PROC.PROC_CD    
	--	  ,ORDER_PROC.PROC_SEQ    
 --         , CASE WHEN EXISTS(SELECT DIV_CD FROM PD_RESULT A WITH (NOLOCK)   
	--	  WHERE A.DIV_CD = ORDER_M.DIV_CD AND A.PLANT_CD = ORDER_M.PLANT_CD AND A.WC_CD = ORDER_M.WC_CD AND A.LINE_CD = ORDER_M.LINE_CD   
	--	  AND A.PROC_CD = ORDER_PROC.PROC_CD AND A.ORDER_NO = ORDER_M.ORDER_NO AND A.REVISION = ORDER_M.REVISION AND A.EDATE IS NULL  
	--	  )  
	--	  THEN   
	--	  'Y' ELSE 'N' END AS ST--CASE WHEN F.ORDER_NO IS NULL AND F.EDATE IS NULL THEN 'N' ELSE 'Y' END AS ST   
	--	  ,ORDER_M.CLOSE_FLG  
	--	  ,'' AS BTN_CLOSE   
	--FROM PD_ORDER ORDER_M (NOLOCK)    
	--INNER JOIN @TEMP_ORDER_MAX ORDER_MAX   
	-- ON ORDER_M.DIV_CD = ORDER_MAX.DIV_CD    
	-- AND ORDER_M.PLANT_CD = ORDER_MAX.PLANT_CD    
	-- AND ORDER_M.ORDER_NO = ORDER_MAX.ORDER_NO    
	-- AND ORDER_M.REVISION = ORDER_MAX.REVISION    
	--INNER JOIN PD_ORDER_PROC ORDER_PROC (NOLOCK)    
	-- ON ORDER_M.DIV_CD = ORDER_PROC.DIV_CD    
	-- AND ORDER_M.PLANT_CD = ORDER_PROC.PLANT_CD    
	-- AND ORDER_M.ORDER_NO = ORDER_PROC.ORDER_NO    
	-- AND ORDER_M.REVISION = ORDER_PROC.REVISION    
	--INNER JOIN V_ITEM ITEM (NOLOCK)    
	-- ON ORDER_M.PLANT_CD = ITEM.PLANT_CD    
	-- AND ORDER_M.ITEM_CD = ITEM.ITEM_CD    
	--INNER JOIN BA_SUB_CD ORDER_FORM (NOLOCK)    
	-- ON ORDER_FORM.MAIN_CD = 'P1005'    
	-- AND ORDER_FORM.SUB_CD = ORDER_M.ORDER_FORM    
	--INNER JOIN BA_SUB_CD BASE_ITEM (NOLOCK)    
	-- ON BASE_ITEM.MAIN_CD = 'BA206'    
	-- AND BASE_ITEM.SUB_CD = ITEM.BASE_ITEM_CD    
	--INNER JOIN BA_SUB_CD ORDER_TYPE (NOLOCK)    
	-- ON ORDER_TYPE.MAIN_CD = 'SAP01'    
	-- AND ORDER_TYPE.SUB_CD = ORDER_M.ORDER_TYPE    
	--LEFT JOIN BA_SUB_CD CC WITH (NOLOCK)   
	-- ON ITEM.ITEM_GROUP_CD2 = CC.SUB_CD AND CC.MAIN_CD = 'B0002'  
	-- /*  
 --   LEFT JOIN PD_RESULT F WITH (NOLOCK) ON ORDER_M.DIV_CD = F.DIV_CD AND ORDER_M.PLANT_CD = F.PLANT_CD  
 --   AND ORDER_M.ORDER_NO = F.ORDER_NO AND ORDER_M.REVISION = F.REVISION AND  ORDER_M.ORDER_TYPE = F.ORDER_TYPE   
	--AND ORDER_M.ORDER_FORM = F.ORDER_FORM AND ORDER_M.WC_CD = F.WC_CD AND ORDER_M.LINE_CD = F.LINE_CD   
	--AND ORDER_PROC.PROC_CD = F.PROC_CD AND F.EDATE IS NULL  
	--*/  
	--WHERE LEFT(ORDER_M.ORDER_DT,7) BETWEEN LEFT((DATEADD(MONTH,-1, CAST(@ORDER_DT AS DATETIME))),7) AND  LEFT(@ORDER_DT,7)    
	--  AND ORDER_PROC.WC_CD = @WC_CD    
	--  AND ORDER_PROC.LINE_CD = @LINE_CD    
	--  AND ORDER_PROC.PROC_CD = @PROC_CD 
	--  AND ORDER_PROC.ORDER_FORM LIKE @ORDER_FORM 
	--  AND ORDER_PROC.ORDER_TYPE LIKE @ORDER_TYPE 
END    
    