-- ==========================================
-- MINI MDT - DATABASE SETUP COMPLETE
-- File SQL duy nhất - Import vào database
-- An toàn: Không xóa data cũ, chỉ tạo table nếu chưa có
-- ==========================================

-- ==========================================
-- BẢNG HỒ SƠ VỤ ÁN
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `title` VARCHAR(255) NOT NULL,
    `description` LONGTEXT DEFAULT NULL,
    `handler_officer_id` VARCHAR(50) NOT NULL,
    `handler_officer_name` VARCHAR(255) NOT NULL,
    `handler_officer_rank` VARCHAR(100) DEFAULT NULL,
    `status` VARCHAR(50) DEFAULT 'pending',
    `created_by` VARCHAR(50) NOT NULL,
    `created_by_name` VARCHAR(255) NOT NULL,
    `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_created_by` (`created_by`),
    INDEX `idx_handler` (`handler_officer_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_handler_date` (`handler_officer_id`, `created_date`),
    INDEX `idx_created_date` (`created_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG TỘI PHẠM
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_offenders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `record_id` INT NOT NULL,
    `offender_id` VARCHAR(50) NOT NULL,
    `offender_name` VARCHAR(255) NOT NULL,
    `charge_id` INT NOT NULL,
    `charge_name` VARCHAR(255) NOT NULL,
    `fine_amount` INT NOT NULL DEFAULT 0,
    `jail_time` INT NOT NULL DEFAULT 0,
    `status` VARCHAR(50) DEFAULT 'pending',
    `added_by` VARCHAR(50) NOT NULL,
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`record_id`) REFERENCES `mini_mdt_records`(`id`) ON DELETE CASCADE,
    INDEX `idx_record_id` (`record_id`),
    INDEX `idx_offender_id` (`offender_id`),
    INDEX `idx_offender_record` (`offender_id`, `record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG CẢNH SÁT THAM GIA
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_case_officers` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `record_id` INT NOT NULL,
    `officer_id` VARCHAR(50) NOT NULL,
    `officer_name` VARCHAR(255) NOT NULL,
    `officer_rank` VARCHAR(100) DEFAULT NULL,
    `added_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`record_id`) REFERENCES `mini_mdt_records`(`id`) ON DELETE CASCADE,
    INDEX `idx_record_id` (`record_id`),
    INDEX `idx_officer_id` (`officer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG TIỀN PHẠT
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_fines` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `record_id` INT NOT NULL,
    `offender_id` INT NOT NULL,
    `player_id` VARCHAR(50) NOT NULL,
    `fine_type` VARCHAR(255) NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `jail_time` INT NOT NULL DEFAULT 0,
    `paid` TINYINT(1) DEFAULT 0,
    `paid_date` TIMESTAMP NULL DEFAULT NULL,
    `created_by` VARCHAR(50) NOT NULL,
    `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`record_id`) REFERENCES `mini_mdt_records`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`offender_id`) REFERENCES `mini_mdt_offenders`(`id`) ON DELETE CASCADE,
    INDEX `idx_record_id` (`record_id`),
    INDEX `idx_player_id` (`player_id`),
    INDEX `idx_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG BẰNG CHỨNG
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_evidence` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `record_id` INT NOT NULL,
    `image_url` VARCHAR(500) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `uploaded_by` VARCHAR(50) NOT NULL,
    `uploaded_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`record_id`) REFERENCES `mini_mdt_records`(`id`) ON DELETE CASCADE,
    INDEX `idx_record_id` (`record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG MẪU TỘI DANH
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_charges_template` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `charge_name` VARCHAR(255) NOT NULL,
    `fine_amount_min` INT NOT NULL DEFAULT 0,
    `fine_amount_max` INT NOT NULL DEFAULT 0,
    `jail_time_min` INT NOT NULL DEFAULT 0,
    `jail_time_max` INT NOT NULL DEFAULT 0,
    `created_by` VARCHAR(50) NOT NULL,
    `created_by_name` VARCHAR(255) NOT NULL,
    `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_charge_name` (`charge_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG TẠM GIAM LOGOUT
-- ==========================================
CREATE TABLE IF NOT EXISTS `mini_mdt_offline_prison` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `offender_pid` VARCHAR(50) NOT NULL,
    `offender_name` VARCHAR(255) NOT NULL,
    `punisher_pid` VARCHAR(50) NOT NULL,
    `punisher_name` VARCHAR(255) NOT NULL,
    `punisher_rank` VARCHAR(100) DEFAULT NULL,
    `reason` TEXT NOT NULL,
    `status` VARCHAR(50) DEFAULT 'active',
    `created_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `released_date` TIMESTAMP NULL DEFAULT NULL,
    `released_by` VARCHAR(50) NULL DEFAULT NULL,
    `released_by_name` VARCHAR(255) NULL DEFAULT NULL,
    INDEX `idx_offender_pid` (`offender_pid`),
    INDEX `idx_punisher_pid` (`punisher_pid`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_date` (`created_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- BẢNG LOG TUẦN TRA
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

-- ==========================================
-- CẬP NHẬT STATISTICS (TỐI ƯU)
-- ==========================================
ANALYZE TABLE `mini_mdt_records`;
ANALYZE TABLE `mini_mdt_offenders`;
ANALYZE TABLE `mini_mdt_case_officers`;
ANALYZE TABLE `mini_mdt_charges_template`;
ANALYZE TABLE `mini_mdt_offline_prison`;
ANALYZE TABLE `mini_mdt_patrol_logs`;
