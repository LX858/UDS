-- Additive migration. Run before enabling InviteCode. Does not alter players or giftcodes.
CREATE TABLE IF NOT EXISTS tipi_invite_guard (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY
) ENGINE=InnoDB;
INSERT IGNORE INTO tipi_invite_guard (id) VALUES (1);

CREATE TABLE IF NOT EXISTS tipi_invite_codes (
  citizenid VARCHAR(50) NOT NULL PRIMARY KEY,
  code VARCHAR(12) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
  identity_ready TINYINT(1) NOT NULL DEFAULT 0,
  admin_fraud TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipi_invite_fingerprints (
  citizenid VARCHAR(50) NOT NULL,
  kind ENUM('license','token') NOT NULL,
  fingerprint CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  PRIMARY KEY (citizenid, kind, fingerprint),
  KEY identity_lookup (kind, fingerprint, citizenid),
  FOREIGN KEY (citizenid) REFERENCES tipi_invite_codes(citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipi_invite_redemptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  invitee VARCHAR(50) NOT NULL UNIQUE,
  inviter VARCHAR(50) NOT NULL,
  online_seconds BIGINT UNSIGNED NOT NULL DEFAULT 0,
  auto_fraud TINYINT(1) NOT NULL DEFAULT 0,
  qualified_at DATETIME(6) NULL,
  reward_state ENUM('pending','paid','exhausted') NOT NULL DEFAULT 'pending',
  reward_slot INT UNSIGNED NULL,
  redeemed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE KEY owner_slot (inviter, reward_slot),
  KEY owner_status (inviter, qualified_at),
  FOREIGN KEY (invitee) REFERENCES tipi_invite_codes(citizenid),
  FOREIGN KEY (inviter) REFERENCES tipi_invite_codes(citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipi_invite_sessions (
  session_key CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL PRIMARY KEY,
  invitee VARCHAR(50) NOT NULL,
  seconds BIGINT UNSIGNED NOT NULL DEFAULT 0,
  started_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY player_sessions (invitee),
  FOREIGN KEY (invitee) REFERENCES tipi_invite_codes(citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipi_invite_reward_log (
  reward_key VARCHAR(160) NOT NULL PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  amount INT UNSIGNED NOT NULL,
  kind ENUM('invitee','inviter','milestone') NOT NULL,
  batch CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY recipient (citizenid),
  KEY payout_batch (batch),
  FOREIGN KEY (citizenid) REFERENCES tipi_invite_codes(citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tipi_invite_fraud_audit (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  citizenid VARCHAR(50) NOT NULL,
  actor VARCHAR(50) NOT NULL,
  flagged TINYINT(1) NOT NULL,
  reason VARCHAR(512) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  KEY player_audit (citizenid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
