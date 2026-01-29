ALTER PROC USP_POP_004_PROC_SPEC_ADD(    
     @DIV_CD        NVARCHAR(10)     = '01'    
    ,@PLANT_CD      NVARCHAR(10)     = '1140'    
    ,@ORDER_NO      NVARCHAR(50)     = 'PD231212003'    
    ,@REVISION      INT              = 2    
    ,@PROC_NO       NVARCHAR(50)     = 'OPL2312180005'    
    ,@ORDER_TYPE    NVARCHAR(10)     = 'PP01'    
    ,@ORDER_FORM    NVARCHAR(10)     = '10'    
    ,@ROUT_NO       NVARCHAR(10)     = 'C01'    
    ,@ROUT_VER      INT              = '1'    
    ,@WC_CD         NVARCHAR(10)     = '14GC'    
    ,@LINE_CD       NVARCHAR(10)     = '14G05C'    
    ,@S_CHK         NVARCHAR(1)      = 'N'    
    ,@PROC_CD       NVARCHAR(10)     = 'S' --RK, S, EU, ED, P    
    ,@RESULT_SEQ     INT     
    ,@EQP_CD        NVARCHAR(20)     = ''    
    ,@USER_ID       NVARCHAR(15)     = ''    
    ,@MSG_CD        NVARCHAR(4)      OUTPUT     
    ,@MSG_DETAIL    NVARCHAR(MAX)    OUTPUT     
    
)    
AS     
    
