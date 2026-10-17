CREATE TABLE IF NOT EXISTS `xn_adminitem_limits` (
    `item` VARCHAR(50) NOT NULL,
    `limit_val` INT NOT NULL DEFAULT 100,
    PRIMARY KEY (`item`)
);

CREATE TABLE IF NOT EXISTS `xn_adminitem_usage` (
    `license` VARCHAR(60) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `count` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`license`, `item`)
);
