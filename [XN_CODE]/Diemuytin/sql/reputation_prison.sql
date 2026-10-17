-- SQL Table cho hệ thống tù liên bang
CREATE TABLE IF NOT EXISTS `reputation_prison` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `prison_time` int(11) NOT NULL DEFAULT 0, -- Thời gian tù còn lại (giây)
    `prison_reason` varchar(255) DEFAULT 'Uy tín thấp', -- Lý do bị tù
    `jailed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Thời gian bị tù
    `released_at` timestamp NULL DEFAULT NULL, -- Thời gian được thả
    `is_active` tinyint(1) DEFAULT 1, -- Có đang bị tù không
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Index để tối ưu hóa query
CREATE INDEX `idx_citizenid_active` ON `reputation_prison` (`citizenid`, `is_active`);
CREATE INDEX `idx_is_active` ON `reputation_prison` (`is_active`);
