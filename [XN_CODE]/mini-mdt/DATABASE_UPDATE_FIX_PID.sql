-- ==========================================
-- FIX: Sửa lỗi cấu trúc bảng mini_mdt_vehicle_impound
-- Script AN TOÀN - Chỉ thêm cột chưa có, bỏ qua cột đã tồn tại
-- ==========================================

-- HƯỚNG DẪN: 
-- 1. Kiểm tra cột nào còn thiếu bằng lệnh:
--    SHOW COLUMNS FROM mini_mdt_vehicle_impound;
-- 
-- 2. Chạy TỪNG câu lệnh ALTER TABLE bên dưới
--    (Bỏ qua câu lệnh nào báo lỗi "Duplicate column name")

-- Thêm officer_citizenid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_citizenid VARCHAR(50) DEFAULT "" AFTER id';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_citizenid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm officer_name
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_name VARCHAR(255) DEFAULT "Unknown" AFTER officer_citizenid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_name');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm officer_pid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_pid INT(11) DEFAULT 0 AFTER officer_name';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_pid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_citizenid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_citizenid VARCHAR(50) DEFAULT "" AFTER officer_pid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_citizenid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_name
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_name VARCHAR(255) DEFAULT "Unknown" AFTER owner_citizenid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_name');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_pid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_pid INT(11) DEFAULT 0 AFTER owner_name';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_pid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm notes
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN notes TEXT DEFAULT NULL AFTER fine_amount';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'notes');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm duration_until
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN duration_until DATETIME DEFAULT NULL AFTER notes';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'duration_until');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm impound_date
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN impound_date DATETIME DEFAULT CURRENT_TIMESTAMP AFTER released_at';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'impound_date');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT 1');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Cập nhật PID cho dữ liệu cũ (nếu có)
-- Script này sẽ tự động lấy PID từ bảng players dựa trên citizenid

-- Cập nhật officer_pid cho dữ liệu cũ
UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.officer_citizenid = p.citizenid
SET vi.officer_pid = p.pid
WHERE (vi.officer_pid = 0 OR vi.officer_pid IS NULL) AND vi.officer_citizenid != '';

-- Cập nhật owner_pid cho dữ liệu cũ
UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.owner_citizenid = p.citizenid
SET vi.owner_pid = p.pid
WHERE (vi.owner_pid = 0 OR vi.owner_pid IS NULL) AND vi.owner_citizenid != '';

-- Hoàn tất!
-- Bây giờ restart resource mini-mdt để áp dụng code mới
-- Lệnh: restart mini-mdt
