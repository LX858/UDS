local List_Fashion = {}
local List_Skateboard = {}
local List_Weapon = {}
local WeaponActiveModels = {} -- tracks resolved model per weapon: { [itemName] = modelName }
local isNuiOpen = false
local isAdminMode = false
local adminBypassFashion = {} -- items equipped via admin mode, bypass metadata check

local function debugLog(...)
    if Config.debug then
        debugLog(...)
    end
end

local function HasChibiPetMetadata(metadataName)
    local slots = exports.ox_inventory:Search('slots', 'chibi_pet')
    if type(slots) ~= 'table' then return false end
    for _, slot in pairs(slots) do
        if slot and type(slot) == 'table' then
            local metadata = slot.metadata or slot.info
            if type(metadata) == 'table' and metadata.name == metadataName then
                return true
            end
        end
    end
    return false
end

local function GetChibiItems()
    local result = {}
    local slots = exports.ox_inventory:Search('slots', 'chibi_pet')
    debugLog('^3[ItemMod] GetChibiItems >> slots type='..type(slots)..' | slots='..json.encode(slots or {}))
    if type(slots) ~= 'table' then return result end
    for i, slot in pairs(slots) do
        debugLog('^3[ItemMod] slot['..tostring(i)..'] = '..json.encode(slot or {}))
        if slot and type(slot) == 'table' then
            local metadata = slot.metadata or slot.info
            debugLog('^3[ItemMod] metadata = '..json.encode(metadata or {}))
            if type(metadata) == 'table' and metadata.name then
                debugLog('^3[ItemMod] metadata.name='..tostring(metadata.name)..' | inConfig='..tostring(Config.item_setting[metadata.name] ~= nil))
                if Config.item_setting[metadata.name] then
                    result[#result + 1] = {
                        name = metadata.name,
                        label = Config.labels[metadata.name] or metadata.name,
                        imageurl = metadata.imageurl or '',
                        active = List_Fashion[metadata.name] ~= nil and DoesEntityExist(List_Fashion[metadata.name])
                    }
                end
            end
        end
    end
    debugLog('^2[ItemMod] GetChibiItems result count='..#result)
    return result
end

local function GetSkateboardItems()
    local result = {}
    for itemName, _ in pairs(Config.skateboard_setting) do
        local rawCount = exports.ox_inventory:Search('count', itemName)
        local count = 0
        if type(rawCount) == 'number' then
            count = rawCount
        elseif type(rawCount) == 'table' then
            for _, v in pairs(rawCount) do
                if type(v) == 'number' then count = count + v end
            end
        end
        if count > 0 then
            result[#result + 1] = {
                name = itemName,
                label = Config.labels[itemName] or itemName,
                imageurl = ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.png'):format(itemName),
                active = List_Skateboard[itemName] ~= nil and DoesEntityExist(List_Skateboard[itemName])
            }
        end
    end
    debugLog('^2[ItemMod] GetSkateboardItems result count='..#result)
    return result
end

local function GetWeaponItems()
    local result = {}
    WeaponActiveModels = {}
    for itemName, weaponConfig in pairs(Config.weapon_setting) do
        -- Dùng count để check tồn tại (đã hoạt động trước đó)
        local rawCount = exports.ox_inventory:Search('count', itemName)
        local count = 0
        if type(rawCount) == 'number' then
            count = rawCount
        elseif type(rawCount) == 'table' then
            for _, v in pairs(rawCount) do
                if type(v) == 'number' then count = count + v end
            end
        end

        if count > 0 then
            local activeModel = weaponConfig['Model'] -- default model
            local skinName = nil

            -- Dùng slots để đọc metadata.components cho skin detection
            local slots = exports.ox_inventory:Search('slots', itemName)
            debugLog('^3[ItemMod] GetWeaponItems >> '..itemName..' slots='..json.encode(slots or {}))
            if type(slots) == 'table' then
                -- slots = { "WEAPON_BAT": [ {slot1}, {slot2} ] } — nested 2 levels
                local slot = nil
                for _, slotArray in pairs(slots) do
                    if type(slotArray) == 'table' then
                        for _, s in pairs(slotArray) do
                            if type(s) == 'table' then
                                slot = s
                                break
                            end
                        end
                    end
                    if slot then break end
                end
                if slot then
                    local metadata = slot.metadata or slot.info
                    debugLog('^3[ItemMod] '..itemName..' metadata='..json.encode(metadata or {}))
                    if type(metadata) == 'table' and type(metadata.components) == 'table' then
                        debugLog('^3[ItemMod] '..itemName..' components='..json.encode(metadata.components))
                        local skinMap = Config.weapon_component_models[itemName]
                        if skinMap then
                            -- components = [false, false, ..., "skin_batnos"]
                            for idx, storedValue in pairs(metadata.components) do
                                if type(storedValue) == 'string' and skinMap[storedValue] then
                                    activeModel = skinMap[storedValue]
                                    skinName = storedValue
                                    debugLog('^2[ItemMod] MATCH! skin='..storedValue..' model='..activeModel)
                                    break
                                end
                            end
                        end
                    end
                end
            end

            WeaponActiveModels[itemName] = activeModel
            debugLog('^2[ItemMod] '..itemName..' resolvedModel='..activeModel..' skinName='..tostring(skinName))

            result[#result + 1] = {
                name = itemName,
                label = Config.labels[itemName] or itemName,
                imageurl = ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.png'):format(string.upper(itemName)),
                active = List_Weapon[itemName] ~= nil and DoesEntityExist(List_Weapon[itemName]),
                skinName = skinName
            }
        end
    end
    return result
end

local function SendUpdateNUI()
    SendNUIMessage({ action = 'updateItems', items = GetChibiItems(), skateItems = GetSkateboardItems(), weaponItems = GetWeaponItems() })
end

local function GetAllChibiItemsAdmin()
    local result = {}
    for name, _ in pairs(Config.item_setting) do
        result[#result + 1] = {
            name = name,
            label = Config.labels[name] or name,
            imageurl = ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.png'):format(name),
            active = List_Fashion[name] ~= nil and DoesEntityExist(List_Fashion[name])
        }
    end
    table.sort(result, function(a, b) return a.name < b.name end)
    return result
end

local function OpenNUI()
    if isNuiOpen then return end
    local items = GetChibiItems()
    local skateItems = GetSkateboardItems()
    local weaponItems = GetWeaponItems()
    isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', items = items, skateItems = skateItems, weaponItems = weaponItems })
end

local function OpenAdminNUI()
    if isNuiOpen then return end
    isAdminMode = true
    isNuiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', items = GetAllChibiItemsAdmin(), skateItems = {}, weaponItems = {} })
end

local function CloseNUI()
    if not isNuiOpen then return end
    isNuiOpen = false
    isAdminMode = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function AttachProp(Item_Mod, obj_data)
    debugLog('^3[ItemMod] AttachProp called >> Item_Mod='..tostring(Item_Mod))
    debugLog('^3[ItemMod] Config >> Model='..tostring(obj_data['Model'])..' Bone='..tostring(obj_data['Bone']))
    
    local modelHash = GetHashKey(obj_data['Model'])
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) and t < 100 do
        Wait(100)
        t = t + 1
    end
    if not HasModelLoaded(modelHash) then
        debugLog('^1[ItemMod] Model không load được: '..obj_data['Model'])
        return
    end
    debugLog('^2[ItemMod] Model loaded: '..obj_data['Model'])
    
    local netId = lib.callback.await('xn_chibicore:sv:SpawnProp', false, Item_Mod, obj_data['Model'])
    if not netId then 
        debugLog('^1[ItemMod] netId is nil')
        SetModelAsNoLongerNeeded(modelHash)
        return 
    end
    debugLog('^2[ItemMod] Received netId='..tostring(netId))
    
    local obj = NetworkGetEntityFromNetworkId(netId)
    local attempt = 0
    while not DoesEntityExist(obj) and attempt < 10 do
        Wait(100)
        attempt = attempt + 1
        obj = NetworkGetEntityFromNetworkId(netId)
    end
    
    if DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityVisible(obj, true, false)
        local playerPed = PlayerPedId()
        local boneIndex = GetPedBoneIndex(playerPed, obj_data['Bone'])
        
        local posX = obj_data['Pos'].x
        local posY = obj_data['Pos'].y
        local posZ = obj_data['Pos'].z
        local rotX = obj_data['Rot'].x
        local rotY = obj_data['Rot'].y
        local rotZ = obj_data['Rot'].z
        
        debugLog('^2[ItemMod] boneIndex='..tostring(boneIndex))
        debugLog('^2[ItemMod] Attach params: posX='..posX..' posY='..posY..' posZ='..posZ)
        debugLog('^2[ItemMod] Attach params: rotX='..rotX..' rotY='..rotY..' rotZ='..rotZ)
        
        AttachEntityToEntity(obj, playerPed, boneIndex,
            posX, posY, posZ,
            rotX, rotY, rotZ,
            true, true, false, true, 1, true)
        debugLog('^2[ItemMod] AttachEntityToEntity done, IsEntityVisible='..tostring(IsEntityVisible(obj)))
        List_Fashion[Item_Mod] = obj
    else
        debugLog('^1[ItemMod] Entity does not exist after 10 attempts')
    end
    SetModelAsNoLongerNeeded(modelHash)
end

local function DetachProp(Item_Mod)
    adminBypassFashion[Item_Mod] = nil
    if List_Fashion[Item_Mod] and DoesEntityExist(List_Fashion[Item_Mod]) then
        lib.callback.await('xn_chibicore:sv:DeleteProp', false, Item_Mod)
        List_Fashion[Item_Mod] = nil
    end
end

local function AttachSkateProp(Item_Mod, obj_data)
    debugLog('^3[ItemMod] AttachSkateProp called >> Item_Mod='..tostring(Item_Mod))
    local modelHash = GetHashKey(obj_data['Model'])
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) and t < 100 do
        Wait(100)
        t = t + 1
    end
    if not HasModelLoaded(modelHash) then
        debugLog('^1[ItemMod] Skate model không load được: '..obj_data['Model'])
        return
    end

    local netId = lib.callback.await('xn_chibicore:sv:SpawnSkateProp', false, Item_Mod, obj_data['Model'])
    if not netId then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local obj = NetworkGetEntityFromNetworkId(netId)
    local attempt = 0
    while not DoesEntityExist(obj) and attempt < 10 do
        Wait(100)
        attempt = attempt + 1
        obj = NetworkGetEntityFromNetworkId(netId)
    end

    if DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityVisible(obj, true, false)
        local playerPed = PlayerPedId()
        local boneIndex = GetPedBoneIndex(playerPed, obj_data['Bone'])
        AttachEntityToEntity(obj, playerPed, boneIndex,
            obj_data['Pos'].x, obj_data['Pos'].y, obj_data['Pos'].z,
            obj_data['Rot'].x, obj_data['Rot'].y, obj_data['Rot'].z,
            true, true, false, true, 1, true)
        List_Skateboard[Item_Mod] = obj
    end
    SetModelAsNoLongerNeeded(modelHash)
