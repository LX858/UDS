CREATE TABLE IF NOT EXISTS `dep_announcements` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `sender_name` VARCHAR(50) NOT NULL,
    `sender_citizenid` VARCHAR(50) NOT NULL,
    `category` VARCHAR(20) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `apply_time` VARCHAR(100) NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
