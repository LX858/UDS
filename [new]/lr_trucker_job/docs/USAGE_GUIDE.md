# Hướng dẫn sử dụng LR Boilerplate MobX v2

Tài liệu này là hướng dẫn sử dụng đầy đủ dành cho người viết resource. Nội dung
tập trung vào API được phép dùng trong module, contract và NUI. Các hàm orchestration
nội bộ trong `shared/core`, `client/core` và `server/core` không nên được gọi từ feature
module trừ khi phần "API nâng cao" nói rõ.

## Mục lục

1. Chuẩn bị môi trường
2. Mô hình kiến trúc
3. Tạo module đầu tiên
4. Module descriptor và lifecycle
5. ModuleContext
6. Gọi module nội bộ
7. Shared/client/server composition
8. Config và start phase
9. Logger
10. DisposableStack
11. Scheduler
12. Readiness provider và built-in framework bridge
13. Locale và thời gian
14. Contract TypeBox
15. NUI từ Lua client
16. NUI từ React/TypeScript
17. Client/server network
18. Public và External API
19. Application và service API
20. Validation, timeout và giới hạn
21. Quy trình phát triển
22. Ví dụ end-to-end
23. API reference bổ sung
24. Checklist module mới

## 1. Chuẩn bị môi trường

### 1.1 Yêu cầu

| Thành phần | Yêu cầu |
|---|---|
| FiveM | GTA5/FiveM runtime |
| Node.js | 24 trở lên |
| Package manager | pnpm 10.32.1 |
| Editor | VS Code |
| Lua editor extension | `sumneko.lua` 3.19.1 |
| LuaLS CLI | `lua-language-server` 3.19.1 |

Project đã chứa CFX declarations riêng theo client/server/shared. Không bật
`overextended.cfxlua-vscode` trong workspace này vì extension đó tự thay đổi
`Lua.workspace.library` và làm mất side-specific types.

### 1.2 Mở đúng workspace

Mở file:

```text
lr_trucker_job.code-workspace
```

Không mở project bằng `Open Folder`. Workspace chia source thành:

| Workspace | API được nạp |
|---|---|
| `lua-client` | shared + client native + NUI + client Net/Public |
| `lua-server` | shared + server native + server Net/Public |
| `lua-shared` | shared API, không thấy client/server API |
| `nui` | React, TypeScript và generated contract types |

### 1.3 Cài đặt và kiểm tra

Tạo resource mới từ package:

```powershell
npx create-lr-resource@latest --name my_inventory
cd my_inventory
```

Trong checkout của boilerplate có thể dùng:

```powershell
pnpm create:resource -- --name my_inventory
```

Sau đó cài dependency và chạy verification:

```powershell
pnpm install --frozen-lockfile
pnpm generate
pnpm verify
```

Trong quá trình phát triển có thể chạy từng gate nhỏ hơn:

```powershell
pnpm test:lua
pnpm check:luals
pnpm check:contracts
pnpm --filter web test
pnpm --filter web build
```

`pnpm check:luals` cần executable CLI riêng, không dùng binary thông qua editor API.
Script tìm theo thứ tự: biến `LUA_LANGUAGE_SERVER`,
`.tools/lua-language-server/bin/lua-language-server[.exe]`, rồi `PATH`.

Sau khi sửa Lua hoặc contract, restart resource:

```text
restart <resource_name>
```

## 2. Mô hình kiến trúc

Một feature có thể gồm bốn phần:

```text
packages/contracts/src/authoring/inventory/inventory.schemas.ts
packages/contracts/src/authoring/inventory/inventory.boundaries.ts
packages/contracts/src/authoring/inventory/index.ts
packages/contracts/src/authoring/index.ts
web/src/app/modules/inventory/inventory.store.ts
shared/modules/inventory.lua
client/modules/inventory.lua
server/modules/inventory.lua
web/src/... inventory UI components
```

| Phần | Trách nhiệm |
|---|---|
| Neutral contract authoring | DTO schemas và sibling NUI/network/export boundaries |
| Decorated store | Synchronized state và MobX behavior |
| Shared Lua | Helper thuần, logic dùng được ở cả client và server |
| Client Lua | Native client, NUI, client Net và client export |
| Server Lua | Authoritative state, authorization, server Net và server export |
| NUI TypeScript | Decorated MobX store, local UI state, event/RPC handler và React |

Neutral TypeBox schemas và boundary definitions là contract authoring source trong
`packages/contracts/src/authoring/`. Combined boundaries được map theo module ID trong
explicit `moduleBoundaries` registry tại `packages/contracts/src/authoring/index.ts`.
Decorated store và explicit `storeModules` registry lần lượt nằm ở
`web/src/app/modules/<module_id>/` và `web/src/app/modules/registry.ts`.

NUI, network và exports là sibling module boundaries. Codegen compose `@State` metadata
từ `storeModules` với `moduleBoundaries` và validate one-to-one parity. Browser generated
contracts chỉ chứa synchronized state và NUI; net/exports vẫn nằm trong full package,
Lua runtime và LuaLS outputs, không được import hoặc bundle bởi web stores.
`packages/contracts/src/modules/` và các facade/declaration khác là generated artifacts,
không chỉnh bằng tay. Không gửi class, function, userdata, vector hoặc cyclic table qua
NUI, network hay exports.

## 3. Tạo module đầu tiên

### 3.1 Dùng VS Code snippet

Tạo file trong side cần dùng, ví dụ:

```text
client/modules/inventory.lua
```

Gõ `lr-module`, chọn snippet rồi điền:

| Tab stop | Giá trị ví dụ |
|---|---|
| Module ID | `inventory` |
| Class name | `Inventory` |
| Start phase | `resource` hoặc `player` |
| Dependencies | `"player"` hoặc để trống |

Snippet tạo module typesafe:

```lua
LR.Modules:Register({
  id = "inventory",
  start = "resource",
  dependencies = {},

  ---@param context LRClient.ModuleContext
  create = function(context)
    ---@class LRClient.ModuleMap
    ---@field inventory LRClient.InventoryModule
    ---@class LRClient.InventoryModule : LRClient.ModuleInstance
    local instance = {}

    ---@param readyContext LRClient.ModuleContext
    function instance:OnReady(readyContext)
      readyContext.logger:Debug("inventory ready")
    end

    ---@param startContext LRClient.ModuleContext
    function instance:Start(startContext)
      startContext.logger:Debug("inventory started")
    end

    ---@param stopContext LRClient.ModuleContext
    function instance:Stop(stopContext)
      stopContext.logger:Debug("inventory stopped")
    end

    return instance
  end,
})
```

Đổi namespace theo side:

| Side | Instance class | Context class | Module map |
|---|---|---|---|
| Client | `LRClient.ModuleInstance` | `LRClient.ModuleContext` | `LRClient.ModuleMap` |
| Server | `LRServer.ModuleInstance` | `LRServer.ModuleContext` | `LRServer.ModuleMap` |
| Shared | `LRShared.ModuleInstance` | `LRShared.ModuleContext` | `LRShared.ModuleMap` |

## 4. Module descriptor và lifecycle

### 4.1 Descriptor API

```lua
LR.Modules:Register({
  id = "inventory",
  start = "resource",
  dependencies = { "player", "database" },
  ---@param context LRClient.ModuleContext
  create = function(context)
    return {}
  end,
})
```

| Field | Bắt buộc | Ý nghĩa |
|---|---:|---|
| `id` | Có | `^[a-z][a-z0-9_]*$`, duy nhất trong mỗi side registry |
| `start` | Không | `resource` mặc định hoặc `player` |
| `dependencies` | Không | Danh sách module phải có và đứng trước module hiện tại |
| `create` | Có | Tạo instance mới cho application |

`LR.Modules:Register()` trả về descriptor đã normalize. Module author thường không cần
giữ giá trị trả về.

### 4.2 Thứ tự lifecycle

Trong từng start phase:

```text
Create tất cả module
-> OnReady tất cả module
-> Start tất cả module
```

Khi resource stop:

```text
Stop theo dependency order đảo ngược
-> DisposeAll của từng module
-> Dispose service theo thứ tự đảo ngược
```

