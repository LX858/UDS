List_Fashion = {}
List_Skateboard = {}
List_Weapon = {}

local function debugLog(...)
    if Config.debug then
        print(...)
    end
end

local function notify(source, notifyType, message)
    TriggerClientEvent('ox_lib:notify', source, {
        type = notifyType,
        description = message
    })
end

local function getMetadataName(itemData)
    if type(itemData) ~= 'table' then return nil end
    local metadata = itemData.metadata or itemData.info
    if type(metadata) ~= 'table' then return nil end
    local metaName = metadata.name or metadata.Name
    if type(metaName) ~= 'string' then return nil end
    return metaName
end

-- exports.qbx_core:CreateUseableItem('chibi_pet', function(source, item)
--     local itemName = getMetadataName(item)
--     if not itemName or not Config.item_setting[itemName] then
--         TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = 'Metadata name khong hop le cho chibi_pet' })
--         return
--     end
--     TriggerClientEvent('xn_chibicore:cl:SuDungVatPham', source, itemName)
-- end)

lib.callback.register('xn_chibicore:sv:SpawnProp', function(source, itemMod, model)
    if not List_Fashion[source] then
        List_Fashion[source] = {}
    end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    debugLog('^3[ItemMod] SpawnProp >> source='..source..' model='..model..' hash='..GetHashKey(model))
    debugLog('^3[ItemMod] Player coords: x='..playerCoords.x..' y='..playerCoords.y..' z='..playerCoords.z)
   
    local obj = CreateObject(GetHashKey(model), playerCoords.x, playerCoords.y, playerCoords.z - 20.0, true, true, true)
    
    debugLog('^3[ItemMod] CreateObject returned: '..tostring(obj))
    
    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(obj) then
        debugLog('^1[ItemMod] Entity không tồn tại sau 5s timeout, obj='..tostring(obj))
        return nil
    end
    
    debugLog('^2[ItemMod] Tiếp tục với obj='..tostring(obj)..' DoesEntityExist='..tostring(DoesEntityExist(obj)))
    SetEntityOrphanMode(obj, 1)
    SetEntityRoutingBucket(obj, GetPlayerRoutingBucket(source))
    List_Fashion[source][itemMod] = obj
    local netId = NetworkGetNetworkIdFromEntity(obj)
    debugLog('^2[ItemMod] netId='..tostring(netId))
    return netId
end)

lib.callback.register('xn_chibicore:sv:DeleteProp', function(source, itemMod)
    if List_Fashion[source] and List_Fashion[source][itemMod] then
        local ped = List_Fashion[source][itemMod]
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        List_Fashion[source][itemMod] = nil
    end
end)

-- Skateboard prop spawn/delete callbacks
lib.callback.register('xn_chibicore:sv:SpawnSkateProp', function(source, itemMod, model)
    if not List_Skateboard[source] then
        List_Skateboard[source] = {}
    end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    debugLog('^3[ItemMod] SpawnSkateProp >> source='..source..' model='..model)
    local obj = CreateObject(GetHashKey(model), playerCoords.x, playerCoords.y, playerCoords.z - 20.0, true, true, true)
    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not DoesEntityExist(obj) then
        return nil
    end
    SetEntityOrphanMode(obj, 1)
    SetEntityRoutingBucket(obj, GetPlayerRoutingBucket(source))
    List_Skateboard[source][itemMod] = obj
    local netId = NetworkGetNetworkIdFromEntity(obj)
    return netId
end)

lib.callback.register('xn_chibicore:sv:DeleteSkateProp', function(source, itemMod)
    if List_Skateboard[source] and List_Skateboard[source][itemMod] then
        local obj = List_Skateboard[source][itemMod]
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
        List_Skateboard[source][itemMod] = nil
    end
end)