end

local function DetachSkateProp(Item_Mod)
    if List_Skateboard[Item_Mod] and DoesEntityExist(List_Skateboard[Item_Mod]) then
        lib.callback.await('xn_chibicore:sv:DeleteSkateProp', false, Item_Mod)
        List_Skateboard[Item_Mod] = nil
    end
end

local function AttachWeaponProp(Item_Mod, obj_data, modelOverride)
    local modelName = modelOverride or obj_data['Model']
    debugLog('^3[ItemMod] AttachWeaponProp called >> Item_Mod='..tostring(Item_Mod)..' model='..modelName)
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) and t < 100 do
        Wait(100)
        t = t + 1
    end
    if not HasModelLoaded(modelHash) then
        debugLog('^1[ItemMod] Weapon model không load được: '..modelName)
        return
    end

    local netId = lib.callback.await('xn_chibicore:sv:SpawnWeaponProp', false, Item_Mod, modelName)
    if not netId then
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local obj = NetworkGetEntityFromNetworkId(netId)
    local attempt = 0
    while not DoesEntityExist(obj) and attempt < 10 do
        Wait(100)
        attempt = attempt + 1
        obj = NetworkGetEntityFromNetworkId(netId)
    end

    if DoesEntityExist(obj) then
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityVisible(obj, true, false)
        local playerPed = PlayerPedId()
        local boneIndex = GetPedBoneIndex(playerPed, obj_data['Bone'])
        AttachEntityToEntity(obj, playerPed, boneIndex,
            obj_data['Pos'].x, obj_data['Pos'].y, obj_data['Pos'].z,
            obj_data['Rot'].x, obj_data['Rot'].y, obj_data['Rot'].z,
            true, true, false, true, 1, true)
        List_Weapon[Item_Mod] = obj
    end
    SetModelAsNoLongerNeeded(modelHash)
