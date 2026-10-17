-- Tạo bảng logs cho stash (tùy chọn)
CREATE TABLE IF NOT EXISTS `xn_stash_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `stash_id` varchar(100) NOT NULL,
  `action` enum('open','close','take','put') NOT NULL,
  `item_name` varchar(100) DEFAULT NULL,
  `item_count` int(11) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `stash_id` (`stash_id`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
