-- Apply after 20260923_payment_ledger.sql, before starting the updated resource.
ALTER TABLE `lr_trucker_payments`
  MODIFY `kind` enum('reward','rental_overage','rental_fee') NOT NULL;

CREATE TABLE IF NOT EXISTS `lr_trucker_rental_leases` (
  `citizen_id` varchar(64) NOT NULL,
  `rental_id` varchar(64) NOT NULL,
  `rental_key` varchar(32) NOT NULL,
  `model` varchar(32) NOT NULL,
  `plate` varchar(15) NOT NULL,
  `fee` int unsigned NOT NULL,
  `started_at` int unsigned NOT NULL,
  `expires_at` int unsigned NOT NULL,
  `assessed_overage` int unsigned NOT NULL DEFAULT 0,
  `status` enum('pending','active','returning') NOT NULL DEFAULT 'pending',
  PRIMARY KEY (`citizen_id`),
  UNIQUE KEY `unique_trucker_lease_id` (`rental_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_rental_assessments` (
  `settlement_id` varchar(64) NOT NULL,
  `rental_id` varchar(64) NOT NULL,
  `cumulative_due` int unsigned NOT NULL,
  `gross_reward` int unsigned NOT NULL,
  `net_reward` int unsigned NOT NULL,
  `bank_due` int unsigned NOT NULL,
  `committed` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`settlement_id`),
  KEY `idx_trucker_assessment_lease` (`rental_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
