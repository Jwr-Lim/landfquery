


SELECT a.insert_dt, A.START_DM, A.END_DM
, a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%리본%' 
  and a.line_cd = '13G02c'
  AND A.INSERT_DT >= '2025-12-11 13:10:18.813'
  --AND A.EQP_CD = 'LFG01A-02B-PS-0301'
ORDER BY a.insert_dt ASC  


SELECT a.insert_dt, A.START_DM, A.END_DM
, a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%체분리%' 
  and a.line_cd = '13G02c'
  AND A.INSERT_DT >= '2025-12-11 13:10:18.813'
  --AND A.EQP_CD = 'LFG01A-02B-PS-0301'
ORDER BY a.insert_dt ASC  

SELECT a.insert_dt, A.START_DM, A.END_DM, a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a

WHERE a.[CASE] LIKE '%탈철%' 
  and a.line_cd = '13G02c'
  AND A.INSERT_DT >= '2025-12-11 13:10:18.813'
  --AND A.EQP_CD = 'LFG01A-02B-PS-0301'
ORDER BY a.insert_dt ASC  

SELECT a.insert_dt,a.start_dm, a.end_dm,  a.[case], a.eqp_cd, a.* from FLEXAPI_NEW.DBO.IFM705_MASTER a
WHERE a.[CASE] LIKE '%포장%' 
  and a.line_cd = '13G02c'
  AND A.INSERT_DT >= '2025-12-11 12:10:18.813'
  --AND A.EQP_CD = 'LFG01A-02B-PS-0301'
ORDER BY a.insert_dt ASC  