end

local function DetachWeaponProp(Item_Mod)
    if List_Weapon[Item_Mod] and DoesEntityExist(List_Weapon[Item_Mod]) then
        lib.callback.await('xn_chibicore:sv:DeleteWeaponProp', false, Item_Mod)
        List_Weapon[Item_Mod] = nil
    end
end

local function HandleAccessory(Item_Mod, config_data, isAttaching)
    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = false, car = true, combat = true, mouse = false },
        label = isAttaching and "Deo Phu Kien" or "Thao Phu Kien",
    }) then
        if isAttaching then
            AttachProp(Item_Mod, config_data[1])
        else
            DetachProp(Item_Mod)
        end
    end
    ClearPedTasks(PlayerPedId())
end

-- NUI Callbacks
RegisterNUICallback('selectItem', function(data, cb)
    local itemName = data.name
    if not itemName or not Config.item_setting[itemName] then
        cb('error')
        return
    end
    if not isAdminMode and not HasChibiPetMetadata(itemName) then
        cb('error')
        return
    end
    local config_data = Config.item_setting[itemName]
    CreateThread(function()
        if not List_Fashion[itemName] then
            if isAdminMode then adminBypassFashion[itemName] = true end
            HandleAccessory(itemName, config_data, true)
        else
            adminBypassFashion[itemName] = nil
            HandleAccessory(itemName, config_data, false)
        end
        -- Cập nhật lại UI sau khi toggle
        if isNuiOpen then
            if isAdminMode then
                SendNUIMessage({ action = 'updateItems', items = GetAllChibiItemsAdmin(), skateItems = {}, weaponItems = {} })
            else
                SendUpdateNUI()
            end
        end
    end)
    cb('ok')
end)

