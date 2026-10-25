# VX Runtime Monitor

Giám sát metadata của event/export Lua **server**, cùng vòng đời player và entity của FXServer. Resource thu thập viết bằng Node.js; mở dashboard **ngay trong VPS** tại `http://localhost:32190/`. HTTP chỉ bind loopback (`127.0.0.1`), không mở ra IP public. Không ghi payload event/export, license hoặc IP của player.

## Triển khai trên server này

1. Dừng FXServer trên máy chạy artifact. Bộ cài `patch/install.ps1` mặc định nhắm `C:\Users\Administrator\Desktop\UNS\antifact\citizen\scripting\lua\scheduler.lua`; dùng `-TargetPath` nếu chuyển artifact. Chạy bằng PowerShell 7 trên máy đó. Bộ cài chấp nhận hai SHA256 gốc đã kiểm tra: `A533B4C61A28A144ACB3C04BFC5DF7EA19193CBC2FED266A0F7FF5AFC176805C` và `1CCAF7DBF8BD05E838B289D0DA677EFCD8E0A4DA5ABEF0CA6A9FFFDDD6FD632D`. Bản thứ hai chỉ khác bản đầu ở ba dòng chú thích. Bộ cài lưu backup và trạng thái cài đặt; nếu hash khác, phải kiểm tra bản artifact mới rồi truyền `-ApprovedSourceHash <SHA256>`. Bộ cài sẽ từ chối cấu trúc không khớp anchor. Chạy lại bộ cài là thao tác an toàn nếu file chưa đổi.
2. Giữ `vx_runtime_monitor.private.cfg` trong thư mục chứa `server.cfg` và nạp bằng `exec vx_runtime_monitor.private.cfg` trước `ensure vx_runtime_monitor`. Đặt `set vx_monitor_host 127.0.0.1`, `set vx_monitor_port 32190`, `set vx_monitor_scheduler_path` trỏ đúng file artifact và `set vx_monitor_token` tối thiểu 32 ký tự. Không dùng `setr` cho token.
3. Khởi động FXServer. Trong trình duyệt **trên VPS**, mở `http://localhost:32190/` và nhập token lấy trong `vx_runtime_monitor.private.cfg`. Token chỉ nằm trong bộ nhớ của tab; tải lại trang sẽ phải nhập lại. Không cần tạo quy tắc firewall hay mở cổng ra Internet cho dashboard.

Khi artifact cập nhật, kiểm tra `scheduler.lua` mới, tính SHA256 và chạy `install.ps1 -ApprovedSourceHash <SHA256>`; nếu cấu trúc khác các anchor đã kiểm tra, script dừng và không sửa file. `patch/uninstall.ps1` phục hồi đúng backup nếu bản đang cài chưa bị thay đổi. Sau cài/gỡ patch phải **khởi động lại toàn bộ FXServer** vì runtime đã nạp `scheduler.lua` cũ không đổi trong bộ nhớ.

Máy phát triển hiện tại không có thư mục `C:\Users\Administrator`; bản patch đã áp nhầm vào `X:\UDSFxServer\server\citizen\scripting\lua\scheduler.lua` trước đó đã được hoàn nguyên đúng hash gốc. Artifact thật tại đường dẫn trên chưa được sửa; cần chạy bộ cài tại máy chứa nó. Nếu `server.cfg`/resource trên máy đó khác bản trong `X:\UDSFxServer`, chuyển các thay đổi cấu hình và resource sang máy đó trước khi khởi động.

Với bản artifact hash `1CCAF7DB...` bạn đã gửi, hãy chép `patch/install.ps1` mới sang resource trên máy đó rồi chạy lại `./install.ps1` sau khi dừng FXServer; không cần `-ApprovedSourceHash`.

## Dữ liệu và giới hạn

Bản tối ưu 25/10/2026 cần cập nhật cả collector lẫn scheduler hook rồi restart toàn FXServer. Quy trình theo nhóm, kiểm thử dữ liệu và đo A/B nằm trong `tools/performance/README.md` ở root resources. Hook cũ không có chế độ tổng hợp/off đầy đủ.

- Mặc định `light`: gom theo event/export/resource/phase/status mỗi giây, tối đa 512 nhóm/resource. `count` là số sự kiện, `payloadBytes` là tổng bytes, `wallMs` là max của nhóm; không giữ ID cá nhân trong aggregate. Thống kê top tính theo count, còn danh sách records hiển thị các dòng tổng hợp.
- Console/ACE: `vx_monitor_detail 60` bật chi tiết 60 giây (tối đa 300), tự về light; `vx_monitor_mode light` hoặc `vx_monitor_mode off` đổi chế độ. Hook nhận thay đổi trong khoảng một giây. Off bỏ tạo record và đóng gói ở hook, bỏ intake/log lifecycle; dashboard và map player/entity vẫn có chi phí riêng.

