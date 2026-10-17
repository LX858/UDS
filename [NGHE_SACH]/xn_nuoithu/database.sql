-- Bảng lưu thông tin nâng cấp của người chơi
CREATE TABLE IF NOT EXISTS `xn_nuoithu_upgrades` (
  `citizenid` varchar(50) NOT NULL,
  `luck_level` int(11) NOT NULL DEFAULT 0,
  `time_level` int(11) NOT NULL DEFAULT 0,
  `capacity_level` int(11) NOT NULL DEFAULT 0,
  `skill_points` int(11) NOT NULL DEFAULT 0,
  `overall_level` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
