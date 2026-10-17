# PROMPT: Migrate tính năng "Thay đổi Ped" từ xn_motels sang resource khác

## Bối cảnh

Tôi đang phát triển một FiveM server sử dụng framework **QBX (qbx_core)**. Resource `xn_motels` (C:\Users\nghec\Desktop\Newstart\txData\Qbox_2B74CE.base\resources\[XN_CODE2]\xn_motels) đã được tích hợp tính năng cho phép player thay đổi ped nhân vật khi ở trong phòng trọ. Tôi cần bạn giúp tôi **tách tính năng này ra và tích hợp vào resource này** — tích hợp vào cùng vị trí kho đồ.

---

## Môi trường kỹ thuật

| Thành phần | Chi tiết |
|---|---|
| Framework | QBX / qbx_core |
| Database | oxmysql (`MySQL.query.await`, `MySQL.single.await`, `MySQL.insert.await`) |
| Target system | ox_target (hoặc qb-target, toggle qua `config.target`) |
| UI menu | ox_lib (`lib.registerContext`, `lib.showContext`, `lib.callback.await`) |
| Appearance | illenium-appearance (lưu skin vào bảng `playerskins`) |
| Admin commands | ox_lib `lib.addCommand` với `restricted = 'group.admin'` |

---

## Tính năng cần migrate

### Mô tả logic

Player có thể được admin gán một ped model đặc biệt (lưu trong SQL). Khi player vào khu vực có target:

1. **Không có ped đặc biệt** → thông báo "Bạn không có ped đặc biệt"
2. **Có ped, đang dùng ped mặc định** → hiện menu "Đổi sang: `<ped_model>`"
3. **Có ped, đang dùng ped mod** → hiện menu "Đổi về nhân vật mặc định"

Khi **đổi sang ped mod**: áp dụng model + components từ SQL, lưu vào illenium-appearance, sau 1s gọi `clothes:reloadPlayerClothes`.

Khi **đổi về mặc định**: query `playerskins` lấy skin freemode đúng giới tính (gender từ `charinfo.gender`), áp dụng toàn bộ skin bằng GTA5 natives, lưu lại illenium-appearance, sau 1s gọi `clothes:reloadPlayerClothes`. Dữ liệu `motel_ped` **KHÔNG bị xóa** để player có thể toggle lại.

---

## Code cần tích hợp

### 1. SQL — Tạo bảng `motel_ped` (đặt trong `server/sql.lua` hoặc tương đương) (SQL ĐÃ CÓ SẴN KHÔNG CẦN TẠO LẠI NỮA)

```lua
-- Thêm vào trong Citizen.CreateThreadNow hoặc block khởi tạo DB
local ok = pcall(MySQL.scalar.await, 'SELECT 1 FROM motel_ped')
if not ok then
    MySQL.query.await([[CREATE TABLE `motel_ped` (
        `id` int NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(64) NOT NULL,
        `ped_model` varchar(128) DEFAULT NULL,
        `comp0` int DEFAULT 0, `comp1` int DEFAULT 0, `comp2` int DEFAULT 0,
        `comp3` int DEFAULT 0, `comp4` int DEFAULT 0, `comp5` int DEFAULT 0,
        `comp6` int DEFAULT 0, `comp7` int DEFAULT 0, `comp8` int DEFAULT 0,
        `comp9` int DEFAULT 0, `comp10` int DEFAULT 0, `comp11` int DEFAULT 0,
        `tex0` int DEFAULT 0, `tex1` int DEFAULT 0, `tex2` int DEFAULT 0,
        `tex3` int DEFAULT 0, `tex4` int DEFAULT 0, `tex5` int DEFAULT 0,
        `tex6` int DEFAULT 0, `tex7` int DEFAULT 0, `tex8` int DEFAULT 0,
        `tex9` int DEFAULT 0, `tex10` int DEFAULT 0, `tex11` int DEFAULT 0,
        `updated_at` int DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `citizenid` (`citizenid`)
    )]])
end
```

**Các hàm DB cần thêm:**