| Phase | Nên làm | Không nên làm |
|---|---|---|
| `create` | Tạo private state, tạo instance methods | Register event/export hoặc side effect có cleanup |
| `OnReady` | Khởi tạo dữ liệu phía sau API đã khai báo trong `create` | Thêm method mới hoặc gọi module đứng sau chưa ready |
| `Start` | Kết nối module, subscribe, gọi dependency | Tạo resource không có disposer |
| `Stop` | Dừng hành vi đặc biệt | Giả định `Start` đã hoàn tất 100% |

`Stop` phải chịu được partial startup vì một module khác có thể throw trong `Start`.

### 4.3 Custom method

Khai báo custom method trực tiếp trên subclass:

```lua
---@class LRClient.InventoryModule : LRClient.ModuleInstance
local instance = {}
local selectedItem = nil

function instance:GetSelectedItem()
  return selectedItem
end

function instance:Refresh()
  -- Refresh private module state.
end
```

Không dùng `---@type LRClient.ModuleInstance` cho instance nếu muốn thêm method riêng.
Base type là class đóng; module-specific `---@class ... : ModuleInstance` mới cho phép
khai báo API riêng một cách tường minh.

## 5. ModuleContext

Lifecycle nhận cùng một context object. Client context có đầy đủ các field sau:

| Field | Type | Dùng để làm gì |
|---|---|---|
| `app` | `LRClient.Application` | Application sở hữu module |
| `descriptor` | `LRClient.ModuleDescriptor` | Descriptor đã normalize/compose |
| `id` | `string` | ID module hiện tại |
| `side` | `"client"` | Side hiện tại |
| `resourceName` | `string` | Tên FiveM resource |
| `logger` | `LRShared.Logger` | Logger đã scope theo module |
| `scheduler` | `LRShared.Scheduler` | Delay/cancel abstraction |
| `disposables` | `LRShared.DisposableStack` | Cleanup tự động khi stop |
| `services` | `table<string, unknown>` | Service registry cấp thấp |
| `nui` | `LRClient.Nui` | Typed NUI facade |
| `net` | `LRClient.Net` | Typed client network facade |
| `public` | `LRClient.Public` | Đăng ký client exports |
| `external` | `LRClient.External` | Gọi exports của resource khác |
| `modules` | `LRClient.ModuleMap` | Gọi module nội bộ có type tự động |
| `GetModule(id)` | generic | Lookup module động |

Server context không có `nui`; các field `net`, `public`, `external` dùng server types.
Shared context không được gọi API client/server.

Ví dụ:

```lua
---@param startContext LRClient.ModuleContext
function instance:Start(startContext)
  startContext.logger:Info(
    "module=%s side=%s resource=%s",
    startContext.id,
    startContext.side,
    startContext.resourceName
  )
end
```

## 6. Gọi module nội bộ

### 6.1 Typed module map

Module cung cấp API phải augment module map:

```lua
---@class LRClient.ModuleMap
---@field inventory LRClient.InventoryModule
---@class LRClient.InventoryModule : LRClient.ModuleInstance
local instance = {}

function instance:GetCount()
  return 10
end
```

Module sử dụng phải khai báo dependency:

```lua
LR.Modules:Register({
  id = "shop",
  start = "resource",
  dependencies = { "inventory" },

  ---@param context LRClient.ModuleContext
  create = function(context)
    ---@class LRClient.ModuleMap
    ---@field shop LRClient.ShopModule
    ---@class LRClient.ShopModule : LRClient.ModuleInstance
    local instance = {}

    ---@param startContext LRClient.ModuleContext
    function instance:Start(startContext)
      local count = startContext.modules.inventory:GetCount()
      startContext.logger:Info("inventory count=%d", count)
    end

    return instance
  end,
})
```

`startContext.modules.inventory` chỉ trả module đã vào trạng thái ready. Gán field vào
module map sẽ bị từ chối vì map là read-only.

### 6.2 Dynamic lookup

Khi ID chỉ biết ở runtime:

```lua
---@type LRClient.InventoryModule
local Inventory = startContext:GetModule(moduleId)
Inventory:Refresh()
```

LuaLS không thể ánh xạ arbitrary string sang class, vì vậy lookup động cần annotation.
Với ID cố định, luôn ưu tiên `startContext.modules.inventory`.

### 6.3 Dependency là bắt buộc về mặt kiến trúc

Module map không tự kiểm tra caller đã khai báo dependency hay chưa. Một module có thể
tình cờ gọi được module cùng phase, nhưng sẽ hỏng khi module kia bị disable hoặc đổi
phase. Luôn thêm ID được gọi vào `dependencies`.

## 7. Shared/client/server composition

Shared và side có thể đăng ký cùng ID:

```text
shared/modules/inventory.lua
client/modules/inventory.lua
server/modules/inventory.lua
```

Runtime compose theo thứ tự:

| Operation | Thứ tự |
|---|---|
| `create` | shared trước, side sau |
| `OnReady` | shared trước, side sau |
| `Start` | shared trước, side sau |
| `Stop` | side trước, shared sau |

Custom methods của mỗi part được forward vào composed module và bind đúng part owner:

```lua
-- client/modules/inventory.lua
local isOpen = false

function instance:Open()
  isOpen = true
end

-- module khác
startContext.modules.inventory:Open()
```

Hai part không được expose custom method trùng tên. Runtime sẽ fail startup với lỗi
`duplicate method <name>` thay vì override âm thầm. Non-function fields không được
forward; expose state qua methods.

Composer chụp danh sách own function fields ngay sau khi `create` trả instance. Vì vậy
mọi custom method phải được định nghĩa trước `return instance`; method thêm trong
`OnReady`, thêm sau đó hoặc chỉ tồn tại qua metatable sẽ không được forward.

Runtime union methods của shared và side part, nhưng LuaLS không tự hợp nhất hai class.
Side `ModuleMap` phải khai báo class chứa mọi method mà side consumer sẽ gọi. Nếu shared
part có `GetSharedValue()`, hãy khai báo method đó trên side-facing composite class hoặc
interface dùng trong `LRClient.ModuleMap`/`LRServer.ModuleMap`.

Shared và side part cùng ID phải có cùng `start` phase. Dependencies của hai part được
merge và loại trùng.

## 8. Config và start phase

### 8.1 Bật/tắt module

```lua
Config.Modules = {
  inventory = true,
  shop = { enabled = true },
  debug_tools = false,
  old_feature = { enabled = false },
}
```

| Entry | Kết quả |
|---|---|
| Không có entry | Enabled |
| `true` | Enabled |
| `false` | Disabled |
| `{ enabled = true }` | Enabled |
| `{ enabled = false }` | Disabled |

`Config.Modules` không phải allowlist; module không được liệt kê vẫn enabled. Nếu module
enabled phụ thuộc module disabled, startup fail `Missing dependency`.

### 8.2 `resource` và `player`

```lua
start = "resource" -- chạy ngay khi application boot
start = "player"   -- chờ application readiness provider
```

Default standalone readiness provider đã ready ngay. Standard boot tự inject readiness từ
built-in ESX/QBCore/Qbox bridge khi `Config.Framework.Name` chọn framework. Xem phần 12.

Resource module không được depend vào player module. Player module được depend resource
hoặc player module.

### 8.3 Các config hiện có

```lua
Config = {
  Locale = "vi",
  Debug = false,
  Dev = false,
  Framework = { Name = "qbx" },
  Modules = { main = false, trucker = true },
  Job = { RequiredName = "", RequireOnDuty = false },
  NPC = { coords = vector4(...), model = "s_m_m_dockwork_01" },
  ReturnPoint = vector4(...),
  Market = { Items = { ... } },
}

Config.Routes = { ... }
```

`Config.Debug` bật log `Debug`. `Config.Framework.Name` nhận `standalone`, `auto`, `esx`,
`qbcore` hoặc `qbx`; `qbox` là alias của `qbx`. `Config.Dev` bật dữ liệu hỗ trợ phát triển.
Trucker config chỉ giữ job gate, NPC, điểm trả xe, hàng hóa và route content. Luồng đơn
một người, quy đổi kiện, tiền công, progression và thông số kỹ thuật được chốt trong module.

