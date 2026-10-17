# ender_werewolf — Werewolf cho FiveM

Trò chơi **Ma Sói (Werewolf)** trên FiveM, lối chơi giống bản trên iPhone: tạo phòng, phân vai, ban đêm / ban ngày, bỏ phiếu loại người chơi. Hỗ trợ **QBox (QB)** và **ESX**.

## Yêu cầu

| Dependency | Bắt buộc | Ghi chú |
|------------|----------|---------|
| [ox_lib](https://github.com/overextended/ox_lib) | Có | UI, callback, progress |
| [ox_target](https://github.com/overextended/ox_target) | Có | NPC tạo / vào phòng |
| [pma-voice](https://github.com/AvarianKnight/pma-voice) | Có | Voice proximity + radio Ma Sói |
| [qbx_core](https://github.com/Qbox-project/qbx_core) hoặc [qb-core](https://github.com/qbcore-framework/qb-core) | Có (nếu dùng QB) | QBox ưu tiên |
| [es_extended](https://github.com/esx-framework/esx_core) | Có (nếu dùng ESX) | ESX Legacy |

**Không cần database** — phòng chơi chỉ tồn tại trong RAM, tự xóa khi hết người hoặc restart server.

## Cài đặt

1. Copy thư mục `ender_werewolf` vào `resources/`.
2. Build giao diện NUI (chỉ cần làm một lần, hoặc sau khi sửa `web/`):

```bash
cd web
bun install   # hoặc: npm install
bun run build # hoặc: npm run build
```

3. Thêm vào `server.cfg`:

```cfg
ensure ox_lib
ensure ox_target
ensure pma-voice
ensure qbx_core   # hoặc es_extended
ensure ender_werewolf
```

**Thứ tự:** `pma-voice` phải start trước `ender_werewolf`.

4. Cấu hình framework trong `config.lua`:

```lua
-- QBox / QB
Config.Framework = 'qb'

-- ESX
Config.Framework = 'esx'
```

5. Restart server hoặc `ensure ender_werewolf`.

## Cách chơi

### Mở game

Đến **NPC Werewolf** tại `HubLocation` (có blip trên map) → ox_target **Chơi Werewolf** → mở UI (tạo phòng / nhập mã trong giao diện).

Muốn dùng lệnh cũ: bật `Config.Settings.UseCommand = true` → `/werewolf` hoặc `/ww`.

### Lobby & Teleport

- Tối đa **4 phòng** cùng lúc (`Config.Main.MaxLobbies`)
- Mỗi phòng được gán **1 trong 4 khu lobby** (`LobbyLocations[1-4]`)
- Khi **tạo / vào phòng** → tele tới khu lobby đó (xếp vòng tròn quanh `center`)
- Khi **rời phòng / kết thúc** → tele về vị trí cũ (hoặc Hub nếu không lưu được)
- **4 khu lobby nên đặt xa nhau** để proximity voice không lẫn giữa các trận

### Voice (pma-voice)

| Phase | Người sống | Người chết |
|-------|------------|------------|
| Lobby / Ban ngày / Bỏ phiếu | Proximity `DayProximity` (mặc định 12m) trong khu lobby | Tele khu `spectator`, proximity 0 |
| Ban đêm | Proximity rất thấp (im lặng) | Không nói được |
| Ban đêm — Ma Sói | Radio riêng (`7001`–`7004`) + **proximity 0** (người gần không nghe lén) | — |

### UI & Voice cùng lúc

Ban ngày và ban đêm (chờ lượt): **UI vẫn hiển thị** (vai trò, danh sách người chơi, dòng hướng dẫn) nhưng **không** `SetNuiFocus` — game nhận phím bình thường, giữ **N** (PTT) để nói. Khi đến lượt bỏ phiếu/hành động: chuyển sang **Focus** + `KeepInput` + passthrough PTT.

| | Passive (ban ngày / chờ lượt) | Focus (bỏ phiếu / hành động) |
|--|-------------------------------|------------------------------|
| UI | **Hiện** — chỉ xem thông tin | **Hiện** — click chọn |
| `SetNuiFocus` | `false` | `true` |
| PTT (N) | Bình thường | Passthrough |

### State bags (cho resource khác)

Đọc từ `LocalPlayer.state`:

| State | Ý nghĩa |
|-------|---------|
| `werewolfUiOpen` | UI werewolf đang hiển thị |
| `werewolfUiFocus` | UI chiếm chuột/keyboard — **nên chặn** inventory, phone, emote |
| `werewolfHud` | UI passive ban ngày/chờ lượt — **không** chặn PTT |
| `werewolfInMatch` | Đang trong trận (không phải lobby/kết thúc) |

Ví dụ trong resource khác:

```lua
if LocalPlayer.state.werewolfUiFocus then
    return -- không mở inventory
end
```

Khi `werewolfUiFocus` + trong trận: tự **chặn di chuyển/bắn/xe** (`BlockControlsOnFocus`).

| Phase | UI | PTT |
|-------|-----|-----|
| Ban ngày / ban đêm chờ lượt | Hiện (passive) | N — bình thường |
| Bỏ phiếu / hành động | Focus | N + LMENU (sói) |
| Lobby / kết thúc | Focus | Tùy config |
- Người chết **không thể rời phòng** khi trận đang diễn ra — chỉ xem UI + ở khu spectator
- Rời phòng chỉ khi **lobby** hoặc **đã kết thúc**

### Luồng chơi

1. **Tạo phòng** — người tạo là chủ phòng, nhận mã 6 ký tự (VD: `ABC123`).
2. **Tham gia** — người khác nhập mã phòng và bấm **Vào**.
3. **Sẵn sàng** — mọi người bấm **Sẵn sàng**.
4. **Bắt đầu** — chủ phòng bấm **Bắt đầu** khi đủ tối thiểu 6 người.
5. **Xem vai trò** — mỗi người thấy thẻ vai riêng (Ma Sói thấy thêm đồng đội).
6. **Ban đêm** — lần lượt: Ma Sói → Phù Thủy → Bác Sĩ → Tiên Tri.
7. **Ban ngày** — thảo luận bằng **pma-voice proximity** trong khu lobby.
8. **Bỏ phiếu** — loại người nghi ngờ.
9. Lặp đến khi một phe thắng.

### Điều kiện thắng

| Phe | Điều kiện |
|-----|-----------|
| Dân Làng | Loại hết Ma Sói |
| Ma Sói | Số Ma Sói còn sống ≥ số Dân Làng còn sống |

## Vai trò

| Vai trò | Phe | Ban đêm |
|---------|-----|---------|
| Ma Sói | Sói | Chọn nạn nhân (đồng thuận đa số) |
| Dân Làng | Dân | Không có hành động |
| Tiên Tri | Dân | Kiểm tra 1 người (Sói / Dân) |
| Bác Sĩ | Dân | Bảo vệ 1 người khỏi Ma Sói |
| Phù Thủy | Dân | 1 lọ cứu + 1 lọ độc (dùng một lần mỗi loại) |
| Thợ Săn | Dân | Khi bị loại, bắn chết 1 người |

### Phân vai theo số người

| Người chơi | Ma Sói | Tiên Tri | Bác Sĩ | Phù Thủy | Thợ Săn | Dân Làng |
|------------|--------|----------|--------|----------|---------|----------|
| 6 | 2 | 1 | 1 | — | — | 2 |
| 7 | 2 | 1 | 1 | 1 | — | 2 |
| 8 | 2 | 1 | 1 | 1 | — | 3 |
| 9 | 3 | 1 | 1 | 1 | — | 3 |
| 10 | 3 | 1 | 1 | 1 | 1 | 3 |
| 11 | 3 | 1 | 1 | 1 | 1 | 4 |
| 12 | 4 | 1 | 1 | 1 | 1 | 4 |

Chỉnh trong `config.lua` → `Config.Main.RoleDistribution`.

## Cấu hình

File `config.lua`:

```lua
Config.Framework = 'qb'          -- 'qb' | 'esx'

Config.Settings = {
    Command = 'werewolf',
    CommandAlias = 'ww',
    UseCommand = false,          -- false = chỉ NPC ox_target
}

Config.Main = {
    MinPlayers = 6,
    MaxPlayers = 12,
    MaxLobbies = 4,

    HubLocation = {
        coords = vector3(-269.4, -955.3, 31.2),
        radius = 3.0,
        label = 'Sảnh Werewolf',
    },

    Npc = {
        enabled = true,
        model = 'cs_priest',
        coords = vector4(-269.4, -955.3, 31.2, 180.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        targetLabel = 'Chơi Werewolf',
        targetDistance = 2.5,
    },

    -- 4 khu lobby — CHỈNH TỌA ĐỘ THEO SERVER
    LobbyLocations = {
        [1] = {
            label = 'Lobby 1',
            center = vector4(-270.0, -960.0, 31.2, 180.0),
            spectator = vector4(-285.0, -960.0, 31.2, 90.0),
            spawnRadius = 3.0,
        },
        -- [2], [3], [4] ...
    },

    Voice = {
        Enabled = true,
        Resource = 'pma-voice',
        RadioBase = 7000,       -- Lobby 1 = 7001, Lobby 2 = 7002...
        DayProximity = 12.0,
        NightProximity = 0.5,
        DeadProximity = 0.0,
        WerewolfProximity = 0.0,
    },
}
```

> **Radio:** đảm bảo `RadioBase + 1..4` không trùng kênh radio job/server khác. Ma Sói dùng `WerewolfProximity = 0` để không lộ giọng qua proximity.

## Lệnh admin

| Lệnh | Mô tả |
|------|-------|
| `/wwadmin list` | Liệt kê phòng đang hoạt động |
| `/wwadmin close <MÃ_PHÒNG>` | Đóng phòng (kick mọi người) |

Cần quyền admin framework hoặc ACE `command`.

## Export (dành cho dev)

```lua
-- Server
local room = exports['ender_werewolf']:GetRoomByPlayer(source)
local room = exports['ender_werewolf']:GetRoom('ABC123')

-- Gọi impl từ resource khác
exports['ender_werewolf']:ImplCall('Main', 'CreateRoom', source)
```

## Phát triển UI

```bash
cd web
bun run dev        # preview trình duyệt (có mock data)
bun run dev:game   # build watch cho FiveM
```

Mock data nằm trong `web/src/mocks/index.ts`.

## Cấu trúc thư mục

```
ender_werewolf/
├── config.lua              # Cấu hình
├── shared/game.lua         # Định nghĩa vai trò, phase
├── server/
│   ├── bridge.lua          # ESX / QBox bridge
│   ├── classes/room.class.lua
│   └── impl/main.impl.lua  # Logic phòng & game loop
├── client/
│   ├── bridge.lua
│   └── impl/main.impl.lua  # NUI, lệnh, events
└── web/                    # React NUI
    └── src/features/Werewolf/
```

## Framework: ESX vs QBox

| Tính năng | QBox (`qb`) | ESX |
|-----------|-------------|-----|
| Thông báo | `qbx_core:Notify` | `ESX.ShowNotification` |
| Tên nhân vật | `charinfo.firstname/lastname` | `getName()` |
| Admin | `group == 'admin'` | `admin` / `superadmin` |
| Player loaded | `LocalPlayer.state.isLoggedIn` | `Framework.IsPlayerLoaded()` |

Đổi `Config.Framework` rồi restart resource.

## Ghi chú

- Người disconnect giữa ván → phòng kết thúc.
- Ma Sói ban đêm dùng radio kênh `RadioBase + lobbySlot`.
- Người chết tele sang `spectator`, voice proximity = 0.
- Không thể rời phòng khi trận đang chơi (tránh spoil / thiếu người).

## License

Boilerplate & game by **Ender**. Tùy chỉnh tự do cho server của bạn.
