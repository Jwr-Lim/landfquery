SET NOCOUNT ON;
SET LOCK_TIMEOUT 5000;
SET DEADLOCK_PRIORITY LOW;
SET ARITHABORT ON;

DECLARE @TableName SYSNAME;
DECLARE @IndexName SYSNAME;
DECLARE @Frag FLOAT;
DECLARE @SQL NVARCHAR(MAX);

DECLARE IDX_CURSOR CURSOR LOCAL FAST_FORWARD FOR
SELECT
    t.name,
    i.name,
    ips.avg_fragmentation_in_percent
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
WHERE t.name IN ('ST_ITEM_IN', 'ST_ITEM_OUT')
  AND i.is_primary_key = 1
  AND ips.page_count >= 1000;

OPEN IDX_CURSOR;
FETCH NEXT FROM IDX_CURSOR INTO @TableName, @IndexName, @Frag;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        IF @Frag >= 30
        BEGIN
            SET @SQL = '
            ALTER INDEX ' + QUOTENAME(@IndexName) + '
            ON dbo.' + QUOTENAME(@TableName) + '
            REBUILD WITH (MAXDOP = 1);';

            EXEC sp_executesql @SQL;
            PRINT @TableName + ' PK REBUILD (' + CAST(@Frag AS VARCHAR) + '%)';
        END
        ELSE IF @Frag >= 5
        BEGIN
            SET @SQL = '
            ALTER INDEX ' + QUOTENAME(@IndexName) + '
            ON dbo.' + QUOTENAME(@TableName) + '
            REORGANIZE;';

            EXEC sp_executesql @SQL;
            PRINT @TableName + ' PK REORGANIZE (' + CAST(@Frag AS VARCHAR) + '%)';
        END
        ELSE
        BEGIN
            PRINT @TableName + ' PK OK (' + CAST(@Frag AS VARCHAR) + '%)';
        END
    END TRY
    BEGIN CATCH
        PRINT @TableName + ' PK 정리 실패';
    END CATCH;

    FETCH NEXT FROM IDX_CURSOR INTO @TableName, @IndexName, @Frag;
END;

CLOSE IDX_CURSOR;
DEALLOCATE IDX_CURSOR;
