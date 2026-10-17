-- Bảng lưu Hardware IDs của người chơi
-- Import file này vào database của bạn

CREATE TABLE IF NOT EXISTS `player_hardware` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `pid` int(11) DEFAULT NULL,
  `license2` varchar(100) NOT NULL,
  `hardware_id` varchar(255) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL COMMENT 'Username',
  `character_name` varchar(100) DEFAULT NULL COMMENT 'Họ và tên IC',
  `discord_id` varchar(50) DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `player_id` int(11) DEFAULT NULL,
  `first_seen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_seen` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `hardware_id` (`hardware_id`),
  KEY `citizenid` (`citizenid`),
  KEY `license2` (`license2`),
  KEY `last_seen` (`last_seen`),
  KEY `pid` (`pid`),
  UNIQUE KEY `unique_license_hardware` (`license2`, `hardware_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Thêm các cột nếu bảng đã tồn tại (cho trường hợp update từ version cũ)
ALTER TABLE `player_hardware` 
  ADD COLUMN IF NOT EXISTS `pid` int(11) DEFAULT NULL AFTER `citizenid`,
  ADD COLUMN IF NOT EXISTS `character_name` varchar(100) DEFAULT NULL COMMENT 'Họ và tên IC' AFTER `player_name`,
  ADD COLUMN IF NOT EXISTS `player_id` int(11) DEFAULT NULL AFTER `ip_address`;
