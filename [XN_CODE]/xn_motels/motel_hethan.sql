-- =============================================
-- Bảng lưu đồ bị tịch thu khi hết hạn thuê trọ
-- Chạy file này trong phpMyAdmin hoặc HeidiSQL
-- =============================================

CREATE TABLE IF NOT EXISTS `motel_hethan` (
    `id`             int          NOT NULL AUTO_INCREMENT,
    `identifier`     varchar(64)  NOT NULL COMMENT 'citizenid của người thuê',
    `citizenid`      varchar(64)  DEFAULT NULL,
    `pid`            varchar(32)  DEFAULT NULL COMMENT 'Player ID số trong game',
    `motel`          varchar(64)  DEFAULT NULL COMMENT 'Tên motel (vd: vinwood_motels)',
    `room`           varchar(16)  DEFAULT NULL COMMENT 'Số phòng',
    `items`          longtext     DEFAULT NULL COMMENT 'JSON toàn bộ items kèm metadata',
    `confiscated_at` int          DEFAULT 0    COMMENT 'Unix timestamp lúc tịch thu',
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
