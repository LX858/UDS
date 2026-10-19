CREATE TABLE IF NOT EXISTS `lr_trucker_vehicle_upgrades` (
  `player_vehicle_id` int NOT NULL,
  `citizen_id` varchar(64) NOT NULL,
  `tier` tinyint unsigned NOT NULL DEFAULT 1,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_vehicle_id`),
  KEY `idx_trucker_upgrade_citizen` (`citizen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_active_vehicles` (
  `player_vehicle_id` int NOT NULL,
  `citizen_id` varchar(64) NOT NULL,
  `mission_id` varchar(64) NOT NULL,
  `original_garage` varchar(64) NOT NULL DEFAULT '',
  `checked_out_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`player_vehicle_id`),
  UNIQUE KEY `unique_trucker_mission_vehicle` (`mission_id`),
  KEY `idx_trucker_active_citizen` (`citizen_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_rentals` (
  `citizen_id` varchar(64) NOT NULL,
  `rental_id` varchar(64) NOT NULL,
  `rental_key` varchar(32) NOT NULL,
  `model` varchar(32) NOT NULL,
  `capacity` tinyint unsigned NOT NULL,
  `reward_multiplier` tinyint unsigned NOT NULL,
  `fee` int unsigned NOT NULL,
  `expires_at` int unsigned NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`citizen_id`),
  UNIQUE KEY `unique_rental_id` (`rental_id`),
  KEY `idx_rental_expiry` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_rental_refunds` (
  `rental_id` varchar(64) NOT NULL,
  `citizen_id` varchar(64) NOT NULL,
  `amount` int unsigned NOT NULL,
  `claimed_at` timestamp NULL DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rental_id`),
  KEY `idx_trucker_refund_citizen` (`citizen_id`, `paid_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_business_orders` (
  `id` varchar(64) NOT NULL,
  `business_id` varchar(64) NOT NULL,
  `business_label` varchar(96) NOT NULL,
  `adapter` enum('stash','fuel') NOT NULL,
  `account_id` varchar(64) NULL DEFAULT NULL,
  `stash_id` varchar(64) NULL DEFAULT NULL,
  `station_location` int NULL DEFAULT NULL,
  `created_by` varchar(64) NOT NULL,
  `status` enum('waiting_stock','available','reserving','in_transit','delivered','cancelled') NOT NULL,
  `escrow_state` enum('held','released','refunded') NOT NULL DEFAULT 'held',
  `cargo_mode` enum('pallets','tanker') NOT NULL,
  `destination_label` varchar(128) NOT NULL,
  `destination_x` decimal(10,4) NOT NULL,
  `destination_y` decimal(10,4) NOT NULL,
  `destination_z` decimal(10,4) NOT NULL,
  `distance_km` decimal(8,2) NOT NULL,
  `package_count` tinyint unsigned NOT NULL,
  `goods_total` int unsigned NOT NULL,
  `delivery_fee` int unsigned NOT NULL,
  `escrow_total` int unsigned NOT NULL,
  `team_id` varchar(64) NULL DEFAULT NULL,
  `mission_id` varchar(64) NULL DEFAULT NULL,
  `version` int unsigned NOT NULL DEFAULT 1,
  `payout_state` enum('pending','paid') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_business_orders_board` (`status`, `created_at`),
  KEY `idx_business_orders_business` (`business_id`, `status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_business_order_lines` (
  `order_id` varchar(64) NOT NULL,
  `line_index` tinyint unsigned NOT NULL,
  `item_id` varchar(64) NOT NULL,
  `item_label` varchar(96) NOT NULL,
  `category` varchar(32) NOT NULL DEFAULT '',
  `quantity` int unsigned NOT NULL,
  `unit_price` int unsigned NOT NULL,
  `subtotal` int unsigned NOT NULL,
  `package_count` tinyint unsigned NOT NULL,
  `destination_amount` int unsigned NOT NULL,
  `destination_unit` enum('item','liter') NOT NULL,
  `destination_item_id` varchar(64) NULL DEFAULT NULL,
  `destination_label` varchar(96) NULL DEFAULT NULL,
  `reservation_id` varchar(96) NULL DEFAULT NULL,
  `reservation_state` enum('none','reserved','settled','released') NOT NULL DEFAULT 'none',
  PRIMARY KEY (`order_id`, `line_index`),
  UNIQUE KEY `unique_business_reservation` (`reservation_id`),
  CONSTRAINT `fk_business_order_line` FOREIGN KEY (`order_id`)
    REFERENCES `lr_trucker_business_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lr_trucker_business_delivery_receipts` (
  `delivery_id` varchar(96) NOT NULL,
  `order_id` varchar(64) NOT NULL,
  `line_index` tinyint unsigned NOT NULL,
  `destination_adapter` enum('stash','fuel') NOT NULL,
  `amount` int unsigned NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`delivery_id`),
  KEY `idx_business_receipt_order` (`order_id`),
  CONSTRAINT `fk_business_receipt_order` FOREIGN KEY (`order_id`)
    REFERENCES `lr_trucker_business_orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
