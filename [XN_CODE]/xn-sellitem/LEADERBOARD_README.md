# XN-SELLITEM LEADERBOARD FEATURE

## Tính năng mới: Bảng xếp hạng theo danh mục

### Mô tả
- Bảng xếp hạng hiển thị top 10 người chơi có số điểm cao nhất trong mỗi danh mục (CategoryNames)
- Mỗi danh mục là 1 tab riêng: fish, phelieu, mining, nuoithu, traicay
- Điểm được tính theo công thức: **1$ bán được = 1 điểm**
- Điểm được cộng dồn theo thời gian thực khi người chơi bán sản phẩm

### Cách sử dụng
1. **Trong Phone App**: Mở phone app của xn-sellitem, bấm vào tab "🏆 Bảng Xếp Hạng"
2. **Chọn danh mục**: Bấm vào các tab danh mục để xem bảng xếp hạng của từng loại sản phẩm
3. **Xem thông tin**: 
   - Top 3 được đánh dấu đặc biệt với huy chương 🥇🥈🥉
   - Hiển thị tên người chơi, citizen ID và số điểm

### Cài đặt

#### 1. Cập nhật Database
Chạy SQL trong file `install.sql` (phần mới được thêm vào):

```sql
CREATE TABLE IF NOT EXISTS `xn_sellitem_leaderboard` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_id` varchar(50) NOT NULL,
  `player_name` varchar(255) NOT NULL,
  `category` varchar(50) NOT NULL,
  `points` bigint(20) NOT NULL DEFAULT 0,
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_player_category` (`citizen_id`, `category`),
  KEY `idx_category_points` (`category`, `points` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### 2. Build NUI Assets
Vào thư mục `web` và chạy lệnh build:

```bash
cd web
pnpm install
pnpm run build
```

Hoặc nếu dùng npm:

```bash
cd web
npm install
npm run build
```

#### 3. Restart Resource
Restart resource `xn-sellitem`:

```
restart xn-sellitem
```

### Các file đã thay đổi

#### Server-side:
- `server/main.lua`: Thêm hàm `UpdateLeaderboard()` và callback `xn-sellitem:getLeaderboard`
- `install.sql`: Thêm bảng `xn_sellitem_leaderboard`

#### Client-side:
- `client/main.lua`: Thêm NUI callback `getLeaderboard`

#### NUI/Frontend:
- `web/src/PhoneApp.tsx`: Thêm navigation tabs và tích hợp leaderboard view
- `web/src/PhoneApp.module.css`: Thêm styles cho navigation tabs
- `web/src/views/Leaderboard/index.tsx`: Component hiển thị bảng xếp hạng
- `web/src/views/Leaderboard/Leaderboard.module.css`: Styles cho leaderboard

### Cách hoạt động

1. **Tracking điểm**: Khi người chơi bán sản phẩm thành công:
   - Server tính tổng tiền bán được
   - Gọi hàm `UpdateLeaderboard(citizenId, playerName, category, points)`
   - Điểm được cộng dồn vào database theo citizen_id và category

2. **Hiển thị leaderboard**:
   - Phone app fetch dữ liệu từ server qua callback
   - Hiển thị top 10 người chơi theo category
   - Tự động làm mới khi chuyển tab

3. **UI/UX**:
   - Navigation tabs cho phép chuyển đổi giữa "Thị Trường" và "Bảng Xếp Hạng"
   - Category tabs cho phép xem leaderboard từng danh mục
   - Top 3 có highlight đặc biệt
   - Responsive và smooth animations

### Lưu ý
- Điểm chỉ được tính khi bán sản phẩm thành công (có tiền)
- Mỗi người chơi có một điểm riêng cho mỗi category
- Leaderboard tự động cập nhật real-time khi có người bán hàng
- Sử dụng chung global CSS của index.html để đồng nhất style