RegisterNUICallback('selectSkateItem', function(data, cb)
    local itemName = data.name
    if not itemName or not Config.skateboard_setting[itemName] then
        cb('error')
        return
    end
    local config_data = Config.skateboard_setting[itemName]
    CreateThread(function()
        if not List_Skateboard[itemName] then
            if lib.progressCircle({
                duration = 2000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = { move = false, car = true, combat = true, mouse = false },
                label = "Deo Phu Kien",
            }) then
                AttachSkateProp(itemName, config_data)
            end
        else
            if lib.progressCircle({
                duration = 2000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = { move = false, car = true, combat = true, mouse = false },
                label = "Thao Phu Kien",
            }) then
                DetachSkateProp(itemName)
            end
        end
        ClearPedTasks(PlayerPedId())
        if isNuiOpen then
            SendUpdateNUI()
        end
    end)
    cb('ok')
end)

RegisterNUICallback('selectWeaponItem', function(data, cb)
    local itemName = data.name
    if not itemName or not Config.weapon_setting[itemName] then
        cb('error')
        return
    end
    local config_data = Config.weapon_setting[itemName]
    local resolvedModel = WeaponActiveModels[itemName]
    CreateThread(function()
        if not List_Weapon[itemName] then
            if lib.progressCircle({
                duration = 2000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = { move = false, car = true, combat = true, mouse = false },
                label = "Deo Vu Khi",
            }) then
                AttachWeaponProp(itemName, config_data, resolvedModel)
            end
        else
            if lib.progressCircle({
                duration = 2000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = { move = false, car = true, combat = true, mouse = false },
                label = "Thao Vu Khi",
            }) then
                DetachWeaponProp(itemName)
            end
        end
        ClearPedTasks(PlayerPedId())
        if isNuiOpen then
            SendUpdateNUI()
        end
    end)
    cb('ok')
end)

RegisterNUICallback('closeUI', function(_, cb)
    CloseNUI()
    cb('ok')
end)

-- Command /propped mở UI
RegisterCommand('propped', function()
    if isNuiOpen then
        CloseNUI()
    else
        OpenNUI()
    end
end, false)

