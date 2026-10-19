-- Run before deploying the updated lr_trucker_job resource.
-- Idempotent: existing payment intents and historical order prices are untouched.
-- rental_fee is included here so a fresh install has the same ledger contract as
-- an upgraded install after 20260926_persistent_rental_leases.sql.
CREATE TABLE IF NOT EXISTS `lr_trucker_payments` (
  `mission_id` varchar(64) NOT NULL,
  `citizen_id` varchar(64) NOT NULL,
  `kind` enum('reward','rental_overage','rental_fee') NOT NULL,
  `amount` int unsigned NOT NULL,
  `status` enum('pending','processing','paid') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `claimed_at` timestamp NULL DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`mission_id`, `citizen_id`, `kind`),
  KEY `idx_trucker_payments_pending` (`citizen_id`, `kind`, `status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