-- Weapon prop spawn/delete callbacks
lib.callback.register('xn_chibicore:sv:SpawnWeaponProp', function(source, itemMod, model)
    if not List_Weapon[source] then
        List_Weapon[source] = {}
    end
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    debugLog('^3[ItemMod] SpawnWeaponProp >> source='..source..' model='..model)
    local obj = CreateObject(GetHashKey(model), playerCoords.x, playerCoords.y, playerCoords.z - 20.0, true, true, true)
    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    if not DoesEntityExist(obj) then
        return nil
    end
    SetEntityOrphanMode(obj, 1)
    SetEntityRoutingBucket(obj, GetPlayerRoutingBucket(source))
    List_Weapon[source][itemMod] = obj
    local netId = NetworkGetNetworkIdFromEntity(obj)
    return netId
end)

lib.callback.register('xn_chibicore:sv:DeleteWeaponProp', function(source, itemMod)
    if List_Weapon[source] and List_Weapon[source][itemMod] then
        local obj = List_Weapon[source][itemMod]
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
        List_Weapon[source][itemMod] = nil
    end
end)

-- Force cleanup tất cả entity của player và trả về danh sách item đang active
-- Dùng khi player đổi routing bucket để re-attach lại prop trong bucket mới
lib.callback.register('xn_chibicore:sv:ForceCleanupAndGetActive', function(source)
    local result = { fashion = {}, skateboard = {}, weapon = {} }

    if List_Fashion[source] then
        for itemName, obj in pairs(List_Fashion[source]) do
            result.fashion[#result.fashion + 1] = itemName
            if DoesEntityExist(obj) then DeleteEntity(obj) end
        end
        List_Fashion[source] = {}
    end

    if List_Skateboard[source] then
        for itemName, obj in pairs(List_Skateboard[source]) do
            result.skateboard[#result.skateboard + 1] = itemName
            if DoesEntityExist(obj) then DeleteEntity(obj) end
        end
        List_Skateboard[source] = {}
    end

    if List_Weapon[source] then
        for itemName, obj in pairs(List_Weapon[source]) do
            result.weapon[#result.weapon + 1] = itemName
            if DoesEntityExist(obj) then DeleteEntity(obj) end
        end
        List_Weapon[source] = {}
    end

    debugLog('^3[ItemMod] ForceCleanupAndGetActive source='..source
        ..' fashion='..#result.fashion
        ..' skateboard='..#result.skateboard
        ..' weapon='..#result.weapon)
    return result
end)

AddEventHandler('playerDropped', function()
    local _source = source
    if List_Fashion[_source] then
        for _, ped in pairs(List_Fashion[_source]) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        List_Fashion[_source] = nil
    end
    if List_Skateboard[_source] then
        for _, obj in pairs(List_Skateboard[_source]) do
            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
        List_Skateboard[_source] = nil
    end
    if List_Weapon[_source] then
        for _, obj in pairs(List_Weapon[_source]) do
            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
        List_Weapon[_source] = nil
    end
end)

-- Hook ox_inventory để xóa prop khi item bị swap/give sang inventory khác
exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromSlot and payload.fromSlot.name == 'chibi_pet' then
        if payload.fromInventory ~= payload.toInventory then
            local src = payload.source
            local metadata = payload.fromSlot.metadata
            if metadata and metadata.name then
                local chibiName = metadata.name
                if List_Fashion[src] and List_Fashion[src][chibiName] then
                    local obj = List_Fashion[src][chibiName]
                    if DoesEntityExist(obj) then
                        DeleteEntity(obj)
                    end
                    List_Fashion[src][chibiName] = nil
                    TriggerClientEvent('xn_chibicore:cl:RemovePropLocal', src, chibiName)
                    debugLog('^3[ItemMod] swapItems hook: deleted prop '..chibiName..' from source='..src)
                end
            end
        end
    end
    return true
end, {})

-- Hook skateboard item swap (item name = key in Config.skateboard_setting)
exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromSlot and Config.skateboard_setting[payload.fromSlot.name] then
        if payload.fromInventory ~= payload.toInventory then
            local src = payload.source
            local skateName = payload.fromSlot.name
            if List_Skateboard[src] and List_Skateboard[src][skateName] then
                local obj = List_Skateboard[src][skateName]
                if DoesEntityExist(obj) then
                    DeleteEntity(obj)
                end
                List_Skateboard[src][skateName] = nil
                TriggerClientEvent('xn_chibicore:cl:RemoveSkatePropLocal', src, skateName)
                debugLog('^3[ItemMod] swapItems hook: deleted skate prop '..skateName..' from source='..src)
            end
        end
    end
    return true
end, {})

-- Hook weapon item swap (item name = key in Config.weapon_setting)
exports.ox_inventory:registerHook('swapItems', function(payload)
    if payload.fromSlot and Config.weapon_setting[payload.fromSlot.name] then
        if payload.fromInventory ~= payload.toInventory then
            local src = payload.source
            local weaponName = payload.fromSlot.name
            if List_Weapon[src] and List_Weapon[src][weaponName] then
                local obj = List_Weapon[src][weaponName]
                if DoesEntityExist(obj) then
                    DeleteEntity(obj)
                end
                List_Weapon[src][weaponName] = nil
                TriggerClientEvent('xn_chibicore:cl:RemoveWeaponPropLocal', src, weaponName)
                debugLog('^3[ItemMod] swapItems hook: deleted weapon prop '..weaponName..' from source='..src)
            end
        end
    end
    return true
end, {})

lib.addCommand('givechibi', {
    help = 'Cap chibi_pet kem metadata cho nguoi choi',
    params = {
        { name = 'namechibi', type = 'string', help = 'Ten chibi trong Config.item_setting' },
        { name = 'id', type = 'playerId', optional = true, help = 'Server ID nguoi choi nhan item' }
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    local chibiName = args.namechibi
    if not Config.item_setting[chibiName] then
        notify(source, 'error', ('Khong tim thay chibi: %s'):format(chibiName))
        return
    end
    local targetId = args.id or source
    local metadata = {
        name = chibiName,
        imageurl = ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp'):format(chibiName)
    }
    if not exports.ox_inventory:CanCarryItem(targetId, 'chibi_pet', 1) then
        -- Túi đầy → chuyển vào bưu cục
        local Player = exports.qbx_core:GetPlayer(targetId)
        if Player then
            local citizenid = Player.PlayerData.citizenid
            local ok = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'chibi_pet', 1, metadata)
            if ok then
                notify(source, 'success', ('Da cap chibi_pet [%s] vao buu cuc cua ID %s (tui day)'):format(chibiName, targetId))
                if targetId ~= source then
                    notify(targetId, 'info', ('Tui do day! chibi_pet [%s] da duoc gui ve Buu Cuc cua ban'):format(chibiName))
                end
            else
                notify(source, 'error', 'Khong the them vao buu cuc, vui long thu lai')
            end
        else
            notify(source, 'error', 'Khong tim thay nguoi choi')
        end
        return
    end
    local success = exports.ox_inventory:AddItem(targetId, 'chibi_pet', 1, metadata)
    if not success then
        notify(source, 'error', 'Khong the them item chibi_pet')
        return
    end
    notify(source, 'success', ('Da cap chibi_pet [%s] cho ID %s'):format(chibiName, targetId))
    if targetId ~= source then
        notify(targetId, 'success', ('Ban nhan duoc chibi_pet: %s'):format(chibiName))
    end
end)

lib.addCommand('adminchibi', {
    help = 'Mo UI thu tat ca chibi item_setting (admin)',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('xn_chibicore:cl:openAdminChiBI', source)
end)

-- Export: cho resource khác cấp chibi_pet
-- Cách dùng: exports['xn_chibicore']:GiveChibi(source, chibiName, doHiem)
-- doHiem: 'Common' | 'Uncommon' | 'Rare' | 'Epic' | 'Legendary'
-- Trả về true nếu thành công, false nếu thất bại
local VALID_DO_HIEM = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true }

exports('GiveChibi', function(targetId, chibiName, doHiem)
    if not targetId or not chibiName then return false end
    if not Config.item_setting[chibiName] then
        return false, ('chibi not found: %s'):format(chibiName)
    end
    if doHiem and not VALID_DO_HIEM[doHiem] then
        return false, ('DoHiem khong hop le: %s'):format(tostring(doHiem))
    end
    local metadata = {
        name = chibiName,
        imageurl = ('https://raw.githubusercontent.com/xuannguyen995/prime_item/refs/heads/main/%s.webp'):format(chibiName),
        DoHiem = doHiem or 'Common'
    }
    -- Nếu túi đầy → chuyển vào bưu cục
    if not exports.ox_inventory:CanCarryItem(targetId, 'chibi_pet', 1) then
        local Player = exports.qbx_core:GetPlayer(targetId)
        if not Player then return false, 'player not found' end
        local citizenid = Player.PlayerData.citizenid
        local ok = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'chibi_pet', 1, metadata)
        if ok then
            notify(targetId, 'info', ('Tui do day! chibi_pet [%s] da duoc gui ve Buu Cuc cua ban'):format(chibiName))
            debugLog('^3[GiveChibi] Tui day, da gui vao buucuc: source='..targetId..' chibi='..chibiName)
        else
            debugLog('^1[GiveChibi] FAILED buucuc: source='..targetId..' chibi='..chibiName)
        end
        return ok and true or false
    end
    local success = exports.ox_inventory:AddItem(targetId, 'chibi_pet', 1, metadata)
    if success then
        debugLog('^2[GiveChibi] Added to inventory: source='..targetId..' chibi='..chibiName)
    else
        -- Lần cuối fallback bưu cục (phòng trường hợp CanCarryItem sai)
        local Player = exports.qbx_core:GetPlayer(targetId)
        if Player then
            local citizenid = Player.PlayerData.citizenid
            local ok = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, 'chibi_pet', 1, metadata)
            if ok then
                notify(targetId, 'info', ('Tui do day! chibi_pet [%s] da duoc gui ve Buu Cuc cua ban'):format(chibiName))
            end
            debugLog('^1[GiveChibi] AddItem FAILED, fallback buucuc: source='..targetId..' chibi='..chibiName..' ok='..tostring(ok))
            return ok and true or false
        end
        debugLog('^1[GiveChibi] FAILED AddItem: source='..targetId..' chibi='..chibiName)
    end
    return success and true or false
end)

-- lib.addCommand('listchibi', {
--     help = 'Xem danh sach tat ca chibi trong Config.item_setting',
--     restricted = 'group.admin'
-- }, function(source, args, raw)
--     local list = {}
--     for name, _ in pairs(Config.item_setting) do
--         list[#list + 1] = name
--     end
--     table.sort(list)
--     TriggerClientEvent('xn_chibicore:cl:ShowChibiList', source, list)
-- end)

-- lib.addCommand('giveskate', {
--     help = 'Cap skateboard item cho nguoi choi',
--     params = {
--         { name = 'nameskate', type = 'string', help = 'Ten item skateboard trong Config.skateboard_setting' },
--         { name = 'id', type = 'playerId', optional = true, help = 'Server ID nguoi choi nhan item' }
--     },
--     restricted = 'group.admin'
-- }, function(source, args, raw)
--     local skateName = args.nameskate
--     if not Config.skateboard_setting[skateName] then
--         notify(source, 'error', ('Khong tim thay skateboard: %s'):format(skateName))
--         return
--     end
--     local targetId = args.id or source
--     local success = exports.ox_inventory:AddItem(targetId, skateName, 1)
--     if not success then
--         notify(source, 'error', ('Khong the them item %s'):format(skateName))
--         return
--     end
--     notify(source, 'success', ('Da cap %s cho ID %s'):format(skateName, targetId))
--     if targetId ~= source then
--         notify(targetId, 'success', ('Ban nhan duoc: %s'):format(skateName))
--     end
-- end)