RegisterNetEvent('xn_chibicore:cl:openpropped', function()
    if isNuiOpen then
        CloseNUI()
    else
        OpenNUI()
    end
end)

RegisterNetEvent('xn_chibicore:cl:openAdminChiBI', function()
    if isNuiOpen then
        CloseNUI()
    else
        OpenAdminNUI()
    end
end)

-- Giữ lại event cũ cho tương thích
RegisterNetEvent('xn_chibicore:cl:SuDungVatPham', function(Item_Mod)
    local config_data = Config.item_setting[Item_Mod]
    CreateThread(function()
        if not List_Fashion[Item_Mod] then
            HandleAccessory(Item_Mod, config_data, true)
        else
            HandleAccessory(Item_Mod, config_data, false)
        end
    end)
end)

-- Khi server phát hiện item bị swap sang inventory khác
RegisterNetEvent('xn_chibicore:cl:RemovePropLocal', function(chibiName)
    if List_Fashion[chibiName] then
        List_Fashion[chibiName] = nil
        debugLog('^3[ItemMod] RemovePropLocal: '..chibiName)
    end
    if isNuiOpen then
        SendUpdateNUI()
    end
end)

RegisterNetEvent('xn_chibicore:cl:RemoveSkatePropLocal', function(skateName)
    if List_Skateboard[skateName] then
        List_Skateboard[skateName] = nil
        debugLog('^3[ItemMod] RemoveSkatePropLocal: '..skateName)
    end
    if isNuiOpen then
        SendUpdateNUI()
    end
end)

RegisterNetEvent('xn_chibicore:cl:RemoveWeaponPropLocal', function(weaponName)
    if List_Weapon[weaponName] then
        List_Weapon[weaponName] = nil
        debugLog('^3[ItemMod] RemoveWeaponPropLocal: '..weaponName)
    end
    if isNuiOpen then
        SendUpdateNUI()
    end
end)

-- Đồng bộ lại prop khi player chuyển routing bucket
-- Entity networked thuộc bucket cũ sẽ biến mất → cần force-cleanup + re-attach trong bucket mới
local function ReattachAllPropsAfterBucketChange()
    -- Lưu WeaponActiveModels trước khi clear
    local savedWeaponModels = {}
    for k, v in pairs(WeaponActiveModels) do
        savedWeaponModels[k] = v
    end

    -- Yêu cầu server xóa tất cả entity cũ và trả về danh sách item đang active
    local active = lib.callback.await('xn_chibicore:sv:ForceCleanupAndGetActive', false)
    if not active then return end

    -- Xóa tham chiếu local (entity đã bị xóa trên server)
    List_Fashion = {}
    List_Skateboard = {}
    List_Weapon = {}

    Wait(300)

    -- Re-attach chibi/fashion
    for _, itemName in ipairs(active.fashion) do
        local config_data = Config.item_setting[itemName]
        if config_data then
            AttachProp(itemName, config_data[1])
        end
    end

    -- Re-attach skateboard
    for _, itemName in ipairs(active.skateboard) do
        local config_data = Config.skateboard_setting[itemName]
        if config_data then
            AttachSkateProp(itemName, config_data)
        end
    end

    -- Re-attach weapon
    for _, itemName in ipairs(active.weapon) do
        local config_data = Config.weapon_setting[itemName]
        if config_data then
            local resolvedModel = savedWeaponModels[itemName] or config_data['Model']
            AttachWeaponProp(itemName, config_data, resolvedModel)
        end
    end

    if isNuiOpen then
        SendUpdateNUI()
    end
end

