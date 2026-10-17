# 🚔 MINI MDT - Hệ Thống Quản Lý Án Tích

## Tính Năng Chính

✅ **Quản lý hồ sơ vụ án**
- Tạo hồ sơ vụ án với tiêu đề, mô tả chi tiết
- Gắn tags tội phạm (Nghi phạm, Giết người, Buôn lậu, Cướp, Trộm, Bạo lực, Ma túy)
- Theo dõi trạng thái: Đang mở, Đã đóng, Chờ xử lý

✅ **Tìm kiếm người chơi**
- Tìm theo PID (ID trong database)
- Tìm theo Citizen ID
- Tìm theo tên người chơi
- Hiển thị đầy đủ thông tin

✅ **Quản lý tội phạm**
- Thêm tội phạm vào hồ sơ
- Ghi lại tội danh, bằng chứng
- Liên kết với người chơi thật

✅ **Quản lý tiền phạt & tù**
- 10 mức phạt mặc định
- Tạo tiền phạt tùy chỉnh
- Ghi lại thời gian tù (phút)
- Theo dõi trạng thái thanh toán

✅ **Quản lý cảnh sát**
- Xem cảnh sát đang online
- Thêm cảnh sát vào vụ án
- Phân công nhiệm vụ

## Cài Đặt

### 1. Database
Chạy file `mini-mdt.sql` trong database MySQL:
```sql
source mini-mdt.sql
```

### 2. Dependencies
Đảm bảo có các resources:
- qb-core hoặc qbx_core
- ox_lib
- oxmysql

### 3. Server.cfg
Thêm vào server.cfg:
```
ensure mini-mdt
```

### 4. Khởi động
Restart server hoặc:
```
restart mini-mdt
```

## Sử Dụng

### Mở MDT
Trong game, gõ lệnh:
```
/minimdt
```

### Tạo Hồ Sơ
1. Click "Tạo Hồ Sơ Mới"
2. Nhập tiêu đề vụ án
3. Nhập mô tả chi tiết
4. Chọn tags tội phạm
5. Click "Tạo Hồ Sơ"

### Tìm Người Chơi
1. Click "Tìm Người Chơi"
2. Nhập PID, ID hoặc tên
3. Click "Tìm Kiếm"
4. Chọn người để thêm vào hồ sơ

### Thêm Tiền Phạt
1. Mở hồ sơ vụ án
2. Chọn tội phạm
3. Click "Thêm Tiền Phạt"
4. Nhập số tiền và thời gian tù
5. Click "Lưu"

## Cấu Hình

### config.lua
```lua
Config.Command = 'minimdt' -- Lệnh mở MDT
Config.AllowedJobs = {      -- Jobs được phép dùng
    ['police'] = true,
    ['sheriff'] = true
}
```

### Thêm Tags Tội Phạm
Sửa trong `config.lua`:
```lua
Config.CrimeTags = {
    {id = 9, label = "Tag mới"},
}
```

### Thêm Mức Phạt
Sửa trong `config.lua`:
```lua
Config.FineTypes = {
    {id = 11, name = "Tên tiền phạt", amount = 1000, jailTime = 5},
}
```

## Exports

### Server
```lua
-- Kiểm tra quyền
local hasJob = exports['mini-mdt']:HasPoliceJob(source)

-- Lấy tên người chơi
local name = exports['mini-mdt']:GetPlayerName(citizenid)
```

## Support
Discord: [Your Discord]
Github: [Your Github]

## License
MIT License

---
Made with ❤️ for FiveM QBox
