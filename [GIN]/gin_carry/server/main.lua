local carryPairs = {} -- [carrierServerId] = targetServerId
local carriedBy = {}  -- [targetServerId] = carrierServerId

--- Kiểm tra trạng thái chết của Target ở phía Server
---@param targetPed number
---@param targetServerId number
---@return boolean
local function isTargetDead(targetPed, targetServerId)
    if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then return false end

    -- 1. Kiểm tra StateBag trên Player (qbx_medical & QBCore)
    local pState = Player(targetServerId).state
    if pState then
        if pState.isDead or pState.dead or pState.isdead or pState.inLaststand or pState.inlaststand then return true end
        local deathState = pState['qbx_medical:deathState']
        if deathState and deathState > 1 then return true end -- 2 = LAST_STAND, 3 = DEAD
    end

    -- 2. Kiểm tra StateBag trên Entity
    local eState = Entity(targetPed).state
    if eState then
        if eState.isDead or eState.dead or eState.isdead or eState.inLaststand or eState.inlaststand then return true end
        local deathState = eState['qbx_medical:deathState']
        if deathState and deathState > 1 then return true end
    end

    -- 3. Kiểm tra QBCore / QBX Player Metadata (nếu có)
    if GetResourceState('qbx_core') == 'started' and exports.qbx_core then
        local pcallOk, qbxPlayer = pcall(function() return exports.qbx_core:GetPlayer(targetServerId) end)
        if pcallOk and qbxPlayer and qbxPlayer.PlayerData and qbxPlayer.PlayerData.metadata then
            local meta = qbxPlayer.PlayerData.metadata
            if meta.isdead or meta.inlaststand then return true end
        end
    end

    -- 4. Native GTA V health
    if GetEntityHealth(targetPed) <= 0 then return true end

    return false
end

--- Lắng nghe Yêu cầu Bắt đầu Vác từ Client
RegisterNetEvent('gin_carry:server:startCarry', function(targetServerId)
    local src = source
    if not targetServerId or targetServerId == src then return end

    local carrierPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetServerId)

    if not carrierPed or carrierPed == 0 or not targetPed or targetPed == 0 then return end

    -- Kiểm tra khoảng cách an toàn
    local carrierCoords = GetEntityCoords(carrierPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(carrierCoords - targetCoords) > Config.MaxDistance then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.too_far
        })
        return
    end

    -- Kiểm tra trạng thái vác hiện tại
    if carryPairs[src] or carriedBy[src] then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.already_carrying
        })
        return
    end

    if carriedBy[targetServerId] then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.being_carried
        })
        return
    end

    -- Kiểm tra Target đã chết hay chưa
    if not isTargetDead(targetPed, targetServerId) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.target_not_dead
        })
        return
    end

    -- Kiểm tra số lượng vật phẩm trong ox_inventory
    local itemCount = exports.ox_inventory:Search(src, 'count', Config.ItemName)
    if not itemCount or itemCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.no_item
        })
        return
    end

    -- Trừ 1 vật phẩm carry_item
    local success = exports.ox_inventory:RemoveItem(src, Config.ItemName, 1)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.no_item
        })
        return
    end

    -- Lưu trạng thái cặp vác
    carryPairs[src] = targetServerId
    carriedBy[targetServerId] = src

    -- Đồng bộ tới 2 Client
    TriggerClientEvent('gin_carry:client:syncCarry', src, src, targetServerId, true)
    TriggerClientEvent('gin_carry:client:syncCarry', targetServerId, src, targetServerId, false)
end)

--- Lắng nghe Yêu cầu Dừng Vác
RegisterNetEvent('gin_carry:server:stopCarry', function()
    local src = source
    local targetServerId = carryPairs[src]

    if targetServerId then
        carryPairs[src] = nil
        carriedBy[targetServerId] = nil

        TriggerClientEvent('gin_carry:client:stopCarry', src)
        TriggerClientEvent('gin_carry:client:stopCarry', targetServerId)
    end
end)

--- Xử lý an toàn khi Người chơi thoát Server (playerDropped)
AddEventHandler('playerDropped', function()
    local src = source

    -- Nếu Người vác thoát game
    if carryPairs[src] then
        local targetServerId = carryPairs[src]
        carryPairs[src] = nil
        carriedBy[targetServerId] = nil

        TriggerClientEvent('ox_lib:notify', targetServerId, {
            type = 'error',
            description = Config.Locales.carrier_left
        })
        TriggerClientEvent('gin_carry:client:stopCarry', targetServerId)
    end

    -- Nếu Người được vác thoát game
    if carriedBy[src] then
        local carrierServerId = carriedBy[src]
        carriedBy[src] = nil
        carryPairs[carrierServerId] = nil

        TriggerClientEvent('ox_lib:notify', carrierServerId, {
            type = 'error',
            description = Config.Locales.target_left
        })
        TriggerClientEvent('gin_carry:client:stopCarry', carrierServerId)
    end
end)
