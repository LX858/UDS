# XN Police Weapon Restriction

Hệ thống cấm sử dụng vũ khí cảnh sát (súng điện + dùi cui) cho người không có job cảnh sát.

## Vũ khí bị cấm

- **WEAPON_STUNGUN** - Súng điện
- **WEAPON_NIGHTSTICK** - Dùi cui cảnh sát

## Tính năng

- ✅ Sử dụng `ox_inventory:currentWeapon` event 
- ✅ Backup method với thread kiểm tra liên tục
- ✅ Hỗ trợ nhiều loại vũ khí cảnh sát
- ✅ Auto disarm + loop disarm để đảm bảo
- ✅ Commands admin mới

## Cài đặt

1. Thêm folder vào `resources/[XN_CODE]/`
2. Thêm `ensure xn_stungun_restriction` vào server.cfg  
3. Restart server

## Commands Admin

- `/checkpoliceweapon` - Kiểm tra hệ thống và danh sách vũ khí bị cấm
- `/removepoliceweapon [id]` - Xóa tất cả vũ khí cảnh sát khỏi player

## Jobs được phép

- police
- sheriff
- state  
- fbi

Chỉnh sửa `Config.AllowedJobs` trong `config.lua` để thay đổi.
Chỉnh sửa `Config.RestrictedWeapons` để thêm/bớt vũ khí bị cấm.