RegisterNetEvent('xn_chibicore:cl:ShowChibiList', function(list)
    local lines = {}
    for i, name in ipairs(list) do
        lines[#lines + 1] = ('**%d.** %s'):format(i, name)
    end
    lib.alertDialog({
        header = ('Danh sach Chibi Item Setting (%d items)'):format(#list),
        content = table.concat(lines, '  \n'),
        centered = true,
        cancel = false
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CloseNUI()
        for _, obj in pairs(List_Fashion) do
            if DoesEntityExist(obj) then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end
        for _, obj in pairs(List_Skateboard) do
            if DoesEntityExist(obj) then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end
        for _, obj in pairs(List_Weapon) do
            if DoesEntityExist(obj) then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
            end
        end
    end
end)

local function DeleteAllProps()
    adminBypassFashion = {}
    for k, obj in pairs(List_Fashion) do
        if DoesEntityExist(obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteEntity(obj)
        end
        List_Fashion[k] = nil
    end
    for k, obj in pairs(List_Skateboard) do
        if DoesEntityExist(obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteEntity(obj)
        end
        List_Skateboard[k] = nil
    end
    for k, obj in pairs(List_Weapon) do
        if DoesEntityExist(obj) then
            SetEntityAsMissionEntity(obj, true, true)
            DeleteEntity(obj)
        end
        List_Weapon[k] = nil
    end
end

local isReattaching = false

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            -- Kiểm tra item hết metadata thì tháo (bỏ qua item admin đang test)
            for k, _ in pairs(List_Fashion) do
                if not adminBypassFashion[k] and not HasChibiPetMetadata(k) then
                    DetachProp(k)
                end
            end
            -- Phát hiện entity biến mất do đổi bucket → re-attach
            if not isReattaching then
                local missing = false
                for _, obj in pairs(List_Fashion) do
                    if not DoesEntityExist(obj) then missing = true; break end
                end
                if not missing then
                    for _, obj in pairs(List_Skateboard) do
                        if not DoesEntityExist(obj) then missing = true; break end
                    end
                end
                if not missing then
                    for _, obj in pairs(List_Weapon) do
                        if not DoesEntityExist(obj) then missing = true; break end
                    end
                end
                if missing then
                    isReattaching = true
                    debugLog('^3[ItemMod] Phát hiện entity mất → re-attach do đổi bucket')
                    CreateThread(function()
                        ReattachAllPropsAfterBucketChange()
                        isReattaching = false
                    end)
                end
            end
        end
        Wait(1000)
    end
end)

RegisterNetEvent('1307_SuDungItemMod:client:deleteprop', DeleteAllProps)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    CloseNUI()
    DeleteAllProps()
end)

-- Whitelist các prop của resource này (chibi, ván trượt, weapon, skin weapon) + extra local
-- Prop nào KHÔNG có trong danh sách này sẽ bị xóa khi player lên xe
local PROP_DELETE_WHITELIST = {}
-- Chibi (Config.item_setting)
for _, cfgList in pairs(Config.item_setting) do
    for _, entry in ipairs(cfgList) do
        if entry['Model'] then
            PROP_DELETE_WHITELIST[GetHashKey(entry['Model'])] = true
        end
    end
end
-- Ván trượt (Config.skateboard_setting)
for _, entry in pairs(Config.skateboard_setting) do
    if entry['Model'] then
        PROP_DELETE_WHITELIST[GetHashKey(entry['Model'])] = true
    end
end
-- Weapon (Config.weapon_setting)
for _, entry in pairs(Config.weapon_setting) do
    if entry['Model'] then
        PROP_DELETE_WHITELIST[GetHashKey(entry['Model'])] = true
    end
end
-- Skin weapon (Config.weapon_component_models)
for _, skinMap in pairs(Config.weapon_component_models) do
    for _, modelName in pairs(skinMap) do
        PROP_DELETE_WHITELIST[GetHashKey(modelName)] = true
    end
end
-- Extra props từ Config.extra_prop_whitelist
for _, modelName in ipairs(Config.extra_prop_whitelist) do
    PROP_DELETE_WHITELIST[GetHashKey(modelName)] = true
end

RegisterNetEvent('QBCore:Client:VehicleInfo', function(data)
    print(LocalPlayer.state.isLoggedIn, data.event)
    if not LocalPlayer.state.isLoggedIn or data.event == 'Entering' then
        return
    end
    Wait(100)
    local driver = GetPedInVehicleSeat(data.vehicle, -1)
    if driver ~= 0 then
        for _, v in pairs(GetGamePool('CObject')) do
            if IsEntityAttachedToEntity(cache.ped, v) then
                local model = GetEntityModel(v)
                if not PROP_DELETE_WHITELIST[model] then
                    SetEntityAsMissionEntity(v, true, true)
                    DeleteObject(v)
                    DeleteEntity(v)
                end
            end
        end
    end
end)