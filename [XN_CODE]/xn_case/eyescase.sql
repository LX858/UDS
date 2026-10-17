
CREATE TABLE IF NOT EXISTS `eyes_case` (
  `identifier` varchar(50) DEFAULT NULL,
  `gold` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO `eyes_case` (`identifier`, `gold`) VALUES
	('steam:1100001348700b7', '0');


CREATE TABLE IF NOT EXISTS `eyes_purchase` (
  `amount` varchar(50) DEFAULT NULL,
  `tebex` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `es_case_special_pity` (
  `citizenid` varchar(50) NOT NULL,
  `case_label` varchar(100) NOT NULL,
  `counter` int(11) NOT NULL DEFAULT 0,
  `threshold` int(11) NOT NULL DEFAULT 50,
  PRIMARY KEY (`citizenid`, `case_label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
