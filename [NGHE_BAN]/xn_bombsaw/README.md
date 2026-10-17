# xn-bombsaw - QBX Core + OX_Lib + OX_Inventory

Resource cưa bom đã được chuyển đổi sang QBX Core, OX_Lib và OX_Inventory.

## Yêu cầu

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [rpemotes](https://github.com/TayMcKenzieNZ/rpemotes)
- [InteractSound](https://github.com/plunkettscott/interact-sound)
- [dc-requests](https://github.com/your-repo/dc-requests) (hoặc tương tự)

## Cài đặt

1. Sao chép resource vào thư mục `resources` của bạn
2. Thêm `ensure xn-bombsaw` vào `server.cfg`
3. Thêm items vào ox_inventory:
   - Mở file `ox_inventory/data/items.lua`
   - Copy nội dung từ file `items.lua` trong resource này và paste vào
4. Thêm hình ảnh items:
   - Copy `quabom.png` vào `ox_inventory/web/images/`
   - Copy `hoado.png` vào `ox_inventory/web/images/`
5. Khởi động lại server

## Thay đổi chính

### Client Side:
- ✅ Thay thế `QBCore` bằng `exports.qbx_core`
- ✅ Thay thế `QBCore.Functions.Notify` bằng `lib.notify`
- ✅ Thay thế `QBCore.Functions.Progressbar` bằng `lib.progressBar`
- ✅ Thay thế `dc-skillbar` bằng `lib.skillCheck`
- ✅ Thay thế `QBCore.Functions.GetClosestPlayer` bằng `lib.getClosestPlayer`

### Server Side:
- ✅ Thay thế `QBCore.Functions.GetPlayer` bằng `exports.qbx_core:GetPlayer`
- ✅ Thay thế `QBCore.Functions.GetPlayerByCitizenId` bằng `exports.qbx_core:GetPlayerByCitizenId`
- ✅ Thay thế `Player.Functions.AddItem` bằng `exports.ox_inventory:AddItem`
- ✅ Thay thế `Player.Functions.RemoveItem` bằng `exports.ox_inventory:RemoveItem`
- ✅ Thay thế `QBCore.Functions.CreateUseableItem` bằng `ox_inventory hook system`
- ✅ Xóa `TriggerClientEvent('inventory:client:ItemBox')` (ox_inventory tự động xử lý)

### FXManifest:
- ✅ Cập nhật fx_version lên `cerulean`
- ✅ Thêm `@ox_lib/init.lua` vào shared_scripts
- ✅ Thêm `lua54 'yes'`
- ✅ Xóa dependency `@PolyZone/client.lua`

## Config

Có thể điều chỉnh trong `config.lua`:
- `Config.BombSawingSuccess` - Số lần skillcheck thành công cần để hoàn thành
- `Config.BombSawingFail` - Số lần skillcheck thất bại để bom nổ
- `Config.BombProduct` - Phần thưởng nhận được

## Sử dụng

1. Người chơi sử dụng item `quabom`
2. Tìm người chơi khác ở gần để cưa cùng
3. Hoàn thành skillcheck để nhận phần thưởng
4. Nếu fail quá nhiều, bom sẽ nổ!

## Lưu ý

- Các lỗi Lua lint về `lib` là bình thường vì `ox_lib` được load qua shared_script
- Đảm bảo tất cả dependencies được cài đặt và khởi động trước resource này
- Nếu cần điều chỉnh độ khó của skillcheck, sửa trong hàm `BeginOldBombSawing()` ở client/main.lua

## Hỗ trợ

Nếu có vấn đề gì, hãy kiểm tra:
1. Console F8 để xem lỗi
2. Server console để xem lỗi server-side
3. Đảm bảo tất cả dependencies đã được cài đặt đúng
