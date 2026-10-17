-- Bảng dữ liệu phạt offline
CREATE TABLE IF NOT EXISTS `offline_punishment` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `punished_by` varchar(60) DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `punished_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
