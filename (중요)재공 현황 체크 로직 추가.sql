-- 재공 현황 체크 로직 추가
-- PD_USEM 에 저장할때 EQP_CD 를 저장해야 되고, 
-- 재공 체크 할때 설비코드를 확인해서 넣어야 된다. 
-- 그렇지.. 이것 때문에 문제가 되는구나. 

SELECT *FROM PD_RESULT A WITH (NOLOCK)
WHERE A.ORDER_NO = 'PD250929011' AND A.PROC_cD = 'RK'

