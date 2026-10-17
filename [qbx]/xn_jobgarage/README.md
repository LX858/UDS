# XN Job Garage - Vehicle Storage System

## Tính Năng Mới

### Hệ Thống Lưu Trữ Xe SQL
- **Lưu trữ xe cá nhân**: Mỗi nhân viên có xe riêng được lưu trong database, gắn với citizenid
- **Lần đầu lấy xe**: Khi lấy xe lần đầu, hệ thống sẽ tạo biển số ngẫu nhiên và lưu vào database
- **Lưu trạng thái xe**: Khi cất xe, hệ thống lưu:
  - Độ bền thân xe (body health)
  - Độ bền động cơ (engine health)
  - Lượng nhiên liệu (fuel level)
  - Các độ chỉnh (vehicle mods)
- **Khôi phục dữ liệu**: Khi lấy xe ra, tất cả dữ liệu được khôi phục như cũ

### Hệ Thống Impound (Chuộc Xe)
- **Kiểm tra xe ngoài garage**: Nếu player lấy xe nhưng không cất, lần sau sẽ phải chuộc
- **Phí chuộc**: $500 để chuộc xe về
- **Penalty**: Xe chuộc về chỉ còn 30% độ bền (body & engine)
- **Cảnh báo rõ ràng**: Dialog box thông báo tình trạng và giá chuộc

## Cài Đặt

### 1. Import SQL
Chạy file `install.sql` vào database của bạn:
```sql
-- File này sẽ tạo bảng job_vehicles để lưu trữ dữ liệu xe
```

### 2. Dependencies
Đảm bảo bạn đã cài đặt:
- qbx_core
- ox_lib
- oxmysql
- cdn-fuel (hoặc fuel resource tương tự)
- Renewed-Vehiclekeys (hoặc vehicle keys resource tương tự)

### 3. Khởi Động Resource
```
ensure xn_jobgarage
```

## Cách Sử Dụng

### Lấy Xe (First Time)
1. Đến garage công việc
2. Nhấn E để mở menu
3. Chọn xe muốn lấy
4. Hệ thống tự động:
   - Tạo biển số ngẫu nhiên (ví dụ: PO123456 cho police)
   - Lưu vào database
   - Spawn xe với full health (100%)

### Cất Xe
1. Ngồi trong xe job
2. Đến vị trí spawn xe (có marker đỏ)
3. Nhấn E để cất xe
4. Hệ thống lưu:
   - Độ bền hiện tại
   - Lượng fuel
   - Tất cả mods (nếu có)

### Lấy Xe Lần 2+
1. Đến garage
2. Nhấn E, chọn xe
3. Xe spawn với đúng:
   - Biển số cũ
   - Độ bền đã lưu
   - Fuel đã lưu
   - Mods đã lưu

### Impound (Chuộc Xe)
**Khi nào cần chuộc?**
- Bạn lấy xe nhưng không cất
- Lần sau lấy xe khác ở garage đó

**Quy trình:**
1. Thử lấy xe → Hiện dialog cảnh báo
2. Dialog hiển thị: "Xe đang ngoài garage, phí chuộc $500, xe chỉ còn 30% độ bền"
3. Nhấn "Chuộc Xe" → Trả $500
4. Xe về garage với 30% health
5. Có thể lấy xe mới

## Cấu Trúc Database

### Bảng `job_vehicles`
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| citizenid | VARCHAR(50) | ID của nhân viên |
| job | VARCHAR(50) | Job name (police, ambulance, etc) |
| garage | VARCHAR(50) | Garage name (police_2, ambulance_aircraft, etc) |
| vehicle | VARCHAR(50) | Model xe |
| plate | VARCHAR(8) | Biển số xe (unique) |
| mods | LONGTEXT | JSON vehicle properties |
| body | INT | Body health (0-1000) |
| engine | INT | Engine health (0-1000) |
| fuel | INT | Fuel level (0-100) |
| is_out | TINYINT | 1 = xe đang ngoài, 0 = trong garage |
| last_updated | TIMESTAMP | Thời gian cập nhật |

**Unique Key**: Mỗi player chỉ có 1 xe cho mỗi combination của (citizenid, job, garage)

## Logic Flow

### Lấy Xe
```
1. Player nhấn E → Mở menu xe
2. Chọn xe → Check database
3. Nếu xe tồn tại:
   a. Kiểm tra is_out
   b. Nếu is_out = 1 → Show impound dialog
   c. Nếu is_out = 0 → Spawn với dữ liệu đã lưu
4. Nếu xe không tồn tại:
   a. Generate plate ngẫu nhiên
   b. Spawn xe mới
   c. Insert vào database với is_out = 1
```

### Cất Xe
```
1. Player trong xe → Đến spawn point
2. Nhấn E → Delete vehicle
3. Trước khi delete:
   a. Lấy vehicle properties (mods)
   b. Lấy body health
   c. Lấy engine health
   d. Lấy fuel level
4. Update database:
   - Lưu tất cả dữ liệu
   - Set is_out = 0
```

### Impound
```
1. Player thử lấy xe → is_out = 1
2. Show dialog với options:
   - Confirm: Trả $500
   - Cancel: Đóng dialog
3. Nếu confirm:
   a. Check money (cash/bank)
   b. Remove $500
   c. Update database: is_out = 0, body = 300, engine = 300
   d. Spawn xe với 30% health
```

## Config Variables

### Impound Cost
Sửa trong `server.lua`:
```lua
local impoundCost = 500 -- Đổi số này để thay đổi phí chuộc
```

### Impound Health Penalty
Sửa trong `server.lua` (dòng charge impound event):
```lua
body = 300,   -- 30% (1000 = 100%)
engine = 300  -- 30%
```

## Troubleshooting

### Xe không lưu dữ liệu
- Kiểm tra oxmysql đã cài đúng
- Check console có lỗi SQL không
- Xem database đã tạo bảng `job_vehicles` chưa

### Xe spawn không đúng health
- Check cdn-fuel export có hoạt động không
- Xem vehicle properties có được lưu đúng không
- Debug với `Config.Debug = true`

### Impound không hoạt động
- Check player có đủ tiền không
- Xem dialog có hiện không
- Check server event có được gọi không

## Credits
- **Author**: XN
- **Version**: 2.1.0
- **Framework**: QBX Core
- **License**: MIT

## Changelog

### v2.1.0
- ✅ Thêm SQL storage cho xe cá nhân
- ✅ Hệ thống lưu/tải vehicle data
- ✅ Impound system với phí $500
- ✅ Penalty 30% health khi impound
- ✅ Random plate generation
- ✅ Track vehicle status (in/out garage)
