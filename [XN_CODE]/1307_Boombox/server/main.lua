local xSound = exports.xsound
local CurrentZone = nil
local logger = require '@qbx_core.modules.logger'
local WebHook = {
    DatBoomBox = 'https://discord.com/api/webhooks/1348407125260370084/J7J70zWoI9pmn-jBLnrr-b8bzmg9gLgZ_r0HCFmWZFtF3my4QWzvl-53k3aUDmrjHTlz',
    ThemQuyen = 'https://discord.com/api/webhooks/1348407165945385082/0rJDZLk49Pr9D2yCfzsE2nGwRJ1X-ko4rmmPfJlKjSBl37bvMkADufY3L2djSgYv6FJX',
    AddLaiBoombox = 'https://discord.com/api/webhooks/1348407210098557080/QQ2_j7_-s9Bu9qeMbsd3o1bXIK2D7AbU7htqy0M9-EjEVMtm-5wp4lGIP6igZ-au34iU',
}

local function logEvent(Player, eventName, message, webhook)
    logger.log({
        source = eventName,
        webhook = webhook,
        event = eventName,
        color = 'orange',
        message = '\n- Tên nhân vật: `'..Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname..
                  '`\n- citizenid: `'..Player.PlayerData.citizenid..
                  '`\n- ID hiện tại: `'..Player.PlayerData.source.. 
                  '`\n- `'..message..'`',
    })
end


-- lib.callback.register('1307_Boombox:server:Permission_BoomBox', function(source)
--     local src = source
--     local pData = exports.qbx_core:GetPlayer(src)
--     local result = exports.oxmysql:executeSync('SELECT * FROM permission_boombox WHERE citizenid = ?', {pData.PlayerData.citizenid})
--     if result and result[1] then
--         return true
--     else
--         return false
--     end
-- end)

lib.callback.register('1307_Boombox:server:Permission_BoomBox', function(source)
    -- Trả về true ngay lập tức để bỏ qua bước kiểm tra Database
    return true 
end)



lib.callback.register('1307_Boombox:server:CheckMission', function(source)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local Task_BoomBox = Player.PlayerData.metadata["boombox_active"] or false 

    if not Task_BoomBox then 
        Task_BoomBox = 0
    end 

    if type == "boombox_active" then 
        return Task_BoomBox
    end
end)

local PlacedBoomboxes = {}

local function IsAdmin(source)
    if not source or source == 0 then return true end
    local srcStr = tostring(source)
    
    -- 1. Kiểm tra FiveM ACE Permissions (group.admin, group.mod, admin, mod, command, ...)
    for _, group in ipairs(Config.AdminGroups) do
        if IsPlayerAceAllowed(srcStr, group) or IsPlayerAceAllowed(srcStr, 'group.' .. group) then
            return true
        end
    end

    if IsPlayerAceAllowed(srcStr, 'command') 
        or IsPlayerAceAllowed(srcStr, 'admin') 
        or IsPlayerAceAllowed(srcStr, 'group.admin') 
        or IsPlayerAceAllowed(srcStr, 'mod') 
        or IsPlayerAceAllowed(srcStr, 'group.mod') 
        or IsPlayerAceAllowed(srcStr, 'god') 
        or IsPlayerAceAllowed(srcStr, 'group.god') then
        return true
    end

    -- 2. Kiểm tra PlayerData permissions nếu player đã load nhân vật
    local Player = exports.qbx_core and exports.qbx_core.GetPlayer and exports.qbx_core:GetPlayer(source)
    if Player and Player.PlayerData then
        if Player.PlayerData.permissions then
            for _, group in ipairs(Config.AdminGroups) do
                if Player.PlayerData.permissions[group] then return true end
            end
        end
        if Player.PlayerData.permission then
            for _, group in ipairs(Config.AdminGroups) do
                if Player.PlayerData.permission == group then return true end
            end
        end
    end

    -- 3. Kiểm tra qua QBCore.Functions.HasPermission nếu có QBCore
    local QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject()
    if QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
        for _, group in ipairs(Config.AdminGroups) do
            local ok, has = pcall(function() return QBCore.Functions.HasPermission(source, group) end)
            if ok and has then return true end
        end
    end

    return false
end

lib.callback.register('1307_Boombox:server:checkIsAdmin', function(source)
    local adm = IsAdmin(source)
    Player(source).state:set('isBoomboxAdmin', adm, true)
    return adm
end)

local function setupPlayerAdmin(source)
    if not source or source == 0 then return end
    local adm = IsAdmin(source)
    Player(source).state:set('isBoomboxAdmin', adm, true)
    TriggerClientEvent('1307_Boombox:client:setAdminStatus', source, adm)
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    setupPlayerAdmin(src)
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function()
    local src = source
    setupPlayerAdmin(src)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, playerId in ipairs(GetPlayers()) do
        setupPlayerAdmin(tonumber(playerId))
    end