## 9. Logger

Module dùng `context.logger`; không cần tự tạo prefix.

| API | Kết quả |
|---|---|
| `Debug(message, ...)` | Log khi debug được bật |
| `Info(message, ...)` | Log INFO |
| `Warn(message, ...)` | Log WARN |
| `Error(message, ...)` | Log ERROR |
| `Child(scope)` | Tạo logger con |
| `Format(level, message, ...)` | Trả formatted string |
| `Write(level, message, ...)` | Ghi custom level |

Ví dụ:

```lua
context.logger:Debug("loaded item %s", itemId)
context.logger:Info("loaded %d items", #items)
context.logger:Warn("item %s is deprecated", itemId)
context.logger:Error("failed to save player %d", playerSource)

local databaseLogger = context.logger:Child("database")
databaseLogger:Info("connected")
```

Output:

```text
[INFO] [lr.client:inventory] loaded 10 items
[INFO] [lr.client:inventory:database] connected
```

`string.format` được dùng cho placeholders. Nếu format sai, logger fallback về message
gốc thay vì crash vì formatting.

## 10. DisposableStack

Mọi subscription, handler, timer hoặc export registration phải được đưa vào
`context.disposables`.

### 10.1 `Add`

```lua
local dispose = Nui.events.selected:On(function(payload)
  context.logger:Debug("selected %s", payload.id)
end)

context.disposables:Add(dispose)
```

`Add` nhận:

```lua
fun()
{ Dispose = function(self) end }
{ Stop = function(self) end }
nil
```

### 10.2 Cleanup tự viết

```lua
local active = true

context.disposables:Add(function()
  active = false
end)
```

### 10.3 Quy tắc dispose

| Hành vi | Mô tả |
|---|---|
| Order | LIFO |
| Repeated `DisposeAll` | No-op |
| Nhiều lỗi | Tiếp tục cleanup, throw lỗi đầu tiên sau cùng |
| Add sau dispose | Error |
| Table có cả `Dispose` và `Stop` | Ưu tiên `Dispose` |

Application gọi `instance:Stop(context)` trước rồi mới `context.disposables:DisposeAll()`.

## 11. Scheduler

| API | Signature |
|---|---|
| `Delay` | `Delay(milliseconds, callback) -> timer|nil` |
| `Cancel` | `Cancel(timer)` |

Ví dụ:

```lua
local timer = context.scheduler:Delay(1000, function()
  context.logger:Info("one second elapsed")
end)

context.disposables:Add(function()
  context.scheduler:Cancel(timer)
end)
```

Scheduler mặc định chạy callback đồng bộ nếu không được inject `SetTimeout`. Để dùng
FiveM timers thực sự:

```lua
local scheduler = LR.Scheduler:new({
  setTimeout = SetTimeout,
  clearTimeout = ClearTimeout,
})

local app = LR.CreateClientApplication({
  services = {
    scheduler = scheduler,
  },
})
```

Đây là application-level setup trong `client/boot.lua`; không tạo scheduler riêng trong
từng module. `CreateClientApplication`/`CreateServerApplication` hiện nhận custom
scheduler/readiness qua `services`, không forward top-level `scheduler` hoặc `readiness`.

## 12. Readiness provider và built-in framework bridge

### 12.1 Readiness API

```lua
local readiness = LR.StandaloneReadinessProvider:new({ ready = false })

readiness:IsReady()
local cancel = readiness:WhenReady(function()
  print("ready")
end)
readiness:MarkReady()
cancel()
```

| API | Ý nghĩa |
|---|---|
| `IsReady()` | Trả trạng thái hiện tại |
| `WhenReady(callback)` | Chạy ngay nếu ready hoặc queue callback; trả disposer |
| `MarkReady()` | Chuyển ready một lần và chạy callbacks |

Readiness này gate module `start = "player"`. Nó khác hoàn toàn NUI browser handshake.

### 12.2 Chọn framework

```lua
Config.Framework = {
  Name = "qbx", -- standalone | auto | esx | qbcore | qbx
  -- Resource = "renamed_qbx_core", -- chỉ cần khi resource bị đổi tên
}
```

| Name | Resource chuẩn | Readiness client |
|---|---|---|
| `standalone` | không có | Ready ngay |
| `esx` | `es_extended` | ESX player data đã load |
| `qbcore` | `qb-core` | QBCore player data đã load |
| `qbx` | `qbx_core` | Qbox player data đã load |
| `auto` | detect | 0 match dùng standalone, 1 match chọn framework, nhiều match fail |

Explicit selection fail nếu resource chưa `started` hoặc required export không tồn tại.
Đặt framework trước resource này trong `server.cfg`. `auto` không phù hợp khi Qbox và
QBCore compatibility resource cùng chạy; khi đó chọn explicit. Manifest không hard-depend
framework nào và core vẫn chạy standalone.

### 12.3 Client framework bridge

Standard boot inject typed service tại `context.services.framework`:

```lua
---@param context LRClient.ModuleContext
local function start(context)
  local framework = context.services.framework
  if not framework then error("framework service is unavailable") end
  local player = framework:GetPlayerData()

  if player and player.job then
    context.logger:Info("job=%s grade=%s", player.job.name, player.job.grade)
  end

  context.disposables:Add(framework:OnPlayerDataChanged(function(nextPlayer, key)
    context.logger:Debug("player data changed: %s", key or "unknown")
  end))

  framework:Notify({message = "Ready", type = "success", duration = 3000})
end
```

Client API gồm `GetPlayerData()`, `IsPlayerLoaded()`, `Notify()`, `OnPlayerLoaded()`,
`OnPlayerUnloaded()` và `OnPlayerDataChanged()`. Mỗi subscription trả disposer. Bridge
chỉ trả normalized plain DTO, không trả raw ESX/QBCore/Qbox object.

### 12.4 Server framework bridge

```lua
---@param context LRServer.ModuleContext
local function authorize(context, playerSource)
  local framework = context.services.framework
  if not framework then error("framework service is unavailable") end
  local player = framework:GetPlayer(playerSource)
  return player ~= nil and player.job ~= nil and player.job.name == "police"
end
```

Server API gồm `GetPlayer(source)`, `IsPlayerLoaded(source)`, `Notify(source, options)` và
ba lifecycle subscriptions tương ứng. Server readiness chỉ xác nhận framework API đã
acquire, không biểu diễn per-player state. Luôn lookup theo transport-provided `source`.

Framework lifecycle events chỉ là readiness/change hint, không phải authorization.
Client DTO vẫn untrusted; server mutation phải kiểm tra permission, ownership, distance,
bounds, world state và replay risk. Readiness là one-way nên logout không tự stop player
modules đã chạy; dùng `OnPlayerUnloaded()` để clear character state. Xem đầy đủ tại
[Framework bridges](./FRAMEWORK_BRIDGES.md).

## 13. Locale và thời gian

### 13.1 Tạo locale

```lua
-- locales/lang/vi.lua
Locales["vi"] = {
  ["inventory_opened"] = "Đã mở kho đồ",
  ["item_count"] = "Có %d vật phẩm",
  ["hello_player"] = "Xin chào :{name}",
}
```

### 13.2 `SetLocale`

```lua
Config.Settings.locale = SetLocale("vi")
```

Nếu locale không tồn tại, runtime fallback `Locales.default`, sau đó fallback `{}`.

### 13.3 `L`

```lua
L("inventory_opened")
L("item_count", 10)
L("hello_player", { name = "Lorraxs" })
```

Key không tồn tại trả chính key đó.

### 13.4 `Ms`

```lua
Ms.parse("500ms") -- 500
Ms.parse("5s")    -- 5000
Ms.parse("2m")    -- 120000
Ms.parse("1h")    -- 3600000
Ms.parse("1d")    -- 86400000

Ms.tostring(500)   -- "500ms"
Ms.tostring(60000) -- "1m"
```

`Ms.tostring` làm tròn và dùng unit lớn nhất, không dùng để serialize duration cần độ
chính xác tuyệt đối.

## 14. Contract TypeBox

### 14.1 Tạo contract

