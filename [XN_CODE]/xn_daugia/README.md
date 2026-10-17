# 🏛️ XN_DAUGIA - HỆ THỐNG ĐẤU GIÁ REALTIME FIVEM

Script đấu giá realtime cao cấp dành cho FiveM (QBox / QBCore / ox_inventory / ox_lib).

---

## 🌟 TÍNH NĂNG NỔI BẬT

1. **Khởi Tạo Phiên Đấu Giá (Admin)**:
   - Lệnh `/daugia [giá_khởi_điểm] [tên_gói_thầu]` (Ví dụ: `/daugia 5000000 Siêu Xe Bugatti Chiron`).
   - Lệnh `/huydaugia` huỷ phiên khẩn cấp và tự động hoàn trả tiền cược.

2. **Kích Hoạt Qua Thẻ Đấu Giá (`the_dau_gia`)**:
   - Khi sử dụng item `the_dau_gia`, giao diện Đặt Thầu (Bet UI) hiện đại phong cách Luxury Gold & Dark Glassmorphism sẽ xuất hiện.
   - Hiển thị trực quan: **Giá hiện tại** + **[ID] Họ và tên** người gọi thầu trước đó (hoặc hiển thị "Khởi điểm" nếu là lượt đầu).
   - Danh sách mốc cược nhanh: `$100.000`, `$200.000`, `$300.000` ... `$1.000.000`.
   - Tính toán trực tiếp tổng mức thầu mới trước khi bấm.

3. **Hiển Thị 3D Overhead Realtime Trên Đầu Player**:
   - Khi bấm nút trung tâm **"ĐẶT THẦU"**, UI lập tức đóng lại.
   - Phía trên đầu người chơi xuất hiện 3D Tag động:
     - `Đặt thầu: X.XXX.XXX$`
     - `Đếm ngược: 10s` (kèm thanh progress bar đổi màu theo thời gian thực).
   - Khi có người chơi khác đặt thầu cao hơn, 3D Tag ở người cũ tự động biến mất và chuyển sang người mới với bộ đếm reset về 10s.

4. **Quy Tắc Cooldown 3s & Chống Xung Đột (Race Condition Arbitration)**:
   - Khoá đặt cược trong 3s đầu sau mỗi lượt bid (người tiếp theo chỉ được cược từ giây thứ 7 trở đi).
   - Hệ thống Server Mutex Lock xử lý tức thời khi nhiều người bấm cùng lúc: ưu tiên gói cược cao hơn; nếu bằng nhau về giá và thời gian, tự động loại bỏ lượt chậm hơn bằng nano/milli timestamp và hoàn tiền/thông báo an toàn.

5. **Bảng Vinh Danh Người Thắng & Lịch Sử (Winner Leaderboard)**:
   - Hết 10s không ai vượt giá -> Người cao nhất chiến thắng.
   - Giao diện chuyển sang chế độ hiển thị người chiến thắng cùng bảng xếp hạng lịch sử của tất cả người tham gia.
   - Duy trì hiển thị cho đến khi admin mở phiên mới.

---

## 📦 HƯỚNG DẪN CÀI ĐẶT ITEM

### 1. Dành cho `ox_inventory` (`ox_inventory/data/items.lua`)
Thêm vào file items:
```lua
['the_dau_gia'] = {
    label = 'Thẻ Đấu Giá',
    weight = 100,
    stack = true,
    close = true,
    description = 'Thẻ tham gia đặt thầu trong các phiên đấu giá hoàng gia.',
    client = {
        image = 'the_dau_gia.png',
    }
},
```

### 2. Dành cho `qb-core` (`qb-core/shared/items.lua`)
```lua
['the_dau_gia'] = {
    name = 'the_dau_gia',
    label = 'Thẻ Đấu Giá',
    weight = 100,
    type = 'item',
    image = 'the_dau_gia.png',
    unique = false,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'Thẻ tham gia đặt thầu trong các phiên đấu giá hoàng gia.'
},
```

---

## ⚙️ TÙY CHỈNH TRONG `config.lua`

- `Config.CountdownSeconds = 10`: Thời gian đếm ngược (giây).
- `Config.BidLockSeconds = 3`: Thời gian chờ giữa các lần gọi thầu (giây).
- `Config.PaymentMode = 'on_bid'`: Giữ tiền cược ngay khi bid và tự hoàn trả cho người cũ khi bị vượt giá (hoặc `'on_win'` chỉ trừ tiền khi thắng cuộc).
- `Config.BetSteps`: Tuỳ chỉnh các mốc cược theo ý muốn.
- `Config.DiscordWebhook`: Link webhook Discord ghi lại toàn bộ nhật ký đấu giá.
