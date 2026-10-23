# Hệ thống lưu trữ dữ liệu y tế (Medical Data Persistence)

## Vấn đề đã được giải quyết

Trước đây, khi người chơi thoát game và kết nối lại, tất cả trạng thái bị thương và mất máu sẽ bị reset về bình thường. Điều này xảy ra vì dữ liệu chỉ được lưu trong StateBags (bộ nhớ tạm thời) và không được lưu vào cơ sở dữ liệu.

## Giải pháp đã triển khai

### 1. Lưu trữ dữ liệu vào metadata
- Tất cả trạng thái bị thương (`medicalInjuries`) và mức độ mất máu (`bleedLevel`) giờ đây được lưu vào metadata của người chơi
- Metadata được tự động lưu vào cơ sở dữ liệu bởi hệ thống qbx_core

### 2. Đồng bộ dữ liệu tự động
- Khi người chơi kết nối lại (`QBCore:Server:OnPlayerLoaded`), dữ liệu y tế sẽ được khôi phục từ metadata
- Mọi thay đổi trạng thái y tế sẽ được tự động đồng bộ vào metadata thông qua StateBag handlers

### 3. Xử lý disconnect
- Khi người chơi disconnect (`QBCore:Server:OnPlayerUnload`), dữ liệu hiện tại sẽ được lưu vào metadata

## Các thay đổi chính

### Server side (`server/main.lua`)

1. **RegisterNetEvent('QBCore:Server:OnPlayerLoaded')**: Khôi phục dữ liệu y tế từ metadata
2. **StateBag Change Handlers**: Tự động lưu mọi thay đổi vào metadata
3. **RegisterNetEvent('QBCore:Server:OnPlayerUnload')**: Lưu dữ liệu trước khi disconnect
4. **Updated heal functions**: Clear metadata khi được heal
5. **New exports**: `SyncMedicalData` để sync thủ công nếu cần
6. **New command**: `/checkmedical [id]` để admin kiểm tra trạng thái lưu trữ

### Client side (`client/main.lua`)

1. **Auto sync**: Tự động request sync dữ liệu khi spawn
2. **Manual sync event**: `qbx_medical:client:syncMedicalData` để sync thủ công

## Cách sử dụng

### Tự động
Hệ thống hoạt động hoàn toàn tự động. Người chơi không cần làm gì đặc biệt.

### Commands cho Admin
```
/checkmedical [player_id] - Kiểm tra trạng thái y tế được lưu trữ của người chơi
/aheal [player_id] - Heal người chơi và clear tất cả dữ liệu y tế
```

### Exports cho developers
```lua
-- Đồng bộ dữ liệu y tế thủ công
exports.qbx_medical:SyncMedicalData(playerId)

-- Lấy trạng thái y tế
local status = exports.qbx_medical:GetPlayerStatus(playerId)
```

## Dữ liệu được lưu trữ

### bleedLevel (number)
Mức độ mất máu hiện tại (0-4)

### medicalInjuries (table)
```lua
{
    ["HEAD"] = {severity = 2, weaponHash = -1076751822},
    ["LLEG"] = {severity = 3, weaponHash = 453432689},
    -- ... các phần cơ thể khác
}
```

## Lưu ý kỹ thuật

1. Dữ liệu được lưu trong `player.PlayerData.metadata`
2. StateBags vẫn được sử dụng cho real-time sync giữa client và server
3. Metadata được tự động lưu vào database bởi qbx_core
4. Hệ thống tương thích ngược hoàn toàn với code hiện tại

## Test để đảm bảo hoạt động

1. Gây thương tích cho người chơi
2. Kiểm tra với `/checkmedical`
3. Thoát game và kết nối lại
4. Kiểm tra lại với `/checkmedical` - dữ liệu phải vẫn còn
5. Sử dụng `/aheal` để clear dữ liệu
