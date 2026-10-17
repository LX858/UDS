-- -----------------------------------------------------------------------------
-- Migration: thêm cột event_time vào bảng event_cards
--   Dùng khi database đang chạy chưa có cột này (migration tự động chạy khi
--   restart resource Tipi_menu, nhưng có thể chạy tay bằng file này).
--   An toàn chạy nhiều lần: nếu cột đã tồn tại sẽ báo lỗi "Duplicate column",
--   có thể bỏ qua.
-- -----------------------------------------------------------------------------
ALTER TABLE `event_cards`
  ADD COLUMN `event_time` VARCHAR(128) NOT NULL DEFAULT '' AFTER `description`;