end)

local function isBoomboxOwnerServer(src, netId)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return false end

    -- 1. Kiểm tra từ bảng PlacedBoomboxes
    local boomboxData = PlacedBoomboxes[netId]
    if boomboxData then
        if boomboxData.citizenid == Player.PlayerData.citizenid or boomboxData.source == src then
            return true
        end
    end

    -- 2. Kiểm tra StateBag trên Entity
    if netId and netId ~= 0 then
        local ent = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ent) then
            local state = Entity(ent).state
            if state and state.boombox_owner and state.boombox_owner == Player.PlayerData.citizenid then
                return true
            end
        end
    end

    return false
end

RegisterServerEvent('1307_Boombox:server:Boombox_Active')
AddEventHandler('1307_Boombox:server:Boombox_Active', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        Player.Functions.SetMetaData("boombox_active", 0)
    end
end)

for k,v in pairs(Config.Boombox) do
    exports.qbx_core:CreateUseableItem(v.itemname, function(source)
        CurrentZone = v

        TriggerClientEvent(''..v.itemname..':SPAWN', source, CurrentZone)
    end)
end

RegisterNetEvent('1307_Boombox:server:registerBoombox', function(netId, itemName, model, coords)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local charInfo = Player.PlayerData.charinfo
    local charName = (charInfo and (charInfo.firstname .. ' ' .. charInfo.lastname)) or Player.PlayerData.name

    PlacedBoomboxes[netId] = {
        source = src,
        citizenid = Player.PlayerData.citizenid,
        charName = charName,
        playerName = Player.PlayerData.name,
        itemName = itemName,
        model = model,
        time = os.date('%H:%M:%S - %d/%m/%Y'),
        coords = coords
    }

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        Entity(entity).state:set('boombox_owner', Player.PlayerData.citizenid, true)
    else
        CreateThread(function()
            local timeout = 50
            while timeout > 0 and not DoesEntityExist(entity) do
                Wait(100)
                entity = NetworkGetEntityFromNetworkId(netId)
                timeout = timeout - 1
            end
            if DoesEntityExist(entity) then
                Entity(entity).state:set('boombox_owner', Player.PlayerData.citizenid, true)
            end
        end)
    end

    Player.Functions.SetMetaData("boombox_active", 1)
end)

RegisterNetEvent('1307_Boombox:server:playMusic', function(song, entity, coords)
    local src = source
    if not isBoomboxOwnerServer(src, entity) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end
    xSound:PlayUrlPos(-1, entity, song, Config.DefaultVolume, coords)
    xSound:Distance(-1, entity, Config.radius)
    isPlaying = true
end)

RegisterNetEvent('1307_Boombox:server:pickedup', function(entity)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    if not isBoomboxOwnerServer(src, entity) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end

    xSound:Destroy(-1, entity)
    PlacedBoomboxes[entity] = nil
    Player.Functions.SetMetaData("boombox_active", 0)
end)

