-- 신규 실적 등록 (코팅을 위함)
begin tran 
DECLARE @ORDER_NO NVARCHAR(50) = 'PD250929001'
       ,@LOT_INFO NVARCHAR(50) = '' 
       ,@ITEM_CD  NVARCHAR(50) = 'F013C004'
       ,@DIV_CD   NVARCHAR(10) = '01' 
       ,@PLANT_CD NVARCHAR(10) = '1130'
       ,@LOT_NO   NVARCHAR(50) = 'G2510-CLC-NAD-XXX-XXX-CN-100'
       ,@PROC_CD  NVARCHAR(10) = 'PA'
       ,@RESULT_SEQ INT = 0 

SELECT LOT_INFO FROM V_ITEM WITH (NOLOCK) 
WHERE PLANT_CD = @PLANT_CD AND ITEM_cD = @ITEM_CD 


 declare @cnt int = 0
        ,@tcnt int = 5

while @cnt <> @tcnt 
begin 
 set @cnt = @cnt + 1
 
 INSERT INTO PD_RESULT 
    (
        DIV_CD,            PLANT_CD,             PROC_NO,                ORDER_NO,                REVISION,      
        ORDER_TYPE,        ORDER_FORM,           ROUT_NO,                ROUT_VER,                WC_CD, 
        LINE_CD,           PROC_CD,              S_CHK,                  RESULT_SEQ,              ITEM_CD, 
        LOT_NO,            LOT_SEQ,              RESULT_QTY,             GOOD_QTY,                GROUP_LOT, 
        GROUP_YN,          RK_DATE,              SDATE,                  EDATE,                   SIL_DT, 
        DAY_FLG,           J_CHK,                J_SEQ,                  J_VAL,                   EQP_CD,                   
        INSERT_ID,         INSERT_DT,            UPDATE_ID,              UPDATE_DT,               ZMESIFNO
    )
    /*
            @DIV_CD,           @PLANT_CD,            @PROC_NO,               @ORDER_NO,               @REVISION, 
        @ORDER_TYPE,       @ORDER_FORM,          @ROUT_NO,               @ROUT_VER,               @WC_CD, 
        @LINE_CD,          @PROC_CD,             'N',                    @RESULT_SEQ,             @ITEM_CD, 
        @LOT_NO,           0,                    0,                      0,                       @LOT_NO, 
        'N',               @RK_DATE,             @SDATE,                 NULL,                    @SIL_DT, 
        @DAY_FLG,          'N',                  0,                      '%',                     @EQP_CD,
        @USER_ID,          GETDATE(),            @USER_ID,               GETDATE(),               ''
*/
    SELECT 
        A.DIV_CD,         A.PLANT_CD,            A.PROC_NO,             A.ORDER_NO,               A.REVISION, 
        A.ORDER_TYPE,     A.ORDER_FORM,          A.ROUT_NO,             A.ROUT_VER,               A.WC_CD, 
        A.LINE_CD,        @PROC_CD,                  'N',                   @cnt,                     A.ITEM_CD, 
        'G2510-CLC-NAD-XXX-XXX-CN-100' + CAST(@CNT AS NVARCHAR),@CNT,     '3000',                '3000',                   'PRTESET111',
        'N',              '',                    GETDATE(),             GETDATE(),                '2025-10-30',
        'D',              'N',                   0,                     '',                       'LFG01A-01C-RDM-0801',
        'admin',          GETDATE(),             'admin',               GETDATE(),                ''
    FROM PD_ORDER A
    WHERE A.ORDER_NO = @ORDEr_NO

  INSERT INTO PD_ITEM_IN
                (
                DIV_CD, PLANT_CD, PROC_NO, ORDER_NO, REVISION,
                ORDER_TYPE, ORDER_FORM, ROUT_NO, ROUT_VER, WC_CD,
                LINE_CD, PROC_CD, S_CHK, RESULT_SEQ, SEQ,
                ITEM_CD, LOT_NO, SL_CD, LOCATION_NO, RACK_CD,
                BARCODE, SIL_DT, DEPARTMENT, IDX_DT, IDX_SEQ,
                GOOD_QTY, INSERT_ID, INSERT_DT, UPDATE_ID, UPDATE_DT
                )

            SELECT
                A.DIV_CD, A.PLANT_CD, A.PROC_NO, A.ORDER_NO, A.REVISION,
                A.ORDER_TYPE, A.ORDER_FORM, A.ROUT_NO, A.ROUT_VER, A.WC_CD,
                A.LINE_CD, CASE WHEN A.PROC_CD = 'PA' THEN '*' ELSE A.PROC_CD END, A.S_CHK, A.RESULT_SEQ, 1,
                A.ITEM_CD, A.LOT_NO, '3000', A.LINE_CD, '*',
                '*', A.SIL_DT, '', '2025-10-30', @cnt,
                A.GOOD_QTY, 'admin', GETDATE(), 'admin', GETDATE()

            FROM PD_RESULT A
            WHERE A.DIV_CD = @div_cd and a.plant_cd = @plant_cd and a.order_no = @order_no and a.proc_cd = @PROC_cD and a.result_seq = @cnt 

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
                    A.LOT_SEQ,         '',     'admin',              GETDATE(),            'admin',                         
                    GETDATE(),         A.SIL_DT,           3000              
                FROM PD_RESULT A WITH (NOLOCK)                         
            WHERE A.DIV_CD = @div_cd and a.plant_cd = @plant_cd and a.order_no = @order_no and a.proc_cd = @PROC_cD and a.result_seq = @cnt 

end 

select *from pd_result a with (nolock)
where a.order_no = @order_no AND A.PROC_CD = @PROC_CD 

select *from pd_item_in a with (nolock)
where a.order_no = @order_no AND A.PROC_cD = CASE WHEN @PROC_cD = 'PA' THEN '*' ELSE @PROC_CD END 

select *from QC_PQC_ORDER A WITH (NOLOCK)
where a.order_no = @order_no AND A.PROC_CD = @PROC_CD 

SELECT *FROM ST_STOCK_NOW A WHERE A.LOT_NO LIKE @LOT_NO + '%' 
AND A.PROC_cD = CASE WHEN @PROC_cD = 'PA' THEN '*' ELSE @PROC_CD END 



rollback
