# VX Server Profiler

Resource server độc lập, lấy mẫu profiler 350 frame mỗi 30 giây và phân tích trên dashboard `http://127.0.0.1:32191` trong VPS. Không cần hook `scheduler.lua` và không ghi event gameplay.

## Cài đặt

Đặt thư mục `vx_profiler_monitor` vào `resources/[standalone]`. Trong `server.cfg`, chạy cấu hình token trước resource và thêm:

```cfg
exec vx_runtime_monitor.private.cfg
add_ace resource.vx_profiler_monitor command.profiler allow
ensure vx_profiler_monitor
```

Mặc định dashboard dùng `vx_monitor_token` hiện có. Muốn dùng token riêng, đặt `set vx_profiler_token "<chuỗi ngẫu nhiên ít nhất 32 ký tự>"` trong file cấu hình riêng đã `exec` trước `ensure`. Bind mặc định `127.0.0.1:32191`; có thể đặt `vx_profiler_host` thành `127.0.0.1` hoặc `::1`, `vx_profiler_port` thành port khác. Resource không chấp nhận bind IP công cộng.

Khởi động hoặc `restart vx_profiler_monitor`, rồi mở dashboard trong trình duyệt **trên VPS**. Token chỉ gửi qua header Bearer. `GET /profiler/status`, `/profiler/summary?window=5m|1h|24h`, `/profiler/samples?window=...&page=...&limit=...` và `/profiler/trace/:id` đều chỉ đọc và yêu cầu token. Trace được tải bằng nút trong dashboard; token không xuất hiện trong URL.

## Dữ liệu và giới hạn

- Mỗi lần `profiler record 350` ghi 350 mốc `BeginFrame`. Một số artifact dừng ghi ngay đầu frame thứ 350, vì vậy có thể có **349 frame hoàn chỉnh** dùng để tính thời gian. Dashboard luôn ghi riêng số frame đã bắt đầu và số frame tính được.
- P50/P95/P99 của một mẫu tính từ frame hoàn chỉnh; tổng hợp nhiều mẫu dùng bucket 1 ms. `selfMs` của resource trừ thời gian resource con, còn thời gian scope là bao gồm lời gọi con. Đây là thời gian làm việc trong profiler, không phải CPU của toàn máy.
- Thống kê được giữ 24 giờ trong `data/samples`; trace JSON chỉ giữ 20 mẫu gần nhất và tối đa 512 MB trong `data/traces`. File vượt 128 MB không được phân tích. File `data/` đã được gitignore.
- Lượt lấy mẫu trùng lúc profiler được dùng thủ công sẽ bị bỏ. Nếu lượt trước chưa lưu/phân tích xong, lượt kế tiếp cũng bị bỏ. Lỗi lệnh, lưu file, file thiếu hoặc dưới 350 frame hiện trong `/profiler/status` và dashboard; không thay đổi gameplay.

## Kiểm tra khi triển khai

1. Chạy `profiler status` trong console để chắc không có lượt ghi thủ công trước lúc resource bắt đầu.
2. Sau khi restart, xem `/profiler/status` qua dashboard: trạng thái chuyển `Đang ghi` → `Đang lưu` → `Đang phân tích` → `Đang chờ`, số mẫu tăng, không có `lastError`.
3. Tải trace mới nhất, đối chiếu số mốc frame và các scope với file JSON. Thử token sai, localhost và kết nối ngoài localhost.
4. So sánh hitch và thời gian tick trên VPS trước/sau khi bật resource dưới cùng mức tải người chơi. Kiểm thử Node tĩnh không thay thế được phép đo này.
