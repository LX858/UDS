
CREATE TABLE IF NOT EXISTS `giftcode_hwid_tracking` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hwid` varchar(255) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `pid` int(11) DEFAULT NULL,
  `code` varchar(100) NOT NULL,
  `player_name` varchar(100) DEFAULT NULL,
  `license` varchar(100) DEFAULT NULL,
  `discord` varchar(100) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `redeemed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_hwid` (`hwid`),
  KEY `idx_citizenid` (`citizenid`),
  KEY `idx_pid` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `giftcodes` ADD COLUMN `hwid_strict` TINYINT(1) NOT NULL DEFAULT 0;

ALTER TABLE `giftcodes` ADD COLUMN `expires_at` DATETIME NULL DEFAULT NULL;
