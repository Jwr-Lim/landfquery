/*   
기안번호 : PM241204005   
기안구분 : 일반   
제목 : POP 12월 개선 1차   
일자 : 24.12.23   
작업자 : 임종원 이사   
*/   
     
/*==============================================================================                                        
+ PROCEDURE 명 : USP_POP_004_RESULT_QUERY1              
+ 관 련  업 무 : POP 작업실적 - 생산조건 조회              
+ 작   업   자 : 정유영              
+ 작 업  일 자 : 2023.11.27              
+ 비        고 :               
==============================================================================*/              
ALTER PROCEDURE [dbo].[USP_POP_004_RESULT_NEW_QUERY1]              
(              
	 @DIV_CD			NVARCHAR(10)    = ''              
	,@PLANT_CD			NVARCHAR(20)	= ''              
	,@PROC_NO			NVARCHAR(50)	= ''              
	,@ORDER_NO			NVARCHAR(50)	= ''              
	,@REVISION			INT				= 0              
	,@ORDER_TYPE		NVARCHAR(10)	= ''              
	,@ORDER_FORM		NVARCHAR(10)	= ''              
	,@ROUT_NO			NVARCHAR(10)	= ''              
	,@ROUT_VER			INT				= 0              
	,@WC_CD				NVARCHAR(10)	= ''              
	,@LINE_CD			NVARCHAR(10)	= ''              
	,@PROC_CD			NVARCHAR(10)	= ''              
	,@PROC_SEQ			INT				= 0           
	,@S_CHK             NVARCHAR(1)     = ''              
	,@RESULT_SEQ        INT             = 0           
    ,@EQP_CD            NVARCHAR(50)    = ''           
	,@CYCLE_SEQ         INT             = 1           
	,@GROUP_SPEC_CD     NVARCHAR(10)    = ''     
) AS              
BEGIN              
          
	SET NOCOUNT ON           
          
	EXEC sp_recompile N'USP_POP_004_RESULT_QUERY2';          
          
	DECLARE @DC_SPEC_VERSION	INT              

    IF EXISTS(SELECT *FROM BA_EQP A WITH (NOLOCK) 
    WHERE A.EQP_CD = @EQP_CD AND A.PROC_CD = @PROC_CD 
      AND ISNULL(A.TP,'') <> ''
    )
    BEGIN 
        SET @EQP_CD = 
        (SELECT A.TP FROM BA_EQP A WITH (NOLOCK) 
    WHERE A.EQP_CD = @EQP_CD AND A.PROC_CD = @PROC_CD 
      AND ISNULL(A.TP,'') <> ''
    )
    END 
	SELECT @DC_SPEC_VERSION = ISNULL(MAX(SPEC_VERSION),0)              
	FROM PD_ORDER_PROC_SPEC_V2 (NOLOCK)              
	WHERE DIV_CD = @DIV_CD              
	  AND PLANT_CD = @PLANT_CD              
	  AND ORDER_NO = @ORDER_NO              
	  AND REVISION = @REVISION              
	  AND ORDER_TYPE = @ORDER_TYPE              
	  AND ORDER_FORM = @ORDER_FORM              
	  AND ROUT_NO = @ROUT_NO              
	  AND ROUT_VER = @ROUT_VER              
	  AND WC_CD = @WC_CD              
	  AND LINE_CD = @LINE_CD              
	  AND PROC_CD = @PROC_CD            
      AND InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
      WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
     
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
	-- 설비 조회할때 LINE_CD 는 뺍니다.            
	DECLARE @EQP_TBL TABLE (           
		EQP_CD    NVARCHAR(30)            
	)           

	-- TP 가 설비코드랑 같으면? EX)RA, RB 같은거 채분리 분쇄 쪽..           
	IF EXISTS(SELECT *FROM BA_EQP A WITH (NOLOCK)            
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD            
	)           
	BEGIN            
           
		INSERT INTO @EQP_TBL            
		SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD            
		UNION ALL            
		SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND ISNULL(A.TP,'') = ''            

	END            
	ELSE            
	BEGIN            
		-- 아니면, 설비가 선택이 안되었으면 전체 설비 전부다. TP 있는것만, 왜냐, 아래에서 UNION ALL 에서 TP = '' 것은 기분적으로 가지고 온다.           
		IF @EQP_CD = '%' OR @EQP_CD = ''            
		BEGIN            
			IF EXISTS(SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)            
			WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP <> '' )           
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
		-- 그게 아니면 현 파라미터            
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


	DECLARE @MAX_ORDER_NO   NVARCHAR(50) = ''           
	       ,@MAX_REVISION   INT = 0           
		   ,@MAX_RESULT_SEQ INT = 0           
		   ,@MAX_S_CHK      NVARCHAR(1) = ''           
		            
	-- 최종 실적을 가지고 온다.           
	-- 내 위에 실적이 대체 뭐냐.           
	IF EXISTS(SELECT *FROM PD_RESULT A WITH (NOLOCK)           
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD           
	  AND A.EDATE IS NULL           
	)          
	BEGIN           
		SELECT TOP 1 @MAX_ORDER_NO = A.ORDEr_NO, @MAX_REVISION = A.REVISION, @MAX_RESULT_SEQ = A.RESULT_SEQ, @MAX_S_CHK = A.S_CHK            
			FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)          
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD           
		  AND (A.ORDER_NO + CAST(A.REVISION AS NVARCHAR) + CAST(A.RESULT_SEQ AS NVARCHAR)) <>           
		      (@ORDER_NO + CAST(@REVISION AS NVARCHAR) + CAST(@RESULT_SEQ AS NVARCHAR)) AND A.CYCLE_SEQ = @CYCLE_SEQ           
		  AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)          
		            
		ORDER BY A.INSERT_DT DESC           
	END           
	ELSE           
	BEGIN           
		SELECT TOP 1 @MAX_ORDER_NO = A.ORDEr_NO, @MAX_REVISION = A.REVISION, @MAX_RESULT_SEQ = A.RESULT_SEQ, @MAX_S_CHK = A.S_CHK            
			FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)          
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD           
		AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)          
		            
		ORDER BY A.INSERT_DT DESC           
	END           
      
      
	      
