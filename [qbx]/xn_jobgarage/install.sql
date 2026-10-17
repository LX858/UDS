-- SQL Installation for xn_jobgarage
-- Tạo bảng lưu trữ xe công việc của nhân viên

CREATE TABLE IF NOT EXISTS `job_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `job` varchar(50) NOT NULL,
  `garage` varchar(50) NOT NULL,
  `vehicle` varchar(50) NOT NULL COMMENT 'Model name của xe',
  `vehicle_label` varchar(100) DEFAULT NULL COMMENT 'Tên hiển thị của xe',
  `plate` varchar(8) NOT NULL,
  `mods` longtext DEFAULT NULL,
  `body` int(11) DEFAULT 1000,
  `engine` int(11) DEFAULT 1000,
  `fuel` int(11) DEFAULT 100,
  `is_out` tinyint(1) DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_plate` (`plate`),
  KEY `citizenid` (`citizenid`),
  KEY `job_garage` (`job`,`garage`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
