# Module authoring v2

## 1. Define the decorated store contract

Đặt schemas và boundary definitions trung lập tại
`packages/contracts/src/authoring/<module_id>/<module_id>.schemas.ts` và
`<module_id>.boundaries.ts`; schemas-only public entrypoint nằm tại
`<module_id>/index.ts`, còn decorated MobX store nằm tại
`web/src/app/modules/<module_id>/<module_id>.store.ts`. Boundary file export riêng ba
sibling boundaries và combined constant:

```ts
// packages/contracts/src/authoring/inventory/inventory.boundaries.ts
import type {ModuleBoundaries} from '../../index';

export const inventoryNuiBoundary = {
  events: {toNui: {}, toClient: {}},
  rpc: {toNui: {}, toClient: {}},
} as const satisfies ModuleBoundaries['nui'];

export const inventoryNetworkBoundary = {
  events: {clientToServer: {}, serverToClient: {}},
  rpc: {clientToServer: {}, serverToClient: {}},
} as const satisfies ModuleBoundaries['net'];

export const inventoryExportBoundary = {
  client: {},
  server: {},
} as const satisfies ModuleBoundaries['exports'];

export const inventoryBoundaries = {
  nui: inventoryNuiBoundary,
  net: inventoryNetworkBoundary,
  exports: inventoryExportBoundary,
} as const satisfies ModuleBoundaries;

// packages/contracts/src/authoring/inventory/index.ts
export * from './inventory.schemas.ts';

// packages/contracts/src/authoring/index.ts
import {inventoryBoundaries} from './inventory/inventory.boundaries';

export const moduleBoundaries = Object.freeze({
  inventory: inventoryBoundaries,
});

// web/src/app/modules/inventory/inventory.store.ts
import {State, Store} from '@lr/nui-store';
import type {ContractStatic} from '@lr/contracts';
import {InventorySnapshotSchema} from '@lr/contracts/authoring/inventory';

@Store({id: 'inventory'})
export class InventoryStore {
  @State(InventorySnapshotSchema, {items: []})
  accessor snapshot!: ContractStatic<typeof InventorySnapshotSchema>;
}
```

Export module schemas/boundaries và thêm combined constant vào explicit
`moduleBoundaries` registry trong `packages/contracts/src/authoring/index.ts`. NUI,
network và exports là sibling module boundaries. Mỗi per-module `index.ts` chỉ export
schemas. Web store chỉ import state schemas qua
`@lr/contracts/authoring/<module_id>`; boundary files, direct schema-file paths và root
authoring index không được package-export cho browser.

Thêm class vào explicit `storeModules` registry tại
`web/src/app/modules/registry.ts`. Chỉ dùng supported TypeBox schema subset, cung cấp
default hợp lệ cho mỗi state và đánh dấu `mutating: true` cho server state transition.
Codegen compose `@State` metadata từ `storeModules` với `moduleBoundaries` và reject nếu
hai registry không có one-to-one parity. Browser generated contracts chỉ chứa state và
NUI; net/exports chỉ có trong full package, Lua và LuaLS outputs.

Chạy `pnpm generate:contracts` và `pnpm check:contracts`. Không chỉnh generated files,
bao gồm `packages/contracts/src/modules/`.

## 2. Add side implementations

Trong file Lua của side tương ứng, gõ `lr-module` rồi chọn snippet để tạo nhanh
module có đủ `OnReady`, `Start`, `Stop` và `ModuleInstance` type đúng side.

```text
shared/modules/inventory.lua   pure helpers hoặc shared lifecycle part, nếu cần
client/modules/inventory.lua   NUI/client-native/client-net behavior
server/modules/inventory.lua   authorization/server state behavior
```

Mỗi side đăng ký cùng module ID nhưng có lifecycle instance riêng:

```lua
LR.Modules:Register({
    id = "inventory",
    dependencies = {},
    start = "resource",
    ---@param context LRClient.ModuleContext
    create = function(context)
        ---@class LRClient.ModuleMap
        ---@field inventory LRClient.InventoryModule
        ---@class LRClient.InventoryModule : LRClient.ModuleInstance
        local instance = {}

        ---@param readyContext LRClient.ModuleContext
        function instance:OnReady(readyContext)
            -- Chuẩn bị state/API riêng. Tất cả instance cùng phase đã được tạo.
        end

        ---@param startContext LRClient.ModuleContext
        function instance:Start(startContext)
            -- Tất cả module cùng phase đã OnReady; có thể gọi module khác tại đây.
            local Nui = startContext.nui.Inventory()
            startContext.disposables:Add(Nui.events.selected:On(function(payload)
                -- payload đã được runtime validate và có LuaLS type cụ thể
            end))
        end

        ---@param stopContext LRClient.ModuleContext
        function instance:Stop(stopContext) end
        return instance
    end,
})
```

