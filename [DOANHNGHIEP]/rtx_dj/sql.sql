CREATE TABLE `djlocations` (
  `id` int(11) NOT NULL,
  `creatoridentifier` varchar(500) COLLATE utf8mb4_bin NOT NULL,
  `locationid` int(11) NOT NULL,
  `coords` varchar(500) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `maxdistance` int(11) NOT NULL,
  `permissions` longtext COLLATE utf8mb4_bin NOT NULL,
  `lights` longtext COLLATE utf8mb4_bin NOT NULL,
  `smoke` longtext COLLATE utf8mb4_bin NOT NULL,
  `lasers` longtext COLLATE utf8mb4_bin NOT NULL,
  `particles` longtext COLLATE utf8mb4_bin NOT NULL,
  `linear` varchar(255) COLLATE utf8mb4_bin NOT NULL DEFAULT 'linear'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


ALTER TABLE `djlocations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `creatoridentifier` (`creatoridentifier`(191)),
  ADD KEY `locationid` (`locationid`);

ALTER TABLE `djlocations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1;
COMMIT;