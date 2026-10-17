CREATE TABLE IF NOT EXISTS `xn_updates` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `category` VARCHAR(50) NOT NULL DEFAULT 'update',
  `version` VARCHAR(50) NOT NULL DEFAULT 'v1.0',
  `author` VARCHAR(100) NOT NULL DEFAULT 'Admin',
  `date` VARCHAR(50) NOT NULL,
  `content` TEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `xn_updates` (`title`, `category`, `version`, `author`, `date`, `content`) 
SELECT 'Chào mừng tới UNDER STAR ROLEPLAY!', 'update', 'v1.0.0', 'BQL UnderStar', '08/08/2026', 'Chào mừng tất cả cư dân đến với thành phố UnderStar Roleplay!\n\n✨ Hệ thống đã sẵn sàng với nhiều tính năng hấp dẫn:\n• Giao diện Cyan Neon sắc nét, tối ưu hiệu năng tối đa.\n• Hệ thống Paintball, Đua xe, Casino, Bắn súng nảy lửa.\n• Quản lý tài sản, nhà cửa và phương tiện đa dạng.\n\nNhấn nút **ĐÃ ĐỌC** ở phía dưới để vào thành phố trải nghiệm ngay!'
WHERE NOT EXISTS (SELECT * FROM `xn_updates`);
