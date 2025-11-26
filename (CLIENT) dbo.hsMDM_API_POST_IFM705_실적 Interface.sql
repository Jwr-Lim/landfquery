use FlexAPI_NEW
go

---------------------------------------------------------------------
-- Copyright © 2024. Haesol Information Technology. All rights reserved.
---------------------------------------------------------------------
-- 버전			: hsMDM.net
---------------------------------------------------------------------
-- 프로그램 명	: hsMDM_API_POST_IFM705
-- 프로그램 ID	: hsMDM
-- 작성일	: 2025.08
-- 작성자	: 김혜진
-- 수정일	: 2025.08.26
-- 수정자	: 김혜진
---------------------------------------------------------------------
-- ID		: IFM705
-- TASK		: MDM 작업정보요청(수신)->(송신)
---------------------------------------------------------------------

/*  
EXEC hsMDM_API_POST_IFM705
	@InboundId		= 2165,
	@ACT_TYPE		= 'C'
*/

ALTER   PROCEDURE dbo.hsMDM_API_POST_IFM705 
(
	@InboundId		BIGINT,
	@ACT_TYPE		NVARCHAR(10) = 'C'
)
--WITH ENCRYPTION
AS
BEGIN

	SET NOCOUNT ON
	
	--IF ISNULL(@DIV_CD, '') = ''		SET @DIV_CD = '%'
	--IF ISNULL(@PLANT_CD, '') = ''	    SET @PLANT_CD = '%'

	--채번 TEST...
	------------------------------------------------------------------------------------------------------
	DECLARE @AUTO_NO		NVARCHAR(30) = '',
			@AUTO_NO2		NVARCHAR(30) = '',
			@AUTO_NO3		NVARCHAR(30) = '',
			@CURRNT_DATE	NVARCHAR(10)

	SET @CURRNT_DATE = FORMAT(GETDATE(), 'yyyy-MM-dd')

	--IF (SELECT COUNT(*) FROM IFM705_Master_TMP (NOLOCK) WHERE Inboundid_ApiAutoCreate = @InboundId) > 0
	IF (SELECT COUNT(*) FROM IFM705_Master (NOLOCK) WHERE Inboundid_ApiAutoCreate = @InboundId) > 0
	BEGIN

        DECLARE @STR_DATE NVARCHAR(8) = ''
		SET @STR_DATE = CONVERT(NVARCHAR(8), GETDATE(), 112)
    -- AUTO_NO (yyyddd) : Test

        EXEC FlexMES_NEW.DBO.USP_CM_AUTO_NUMBERING 'MD', @STR_DATE, 'admin', @AUTO_NO OUT