```lua
db.getPed = function(citizenid)
    local result = MySQL.query.await('SELECT * FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
    return result and result[1] or nil
end

db.savePed = function(citizenid, pedModel, comps, texs)
    return MySQL.query.await([[
        INSERT INTO `motel_ped`
            (`citizenid`, `ped_model`,
             `comp0`,`comp1`,`comp2`,`comp3`,`comp4`,`comp5`,
             `comp6`,`comp7`,`comp8`,`comp9`,`comp10`,`comp11`,
             `tex0`,`tex1`,`tex2`,`tex3`,`tex4`,`tex5`,
             `tex6`,`tex7`,`tex8`,`tex9`,`tex10`,`tex11`,
             `updated_at`)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
            `ped_model`  = VALUES(`ped_model`),
            `comp0`=VALUES(`comp0`),`comp1`=VALUES(`comp1`),`comp2`=VALUES(`comp2`),
            `comp3`=VALUES(`comp3`),`comp4`=VALUES(`comp4`),`comp5`=VALUES(`comp5`),
            `comp6`=VALUES(`comp6`),`comp7`=VALUES(`comp7`),`comp8`=VALUES(`comp8`),
            `comp9`=VALUES(`comp9`),`comp10`=VALUES(`comp10`),`comp11`=VALUES(`comp11`),
            `tex0`=VALUES(`tex0`),`tex1`=VALUES(`tex1`),`tex2`=VALUES(`tex2`),
            `tex3`=VALUES(`tex3`),`tex4`=VALUES(`tex4`),`tex5`=VALUES(`tex5`),
            `tex6`=VALUES(`tex6`),`tex7`=VALUES(`tex7`),`tex8`=VALUES(`tex8`),
            `tex9`=VALUES(`tex9`),`tex10`=VALUES(`tex10`),`tex11`=VALUES(`tex11`),
            `updated_at`=VALUES(`updated_at`)
    ]], {
        citizenid, pedModel,
        comps[0] or 0, comps[1] or 0, comps[2] or 0, comps[3] or 0,
        comps[4] or 0, comps[5] or 0, comps[6] or 0, comps[7] or 0,
        comps[8] or 0, comps[9] or 0, comps[10] or 0, comps[11] or 0,
        texs[0] or 0, texs[1] or 0, texs[2] or 0, texs[3] or 0,
        texs[4] or 0, texs[5] or 0, texs[6] or 0, texs[7] or 0,
        texs[8] or 0, texs[9] or 0, texs[10] or 0, texs[11] or 0,
        os.time()
    })
end

db.deletePed = function(citizenid)
    return MySQL.query.await('DELETE FROM `motel_ped` WHERE `citizenid` = ?', {citizenid})
end
```

---

### 2. SERVER — Callbacks, events, admin commands (thêm vào `server/main.lua`)

```lua
-- =============================================
-- Callbacks và events cho tính năng ped
-- =============================================
lib.callback.register('xn_ped:getPed', function(src)
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return nil end
    return db.getPed(xPlayer.identifier)
end)

RegisterNetEvent('xn_ped:resetPed', true)
AddEventHandler('xn_ped:resetPed', function()
    local src = source
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return end
    db.deletePed(xPlayer.identifier)
end)

-- Lấy appearance mặc định từ playerskins (freemode model đúng giới tính)
lib.callback.register('xn_ped:getDefaultAppearance', function(src)
    local xPlayer = GetPlayerFromId(src)
    if not xPlayer then return nil end
    local citizenid = xPlayer.identifier

    -- Xác định giới tính từ charinfo (0 = nam, 1 = nữ)
    local gender = xPlayer.PlayerData and xPlayer.PlayerData.charinfo and xPlayer.PlayerData.charinfo.gender
    local freemodeModel = (gender == 1) and 'mp_f_freemode_01' or 'mp_m_freemode_01'

    -- Ưu tiên row active đúng giới tính
    local row = MySQL.single.await(
        "SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? AND active = 1 LIMIT 1",
        { citizenid, freemodeModel }
    )
    if row then return row end

    -- Fallback: bất kỳ row nào đúng giới tính
    row = MySQL.single.await(
        "SELECT model, skin FROM playerskins WHERE citizenid = ? AND model = ? ORDER BY id DESC LIMIT 1",
        { citizenid, freemodeModel }
    )
    if row then return row end

    -- Fallback cuối: trả model không có skin
    return { model = freemodeModel, skin = nil }
end)
```

> **Lưu ý prefix:** Trong `xn_motels` các event/callback dùng prefix `renzu_motels:`. Khi migrate sang resource mới, đổi thành prefix phù hợp — ví dụ `xn_ped:` như trong code trên.

---

### 3. CLIENT — Hàm `ChangePedFunction` + events (thêm vào `client/main.lua`)

