-- =============================================
--  xn_quandudu | CLIENT
-- =============================================

local sayPropObj     = nil
local sayPropObj2    = nil
local donggoiPropObj = nil

-- -----------------------------------------------
-- Hàm tiện ích: spawn prop
-- -----------------------------------------------
local function spawnProp(model, coords)
    local hash = GetHashKey(model)
    if Config.Debug and not IsModelValid(hash) then
        print("^1[xn_quandudu] Error: Model is invalid (not found in game files): " .. tostring(model) .. "^7")
    end

    RequestModel(hash)
    local timer = 0
    while not HasModelLoaded(hash) do 
        Wait(10) 
        timer = timer + 10
        if timer > 3000 then
            if Config.Debug then
                print("^1[xn_quandudu] Error: Model load timeout (3s): " .. tostring(model) .. "^7")
            end
            break
        end
    end

    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
    if Config.Debug then
        if not obj or obj == 0 then
            print("^1[xn_quandudu] Error: CreateObject returned 0 for model: " .. tostring(model) .. "^7")
        else
            print("[xn_quandudu] Spawned prop " .. tostring(model) .. " (Entity: " .. tostring(obj) .. ") at: " .. tostring(coords))
        end
    end

    FreezeEntityPosition(obj, true)
    SetEntityHeading(obj, coords.w)
    SetEntityCollision(obj, false, false)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

-- -----------------------------------------------
-- Hàm tiện ích: xoá prop
-- -----------------------------------------------
local function removeProp(obj)
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
    end
    return nil
end

-- -----------------------------------------------
-- Hàm chạy progressbar chung
-- -----------------------------------------------
local function runProgressBar(cfg)
    local params = {
        duration     = cfg.Duration,
        label        = cfg.Label,
        useWhileDead = false,
        canCancel    = cfg.CanCancel,
        disable = {
            move   = true,
            car    = true,
            combat = true,
        },
        anim = {
            dict = cfg.AnimDict,
            clip = cfg.AnimClip,
        },
    }

    -- Thêm prop cầm tay nếu config có khai báo
    if cfg.AnimProp then
        params.prop = {
            model = cfg.AnimProp.model,
            bone  = cfg.AnimProp.bone,
            pos   = cfg.AnimProp.pos,
            rot   = cfg.AnimProp.rot,
        }
    end

    return lib.progressBar(params)
end

-- -----------------------------------------------
-- Hàm quay ped về hướng tọa độ
-- -----------------------------------------------
local function turnPedToFaceCoords(ped, coords)
    if not coords then return end
    ClearPedTasksImmediately(ped)
    local pedCoords = GetEntityCoords(ped)
    local dx = coords.x - pedCoords.x
    local dy = coords.y - pedCoords.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(ped, heading)
    Wait(100)
end

-- -----------------------------------------------
-- XỬ LÝ: Sấy lá đu đủ
-- -----------------------------------------------
local function handleSayLaDuDu(index)
    local cfg = Config.Say
    local loc = Config.Locations[index]
    if not loc then return end

    sayPropObj  = spawnProp(cfg.PropModel,  loc.Say.PropCoords)
    sayPropObj2 = spawnProp(cfg.PropModel2, loc.Say.PropCoords2)

    local ped = PlayerPedId()
    turnPedToFaceCoords(ped, loc.Say.PropCoords)

    local success = runProgressBar(cfg)

    sayPropObj  = removeProp(sayPropObj)
    sayPropObj2 = removeProp(sayPropObj2)

    if success then
        TriggerServerEvent('xn_quandudu:server:sayLaDuDu', index)
    else
        lib.notify({ title = 'Sấy lá đu đủ', description = 'Đã huỷ quá trình sấy!', type = 'error' })
    end
end

-- -----------------------------------------------
-- XỬ LÝ: Đóng gói lá đu đủ
-- -----------------------------------------------
local function handleDongGoiLaDuDu(index)
    local cfg = Config.DongGoi
    local loc = Config.Locations[index]
    if not loc then return end

    donggoiPropObj = spawnProp(cfg.PropModel, loc.DongGoi.PropCoords)

    local ped = PlayerPedId()
    turnPedToFaceCoords(ped, loc.DongGoi.PropCoords)

    local success = runProgressBar(cfg)

    donggoiPropObj = removeProp(donggoiPropObj)

    if success then
        TriggerServerEvent('xn_quandudu:server:dongGoiLaDuDu', index)
    else
        lib.notify({ title = 'Đóng gói lá đu đủ', description = 'Đã huỷ quá trình đóng gói!', type = 'error' })
    end
end

-- -----------------------------------------------
-- Mở Context Menu
-- -----------------------------------------------
local function openMenu(index)
    local loc = Config.Locations[index]
    if not loc then return end

    -- Lấy số lượng nguyên liệu hiện có trong túi đồ
    local sayCount = exports.ox_inventory:Search('count', Config.Say.InputItem) or 0
    local dongGoiCount = exports.ox_inventory:Search('count', Config.DongGoi.InputItem) or 0

    local sayDisabled = sayCount < Config.Say.InputAmount
    local dongGoiDisabled = dongGoiCount < Config.DongGoi.InputAmount

    lib.registerContext({
        id    = 'menu_quandudu_' .. index,
        title = loc.TargetLabel or Config.TargetLabel,
        options = {
            {
                title       = '🔥 Sấy lá đu đủ',
                description = ('Cần: %s → Nhận: %s (tỷ lệ %d:%d)%s'):format(
                    Config.Say.InputItem, Config.Say.OutputItem,
                    Config.Say.InputAmount, Config.Say.OutputAmount,
                    sayDisabled and '\n⚠️ Không đủ nguyên liệu! (Hiện có: ' .. sayCount .. ')' or ''
                ),
                icon     = 'fire',
                disabled = sayDisabled,
                onSelect = function()
                    handleSayLaDuDu(index)
                end,
            },
            {
                title       = '📦 Đóng gói lá đu đủ',
                description = ('Cần: %s → Nhận: %s (tỷ lệ %d:%d)%s'):format(
                    Config.DongGoi.InputItem, Config.DongGoi.OutputItem,
                    Config.DongGoi.InputAmount, Config.DongGoi.OutputAmount,
                    dongGoiDisabled and '\n⚠️ Không đủ nguyên liệu! (Hiện có: ' .. dongGoiCount .. ')' or ''
                ),
                icon     = 'box',
                disabled = dongGoiDisabled,
                onSelect = function()
                    handleDongGoiLaDuDu(index)
                end,
            },
        },
    })
    lib.showContext('menu_quandudu_' .. index)
end

-- -----------------------------------------------
-- OX_TARGET: Đăng ký vùng tương tác
-- -----------------------------------------------
for index, loc in ipairs(Config.Locations) do
    exports.ox_target:addSphereZone({
        coords  = loc.TargetCoords,
        radius  = loc.TargetRadius or Config.TargetRadius,
        debug   = false,
        options = {
            {
                name     = 'quandudu_xuong_' .. index,
                label    = loc.TargetLabel or Config.TargetLabel,
                icon     = Config.TargetIcon,
                onSelect = function()
                    openMenu(index)
                end,
            },
        },
    })
end

-- -----------------------------------------------
-- Nhận thông báo từ server
-- -----------------------------------------------
RegisterNetEvent('xn_quandudu:client:notify', function(data)
    lib.notify({
        title       = data.title,
        description = data.description,
        type        = data.type or 'inform',
    })
end)
