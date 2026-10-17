-- Ped model hashes
local MALE_FREEMODE_MODEL = joaat('mp_m_freemode_01')
local FEMALE_FREEMODE_MODEL = joaat('mp_f_freemode_01')

-- Biến local cho UI state
local uiOpen = false

-- =====================================================
-- HELPER FUNCTIONS: XÁC ĐỊNH GIỚI TÍNH PED
-- =====================================================

--- Kiểm tra ped có phải freemode model không
---@param ped number
---@return boolean
local function isFreemodePed(ped)
    ped = ped or PlayerPedId()
    local model = GetEntityModel(ped)
    return model == MALE_FREEMODE_MODEL or model == FEMALE_FREEMODE_MODEL
end

--- Kiểm tra ped có phải female freemode không
---@param ped number
---@return boolean
local function isFemalePedForClothes(ped)
    ped = ped or PlayerPedId()
    return IsPedModel(ped, FEMALE_FREEMODE_MODEL)
end

--- Lấy giới tính của ped để dùng cho clothes config
---@param ped number
---@return string 'male' | 'female'
local function getPedSexForClothes(ped)
    ped = ped or PlayerPedId()
    return isFemalePedForClothes(ped) and "female" or "male"
end

-- =====================================================
-- OPEN/CLOSE UI
-- =====================================================

--- Mở giao diện trao đổi quần áo
local function openClothesExchangeUI()
    local ped = PlayerPedId()
    
    -- Kiểm tra ped hợp lệ
    if not isFreemodePed(ped) then
        lib.notify({
            title = 'Lỗi',
            description = Config.Notify.invalid_sex,
            type = 'error'
        })
        return
    end
    
    local sex = getPedSexForClothes(ped)
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    uiOpen = true
    
    -- Gửi dữ liệu đến NUI
    SendNUIMessage({
        action = 'open',
        sex = sex,
        config = {
            slots = Config.ClothingSlots,
            mapping = Config.UIToItemMapping,
            componentMapping = Config.ComponentMapping,
            rarityColors = Config.RarityColors,
            url = Config.Url,
            extension = Config.Extension,
            debug = Config.Debug
        }
    })
end

--- Đóng giao diện
local function closeClothesExchangeUI()
    SetNuiFocus(false, false)
    uiOpen = false
    SendNUIMessage({
        action = 'close'
    })
end

-- =====================================================
-- COMMAND
-- =====================================================

-- RegisterCommand(Config.Command, function()
--     openClothesExchangeUI()
-- end, false)

-- Nếu có OpenKey thì register key mapping
-- if Config.OpenKey then
--     RegisterKeyMapping(Config.Command, 'Mở trao đổi quần áo', 'keyboard', Config.OpenKey)
-- end

-- =====================================================
-- NUI CALLBACKS
-- =====================================================

--- Callback đóng UI
RegisterNUICallback('close', function(data, cb)
    closeClothesExchangeUI()
    cb('ok')
end)

--- Callback lấy danh sách item quần áo của player
RegisterNUICallback('getItems', function(data, cb)
    local items = lib.callback.await('clothes_exchange:getPlayerClothingItems', false, data.sex)
    cb(items or {})
end)

--- Callback lấy danh sách drawable có thể đổi
RegisterNUICallback('getOptions', function(data, cb)
    local options = lib.callback.await('clothes_exchange:getExchangeOptions', false, data)
    cb(options or {})
end)

--- Callback thực hiện trao đổi
RegisterNUICallback('exchange', function(data, cb)
    local result = lib.callback.await('clothes_exchange:exchangeItem', false, data)
    
    if result and result.success then
        lib.notify({
            title = 'Thành công',
            description = Config.Notify.success,
            type = 'success'
        })
    else
        lib.notify({
            title = 'Thất bại',
            description = result and result.message or Config.Notify.failed,
            type = 'error'
        })
    end
    
    cb(result or { success = false })
end)

-- =====================================================
-- ESC KEY HANDLER
-- =====================================================

CreateThread(function()
    while true do
        Wait(0)
        if uiOpen then
            -- Disable control khi UI mở
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            
            -- Bấm ESC để đóng
            if IsControlJustReleased(0, 322) then -- ESC key
                closeClothesExchangeUI()
            end
        else
            Wait(500)
        end
    end
end)

-- =====================================================
-- LOCATION INTERACTION (ox_target)
-- =====================================================

if Config.Location then
    local npcPed = nil

    -- Hàm spawn NPC
    local function spawnNPC()
        if npcPed and DoesEntityExist(npcPed) then return end
        
        local model = joaat(Config.Location.pedModel)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        
        local coords = Config.Location.coords
        npcPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
        SetEntityHeading(npcPed, coords.w)
        FreezeEntityPosition(npcPed, true)
        SetEntityInvincible(npcPed, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        SetModelAsNoLongerNeeded(model)

        -- Đăng ký ox_target cho NPC local entity
        exports.ox_target:addLocalEntity(npcPed, {
            {
                name = 'xn_quydoiquanao:npc',
                icon = Config.Location.target and Config.Location.target.icon or 'fas fa-tshirt',
                label = Config.Location.target and Config.Location.target.label or 'Trao Đổi Quần Áo',
                distance = Config.Location.target and Config.Location.target.distance or 2.5,
                onSelect = function()
                    openClothesExchangeUI()
                end
            }
        })
    end

    -- Hàm xóa NPC
    local function deleteNPC()
        if npcPed and DoesEntityExist(npcPed) then
            exports.ox_target:removeLocalEntity(npcPed, 'xn_quydoiquanao:npc')
            DeleteEntity(npcPed)
            npcPed = nil
        end
    end

    -- Khởi tạo NPC
    CreateThread(function()
        spawnNPC()
    end)

    -- Dọn dẹp NPC khi stop resource
    AddEventHandler('onResourceStop', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            deleteNPC()
        end
    end)
end

