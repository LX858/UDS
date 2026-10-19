ALTER TABLE `xn_sellitem_config`
  ADD COLUMN IF NOT EXISTS `current_amount` int(11) NOT NULL DEFAULT 0 AFTER `amount_sold`;

CREATE TABLE IF NOT EXISTS `xn_sellitem_delivery_reservations` (
  `reservation_id` varchar(64) NOT NULL,
  `owner_resource` varchar(64) NOT NULL,
  `category` varchar(50) NOT NULL,
  `item_name` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL,
  `status` varchar(16) NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`reservation_id`),
  KEY `idx_delivery_item_status` (`category`, `item_name`, `status`),
  KEY `idx_delivery_owner_status` (`owner_resource`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
