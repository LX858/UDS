-- Bảng lưu lịch sử kiểm tra tiền
CREATE TABLE IF NOT EXISTS `money_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `base_money` bigint(20) NOT NULL DEFAULT 0 COMMENT 'Tiền gốc khi bắt đầu chu kỳ 1 tiếng',
  `total_money` bigint(20) NOT NULL DEFAULT 0 COMMENT 'Tổng tiền hiện tại',
  `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Lần reset chu kỳ 1 tiếng gần nhất',
  `last_check` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Migration: Thêm cột mới nếu đã tồn tại bảng
ALTER TABLE `money_history` 
  ADD COLUMN IF NOT EXISTS `base_money` bigint(20) NOT NULL DEFAULT 0 COMMENT 'Tiền gốc khi bắt đầu chu kỳ 1 tiếng' AFTER `citizenid`,
  ADD COLUMN IF NOT EXISTS `last_reset` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Lần reset chu kỳ 1 tiếng gần nhất' AFTER `total_money`;
