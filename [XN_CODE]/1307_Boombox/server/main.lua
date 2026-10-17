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

    Player.Functions.SetMetaData("boombox_active", 1)
end)

RegisterNetEvent('1307_Boombox:server:playMusic', function(song, entity, coords)
    local src = source
    xSound:PlayUrlPos(-1, entity, song, Config.DefaultVolume, coords)
    xSound:Distance(-1, entity, Config.radius)
    isPlaying = true
end)

RegisterNetEvent('1307_Boombox:server:pickedup', function(entity)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    xSound:Destroy(-1, entity)
    PlacedBoomboxes[entity] = nil
end)

RegisterNetEvent('1307_Boombox:server:stopMusic', function(data)
    local src = source
    xSound:Destroy(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:pauseMusic', function(data)
    local src = source
    xSound:Pause(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:resumeMusic', function(data)
    local src = source
    xSound:Resume(-1, data)
end)

RegisterNetEvent('1307_Boombox:server:changeVolume', function(volume, entity)
    local src = source
    if not tonumber(volume) then return end
    xSound:setVolume(-1, entity, volume)
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

local function IsAdmin(source)
    if not source or source == 0 then return true end
    
    if exports.qbx_core and exports.qbx_core.HasGroup and exports.qbx_core:HasGroup(source, Config.AdminGroups) then
        return true
    end

    if exports.qbx_core and exports.qbx_core.HasPermission then
        for _, group in ipairs(Config.AdminGroups) do
            if exports.qbx_core:HasPermission(source, group) then
                return true
            end
        end
    end

    local QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject()
    if QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
        for _, group in ipairs(Config.AdminGroups) do
            if QBCore.Functions.HasPermission(source, group) then
                return true
            end
        end
    end

    if IsPlayerAceAllowed(source, 'command') or IsPlayerAceAllowed(source, 'admin') or IsPlayerAceAllowed(source, 'group.admin') then
        return true
    end

    return false
end

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