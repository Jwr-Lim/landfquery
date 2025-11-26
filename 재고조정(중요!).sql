BEGIN TRAN 
-- 재공 데이터를 정리하자. 

DECLARE @LOOP_TABLE TABLE 
(
     CNT           INT IDENTITY(1,1)
    ,DIV_CD        NVARCHAR(10) 
    ,PLANT_CD      NVARCHAR(10)
    ,ITEM_CD       NVARCHAR(50) 
    ,LOT_NO        NVARCHAR(50) 
    ,WC_CD         NVARCHAR(10) 
    ,LOCATION_NO   NVARCHAR(10) 
    ,PROC_CD       NVARCHAR(10) 
    ,BARCODE       NVARCHAR(50) 
    ,RACK_CD       NVARCHAR(50) 
    ,CHA           NUMERIC(18,3) 
    ,QTY           NUMERIC(18,3) 
)

INSERT INTO @LOOP_TABLE (
     DIV_CD, PLANT_CD, ITEM_CD, LOT_NO, WC_CD, LOCATION_NO, PROC_CD, BARCODE, RACK_CD, CHA, QTY 
)
SELECT AAA.DIV_CD, AAA.PLANT_CD, AAA.ITEM_CD, AAA.LOT_NO, AAA.WC_CD, AAA.LOCATION_NO, AAA.PROC_CD, AAA.BARCODE, AAA.RACK_CD, AAA.CHA, BBB.QTY

    FROM 
    (
        SELECT AA.DIV_CD, AA.PLANT_CD, AA.ITEM_CD, AA.LOT_NO, AA.WC_CD, AA.LOCATION_NO, AA.PROC_CD, AA.BARCODE, AA.RACK_CD,
        SUM(AA.I) AS I, SUM(AA.O) AS O, SUM(AA.I) - SUM(AA.O) AS CHA
        FROM 
        (
            SELECT A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, ISNULL(A.BARCODE,'*') AS BARCODE, ISNULL(A.RACK_CD,'*') AS RACK_CD, 
            SUM(A.QTY) AS I, 0 AS O
            FROM ST_ITEM_IN A WITH (NOLOCK) 
            WHERE A.WC_CD <> '*' AND A.LOCATION_NO <> '*' AND A.PROC_CD <> '*' AND A.SL_CD = '3000'
            GROUP BY A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, A.BARCODE,  A.RACK_CD
            UNION ALL 
            SELECT A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, ISNULL(A.BARCODE,'*') AS BARCODE, ISNULL(A.RACK_CD,'*') AS RACK_CD, 
            0 AS I, SUM(A.QTY) AS O 
            FROM ST_ITEM_OUT A WITH (NOLOCK) 
            WHERE A.WC_CD <> '*' AND A.LOCATION_NO <> '*' AND A.PROC_CD <> '*' AND A.SL_CD = '3000'
            GROUP BY A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, A.BARCODE,  A.RACK_CD
        ) AA
        GROUP BY AA.DIV_CD, AA.PLANT_CD, AA.ITEM_CD, AA.LOT_NO, AA.WC_CD, AA.LOCATION_NO, AA.PROC_CD, AA.BARCODE, AA.RACK_CD
        --HAVING SUM(AA.I) - SUM(AA.O) > 0
    ) AAA 
    INNER JOIN ST_STOCK_NOW BBB WITH (NOLOCK) ON 
    AAA.DIV_CD = BBB.DIV_CD AND AAA.PLANT_CD = BBB.PLANT_CD AND AAA.ITEM_CD = BBB.ITEM_CD AND AAA.LOT_NO = BBB.LOT_NO AND AAA.WC_CD = BBB.WC_CD 
    AND AAA.LOCATION_NO = BBB.LOCATION_NO AND AAA.PROC_CD = BBB.PROC_CD AND AAA.BARCODE = BBB.BARCODE AND AAA.RACK_CD = BBB.RACK_CD AND BBB.SL_CD = '3000'
    AND AAA.CHA <> BBB.QTY 
    --AND AAA.CHA <> 0 AND BBB.QTY = 0 -- 조건 1
    --AND AAA.CHA > 0 AND BBB.QTY = 0   -- 조건 2
    --AND AAA.CHA = 0 AND BBB.QTY <> 0 -- 조건 3
    --AND AAA.CHA <> 0 AND BBB.QTY <> 0 
    ORDER BY AAA.LOT_NO

SELECT *FROM @LOOP_TABLE

DECLARE @ST NVARCHAR(1) = 'N'

IF @ST = 'N' 
BEGIN 
    ROLLBACK 
    RETURN 