- Hook quan sát `AddEventHandler`, `RemoveEventHandler`, `RegisterNetEvent`, handler nhận event, `TriggerEvent`, `TriggerClientEvent`, `TriggerLatentClientEvent`, và export Lua khai báo qua manifest hoặc `exports(...)`. Event nội bộ `__cfx_export_*` và event gửi lô của monitor được bỏ qua để tránh log trùng/lặp.
- Mỗi bản ghi có thời gian, loại/bước, tên, resource, player ID phiên nếu xác định được, kích thước payload, thời gian thực tế của handler/export và trạng thái. `wallMs` bao gồm thời gian `Wait`/await; dùng profiler của FiveM để đo CPU riêng.
- Player và entity được snapshot khi resource bắt đầu. Entity có type/model/net ID/owner/resource tạo khi native trả về; nếu native không có thông tin, trường tương ứng là `null`.
- Event/export phát sinh hoàn toàn trong JS hoặc C# không có trace lời gọi. Các sự kiện vòng đời player/entity vẫn được bắt ở server. Log chỉ bắt đầu sau khi monitor chạy.
- Trong detail, mỗi Lua runtime đệm tối đa 4.096 bản ghi, gửi lô sau tối đa 200 ms hoặc khi đạt 256 bản ghi; light flush mỗi giây, heartbeat khi nhàn mỗi 5 giây. Collector nhận qua queue giới hạn, xử lý tối đa 128 dòng/lượt, ghi tối đa 250 dòng/lượt và đệm tối đa 50.000 dòng. Light tổng hợp giữ count thay vì lưu riêng từng event; quá tải/lỗi đĩa báo số sự kiện bị mất theo trọng số count. `/health` thêm `collectionMode` và `inputQueue`.
- Log JSONL nằm ở `logs/YYYY-MM-DD/HH-NNN.jsonl`. Xoay khi đổi giờ hoặc đạt 128 MB; giữ tối đa 24 giờ hoặc 2 GB. Dashboard tra cứu gần đây từ bộ nhớ 10.000 bản ghi; nút **Xem log lưu** tìm trong file theo bộ lọc và phân trang tối đa 200 bản ghi/lần.
- Trang đầu hiển thị Top event/export theo 5 phút, 1 giờ hoặc 24 giờ. Mỗi `TriggerClientEvent`/`TriggerLatentClientEvent` là một lượt; gửi `-1` là một lượt broadcast. Event nội bộ, handler, export `call` và `invoke` được đếm riêng. Bấm tên để xem theo resource và ID đích/người gửi. Thống kê chỉ tính bản ghi đã ghi thành công vào JSONL; lượt mất không được suy đoán.
- Cửa sổ 5 phút/1 giờ được gom theo phút và dựng lại từ JSONL khi resource khởi động. Khoảng thời gian thực tế trả trong API có thể bắt đầu ở đầu phút. Thống kê 24 giờ quét log bất đồng bộ, cache 60 giây; khi đang quét UI hiện trạng thái chờ. Tối đa 5.000 nhóm tên/resource cho mỗi cửa sổ; phần vượt gộp vào **Khác** và đánh dấu kết quả chưa đủ. Khi log bị cắt bởi giới hạn lưu trữ, API trả thời điểm sớm nhất còn dữ liệu và cờ `partial`.
- **Log chi tiết** giữ bộ lọc và bản ghi gốc. Mặc định UI ẩn `__cfx_internal:*`, `receive`, các bước đăng ký và `export/invoke`; bấm **Hiện tất cả** để điều tra. Thẻ mất bản ghi tách số agent báo ở lô đầu khỏi số tăng sau đó, queue và disk.

## API đọc

`GET /health`, `/summary`, `/stats`, `/records`, `/players`, `/entities` yêu cầu Bearer token. `/stats` nhận `window=5m|1h|24h`, `view=client|local|handled|exports`, `search` (tìm tên/resource) và `name` (phân bố chính xác một tên). Kết quả có `from`, `to`, `availableFrom`, `retainedFrom`, `total`, `broadcast`, `targeted`, `top` tối đa 50, `partial`, `partialReasons`, `selected`. `/records` nhận `kind`, `phase`, `resource`, `targetResource`, `name`, `playerSessionId`, `entityNetId`, `from`, `to`, `page`, `limit`, `history=1`, `clean=1`. `/entities` nhận `type`, `resource`, `page`, `limit`. Không có API ghi hay thực thi event/export.

## Xác minh

Đợt tối ưu này cần chép `server.js`, `store.js`, **`stats.js`**, thư mục `web` và bộ `patch` sang VPS; giữ token và bind `127.0.0.1:32190`. Dừng FXServer, chạy lại installer trên artifact đúng host với install-state/backup đã có, rồi khởi động toàn FXServer. Chạy kiểm tra tĩnh từ thư mục resource: `node --check server.js`, `node --check store.js`, `node --check stats.js`, `node --check web/app.js`, `node --test tests/store.test.js tests/api.test.js tests/stats.test.js`. Trên máy có Chrome, chạy thêm `node tests/ui-browser.js` để kiểm tra đăng nhập, bảng, chi tiết ID và trạng thái chờ 24 giờ trong trình duyệt thật. Bộ cài có thể kiểm tra trên bản sao `scheduler.lua` bằng `-TargetPath`; Lua parser thường không hiểu literal hash CfxLua nên chỉ thay literal đó trong bản sao dùng cho kiểm tra cú pháp, không thay artifact.

Sau restart thực tế, kiểm tra `/health`: `schedulerHookPresent=true`, `freshAgents>0`, `status=ok`. Dùng fixture trong `tests/fixture` để thử event nội bộ, nhiều handler, handler `Wait`, export, lỗi có chủ đích, event gửi client và restart resource. Tiếp theo thử người chơi vào/rời, tạo/xóa entity, log xoay, từ chối kết nối không từ loopback, token sai và so sánh profiler trước/sau dưới tải đại diện. Các kiểm tra Node/PowerShell không chứng minh hành vi FXServer hoặc nhiều người chơi.
