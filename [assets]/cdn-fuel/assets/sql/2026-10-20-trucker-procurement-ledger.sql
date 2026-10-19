-- Additive ledger for trucker procurement; does not update station prices or balances.
CREATE TABLE IF NOT EXISTS `fuel_station_procurement_ledger` (
              `order_id` varchar(64) NOT NULL,
              `location` int NOT NULL,
              `amount` int unsigned NOT NULL,
              `debited_at` timestamp NULL DEFAULT NULL,
              `delivery_id` varchar(96) NULL DEFAULT NULL,
              `refunded_at` timestamp NULL DEFAULT NULL,
              `delivered_at` timestamp NULL DEFAULT NULL,
              `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
              PRIMARY KEY (`order_id`),
              UNIQUE KEY `unique_fuel_procurement_delivery` (`delivery_id`),
              KEY `idx_fuel_procurement_location` (`location`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
