CREATE TABLE IF NOT EXISTS `player_jobs_activity` (
  `id` int UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) COLLATE utf8mb4_unicode_ci,
  `job` varchar(255) NOT NULL,
  `last_checkin` int NOT NULL,
  `last_checkout` int NULL DEFAULT NULL,
  FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `id` (`id` DESC) USING BTREE,
  INDEX `last_checkout` (`last_checkout` ASC) USING BTREE,
  INDEX `citizenid_job` (`citizenid`, `job`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `player_job_cooldowns` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(50) NOT NULL,
  `job` VARCHAR(50) NOT NULL,
  `fire_type` VARCHAR(20) NOT NULL,
  `reason` TEXT NULL,
  `fired_by` VARCHAR(50) NOT NULL,
  `fired_by_name` VARCHAR(100) NULL,
  `expire_time` INT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `citizenid_expire` (`citizenid`, `expire_time`)
) ENGINE = InnoDB AUTO_INCREMENT = 1 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci;