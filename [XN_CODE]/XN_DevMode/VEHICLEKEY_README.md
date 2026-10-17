# Vehicle Key System

## Mô tả
System này cho phép người chơi đánh chìa khóa xe cho người chơi khác thông qua command `/danhchiakhoa`.

## Tính năng
- Command `/danhchiakhoa [ID]` để đánh chìa khóa xe
- Tự động lấy biển số xe từ xe người chơi đang ngồi
- Kiểm tra quyền sở hữu chìa khóa trước khi đánh
- Kiểm tra khoảng cách giữa hai người chơi
- Thông báo cho cả hai bên khi thành công

## Cách sử dụng

### Client Side
```lua
-- Kiểm tra có chìa khóa xe không
local hasKey = exports['Renewed-Vehiclekeys']:hasKey(plate)
```

### Server Side
```lua
-- Đánh chìa khóa cho người chơi
exports['Renewed-Vehiclekeys']:addKey(source, plate)
```

## Command
```
/danhchiakhoa [ID người chơi]
```

### Ví dụ:
```
/danhchiakhoa 12
```

## Requirements
- ox_lib
- qbx_core
- Renewed-Vehiclekeys

## Files
- `client/cl_vehiclekey.lua` - Phiên bản sử dụng lib.addCommand
- `client/cl_vehiclekey_alt.lua` - Phiên bản sử dụng RegisterCommand (backup)
- `server/sv_vehiclekey.lua` - Server logic

## Lưu ý
- Người chơi phải ngồi trong xe để sử dụng command
- Người chơi phải có chìa khóa xe trước khi có thể đánh cho người khác
- Hai người chơi phải ở gần nhau (trong vòng 10 mét)