/*
		EXEC hsMDM_AutoNumbering
			@AUTO_NO_TYPE				= 'MDM',
			@CURRNT_DATE				= @CURRNT_DATE,
			@USER_ID					= 'MDMADMIN',
			@LAST_AUTO_NO				= @AUTO_NO OUTPUT 
*/
		-- ORDER_NO (PD + yyyyMMdd + 000) : Test
		EXEC hsMDM_AutoNumbering
			@AUTO_NO_TYPE				= 'PD',
			@CURRNT_DATE				= @CURRNT_DATE,
			@USER_ID					= 'MDMADMIN',
			@LAST_AUTO_NO				= @AUTO_NO2 OUTPUT 

		-- PLAN_SEQ (0000) : Test
		EXEC hsMDM_AutoNumbering
			@AUTO_NO_TYPE				= 'SEQ',
			@CURRNT_DATE				= @CURRNT_DATE,
			@USER_ID					= 'MDMADMIN',
			@LAST_AUTO_NO				= @AUTO_NO3 OUTPUT 
	END
	------------------------------------------------------------------------------------------------------
	--SELECT * FROM IFM705_Master_TMP WHERE InboundId_ApiAutoCreate = 1527
	--SELECT * FROM IFM705_Master WHERE InboundId_ApiAutoCreate = 1527
	--SELECT (CASE WHEN RIGHT([CASE], 2) IN ('완료', '종료') THEN AUTO_NO ELSE CAST(0 AS INT) END) AS AUTO_NO FROM IFM705_Master WHERE InboundId_ApiAutoCreate = 1526

	--EXEC SP
	DECLARE @WC_CD NVARCHAR(10) = ''
	       ,@LINE_CD NVARCHAR(10) = ''
		   ,@PROC_CD NVARCHAR(10) = '' 
		   ,@CHK_YN NVARCHAR(1) = 'N'
		   ,@EQP_CD NVARCHAR(50) = ''
	SELECT @WC_CD = WC_CD, @LINE_CD = LINE_CD, @PROC_CD = PROC_CD, @EQP_CD = EQP_CD
		FROM IFM705_Master (NOLOCK)
	WHERE 1 = 1
	AND Inboundid_ApiAutoCreate = @InboundId

	--IF ISNULL(@LINE_CD,'') NOT IN ('13G01B')
	BEGIN 
		IF ISNULL(@PROC_CD,'') IN  ('RI','AI') 
		BEGIN
			SET @CHK_YN = 'Y'
		END 

		IF @LINE_CD = '13G01B' AND @PROC_CD IN ('RH') AND @EQP_CD IN (
			'LFG01A-01B-PS-0301','LFG01A-01B-PS-0302'			--'LFG01A-01B-RCV-0401', 'LFG01A-01B-RCV-0402')
		)
		BEGIN
			SET @CHK_YN = 'Y'
		END

		IF @LINE_CD = '13G01A' AND @PROC_CD = 'RK' AND @EQP_CD IN ('LFG01A-01B-TK-0501','LFG01A-01B-TK-0502','LFG01A-01A-RCO-0701','LFG01A-01A-RCO-0702')
		BEGIN
			SET @CHK_YN = 'Y'
		END

		IF @LINE_CD = '13G01B' AND @PROC_CD IN ('RB','SI','EM','PA')
		BEGIN
			SET @CHK_YN = 'Y'
		END

		SET @CHK_YN = 'Y'
		
		IF @CHK_YN = 'N'
		BEGIN
			DECLARE @I_VALUE INT 
			,@MSG_CD NVARCHAR(4) 
			,@MSG_DETAIL NVARCHAR(MAX)
			-- 
			EXEC @I_VALUE = flexmes_new.dbo.USP_MDM_PROD_INFO_QUERY 
			@INBOUNDID = @InboundId
			,@MSG_CD = @MSG_CD OUTPUT 
			,@MSG_DETAIL = @MSG_DETAIL OUTPUT
		END 
	END 
--	SELECT @I_VALUE, @MSG_CD, @MSG_DETAIL

	SELECT 
		BIL_ID,
		[CASE],
		DIV_CD,
		PLANT_CD,
		PD_AUTO_NO,
		--CAST(@AUTO_NO AS INT) AS AUTO_NO,
		--(CASE WHEN RIGHT([CASE], 2) IN ('완료', '종료') THEN AUTO_NO ELSE CAST(@AUTO_NO AS INT) END) AS AUTO_NO, --2025.09.25
		--(CASE WHEN AUTO_NO IS NOT NULL AND PD_AUTO_NO IS NOT NULL THEN AUTO_NO ELSE CAST(@AUTO_NO AS INT) END) AS 
		AUTO_NO, --2025.09.25
		--@AUTO_NO2 AS ORDER_NO,
		--(CASE WHEN RIGHT([CASE], 2) IN ('완료', '종료') THEN ORDER_NO ELSE @AUTO_NO2 END) AS ORDER_NO, --2025.09.25
		--(CASE WHEN AUTO_NO IS NOT NULL AND PD_AUTO_NO IS NOT NULL THEN ORDER_NO ELSE @AUTO_NO2 END) AS 
		ORDER_NO, --2025.09.25
		WC_CD,
		LINE_CD,
		PROC_CD,
		--@AUTO_NO3 AS PLAN_SEQ,
		--(CASE WHEN RIGHT([CASE], 2) IN ('완료', '종료') THEN PLAN_SEQ ELSE CAST(@AUTO_NO3 AS INT) END) AS PLAN_SEQ, --2025.09.25
		--(CASE WHEN AUTO_NO IS NOT NULL AND PD_AUTO_NO IS NOT NULL THEN PLAN_SEQ ELSE CAST(@AUTO_NO3 AS INT) END) 
		PLAN_SEQ, --2025.09.25
		--ECP_CD,
		EQP_CD, --2025.09.18
		LOT_NO,
		-- RK 소성일때 설정시간 으로 (-) 업데이트
		CASE WHEN ISNULL(START_DM,'') = '' AND END_DM <> '' THEN DATEADD(MINUTE, -10, CAST(END_DM AS DATETIME)) ELSE START_DM END AS START_DM,
		END_DM,
		PACK_LOT_NO,
		PACK_DM,
		START_WEI_TAG,
		START_WEI,
		END_WEI_TAG,
		END_WEI,
		NET_WEI_TAG,
		NET_WEI,
		SETTIME_VAL_TAG,
		SETTIME_VAL,
		PBTK_TYPE_TAG,
		PBTK_TYPE,
		WEI_SV_TAG,
		WEI_SV,
		WEI_PV_TAG,
		WEI_PV,
		ERROR_SV_TAG,
		ERROR_SV,
		ERROR_PV_TAG,
		ERROR_PV,
		CASE_UNIT_TAG,
		CASE_UNIT,
		REV_PASS_TAG,
		REV_PASS,
		WEI_SKIP_TAG,
		WEI_SKIP,
		PACK_CNT_TAG,
		PACK_CNT,
		WEI_SV_CNT_TAG,
		WEI_SV_CNT,
		WEI_CNT_TAG,
		WEI_CNT,
		IN_WATER_TYPE, --2025.10.23
		REG_DM,
		UPD_DM,
		ACT_TYPE
	--FROM IFM705_Master_TMP (NOLOCK)
	FROM IFM705_Master (NOLOCK)
	WHERE 1 = 1
	AND Inboundid_ApiAutoCreate = @InboundId


