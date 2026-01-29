/*  
기안번호 : PM250206001  
기안구분 : 일반  
제목 : POP 원료투입 공정 수동투입 locking 기능 추가 요청 件 
일자 : 25.02.18  
작업자 : 임종원 이사  
*/  
  
  
/*==============================================================================                                   
+ PROCEDURE 명 : USP_POP_004_RESULT_ORDER_QUERY         
+ 관 련  업 무 : POP 작업실적 - 지시조회         
+ 작   업   자 : 정유영         
+ 작 업  일 자 : 2023.11.26         
+ 추 가 수 정 : ljw       
+ 최 종 일 자 : 24.02.14      
+ 비        고 :          
==============================================================================*/         
ALTER PROCEDURE [dbo].[USP_POP_004_RESULT_ORDER_QUERY]         
(         
	 @DIV_CD		NVARCHAR(10)    = ''         
	,@PLANT_CD		NVARCHAR(20)	= ''         
	,@PROC_NO		NVARCHAR(50)	= ''         
	,@ORDER_NO		NVARCHAR(50)	= ''         
	,@REVISION		INT				= 0         
	,@ORDER_TYPE	NVARCHAR(10)	= ''         
	,@ORDER_FORM	NVARCHAR(10)	= ''         
	,@ROUT_NO		NVARCHAR(10)	= ''         
	,@ROUT_VER		INT				= 0         
	,@WC_CD			NVARCHAR(10)	= ''         
	,@LINE_CD		NVARCHAR(10)	= ''         
	,@PROC_CD		NVARCHAR(10)	= ''         
	,@PROC_SEQ		INT				= 0         
    ,@EQP_CD        NVARCHAR(10)    = ''
) AS        
        