END 

DECLARE @CNT  INT = 0 
       ,@TCNT INT = 0 

SELECT @TCNT = COUNT(*) FROM @LOOP_TABLE 

DECLARE @DATE    NVARCHAR(10) = CONVERT(NVARCHAR(10),GETDATE(), 120)
       ,@SEQ     INT = 0

WHILE @CNT <> @TCNT 
BEGIN 
    SET @CNT = @CNT + 1 

    DECLARE 
     @DIV_CD        NVARCHAR(10) 
    ,@PLANT_CD      NVARCHAR(10)
    ,@ITEM_CD       NVARCHAR(50) 
    ,@LOT_NO        NVARCHAR(50) 
    ,@WC_CD         NVARCHAR(10) 
    ,@LOCATION_NO   NVARCHAR(10) 
    ,@PROC_CD       NVARCHAR(10) 
    ,@BARCODE       NVARCHAR(50) 
    ,@RACK_CD       NVARCHAR(50) 
    ,@CHA           NUMERIC(18,3) 
    ,@QTY           NUMERIC(18,3) 
    ,@CAL_QTY       NUMERIC(18,3) 

    SELECT @DIV_CD = A.DIV_CD, @PLANT_CD = A.PLANT_CD, @ITEM_CD = A.ITEM_CD, @LOT_NO = A.LOT_NO, @WC_CD = A.WC_CD, @LOCATION_NO = A.LOCATION_NO,
    @PROC_CD = A.PROC_CD, @BARCODE = A.BARCODE, @RACK_CD = A.RACK_CD, @CHA = A.CHA, @QTY = A.QTY 
        FROM @LOOP_TABLE A WHERE A.CNT = @CNT 

    IF @CHA < 0 AND @QTY = 0
    BEGIN 
        SET @CAL_QTY = @QTY - @CHA
         
        -- 음수이므로... ST_ITEM_OUT 에 더 집어 넣고 
        -- ST_STOCK_NOW 는 그대로 다시 UPDATE 

        SET @SEQ = ISNULL((SELECT MAX(A.IN_SEQ) FROM ST_ITEM_IN A WITH (NOLOCK) 
        WHERE CONVERT(NVARCHAR(10),A.IN_DATE,120) = @DATE),0) + 1

--        SELECT @DATE, @SEQ 

        INSERT INTO ST_ITEM_IN 
        (
            DIV_CD,         PLANT_CD,       IN_DATE,          IN_SEQ,           ITEM_CD,          MOVE_TYPE,             
            WC_CD,          PROC_CD,        LOT_NO,          
            IN_UNIT,        QTY,            TABLENM,          ORDER_NO,         ORDER_SEQ,        RESULTS_SEQ,           SEQ,         
            SL_CD,          LOCATION_NO,    MAT_LOT,          RACK_CD,          BARCODE,          REMARK,           
            INSERT_ID,      INSERT_DT
        )
        SELECT 
            @DIV_CD,        @PLANT_CD,      @DATE,            @SEQ,             @ITEM_CD,         '506',                 -- 503 재고 실사
            @WC_CD,         @PROC_CD,       @LOT_NO, 
            'KG',           @CAL_QTY,       'BATCH',          '*',              0,                0,                     0,                
            '3000',         @LOCATION_NO,   '*',              @RACK_CD,         @BARCODE,         '수불조정BATCH',
            'haesol_ljw',   GETDATE()

        UPDATE A SET A.QTY = @QTY 
            FROM ST_STOCK_NOW A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.PROC_CD = @PROC_CD AND A.LOCATION_NO = @LOCATION_NO 
          AND A.BARCODE = @BARCODE AND A.RACK_CD= @RACK_CD AND A.SL_CD = '3000'    
    END 
    
    IF @CHA > 0 AND @QTY = 0
    BEGIN 
        SET @CAL_QTY = @CHA - @QTY 

