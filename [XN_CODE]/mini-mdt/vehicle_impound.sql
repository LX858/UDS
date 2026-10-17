-- ==================== VEHICLE IMPOUND TABLE ====================
-- Bảng lưu trữ lịch sử xe bị tạm giam

CREATE TABLE IF NOT EXISTS `mini_mdt_vehicle_impound` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `officer_citizenid` VARCHAR(50) NOT NULL,
    `officer_name` VARCHAR(255) NOT NULL,
    `officer_pid` INT(11) DEFAULT 0,
    `owner_citizenid` VARCHAR(50) NOT NULL,
    `owner_name` VARCHAR(255) NOT NULL,
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

-- Event tự động xóa dữ liệu cũ hơn 30 ngày
CREATE EVENT IF NOT EXISTS `evt_cleanup_vehicle_impound`
ON SCHEDULE EVERY 1 DAY
DO
    DELETE FROM `mini_mdt_vehicle_impound` 
    WHERE `impound_date` < DATE_SUB(NOW(), INTERVAL 30 DAY);
