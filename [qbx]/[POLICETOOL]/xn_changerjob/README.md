# XN Job Changer Script - QBCore Version

Script thay đổi job cho FiveM sử dụng QBCore, ox_target và ox_lib.

## Tính năng

- Thay đổi job Police bậc 11+ ↔ HocVien bậc 4
- Chỉ cho phép citizenid được chỉ định sử dụng
- Sử dụng ox_target để tạo interaction point
- Sử dụng ox_lib context menu và notification
- Ghi log các thay đổi job

## Yêu cầu

- QBCore Framework
- ox_target
- ox_lib
- oxmysql (tùy chọn, cho logging)

## Cài đặt

1. Copy folder `xn_changerjob` vào thư mục `resources` của server
2. Thêm vào `server.cfg`:
   ```
   ensure xn_changerjob
   ```
3. (Tùy chọn) Chạy file `job_change_logs.sql` để tạo bảng log trong database

## Cấu hình

### Thay đổi vị trí target:
Trong `config.lua`:
```lua
Config.TargetLocation = vec3(629.2, -6.24, 82.78)
```

### Cấu hình nhiều citizenid được phép:
Trong `config.lua`:
```lua
Config.AllowedCitizenIds = {
    "G601AI68",
    "ABC12345", -- Thêm citizenid khác ở đây
    "XYZ67890", -- Có thể thêm bao nhiêu cũng được
}
```

### Quản lý citizenid runtime (Commands Admin):
- `/jobchanger_add [citizenid]` - Thêm citizenid vào danh sách cho phép
- `/jobchanger_remove [citizenid]` - Xóa citizenid khỏi danh sách cho phép
- `/jobchanger_list` - Xem danh sách tất cả citizenid được phép

### Thay đổi job và grade:
Trong `config.lua`, section `Config.Jobs`

## Sử dụng

1. Thêm citizenid vào danh sách cho phép (2 cách):
   - **Cách 1**: Chỉnh sửa `config.lua` và restart resource
   - **Cách 2**: Dùng command `/jobchanger_add [citizenid]` (không cần restart)

2. Người chơi có citizenid trong danh sách đến vị trí `vec3(629.2, -6.24, 82.78)`
3. Nhấn `E` hoặc click vào target zone
4. Chọn option thay đổi job từ context menu
5. Xác nhận thay đổi

## Điều kiện thay đổi job

- Từ Police bậc 11+ → HocVien bậc 4
- Từ HocVien bậc 4 → Police bậc 13
- Chỉ các citizenid trong `Config.AllowedCitizenIds` mới có thể sử dụng

## Commands (Admin)

- `/checkjob` - Kiểm tra job và grade hiện tại
- `/jobchanger_add [citizenid]` - Thêm citizenid vào danh sách cho phép
- `/jobchanger_remove [citizenid]` - Xóa citizenid khỏi danh sách cho phép
- `/jobchanger_list` - Xem tất cả citizenid được phép

## QBCore Specific Notes

- Sử dụng `QBCore.Functions.GetPlayer()` thay vì ESX functions
- Job grades trong QBCore có structure `job.grade.level` thay vì `job.grade`
- Citizenid được lấy từ `Player.PlayerData.citizenid`
- Player name được lấy từ `Player.PlayerData.charinfo`

## Log

Script sẽ ghi log các thay đổi job vào:
- Console server
- Database (nếu bật tính năng logging)

## Cấu trúc file

```
xn_changerjob/
├── fxmanifest.lua      # Manifest file
├── config.lua          # Configuration file  
├── client.lua          # Client-side script
├── server.lua          # Server-side script
├── job_change_logs.sql # SQL tạo bảng log (tùy chọn)
├── demo.lua            # Demo script
└── README.md           # Hướng dẫn này
```
