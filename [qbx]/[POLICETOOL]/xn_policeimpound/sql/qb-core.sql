CREATE TABLE police_impound_offence (
    `id` varchar(32) NOT NULL,
    `name` varchar(255) NOT NULL,
    `amount` int(11) DEFAULT 100,
    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO police_impound_offence (`id`, `name`, `amount`) VALUES
('illegal_parking', 'Đỗ xe trái phép', 150),
('abandoned_vehicle', 'Phương tiện bị bỏ lại', 200),
('unregistered_vehicle', 'Phương tiện chưa đăng ký', 300),
('stolen_recovery', 'Thu hồi xe bị đánh cắp', 500),
('obstructing_traffic', 'Cản trở giao thông', 250),
('illegal_mods', 'Độ xe trái phép', 400),
('crime_vehicle', 'Phương tiện dùng trong tội phạm', 1000),
('driver_arrested', 'Tài xế bị bắt giữ', 300),
('evidence_seizure', 'Tịch thu bằng chứng', 500),
('noise_complaint', 'Phàn nàn về tiếng ồn', 100),
('reckless_driving', 'Lái xe ẩu', 350),
('safety_issues', 'Vấn đề an toàn xe', 200),
('dui', 'Lái xe khi say xỉn', 700),
('hit_and_run', 'Liên quan đến tai nạn bỏ trốn', 800);


CREATE TABLE police_impound_status (
    `id` int(1) NOT NULL,
    `name` varchar(255) NOT NULL,
    PRIMARY KEY (`id`)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

INSERT INTO police_impound_status (`id`, `name`) VALUES
(1, 'Đã phát hành'),
(2, 'Đang bị tạm giữ'),
(3, 'Cần mở khóa qua LSPD');

CREATE TABLE police_impound (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `officer` varchar(46) NOT NULL, -- Officer Identifier
    `officer_name` varchar(128) NOT NULL, 
    `status` int(1) DEFAULT 2,
    `duration` timestamp NULL DEFAULT NULL,
    `fine` int(11) DEFAULT 0,
    `offence` varchar(32) NOT NULL,
    `notes` LONGTEXT DEFAULT 'No extra notes',
    `vehicle` LONGTEXT NOT NULL,
    `vehicle_plate` varchar(64) DEFAULT 'Unknown',
    `vehicle_owner` varchar(46) NOT NULL, -- Owner Identifier
    `vehicle_owner_name` varchar(128) DEFAULT 'Unknown', -- Owner Name
    `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
    `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (`id`),
    FOREIGN KEY (`status`) REFERENCES police_impound_status(id),
    FOREIGN KEY (`offence`) REFERENCES police_impound_offence(id)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;