SET NOCOUNT ON         
BEGIN        
	-- 확정된 지시의 필요 정보를 가지고 온다.      
	-- 기본 key, 품목 정보, 시작, 종료 일자, 투입, 소분투입, 그룹시작, 종료, 그룹, 이전 lot , 현재 lot, 시간 실적, 초품, 공정 추가, 잔여, 설비, 회차 등      
	        
	SELECT A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, A.PROC_NO, A.ORDER_TYPE, A.ORDER_FORM, A.ROUT_NO, A.ROUT_VER, A.WC_CD,         
	E.WC_NM,        
	A.LINE_CD,         
	F.LINE_NM,        
	B.PROC_CD,        
	G.PROC_NM,        
	A.ITEM_CD,         
	D.ITEM_NM      
	 + CASE WHEN ISNULL(CC.SUB_NM,'') = '' THEN '' ELSE '/' + CC.SUB_NM END AS ITEM_NM      
	,         
	CASE WHEN Z.ORDER_NO IS NULL THEN 'D'         
	     WHEN Z.EDATE IS NULL THEN 'R'        
	     WHEN Z.EDATE IS NOT NULL THEN 'E' END AS ST,       
     ISNULL(Z.SDATE, GETDATE()) AS SDATE,        
     ISNULL(Z.EDATE, '') AS EDATE,       
     B.IN_CHK,       
     B.OUT_CHK,        
     B.MIN_CHK,        
     B.GROUP_S,        
     B.GROUP_E,       
     dbo.UFNR_GET_GROUP(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, B.PROC_CD,'N') AS GROUP_CHK,       
	 ISNULL(Z.RESULT_SEQ ,0) AS RESULT_SEQ,      
     CASE WHEN Z.LOT_NO = '*' THEN CASE WHEN       
		B.IN_CHK = 'Y'       
		THEN       
		(SELECT TOP 1 AA.LOT_NO      
			FROM PD_USEM AA WITH (NOLOCK)       
			WHERE AA.DIV_CD = Z.DIV_CD AND AA.PLANT_CD = Z.PLANT_CD AND AA.PROC_NO = Z.PROC_NO       
			  AND AA.ORDER_NO = Z.ORDER_NO AND AA.REVISION = Z.REVISION AND AA.WC_CD = Z.WC_CD AND AA.LINE_CD = Z.LINE_CD       
			  AND AA.PROC_CD  =Z.PROC_CD AND AA.RESULT_SEQ = Z.RESULT_SEQ AND AA.IN_GBN <> 'E'      
			ORDER BY AA.USEM_SEQ DESC )       
	 ELSE       
		'' -- 왜 이렇게 했지?      
	 END       
	  ELSE Z.LOT_NO END LOT_NO       
	 , B.S_CHK      
	 , B.ADD_CHK      
	 , (SELECT TOP 1 AA.LOT_NO       
	       
	 	FROM PD_RESULT AA WITH (NOLOCK)       
		WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.WC_CD = A.WC_CD AND AA.LINE_CD = A.LINE_CD AND AA.PROC_CD = B.PROC_CD      
		  AND AA.EDATE IS NOT NULL      
		ORDER BY AA.SDATE DESC, AA.LOT_NO DESC       
	 ) AS BE_LOT_NO-- 가장 마지막 LOT 를 가지고 옵시다.      
	 , ISNULL(Z.J_CHK,'N') AS J_CHK      
	 --, ISNULL(Z.EQP_CD,'%') AS EQP_CD      
	 , B.F_CHK      
	 , Z.S_CHK AS RES_CHK       
	 , B.RECY_RT       
	 , dbo.FN_GET_LAST_PROC(A.DIV_CD, A.PLANT_CD, A.ORDER_NO, A.REVISION, B.PROC_CD) AS LAST_CHK      
	 , CONVERT(NVARCHAR(20), Z.SDATE, 120) AS SDATE      
	 , B.SKIP       
	 , D.LOT_INFO      
	 , CASE WHEN Z.ORDER_NO IS NULL OR Z.EDATE IS NOT NULL THEN       
		CASE WHEN EXISTS(SELECT *FROM PD_RESULT AA WITH (NOLOCK)       
		WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.WC_CD = A.WC_CD AND AA.LINE_CD = A.LINE_CD       
		  AND AA.PROC_CD = B.PROC_CD AND AA.EDATE IS NULL) THEN '현재 다른 작업지시에서 작업진행중입니다.' ELSE '' END       
		      
	 ELSE       
	 ''      
	 END AS OTHER_ST,   
	   
	 CASE WHEN B.IN_CHK = 'N' THEN   
	    CASE WHEN @PLANT_CD = '1150' AND @PROC_CD = 'PA' THEN         
            ISNULL(Z.EQP_CD, @EQP_CD) 
            ELSE 
            ISNULL(Z.EQP_CD, '%') 
            END 
        ELSE 

    
        
        ISNULL(Z.EQP_CD,  
        
        ISNULL((SELECT TOP 1 AA.EQP_CD FROM PD_RESULT AA WITH (NOLOCK)  	 WHERE AA.DIV_CD = @DIV_CD AND AA.PLANT_CD = @PLANT_CD AND AA.WC_CD = @WC_CD AND AA.LINE_CD = @LINE_CD AND AA.PROC_CD = @PROC_CD   
        ORDER BY AA.INSERT_DT DESC   
        )  
        ,  
        ''))   
    
     END  
	 AS EQP_CD,     
	 Z.EXP_LOT,      
     ISNULL(B.CSIL_CHK,'N') AS CSIL_CHK ,    
	 ISNULL(B.PRINT_CHK,'N') AS PRINT_CHK,    
	 CASE WHEN A.WC_CD IN ('14C','13R') THEN Z.J_SEQ ELSE     
	 Z.LOT_SEQ END AS LOT_SEQ ,    
	 ISNULL(Z.J_VAL,'%') AS J_VAL,   
	 ISNULL(Z.GROUP_SPEC_CD,'') AS GROUP_SPEC_CD, 
	 ISNULL(B.SIN_CHK,'N') AS SIN_CHK
        
      
	FROM PD_ORDER A WITH (NOLOCK)         
	INNER JOIN PD_ORDER_PROC B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND        
	A.ORDER_NO = B.ORDER_NO AND A.REVISION = B.REVISION AND B.PROC_CD = @PROC_CD         
	INNER JOIN V_ITEM D WITH (NOLOCK) ON A.PLANT_CD = D.PLANT_CD AND A.ITEM_CD = D.ITEM_CD         
	INNER JOIN BA_WORK_CENTER E WITH (NOLOCK) ON A.DIV_CD = E.DIV_CD AND A.PLANT_CD = E.PLANT_CD AND A.WC_CD = E.WC_CD         
	INNER JOIN BA_LINE F WITH (NOLOCK) ON A.DIV_CD = F.DIV_CD AND A.PLANT_CD = F.PLANT_CD AND A.LINE_CD = F.LINE_CD         
	INNER JOIN BA_PROC G WITH (NOLOCK) ON B.PROC_CD = G.PROC_CD        
	LEFT JOIN PD_RESULT Z WITH (NOLOCK)         
	ON  A.DIV_CD = Z.DIV_CD AND A.PLANT_CD = Z.PLANT_CD AND A.ORDER_NO = Z.ORDER_NO         
	AND A.REVISION = Z.REVISION AND A.ORDER_TYPE = Z.ORDER_TYPE AND A.ORDER_FORM = Z.ORDER_FORM AND A.ROUT_NO = Z.ROUT_NO         
	AND A.WC_CD = Z.WC_CD AND A.LINE_CD = Z.LINE_CD AND B.PROC_CD = Z.PROC_CD AND Z.EDATE IS NULL       
    AND Z.EQP_CD LIKE CASE WHEN @EQP_cD = '' THEN '' ELSE @EQP_CD END + '%'
	LEFT JOIN BA_SUB_CD CC WITH (NOLOCK)       
	 ON D.ITEM_GROUP_CD2 = CC.SUB_CD AND CC.MAIN_CD = 'B0002'      
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD         
	  AND A.ORDER_NO = @ORDER_NO         
	  AND A.REVISION = @REVISION        
	  AND A.CFM_FLG = 'Y'         
	            
	   
	SELECT A.GROUP_SPEC_CD, B.SUB_NM AS GROUP_SPEC_NM    
	    FROM PD_ORDER_PROC_SPEC A WITH (NOLOCK)    
	    INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.GROUP_SPEC_CD = B.SUB_CD AND B.MAIN_CD = 'POP17' AND B.USE_YN = 'Y'   
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION    
	  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER    
	  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD    
	  AND A.GROUP_SPEC_CD IS NOT NULL      
	GROUP BY A.GROUP_SPEC_CD, B.SUB_NM   
	ORDER BY A.GROUP_SPEC_CD    
   
	-- 마지막 실적의 정보를 가지고 오자.    
	-- 현재 실적이 가동 중이면?    
   
--	SELECT 'V' AS GROUP_SPEC_CD    
   
	SELECT TOP 1 A.GROUP_SPEC_CD    
	    FROM PD_RESULT A WITH (NOLOCK)    
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD    
	  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD    
	ORDER BY A.INSERT_DT DESC    
END 