-- Tạo bảng để lưu log thay đổi job (Tùy chọn)
-- Chạy script này trong database MySQL của bạn nếu muốn lưu log

CREATE TABLE IF NOT EXISTS `job_change_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_id` varchar(50) NOT NULL,
  `old_job` varchar(50) NOT NULL,
  `old_grade` int(11) NOT NULL,
  `new_job` varchar(50) NOT NULL,
  `new_grade` int(11) NOT NULL,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizen_id` (`citizen_id`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
