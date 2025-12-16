declare @time datetime = '2025-12-10 08:20'

SELECT a.insert_dt, A.START_DM, A.END_DM,a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%계량%' 
  and a.line_cd = '13G02c'
  AND A.insert_dt >= @time
  --AND A.EQP_CD = 'LFG01A-02C-LIW-0801'
ORDER BY a.InboundId_ApiAutoCreate ASC 



SELECT a.insert_dt, A.START_DM, A.END_DM,a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%혼합%' 
  and a.line_cd = '13G02c'
  AND A.insert_dt >= @time
  --AND A.EQP_CD = 'LFG01A-02C-LIW-0801'
ORDER BY a.InboundId_ApiAutoCreate ASC 



SELECT a.insert_dt, A.START_DM, A.END_DM
, a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%RK%' 
  and a.line_cd = '13G02c'
  AND A.insert_dt >= @time
  --AND A.EQP_CD = 'LFG01A-02C-LIW-0801'
ORDER BY a.InboundId_ApiAutoCreate ASC 



 /*
SELECT *FROM PD_MDM_RESULT_MASTER A WITH (NOLOCK) 
WHERE A.EDATE IS NULL 

UPDATE A SET A.EDATE = GETDATE() FROM PD_RESULT A WITH (NOLOCK) 
WHERE A.EDATE IS NULL AND A.PROC_CD = 'AI'


SELECT *FROM PD_USEM_MAT_TEMP 
SELECT *FROM PD_USEM_MAT_TEMP_MASTER 

*/