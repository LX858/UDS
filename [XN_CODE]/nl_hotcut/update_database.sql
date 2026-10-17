-- File này để update database hiện tại, chạy nếu bảng communityservice đã tồn tại
-- và chưa có cột sentence_time

USE `essentialmode`;

-- Thêm cột sentence_time nếu chưa có
ALTER TABLE communityservice 
ADD COLUMN IF NOT EXISTS sentence_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Update tất cả records hiện tại để có thời gian
UPDATE communityservice 
SET sentence_time = CURRENT_TIMESTAMP 
WHERE sentence_time IS NULL;
