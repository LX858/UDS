# LR Trucker Job

Resource vận chuyển hàng một người dành cho Qbox. Bản này chuyển đầy đủ gameplay từ
`nvn_transport` sang kiến trúc contract-first v2 và loại bỏ cơ chế chạy Lua từ xa,
callback tin dữ liệu client cùng các dependency Vinx/ESX cũ.

## Tính năng

- Tối đa 10 phiếu điều phối từ tồn kho sạch `xn-sellitem`, trộn với đơn doanh nghiệp;
  mặt hàng và điểm giao chỉ hiện sau khi nhận. Điểm giao bốc từ 6 địa điểm an toàn.
- Mỗi tài xế tự nhận, giao và hủy đơn; toàn bộ tiền công thuộc tài xế đó.
- Xe thuê dùng cho nhiều đơn trong 60 phút và tiếp tục dùng được sau mốc này với
  phụ phí 3% giá thuê mỗi phút. Trả xe tại `ReturnPoint` khi không có đơn đang chạy.
- Xe tải, rơ-moóc, xe hộ tống, xe nâng và kiện hàng được tạo bởi server qua OneSync.
- Tự khôi phục phương tiện/kiện hàng bị mất. Hoàn thành hoặc hủy đơn chỉ dọn hàng và
  thực thể của đơn; xe thuê được giữ đến khi trả, kể cả sau khi đăng nhập lại.
- Tiền Qbox, XP nghề lái xe trong metadata và hỗ trợ `qbx_vehiclekeys` nếu resource
  này đang chạy.
- NUI MobX responsive, HUD tiến độ và bảng phiếu điều phối ẩn chi tiết trước khi nhận.
- Cổng đặt hàng B2B cho quán ăn, quán nước và trạm xăng; đơn nhiều mặt hàng,
  escrow doanh nghiệp, chờ tồn kho và phân trang trên bảng tài xế.
- Chỉ dùng xe thuê Mule, Benson, Pounder, Hauler, Packer và Phantom; Packer/Phantom
  dùng rơ moóc bồn cho dầu thô.
- Light/dark theme lưu theo citizen ID và Roboto Condensed được đóng gói trong NUI.
- FSM server-authoritative kiểm tra thành viên, bước hiện tại, route, khoảng cách,
  ghế lái, xe nâng, package và chống gọi RPC lặp.

## Yêu cầu

- FXServer có OneSync.
- `qbx_core`.
- `qbx_vehiclekeys` là tùy chọn nhưng nên dùng.
- `oxmysql`; chạy [install.sql](./install.sql) trước khi start resource.
- `xn-sellitem` là nguồn tồn kho bắt buộc để tạo phiếu điều phối và nhận đơn doanh
  nghiệp. `Renewed-Banking`, `ox_inventory` và `cdn-fuel` phục vụ các tích hợp tương ứng.
- Node.js 24 và pnpm 12.3.4 chỉ cần khi build/chỉnh NUI hoặc chạy bộ kiểm tra.

Thứ tự khởi động tối thiểu trong `server.cfg`:

```cfg
ensure qbx_core
ensure qbx_vehiclekeys
ensure lr_trucker_job
```

Để dùng đầy đủ chuỗi cung ứng doanh nghiệp, start các tích hợp trước Trucker:

```cfg
ensure xn-sellitem
ensure Renewed-Banking
ensure ox_inventory
ensure cdn-fuel
ensure lr_trucker_job
```

Core bridge sẽ báo lỗi rõ ràng nếu `qbx_core` chưa start. Manifest không hard-code
framework dependency để giữ boundary v2 có thể kiểm thử độc lập.

## Cấu hình

Các tùy chọn chính nằm trong `config.lua`:

```lua
Config.Job.RequiredName = ''       -- Để trống cho phép mọi job
Config.Job.RequireOnDuty = false
Config.NPC.coords = vector4(...)
Config.ReturnPoint = vector4(...)
Config.Market.Items.orange = { category = 'traicay' } -- Giá và tồn kho lấy từ xn-sellitem.
Config.BusinessOrders.Fees = { base = 2000, perKm = 500, perPackage = 250, maximum = 25000 }
```

Các quy tắc hệ thống được chốt trong code: tối đa 10 phiếu trên bảng, 12 vật phẩm
mỗi kiện, chu kỳ thị trường 5 phút và 1.000 XP mỗi cấp.
Không cần cấu hình những giá trị này để vận hành resource.

Sửa hàng hóa trong `Config.Market.Items`; sửa xe đầu kéo, tọa độ kho, bãi giao và
thưởng trong `Config.Routes`. Model rơ-moóc, xe hộ tống và kiện hàng được resource
quản lý cố định. Điểm lấy và điểm giao đang dùng được khóa để tránh xếp dỡ chồng lên nhau.

## Build và kiểm tra

```powershell
pnpm install --frozen-lockfile
pnpm generate:contracts
pnpm typecheck
pnpm lint
pnpm test:lua
pnpm test:security
pnpm --filter web test
pnpm build
pnpm test:e2e
pnpm verify:manifest
```

Build production được tạo tại `web/build` và đã được `fxmanifest.lua` sử dụng.

## OOP runtime

Module `trucker` chỉ là composition root. Gameplay được chia theo domain và được
`fxmanifest.lua` load tường minh theo thứ tự class -> service -> module:

```text
server/classes/trucker/order_board.lua      hàng đợi và quyền sở hữu route
server/classes/trucker/team.lua             thành viên, host và reconnect
server/classes/trucker/mission_session.lua  FSM, entity, package và payout
server/services/trucker_service.lua         network handlers và orchestration
client/classes/trucker/npc.lua              NPC, blip và interaction
client/classes/trucker/mission.lua          world sync và gameplay 7 bước
client/services/trucker_service.lua         NUI/net/public composition
client|server/modules/trucker.lua           chỉ đăng ký lifecycle
```

Mọi class dùng `LR.Class:Define` và constructor nhận đúng một input table có type.
Không dùng `require`, `load`, source hot reload hoặc transport thô trong domain code.

## Public client API

Resource khác có thể mở bảng điều phối hoặc đọc snapshot qua public contract:

```lua
local result = exports.lr_trucker_job:trucker_open({})
local snapshot = exports.lr_trucker_job:trucker_getSnapshot({})
```

Không còn `ImplCall`, hot reload source Lua, event động hoặc callback `nvn_transport`
cũ. Đây là breaking port dành riêng cho Qbox.

## Kiến trúc phát triển

Xem [Hướng dẫn sử dụng đầy đủ](./docs/USAGE_GUIDE.md) trước khi thêm module. Contract
được author tại `packages/contracts/src/authoring/<module_id>/`; mỗi module có
`<module_id>.schemas.ts`, `<module_id>.boundaries.ts` và schemas-only
`authoring/<module_id>/index.ts`. Đăng ký boundary qua `moduleBoundaries`, sau đó đăng
ký store tương ứng:

```ts
import {InventorySnapshotSchema} from '@lr/contracts/authoring/inventory';

@Store({id: 'inventory'})
export class InventoryStore {
  @State(InventorySnapshotSchema, {items: []})
  accessor snapshot!: ContractStatic<typeof InventorySnapshotSchema>;
}
```
