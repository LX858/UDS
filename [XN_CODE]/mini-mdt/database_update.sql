-- ==========================================
-- MINI-MDT DATABASE UPDATE - VEHICLE IMPOUND SYSTEM
-- Chạy file này để cập nhật database cho hệ thống giam xe
-- Chú ý: Script này an toàn, sẽ kiểm tra trước khi thêm cột/table
-- Version: 2.0 - Đã bao gồm fix PID và tất cả cột cần thiết
-- ==========================================

-- ==========================================
-- 0. TẠO TABLE mini_mdt_vehicle_impound (nếu chưa có)
-- Bảng MỚI với đầy đủ cột cần thiết
-- ==========================================

CREATE TABLE IF NOT EXISTS `mini_mdt_vehicle_impound` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `officer_citizenid` VARCHAR(50) NOT NULL DEFAULT '',
  `officer_name` VARCHAR(255) NOT NULL DEFAULT 'Unknown',
  `officer_pid` INT(11) DEFAULT 0,
  `owner_citizenid` VARCHAR(50) NOT NULL DEFAULT '',
  `owner_name` VARCHAR(255) NOT NULL DEFAULT 'Unknown',
  `owner_pid` INT(11) DEFAULT 0,
  `vehicle_plate` VARCHAR(20) NOT NULL,
  `vehicle_model` VARCHAR(100) DEFAULT NULL,
  `offence` VARCHAR(255) DEFAULT NULL,
  `fine_amount` INT(11) DEFAULT 0 COMMENT 'Số tiền phạt',
  `notes` TEXT DEFAULT NULL,
  `duration_until` DATETIME DEFAULT NULL,
  `status` TINYINT(2) DEFAULT 2 COMMENT '1=đã lấy, 2=đang giam, 3=cần mở khóa',
  `released_at` DATETIME DEFAULT NULL,
  `impound_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_officer_pid` (`officer_pid`),
  INDEX `idx_owner_pid` (`owner_pid`),
  INDEX `idx_vehicle_plate` (`vehicle_plate`),
  INDEX `idx_status` (`status`),
  INDEX `idx_impound_date` (`impound_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- 0.1. CẬP NHẬT TABLE CŨ (nếu bảng đã tồn tại)
-- Thêm các cột còn thiếu vào bảng cũ
-- ==========================================

-- Thêm officer_citizenid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_citizenid VARCHAR(50) DEFAULT "" AFTER id';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_citizenid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ officer_citizenid exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm officer_name
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_name VARCHAR(255) DEFAULT "Unknown" AFTER officer_citizenid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_name');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ officer_name exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm officer_pid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN officer_pid INT(11) DEFAULT 0 AFTER officer_name';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'officer_pid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ officer_pid exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_citizenid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_citizenid VARCHAR(50) DEFAULT "" AFTER officer_pid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_citizenid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ owner_citizenid exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_name
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_name VARCHAR(255) DEFAULT "Unknown" AFTER owner_citizenid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_name');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ owner_name exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm owner_pid
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN owner_pid INT(11) DEFAULT 0 AFTER owner_name';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'owner_pid');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ owner_pid exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm notes
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN notes TEXT DEFAULT NULL AFTER fine_amount';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'notes');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ notes exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm duration_until
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN duration_until DATETIME DEFAULT NULL AFTER notes';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'duration_until');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ duration_until exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm impound_date
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound ADD COLUMN impound_date DATETIME DEFAULT CURRENT_TIMESTAMP';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'impound_date');
PREPARE stmt FROM IF(@check = 0, @query, 'SELECT "✓ impound_date exists" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Cập nhật PID cho dữ liệu cũ từ bảng players
UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.officer_citizenid = p.citizenid
SET vi.officer_pid = p.pid
WHERE (vi.officer_pid = 0 OR vi.officer_pid IS NULL) AND vi.officer_citizenid != '';

UPDATE `mini_mdt_vehicle_impound` vi
JOIN `players` p ON vi.owner_citizenid = p.citizenid
SET vi.owner_pid = p.pid
WHERE (vi.owner_pid = 0 OR vi.owner_pid IS NULL) AND vi.owner_citizenid != '';

SELECT '✓ Đã cập nhật PID cho dữ liệu cũ' AS Info;

-- ==========================================
-- 1. CẬP NHẬT TABLE mini_mdt_charges_template
-- Thêm charge_type và impound_duration
-- ==========================================

-- Kiểm tra và thêm cột charge_type
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'mini_mdt_charges_template' 
  AND COLUMN_NAME = 'charge_type';

SET @query = IF(@col_exists = 0, 
    'ALTER TABLE `mini_mdt_charges_template` ADD COLUMN `charge_type` ENUM(''criminal'', ''vehicle_impound'') NOT NULL DEFAULT ''criminal'' AFTER `charge_name`',
    'SELECT "✓ Column charge_type already exists" AS Info');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Kiểm tra và thêm cột impound_duration
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'mini_mdt_charges_template' 
  AND COLUMN_NAME = 'impound_duration';

SET @query = IF(@col_exists = 0, 
    'ALTER TABLE `mini_mdt_charges_template` ADD COLUMN `impound_duration` INT NOT NULL DEFAULT 0 COMMENT ''Thời gian giam xe (phút) - chỉ dùng cho vehicle_impound'' AFTER `jail_time_max`',
    'SELECT "✓ Column impound_duration already exists" AS Info');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Kiểm tra và thêm index cho charge_type
SET @index_exists = 0;
SELECT COUNT(*) INTO @index_exists 
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'mini_mdt_charges_template' 
  AND INDEX_NAME = 'idx_charge_type';

SET @query = IF(@index_exists = 0, 
    'ALTER TABLE `mini_mdt_charges_template` ADD INDEX `idx_charge_type` (`charge_type`)',
    'SELECT "✓ Index idx_charge_type already exists" AS Info');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================
-- 2. CẬP NHẬT TABLE mini_mdt_vehicle_impound
-- Thêm fine_amount và sửa status type
-- ==========================================

-- Kiểm tra và thêm cột fine_amount
SET @col_exists = 0;
SELECT COUNT(*) INTO @col_exists 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
  AND COLUMN_NAME = 'fine_amount';

SET @query = IF(@col_exists = 0, 
    'ALTER TABLE `mini_mdt_vehicle_impound` ADD COLUMN `fine_amount` INT(11) DEFAULT 0 COMMENT ''Số tiền phạt'' AFTER `offence`',
    'SELECT "✓ Column fine_amount already exists" AS Info');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Sửa type cột status từ TINYINT(1) sang TINYINT(2) để tránh convert sang boolean
SET @table_exists = 0;
SELECT COUNT(*) INTO @table_exists 
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'mini_mdt_vehicle_impound';

SET @query = IF(@table_exists > 0, 
    'ALTER TABLE `mini_mdt_vehicle_impound` MODIFY COLUMN `status` TINYINT(2) DEFAULT 2 COMMENT ''1=đã lấy, 2=đang giam, 3=cần mở khóa''',
    'SELECT "✓ Table mini_mdt_vehicle_impound will be created above" AS Info');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================
-- 3. XÓA CÁC CỘT CŨ KHÔNG DÙNG (nếu có)
-- ==========================================

-- Xóa cột citizenid cũ (đã thay bằng owner_citizenid)
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound DROP COLUMN citizenid';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'citizenid');
PREPARE stmt FROM IF(@check > 0, @query, 'SELECT "✓ citizenid already removed" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Xóa cột impounded_by cũ (đã thay bằng officer_citizenid)
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound DROP COLUMN impounded_by';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'impounded_by');
PREPARE stmt FROM IF(@check > 0, @query, 'SELECT "✓ impounded_by already removed" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Xóa cột impounded_at cũ (đã thay bằng impound_date)
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound DROP COLUMN impounded_at';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'impounded_at');
PREPARE stmt FROM IF(@check > 0, @query, 'SELECT "✓ impounded_at already removed" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Xóa cột release_at cũ (đã thay bằng duration_until)
SET @query = 'ALTER TABLE mini_mdt_vehicle_impound DROP COLUMN release_at';
SET @check = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
              WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME = 'mini_mdt_vehicle_impound' 
              AND COLUMN_NAME = 'release_at');
PREPARE stmt FROM IF(@check > 0, @query, 'SELECT "✓ release_at already removed" AS Info');
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ==========================================
-- HOÀN TẤT!
-- ==========================================
-- ✓ Đã tạo/cập nhật bảng mini_mdt_vehicle_impound với đầy đủ cột:
--   - officer_citizenid, officer_name, officer_pid
--   - owner_citizenid, owner_name, owner_pid
--   - vehicle_plate, vehicle_model, offence, fine_amount
--   - notes, duration_until, status, released_at, impound_date
-- ✓ Đã cập nhật bảng mini_mdt_charges_template với charge_type và impound_duration
-- ✓ Đã cập nhật PID cho dữ liệu cũ từ bảng players
-- ✓ Đã xóa các cột cũ không dùng nữa
--
-- Sau khi chạy script này:
-- 1. Restart resource: restart mini-mdt
-- 2. Test tạo mức án giam xe trong MDT (tự tạo trong UI)
-- 3. Test giam xe bằng target system
-- 4. Kiểm tra PID hiển thị đúng trong danh sách xe tạm giam
-- 5. Kiểm tra ngày giam xe hiển thị đúng
-- ==========================================
-- 4. TẠO TABLE LOG TUẦN TRA (mini_mdt_patrol_logs)
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_patrol_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `area_name` VARCHAR(255) NOT NULL,
    `officer_name` VARCHAR(255) NOT NULL,
    `officer_callsign` VARCHAR(50) DEFAULT 'N/A',
    `officer_rank` VARCHAR(100) DEFAULT 'Officer',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_area_name` (`area_name`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

