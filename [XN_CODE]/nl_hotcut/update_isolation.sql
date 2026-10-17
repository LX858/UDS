-- Thêm column isolation_bucket vào bảng communityservice
ALTER TABLE `communityservice` ADD COLUMN `isolation_bucket` INT DEFAULT 0 COMMENT 'Routing bucket nếu bị cách ly (0 = không cách ly, 999 = đang cách ly)';