-- 등록 임시 테이블 정리      
      
DECLARE @RESULT_TBL TABLE (      
      
	 CYCLE_SEQ             INT       
	,SEQ                   INT       
    ,GROUP_SPEC            NVARCHAR(10)       
	,SPEC_CD               NVARCHAR(10)       
	,SPEC_NM               NVARCHAR(50)       
	,EQP_CD                NVARCHAR(50)       
	,EQP_NM                NVARCHAR(50)       
	,BE_IN_VALUE          NVARCHAR(100)       
	,IN_VALUE              NVARCHAR(100)       
	,PROC_SPEC_U           NVARCHAR(20)      
	,PROC_SPEC_L           NVARCHAR(20)       
	,PROC_SPEC_VALUE_TECH  NVARCHAR(20)       
	,PROC_EQP_U            NVARCHAR(20)       
	,PROC_EQP_L            NVARCHAR(20)       
	,SPEC_TYPE             NVARCHAR(10)       
	,SPEC_VALUE_TYPE_NM    NVARCHAR(50)       
	,BTN_PLC               NVARCHAR(1)       
	,USEM_ITEM_GROUP       NVARCHAR(50)       
	,EQP_CHK               NVARCHAR(1)       
	,POP_IP                NVARCHAR(50)       
	,OPC_NM                NVARCHAR(100)       
	,OPC_AS                NVARCHAR(50)       
	,PLC_DP                NVARCHAR(50)       
	,BTN_INIT              NVARCHAR(10)      
	,CAL_CHK               NVARCHAR(1)       
	,PROC_WARNING_U        NVARCHAR(20)       
	,PROC_WARNING_L        NVARCHAR(20)       
	,WARNING_TYPE          NVARCHAR(20)       
	,PLC_I_CHK             NVARCHAR(1)       
	,PROC_DIGIT            NVARCHAR(10)     
	,REQ_FLG               NVARCHAR(1)    
     
)      
      
          
	IF EXISTS(SELECT *FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)           
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE           
	AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD           
	AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ)          
	BEGIN       
		-- 계산식을 가지고 와서          
		-- 해당 CYCLE 이 마지막이면 보여 주고 아니면 보여주면 안된다.          
         
		DECLARE @CSIL_CHK NVARCHAR(1) = 'N'          
		       ,@LAST_CHK NVARCHAR(1) = 'N' -- 마지막인지를 확인한다.          
			   ,@LAST_SEQ INT = @CYCLE_SEQ         
         
		IF NOT EXISTS(         
		SELECT          
			*FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)          
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
		  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER          
		  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ          
		  AND A.CYCLE_SEQ > @CYCLE_SEQ         
		)         
		BEGIN          
			SET @LAST_CHK = 'Y'          
         
		END          
        
		SET @LAST_SEQ = ISNULL((SELECT          
		MAX(A.CYCLE_SEQ) FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)          
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION          
		  AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER          
		  AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ          
		  ),@CYCLE_SEQ)         
        
		DECLARE @CSIL_TBL TABLE (         
			  CNT             INT IDENTITY(1,1)         
			 ,CAL_SPEC_CD     NVARCHAR(10)          
		)         
         
		SET @CSIL_CHK = ISNULL((SELECT          
		A.CSIL_CHK FROM PD_ORDER_PROC A WITH (NOLOCK)          
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE          
		AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD          
		AND A.PROC_CD = @PROC_CD          
		),'N')         
         
        IF @CSIL_CHK = 'Y'         
		BEGIN          
			INSERT INTO @CSIL_TBL          
			-- 계산 공식을 가지고 오자..          
			SELECT VALUE          
			FROM string_split(         
			(         
				SELECT          
	 			(SUBSTRING(REPLACE(REPLACE(REPLACE(B.TEMP_CD4,'[',''),']',''),' ',''),CHARINDEX('-', REPLACE(REPLACE(REPLACE(B.TEMP_CD4,'[',''),']',''),' ','')) + 1, LEN(B.TEMP_CD4))         
				+ ',' +          
				SUBSTRING(REPLACE(REPLACE(REPLACE(B.TEMP_CD4,'[',''),']',''),' ',''),0, CHARINDEX('-', REPLACE(REPLACE(REPLACE(B.TEMP_CD4,'[',''),']',''),' ','')))          
				+',' + A.PROC_SPEC_CD) AS CAL_PROC_CD         
				         
				 FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)          
				INNER JOIN BA_SUB_CD B WITH (NOLOCK) ON A.PROC_SPEC_CD = B.SUB_CD AND B.MAIN_CD = 'P2001' AND B.TEMP_CD4 <> ''         
				INNER JOIN PD_ORDER_PROC_SPEC_V2 C WITH (NOLOCK) ON A.DIV_CD = C.DIV_CD AND A.PLANT_CD = C.PLANT_CD          
				AND A.ORDER_NO = C.ORDER_NO AND A.REVISION = C.REVISION AND A.ORDER_FORM = C.ORDER_FORM AND A.ORDER_TYPE = C.ORDER_TYPE          
				AND A.ROUT_NO = C.ROUT_NO AND A.ROUT_VER = C.ROUT_VER AND A.WC_CD = C.WC_CD AND A.LINE_CD = C.LINE_CD          
				AND A.PROC_CD = C.PROC_CD AND A.SEQ = C.SEQ AND A.SPEC_VERSION = C.SPEC_VERSION AND A.EQP_CD = C.EQP_CD          
				AND A.PROC_SPEC_CD = C.PROC_SPEC_CD          
				AND C.USEM_ITEM_GROUP <> '' AND B.TEMP_CD4 <> ''         
                AND C.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                    WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 
				WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD          
				  AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM          
				  AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD          
				  AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @CYCLE_SEQ         
				  AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)           
			), ',')         
		END          
        
		-- @LAST_CHK = @CYCLE_SEQ 가 같으면 하나도 지우지 않음        
		-- @LAST_SEQ 하고 1 사이이면? 다 지운다         
		-- @        
        
		IF @LAST_CHK = 'Y'        
		BEGIN          
			IF @LAST_SEQ > 1         
			BEGIN         
				DELETE @CSIL_TBL WHERE CNT <> 1         
			END         
			ELSE         
			BEGIN         
				DELETE @CSIL_TBL        
			END         
		END          
		ELSE          
		BEGIN          
			IF @CYCLE_SEQ = 1         
			BEGIN         
				IF @LAST_SEQ > 1         
				BEGIN         
					DELETE @CSIL_TBL WHERE CNT = 1        
				END         
			END        
			        
		END        


		--DELETE @CSIL_TBL          
		INSERT INTO @RESULT_TBL       
	    SELECT AA.CYCLE_SEQ, AA.SEQ, ISNULL(AA.GROUP_SPEC_CD,'') AS GROUP_SPEC_CD,  AA.SPEC_CD, AA.SPEC_NM, AA.EQP_CD, AA.EQP_NM, AA.BE_SPEC_VALUE AS BE_IN_VALUE, AA.IN_VALUE,        
       
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_U AS NVARCHAR) ELSE '' END AS PROC_SPEC_U,        
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_L AS NVARCHAR) ELSE '' END AS PROC_SPEC_L,            
	    CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_VALUE_TECH AS NVARCHAR) ELSE '' END AS PROC_SPEC_VALUE_TECH,       
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_EQP_U AS NVARCHAR) ELSE '' END AS PROC_EQP_U,        
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_EQP_L AS NVARCHAR) ELSE '' END AS PROC_EQP_L,        
       
		AA.SPEC_TYPE, AA.SPEC_VALUE_TYPE_NM, AA.BTN_PLC, AA.USEM_ITEM_GROUP,           
	           
		CASE WHEN ISNULL(BB.POP_IP,'') = '' THEN 'N' ELSE 'Y' END AS EQP_CHK,            
		BB.POP_IP, BB.OPC_AS + '.' + BB.OPC_AS + '.' + BB.POP_IP_ENO_AS AS OPC_NM, BB.OPC_AS, BB.POP_IP_ENO AS PLC_DP ,          
		'Init' AS BTN_INIT,       
		AA.CAL_CHK,       
		AA.PROC_WARNING_U,       
		AA.PROC_WARNING_L,       
		AA.WARNING_TYPE,      
		AA.PLC_CHK,    
		AA.PROC_DIGIT,   
		AA.REQ_FLAG     
	    FROM            
	    (           
		  -- 등록되어 있는 것들           
		             
	    	          
			  SELECT '1' AS GBN_SEQ, A.CYCLE_SEQ, A.SEQ, ISNULL(A.GROUP_SPEC_CD,'') AS GROUP_SPEC_CD,  A.PROC_SPEC_CD AS SPEC_CD, C.SUB_NM AS SPEC_NM, A.EQP_CD, D.EQP_NM,           
			  (SELECT TOP 1 AA.SPEC_VALUE          
				FROM PD_RESULT_PROC_SPEC_VALUE AA WITH (NOLOCK)           
				WHERE AA.DIV_CD = A.DIV_CD AND AA.PLANT_CD = A.PLANT_CD AND AA.WC_CD = A.WC_CD AND AA.LINE_CD = A.LINE_CD AND AA.PROC_CD = A.PROC_CD           
				  AND AA.ORDER_NO = @MAX_ORDER_NO AND AA.REVISION = @MAX_REVISION AND AA.S_CHK = @MAX_S_CHK AND AA.RESULT_SEQ = @MAX_RESULT_SEQ           
				  AND AA.CYCLE_SEQ = A.CYCLE_SEQ AND AA.PROC_SPEC_CD = A.PROC_SPEC_CD AND AA.EQP_CD = A.EQP_CD          
				) AS BE_SPEC_VALUE,           
			  A.SPEC_VALUE AS IN_VALUE, B.PROC_SPEC_U, B.PROC_SPEC_L,            
	            B.PROC_SPEC_VALUE AS PROC_SPEC_VALUE_TECH,            
	            B.PROC_EQP_U, B.PROC_EQP_L, E.SUB_CD AS SPEC_TYPE, E.SUB_NM AS SPEC_VALUE_TYPE_NM,            
	         ISNULL(B.PLC_FLAG,'N') AS BTN_PLC,           
	            B.USEM_ITEM_GROUP,        
				CASE WHEN CHARINDEX(E.TEMP_CD4,'-') > 0 THEN 'Y' ELSE 'N' END AS CAL_CHK,       
				B.PROC_WARNING_U,       
				B.PROC_WARNING_L,       
				B.WARNING_TYPE,      
				ISNULL(B.AUTO_PLC_FLAG,'N') AS PLC_CHK,    
				B.PROC_DIGIT,   
				B.REQ_FLAG    
				FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)            
	            INNER JOIN PD_ORDER_PROC_SPEC_V2 B WITH (NOLOCK) ON A.DIV_CD = B.DIV_CD AND A.ORDER_NO = B.ORDER_NO            
	            AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO        
	            AND A.ROUT_VER = B.ROUT_VER AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD --AND A.SEQ = B.SEQ 
                AND A.SPEC_VERSION = B.SPEC_VERSION AND A.PROC_SPEC_CD = B.PROC_SPEC_CD AND A.EQP_CD = B.EQP_CD

                     AND B.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                      WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 

	            INNER JOIN BA_SUB_CD C WITH (NOLOCK) ON A.PROC_SPEC_CD = C.SUB_CD AND C.MAIN_CD = 'P2001'           
				INNER JOIN BA_EQP D WITH (NOLOCK) ON A.DIV_CD = D.DIV_CD AND A.PLANT_CD = D.PLANT_CD AND A.EQP_CD = D.EQP_CD AND A.WC_CD = D.WC_CD AND A.PROC_CD = D.PROC_CD           
	               
	            INNER JOIN BA_SUB_CD E WITH (NOLOCK) ON A.SPEC_VALUE_TYPE = E.SUB_CD AND E.MAIN_CD = 'P2002'            
					     		                  
	          WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE            
	          AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD            
	            AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @CYCLE_SEQ            
	  --          AND ISNULL(A.SPEC_VALUE,'') = ''           
			    AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)           
				AND A.PROC_SPEC_CD NOT IN (SELECT CAL_SPEC_CD FROM @CSIL_TBL)         
				AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)     
		 ) AA           
		LEFT JOIN POP_EQP_ENO BB WITH (NOLOCK) ON BB.DIV_CD = @DIV_CD AND BB.PLANT_CD = @PLANT_CD            
		AND AA.EQP_CD = BB.EQP_CD AND BB.PROC_CD = @PROC_CD AND AA.SPEC_CD = BB.PROC_SPEC_CD            
	    ORDER BY AA.GBN_SEQ, AA.SEQ         
 
	END           
	ELSE           
	BEGIN      
	     
	--SELECT @MAX_ORDER_NO, @MAX_REVISION, @MAX_RESULT_SEQ          
		--최종조회              
		INSERT INTO @RESULT_TBL      
	    SELECT AA.CYCLE_SEQ, AA.SEQ, AA.GROUP_SPEC_CD,  AA.SPEC_CD, AA.SPEC_NM, AA.EQP_CD, AA.EQP_NM,           
		(SELECT TOP 1 A.SPEC_VALUE          
		FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)           
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD          
		  AND A.ORDER_NO = @MAX_ORDER_NO AND A.REVISION = @MAX_REVISION AND A.S_CHK = @MAX_S_CHK AND A.RESULT_SEQ = @MAX_RESULT_SEQ           
		  AND A.CYCLE_SEQ = @CYCLE_SEQ AND A.PROC_SPEC_CD = AA.SPEC_CD AND A.EQP_CD = AA.EQP_CD          
		) AS BE_IN_VALUE,           
		AA.IN_VALUE,        
       
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_U AS NVARCHAR) ELSE '' END AS PROC_SPEC_U,        
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_L AS NVARCHAR) ELSE '' END AS PROC_SPEC_L,            
	    CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_SPEC_VALUE_TECH AS NVARCHAR) ELSE '' END AS PROC_SPEC_VALUE_TECH,       
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_EQP_U AS NVARCHAR) ELSE '' END AS PROC_EQP_U,        
		CASE WHEN AA.SPEC_TYPE = '20' THEN CAST(AA.PROC_EQP_L AS NVARCHAR) ELSE '' END AS PROC_EQP_L,        
		       
		       
		AA.SPEC_TYPE, AA.SPEC_VALUE_TYPE_NM, AA.BTN_PLC, AA.USEM_ITEM_GROUP,           
         
		CASE WHEN ISNULL(BB.POP_IP,'') = '' THEN 'N' ELSE 'Y' END AS EQP_CHK,           
		BB.POP_IP, BB.OPC_AS + '.' + BB.OPC_AS + '.' + BB.POP_IP_ENO_AS AS OPC_NM, BB.OPC_AS, BB.POP_IP_ENO AS PLC_DP ,          
		'Init' AS BTN_INIT,       
		AA.CAL_CHK,       
		AA.PROC_WARNING_U,       
		AA.PROC_WARNING_L,       
		AA.WARNING_TYPE,      
		AA.PLC_CHK,    
		AA.PROC_DIGIT,   
		AA.REQ_FLAG   
	    FROM            
	    (           
	             
    	SELECT '1' AS GBN_SEQ,           
		AA.CYCLE_SEQ, AA.SEQ, ISNULL(AA.GROUP_SPEC_CD,'') AS GROUP_SPEC_CD, AA.SPEC_CD, AA.SPEC_NM, AA.EQP_CD, AA.EQP_NM, AA.IN_VALUE, AA.PROC_SPEC_U, AA.PROC_SPEC_L,            
		AA.PROC_SPEC_VALUE_TECH, AA.PROC_EQP_U, AA.PROC_EQP_L, AA.SPEC_TYPE, AA.SPEC_VALUE_TYPE_NM, AA.BTN_PLC, AA.USEM_ITEM_GROUP, AA.CAL_CHK,       
		AA.PROC_WARNING_U,       
		AA.PROC_WARNING_L,       
		AA.WARNING_TYPE,      
		AA.PLC_CHK,    
		AA.PROC_DIGIT,   
		AA.REQ_FLAG   
     
		FROM            
		(           
	    	SELECT           
				   '1' AS CYCLE_SEQ           
	    	      ,A.SEQ            
                  ,A.GROUP_SPEC_CD       
	              ,A.PROC_SPEC_CD AS SPEC_CD             
	              ,D.SUB_NM AS SPEC_NM             
	    		  ,C.EQP_CD             
	    		  ,C.EQP_NM               
	    		  ,'' AS IN_VALUE               
	    		  ,A.PROC_SPEC_U               
	    		  ,A.PROC_SPEC_L               
	    		  ,A.PROC_SPEC_VALUE AS PROC_SPEC_VALUE_TECH               
	    		  ,A.PROC_EQP_U     
	    		  ,A.PROC_EQP_L               
	    		  ,ISNULL(E.SUB_CD,'20') AS SPEC_TYPE           
	    		  ,ISNULL(E.SUB_NM,'숫자') AS SPEC_VALUE_TYPE_NM              

	    		  ,ISNULL(A.PLC_FLAG,'N') AS BTN_PLC               
	    		  ,A.USEM_ITEM_GROUP        
				  ,CASE WHEN CHARINDEX(D.TEMP_CD4,'-') > 0 THEN 'Y' ELSE 'N' END AS CAL_CHK        
				  ,A.PROC_WARNING_U       
				  ,A.PROC_WARNING_L       
				  ,A.WARNING_TYPE      
				  ,A.AUTO_PLC_FLAG AS PLC_CHK      
				  ,A.PROC_DIGIT     
				  ,A.REQ_FLAG   
                      
	    	FROM PD_ORDER_PROC_SPEC_V2 A (NOLOCK)               
	    	INNER JOIN BA_EQP C (NOLOCK)               
	  	 ON A.DIV_CD = C.DIV_CD               
	    	 AND A.PLANT_CD = C.PLANT_CD               
	    	 AND A.EQP_CD = C.EQP_CD              
			 AND ISNULL(C.TP,'') <> ''            
	    	-- AND A.PROC_CD = C.PROC_CD             
	    	INNER JOIN BA_SUB_CD D (NOLOCK)               
	    	 ON D.MAIN_CD = 'P2001'               
	    	 AND A.PROC_SPEC_CD = D.SUB_CD              
	        LEFT JOIN BA_SUB_CD E WITH (NOLOCK)              
	         ON A.SPEC_VALUE_TYPE = E.SUB_CD AND E.MAIN_CD = 'P2002'             
	    	WHERE A.DIV_CD = @DIV_CD               
	    	  AND A.PLANT_CD = @PLANT_CD               
	    	  AND A.ORDER_NO = @ORDER_NO               
	    	  AND A.REVISION = @REVISION               
	    	  AND A.ORDER_TYPE = @ORDER_TYPE               
	    	  AND A.ORDER_FORM = @ORDER_FORM               
	    	  AND A.ROUT_NO = @ROUT_NO               
	    	  AND A.ROUT_VER = @ROUT_VER               
	    	  AND A.WC_CD = @WC_CD               
	    	  AND A.LINE_CD = @LINE_CD               
	    	  AND A.PROC_CD = @PROC_CD               
	    	  AND A.SPEC_VERSION = @DC_SPEC_VERSION               
	          AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL) --LIKE '%' + @EQP_CD + '%'             
	    	  AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)     
                AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 
			UNION ALL             
	          
           
			SELECT            
	    	       '3' AS CYCLE_SEQ          
	    	      ,A.SEQ           
                  ,A.GROUP_SPEC_CD      
	              ,A.PROC_SPEC_CD AS SPEC_CD            
	              ,D.SUB_NM AS SPEC_NM            
	    		  ,C.EQP_CD            
	    		  ,C.EQP_NM              
	    		  ,'' AS IN_VALUE              
	    		  ,A.PROC_SPEC_U              
	    		  ,A.PROC_SPEC_L              
	    		  ,A.PROC_SPEC_VALUE AS PROC_SPEC_VALUE_TECH              
	    		  ,A.PROC_EQP_U              
	    		  ,A.PROC_EQP_L              
	    		  ,ISNULL(E.SUB_CD,'20') AS SPEC_TYPE           
	    		  ,ISNULL(E.SUB_NM,'숫자') AS SPEC_VALUE_TYPE_NM              
	    		  ,ISNULL(A.PLC_FLAG,'N') AS BTN_PLC              
	    		  ,A.USEM_ITEM_GROUP        
				  ,CASE WHEN CHARINDEX(D.TEMP_CD4,'-') > 0 THEN 'Y' ELSE 'N' END AS CAL_CHK        
 				  ,A.PROC_WARNING_U       
				  ,A.PROC_WARNING_L       
				  ,A.WARNING_TYPE      
				  ,A.AUTO_PLC_FLAG AS PLC_CHK      
				  ,A.PROC_DIGIT    
				  ,A.REQ_FLAG   
				      
	    	FROM PD_ORDER_PROC_SPEC_V2 A (NOLOCK)              
	    	          
	    	INNER JOIN BA_EQP C (NOLOCK)              
	    	 ON A.DIV_CD = C.DIV_CD       
	    	 AND A.PLANT_CD = C.PLANT_CD              
	    	 AND A.EQP_CD = C.EQP_CD             
			 AND ISNULL(C.TP,'') = ''           
	    	INNER JOIN BA_SUB_CD D (NOLOCK)              
	    	 ON D.MAIN_CD = 'P2001'              
	    	 AND A.PROC_SPEC_CD = D.SUB_CD             
	        LEFT JOIN BA_SUB_CD E WITH (NOLOCK)             
	         ON A.SPEC_VALUE_TYPE = E.SUB_CD AND E.MAIN_CD = 'P2002'            
	    	     
	    	WHERE A.DIV_CD = @DIV_CD              
	    	  AND A.PLANT_CD = @PLANT_CD              
	    	  AND A.ORDER_NO = @ORDER_NO              
	    	  AND A.REVISION = @REVISION              
	    	  AND A.ORDER_TYPE = @ORDER_TYPE              
	    	  AND A.ORDER_FORM = @ORDER_FORM              
	    	  AND A.ROUT_NO = @ROUT_NO              
	    	  AND A.ROUT_VER = @ROUT_VER              
	    	  AND A.WC_CD = @WC_CD              
	    	  AND A.LINE_CD = @LINE_CD              
	    	  AND A.PROC_CD = @PROC_CD              
	    	  --AND A.SPEC_VERSION = @DC_SPEC_VERSION              
			  AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)     
                   AND A.InboundId_ApiAutoCreate = (SELECT MAX(InboundId_ApiAutoCreate) FROM PD_ORDER_PROC_SPEC_V2 
                WHERE DIV_CD = @DIV_CD AND PLANT_CD = @PLANT_CD AND ORDER_NO = @ORDEr_NO AND REVISION = @REVISION)
 
	    	  --AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)          
		  ) AA            
	      GROUP BY            
		  AA.CYCLE_SEQ, AA.SEQ, AA.GROUP_SPEC_CD, AA.SPEC_CD, AA.SPEC_NM, AA.EQP_CD, AA.EQP_NM, AA.IN_VALUE, AA.PROC_SPEC_U, AA.PROC_SPEC_L,            
	   	  AA.PROC_SPEC_VALUE_TECH, AA.PROC_EQP_U, AA.PROC_EQP_L, AA.SPEC_TYPE, AA.SPEC_VALUE_TYPE_NM, AA.BTN_PLC, AA.USEM_ITEM_GROUP,       
	      AA.CAL_CHK, AA.PROC_WARNING_U, AA.PROC_WARNING_L, AA.WARNING_TYPE, AA.PLC_CHK, AA.PROC_DIGIT, AA.REQ_FLAG   
    	           
    	           
	    ) AA           
		LEFT JOIN POP_EQP_ENO BB WITH (NOLOCK) ON BB.DIV_CD = @DIV_CD AND BB.PLANT_CD = @PLANT_CD            
		AND AA.EQP_CD = BB.EQP_CD AND BB.PROC_CD = @PROC_CD AND AA.SPEC_CD = BB.PROC_SPEC_CD            
	    ORDER BY AA.GBN_SEQ, AA.SEQ           
          
		-- 회차 실적 시간을 가지고 온다.           
        
              
	END           
      
	SELECT A.CYCLE_SEQ,     
	A.SEQ,     
	A.GROUP_SPEC,     
	A.SPEC_CD,     
	A.SPEC_NM,     
	A.EQP_CD,     
	A.EQP_NM,     
	A.BE_IN_VALUE,     
	A.IN_VALUE,     
	CASE WHEN A.SPEC_TYPE = '20' THEN CASE WHEN A.PROC_SPEC_U = '' THEN '' ELSE dbo.FN_GET_DIGIT(A.PROC_SPEC_U, A.PROC_DIGIT) END ELSE A.PROC_SPEC_U END AS PROC_SPEC_U,     
	CASE WHEN A.SPEC_TYPE = '20' THEN CASE WHEN A.PROC_SPEC_L = '' THEN '' ELSE dbo.FN_GET_DIGIT(A.PROC_SPEC_L, A.PROC_DIGIT) END ELSE A.PROC_SPEC_L END AS PROC_SPEC_L,     
	CASE WHEN A.SPEC_TYPE = '20' THEN CASE WHEN A.PROC_SPEC_VALUE_TECH = '' THEN '' ELSE dbo.FN_GET_DIGIT(A.PROC_SPEC_VALUE_TECH, A.PROC_DIGIT) END ELSE A.PROC_SPEC_VALUE_TECH END AS PROC_SPEC_VALUE_TECH,     
	CASE WHEN A.SPEC_TYPE = '20' THEN CASE WHEN A.PROC_EQP_U = '' THEN '' ELSE dbo.FN_GET_DIGIT(A.PROC_EQP_U, A.PROC_DIGIT) END ELSE A.PROC_EQP_U END AS PROC_EQP_U,     
	CASE WHEN A.SPEC_TYPE = '20' THEN CASE WHEN A.PROC_EQP_U = '' THEN '' ELSE dbo.FN_GET_DIGIT(A.PROC_EQP_L, A.PROC_DIGIT) END ELSE A.PROC_EQP_L END AS PROC_EQP_L,     
	A.SPEC_TYPE,     
	A.SPEC_VALUE_TYPE_NM,     
	A.BTN_PLC,    
	A.USEM_ITEM_GROUP,     
	A.EQP_CHK,     
	A.POP_IP,     
	A.OPC_NM,     
	A.OPC_AS,     
	A.PLC_DP,     
	A.BTN_INIT,     
	A.CAL_CHK,     
	A.PROC_WARNING_U,    
	A.PROC_WARNING_L,    
	A.WARNING_TYPE,     
	A.PLC_I_CHK,     
	A.PROC_DIGIT,   
	-- GAP CHK 를 진행합시다.    
	CASE WHEN A.SPEC_TYPE = '20' THEN    
		CASE WHEN A.PROC_SPEC_U <> '' AND A.PROC_SPEC_L <> '' AND A.IN_VALUE <> '' THEN    
			CASE WHEN CAST(A.PROC_SPEC_U AS NUMERIC) = 0 AND CAST(A.PROC_SPEC_L AS NUMERIC) = 0 THEN    
			'N'    
			ELSE    
				CASE WHEN CAST(A.PROC_SPEC_U AS NUMERIC) < CAST(A.IN_VALUE AS NUMERIC) OR CAST(A.PROC_SPEC_L AS NUMERIC) > CAST(A.IN_VALUE AS NUMERIC) THEN    
						   
				'Y' ELSE 'N' END    
			END     
   
		ELSE    
		'N'    
		END   
	ELSE    
	'N' END AS GAP_CHK,   
	CASE WHEN A.REQ_FLG = 'Y' THEN    
		CASE WHEN ISNULL(A.IN_VALUE,'') <> '' THEN 'Y' ELSE 'N' END    
	ELSE    
	'Y'    
	END AS REQ_CHK    
	    
	FROM @RESULT_TBL A     
	ORDER BY A.CYCLE_SEQ, A.SEQ      
	          
	SELECT A.INSERT_DT           
		FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)           
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE           
	AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD           
	AND A.PROC_CD = @PROC_CD AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @CYCLE_SEQ          
	GROUP BY A.INSERT_DT           
