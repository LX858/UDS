# Debug Guide - Hệ thống lưu trữ dữ liệu y tế

## Vấn đề hiện tại
Người chơi vẫn đầy máu và hết bị đau khi kết nối lại

## Các thay đổi Debug đã thêm

### 1. Console Logging
Hệ thống sẽ in ra console khi:
- Khôi phục dữ liệu y tế: `^2[qbx_medical] Restoring medical data for player X^7`
- Lưu dữ liệu y tế: `^4[qbx_medical] Saving bleed level X for player Y^7`
- Sync dữ liệu: `^5[qbx_medical] Client requested data sync for player X^7`

### 2. Backup System
- Tự động backup dữ liệu mỗi 30 giây
- Chạy nền để đảm bảo dữ liệu không bị mất

### 3. Multiple Event Handlers
- `QBCore:Server:OnPlayerLoaded`
- `QBCore:Server:PlayerLoaded` (backup event)
- Client spawn events

## Commands để debug

### `/checkmedical [id]`
Kiểm tra dữ liệu y tế đã lưu trong database

### `/restoremedical [id]`
Force khôi phục dữ liệu y tế từ database

## Cách test và debug

### Bước 1: Test lưu dữ liệu
1. Gây thương tích cho người chơi
2. Kiểm tra console có thông báo lưu dữ liệu không
3. Dùng `/checkmedical` để xem dữ liệu đã lưu chưa

### Bước 2: Test khôi phục dữ liệu
1. Restart resource: `/restart qbx_medical`
2. Hoặc reconnect game
3. Kiểm tra console có thông báo khôi phục không
4. Nếu không tự động khôi phục, dùng `/restoremedical`

### Bước 3: Kiểm tra events
Nếu vẫn không hoạt động, có thể:
1. Event `QBCore:Server:OnPlayerLoaded` không được trigger
2. Metadata không được lưu đúng cách
3. StateBag handlers bị conflict

## Troubleshooting

### Nếu không thấy log console
Có thể events không được trigger đúng. Thử:
```
/restoremedical [your_id]
```

### Nếu dữ liệu không được lưu
Kiểm tra xem có conflict với resource khác không:
- ambulancejob
- hospital
- esx_ambulancejob

### Nếu dữ liệu được lưu nhưng không khôi phục
Có thể do load order. Thêm vào `fxmanifest.lua`:
```lua
dependencies {
    'qbx_core'
}
```

## Debug commands trong game

### Test save
```
-- Gây thương tích
-- Dùng weapon để gây damage
-- Kiểm tra console logs
```

### Test restore
```
/checkmedical
/restoremedical
```

### View metadata trực tiếp
```lua
-- Trong server console
local player = exports.qbx_core:GetPlayer(1) -- thay 1 bằng player ID
--print(json.encode(player.PlayerData.metadata.medicalInjuries))
--print(player.PlayerData.metadata.bleedLevel)
```

## Expected Console Output

Khi hoạt động đúng, bạn sẽ thấy:

```
^2[qbx_medical] Restoring medical data for player 1^7
^3[qbx_medical] Restored bleed level: 2^7
^3[qbx_medical] Restored injury: HEAD - Severity: 3^7
^3[qbx_medical] Total restored injuries: 1^7
```

Nếu không thấy các log này, có vấn đề với event handlers.
