-- Bảng quản lý danh sách cấm xn_bans
CREATE TABLE IF NOT EXISTS `xn_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `ban_id` VARCHAR(32) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Không xác định',
    `license` VARCHAR(100) NULL,
    `discord` VARCHAR(100) NULL,
    `gmail` VARCHAR(150) NULL,
    `ip` VARCHAR(60) NULL,
    `reason` TEXT NOT NULL,
    `banned_by` VARCHAR(100) NOT NULL DEFAULT 'Console / Admin',
    `banned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expire_at` TIMESTAMP NULL DEFAULT NULL,
    `status` TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1: Đang bị cấm, 0: Đã gỡ cấm',
    `revoked_by` VARCHAR(100) NULL,
    `revoked_reason` TEXT NULL,
    `revoked_at` TIMESTAMP NULL DEFAULT NULL,
    INDEX `idx_license` (`license`),
    INDEX `idx_discord` (`discord`),
    INDEX `idx_gmail` (`gmail`),
    INDEX `idx_ip` (`ip`),
    INDEX `idx_ban_id` (`ban_id`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng lưu người chơi từng kết nối (dùng để tìm kiếm người chơi offline khi ban)
CREATE TABLE IF NOT EXISTS `xn_players` (
    `license` VARCHAR(100) NOT NULL PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL DEFAULT 'Không tên',
    `first_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_name` (`name`),
    INDEX `idx_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Mọi discord/gmail từng thấy của 1 người chơi kèm số lần xuất hiện (seen_count lớn nhất = chính xác nhất)
CREATE TABLE IF NOT EXISTS `xn_player_ids` (
    `license` VARCHAR(100) NOT NULL,
    `id_type` VARCHAR(16) NOT NULL,
    `id_value` VARCHAR(150) NOT NULL,
    `seen_count` INT UNSIGNED NOT NULL DEFAULT 1,
    `first_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `last_seen` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`license`, `id_type`, `id_value`),
    INDEX `idx_value` (`id_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
