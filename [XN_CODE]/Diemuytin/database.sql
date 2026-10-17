-- File này dành cho việc setup database nếu cần thiết
-- Hiện tại hệ thống sử dụng metadata của qbx_core nên không cần database riêng

-- =================================================================================
-- THÔNG TIN VỀ METADATA SYSTEM:
-- =================================================================================
-- Hệ thống TỰ ĐỘNG tạo metadata 'reputation' cho người chơi khi:
-- 1. Người chơi load lần đầu (QBCore:Server:PlayerLoaded event)
-- 2. Backup khi join server (playerJoining event)
-- 3. Khi gọi hàm getPlayerReputation() và chưa có metadata
--
-- Metadata được lưu trong bảng `players` của qbx_core:
-- Column: metadata -> JSON object -> reputation: [số điểm]
-- Ví dụ: {"reputation": 50, "hunger": 100, "thirst": 100, ...}
-- =================================================================================

-- Nếu muốn lưu log lịch sử điểm uy tín, có thể tạo bảng như sau:
/*
CREATE TABLE IF NOT EXISTS `reputation_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `old_reputation` int(11) NOT NULL DEFAULT 50,
  `new_reputation` int(11) NOT NULL DEFAULT 50,
  `change_amount` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  `location` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
*/

-- Lệnh SQL để kiểm tra metadata của tất cả người chơi:
/*
SELECT 
    citizenid, 
    JSON_EXTRACT(metadata, '$.reputation') as reputation_points,
    metadata
FROM players 
WHERE JSON_EXTRACT(metadata, '$.reputation') IS NOT NULL
ORDER BY JSON_EXTRACT(metadata, '$.reputation') DESC;
*/

-- Lệnh SQL để reset điểm uy tín của một người chơi cụ thể:
/*
UPDATE players 
SET metadata = JSON_SET(metadata, '$.reputation', 50) 
WHERE citizenid = 'YOUR_CITIZEN_ID_HERE';
*/
