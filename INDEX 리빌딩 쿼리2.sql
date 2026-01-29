/* 
기안번호 : PM260115002
기안구분 : 긴급
제목 : 소성 실적 삭제 및 INDEX 작업
일자 : 2026-01-15 
작업자 : 임종원 이사
*/   
ALTER INDEX PK_PD_RESULT_PROC_SPEC_VALUE
ON dbo.PD_RESULT_PROC_SPEC_VALUE
REORGANIZE;

/*
ALTER INDEX PK_PD_RESULT_PROC_SPEC_VALUE
ON dbo.PD_RESULT_PROC_SPEC_VALUE
REBUILD
WITH (FILLFACTOR = 80, MAXDOP = 1);

-- 2️⃣ 나머지 NONCLUSTERED
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + '
ALTER INDEX [' + i.name + '] 
ON dbo.PD_RESULT_PROC_SPEC_VALUE
REBUILD WITH (FILLFACTOR = 80, MAXDOP = 1);'
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.PD_RESULT_PROC_SPEC_VALUE')
  AND i.type_desc = 'NONCLUSTERED'
  AND i.is_disabled = 0
  AND i.name IS NOT NULL;

-- 확인용
PRINT @sql;

EXEC sp_executesql @sql;
*/
/*
ALTER INDEX PK_ST_STOCK_NOW
ON dbo.ST_STOCK_NOW
REORGANIZE;

/* =========================================================
   PK Index Rebuild Script (STANDARD SAFE VERSION)
   대상 : ST_ITEM_IN, ST_ITEM_OUT
   특징 :
     - PK만 리빌딩
     - 실패 시 즉시 중단 (서비스 영향 없음)
     - 사용자 많은 시간대 실행 가능
   ========================================================= */
/*
ALTER INDEX PK_ST_STOCK_NOW
ON dbo.ST_STOCK_NOW
REORGANIZE;
*/
SET LOCK_TIMEOUT 5000;        -- 5초 이상 대기 시 실패
SET DEADLOCK_PRIORITY LOW;
SET ARITHABORT ON;

DECLARE @TableName SYSNAME;
DECLARE @IndexName SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

DECLARE PK_CURSOR CURSOR LOCAL FAST_FORWARD FOR
SELECT
    t.name  AS TableName,
    i.name  AS IndexName
FROM sys.tables t
JOIN sys.indexes i
  ON t.object_id = i.object_id
WHERE t.name IN ('ST_STOCK_NOW')
  AND i.is_primary_key = 1;

OPEN PK_CURSOR;
FETCH NEXT FROM PK_CURSOR INTO @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        SET @SQL = N'
        ALTER INDEX ' + QUOTENAME(@IndexName) + '
        ON dbo.' + QUOTENAME(@TableName) + '
        REBUILD
        WITH (MAXDOP = 1);';

        EXEC sp_executesql @SQL;

        PRINT @TableName + ' - PK 리빌드 성공';
    END TRY
    BEGIN CATCH
        PRINT @TableName + ' - PK 리빌드 실패 (사용자 사용 중)';
    END CATCH;

    FETCH NEXT FROM PK_CURSOR INTO @TableName, @IndexName;
END;

CLOSE PK_CURSOR;
DEALLOCATE PK_CURSOR;

/*

SELECT
    t.name AS table_name,
    i.name AS pk_name,
    ips.avg_fragmentation_in_percent AS fragmentation_percent,
    ips.page_count,
    i.is_disabled,
    i.type_desc
FROM sys.dm_db_index_physical_stats
(
    DB_ID(),
    NULL,
    NULL,
    NULL,
    'SAMPLED'
) ips
JOIN sys.indexes i
  ON ips.object_id = i.object_id
 AND ips.index_id = i.index_id
JOIN sys.tables t
  ON i.object_id = t.object_id
WHERE t.name IN ('ST_sTOCK_NOW')
  AND i.is_primary_key = 1
ORDER BY t.name;



SELECT
    i.name,
    s.user_updates,
    s.user_seeks,
    s.user_scans
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i
  ON s.object_id = i.object_id
 AND s.index_id = i.index_id
WHERE s.object_id = OBJECT_ID('dbo.ST_STOCK_NOW');
/*

/* 데이터가 손실되지 않도록 하려면 데이터베이스 디자이너의 컨텍스트 외부에서 실행하기 전에 이 스크립트를 자세히 검토해야 합니다.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
DROP INDEX IX_ST_ITEM_OUT ON dbo.ST_ITEM_OUT
GO
CREATE NONCLUSTERED INDEX IX_ST_ITEM_OUT ON dbo.ST_ITEM_OUT
	(
	PROC_CD,
	LOT_NO DESC,
	ORDER_NO DESC,
	ORDER_SEQ,
	RESULTS_SEQ,
	USEM_SEQ,
	SL_CD,
	WC_CD,
	LOCATION_NO,
	RACK_CD,
	BARCODE,
	IN_DATE,
	IN_SEQ,
	REQ_NO
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE dbo.ST_ITEM_OUT SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

*/
*/
*/