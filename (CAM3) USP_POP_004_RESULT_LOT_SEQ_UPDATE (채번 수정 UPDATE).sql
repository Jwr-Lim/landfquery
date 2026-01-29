/*  
-- 240604-H005  
-- 긴급처리  
-- [긴급] CAM1 유지보수  
-- 순번 조정  
-- 2024.06.01  임종원 이사   
-- 분쇄,  G1R 순번 조정  
*/  
  
ALTER PROC USP_POP_004_RESULT_LOT_SEQ_UPDATE(  
  
     @DIV_CD         NVARCHAR(10)   
    ,@PLANT_CD       NVARCHAR(10)   
    ,@ORDER_NO       NVARCHAR(50)   
    ,@REVISION       INT   
    ,@ORDER_TYPE     NVARCHAR(10)   
    ,@ORDER_FORM     NVARCHAR(10)   
    ,@ROUT_NO        NVARCHAR(10)   
    ,@ROUT_VER       INT   
    ,@WC_CD          NVARCHAR(10)   
    ,@LINE_CD        NVARCHAR(10)   
    ,@PROC_CD        NVARCHAR(10)   
    ,@S_CHK          NVARCHAR(1) = 'N'  
    ,@RESULT_sEQ     INT   
    ,@LOT_NO         NVARCHAR(50)   
    ,@LOT_SEQ        INT   
    ,@MSG_CD         NVARCHAR(4)    OUTPUT   
    ,@MSG_DETAIL     NVARCHAR(MAX)  OUTPUT   
)  
AS  
  
SET NOCOUNT ON   
  
  
BEGIN TRY   
      
      
    -- 첨가제일 경우 LOT 채번을 강제 조정을 진행한다.   
    IF @WC_CD IN ('13P', '14C','13R')  
    BEGIN     
        -- 이미 실적이 등록이 되어 있는지를 확인한다.  
        IF (SELECT SUM(A.USEM_QTY) FROM pd_usem A WITH (NOLOCK)   
        WHERE A.DIV_CD = @DIV_CD   
          AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE   
          AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD   
          AND A.PROC_CD = @PROC_CD AND A.RESULT_SEQ = @RESULT_SEQ   
  
        ) > 0   
        BEGIN   
  
            UPDATE A SET A.LOT_NO = @LOT_NO, A.LOT_SEQ = @LOT_SEQ, A.J_SEQ = @LOT_SEQ   
                FROM PD_RESULT A WITH (NOLOCK)   
            WHERE A.DIV_CD = @DIV_CD   
              AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE   
              AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD   
              AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ   
        END   
        ELSE   
        BEGIN   
            SET @MSG_CD = '9999'  
            SET @MSG_DETAIL = '실적 재고가 등록되지 않았습니다. 변경 불가 합니다.'  
            RETURN 1  
        END   
    END     

    IF @PLANT_CD = '1150' AND @PROC_CD = 'PA' 
    BEGIN 
        UPDATE A SET A.LOT_NO = @LOT_NO, A.LOT_SEQ = @LOT_SEQ
            FROM PD_RESULT A WITH (NOLOCK)   
        WHERE A.DIV_CD = @DIV_CD   
            AND A.PLANT_CD = @PLANT_CD AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.ORDER_TYPE = @ORDER_TYPE   
            AND A.ORDER_FORM = @ORDER_FORM AND A.ROUT_NO = @ROUT_NO AND A.ROUT_VER = @ROUT_VER AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD   
            AND A.PROC_CD = @PROC_CD AND A.S_CHK = 'N' AND A.RESULT_SEQ = @RESULT_SEQ   
    END 
  
END TRY   
BEGIN CATCH   
    SET @MSG_CD = '9999'  
    SET @MSG_DETAIL = ERROR_MESSAGE()   
    RETURN 1   
END CATCH