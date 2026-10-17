-- SQL Update Livery cho xe đã có
-- Chạy script này để cập nhật defaultMods cho xe cũ

-- POLICE VEHICLES
-- polbuffalo4: modLivery = 2
UPDATE job_vehicles SET mods = '{"modLivery":2}' 
WHERE vehicle = 'polbuffalo4' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- polvstr: modLivery = 2
UPDATE job_vehicles SET mods = '{"modLivery":2}' 
WHERE vehicle = 'polvstr' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- nkscout: modLivery = 0, modSpoilers = 1
UPDATE job_vehicles SET mods = '{"modLivery":0,"modSpoilers":1}' 
WHERE vehicle = 'nkscout' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- poldom: modLivery = 0
UPDATE job_vehicles SET mods = '{"modLivery":0}' 
WHERE vehicle = 'poldom' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- polvigero2: modLivery = 0
UPDATE job_vehicles SET mods = '{"modLivery":0}' 
WHERE vehicle = 'polvigero2' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- polmav: livery = 0 (aircraft)
UPDATE job_vehicles SET mods = '{"livery":0}' 
WHERE vehicle = 'polmav' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- =============================================
-- SCRIPT CẬP NHẬT XE ĐÃ CÓ MODS (giữ nguyên mods cũ, thêm livery)
-- Chỉ chạy nếu muốn THÊM livery vào xe đã có mods
-- =============================================

-- polbuffalo4 - thêm modLivery vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(COALESCE(mods, '{}'), '$.modLivery', 2)
WHERE vehicle = 'polbuffalo4' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- polvstr - thêm modLivery vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(COALESCE(mods, '{}'), '$.modLivery', 2)
WHERE vehicle = 'polvstr' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- nkscout - thêm modLivery và modSpoilers vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(JSON_SET(COALESCE(mods, '{}'), '$.modLivery', 0), '$.modSpoilers', 1)
WHERE vehicle = 'nkscout' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- poldom - thêm modLivery vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(COALESCE(mods, '{}'), '$.modLivery', 0)
WHERE vehicle = 'poldom' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- polvigero2 - thêm modLivery vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(COALESCE(mods, '{}'), '$.modLivery', 0)
WHERE vehicle = 'polvigero2' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- polmav - thêm livery vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(COALESCE(mods, '{}'), '$.livery', 0)
WHERE vehicle = 'polmav' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- amrfreightliner: modFrame = 0, modRoof = 0, modHood = 0, modRightFender = 0, modOrnaments = 4
UPDATE job_vehicles SET mods = '{"modFrame":0,"modRoof":0,"modHood":0,"modRightFender":0,"modOrnaments":4}' 
WHERE vehicle = 'amrfreightliner' AND (mods IS NULL OR mods = '{}' OR mods = 'null');

-- amrfreightliner - thêm mods vào mods hiện có
UPDATE job_vehicles 
SET mods = JSON_SET(JSON_SET(JSON_SET(JSON_SET(JSON_SET(COALESCE(mods, '{}'), '$.modFrame', 0), '$.modRoof', 0), '$.modHood', 0), '$.modRightFender', 0), '$.modOrnaments', 4)
WHERE vehicle = 'amrfreightliner' AND mods IS NOT NULL AND mods != '{}' AND mods != 'null';

-- Kiểm tra kết quả
SELECT vehicle, plate, mods FROM job_vehicles WHERE vehicle = 'amrfreightliner';