```ts
// packages/contracts/src/authoring/inventory/inventory.schemas.ts
import Type from 'typebox';

export const EmptySchema = Type.Object({});
export const InventoryItemSchema = Type.Object({
  id: Type.String({minLength: 1, maxLength: 64}),
  label: Type.String({minLength: 1, maxLength: 128}),
  count: Type.Integer({minimum: 0}),
});
export const InventorySnapshotSchema = Type.Object({
  items: Type.Array(InventoryItemSchema, {maxItems: 200}),
});
export const InventoryFiltersSchema = Type.Object({
  search: Type.String({maxLength: 64}),
});
```

Khai báo riêng ba sibling module boundaries và combined constant:

```ts
// packages/contracts/src/authoring/inventory/inventory.boundaries.ts
import Type from 'typebox';
import {rpc, type ModuleBoundaries} from '../../index';
import {EmptySchema, InventorySnapshotSchema} from './inventory.schemas';

export const inventoryNuiBoundary = {
  events: {
    toNui: {
      toast: Type.Object({message: Type.String({maxLength: 256})}),
    },
    toClient: {
      selected: Type.Object({id: Type.String({minLength: 1, maxLength: 64})}),
    },
  },
  rpc: {
    toNui: {
      confirm: rpc(
        Type.Object({message: Type.String({maxLength: 256})}),
        Type.Object({accepted: Type.Boolean()})
      ),
    },
    toClient: {
      close: rpc(EmptySchema, EmptySchema),
    },
  },
} as const satisfies ModuleBoundaries['nui'];

export const inventoryNetworkBoundary = {
  events: {
    clientToServer: {},
    serverToClient: {
      notification: Type.Object({message: Type.String({maxLength: 256})}),
    },
  },
  rpc: {
    clientToServer: {
      moveItem: rpc(
        Type.Object({
          itemId: Type.String({minLength: 1, maxLength: 64}),
          amount: Type.Integer({minimum: 1, maximum: 100}),
        }),
        InventorySnapshotSchema,
        {
          mutating: true,
          rateLimit: {requestsPerSecond: 5, burst: 10},
        }
      ),
    },
    serverToClient: {},
  },
} as const satisfies ModuleBoundaries['net'];

export const inventoryExportBoundary = {
  client: {
    getSnapshot: rpc(EmptySchema, InventorySnapshotSchema),
  },
  server: {
    getSnapshot: rpc(EmptySchema, InventorySnapshotSchema),
  },
} as const satisfies ModuleBoundaries['exports'];

export const inventoryBoundaries = {
  nui: inventoryNuiBoundary,
  net: inventoryNetworkBoundary,
  exports: inventoryExportBoundary,
} as const satisfies ModuleBoundaries;
```

Tạo public per-module entrypoint chỉ export schemas, rồi đăng ký combined boundaries độc
lập với store trong internal root index:

```ts
// packages/contracts/src/authoring/inventory/index.ts
export * from './inventory.schemas.ts';

// packages/contracts/src/authoring/index.ts
import {inventoryBoundaries} from './inventory/inventory.boundaries';

export const moduleBoundaries = Object.freeze({
  inventory: inventoryBoundaries,
});
```

Store chuẩn dùng `@Store({id: 'inventory'})` và `@State(schema, default)` accessors. Store
chỉ import state schemas qua specific module subpath:

```ts
// web/src/app/modules/inventory/inventory.store.ts
import {State, Store} from '@lr/nui-store';
import type {ContractStatic} from '@lr/contracts';
import {
  InventoryFiltersSchema,
  InventorySnapshotSchema,
} from '@lr/contracts/authoring/inventory';

@Store({id: 'inventory'})
export class InventoryStore {
  @State(InventorySnapshotSchema, {items: []})
  accessor snapshot!: ContractStatic<typeof InventorySnapshotSchema>;

  @State(InventoryFiltersSchema, {search: ''})
  accessor filters!: ContractStatic<typeof InventoryFiltersSchema>;
}
```

Web store chỉ dùng public `@lr/contracts/authoring/<module_id>` subpath. Per-module
`index.ts` chỉ export schemas; boundary files, direct schema-file paths và root authoring
index không được package-export cho browser. Điều này giữ net/exports khỏi browser bundle.

State không có owner; hai accessors trên đều có thể được Lua hoặc NUI ghi. Chỉ accessor
có `@State` mới là boundary state. Computed getter và method thường vẫn có thể đặt trong
store mà không trở thành contract.

Đăng ký store tường minh:

```ts
// web/src/app/modules/registry.ts
import {MainStore} from './main/main.store';
import {TruckerStore} from './trucker/trucker.store';

export const storeModules = {
  main: MainStore,
  trucker: TruckerStore,
} as const;
```

Registry key phải trùng `@Store` ID. Mỗi ID trong `storeModules` phải có đúng một entry
cùng ID trong `moduleBoundaries`, và boundary registry không được có ID thiếu store. Sau
đó generate:

```powershell
pnpm generate:contracts
pnpm check:contracts
```

Không chỉnh tay `packages/contracts/src/modules/`, `shared/generated/`,
`client/generated/`, `server/generated/`, `types/*/generated/`, `web/src/generated/` hoặc
`docs/generated/`. Commit canonical schema, boundary, store, cả hai registry và generated
outputs cùng nhau.

### 14.2 Contract DSL

| API | Dùng để làm gì |
|---|---|
| `@Store({id: 'inventory'})` | Khai báo ID cho decorated state store |
| `@State(schema, default)` | Khai báo synchronized accessor và MobX observable |
| `ContractStatic<typeof Schema>` | Suy ra TypeScript value type từ TypeBox schema |
| `rpc(request, response, options?)` | Khai báo request/response endpoint |
| `compileValidator(schema)` | Compile validator TypeScript |
| `validateModuleContract(contract)` | Trả danh sách validation errors |
| `assertSupportedSchema(schema)` | Reject schema ngoài supported subset |

RPC options:

```ts
rpc(Request, Response, {
  timeoutMs: 10_000,
  mutating: true,
  rateLimit: {
    requestsPerSecond: 5,
    burst: 10,
  },
});
```

Supported schema types là `object`, `array`, `boolean`, `integer`, `number`, `null` và
`string`. Object schemas được đóng mặc định (`additionalProperties: false`). Tránh
recursive schema, class instance, function, userdata, vector, `Date`, `BigInt`, transform
và schema keywords ngoài supported subset.

Optional và explicit null khác nhau trong Lua:

```lua
local optionalDto = {
  -- Bỏ key bằng nil nghĩa là property không tồn tại.
}

local nullableDto = {
  value = LR.JSON_NULL, -- JSON null tường minh cho required nullable field.
}
```

Không dùng `nil` cho required nullable property vì Lua sẽ xóa key. Generated nullable
LuaLS types hiện chưa mô tả sentinel hoàn hảo; kiểm tra contract tests và QA CEF/FiveM
khi dùng explicit null.

### 14.3 Direction table

| Contract | Lua side | NUI/server side |
|---|---|---|
| synchronized `@State` | `Get/Set/Watch`, object có `Patch` | `get/set/subscribe`, object có `patch` |
| `nui.events.toNui` | Lua `Emit` | NUI `subscribe` |
| `nui.events.toClient` | Lua `On` | NUI `emit` |
| `nui.rpc.toNui` | Lua `Call` | NUI `handle` |
| `nui.rpc.toClient` | Lua `Handle` | NUI `call` |
| `net.events.clientToServer` | Client `Emit` | Server `Handle` |
| `net.events.serverToClient` | Client `On` | Server `Emit` |
| `net.rpc.clientToServer` | Client `Call` | Server `Handle` |
| `net.rpc.serverToClient` | Client `Handle` | Server `Call` |
| `exports.client/server` | Provider `Register` | Consumer `External` |

Lua bridge là canonical revision sequencer của từng state. Lua write và NUI write dùng
cùng commit path; write hợp lệ được bridge chấp nhận sau cùng thắng. Browser không tự cấp
revision.

### 14.4 Local UI state và boundary state