```lua
-- =============================================
-- Thay đổi ped của player (gọi từ target/zone)
-- =============================================
ChangePedFunction = function()
    local pedData = lib.callback.await('xn_ped:getPed', false)

    if not pedData or not pedData.ped_model then
        return lib.notify({ description = 'Bạn không có ped đặc biệt', type = 'inform' })
    end

    local currentModel  = GetEntityModel(PlayerPedId())
    local isUsingPedMod = currentModel == GetHashKey(pedData.ped_model)
    local options = {}

    if isUsingPedMod then
        -- Đang dùng ped mod → cho đổi về mặc định
        table.insert(options, {
            title       = 'Đổi về nhân vật mặc định',
            description = 'Trở về ped mặc định của nhân vật',
            icon        = 'fas fa-undo',
            onSelect    = function()
                local defaultRow = lib.callback.await('xn_ped:getDefaultAppearance', false)
                if not defaultRow or not defaultRow.model then
                    return lib.notify({ description = 'Không tìm thấy dữ liệu mặc định. Vui lòng reconnect.', type = 'inform' })
                end

                local model = GetHashKey(defaultRow.model)
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(100) end
                SetPlayerModel(PlayerId(), model)
                SetModelAsNoLongerNeeded(model)

                local skin = defaultRow.skin and json.decode(defaultRow.skin) or nil
                if skin then
                    local ped = PlayerPedId()

                    -- Components
                    if skin.components then
                        for _, comp in ipairs(skin.components) do
                            SetPedComponentVariation(ped, comp.component_id, comp.drawable or 0, comp.texture or 0, 0)
                        end
                    end

                    -- Props
                    if skin.props then
                        for _, prop in ipairs(skin.props) do
                            if prop.drawable == -1 then
                                ClearPedProp(ped, prop.prop_id)
                            else
                                SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture or 0, true)
                            end
                        end
                    end

                    -- HeadBlend (freemode only)
                    if skin.headBlend then
                        local hb = skin.headBlend
                        SetPedHeadBlendData(ped,
                            hb.shapeFirst or 0, hb.shapeSecond or 0, hb.shapeThird or 0,
                            hb.skinFirst  or 0, hb.skinSecond  or 0, hb.skinThird  or 0,
                            hb.shapeMix   or 0, hb.skinMix     or 0, hb.thirdMix   or 0,
                            false
                        )
                    end

                    -- Hair color
                    if skin.hair then
                        SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
                    end

                    -- Eye color
                    if skin.eyeColor and skin.eyeColor >= 0 then
                        SetPedEyeColor(ped, skin.eyeColor)
                    end

                    -- Head overlays
                    if skin.headOverlays then
                        local overlayMap = {
                            blemishes       = 0, facialHair = 1, eyebrows = 2,
                            ageing          = 3, makeUp     = 4, blush    = 5,
                            complexion      = 6, sunDamage  = 7, lipstick = 8,
                            moleAndFreckles = 9, chestHair  = 10, bodyBlemishes = 11,
                        }
                        for name, idx in pairs(overlayMap) do
                            local o = skin.headOverlays[name]
                            if o then
                                SetPedHeadOverlay(ped, idx, o.style or 0, o.opacity or 0)
                                SetPedHeadOverlayColor(ped, idx, 1, o.color or 0, o.secondColor or 0)
                            end
                        end
                    end

                    -- Lưu lại vào illenium-appearance
                    TriggerServerEvent('illenium-appearance:server:saveAppearance', skin)
                end

                -- KHÔNG xóa motel_ped — player có thể đổi lại
                lib.notify({ description = 'Đã đổi về nhân vật mặc định (' .. defaultRow.model .. ')', type = 'success' })

                -- Sau 1s reload quần áo
                SetTimeout(1000, function()
                    TriggerServerEvent('clothes:reloadPlayerClothes')
                end)
            end
        })
    else
        -- Có ped mod nhưng đang dùng mặc định → cho đổi sang ped mod
        table.insert(options, {
            title       = 'Đổi sang: ' .. pedData.ped_model,
            description = 'Áp dụng nhân vật đặc biệt được gán cho bạn',
            icon        = 'fas fa-user-check',
            onSelect    = function()
                local model = GetHashKey(pedData.ped_model)
                RequestModel(model)
                while not HasModelLoaded(model) do Wait(100) end
                SetPlayerModel(PlayerId(), model)
                SetModelAsNoLongerNeeded(model)

                local ped = PlayerPedId()
                for i = 0, 11 do
                    SetPedComponentVariation(ped, i, pedData['comp'..i] or 0, pedData['tex'..i] or 0, 0)
                end
                for i = 0, 2 do ClearPedProp(ped, i) end
                ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

                -- Lưu vào illenium-appearance
                lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
                    if not appearance then appearance = {} end
                    appearance.model        = pedData.ped_model
                    appearance.headBlend    = nil
                    appearance.faceFeatures = nil
                    appearance.headOverlays = nil
                    appearance.hair         = nil
                    appearance.tattoos      = nil
                    local components = {}
                    for i = 0, 11 do
                        components[i + 1] = {
                            componentId = i,
                            drawableId  = pedData['comp'..i] or 0,
                            textureId   = pedData['tex'..i]  or 0,
                            paletteId   = 0,
                        }
                    end
                    appearance.components = components
                    appearance.props = {
                        { propId = 0, drawableId = -1, textureId = -1 },
                        { propId = 1, drawableId = -1, textureId = -1 },
                        { propId = 2, drawableId = -1, textureId = -1 },
                        { propId = 6, drawableId = -1, textureId = -1 },
                        { propId = 7, drawableId = -1, textureId = -1 },
                    }
                    TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
                end)

                lib.notify({ description = 'Đã đổi sang nhân vật: ' .. pedData.ped_model, type = 'success' })

                -- Sau 1s reload quần áo
                SetTimeout(1000, function()
                    TriggerServerEvent('clothes:reloadPlayerClothes')
                end)
            end
        })
    end

    lib.registerContext({
        id      = 'changePed_menu',
        title   = 'Thay đổi ngoại hình nhân vật',
        options = options,
    })
    lib.showContext('changePed_menu')
end

-- Event: Admin gán ped và áp dụng ngay cho client
RegisterNetEvent('xn_ped:applyPed', function(pedModel, comps, texs)
    local model = GetHashKey(pedModel)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(100) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()
    for i = 0, 11 do
        SetPedComponentVariation(ped, i, comps[i] or 0, texs[i] or 0, 0)
    end
    for i = 0, 2 do ClearPedProp(ped, i) end
    ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

    lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
        if not appearance then appearance = {} end
        appearance.model = pedModel
        appearance.headBlend = nil ; appearance.faceFeatures = nil
        appearance.headOverlays = nil ; appearance.hair = nil ; appearance.tattoos = nil
        local components = {}
        for i = 0, 11 do
            components[i + 1] = { componentId = i, drawableId = comps[i] or 0, textureId = texs[i] or 0, paletteId = 0 }
        end
        appearance.components = components
        appearance.props = {
            { propId = 0, drawableId = -1, textureId = -1 },
            { propId = 1, drawableId = -1, textureId = -1 },
            { propId = 2, drawableId = -1, textureId = -1 },
            { propId = 6, drawableId = -1, textureId = -1 },
            { propId = 7, drawableId = -1, textureId = -1 },
        }
        TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
    end)

    lib.notify({ description = 'Admin đã gán ped "' .. pedModel .. '" cho bạn', type = 'inform' })
end)

-- Event: Thông báo chung từ server
RegisterNetEvent('xn_ped:notify', function(msg, notifyType)
    lib.notify({ description = msg, type = notifyType or 'inform' })
end)
```