--        SELECT @CAL_QTY 
        SET @SEQ = ISNULL((SELECT MAX(A.OUT_SEQ) FROM ST_ITEM_OUT A WITH (NOLOCK) 
        WHERE CONVERT(NVARCHAR(10), A.OUT_DATE, 120) = @DATE),0) + 1

        INSERT INTO ST_ITEM_OUT
        (
            DIV_CD,         PLANT_CD,       OUT_DATE,          OUT_SEQ,           ITEM_CD,          MOVE_TYPE,             
            WC_CD,          PROC_CD,        LOT_NO,          
            OUT_UNIT,        QTY,           TABLENM,          ORDER_NO,         ORDER_SEQ,        RESULTS_SEQ,           SEQ,         
            SL_CD,          LOCATION_NO,    MAT_LOT,          RACK_CD,          BARCODE,          REMARK,           
            INSERT_ID,      INSERT_DT
        )
        SELECT 
            @DIV_CD,        @PLANT_CD,      @DATE,            @SEQ,             @ITEM_CD,         '506',                 -- 503 재고 실사
            @WC_CD,         @PROC_CD,       @LOT_NO, 
            'KG',           @CAL_QTY,       'BATCH',          '*',              0,                0,                     0,                
            '3000',         @LOCATION_NO,   '*',              @RACK_CD,         @BARCODE,         '수불조정BATCH',
            'haesol_ljw',   GETDATE()

        UPDATE A SET A.QTY = @QTY 
            FROM ST_STOCK_NOW A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.PROC_CD = @PROC_CD AND A.LOCATION_NO = @LOCATION_NO 
          AND A.BARCODE = @BARCODE AND A.RACK_CD= @RACK_CD AND A.SL_CD = '3000'    

    END 

    IF @CHA = 0 AND @QTY > 0
    BEGIN 
        -- STOCK_NOW 만 다 처리 해야 된다. 
      --  SELECT '1' 
        
        UPDATE A SET A.QTY = @CHA
            FROM ST_STOCK_NOW A WITH (NOLOCK) 
        WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.PROC_CD = @PROC_CD AND A.LOCATION_NO = @LOCATION_NO 
          AND A.BARCODE = @BARCODE AND A.RACK_CD= @RACK_CD AND A.SL_CD = '3000'    

--        ROLLBACK 
  --      RETURN 
        

    END 

    if @CHA <> 0 AND @QTY <> 0 
    BEGIN 
        IF @CHA > 0 
        BEGIN 
            -- ST_ITEM_OUT 에 처리

            SET @CAL_QTY = @CHA
            SET @SEQ = ISNULL((SELECT MAX(A.OUT_SEQ) FROM ST_ITEM_OUT A WITH (NOLOCK) 
            WHERE CONVERT(NVARCHAR(10), A.OUT_DATE, 120) = @DATE),0) + 1

            INSERT INTO ST_ITEM_OUT
            (
                DIV_CD,         PLANT_CD,       OUT_DATE,          OUT_SEQ,           ITEM_CD,          MOVE_TYPE,             
                WC_CD,          PROC_CD,        LOT_NO,          
                OUT_UNIT,        QTY,           TABLENM,          ORDER_NO,         ORDER_SEQ,        RESULTS_SEQ,           SEQ,         
                SL_CD,          LOCATION_NO,    MAT_LOT,          RACK_CD,          BARCODE,          REMARK,           
                INSERT_ID,      INSERT_DT
            )
            SELECT 
                @DIV_CD,        @PLANT_CD,      @DATE,            @SEQ,             @ITEM_CD,         '506',                 -- 503 재고 실사
                @WC_CD,         @PROC_CD,       @LOT_NO, 
                'KG',           @CAL_QTY,       'BATCH',          '*',              0,                0,                     0,                
                '3000',         @LOCATION_NO,   '*',              @RACK_CD,         @BARCODE,         '수불조정BATCH',
                'haesol_ljw',   GETDATE()

            UPDATE A SET A.QTY = 0 
                FROM ST_STOCK_NOW A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.PROC_CD = @PROC_CD AND A.LOCATION_NO = @LOCATION_NO 
              AND A.BARCODE = @BARCODE AND A.RACK_CD= @RACK_CD AND A.SL_CD = '3000'    
        END 
        ELSE 
        BEGIN 
            -- ST_ITEM_IN 에 처리 
            SET @CAL_QTY = @CHA * (-1) 
            SET @SEQ = ISNULL((SELECT MAX(A.IN_SEQ) FROM ST_ITEM_IN A WITH (NOLOCK) 
            WHERE CONVERT(NVARCHAR(10),A.IN_DATE,120) = @DATE),0) + 1

    --        SELECT @DATE, @SEQ 

            INSERT INTO ST_ITEM_IN 
            (
                DIV_CD,         PLANT_CD,       IN_DATE,          IN_SEQ,           ITEM_CD,          MOVE_TYPE,             
                WC_CD,          PROC_CD,        LOT_NO,          
                IN_UNIT,        QTY,            TABLENM,          ORDER_NO,         ORDER_SEQ,        RESULTS_SEQ,           SEQ,         
                SL_CD,          LOCATION_NO,    MAT_LOT,          RACK_CD,          BARCODE,          REMARK,           
                INSERT_ID,      INSERT_DT
            )
            SELECT 
                @DIV_CD,        @PLANT_CD,      @DATE,            @SEQ,             @ITEM_CD,         '506',                 -- 503 재고 실사
                @WC_CD,         @PROC_CD,       @LOT_NO, 
                'KG',           @CAL_QTY,       'BATCH',          '*',              0,                0,                     0,                
                '3000',         @LOCATION_NO,   '*',              @RACK_CD,         @BARCODE,         '수불조정BATCH',
                'haesol_ljw',   GETDATE()

            UPDATE A SET A.QTY = 0 
                FROM ST_STOCK_NOW A WITH (NOLOCK) 
            WHERE A.DIV_CD = @DIV_CD AND A.PLANT_CD = @PLANT_CD AND A.ITEM_CD = @ITEM_CD AND A.LOT_NO = @LOT_NO AND A.PROC_CD = @PROC_CD AND A.LOCATION_NO = @LOCATION_NO 
              AND A.BARCODE = @BARCODE AND A.RACK_CD= @RACK_CD AND A.SL_CD = '3000'    

        END 
       -- ROLLBACK
        --RETURN 
    END 

