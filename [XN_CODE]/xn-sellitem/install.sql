-- XN-SELLITEM DATABASE INSTALLATION
-- Tạo bảng lưu trữ cấu hình items

CREATE TABLE IF NOT EXISTS `xn_sellitem_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(50) NOT NULL,
  `item_name` varchar(50) NOT NULL,
  `label` varchar(255) NOT NULL,
  `min_price` int(11) NOT NULL DEFAULT 50,
  `max_price` int(11) NOT NULL DEFAULT 100,
  `random_when_start` tinyint(1) NOT NULL DEFAULT 1,
  `range_change_min` int(11) NOT NULL DEFAULT 1,
  `range_change_max` int(11) NOT NULL DEFAULT 4,
  `amount_to_change` int(11) NOT NULL DEFAULT 50,
  `current_price` int(11) NOT NULL DEFAULT 0,
  `amount_sold` int(11) NOT NULL DEFAULT 0,
  `current_amount` int(11) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_item` (`category`, `item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migration an toàn cho cài đặt cũ (MySQL 8+/MariaDB hỗ trợ IF NOT EXISTS).
ALTER TABLE `xn_sellitem_config`
  ADD COLUMN IF NOT EXISTS `current_amount` int(11) NOT NULL DEFAULT 0 AFTER `amount_sold`;

CREATE TABLE IF NOT EXISTS `xn_sellitem_delivery_reservations` (
  `reservation_id` varchar(64) NOT NULL,
  `owner_resource` varchar(64) NOT NULL,
  `category` varchar(50) NOT NULL,
  `item_name` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`reservation_id`),
  KEY `idx_delivery_item_status` (`category`, `item_name`, `status`),
  KEY `idx_delivery_owner_status` (`owner_resource`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert dữ liệu mẫu từ config.lua
INSERT INTO `xn_sellitem_config` (`category`, `item_name`, `label`, `min_price`, `max_price`, `random_when_start`, `range_change_min`, `range_change_max`, `amount_to_change`) VALUES
-- Hải sản
('fish', 'fish', 'Cá Thu', 70, 90, 1, 1, 4, 50),
('fish', 'anchovy', 'Cá Trích', 50, 70, 1, 1, 4, 50),
('fish', 'smallbluefish', 'Cá Đuối Nhỏ', 70, 90, 1, 1, 4, 40),
('fish', 'bluefish', 'Cá Chim Vây Vàng', 90, 110, 1, 1, 4, 300),
('fish', 'bonitosfish', 'Cá Kiếm Xanh', 110, 130, 1, 1, 4, 250),
('fish', 'garfish', 'Cá Nóc Gai', 130, 150, 1, 1, 4, 200),
('fish', 'perch', 'Cá Hồi Đại Dương', 150, 170, 1, 1, 4, 200),
('fish', 'carettacaretta', 'Cá Ngừ Vây Xanh', 180, 220, 1, 1, 4, 150),
('fish', 'pantfish', 'Cá Mập Trắng Lớn', 230, 270, 1, 1, 4, 100),
('fish', 'sharkfish', 'Cá Chà Bặc', 280, 320, 1, 1, 4, 80),

-- Phế liệu
('phelieu', 'racthaidaphanloai', 'Rác thải phân loại', 100, 200, 1, 1, 4, 50),
('phelieu', 'lachabon', 'Lá Chà Bồn', 350, 450, 1, 1, 4, 50),
('phelieu', 'vodanhong', 'Vỏ đạn hỏng', 50, 100, 1, 1, 4, 50),
('phelieu', 'khuyentaicu', 'Khuyên tai cũ', 150, 200, 1, 1, 4, 50),
('phelieu', 'machdienchay', 'Mạch điện cháy', 100, 200, 1, 1, 4, 50),
('phelieu', 'thuocsung', 'Thuốc súng', 100, 200, 1, 1, 4, 50),

-- Khoáng sản
('mining', 'soi', 'Viên sỏi', 50, 100, 1, 1, 4, 50),
('mining', 'than', 'Than', 100, 150, 1, 1, 4, 50),
('mining', 'sat', 'Sắt', 150, 200, 1, 1, 4, 50),
('mining', 'kimcuong', 'Kim Cương', 250, 300, 1, 1, 4, 50),

-- Nông sản
('traicay', 'coconut', 'Quả dừa', 50, 100, 1, 1, 4, 50),
('traicay', 'orange', 'Quả Cam', 50, 100, 1, 1, 4, 50);

-- Tạo bảng leaderboard theo category
CREATE TABLE IF NOT EXISTS `xn_sellitem_leaderboard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_id` varchar(50) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `category` varchar(50) NOT NULL,
  `points` bigint(20) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_player_category` (`citizen_id`, `category`),
  KEY `idx_category_points` (`category`, `points` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
