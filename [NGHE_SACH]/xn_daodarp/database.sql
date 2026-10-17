-- SQL file for future database features
-- This is optional and can be used for logging mining activities

CREATE TABLE IF NOT EXISTS `xn_mining_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `rock_location` varchar(100) NOT NULL,
  `mined_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reward_item` varchar(50) NOT NULL,
  `reward_amount` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for tracking drill durability (optional)
CREATE TABLE IF NOT EXISTS `xn_drill_durability` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `item_slot` int(11) NOT NULL,
  `durability` int(11) NOT NULL DEFAULT 100,
  `last_used` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_slot` (`citizenid`, `item_slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