END


/*

SELECT * FROM IFM705_Master_TMP (NOLOCK)
SELECT * FROM IFM705_Master (NOLOCK)

SELECT * FROM AutoNumbering WITH(NOLOCK)

*/

/*
--div_cd			string		사업장코드
--plant_cd			string		공장코드
----auto_no			string		자동채번번호(매핑SEQ)
--auto_no			int			자동채번번호(매핑SEQ) --2025.09.18 (yyyddd)
--order_no			string		작업지시번호(W/O)
--wc_cd				string		작업장코드
--line_cd			string		라인정보
--proc_cd			string		공정정보
--plan_seq			string		배치번호
----ecp_cd			string		설비코드
--eqp_cd			string		설비코드 --2025.09.18
--lot_no			string		LOT번호
--start_dm			datetime	시작시간
--end_dm			datetime	완료시간
--pack_lot_no		string		포장LOTNO
--pack_dm			datetime	포장최종완료시간
--start_wei_tag		string		시작중량 TAG
--start_wei			numeric		시작중량
--end_wei_tag		string		완료중량 TAG
--end_wei			numeric		완료중량(총중량)
--net_wei_tag		string		실중량 TAG
--net_wei			numeric		실중량(중량차, 배출중량)
--settime_val_tag	string		시간설정값 TAG
--settime_val		int			시간설정값
--pbtk_type_tag		string		프리베어탱크 배출구분 TAG
--pbtk_type			string		프리베어탱크 배출구분
--wei_sv_tag		string		계량설정값 TAG
--wei_sv			numeric		계량설정값(RHK충진)
--wei_pv_tag		string		계량값 TAG
--wei_pv			numeric		계량값(RHK충진)
--error_sv_tag		string		오차설정값 TAG
--error_sv			numeric		오차설정값(RHK충진)
--error_pv_tag		string		오차값 TAG
--error_pv			numeric		오차값(RHK충진)
--case_unit_tag		string		용기단수 TAG
----case_unit			numeric		용기단수(최대 4단)(RHK충진)
--case_unit			int			용기단수(최대 4단)(RHK충진)
--rev_pass_tag		string		반전PASS TAG
--rev_pass			string		반전PASS(RHK반전)
--wei_skip_tag		string		중량SKIP TAG
--wei_skip			string		중량SKIP(로드셀측정여부)(RHK반전)
--pack_cnt_tag		string		포장회차 TAG
--pack_cnt			int			포장회차
--wei_sv_cnt_tag	string		계량설정회차 TAG
--wei_sv_cnt		int			계량설정회차(코팅 계량)
--wei_cnt_tag		string		계량회차 TAG
--wei_cnt			int			계량회차(코팅 계량)
--in_water_type		string		투입수구분 --2025.10.23
*/
