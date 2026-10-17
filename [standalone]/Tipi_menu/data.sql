-- =============================================================================
-- Tipi_menu — Database schema đầy đủ
-- Chạy file này MỘT LẦN trên database server FiveM (HeidiSQL / phpMyAdmin)
-- Resource KHÔNG tự import file này khi start — bạn phải chạy thủ công.
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. prime_ticket
--    Lưu thời gian Prime Ticket còn lại (giây) theo citizenid
--    Dùng bởi: server/impl/main.impl.lua (mua Prime, đếm ngược)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prime_ticket` (
  `identifier` VARCHAR(255) NOT NULL COMMENT 'citizenid người chơi (QBX)',
  `time` INT(11) NOT NULL DEFAULT 0 COMMENT 'Thời gian Prime còn lại (giây)',
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 2. giftcodes
--    Mã quà tặng / giftcode
--    Dùng bởi: server/utils.lua, server/impl/giftcode.impl.lua
--
--    type     : item | currency | vehicle | bundle | clothing
--    remaining: -1 = không giới hạn lượt, >= 1 = số lượt còn lại
--    redeems  : JSON array citizenid đã đổi, vd: ["ABC123","DEF456"]
--    rewards  : JSON bundle, vd: [{"type":"item","name":"bread","count":5}]
--    hwid_strict: 1 = chặn 1 HWID / 1 lượt (code 1 lần dùng)
--    expires_at: NULL = không hết hạn
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `giftcodes` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(50) NOT NULL COMMENT 'Mã giftcode (PK)',
  `type` VARCHAR(50) NOT NULL COMMENT 'item | currency | vehicle | bundle',
  `name` VARCHAR(50) NOT NULL COMMENT 'Tên item / model xe / label bundle',
  `count` INT(11) NOT NULL DEFAULT 0 COMMENT 'Số lượng (item/currency)',
  `rewards` LONGTEXT NULL DEFAULT NULL COMMENT 'JSON phần thưởng bundle',
  `min_level` INT(11) NOT NULL DEFAULT 0 COMMENT 'Cấp tối thiểu để đổi (0 = không yêu cầu)',
  `redeems` LONGTEXT NOT NULL DEFAULT '[]' COMMENT 'JSON danh sách citizenid đã đổi',
  `remaining` INT(11) NOT NULL DEFAULT 0 COMMENT '-1 = vô hạn, >=1 = lượt còn lại',
  `hwid_strict` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = bật chống abuse HWID (code 1 lượt)',
  `expires_at` DATETIME NULL DEFAULT NULL COMMENT 'Thời điểm hết hạn (NULL = vĩnh viễn)',
  PRIMARY KEY (`code`),
  KEY `idx_id` (`id`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_remaining` (`remaining`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 3. giftcode_hwid_tracking
--    Log HWID khi đổi giftcode (chống abuse nhiều tài khoản cùng máy)
--    Dùng bởi: server/impl/giftcode.impl.lua
--    (Resource cũng tự CREATE nếu thiếu, nhưng nên có sẵn trong DB)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `giftcode_hwid_tracking` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `hwid` VARCHAR(255) NOT NULL COMMENT 'Hardware token người chơi',
  `citizenid` VARCHAR(50) NOT NULL COMMENT 'Citizenid đã đổi code',
  `pid` INT(11) DEFAULT NULL COMMENT 'Player ID server (txAdmin)',
  `code` VARCHAR(100) NOT NULL COMMENT 'Mã giftcode đã đổi',
  `player_name` VARCHAR(100) DEFAULT NULL,
  `license` VARCHAR(100) DEFAULT NULL,
  `discord` VARCHAR(100) DEFAULT NULL,
  `ip` VARCHAR(50) DEFAULT NULL,
  `redeemed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hwid` (`hwid`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_pid` (`pid`),
  KEY `idx_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- 4. event_cards
--    Cấu hình card sự kiện (label, ảnh, nền, thể lệ, action...)
--    Dùng bởi: server/impl/EventRules.impl.lua
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `event_cards` (
  `card_key` VARCHAR(64) NOT NULL,
  `label` VARCHAR(128) NOT NULL DEFAULT '',
  `description` VARCHAR(512) NOT NULL DEFAULT '',
  `event_time` VARCHAR(128) NOT NULL DEFAULT '',
  `image_url` VARCHAR(512) NOT NULL DEFAULT '',
  `background_url` VARCHAR(512) NOT NULL DEFAULT '',
  `rules_content` TEXT NOT NULL,
  `action` VARCHAR(64) NOT NULL DEFAULT '',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `show_join_button` TINYINT(1) NOT NULL DEFAULT 0,
  `join_export` VARCHAR(128) NOT NULL DEFAULT '',
  `sort_order` INT(11) NOT NULL DEFAULT 0,
  `updated_by` VARCHAR(64) DEFAULT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`card_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