---

### 4. TARGET — Thêm target gọi `ChangePedFunction` (ox_target)

```lua
-- Trong ShellTargets hoặc zone nào phù hợp với resource mới
-- canInteract: tùy logic resource mới (kiểm tra player có quyền không)
table.insert(options, {
    name        = 'changePed_zone',
    onSelect    = function()
        return ChangePedFunction()
    end,
    icon        = 'fas fa-user-circle',
    label       = 'Thay đổi Ped',
    canInteract = function()
        -- Điều kiện để target hiện ra (tùy resource)
        return true
    end
})
```

---

## Checklist khi migrate

- [ ] Đổi tất cả prefix event/callback từ `renzu_motels:` / `xn_ped:` sang prefix của resource mới
- [ ] Đảm bảo `db` object đã được khởi tạo trước khi gọi `db.getPed`, `db.savePed`, `db.deletePed`
- [ ] Thêm `oxmysql` vào `dependencies` trong `fxmanifest.lua` nếu chưa có
- [ ] Thêm `ox_lib` vào `dependencies` trong `fxmanifest.lua` nếu chưa có
- [ ] Bảng `motel_ped` chỉ cần tạo 1 lần — nếu đã tồn tại (từ xn_motels) thì **bỏ bước tạo bảng**, dùng thẳng
- [ ] Hàm `Notify` trong client — thay bằng hàm notify của resource mới hoặc dùng `lib.notify({...})`
- [ ] `GetPlayerFromId(src)` dùng cho ESX. Nếu QBX thuần thì đổi thành `exports.qbx_core:GetPlayer(src)` và thay `.identifier` thành `.PlayerData.citizenid`

---

## Lưu ý quan trọng

- **`playerskins.skin`** là JSON của illenium-appearance với format: `components[{component_id, drawable, texture}]`, `props[{prop_id, drawable, texture}]`, `headBlend{shapeFirst...}`, `hair{color, highlight}`, `eyeColor`, `headOverlays{blemishes, facialHair, eyebrows, ageing, makeUp, blush, complexion, sunDamage, lipstick, moleAndFreckles, chestHair, bodyBlemishes}` — mỗi overlay có `{style, opacity, color, secondColor}`
- **Toggle không xóa SQL**: khi đổi về mặc định, dữ liệu `motel_ped` được giữ nguyên. Chỉ `/resetped` mới xóa.
- **`clothes:reloadPlayerClothes`** là server event của resource quản lý quần áo — giữ nguyên tên này.
- **`illenium-appearance:server:saveAppearance`** là server event của illenium-appearance — giữ nguyên.
