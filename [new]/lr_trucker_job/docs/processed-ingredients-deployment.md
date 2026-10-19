# Triển khai nguyên liệu chế biến B2B

Phạm vi: `restaurant_shop` (job `quanan`) và `bar` (job `quannuoc`). Không đổi công thức bar cao cấp hoặc quy đổi dầu.

## File cần triển khai cùng nhau

- `lr_trucker_job`: config, server, generated contracts và web build.
- `ox_inventory/data/items.lua`: bản resource đang chạy; không dùng bản sao `[ox]/data/items.lua`.
- `xn_banhnuoc`: config, manifest, `server/main.lua`, `server/crafting_service.lua`.

## Database hiện có

1. Ngừng nhận đơn mới; hoàn tất tất cả nhiệm vụ B2B và các lần nhập kho/quyết toán đang retry.
2. Dừng Trucker và chế tạo doanh nghiệp trong cửa sổ bảo trì. Backup database và bảo đảm inventory đã lưu.
3. Chạy `migrations/20260913_processed_ingredients.sql` bằng client MySQL/MariaDB hỗ trợ `DELIMITER` trên database đúng server. Không dùng tùy chọn bỏ qua lỗi.
4. Nếu báo `STOP`, không sửa status để vượt qua guard. Khôi phục bản resource cũ và xử lý nhiệm vụ/receipt còn treo trước.
5. Triển khai đồng bộ các resource, reload inventory item definitions trong kỳ bảo trì và khởi động lại doanh nghiệp/Trucker.

Migration có thể chạy lại: chỉ dòng NULL của đơn quán chưa có tài xế được bổ sung mapping. Giá, số lượng, tiền escrow, phí, trạng thái, inventory hiện có và lịch sử không được viết lại. Không chạy migration khi resource còn ghi đơn. Cài mới dùng `install.sql`.

Mapping mới chốt tại thời điểm đặt, trong `Config.BusinessOrders.Items`. `destinationMultiplier` là số nguyên dương, mặc định 1; đơn đã trả tiền không đọc lại config khi giao. Giá/reservation luôn tính theo nguồn thô.

## Nghiệm thu trong game

- Đặt `luami` và `coconut` cho quán ăn: stash nhận `gao` và `dua_soche`; chế tạo bánh rán (1+1 → 3), mochi (3 → 4).
- Đặt `coconut` và `la_che` cho quán nước: stash nhận `dua_soche` và `tra_kho`; nước dừa/trà đá mỗi công thức 1 → 1.
- Kiểm tra nguyên liệu thô cũ vẫn rút được nhưng không chế tạo được; không có output trong túi tài xế.
- Kiểm tra giỏ không đủ tổng trọng lượng/slot bị từ chối trước khi trừ quỹ, và kho đầy khi giao không quyết toán stock.
- Thử hai nhân viên cùng craft, đổi job/off-duty/đi xa sau khi bắt đầu, hủy progress, gửi lặp complete. Rollback giữ nguyên metadata và chỉ hoàn phần thực sự đã trừ; nếu inventory từ chối hoàn, stash bị khóa và retry mỗi 5 giây.
- Với import dở, không hủy để mở lại đơn: tiếp tục quyết toán theo receipt/delivery ID. Restart Trucker sẽ retry các lần nhập dở thay vì hoàn nguyên liệu thô đã biến thành output.
- Thử một đơn dầu, một đơn hệ thống và công thức bar cao cấp để xác nhận hồi quy.

Kiểm thử SQL migration và crash toàn server cần database thử nghiệm và FiveM. Test Lua dùng adapter giả lập không thay thế kiểm thử độ bền lưu inventory trên máy chủ thật; không triển khai khi còn import hoặc rollback dở.
