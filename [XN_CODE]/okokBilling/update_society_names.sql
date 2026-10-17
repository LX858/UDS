-- =====================================================
-- Script chuẩn hóa society_name trong bảng okokBilling
-- Chuyển tất cả các tên society về job.name trong config
-- =====================================================

-- Backup trước khi update (optional)
-- CREATE TABLE okokBilling_backup AS SELECT * FROM okokBilling;

-- 1. Cảnh sát - chuyển về 'police'
UPDATE okokBilling 
SET society_name = 'police' 
WHERE society_name IN ('Cảnh Sát', 'Sở Cảnh Sát', 'Cáº£nh SÃ¡t', 'LSPD', 'Police')
   OR society_name LIKE '%Cảnh Sát%'
   OR society_name LIKE '%LSPD%';

-- 2. Bệnh viện/EMS - chuyển về 'ambulance'
UPDATE okokBilling 
SET society_name = 'ambulance' 
WHERE society_name IN ('Bác sĩ', 'Bệnh viện', 'BÃ¡c sÄ©', 'Bá»‡nh viá»‡n', 'EMS')
   OR society_name LIKE '%Bác sĩ%'
   OR society_name LIKE '%Bệnh viện%'
   OR society_name LIKE '%EMS%';

-- 3. Sửa xe/Garage - chuyển về 'mechanic'
UPDATE okokBilling 
SET society_name = 'mechanic' 
WHERE society_name IN ('Sửa Xe', 'Sá»­a Xe', 'Garage', 'Mechanic')
   OR society_name LIKE '%Sửa Xe%'
   OR society_name LIKE '%Garage%';

-- 4. Đỗ xe - chuyển về 'doxe'
UPDATE okokBilling 
SET society_name = 'doxe' 
WHERE society_name LIKE '%Đỗ Xe%'
   OR society_name LIKE '%Parking%'
   OR society_name LIKE '%Ä\u0090á»%';

-- 5. Car Dealer - chuyển về 'cardealer'
UPDATE okokBilling 
SET society_name = 'cardealer' 
WHERE society_name IN ('Car Dealer', 'cardealer')
   OR society_name LIKE '%Car Dealer%'
   OR society_name LIKE '%Đại Lý Xe%'
   OR society_name LIKE '%Ä\u0090á»\u0091i LÃ½%';

-- 6. Nhà hàng - chuyển về 'nhahang'
UPDATE okokBilling 
SET society_name = 'nhahang' 
WHERE society_name LIKE '%Nhà Hàng%'
   OR society_name LIKE '%Restaurant%'
   OR society_name LIKE '%NhÃ  HÃ ng%';

-- 7. Bar - chuyển về 'bar'
UPDATE okokBilling 
SET society_name = 'bar' 
WHERE society_name LIKE '%Bar%'
   OR society_name LIKE '%QuÃ¡n Bar%';

-- 8. Quán nước - chuyển về 'quannuoc'
UPDATE okokBilling 
SET society_name = 'quannuoc' 
WHERE society_name LIKE '%Quán Nước%'
   OR society_name LIKE '%Cafe%'
   OR society_name LIKE '%QuÃ¡n Ná»%';

-- 9. Tòa thị chính - chuyển về 'toathichinh'
UPDATE okokBilling 
SET society_name = 'toathichinh' 
WHERE society_name LIKE '%Tòa Thị Chính%'
   OR society_name LIKE '%City Hall%'
   OR society_name LIKE '%TÃ²a Thá»%';

-- =====================================================
-- Kiểm tra kết quả sau khi update
-- =====================================================
SELECT society_name, COUNT(*) as total 
FROM okokBilling 
GROUP BY society_name 
ORDER BY total DESC;
