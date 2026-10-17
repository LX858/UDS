-- ================================================
-- OKOKBILLING - OPTIMIZATION INDEX
-- ================================================
-- Tạo index để tối ưu hóa hiệu suất query hóa đơn
-- Chạy câu lệnh này trong phpMyAdmin hoặc MySQL client
-- ================================================

-- Index 1: Tối ưu cho hàm checkTimeLeft() - Tìm hóa đơn quá hạn
-- Query: WHERE status = 'unpaid' AND limit_pay_date IS NOT NULL
CREATE INDEX IF NOT EXISTS idx_billing_status_limit 
ON okokBilling(status, limit_pay_date);

-- Index 2: Tối ưu khi lấy hóa đơn của người chơi
-- Query: WHERE receiver_identifier = ? ORDER BY status, id DESC
CREATE INDEX IF NOT EXISTS idx_billing_receiver_status 
ON okokBilling(receiver_identifier, status, id);

-- Index 3: Tối ưu khi lấy hóa đơn của công ty
-- Query: WHERE society_name = ? ORDER BY id DESC
CREATE INDEX IF NOT EXISTS idx_billing_society_id 
ON okokBilling(society_name, id);

-- ================================================
-- THÔNG TIN BỔ SUNG:
-- ================================================
-- Index 1: Giúp tăng tốc việc tìm hóa đơn cần thanh toán tự động (checkTimeLeft)
-- Index 2: Composite index giúp tăng tốc cả WHERE và ORDER BY cho hóa đơn cá nhân
-- Index 3: Composite index giúp tăng tốc cả WHERE và ORDER BY cho hóa đơn công ty
--
-- LƯU Ý:
-- - Chạy các câu lệnh này trong database của bạn
-- - Nếu index đã tồn tại, MySQL sẽ bỏ qua (do có IF NOT EXISTS)
-- - Sau khi tạo index, hiệu suất query sẽ cải thiện 10-100 lần tùy vào kích thước dữ liệu
-- - Không cần restart server, index hoạt động ngay lập tức
-- ================================================