BEGIN TRY    
    
    DECLARE @CYCLE_SEQ INT = 0     
       
    SET @CYCLE_SEQ = ISNULL((SELECT MAX(A.CYCLE_SEQ)    
    FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)     
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE     
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD     
    AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ     
    ),0) + 1   
   
     DECLARE @EQP_TBL TABLE (    
		EQP_CD    NVARCHAR(30)     
	)    
    
	IF EXISTS(SELECT *FROM BA_EQP A WITH (NOLOCK)     
	WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD     
	)    
	BEGIN     
    
		INSERT INTO @EQP_TBL     
		SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)     
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = @EQP_CD     
        UNION ALL     
        SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)     
		WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD AND A.TP = ''     
    
	END     
	ELSE     
	BEGIN     
		IF @EQP_CD = '%' OR @EQP_CD = ''     
		BEGIN     
			IF EXISTS(SELECT A.EQP_CD FROM BA_EQP A WITH (NOLOCK)     
			WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.PROC_CD = @PROC_CD AND A.TP <> '' )    
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
       
      
    
     
    IF NOT EXISTS(SELECT *FROM PD_RESULT_PROC_SPEC_VALUE A WITH (NOLOCK)    
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE     
    AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD     
    AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ AND A.CYCLE_SEQ = @CYCLE_SEQ    
    )    
    BEGIN     
    
        DECLARE @IN_SEQ INT = 0     
    
        SET @IN_SEQ = ISNULL((SELECT MAX(A.IN_SEQ) FROM PD_RESULT_PROC_SPEC_VALUE_HIS A WITH (NOLOCK)    
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.IN_DATE = CONVERT(NVARCHAR(10), GETDATE(), 120)     
        ), 0) + 1    
    
        INSERT INTO PD_RESULT_PROC_SPEC_VALUE_HIS    
        (    
            DIV_CD,             PLANT_CD,          WC_CD,              LINE_CD,             PROC_CD,     
            IN_DATE,                
            IN_SEQ,             ORDER_NO,          REVISION,           RESULT_SEQ,          S_CHK,  
            CYCLE_SEQ,          INSERT_ID,         INSERT_DT,          UPDATE_ID,           UPDATE_DT     
        )    
        SELECT     
            @DIV_CD,            @PLANT_CD,         @WC_CD,             @LINE_CD,            @PROC_CD,     
            CONVERT(NVARCHAR(10), GETDATE(), 120),     
            @IN_SEQ,            @ORDER_NO,         @REVISION,          @RESULT_SEQ,         @S_CHK,  
            @CYCLE_SEQ,         @USER_ID,          GETDATE(),          @USER_ID,            GETDATE()    
    
        INSERT INTO PD_RESULT_PROC_SPEC_VALUE (    
            DIV_CD,              PLANT_CD,             ORDER_NO,              REVISION,              ORDER_TYPE,             ORDER_FORM,     
            ROUT_NO,             ROUT_VER,             WC_CD,                 LINE_CD,               PROC_CD,                S_CHK,           RESULT_SEQ,     
            CYCLE_SEQ,           SEQ,                  SPEC_VERSION,          PROC_SPEC_CD,          EQP_CD,                 SPEC_VALUE_TYPE,     
            SPEC_VALUE,          REMARK,               INSERT_ID,             INSERT_DT,             UPDATE_ID,              UPDATE_DT,    
            IN_DATE,             IN_SEQ    
        )    
    
        SELECT A.DIV_CD,         A.PLANT_CD,           A.ORDER_NO,            A.REVISION,            A.ORDER_TYPE,           A.ORDER_FORM,     
            A.ROUT_NO,           A.ROUT_VER,           A.WC_CD,               A.LINE_CD,             A.PROC_CD,              @S_CHK,          @RESULT_SEQ,    
            @CYCLE_SEQ,          A.SEQ,                A.SPEC_VERSION,        A.PROC_SPEC_CD,        A.EQP_CD,               A.SPEC_VALUE_TYPE,     
            CASE WHEN A.SET_FLAG = 'Y' AND  
            A.USEM_ITEM_GROUP = '' AND A.PROC_SPEC_VALUE <> '' THEN  
            A.PROC_SPEC_VALUE ELSE '' END  
             
            ,                  '',                   @USER_ID,              GETDATE(),             @USER_ID,               GETDATE(),    
            CONVERT(NVARCHAR(10), GETDATE(), 120),    
            @IN_SEQ    
            FROM PD_ORDER_PROC_SPEC A WITH (NOLOCK)     
        WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM     
          AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD     
          AND A.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)    
          AND A.RECYCLE_NO IN (@CYCLE_SEQ, '')   
    
    END     

    -- CAM3 포장이면?
    -- 바코드 채번 및 PD_ITEM_IN 에 넣어야 함. 

    IF @PLANT_CD = '1150' AND @PROC_CD = 'PA' AND dbo.FN_GET_LAST_PROC(@DIV_CD, @PLANT_CD, @ORDER_NO, @REVISION, @PROC_CD) = 'Y'
    BEGIN 
        SET @CYCLE_SEQ = @CYCLE_SEQ - 1 

        --SELECT @CYCLE_SEQ 
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

        DECLARE @VAL     INT      
               ,@ITEM_CD NVARCHAR(50) 
               ,@SIL_DT  NVARCHAr(10)
               ,@CYCLE_QTY NUMERIC(18,3) = 0 
               ,@LOT_NO  NVARCHAR(50) 

        SELECT @ITEM_CD = A.ITEM_CD, @SIL_DT = A.SIL_DT, @LOT_NO = A.LOT_NO
         FROM PD_RESULT A WITH (NOLOCK) 
         WHERE A.DIV_CD = @DIV_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM     
          AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD     
          AND A.RESULT_SEQ = @RESULT_SEQ 

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
        
        SET @CYCLE_QTY = ISNULL((SELECT A.SPEC_VALUE                              
        FROM PD_RESULT_PROC_SPEC_VALUE A  
        INNER JOIN PD_ORDER_PROC_SPEC B ON A.DIV_CD = B.DIV_CD AND A.PLANT_CD = B.PLANT_CD AND A.ORDER_NO = B.ORDER_NO                              
        AND A.REVISION = B.REVISION AND A.ORDER_TYPE = B.ORDER_TYPE AND A.ORDER_FORM = B.ORDER_FORM AND A.ROUT_NO = B.ROUT_NO AND A.ROUT_VER = B.ROUT_VER                              
        AND A.WC_CD = B.WC_CD AND A.LINE_CD = B.LINE_CD AND A.PROC_CD = B.PROC_CD AND A.PROC_SPEC_CD = B.PROC_SPEC_CD AND  ISNULL(B.USEM_ITEM_GROUP,'') <> ''                             
        AND B.EQP_CD IN (SELECT EQP_CD FROM @EQP_TBL)    
        
        INNER JOIN BA_SUB_CD C ON A.PROC_SPEC_CD = C.SUB_CD AND C.MAIN_CD = 'P2001' AND C.TEMP_CD5= 'R'                             
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE                              
        AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = @PROC_CD                              
        AND A.S_CHK = @S_CHK AND A.RESULT_SEQ = @RESULT_SEQ AND A.SPEC_VALUE <> ''                             
        AND A.CYCLE_SEQ = @CYCLE_SEQ 
        ),0)

        IF @CYCLE_QTY = 0 
        BEGIN 
            SET @MSG_CD = '9999'
            SET @MSG_DETAIL = '포장 수량이 등록되지 않았습니다. 포장 회차 : ' + CAST(@CYCLE_SEQ AS NVARCHAR)
            RETURN 1
        END     
      

        -- 바코드 생성

        INSERT INTO PALLET_MASTER (                             
        DIV_CD,         BARCODE,         BAR_SEQ,      ITEM_CD,         LOT_NO,         BAG_SIZE,          
        MOVE_TYPE,      BAR_DT,         INSERT_ID,      INSERT_DT,      UPDATE_ID,      UPDATE_DT,         
        LOT_GBN,        ITEM_TYPE,      DT,             SEQ,       
        CREATE_SYS,     USE_FLAG,       PRINT_CNT,      ORDER_NO,       ORDER_SEQ,      NSEQ
        --TEMP_CD1,      TEMP_CD2,      TEMP_CD3,      CON_NO,                    
                                    
        )                             
        VALUES (                             
        @DIV_CD,      @BARCODE,      @CYCLE_SEQ,         @ITEM_CD,      @LOT_NO,      @CYCLE_QTY,  
        @MOVE_TYPE,     CONVERT(NVARCHAR(6), CAST(@SIL_DT AS DATETIME), 12),  @USER_ID,      GETDATE(),          @USER_ID,      GETDATE(),                           
        'P',            @MTART,         @SIL_DT,        @PALLET_SEQ,
        'POP',         'Y',             1,              @ORDEr_NO,      @REVISION,      @RESULT_SEQ 
            --@ZDEDN,         @NSEQ,         @TOTALCNT,      @ZCOTNO,                             
                                        
        )     

        IF NOT EXISTS(               
        SELECT *FROM PALLET_MASTER A WITH (NOLOCK)                
        WHERE A.DIV_CD = @DIV_CD AND A.BARCODE = @BARCODE AND A.BAR_SEQ = @CYCLE_SEQ AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO                
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

        -- PD_ITEM_IN 등록 
        INSERT INTO PD_ITEM_IN                              
        (                        
            DIV_CD,              PLANT_CD,                 PROC_NO,                ORDER_NO,                    REVISION,                 ORDER_TYPE,                                     
            ORDER_FORM,          ROUT_NO,                  ROUT_VER,               WC_CD,                       LINE_CD,                  PROC_CD,                              
            S_CHK,                              
            RESULT_SEQ, SEQ,      ITEM_CD,                  LOT_NO,                    SL_CD,                       LOCATION_NO,              RACK_CD,                              
            SIL_DT,                                           
            GOOD_QTY,            INSERT_ID,                INSERT_DT,              UPDATE_ID,                   UPDATE_DT,                BARCODE                            

                
        )                             
        SELECT                              
            @DIV_CD,             @PLANT_CD,                @PROC_NO,               @ORDER_NO,                   @REVISION,                @ORDER_TYPE,                              
            @ORDER_FORM,         @ROUT_NO,    @ROUT_VER,              @WC_CD,                                 @LINE_CD,                                              
            '*',
            @S_CHK,                              
            @RESULT_SEQ,         @CYCLE_SEQ,               @ITEM_CD,               @LOT_NO,   '3000',                      @LINE_CD,                 @RACK_CD,                              
            @SIL_DT,                                      
            @CYCLE_QTY,            @USER_ID,                 GETDATE(),              @USER_ID,                    GETDATE(),                @BARCODE                            

        -- SAP 등록

        DECLARE @ZMESIFNO NVARCHAR(50) = ''
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
        ,B.GOOD_QTY
        ,CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END                     
        ,CASE WHEN ISNULL(E.ZLOT,0) = 0 THEN F.PALLET_QTY ELSE E.ZLOT END                     
    --    ,CASE WHEN CAST(ROUND(SUM(B.GOOD_QTY) / CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END, 0) AS INT) = 0 THEN 1                            
        --                  ELSE CAST(ROUND(SUM(B.GOOD_QTY) / CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END , 0) AS INT) END      
        ,1
        ,B.GOOD_QTY - (1 - 1) * CASE WHEN ISNULL(E.ZBAG,0) = 0 THEN F.SNP_QTY ELSE E.ZBAG END AS FBAG                           
                    
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
        AND A.S_CHK = B.S_CHK AND A.RESULT_SEQ = B.RESULT_SEQ AND B.SEQ = @CYCLE_SEQ                             
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
        


        IF NOT EXISTS(SELECT *FROM SAP_Z02MESF_P060 A WITH (NOLOCK)                             
        WHERE A.ZMESIFNO = @ZMESIFNO                            
        )                            
        BEGIN                             
            SET @MSG_CD = '9999'                            
            SET @MSG_DETAIL = 'SAP Interface 포장량 정보가 생성되지 않았습니다. 관리자에게 문의하여 주십시오.'                            
            RETURN 1      
        END                

                        
        UPDATE A SET A.ZMESIFNO = @ZMESIFNO                             
            FROM PD_ITEM_IN A  
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION                             
        AND A.ORDER_TYPE = @ORDER_TYPE AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER                             
        AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.PROC_CD = '*' AND A.RESULT_SEQ = @RESULT_SEQ    
        AND A.SEQ = @CYCLE_SEQ 
    END 
   
END TRY     
BEGIN CATCH     
    SET @MSG_CD = '9999'    
    SET @MSG_DETAIL = ERROR_MESSAGE()     
    RETURN 1     
END CATCH 