END      
     
    
 /*    
SELECT            
	    	       '3' AS CYCLE_SEQ          
	    	      ,A.SEQ           
                  ,A.GROUP_SPEC_CD      
	              ,A.PROC_SPEC_CD AS SPEC_CD            
	              ,D.SUB_NM AS SPEC_NM            
	    		  ,C.EQP_CD            
	    		  ,C.EQP_NM              
	    		  ,'' AS IN_VALUE              
	    		  ,A.PROC_SPEC_U              
	    		  ,A.PROC_SPEC_L              
	    		  ,A.PROC_SPEC_VALUE AS PROC_SPEC_VALUE_TECH              
	    		  ,A.PROC_EQP_U              
	    		  ,A.PROC_EQP_L              
	    		  ,E.SUB_CD AS SPEC_TYPE           
	    		  ,E.SUB_NM AS SPEC_VALUE_TYPE_NM              
	    		  ,ISNULL(A.PLC_FLAG,'N') AS BTN_PLC              
	    		  ,A.USEM_ITEM_GROUP        
				  ,CASE WHEN CHARINDEX(D.TEMP_CD4,'-') > 0 THEN 'Y' ELSE 'N' END AS CAL_CHK        
 				  ,A.PROC_WARNING_U       
				  ,A.PROC_WARNING_L       
				  ,A.WARNING_TYPE      
				  ,A.AUTO_PLC_FLAG AS PLC_CHK      
				      
	    	FROM PD_ORDER_PROC_SPEC A (NOLOCK)              
	    	          
	    	INNER JOIN BA_EQP C (NOLOCK)              
	    	 ON A.DIV_CD = C.DIV_CD              
	    	 AND A.PLANT_CD = C.PLANT_CD              
	    	 AND A.EQP_CD = C.EQP_CD             
			 AND ISNULL(C.TP,'') = ''           
	    	INNER JOIN BA_SUB_CD D (NOLOCK)              
	    	 ON D.MAIN_CD = 'P2001'              
	    	 AND A.PROC_SPEC_CD = D.SUB_CD             
	        INNER JOIN BA_SUB_CD E WITH (NOLOCK)             
	         ON A.SPEC_VALUE_TYPE = E.SUB_CD AND E.MAIN_CD = 'P2002'            
	    	     
	    	WHERE A.DIV_CD = @DIV_CD              
	    	  AND A.PLANT_CD = @PLANT_CD              
	    	  AND A.ORDER_NO = @ORDER_NO              
	    	  AND A.REVISION = @REVISION              
	    	  AND A.ORDER_TYPE = @ORDER_TYPE              
	    	  AND A.ORDER_FORM = @ORDER_FORM             
	    	  AND A.ROUT_NO = @ROUT_NO              
	    	  AND A.ROUT_VER = @ROUT_VER              
	    	  AND A.WC_CD = @WC_CD              
	    	  AND A.LINE_CD = @LINE_CD              
	    	  AND A.PROC_CD = @PROC_CD              
	    	  AND A.SPEC_VERSION = @DC_SPEC_VERSION              
			  AND ISNULL(A.GROUP_SPEC_CD,'') IN (SELECT GROUP_SPEC_CD FROM @GROUP_SPEC_TBL)    
    
    
			  */ 