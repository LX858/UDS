-- Use this if you are installing a new DB/Server (these are the default QB-Management jobs/gangs)

-- Thêm cột conghien và tien_conghien vào bảng players nếu chưa có
ALTER TABLE `players`
    ADD COLUMN IF NOT EXISTS `conghien` INT(11) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `tien_conghien` INT(11) NOT NULL DEFAULT 0;

-- Bảng xn_gang lưu thông tin gang
CREATE TABLE IF NOT EXISTS `xn_gang` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name_gang` VARCHAR(50) NOT NULL,
    `thong_bao` TEXT DEFAULT NULL,
    `cap_do` INT(11) NOT NULL DEFAULT 1,
    `exp` INT(11) NOT NULL DEFAULT 0,
    `so_member` INT(11) NOT NULL DEFAULT 20,
    `diem_chiemdong` INT(11) NOT NULL DEFAULT 0,
    `logo` VARCHAR(255) DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `name_gang` (`name_gang`)
);

-- Bảng xn_qua_cd lưu quà chiếm đóng đã nhận
CREATE TABLE IF NOT EXISTS `xn_qua_cd` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `id_nv` INT(11) NOT NULL DEFAULT 0,
    `name_gang` VARCHAR(50) NOT NULL,
    `diem` INT(11) NOT NULL DEFAULT 0,
    `trang_thai` INT(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
);

-- Bảng xn_gang_requests lưu đơn đăng ký tạo gang mới
CREATE TABLE IF NOT EXISTS `xn_gang_requests` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `char_name` VARCHAR(100) NOT NULL,
    `gang_label` VARCHAR(100) NOT NULL,
    `gang_tag` VARCHAR(20) NOT NULL,
    `description` TEXT NOT NULL,
    `fee` INT(11) NOT NULL DEFAULT 1000000,
    `status` ENUM('pending', 'approved', 'rejected', 'completed', 'refunded') NOT NULL DEFAULT 'pending',
    `gang_name` VARCHAR(50) DEFAULT NULL,
    `admin_name` VARCHAR(100) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `citizenid` (`citizenid`),
    KEY `status` (`status`)
);

-- Bảng xn_gang_inventory lưu trữ tài nguyên tồn kho của từng gang
CREATE TABLE IF NOT EXISTS `xn_gang_inventory` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `gang_name` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `amount` INT(11) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `gang_item` (`gang_name`, `item`),
    KEY `idx_gang_name` (`gang_name`)
);

-- Bảng xn_gang_kick_cooldown lưu thời gian cooldown 3 ngày sau khi bị khai trừ
CREATE TABLE IF NOT EXISTS `xn_gang_kick_cooldown` (
    `citizenid` VARCHAR(50) NOT NULL,
    `gang_name` VARCHAR(50) NOT NULL,
    `expires_at` BIGINT NOT NULL,
    PRIMARY KEY (`citizenid`)
);

-- Bảng xn_gang_welfare_claims lưu lịch sử nhận quà mốc phúc lợi gang
CREATE TABLE IF NOT EXISTS `xn_gang_welfare_claims` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `name_gang` VARCHAR(50) NOT NULL,
    `milestone_id` INT(11) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `claimed_by` VARCHAR(50) NOT NULL,
    `claimed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `gang_milestone` (`name_gang`, `milestone_id`),
    KEY `idx_name_gang` (`name_gang`)
);


