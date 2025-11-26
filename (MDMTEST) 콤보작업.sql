-- 콤보 작업
ALTER PROC USP_MDM705CON_COMBO(
    @GBN     NVARCHAR(1) 
    ,@MCASE  NVARCHAR(50) = ''
)
AS 

IF @GBN = 'M' 
BEGIN
    select aa.code, aa.name 
    from 
    ( 
        SELECT  
        SUBSTRING(A.MCASE, 0, CHARINDEX(' ', A.MCASE)) AS CODE, A.MCASE AS NAME 
        FROM PD_MDM_BASE_CODE A WITH (NOLOCK) 
        GROUP BY A.MCASE 
        union all 
        select 
        'pre-bare' as code, 'Pre-Bare 혼합 시작'
    ) aa  
    order by aa.code, aa.name 
END

IF @GBN = 'E'
BEGIN
    SELECT A.EQP_CD AS CODE, B.EQP_NM AS NAME FROM FLEXAPI_NEW.DBO.IFM705_MASTER_TMP A WITH (NOLOCK) 
    INNER JOIN BA_EQP B WITH (NOLOCK) ON B.PLANT_CD = '1130' AND A.EQP_CD = B.EQP_CD AND CASE WHEN A.PROC_CD = 'RB' THEN 'SE' ELSE A.PROC_CD END = B.PROC_CD
    WHERE A.[CASE] = @MCASE 
    GROUP BY A.EQP_CD, B.EQP_NM
END

IF @GBN = 'C'
BEGIN
    SELECT '1' AS CODE, '1화차' AS NAME 
    UNION ALL 
    SELECT '2' AS CODE, '2화차' AS NAME 
    UNION ALL 
    SELECT '3' AS CODE, '3화차' AS NAME 
    UNION ALL 
    SELECT '4' AS CODE, '4화차' AS NAME 

END 



