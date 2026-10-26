# XN Ban Management System (React + Vite + txAdmin Style)

Hệ thống quản lý lệnh cấm người chơi (Ban System) toàn diện cho FiveM Qbox / QB-Core / Standalone, hỗ trợ kiểm tra đa định danh khi người chơi kết nối.

---

## 📌 Các tính năng chính

1. **Kiểm tra đa định danh khi kết nối (`playerConnecting`)**:
   - `license` (Rockstar License)
   - `discord` (Discord ID)
   - `gmail` / `email` (Địa chỉ email)
   - `IP` (Địa chỉ IP mạng)
   - **Chỉ cần trùng 1 trong các thông tin trên**, người chơi sẽ bị chặn lại ngay lập tức với thông báo:
     ```text
     ❌ BẠN ĐÃ BỊ CHẶN KẾT NỐI VÀO MÁY CHỦ!

     Bạn đang bị cấm vì lí do: <Lí do ban>

     Mã Cấm: [XXXX-YYYY]
     Người thực hiện: Admin
     Thời điểm cấm: ...
     Thời hạn: Vĩnh viễn / ngày cụ thể
     ```

2. **In-memory Ban Cache**:
   - Tải toàn bộ danh sách ban còn hiệu lực vào RAM server khi khởi động.
   - Kiểm tra `playerConnecting` với độ trễ gần như bằng 0 (O(1)), không làm nghẽn kết nối database khi có đông người chơi truy cập.

3. **Giao diện NUI React Vite chuẩn txAdmin**:
   - Tái hiện 1:1 giao diện Modal như hình ảnh đính kèm:
     - Header `[MÃ-CẤM] Banned Tên Đối Tượng`
     - Sidebar 3 Tab: **Info**, **IDs**, **Revoke**
     - Tab IDs: Phân loại **Player Identifiers** (`license:...`, `discord:...`, `email:...`) và **Hardware IDs / IP** (`ip:...`) kèm nút Copy nhanh.
     - Tab Info: Xem chi tiết lý do, người ban, thời hạn, trạng thái.
     - Tab Revoke: Nhập lý do và bấm xác nhận gỡ cấm.
   - Danh sách tổng thể tất cả các lệnh cấm: Thanh tìm kiếm thông minh, bộ lọc trạng thái Đang cấm / Đã gỡ cấm.
   - Modal Thêm Lệnh Cấm: Hỗ trợ chọn nhanh người chơi đang Online để tự động điền License, Discord, IP, Gmail.

4. **Tích hợp Discord Webhook**:
   - Tự động gửi embed thông báo chi tiết khi Admin tạo lệnh cấm hoặc gỡ cấm.

---

## 🚀 Hướng dẫn Cài Đặt

### 1. Import SQL vào Database:
- Chạy file: `sql/xn_ban.sql` trong HeidiSQL / phpMyAdmin hoặc công cụ quản lý MySQL của bạn.

### 2. Cài đặt & Build UI React Vite:
Mở terminal trong thư mục `web`:
```bash
cd web
npm install
npm run build
```
Sau khi build thành công, thư mục `web/dist` sẽ được tạo và sẵn sàng cho FiveM load NUI.

*(Nếu muốn chạy thử giao diện trên trình duyệt ngoài FiveM để tinh chỉnh thêm, bạn chỉ cần gõ `npm run dev`)*.

### 3. Khởi động Resource trong `server.cfg`:
```cfg
ensure xn_ban
```

---

## 🎮 Lệnh trong game:
- `/banmenu` : Mở giao diện Quản lý cấm (Dành cho Admin).
- Phím `ESC` hoặc lệnh `/closebanui` để đóng giao diện.