RegisterNetEvent('1307_Boombox:server:stopMusic', function(data)
    local src = source
    if not isBoomboxOwnerServer(src, data) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end
    xSound:Destroy(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:pauseMusic', function(data)
    local src = source
    if not isBoomboxOwnerServer(src, data) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end
    xSound:Pause(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:resumeMusic', function(data)
    local src = source
    if not isBoomboxOwnerServer(src, data) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end
    xSound:Resume(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:changeVolume', function(volume, entity)
    local src = source
    if not isBoomboxOwnerServer(src, entity) and not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không phải là chủ sở hữu của Boombox này!', 'error', 5000)
    end
    if not tonumber(volume) then return end
    xSound:setVolume(-1, entity, volume)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for netId, data in pairs(PlacedBoomboxes) do
        if data.source == src then
            xSound:Destroy(-1, netId)
            local ent = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(ent) then
                DeleteEntity(ent)
            end
            TriggerClientEvent('1307_Boombox:client:forceDeleteEntity', -1, netId, data.coords)
            PlacedBoomboxes[netId] = nil
        end
    end
end)

--============================== NHẶT BOOMBOX THEO TÊN OBJECT ========================================
RegisterNetEvent('1307_Boombox:server:AddItem', function(ItemName, ItemAmount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local PlayerPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(PlayerPed)
    logEvent(Player, '1307_Boombox | THÊM LẠI BOOMBOX', 'THEM LAI BOOMBOX', WebHook.AddLaiBoombox or WebHook.DatBoomBox)
end)
--================================================== REMOVE BOOMBOX ==================================================
RegisterNetEvent('1307_Boombox:server:RemoveItem', function(ItemName, ItemAmount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end
    local PlayerPed = GetPlayerPed(src)
    local pCoords = GetEntityCoords(PlayerPed)
    Player.Functions.SetMetaData("boombox_active", 0)
    logEvent(Player, '1307_Boombox | SỬ DỤNG BOOMBOX', 'Sử dụng Boombox: ' .. tostring(ItemName) .. 'x \n Vị Trí : '..tostring(pCoords)..'', WebHook.DatBoomBox)
end)

RegisterNetEvent("1307_Boombox:server:Confirm_Use_BoomBox", function()
    local src = source 
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        Player.Functions.SetMetaData("boombox_active", 1)
    end
end)

-- ===================================================================================
-- ADMIN FEATURES: KIỂM TRA THÔNG TIN & XÓA PROP BOOMBOX
-- ===================================================================================

lib.callback.register('1307_Boombox:server:getBoomboxInfo', function(source, netId)
    local src = source
    if not IsAdmin(src) then
        return { isNotAdmin = true }
    end

    local data = PlacedBoomboxes[netId]
    if not data then 
        return { hasData = false } 
    end

    local ownerPlayer = exports.qbx_core:GetPlayer(data.source)
    local isOnline = false
    if ownerPlayer and ownerPlayer.PlayerData and ownerPlayer.PlayerData.citizenid == data.citizenid then
        isOnline = true
    end

    return {
        hasData = true,
        source = data.source,
        citizenid = data.citizenid,
        charName = data.charName,
        playerName = data.playerName,
        itemName = data.itemName,
        model = data.model,
        time = data.time,
        coords = data.coords,
        isOnline = isOnline
    }
end)

RegisterNetEvent('1307_Boombox:server:adminDeleteBoombox', function(netId, coords)
    local src = source
    if not IsAdmin(src) then
        return exports.qbx_core:Notify(src, 'Bạn không có quyền thực hiện hành động này!', 'error', 5000)
    end

    -- Stop audio stream
    if netId and netId ~= 0 then
        xSound:Destroy(-1, netId)
    end

    -- Delete server entity if exists
    if netId and netId ~= 0 then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    -- Sync delete on all clients
    TriggerClientEvent('1307_Boombox:client:forceDeleteEntity', -1, netId, coords)

    local ownerInfo = PlacedBoomboxes[netId]
    PlacedBoomboxes[netId] = nil

    local adminPlayer = exports.qbx_core:GetPlayer(src)
    exports.qbx_core:Notify(src, 'Đã xóa đối tượng Boombox thành công!', 'success', 5000)

    if adminPlayer then
        local msg = 'Admin: `' .. adminPlayer.PlayerData.charinfo.firstname .. ' ' .. adminPlayer.PlayerData.charinfo.lastname ..
                    '` (ID: `' .. src .. '`) đã xóa Boombox (NetID: `' .. tostring(netId) .. '`)'
        if ownerInfo then
            msg = msg .. '\n- Người sở hữu trước đó: `' .. tostring(ownerInfo.charName) .. '` | ID: `' .. tostring(ownerInfo.source) .. '` | CID: `' .. tostring(ownerInfo.citizenid) .. '`'
        end
        logEvent(adminPlayer, '1307_Boombox | ADMIN XÓA BOOMBOX', msg, WebHook.DatBoomBox)
    end
end)

lib.addCommand("addquyenbb", {
    help = "Cấp quyền sử dụng item (Chỉ dành cho nhân viên Tòa Thị Chính)",
    params = {
        { name = 'id', help = 'ID NGƯỜI CHƠI', type = 'pid' },
        { name = 'loaisudung', help = 'LOẠI SỬ DỤNG', type = 'string' }

    },
    restricted = 'group.admin'
}, function(source, args)
    
    if args['id'] == nil or args['loaisudung'] == nil then 
        return exports.qbx_core:Notify(source, 'Vui lòng nhập đầy đủ thông số', 'error') 
    end
    local target = GetPlayerPed(tonumber(args['id'] ))
    local Player = exports.qbx_core:GetPlayer(tonumber(args['id'] ))
    local CID = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    if target ~= 0 then
        if args['loaisudung'] == 'boombox' or args['loaisudung'] == 'vantruot' then
            exports.oxmysql:execute('INSERT INTO permission_'..args['loaisudung']..' (citizenid, name) VALUES (@citizenid, @name)', {
                ['@citizenid'] = CID,
                ['@name'] = name,
            }, function(result)
                logEvent(Player, '1307_Boombox | THÊM QUYỀN', 'Thêm loại quyền ' .. args['loaisudung'] .. 'x ', WebHook.ThemQuyen)

                TriggerClientEvent('QBCore:Notify', src, 'Bạn vừa cấp quyền thành công!', 'success')
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, 'Loại quyền không chính xác!', 'error')
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Người chơi không trực tuyến', 'error')
    end
end)