Chỉ dùng `@State` khi Lua và NUI thực sự cần chia sẻ giá trị. Tab tạm, hover, input draft,
modal local và UI-only error dùng React `useState` hoặc MobX field không decorate. Đưa
mọi UI-only state vào contract làm tăng boundary, validation, generated API và traffic
không cần thiết.

## 15. NUI từ Lua client

Lấy generated facade:

```lua
local Nui = startContext.nui.Trucker()
-- Hoặc global service:
local Nui = LR.Nui.Trucker()
```

Ưu tiên context trong module để dependency rõ ràng và dễ test.

### 15.1 State API

| API | Ý nghĩa |
|---|---|
| `Get()` | Lấy clone của synchronized state hiện tại |
| `Watch(callback)` | Theo dõi mọi accepted write; trả disposer |
| `Set(value)` | Validate và thay toàn bộ state |
| `Patch(partial)` | Validate và shallow-patch object state |

State không có owner. Lua có thể write mọi generated state:

```lua
local Nui = startContext.nui.Trucker()

Nui.state.visibility:Set({ visible = true })

Nui.state.visibility:Patch({ visible = false })

local visibility = Nui.state.visibility:Get()

local disposeVisibility = Nui.state.visibility:Watch(function(value, previous)
  startContext.logger:Debug(
    "visible=%s previous=%s",
    tostring(value.visible),
    tostring(previous and previous.visible)
  )
end)

startContext.disposables:Add(disposeVisibility)
```

`Set`/`Patch` trả `true` khi value thay đổi và `false` khi candidate bằng canonical value.
Watchers chạy cho cả Lua writes và browser writes đã được bridge chấp nhận. Lua bridge
validate, deep-clone, tăng canonical revision rồi phát full snapshot. Lua và browser dùng
cùng sequencer; write hợp lệ được xử lý sau cùng thắng.

### 15.2 Event API

Lua gửi event sang NUI:

```lua
local sent = Nui.events.toast:Emit({
  level = "success",
  message = "Saved",
})

if not sent then
  startContext.logger:Warn("NUI chưa ready; event đã bị drop")
end
```

Lua nhận event từ NUI:

```lua
startContext.disposables:Add(
  Nui.events.selected:On(function(payload)
    startContext.logger:Info("selected=%s", payload.id)
  end)
)
```

Event là fire-and-forget. Dùng RPC nếu cần response.

### 15.3 RPC API

Lua gọi NUI đồng bộ:

```lua
local result = Nui.rpc.confirm:Call({
  message = "Continue?",
})

if result.accepted then
  startContext.logger:Info("accepted")
end
```

Runtime core hỗ trợ callback form, nhưng generated endpoint declarations hiện chỉ expose
sync `Call(request) -> response`. Module typesafe nên dùng sync form ở trên cho đến khi
generator bổ sung callback overload.

Lua handle RPC từ NUI:

```lua
startContext.disposables:Add(
  Nui.rpc.close:Handle(function(_request)
    SetNuiFocus(false, false)
    Nui.state.visibility:Set({ visible = false })
    return {}
  end)
)
```

Mỗi incoming RPC endpoint chỉ có một handler.

### 15.4 NUI readiness

Trước browser handshake:

| Operation | Behavior |
|---|---|
| Lua synchronized state write | Commit canonical; queue/coalesce full snapshot mới nhất |
| Event Lua -> NUI | Drop và trả `false` |
| RPC Lua -> NUI | Fail `NUI_NOT_READY` |

NUI handshake dùng endpoint `lr_bridge` và protocol version 2. Browser gửi
`core/event/ready` cùng `sessionId`; Lua ACK, gửi full initial `state.snapshot` messages,
rồi gửi `core/event/synced` cùng session. `NuiRuntime.ready()` và `AppRuntime.start()` chỉ
resolve sau barrier đó. Module không tự gọi `MarkReady()`.

Browser `state.set`/`state.patch` commands có `requestId` và `sessionId`, không có
revision. Lua response chứa full canonical value và revision; Lua outbound state update
luôn là full `state.snapshot`, không phát partial patch.

Khi một native như focus chỉ hợp lệ sau khi browser đã load, dùng readiness callback:

```lua
startContext.disposables:Add(
  startContext.nui:WhenReady(function()
    SetNuiFocus(true, true)
  end)
)
```

`IsReady()` trả trạng thái handshake hiện tại. `WhenReady()` chạy callback ngay nếu đã
ready, hoặc queue đến sau khi snapshots và `core.synced` được gửi.

## 16. NUI từ React/TypeScript

UI application bình thường dùng store class đã khai báo contract. `AppRuntime` tạo mọi
store trong `storeModules`, bind `@State` accessors với MobX và low-level NUI facade tự
động.

### 16.1 Decorated store và assignment

Trong React component, lấy store typed qua context:

```ts
import {observer} from 'mobx-react-lite';
import {useAppRuntime, useStore} from '@/app/runtimeContext';

export const VisibilityButton = observer(() => {
  const runtime = useAppRuntime();
  const trucker = useStore('trucker');

  const toggleVisibility = () => {
    trucker.visibility = {visible: !trucker.visibility.visible};
  };

  const saveAndWait = async () => {
    trucker.visibility = {visible: true};
    await runtime.flush();
  };

  return <button onClick={toggleVisibility}>{String(trucker.visibility.visible)}</button>;
});
```

Assignment update MobX state optimistic ngay và browser serialize writes theo từng state.
`@State` validate assignment trước khi setter hoàn tất; value sai schema throw `TypeError`
đồng bộ. ACK/full snapshot từ Lua reconcile canonical state và các optimistic writes còn
pending. Transport failure là bất đồng bộ và đi qua `onError`; `flush()` chỉ là optional
barrier chờ pending assignments settle, không cần gọi sau mỗi assignment.

Store fields không decorate và React `useState` vẫn local. Dùng chúng cho tab, hover,
draft hoặc modal chỉ tồn tại trong UI.

### 16.2 Low-level state facade

Code hạ tầng hoặc trường hợp cần `patch`/subscription trực tiếp có thể dùng typed facade:

```ts
const trucker = appRuntime.nui.nui.trucker;
const current = trucker.state.snapshot.get();

const subscription = trucker.state.snapshot.subscribe(snapshot => {
  console.log(snapshot.player.name, snapshot.orderPage.items.length);
});

const replaced = await trucker.state.visibility.set({visible: true});
const patched = await trucker.state.visibility.patch({visible: false});

subscription.dispose();
```

`set` và object-only `patch` trả `Promise<boolean>`, áp optimistic state ngay và dùng cùng
serialized command queue như decorated assignment. Invalid low-level payload trả `false`;
transport error reject promise và được báo qua runtime `onError`. Normal component không
cần tự subscribe vì MobX binding đã làm việc đó.

### 16.3 Events

Nhận event Lua -> NUI:

```ts
const refreshedSubscription = inventory.events.refreshed.subscribe(payload => {
  console.log(payload.items.length);
});
```

Gửi event NUI -> Lua:

```ts
await inventory.events.selected.emit({id: 'water'});
```

### 16.4 RPC

NUI gọi Lua:

```ts
await trucker.rpc.close.call({});
const result = await trucker.rpc.refresh.call({});
```

NUI handle RPC từ Lua:

```ts
const confirmSubscription = inventory.rpc.confirm.handle(async request => {
  return {
    accepted: window.confirm(request.message),
  };
});

confirmSubscription.dispose();
```

### 16.5 Runtime lifecycle

```ts
import {createAppRuntime} from '@/app/runtime';

const appRuntime = createAppRuntime({
  onError(error) {
    console.error(error.code, error.message, error.details);
  },
});

await appRuntime.start();
appRuntime.stores.trucker.visibility = {visible: true};
await appRuntime.flush();
appRuntime.dispose();
```

Không cần truyền `resourceName`; runtime tự dùng `window.GetParentResourceName()` trong
FiveM và fallback an toàn trong browser preview. `start()` chỉ resolve sau ACK
`core.ready`, full initial snapshots và same-session `core.synced`.

`NuiRuntimeError.code` có thể là:

```text
invalid_envelope
invalid_payload
invalid_response
rpc_failed
subscriber_failed
timeout
disposed
```

