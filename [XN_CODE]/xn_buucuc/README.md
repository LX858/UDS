# XN_BUUCUC - Personal Storage System

## Mô tả
Script kho cá nhân sử dụng ox_inventory + qbxcore + ox_lib + ox_target. Mỗi người chơi có kho riêng tại cùng một vị trí.

## Tính năng
- Kho cá nhân với 500 slot và 10.000kg dung lượng
- Sử dụng ox_target để tương tác
- Mỗi người chơi có kho riêng dựa trên citizenid
- Stash ID theo format: `buucuc_citizenid`
- Vị trí: `vec3(-1082.57, -247.0, 37.81)`
- **Ngăn player swap item** vào kho (sử dụng `registerHook` của ox_inventory)
- **Export functions** để quản lý kho từ resource khác

## Dependencies
- qbx_core
- ox_lib
- ox_target  
- ox_inventory

## Cài đặt
1. Tải script về thư mục `resources/[XN_CODE]/xn_buucuc`
2. Thêm `ensure xn_buucuc` vào server.cfg
3. Khởi động lại server

## Cấu hình
Chỉnh sửa file `config.lua` để thay đổi:
- Vị trí kho (`Config.StorageLocation`)
- Số slot và trọng lượng (`Config.Storage`)
- Cấu hình target (`Config.Target`)
- Bật/tắt debug mode (`Config.Debug`)

## Sử dụng
- Đến vị trí `vec3(-1082.57, -247.0, 37.81)`
- Nhấn `E` hoặc click vào target để mở kho cá nhân
- Mỗi người chơi sẽ thấy kho riêng của mình

## Debug Commands (chỉ khi Config.Debug = true)
### Client:
- `/buucuc_debug` - Hiển thị thông tin debug

### Server (Admin only):
- `/buucuc_check [citizenid]` - Kiểm tra kho của người chơi
- `/buucuc_stats` - Thống kê số kho đã đăng ký

## Lưu ý
- Script tự động đăng ký stash khi người chơi mở lần đầu
- Dữ liệu kho được lưu trong database của ox_inventory
- Stash ID có format: `buucuc_[citizenid]`
- **Sử dụng `registerHook`** để chặn player swap item vào kho hiệu quả
- Player chỉ có thể xem kho, không thể tự thêm/xóa item
- Tất cả việc quản lý item phải thông qua export functions

## Export Functions
Các functions để sử dụng từ resource khác:

### 1. Thêm item vào kho
```lua
local success, message = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, item, count, metadata)
-- Ví dụ: exports.xn_buucuc:AddItemToPersonalStorage('ABC12345', 'bread', 5)
```

### 2. Xóa item khỏi kho
```lua
local success, message = exports.xn_buucuc:RemoveItemFromPersonalStorage(citizenid, item, count, metadata)
-- Ví dụ: exports.xn_buucuc:RemoveItemFromPersonalStorage('ABC12345', 'bread', 2)
```

### 3. Kiểm tra item trong kho
```lua
local itemData = exports.xn_buucuc:GetItemFromPersonalStorage(citizenid, item)
local allItems = exports.xn_buucuc:GetItemFromPersonalStorage(citizenid) -- Lấy toàn bộ
-- Ví dụ: exports.xn_buucuc:GetItemFromPersonalStorage('ABC12345', 'bread')
```

### 4. Kiểm tra có thể thêm item không
```lua
local canAdd, message = exports.xn_buucuc:CanAddToPersonalStorage(citizenid, item, count)
-- Ví dụ: exports.xn_buucuc:CanAddToPersonalStorage('ABC12345', 'bread', 10)
```

### 5. Lấy thông tin kho
```lua
local storageInfo, message = exports.xn_buucuc:GetPersonalStorageInfo(citizenid)
-- Trả về: stashId, citizenid, slots, weight, maxWeight, items
```

### 6. Làm sạch kho (xóa toàn bộ)
```lua
local success, message = exports.xn_buucuc:ClearPersonalStorage(citizenid)
-- Ví dụ: exports.xn_buucuc:ClearPersonalStorage('ABC12345')
```

## Ví dụ sử dụng trong resource khác:
```lua
-- Thêm 5 bánh mì vào kho của player
local player = QBX:GetPlayer(source)
if player then
    local success = exports.xn_buucuc:AddItemToPersonalStorage(player.PlayerData.citizenid, 'bread', 5)
    if success then
        print('Đã thêm 5 bánh mì vào kho cá nhân')
    end
end

-- Kiểm tra player có bao nhiêu bánh mì trong kho
local breadData = exports.xn_buucuc:GetItemFromPersonalStorage(player.PlayerData.citizenid, 'bread')
if breadData then
    print('Player có ' .. breadData.count .. ' bánh mì trong kho')
end
```