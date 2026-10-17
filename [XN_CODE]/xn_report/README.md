# 🚨 XN_REPORT - HỆ THỐNG GỬI BÁO CÁO KÈM VIDEO HD BẰNG CHỨNG (FIVEMANAGE)

Resource FiveM cao cấp giúp người chơi gửi report sự cố/vi phạm với tính năng tự động ghi hình video màn hình game HD (không voice), tự động upload lên **FiveManage Cloud CDN** và gửi báo cáo chi tiết đến **Discord Webhook** cùng danh sách người chơi trong bán kính 50m.

---

## 🌟 TÍNH NĂNG CHÍNH

1. **Lệnh mở Menu Report**: `/rp` (hoặc `/report`, `/baocao`).
2. **Giao diện NUI Hiện Đại & Tối Giản**:
   - Thiết kế Dark Theme gọn gàng, hỗ trợ phím tắt ESC.
   - Khi bấm bắt đầu ghi hình, UI thu nhỏ thành mini HUD ở góc dưới màn hình.
3. **Ghi hình Video HD Chuẩn Thời Gian Thực (720p @ 30 FPS)**:
   - Quay trực tiếp từ DirectX backbuffer ở độ phân giải HD 1280x720 với tốc độ 30 FPS.
   - Tích hợp Master Audio Clock đồng bộ thời gian 1:1, ngăn chặn triệt để lỗi tua nhanh của Chromium.
   - Dung lượng siêu nhẹ (~1.8MB cho 10s video), upload CDN cực nhanh trong 1 giây.
4. **Tự Động Upload FiveManage CDN**:
   - Sử dụng API Key FiveManage gửi video trực tiếp lên `https://api.fivemanage.com/api/v3/file`.
5. **Quét Danh Sách Người Chơi Bán Kính 50m**:
   - Thu thập: Server ID, Tên Ingame, CitizenID, Discord ID, Khoảng cách (m), Trạng thái (Lái xe / Đi bộ).
6. **Discord Webhook Tinh Gọn & Đẹp Mắt**:
   - Giao diện Discord Embed tối giản, hiển thị chính xác thông tin quan trọng nhất.
7. **Thông báo In-game cho Ban Quản Trị**:
   - Tự động gửi notify cho các Admin/Staff đang online trong máy chủ.

---

## 📁 CẤU TRÚC THƯ MỤC

```
xn_report/
├── fxmanifest.lua       # Khai báo resource FiveM
├── config.lua           # Cấu hình API FiveManage, Webhook Discord, Bán kính, v.v.
├── README.md            # Hướng dẫn sử dụng
├── client/
│   └── main.lua         # Xử lý client, lệnh /rp, quét bán kính 50m
├── server/
│   └── main.lua         # Xử lý server, lấy thông tin người chơi, gửi Discord Webhook
└── web/
    ├── index.html       # Giao diện HTML
    ├── style.css        # Giao diện CSS Dark Theme
    └── script.js        # Logic quay video HD & upload FiveManage
```

---

## ⚙️ HƯỚNG DẪN CÀI ĐẶT

1. Mở file [config.lua](file:///c:/Users/nghec/Desktop/UnderStar/txData/Qbox/resources/[XN_CODE]/xn_report/config.lua):
   - Điền link Webhook Discord của Admin vào dòng `Config.DiscordWebhook`.
   - Kiểm tra API Key FiveManage `Config.FiveManage.ApiKey`.
2. Thêm vào `server.cfg`:
   ```cfg
   ensure xn_report
   ```
3. Khởi động lại server hoặc gõ lệnh trong txAdmin console:
   ```cmd
   refresh
   ensure xn_report
   ```
4. Vào game và gõ lệnh:
   ```cmd
   /rp
   ```