### 16.6 Browser mock

```ts
const runtime = createNuiRuntime({
  browserMock: {
    rpc: {
      trucker: {
        close: async () => ({success: true, message: ''}),
        refresh: async () => ({success: true, message: 'Refreshed'}),
      },
    },
    boot(dispatch) {
      dispatch({
        version: 2,
        module: 'trucker',
        kind: 'state.snapshot',
        name: 'visibility',
        revision: 1,
        payload: {visible: true},
      });
    },
  },
});

await runtime.startBrowserMock();
await runtime.ready();
```

### 16.7 AppRuntime của template

Template bọc raw `NuiRuntime` bằng `AppRuntime` để compose MobX stores:

```ts
import {createAppRuntime} from '@/app/runtime';

const appRuntime = createAppRuntime({
  isBrowser: false,
  onError(error) {
    console.error(error.code, error.message);
  },
});

await appRuntime.start();

appRuntime.isBrowser;
appRuntime.stores.trucker.snapshot;
appRuntime.nui.nui.trucker;
appRuntime.storeStatus;

appRuntime.stores.trucker.visibility = {visible: true};
await appRuntime.flush();

appRuntime.dispose();
```

| Field/API | Ý nghĩa |
|---|---|
| `nui` | Raw typed `NuiRuntime` |
| `stores` | Typed instances từ explicit `storeModules` registry |
| `isBrowser` | Browser preview hay FiveM NUI |
| `storeStatus` | `idle`, `pending` hoặc `disposed` |
| `start()` | Start browser mock nếu có, sau đó protocol-v2 ready/synced handshake |
| `flush()` | Chờ decorated assignments đang pending settle |
| `dispose()` | Dispose subscriptions và NUI runtime |

Normal UI dùng `appRuntime.stores.trucker`. Raw `NuiRuntime` dùng
`nuiRuntime.nui.trucker`; low-level facade qua AppRuntime là
`appRuntime.nui.nui.trucker`.

## 17. Client/server network

Feature module chỉ dùng generated facade. Không gọi raw `TriggerServerEvent`,
`RegisterNetEvent` hoặc tự đặt event string.

Mỗi module network facade tách endpoint thành `events` và `rpc`. Vì hai namespace độc
lập, một event và một RPC có thể dùng cùng member name.

### 17.1 Client gọi server RPC

Contract trucker có RPC `getState`:

```lua
local snapshot = startContext.net.Trucker.rpc.getState:Call({})

startContext.logger:Info("orders=%d", #snapshot.orderPage.items)
```

Runtime transport hỗ trợ callback form, nhưng generated endpoint declarations hiện chỉ
expose sync `Call(request) -> response`. Module typesafe nên dùng sync form ở trên.

### 17.2 Server handle client RPC

```lua
startContext.disposables:Add(
  startContext.net.Trucker.rpc.getState:Handle(function(playerSource, _request)
    return startContext.modules.trucker:GetSnapshot(playerSource)
  end)
)
```

RPC có `mutating: true` bắt buộc `Authorize` và `Execute`. Không tin `source` từ payload;
transport truyền `playerSource` thật vào handler.

### 17.3 Server gửi event cho client

```lua
startContext.net.Trucker.events.notice:Emit(playerSource, {
  type = "success",
  message = "Saved",
})
```

Truyền target `-1` để broadcast một server-to-client event tới tất cả player:

```lua
startContext.net.Trucker.events.notice:Emit(-1, {
  type = "warning",
  message = "Server restart in 5 minutes",
})
```

`-1` chỉ hợp lệ với server-to-client event `Emit`. Server-to-client RPC `Call` luôn cần
một `playerSource` dương vì RPC phải nhận đúng một response.

Client nhận:

```lua
startContext.disposables:Add(
  startContext.net.Trucker.events.notice:On(function(payload)
    startContext.logger:Info("notice=%s", payload.message)
  end)
)
```

### 17.4 Các direction còn lại

Nếu contract có `clientToServer` event:

```lua
-- client
startContext.net.Inventory.events.selected:Emit({id = "water"})

-- server
startContext.disposables:Add(
  startContext.net.Inventory.events.selected:Handle(function(playerSource, payload)
    print(playerSource, payload.id)
  end)
)
```

Nếu contract có `serverToClient` RPC:

```lua
-- client handler
startContext.disposables:Add(
  startContext.net.Inventory.rpc.confirm:Handle(function(request)
    return {accepted = true}
  end)
)

-- server caller
local result = startContext.net.Inventory.rpc.confirm:Call(playerSource, {
  message = "Continue?",
})
```

Các accessor trên chỉ tồn tại sau khi endpoint tương ứng được thêm vào contract và chạy
`pnpm generate:contracts`.

## 18. Public và External API

Public/External dùng cho resource-to-resource call trên cùng side. Client export chỉ gọi
được từ client resource khác; server export chỉ gọi được từ server resource khác.

### 18.1 Provider non-mutating

```lua
startContext.disposables:Add(
  startContext.public.Trucker:Register({
    open = function(_request)
      return { success = true, message = "Opened" }
    end,
    getSnapshot = function(_request)
      return startContext.modules.trucker:GetSnapshot()
    end,
  })
)
```

### 18.2 Consumer

```lua
local external = startContext.external.Trucker("other_resource")
local snapshot = external:GetSnapshot({})

startContext.logger:Info("external orders=%d", #snapshot.orderPage.items)
```

Generated consumer method dùng PascalCase: contract `getSnapshot` thành `GetSnapshot`.
Raw export name là `trucker_getSnapshot`, nhưng module không gọi raw export trực tiếp.

### 18.3 Mutating export

Giả sử contract export có `mutating: true`:

```lua
startContext.disposables:Add(
  startContext.public.Inventory:Register({
    setBalance = {
      Authorize = function(invokingResource, request)
        return invokingResource == "trusted_resource"
          and request.amount >= 0
      end,

      Execute = function(invokingResource, request)
        startContext.logger:Info(
          "%s set balance to %d",
          invokingResource,
          request.amount
        )

        return {ok = true}
      end,
    },
  })
)
```

Public payload request và response đều được validate. Export runtime không áp timeout
hoặc rate limit metadata; đây là synchronous FiveM export.

### 18.4 Nội bộ và external khác nhau

| Nhu cầu | API đúng |
|---|---|
| Module cùng application | `startContext.modules.inventory:Method()` |
| Module ID runtime | `startContext:GetModule(id)` |
| Resource khác cùng side | `startContext.external.Inventory(resource)` |
| Client gọi server | `startContext.net.Inventory.rpc.<name>:Call(...)` |
| Lua gọi browser | `startContext.nui.Inventory().rpc...` |

## 19. Application và service API

Module author thường chỉ dùng `context.app` để lookup hoặc kiểm tra service. Các API:

| API | Ý nghĩa |
|---|---|
| `RegisterModule(descriptor)` | Register trước khi app start |
| `RegisterService(name, service)` | Thêm application service |
| `RegisterGlobalService(name, globalName, service)` | Thêm service và bind `LR[globalName]` |
| `GetService(name)` | Lấy service |
| `HasService(name)` | Kiểm tra service |
| `GetModule(id)` | Lấy module active |
| `Start()` | Start application một lần |
| `StartPlayerModules()` | Start player phase |
| `Stop()` | Stop và cleanup |
| `IsStopped()` | Kiểm tra trạng thái |

Ví dụ đọc custom service:

```lua
if context.app:HasService("database") then
  local database = context.app:GetService("database")
  -- Annotate custom service type trước khi dùng.
end
```

Các hàm sau là orchestration nội bộ, feature module không gọi:

```text
CreateModuleContext
CreateModule
ReadyModule
StartModule
StartMatchingModules
DisposeServices
ClearGlobalService
```

## 20. Validation, timeout và giới hạn

| Boundary | Max payload | Timeout mặc định | Timeout tối đa |
|---|---:|---:|---:|
| Lua client <-> NUI | 256 KiB | 5 giây | 60 giây |
| Client <-> server Net | 128 KiB | 10 giây | 30 giây |
| Public exports | 128 KiB request/response | Không có | Không có |

Server network có thêm:

