-- SQL Fix: Xóa plate khỏi cột mods trong tất cả records
-- Chạy script này để fix dữ liệu cũ bị lưu plate trong mods

-- Cách 1: Update từng record bằng JSON_REMOVE (MySQL 5.7+)
UPDATE job_vehicles 
SET mods = JSON_REMOVE(mods, '$.plate')
WHERE mods IS NOT NULL 
  AND mods != '{}' 
  AND mods != 'null'
  AND JSON_CONTAINS_PATH(mods, 'one', '$.plate');

-- Kiểm tra kết quả
SELECT id, plate, 
       JSON_EXTRACT(mods, '$.plate') as mods_plate,
       JSON_EXTRACT(mods, '$.bodyHealth') as mods_body,
       JSON_EXTRACT(mods, '$.engineHealth') as mods_engine
FROM job_vehicles 
WHERE mods IS NOT NULL AND mods != '{}';
