-- ============================================================
--  xn_farming — INSTALL SQL (chạy 1 lần khi cài lần đầu)
--  MariaDB / MySQL
-- ============================================================

-- ── 1. Bảng cây trồng chính ──────────────────────────────────
CREATE TABLE IF NOT EXISTS `tomato_db` (
  `id`          int(11)      NOT NULL AUTO_INCREMENT,
  `coords`      longtext     DEFAULT NULL,
  `plantgender` int(11)      DEFAULT NULL,
  `water`       int(11)      DEFAULT NULL,
  `fertilizer`  int(11)      DEFAULT NULL,
  `timestamp`   bigint(20)   DEFAULT NULL,
  `owner`       varchar(50)  DEFAULT NULL,
  `zone_id`     int(11)      DEFAULT NULL,
  `crop_type`   varchar(50)  NOT NULL DEFAULT 'rice',
  `health`      int(11)      NOT NULL DEFAULT 100,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 2. Bảng thuê ruộng ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS `farm_rentals` (
  `id`           int(11)     NOT NULL AUTO_INCREMENT,
  `zone_id`      int(11)     NOT NULL,
  `owner`        varchar(50) NOT NULL,
  `start_time`   bigint(20)  NOT NULL,
  `end_time`     bigint(20)  NOT NULL,
  `hours_rented` int(11)     NOT NULL,
  `price_paid`   int(11)     NOT NULL,
  `is_active`    tinyint(1)  DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_zone_active_time` (`zone_id`, `is_active`, `end_time`),
  KEY `idx_owner_active`     (`owner`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 3. Bảng quyền chia sẻ ruộng ─────────────────────────────
CREATE TABLE IF NOT EXISTS `farm_permissions` (
  `id`          int(11)     NOT NULL AUTO_INCREMENT,
  `rental_id`   int(11)     NOT NULL,
  `zone_id`     varchar(50) NOT NULL,
  `owner`       varchar(50) NOT NULL,
  `shared_with` varchar(50) NOT NULL,
  `granted_at`  bigint(20)  NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_permission` (`zone_id`, `owner`, `shared_with`),
  KEY `idx_zone_shared`      (`zone_id`, `shared_with`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. Bảng thuê chó bảo vệ ──────────────────────────────────
CREATE TABLE IF NOT EXISTS `farm_dog_protection` (
  `id`         int(11)     NOT NULL AUTO_INCREMENT,
  `zone_id`    int(11)     NOT NULL,
  `renter_pid` varchar(50) NOT NULL,
  `expires_at` timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `zone_id`    (`zone_id`),
  KEY `expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 5. Bảng log trộm cây ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS `farm_theft_logs` (
  `id`             int(11)     NOT NULL AUTO_INCREMENT,
  `thief_pid`      varchar(50) NOT NULL,
  `target_pid`     varchar(50) NOT NULL,
  `zone_id`        int(11)     NOT NULL,
  `plant_type`     varchar(50) NOT NULL,
  `amount_stolen`  int(11)     NOT NULL DEFAULT 0,
  `success`        tinyint(1)  NOT NULL DEFAULT 0,
  `was_bitten`     tinyint(1)  NOT NULL DEFAULT 0,
  `created_at`     timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `thief_pid`  (`thief_pid`),
  KEY `target_pid` (`target_pid`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
