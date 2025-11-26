ALTER PROC USP_POP_004_MATERIAL_QUERY1(

--DECLARE
     @DIV_CD           NVARCHAR(10)    = '01'
    ,@PLANT_CD         NVARCHAR(10)    = '1130'
    ,@WC_CD            NVARCHAR(10)    = '13GA'
    ,@LINE_CD          NVARCHAR(20)    = '13G01A'
    ,@PROC_CD          NVARCHAr(10)    = 'RI' 
    ,@EQP_CD           NVARCHAR(50)    = 'LFG-MST-10-02'
    ,@ORDER_NO         NVARCHAR(50)    = 'PD250113002'
    ,@REVISION         INT             = 0
)
AS
-- 작업지시가 있다는 가정

IF @ORDEr_NO <> '' 
BEGIN 

    -- 오더 편성 정보에서 처리 한다. 

    IF @REVISION = '' 
    BEGIN 
        SET @REVISION = ISNULL((
            SELECT MAX(A.REVISION)
                FROM PD_ORDER A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD 
            AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD AND A.ORDER_NO = @ORDER_NO
        ),1)
    END 
    -- REVISION 을 가지고 왔으면 PD_ORDER_USEM 에서 정보를 확인한다.

    SELECT A.ITEM_CD, B.ITEM_NM, A.USEM_QTY, A.EQP_CD FROM PD_ORDER_USEM A WITH (NOLOCK) 
    INNER JOIN V_ITEM B WITH (NOLOCK) ON A.PLANT_CD = B.PLANT_CD AND A.ITEM_CD = B.ITEM_CD 
    WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.WC_CD = @WC_CD AND A.LINE_CD = @LINE_CD 
    AND A.ORDER_NO = @ORDER_NO AND A.REVISION = @REVISION AND A.PROC_CD = @PROC_CD AND A.EQP_CD = @EQP_CD 
END 



