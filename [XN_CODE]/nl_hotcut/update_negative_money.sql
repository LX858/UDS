-- Thêm cột negative_money_clear vào bảng communityservice
-- Chạy SQL này để cập nhật database

ALTER TABLE `communityservice` 
ADD COLUMN `negative_money_clear` TINYINT(1) DEFAULT 0 COMMENT 'Đánh dấu án phạt do tiền âm để tự động set tiền về 0 khi hoàn thành';
