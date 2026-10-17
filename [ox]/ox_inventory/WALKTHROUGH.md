# TỔNG HỢP TỐI ƯU HÓA DATABASE & HIỆU NĂNG CHO OX_INVENTORY (200+ PLAYERS)

Tài liệu này lưu trữ chi tiết các thay đổi mã nguồn, nguyên lý hoạt động và hướng dẫn cấu hình chuẩn cho máy chủ FiveM đông người (200+ online đồng thời) mà không làm quá tải cơ sở dữ liệu và không làm hỏng logic gốc.

---

## 1. Các Thay Đổi Mã Nguồn Đã Thực Hiện

### A. Triệt tiêu quét toàn bộ Database khi Server khởi động
- **File:** `modules/items/server.lua`
- **Vấn đề trước đây:** Hàm `db.updateItemDegradeMeta` quét toàn bộ bảng `players` và toàn bộ bảng `ox_inventory` (hàng chục ngàn tài khoản) lúc server vừa bật, gây nghẽn MariaDB và đơ CPU máy chủ.
- **Đã xử lý:** Gỡ bỏ tác vụ quét toàn bộ DB lúc server start. Resource khởi động ngay lập tức trong vài mili-giây.

### B. Chuyển sang cơ chế Lazy Loading cho Metadata Degrade
- **File:** `modules/bridge/qbx/server.lua`
- **Đã xử lý:** Cập nhật metadata degrade trực tiếp trong bộ nhớ RAM khi người chơi đăng nhập (`setupPlayer`), không gửi query thừa xuống cơ sở dữ liệu.

### C. Chuẩn hóa Khóa & Chỉ mục cho Kho Chung (Shared Stashes)
- **File:** `modules/mysql/server.lua`
- **Vấn đề trước đây:** Trong MySQL/MariaDB, `NULL != NULL`. Nếu `owner` là `NULL`, `UNIQUE KEY (owner, name)` mất tác dụng và `UPSERT_STASH` sẽ tạo dòng mới gây duplicate/dupe đồ ở kho chung.
- **Đã xử lý:** 
  - Định nghĩa schema bảng `ox_inventory` với `owner VARCHAR(60) NOT NULL DEFAULT ''`.
  - Tự động chuẩn hóa dữ liệu `owner` NULL thành `''` (chuỗi rỗng).
  - Bổ sung `KEY idx_name (name)` để tăng tốc độ truy vấn kho chung lên $O(1)$.

### D. Chia Chunk cho Batch Stash Saving
- **File:** `modules/mysql/server.lua`
- **Đã xử lý:** Khi có nhiều kho chung và rương đồ cần lưu trong 1 chu kỳ auto-save, hệ thống chia nhỏ thành các chunk tối đa 50 stashes mỗi query `INSERT ... ON DUPLICATE KEY UPDATE` để tránh vượt quá `max_allowed_packet` và tránh lock bảng dài.

---

## 2. Cấu Hình Khuyến Nghị Cho `server.cfg`

Thêm các dòng sau vào file `server.cfg` của máy chủ:

```cfg
# Bật gộp nhiều stash vào 1 câu lệnh SQL duy nhất khi lưu
setr inventory:bulkstashsave true

# Tăng thời gian lưu cache của kho xe / rương trong RAM lên 15 phút (giảm tải query SELECT)
set inventory:cleartime 15

# Tự động dọn dẹp các stash rác không dùng sau 6 tháng
set inventory:clearstashes "6 MONTH"

# Giảm log I/O console
set inventory:loglevel 1

# Tối ưu chuỗi kết nối oxmysql (chỉnh sửa user, pass, database tương ứng)
set mysql_connection_string "mysql://root:password@127.0.0.1/qbox?charset=utf8mb4&connectionLimit=25"
```

---

## 3. Cấu Hình Tối Ưu Cho MariaDB (`my.ini`) - Máy Chủ 64GB RAM

Đường dẫn file gốc: `C:\Program Files\MariaDB 12.3\data\my.ini`

```ini
[mysqld]
datadir=C:/Program Files/MariaDB 12.3/data
port=3306

# --- TỐI ƯU HÓA HIỆU NĂNG CHO FIVEM 200+ PLAYERS ---
# Tăng tốc độ ghi DB gấp 5-10 lần (Cực kỳ quan trọng cho FiveM)
# Đổi từ 1 sang 2 giúp ghi vào buffer RAM thay vì bắt ổ cứng ghi ngay lập tức
innodb_flush_log_at_trx_commit=2

# Bộ đệm dữ liệu trên RAM (Buffer Pool) - Dành cho máy chủ 64GB RAM (28GB RAM cho MariaDB)
innodb_buffer_pool_size=28G
innodb_buffer_pool_instances=8

# Bộ đệm log giao dịch
innodb_log_buffer_size=128M

# Tối ưu đọc/ghi cho ổ cứng SSD / NVMe
innodb_io_capacity=1000
innodb_io_capacity_max=2000

# Giới hạn kết nối và kích thước gói tin (tránh lỗi Lost Connection / Packet Too Large)
max_connections=300
max_allowed_packet=128M

# Tối ưu Cache Threads và Tables
thread_cache_size=32
table_open_cache=2048
table_definition_cache=2048

# Tắt DNS lookup để tăng tốc kết nối client cục bộ/mạng
skip-name-resolve=1

feedback=ON

[client]
port=3306
plugin-dir=C:\Program Files\MariaDB 12.3/lib/plugin
```

> **Lưu ý sau khi sửa `my.ini`:** Mở PowerShell (Admin) và chạy lệnh:
> ```powershell
> net stop MariaDB
> net start MariaDB
> ```
