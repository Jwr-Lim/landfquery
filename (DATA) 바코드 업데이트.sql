begin tran 
DECLARE @LOOP_TABLE table
(
     cnt              int
    ,item_cd          nvarchar(50) 
    ,lot_no           nvarchar(50) 
    ,qty              numeric(18,3)
    ,barcode          nvarchar(50) 
    ,real_barcode     nvarchar(50) 

)

insert into @loop_table 

select row_number() over (PARTITION by bb.lot_no order by bb.barcode) as cnt,
bb.item_cd, bb.lot_no, bb.qty, bb.barcode, ''
from 
(select a.item_cd, a.lot_no from mt_item_out_batch a with (nolock) 
where a.req_dt = '2025-11'
group by a.item_cd, a.lot_no 
) aa 
inner join st_stock_now bb on aa.item_cd  =bb.item_cd and aa.lot_no = bb.lot_no and bb.location_no = '*' and bb.rack_cd <> '*' and bb.barcode <> '*' 
and bb.sl_cd = '3000' and bb.qty > 0 and bb.plant_cd = '1130'


-- 실제 재고와 
-- 현재고 바코드를 매칭한다. 


update aa set aa.real_barcode = bb.barcode from 
@loop_table aa 
inner join 
(select row_number() over (PARTITION by bb.lot_no order by bb.barcode) as cnt,
bb.item_cd, bb.lot_no, bb.qty, bb.barcode 
from 
(select a.item_cd, a.lot_no from mt_item_out_batch a with (nolock) 
where a.req_dt = '2025-11'
group by a.item_cd, a.lot_no 
) aa 
inner join [REAL_MES].flexmes.dbo.st_stock_now bb on aa.item_cd  =bb.item_cd and aa.lot_no = bb.lot_no and bb.location_no = '*' and bb.rack_cd <> '*' and bb.barcode <> '*' 
and bb.sl_cd = '3000' and bb.qty > 0 and bb.plant_cd = '1130'
--order by aa.lot_no, bb.barcode 
) bb on aa.item_cd = bb.item_cd and aa.lot_no = bb.lot_no and aa.cnt = bb.cnt 

update bb set bb.barcode = aa.real_barcode from @loop_table aa 
inner join pallet_master bb on aa.barcode = bb.barcode
where aa.real_barcode <> ''

update bb set bb.barcode = aa.real_barcode from @loop_table aa 
inner join st_item_in bb on aa.item_cd = bb.item_cd and aa.lot_no = bb.lot_no and aa.barcode = bb.barcode and bb.sl_cd = '3000'
where aa.real_barcode <> '' 


select row_number() over (PARTITION by bb.lot_no order by bb.barcode) as cnt,
bb.item_cd, bb.lot_no, bb.qty, bb.barcode, ''
from 
(select a.item_cd, a.lot_no from mt_item_out_batch a with (nolock) 
where a.req_dt = '2025-11'
group by a.item_cd, a.lot_no 
) aa 
inner join st_stock_now bb on aa.item_cd  =bb.item_cd and aa.lot_no = bb.lot_no and bb.location_no = '*' and bb.rack_cd <> '*' and bb.barcode <> '*' 
and bb.sl_cd = '3000' and bb.qty > 0 and bb.plant_cd = '1130'

rollback  
--select *from st_item_in where lot_no = '1113017848' and sl_cd = '3000' and tablenm = 'pallet_master'
/*
begin tran 

update a set a.department = 'LFG01A-01A-TK-1001', a.idx_dt = '2025-11-16', a.idx_seq = 1 from pd_item_in a where a.lot_no = 'ZWN507-2510136-22'
update a set a.department = 'LFG01A-01A-TK-1002', a.idx_dt = '2025-11-16', a.idx_seq = 2 from pd_item_in a where a.lot_no = '1113017845'
update a set a.department = 'LFG01A-01A-TK-0901', a.idx_dt = '2025-11-16', a.idx_seq = 3 from pd_item_in a where a.lot_no = 'GCS-251002-18'

select *from st_stock_now where location_no = '13g01a' and qty > 0

rollback 


SELECT *FROM ST_sTOCK_NOW WHERE LOT_NO = 'ZWN507-2510142-22' AND QTY > 0 AND SL_CD = '3000'

*/