

CREATE TABLE `blacklist` (
  `id` int(11) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `blacklister` varchar(100) NOT NULL,
  `time` bigint(20) NOT NULL DEFAULT 0,
  `reason` longtext DEFAULT NULL,
  `job` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `blacklist`
  ADD PRIMARY KEY (`id`);


ALTER TABLE `blacklist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
COMMIT;
