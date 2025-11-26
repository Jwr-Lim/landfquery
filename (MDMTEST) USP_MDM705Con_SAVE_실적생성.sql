
ALTER proc USP_MDM705Con_SAVE(


     @MCASE       NVARCHAR(50) = 'pre-bare 원료투입 시작'
     ,@PD_AUTO_NO NVARCHAR(50) = 'PD253100001'
     ,@AUTO_NO     NVARCHAR(50) = '253100001'
     ,@EQP_CD     NVARCHAR(50) = ''
     ,@QTY        NUMERIC(18,3) = 100
     ,@CYCLE      NVARCHAR(1) = '1'
     ,@MSG_CD     NVARCHAR(4) OUTPUT 
     ,@MSG_DETAIL NVARCHAR(MAX) OUTPUT 
)
AS

BEGIN TRY 
/*
update aa set aa.test_id = bb.cnt 
from PD_MDM_BASE_CODE aa inner join (
SELECT a.mcase, max(b.InboundId_ApiAutoCreate) as cnt from PD_MDM_BASE_CODE A
inner join flexapi_new.dbo.ifm705_master b on a.mcase = b.[case]
where a.mcase like 'bare%'
group by a.mcase
) bb on aa.mcase = bb.mcase 
*/

    DECLARE @TEST_ID INT = 0 
        ,@NEW_ID INT = 0 

--    SELECT @TEST_ID = A.TEST_ID FROM PD_MDM_BASE_CODE A WHERE A.MCASE = @MCASE 
    SELECT @test_id = max(a.InboundId_ApiAutoCreate)
    from flexapi_new.dbo.ifm705_master_tmp a with (nolock) 
    where a.[case] = @mcase and a.eqp_cd = @eqp_cd 
    

    SELECT @NEW_ID = MAX(A.INBOUNDID_APIAUTOCREATE) + 1 FROM FLEXAPI_NEW.DBO.IFM705_MASTER A 
--    WHERE A.EQP_CD = @EQP_CD AND A.[CASE] = @MCASE 

    -- MASTER 에 INSERT 한다 

    INSERT INTO FLEXAPI_NEW.DBO.IFM705_MASTER 
    SELECT 
    @NEW_ID
    ,STATUS_APIAUTOCREATE
    ,BIL_ID
    ,[CASE]
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,NULL
    ,WC_CD
    ,LINE_CD
    ,PROC_CD
    ,NULL
    ,@EQP_CD --'LFG01A-01B-TK-0502'
    ,NULL
    ,START_DM
    ,END_DM
    ,PACK_LOT_NO
    ,PACK_DM
    ,START_WEI_TAG
    ,START_WEI
    ,END_WEI_TAG
    ,END_WEI
    ,NET_WEI_TAG
    ,NET_WEI
    ,SETTIME_VAL_TAG
    ,SETTIME_VAL
    ,PBTK_TYPE_TAG
    ,PBTK_TYPE
    ,WEI_SV_TAG
    ,WEI_SV
    ,WEI_PV_TAG
    ,WEI_PV
    ,ERROR_SV_TAG
    ,ERROR_SV
    ,ERROR_PV_TAG
    ,ERROR_PV
    ,CASE_UNIT_TAG
    ,CASE_UNIT
    ,REV_PASS_TAG
    ,REV_PASS
    ,WEI_SKIP_TAG
    ,WEI_SKIP
    ,PACK_CNT_TAG
    ,PACK_CNT
    ,WEI_SV_CNT_TAG
    ,WEI_SV_CNT
    ,WEI_CNT_TAG
    ,WEI_CNT
    ,IN_WATER_TYPE
    ,REG_DM
    ,UPD_DM
    ,'J'
    FROM FLEXAPI_NEW.DBO.IFM705_MASTER_tmp
    WHERE INBOUNDID_APIAUTOCREATE = @TEST_ID 

    IF @MCASE LIKE '%원료투입%'
    BEGIN 
        UPDATE A SET A.PD_AUTO_NO = @PD_AUTO_NO, A.AUTO_NO = @AUTO_NO
            FROM FLEXAPI_NEW.DBO.IFM705_MASTER A
        WHERE A.INBOUNDID_APIAUTOCREATE = @NEW_ID
    END 


    DECLARE @P_VALUE INT 
    ,@P_MSG_CD NVARCHAR(4) 
    ,@P_MSG_DETAIL NVARCHAR(MAX)
    -- 
    EXEC @P_VALUE = USP_MDM_PROD_INFO_QUERY 
    @INBOUNDID = @NEW_ID --2285--2547--= '2570' 
    ,@MSG_CD = @P_MSG_CD OUTPUT 
    ,@MSG_DETAIL = @P_MSG_DETAIL OUTPUT

    IF  @P_VALUE = 1
    BEGIN 
        SET @MSG_CD = '9999'
        SET @MSG_DETAIL = 'USP_MDM_PROD_INFO : ' + CAST(@NEW_ID AS NVARCHAR)
        RETURN 1
    END

    UPDATE A SET A.VALUE = @QTY FROM PD_MDM_RESULT_PROC_SPEC A
    WHERE A.INBOUND_ID = @NEW_ID AND TAG_ID <> '' AND COL_CHK = 'V' 

    UPDATE A SET A.ROTATION = @CYCLE FROM PD_MDM_RESULT_PROC_SPEC A
    WHERE A.INBOUND_ID = @NEW_ID

--        select *from flexapi_new.dbo.ifm705_master where InboundId_ApiAutoCreate = @new_id 

END TRY 
BEGIN CATCH 
    SET @MSG_CD = '9999'
    SET @MSG_DETAIL = ERROR_MESSAGE()
    RETURN 1
END CATCH 