| Protection | Mặc định |
|---|---|
| Coarse ingress | 50 request/s, burst 100 |
| Endpoint bucket | 10 request/s, burst 20 |
| Replay TTL | 30 giây |
| Mutating RPC | Bắt buộc authorization |

Nguyên tắc:

- Payload luôn được validate trước handler.
- RPC response được validate trước khi trả caller.
- Không lấy player identity từ request DTO.
- Không tăng payload/rate limit constructor options trong feature module.
- Event chỉ dùng cho thông báo không cần kết quả.
- Mutation từ client phải đi qua server RPC có `Authorize`.
- Synchronized NUI state là browser-writable và không đáng tin; store assignment/Watch
  không thay thế server authorization.

## 21. Quy trình phát triển

### 21.1 Khi chỉ sửa Lua

```powershell
pnpm test:lua
pnpm check:luals
```

Sau đó restart resource.

### 21.2 Khi sửa decorated store hoặc boundary contract

```powershell
pnpm generate:contracts
pnpm check:contracts
pnpm test:nui-store
pnpm typecheck
pnpm test:lua
pnpm --filter web test
```

Sửa canonical schemas/boundaries và `moduleBoundaries` dưới
`packages/contracts/src/authoring/`, decorated store và `storeModules` dưới
`web/src/app/modules/`. Giữ one-to-one parity giữa hai registry. Commit generated files
cùng canonical source; không sửa `packages/contracts/src/modules/`.

### 21.3 Khi sửa NUI

Browser development:

```powershell
pnpm --dir web dev
```

Build watch cho FiveM:

```powershell
pnpm --dir web start:game
```

Production build:

```powershell
pnpm --filter web build
```

Output nằm ở `web/build` và được `fxmanifest.lua` load.

### 21.4 Full verification

```powershell
pnpm verify
```

Automated tests không thay thế QA trong FiveM thật cho NUI focus, resource restart,
authorization, malformed traffic và cleanup.

## 22. Ví dụ end-to-end

Phần này dùng contract `trucker` đang chạy trong resource.

### 22.1 Client module

```lua
LR.Modules:Register({
  id = "trucker_consumer",
  start = "resource",
  dependencies = { "trucker" },

  ---@param context LRClient.ModuleContext
  create = function(context)
    ---@class LRClient.ModuleMap
    ---@field trucker_consumer LRClient.TruckerConsumerModule
    ---@class LRClient.TruckerConsumerModule : LRClient.ModuleInstance
    local instance = {}

    ---@param readyContext LRClient.ModuleContext
    function instance:OnReady(readyContext)
      readyContext.logger:Debug("consumer ready")
    end

    ---@param startContext LRClient.ModuleContext
    function instance:Start(startContext)
      local Nui = startContext.nui.Trucker()

      startContext.disposables:Add(
        startContext.net.Trucker.events.notice:On(function(payload)
          startContext.logger:Info("notice=%s", payload.message)
        end)
      )

      local snapshot = startContext.net.Trucker.rpc.getState:Call({})
      Nui.state.snapshot:Set(snapshot)

      startContext.logger:Info("available orders=%d", #snapshot.orderPage.items)
    end

    ---@param stopContext LRClient.ModuleContext
    function instance:Stop(stopContext)
      stopContext.logger:Debug("consumer stopped")
    end

    return instance
  end,
})
```

### 22.2 Server consumer

```lua
LR.Modules:Register({
  id = "trucker_audit",
  start = "resource",
  dependencies = { "trucker" },

  ---@param context LRServer.ModuleContext
  create = function(context)
    ---@class LRServer.ModuleMap
    ---@field trucker_audit LRServer.TruckerAuditModule
    ---@class LRServer.TruckerAuditModule : LRServer.ModuleInstance
    local instance = {}

    ---@param startContext LRServer.ModuleContext
    function instance:Start(startContext)
      local snapshot = startContext.modules.trucker:GetSnapshot(1)
      startContext.logger:Info(
        "audit player=%s orders=%d",
        snapshot.player.name,
        #snapshot.orderPage.items
      )
    end

    return instance
  end,
})
```

Đây là module cùng application nên dùng typed module map. `External` chỉ dành cho
resource khác cùng side.

### 22.3 NUI component logic

```ts
import {observer} from 'mobx-react-lite';
import {useAppRuntime, useStore} from '@/app/runtimeContext';

export const TruckerPanel = observer(() => {
  const runtime = useAppRuntime();
  const trucker = useStore('trucker');
  const Nui = runtime.nui.nui.trucker;

  const refresh = async () => {
    await Nui.rpc.refresh.call({});
  };

  return (
    <div>
      <p>{trucker.snapshot.player.name}: {trucker.snapshot.orderPage.items.length}</p>
      <button
        onClick={() => {
          trucker.visibility = {visible: !trucker.visibility.visible};
        }}
      >
        Toggle visibility
      </button>
      <button onClick={refresh}>Refresh</button>
    </div>
  );
});
```

Component đọc/render state qua decorated store để MobX tự theo dõi. Low-level facade chỉ
còn dùng cho event/RPC. Nếu code hạ tầng lấy facade trực tiếp từ `createNuiRuntime`, đường
dẫn là `runtime.nui.trucker`; qua `useAppRuntime()` là `runtime.nui.nui.trucker`.

## 23. API reference bổ sung

### 23.1 Namespace helpers

| API | Signature | Ghi chú |
|---|---|---|
| `LR.extend` | `(target?, source?) -> table` | Shallow-copy source vào target và mutate target |
| `LR.shallowCopy` | `(source?) -> table` | Tạo shallow copy |
| `LR.assertName` | `(name, label?)` | Bắt buộc non-empty string |
| `LR.VERSION` | `string` | Version runtime |
| `LR.MODULE_ID_PATTERN` | `string` | Regex module ID |

Ví dụ:

```lua
local defaults = {compact = false, page = 1}
local settings = LR.shallowCopy(defaults)
LR.extend(settings, {compact = true})
LR.assertName("inventory", "module name")
```

Các helper này chỉ shallow-copy. Nested tables vẫn dùng chung reference.

### 23.2 Domain OOP với `LR.Class`

`LR.Class` dành cho entity/value-rich domain model bên trong Lua. Mỗi instance chỉ chứa
state; methods, property descriptors và inheritance metadata nằm trên class dùng chung.
Không dùng class instance làm module part hoặc boundary DTO.

Runtime API:

| API | Ý nghĩa |
|---|---|
| `LR.Class:Define(name, base?)` | Tạo class, có thể kế thừa một LR class |
| `Class:Extend(name)` | Tạo subclass |
| `Class:New(input)` | Tạo instance và gọi `init(input)` nếu có |
| `Class:Property(name, options?)` | Khai báo class-level property descriptor |
| `Class:IsSubclassOf(target)` | Kiểm tra class inheritance |
| `instance:IsA(target)` | Kiểm tra instance inheritance |
| `instance:GetClass()` | Lấy concrete class |
| `LR.Class:IsClass(value)` | Kiểm tra class object |
| `LR.Class:IsInstance(value, target)` | Kiểm tra mà không gọi instance method |

Ví dụ typed domain entity:

```lua
---@class LRShared.DeliveryInput
---@field id string
---@field progress number

---@class LRShared.Delivery : LRShared.ClassInstance
---@field id string
---@field progress number

---@class LRShared.DeliveryClass : LRShared.Class<LRShared.Delivery, LRShared.DeliveryInput>
---@field init fun(self: LRShared.Delivery, input: LRShared.DeliveryInput)

---@type LRShared.DeliveryClass
local Delivery = LR.Class:Define("Delivery")

---@type LRShared.ClassProperty<LRShared.Delivery, number>
local ProgressProperty = {
  validate = function(_, value)
    return type(value) == "number", "progress must be a number"
  end,
  set = function(_, value)
    return math.max(0, math.min(100, value))
  end,
}
Delivery:Property("progress", ProgressProperty)

---@param self LRShared.Delivery
---@param input LRShared.DeliveryInput
function Delivery:init(input)
  self.id = input.id
  self.progress = input.progress
end

local delivery = Delivery:New({id = "route_1", progress = 50})
print(delivery:IsA(Delivery), delivery.progress)
```