END 

SELECT AAA.DIV_CD, AAA.PLANT_CD, AAA.ITEM_CD, AAA.LOT_NO, AAA.WC_CD, AAA.LOCATION_NO, AAA.PROC_CD, AAA.BARCODE, AAA.RACK_CD, AAA.CHA, BBB.QTY

    FROM 
    (
        SELECT AA.DIV_CD, AA.PLANT_CD, AA.ITEM_CD, AA.LOT_NO, AA.WC_CD, AA.LOCATION_NO, AA.PROC_CD, AA.BARCODE, AA.RACK_CD,
        SUM(AA.I) AS I, SUM(AA.O) AS O, SUM(AA.I) - SUM(AA.O) AS CHA
        FROM 
        (
            SELECT A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, ISNULL(A.BARCODE,'*') AS BARCODE, ISNULL(A.RACK_CD,'*') AS RACK_CD, 
            SUM(A.QTY) AS I, 0 AS O
            FROM ST_ITEM_IN A WITH (NOLOCK) 
            WHERE A.WC_CD <> '*' AND A.LOCATION_NO <> '*' AND A.PROC_CD <> '*' AND A.SL_CD = '3000'
            GROUP BY A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, A.BARCODE,  A.RACK_CD
            UNION ALL 
            SELECT A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, ISNULL(A.BARCODE,'*') AS BARCODE, ISNULL(A.RACK_CD,'*') AS RACK_CD, 
            0 AS I, SUM(A.QTY) AS O 
            FROM ST_ITEM_OUT A WITH (NOLOCK) 
            WHERE A.WC_CD <> '*' AND A.LOCATION_NO <> '*' AND A.PROC_CD <> '*' AND A.SL_CD = '3000'
            GROUP BY A.DIV_CD, A.PLANT_CD, A.ITEM_CD, A.LOT_NO, A.WC_CD, A.LOCATION_NO, A.PROC_CD, A.BARCODE,  A.RACK_CD
        ) AA
        GROUP BY AA.DIV_CD, AA.PLANT_CD, AA.ITEM_CD, AA.LOT_NO, AA.WC_CD, AA.LOCATION_NO, AA.PROC_CD, AA.BARCODE, AA.RACK_CD
        --HAVING SUM(AA.I) - SUM(AA.O) > 0
    ) AAA 
    INNER JOIN ST_STOCK_NOW BBB WITH (NOLOCK) ON 
    AAA.DIV_CD = BBB.DIV_CD AND AAA.PLANT_CD = BBB.PLANT_CD AND AAA.ITEM_CD = BBB.ITEM_CD AND AAA.LOT_NO = BBB.LOT_NO AND AAA.WC_CD = BBB.WC_CD 
    AND AAA.LOCATION_NO = BBB.LOCATION_NO AND AAA.PROC_CD = BBB.PROC_CD AND AAA.BARCODE = BBB.BARCODE AND AAA.RACK_CD = BBB.RACK_CD AND BBB.SL_CD = '3000'
    AND AAA.CHA <> BBB.QTY 
   -- AND AAA.CHA <> 0 AND BBB.QTY = 0 -- 조건 1
    -- AND AAA.CHA = 0 AND BBB.QTY <> 0 -- 조건 2
    --AND AAA.CHA <> 0 AND BBB.QTY <> 0 
    ORDER BY AAA.LOT_NO

ROLLBACK 
RETURN 