Client dùng `LRClient.ModuleInstance`, server dùng `LRServer.ModuleInstance`, shared
dùng `LRShared.ModuleInstance`. Khai báo subclass bằng `---@class` làm cho `OnReady`,
`Start`, `Stop` tự nhận đúng context typed theo side và vẫn cho phép thêm method riêng.

Trong mỗi start phase, runtime chạy toàn bộ `Create`, sau đó toàn bộ `OnReady`, rồi
toàn bộ `Start`. Custom methods phải được khai báo trong `create` trước khi return;
`OnReady` dùng để chuẩn bị dữ liệu phía sau API đó;
`Start` dùng để nối module với nhau. Dependency order vẫn được giữ trong từng phase.

Module khác lấy instance nội bộ đã ready qua typed module map:

```lua
startContext.modules.inventory:Refresh()
```

Khai báo module đó trong `dependencies`. Không dùng `public` để gọi method nội bộ;
`Public/External` chỉ expose method đã khai báo trong contract. `GetModule(id)` vẫn có
sẵn cho lookup động, nhưng cần type annotation vì LuaLS không ánh xạ string runtime.

Các wildcard module trong manifest tự load file; không sửa side Application. Shared và
side file được phép cùng đăng ký `id = "inventory"`: runtime compose shared part trước
client/server part và stop đảo ngược. Hai part phải dùng cùng `start`. Bật/tắt bằng
`Config.Modules.inventory` khi cần; mỗi Application vẫn tạo module instance mới.

## 3. Use ownerless synchronized state

- State không có owner. Lua dùng `Get/Set/Watch`, object state có `Patch`.
- Browser low-level facade dùng `get/set/subscribe`, object state có `patch`.
- UI bình thường đọc/gán decorated store accessor; automatic MobX binding chuyển
  assignment thành browser state write.
- Decorated assignment được validate đồng bộ và optimistic. Browser serialize writes
  theo từng state; lỗi transport được báo qua runtime `onError`.
- Dùng `AppRuntime.flush()` khi cần chờ toàn bộ assignment đang pending.
- Lua bridge giữ canonical revision. Lua và browser writes đi qua cùng sequencer; write
  hợp lệ được chấp nhận sau cùng thắng.
- Event là fire-and-forget; không dùng event khi cần result.
- RPC luôn có request/response schema và timeout.
- High-frequency data dùng typed batched event ở module, không poll mỗi frame.

## 4. Authorization and cleanup

Client không authoritative. Server mutating RPC phải có `Authorize` và `Execute`:

```lua
LR.Net.Inventory.rpc.useItem:Handle({
    Authorize = function(playerSource, request)
        return playerSource > 0 and canUseItem(playerSource, request.itemId)
    end,
    Execute = function(playerSource, request)
        return useItem(playerSource, request.itemId)
    end,
})
```

Synchronized NUI state vẫn là input không tin cậy. Không dùng watcher hoặc decorated
store write để cấp tiền/item/role hay thay server RPC có authorization.

Mutating public export dùng cùng nguyên tắc, nhưng authorize theo resource gọi:

```lua
LR.Public.Inventory:Register({
    setBalance = {
        Authorize = function(invokingResource, request)
            return invokingResource == "trusted_resource"
        end,
        Execute = function(invokingResource, request)
            return updateBalance(request)
        end,
    },
})
```

Đưa mọi disposer từ `Watch`, `On`, `Handle`, public registration và timer vào
`context.disposables`. Không giữ global singleton module, không thực thi source Lua,
không dynamic dispatch method name và không gọi raw transport API trong module.
`AddEventHandler`, `TriggerEvent`, raw NUI/net API chỉ thuộc core boundary; raw framework
events/exports chỉ thuộc exact files trong `client/bridges` và `server/bridges`. Feature
module dùng typed `context.services.framework` và đưa mọi bridge subscription disposer
vào `context.disposables`. Static security gate/LuaLS fixture chặn raw access khỏi module.

## 5. Verify

```powershell
pnpm generate:contracts
pnpm check:contracts
pnpm test:nui-store
pnpm typecheck
pnpm test:coverage
pnpm test:lua
pnpm check:luals
pnpm test:security
```

Thêm test cho validator, lifecycle/cleanup, synchronized-state sequencing, optimistic
reconciliation, RPC timeout/error và authorization của module. Với gameplay behavior,
hoàn tất QA bằng FXServer/client thật.