Hai generic của `LRShared.Class<TInstance, TInit>` liên kết return instance với constructor
input. `New` nhận đúng một input; runtime từ chối nhiều argument. Callable syntax như
`Delivery(...)` cố ý không hỗ trợ vì LuaLS 3.19.1 không validate operator-call arguments đủ
chặt. Companion class khai báo `New` cụ thể giúp LuaLS kiểm tra cả nested fields trong
options DTO mà không cần `@as` cast.

Property assignment chạy theo thứ tự:
`validate input -> set transform -> commit -> afterSet`. Getter nhận backing value hiện
tại. `readonly = true` chặn assignment;
`storage = "_custom"` đổi backing field mặc định `_<property>`.

Không đặt mutable defaults như `{}` trên class vì mọi instance sẽ nhìn cùng reference.
Khởi tạo chúng trong `init`. Gọi parent tĩnh bằng `Base.init(self, ...)`; không dùng
string-based `super`. Với gameplay action, ưu tiên method có nghĩa domain như
`mission:Advance(expectedStep)` thay vì setter chung chung.

Module composer chỉ forward own function fields, vì vậy không trả class instance từ
`create`. Class metatable phù hợp cho `Delivery`, `Mission`, `Team` nội bộ; trước khi qua NUI,
network hoặc export phải chuyển chúng thành schema-backed plain DTO tables. Production
trucker domain được tách đúng ownership:

| Side | Classes | Service |
|---|---|---|
| Server authoritative | [`server/classes/trucker/`](../server/classes/trucker/) | [`server/services/trucker_service.lua`](../server/services/trucker_service.lua) |
| Client projection | [`client/classes/trucker/`](../client/classes/trucker/) | [`client/services/trucker_service.lua`](../client/services/trucker_service.lua) |

Server giữ session, team, order board, entity ownership và payout. Client chỉ giữ world
projection và input flow; không nhận server class instances. Manifest load class/service
files trước composition root trong `modules/*.lua`.

### 23.3 ModuleRegistry

| API | Signature | Dùng khi nào |
|---|---|---|
| `LR.ModuleRegistry:new()` | `() -> registry` | Tạo custom registry cho test/advanced app |
| `ValidateId` | `(id)` | Validate module ID |
| `ValidateDescriptor` | `(descriptor)` | Validate descriptor shape |
| `Register` | `(descriptor) -> normalized` | Đăng ký module |
| `Get` | `(id) -> descriptor|nil` | Lấy descriptor, không phải running instance |
| `Descriptors` | `() -> descriptor[]` | Snapshot registration order |
| `ResolveStartOrder` | `() -> descriptor[]` | Topological sort |

Feature module chỉ cần `LR.Modules:Register()`. Các API còn lại chủ yếu dành cho core và
tests.

### 23.4 DisposableStack đầy đủ

```lua
local stack = LR.DisposableStack:new()
local disposer = stack:Add(function() print("cleanup") end)
stack:DisposeOne(disposer)
stack:DisposeAll()
```

Không gọi `DisposeOne` trên item vẫn còn trong stack rồi mong nó bị remove; method này
chỉ invoke một disposable. Module bình thường chỉ dùng `context.disposables:Add()`.

### 23.5 Low-level transport factories

| Factory | Kết quả |
|---|---|
| `LR.CreateClientNui(options?)` | Client NUI service |
| `LR.CreateClientNet(options?)` | Client network service |
| `LR.CreateServerNet(options?)` | Server network service |
| `LR.CreateClientPublic(options?)` | Client Public/External service |
| `LR.CreateServerPublic(options?)` | Server Public/External service |

Các factory cho phép inject transport, clock, timer, payload limit và contracts để test.
Feature module không tự tạo các service này vì standard application đã register chúng.

Service low-level methods:

| Service | Methods |
|---|---|
| NUI | `RegisterModule`, `Module`, `IsReady`, `WhenReady`, `MarkReady`, `Dispose` |
| Client Net | `RegisterModule`, `Module`, `Dispose` |
| Server Net | `RegisterModule`, `Module`, `ForgetPlayer`, `Dispose` |
| Public | `Register`, `Dispose` |

Generated accessor luôn được ưu tiên hơn dynamic `Module(id)` vì có DTO types cụ thể:

```lua
local typed = LR.Nui.Trucker()
local dynamic = LR.Nui:Module("trucker")
```

### 23.6 Constructors

```lua
local logger = LR.Logger:new({
  prefix = "custom",
  debug = true,
  sink = print,
})

local scheduler = LR.Scheduler:new({
  setTimeout = SetTimeout,
  clearTimeout = ClearTimeout,
})

local readiness = LR.StandaloneReadinessProvider:new({ready = false})

local app = LR.CreateApplication({
  name = "custom",
  side = "client",
  logger = logger,
  scheduler = scheduler,
  readiness = readiness,
})
```

Standard resource dùng `LR.CreateClientApplication()` hoặc
`LR.CreateServerApplication()` trong boot. Không tạo application thứ hai trong feature
module. Với side factory, inject scheduler/readiness theo shape thực tế:

```lua
local app = LR.CreateClientApplication({
  services = {
    scheduler = scheduler,
    readiness = readiness,
  },
})
```

### 23.7 Những API module không được gọi trực tiếp

| Raw API | Dùng API thay thế |
|---|---|
| `SendNUIMessage`, `RegisterNuiCallback` | `context.nui` generated facade |
| `TriggerServerEvent`, `TriggerClientEvent` | `context.net` generated facade |
| `RegisterNetEvent`, `AddEventHandler` cho transport | Contract event/RPC |
| `exports[...]` | `context.public` / `context.external` |
| `load`, `loadstring`, dynamic method dispatch | Static module/contract methods |

## 24. Checklist module mới

| Kiểm tra | Hoàn tất |
|---|---|
| Module ID đúng regex và filename đúng ID | [ ] |
| Schema và boundary files nằm dưới `packages/contracts/src/authoring/<id>/` | [ ] |
| Per-module `authoring/<id>/index.ts` chỉ export schemas | [ ] |
| Boundary file export explicit NUI/network/export constants và combined `<id>Boundaries` | [ ] |
| Combined boundaries được thêm vào explicit `moduleBoundaries` registry | [ ] |
| Store chỉ import schemas từ `@lr/contracts/authoring/<id>` | [ ] |
| `@Store({id: 'inventory'})` và `@State` defaults hợp lệ | [ ] |
| Store được thêm vào explicit `storeModules` registry | [ ] |
| `storeModules` và `moduleBoundaries` có one-to-one parity | [ ] |
| Đã chạy `pnpm generate:contracts` | [ ] |
| Client/server/shared file dùng đúng namespace type | [ ] |
| Custom class augment đúng `ModuleMap` | [ ] |
| Mọi module được gọi đều nằm trong `dependencies` | [ ] |
| `create` không tạo side effect khó rollback | [ ] |
| Registration/subscription được thêm vào `disposables` | [ ] |
| Client mutation đi qua server RPC có `Authorize` | [ ] |
| Event chỉ dùng khi không cần response | [ ] |
| Lua/NUI writes dùng ownerless synchronized state đúng mục đích | [ ] |
| UI-only state không decorate và vẫn local | [ ] |
| Browser-writable state không thay server authorization | [ ] |
| Public export chỉ expose contract allowlist | [ ] |
| LuaLS không có diagnostic | [ ] |
| Lua/web tests pass | [ ] |
| Đã restart và QA bằng FiveM thật | [ ] |

## Tài liệu liên quan

| Tài liệu | Nội dung |
|---|---|
| [Architecture](./ARCHITECTURE.md) | Kiến trúc và boundary |
| [Module authoring](./MODULE_AUTHORING.md) | Quy ước viết module ngắn gọn |
| [Contracts](./CONTRACTS.md) | Contract/protocol reference |
| [Security](./SECURITY.md) | Threat model và policy |
| [Release](./RELEASE.md) | Build/release/FXServer QA |
| [Migration v2](./MIGRATION_V2.md) | Chuyển từ v1 sang v2 |
