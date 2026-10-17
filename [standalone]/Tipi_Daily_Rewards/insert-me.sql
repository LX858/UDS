
CREATE TABLE IF NOT EXISTS `tipi_daily_rewards` (
  `citizenid` varchar(50) NOT NULL,
  `usual` longtext NOT NULL DEFAULT '{}',
  `collected` longtext NOT NULL DEFAULT '{}',
  `daily_online` longtext NOT NULL DEFAULT '{}',
  `month_assignments` longtext NOT NULL DEFAULT '{}',
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `tipi_daily_catalog` (
  `catalog_key` varchar(32) NOT NULL,
  `payload` longtext NOT NULL,
  `updated_by` varchar(64) DEFAULT NULL,
  `updated_at` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`catalog_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
