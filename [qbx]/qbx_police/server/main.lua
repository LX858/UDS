local sharedConfig = require 'config.shared'
Plates = {}
local playerStatus = {}
local casings = {}
local bloodDrops = {}
local fingerDrops = {}
local updatingCops = false

-- Track trạng thái carry: carryingTable[patientSrc] = doctorSrc
local carryingTable = {}

---@param player Player
---@param minGrade? integer
---@return boolean?
function IsLeoAndOnDuty(player, minGrade)
    if not player then return false end
    local job = player.PlayerData.job
    if job and job.type == 'leo' and job.onduty then
        return job.grade.level >= (minGrade or 0)
    end 
end

local function generateId(table)
    local id = lib.string.random('11111')
    if not table then return id end
    while table[id] do
        id = lib.string.random('11111')
    end
    return id
end

RegisterNetEvent('police:server:SendTrackerLocation', function(coords, requestId)
    local target = exports.qbx_core:GetPlayer(source)
    local msg = locale('info.target_location', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname)
    local alertData = {
        title = locale('info.anklet_location'),
        coords = coords,
        description = msg
    }
    TriggerClientEvent('police:client:TrackerMessage', requestId, msg, coords)
    TriggerClientEvent('qb-phone:client:addPoliceAlert', requestId, alertData)
end)

-- Items
-- Items
exports.qbx_core:CreateUseableItem('handcuffs', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player.Functions.GetItemByName('handcuffs') then return end
    if not IsLeoAndOnDuty(player) then
        exports.qbx_core:Notify(source, locale('error.on_duty_police_only'), 'error')
        return
    end
    TriggerClientEvent('police:client:CuffPlayerSoft', source)
end)

-- exports.qbx_core:CreateUseableItem('moneybag', function(source, item)
--     if not item.info or item.info == '' then return end
--     local player = exports.qbx_core:GetPlayer(source)
--     if not player
--         or player.PlayerData.job.type == 'leo'
--         or not player.Functions.GetItemByName('moneybag')
--         or not player.Functions.RemoveItem('moneybag', 1, item.slot)
--     then return end
--     player.Functions.AddMoney('cash', tonumber(item.info.cash), 'used-moneybag')
-- end)

-- Callbacks
lib.callback.register('police:server:isPlayerDead', function(_, playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return false end
    return player.PlayerData.metadata.isdead or player.PlayerData.metadata.inlaststand
end)

lib.callback.register('police:server:isPlayerHandcuffed', function(_, playerId)
    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return false end
    return player.PlayerData.metadata.ishandcuffed or false
end)

lib.callback.register('police:GetPlayerStatus', function(_, targetSrc)
    local player = exports.qbx_core:GetPlayer(targetSrc)
    if not player or not next(playerStatus[targetSrc]) then return {} end
    local status = playerStatus[targetSrc]

    local statList = {}
    for i = 1, #status do
        statList[#statList + 1] = status[i].text
    end

    return statList
end)

lib.callback.register('police:GetImpoundedVehicles', function()
    return FetchImpoundedVehicles()
end)

lib.callback.register('qbx_policejob:server:spawnVehicle', function(source, model, coords, plate, giveKeys, vehId)
    local netId, veh = qbx.spawnVehicle({
        model = model,
        spawnSource = coords,
        warp = GetPlayerPed(source)
    })

    if not netId or netId == 0 or not veh or veh == 0 then return end

    SetVehicleNumberPlateText(veh, plate)
    if giveKeys == true then exports.qbx_vehiclekeys:GiveKeys(source, veh) end

    if vehId then Entity(veh).state.vehicleid = vehId end
    return netId
end)

local function isPlateFlagged(plate)
    return Plates and Plates[plate] and Plates[plate].isflagged
end


lib.callback.register('qbx_police:server:isPlateFlagged', function(_, plate)
    return isPlateFlagged(plate)
end)

local function isPoliceForcePresent()
    local players = exports.qbx_core:GetQBPlayers()
    for i = 1, #players do
        local job = players[i].PlayerData.job
        if job.type == 'leo' and job.grade.level >= 2 then
            return true
        end
    end
end

lib.callback.register('qbx_police:server:isPoliceForcePresent', isPoliceForcePresent)

if GetConvar('qbx:enablebridge', 'true') == 'true' then
    local QBCore = exports['qb-core']:GetCoreObject()
    ---@deprecated use qbx_police:server:isPlateFlagged
    QBCore.Functions.CreateCallback('police:IsPlateFlagged', function(_, cb, plate)
        lib.print.warn(GetInvokingResource(), 'invoked deprecated callback police:IsPlateFlagged. Use qbx_police:server:isPlateFlagged instead.')
        cb(isPlateFlagged(plate))
    end)

    ---@deprecated
    QBCore.Functions.CreateCallback('police:server:IsPoliceForcePresent', function(_, cb)
        lib.print.warn(GetInvokingResource(), 'invoked deprecated callback police:server:IsPoliceForcePresent. Use lib callback qbx_police:server:isPoliceForcePresent instead')
        cb(isPoliceForcePresent())
    end)
end

-- Events
RegisterNetEvent('police:server:Radar', function(fine)
    local src = source
    local price  = sharedConfig.radars.speedFines[fine].fine
    local player = exports.qbx_core:GetPlayer(src)
    if not player.Functions.RemoveMoney('bank', math.floor(price), 'Radar Fine') then return end
    exports['Renewed-Banking']:addAccountMoney('police', price)
    exports.qbx_core:Notify(src, locale('info.fine_received', price), 'inform')
end)

RegisterNetEvent('police:server:policeAlert', function(text, camId, playerSource)
    if not playerSource then playerSource = source end
    local ped = GetPlayerPed(playerSource)
    local coords = GetEntityCoords(ped)
    local players = exports.qbx_core:GetQBPlayers()
    for k, v in pairs(players) do
        if IsLeoAndOnDuty(v) then
            if camId then
                local alertData = {title = locale('info.new_call'), coords = coords, description = text .. locale('info.camera_id') .. camId}
                TriggerClientEvent('qb-phone:client:addPoliceAlert', k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text, camId)
            else
                local alertData = {title = locale('info.new_call'), coords = coords, description = text}
                TriggerClientEvent('qb-phone:client:addPoliceAlert', k, alertData)
                TriggerClientEvent('police:client:policeAlert', k, coords, text)
            end
        end
    end
end)

RegisterNetEvent('police:server:TakeOutImpound', function(plate, garage)
    local src = tonumber(source)
    if not src then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if #(playerCoords - sharedConfig.locations.impound[garage]) > 10.0 then return end

    Unimpound(plate)
    exports.qbx_core:Notify(src, locale('success.impound_vehicle_removed'), 'success')
end)

local function isTargetTooFar(src, targetSrc, maxDistance)
    maxDistance = maxDistance or 2.5
    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(targetSrc)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(playerCoords - targetCoords) > maxDistance then
        return true
    end
end

lib.callback.register('police:server:CuffPlayer', function(src, cuffedSrc, isSoftcuff)
    if isTargetTooFar(src, cuffedSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local cuffedPlayer = exports.qbx_core:GetPlayer(cuffedSrc)
    if not cuffedPlayer or not player.Functions.GetItemByName('handcuffs') then return end

    TriggerClientEvent('police:client:GetCuffed', cuffedPlayer.PlayerData.source, player.PlayerData.source, isSoftcuff)

    return true
end)

RegisterNetEvent('police:server:EscortPlayer', function(escortSrc)
    local src = source
    if isTargetTooFar(src, escortSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local escortPlayer = exports.qbx_core:GetPlayer(escortSrc)
    if not escortPlayer then return end

    if (player.PlayerData.job.type == 'leo' or player.PlayerData.job.type == 'ems') or (escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand) then
        TriggerClientEvent('police:client:GetEscorted', escortPlayer.PlayerData.source, player.PlayerData.source)
    else
        exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end
end)

RegisterNetEvent('ambulance:server:EscortPlayer', function(escortSrc)
    local src = source
    if isTargetTooFar(src, escortSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local escortPlayer = exports.qbx_core:GetPlayer(escortSrc)
    if not escortPlayer then return end

    -- Kiểm tra job EMS
    if player.PlayerData.job.type == 'ems' then
        -- TẮT KIỂM TRA - Cho phép vác xác bất kể trạng thái
        -- local metadata = escortPlayer.PlayerData.metadata
        -- if not (metadata.isdead or metadata.inlaststand) then
        --     return exports.qbx_core:Notify(src, 'Người chơi phải chết hoặc bất tỉnh!', 'error')
        -- end

        -- Lưu trạng thái carry: bệnh nhân escortSrc đang được bác sĩ src vác
        carryingTable[escortSrc] = src

        TriggerClientEvent('ambulance:client:GetCarried', escortPlayer.PlayerData.source, player.PlayerData.source)
        TriggerClientEvent('ambulance:client:CarryingPlayer', player.PlayerData.source)
    else
        exports.qbx_core:Notify(src, 'Chỉ bác sĩ mới có thể vác người!', 'error')
    end
end)

-- Event để stop carrying
-- patientId (tùy chọn): server ID của bệnh nhân cần dừng carry.
--   Nếu truyền vào, chỉ stop bác sĩ đang carry bệnh nhân đó.
--   Nếu không truyền, stop chính người gọi (bác sĩ tự dừng / bệnh nhân gọi từ client của mình).
RegisterNetEvent('ambulance:server:StopCarrying', function(patientId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if patientId then
        -- Tìm bác sĩ đang carry bệnh nhân patientId
        local doctorSrc = carryingTable[patientId]
        if doctorSrc then
            -- Chỉ stop đúng bác sĩ đó và bệnh nhân đó
            TriggerClientEvent('ambulance:client:ForceStopCarrying', doctorSrc)
            TriggerClientEvent('ambulance:client:ForceDetach', patientId)
            carryingTable[patientId] = nil
        end
        -- Không làm gì với bác sĩ khác
    else
        -- Không có patientId → người gọi tự dừng (bệnh nhân gọi từ phía mình hoặc bác sĩ tự dừng)
        -- Tìm xem src có phải là bệnh nhân đang bị carry không
        local doctorSrc = carryingTable[src]
        if doctorSrc then
            -- src là bệnh nhân, stop bác sĩ đang carry src
            TriggerClientEvent('ambulance:client:ForceStopCarrying', doctorSrc)
            TriggerClientEvent('ambulance:client:ForceDetach', src)
            carryingTable[src] = nil
        else
            -- src là bác sĩ tự dừng: tìm bệnh nhân nào đang bị src carry
            for pSrc, dSrc in pairs(carryingTable) do
                if dSrc == src then
                    TriggerClientEvent('ambulance:client:ForceDetach', pSrc)
                    carryingTable[pSrc] = nil
                    break
                end
            end
            TriggerClientEvent('ambulance:client:ForceStopCarrying', src)
        end
    end
end)

-- Export function để resource khác có thể gọi
exports('ForceStopCarry', function(targetSrc)
    if not targetSrc then return false end

    -- Force detach người bị vác
    TriggerClientEvent('ambulance:client:ForceDetach', targetSrc)

    -- Reset tất cả bác sĩ
    local players = exports.qbx_core:GetQBPlayers()
    for _, otherPlayer in pairs(players) do
        if otherPlayer.PlayerData.job.type == 'ems' then
            TriggerClientEvent('ambulance:client:ForceStopCarrying', otherPlayer.PlayerData.source)
        end
    end

    return true
end)

RegisterNetEvent('police:server:KidnapPlayer', function(kidnapedSrc)
    local src = source
    if isTargetTooFar(src, kidnapedSrc) then return end
    local player = exports.qbx_core:GetPlayer(source)
    local escortPlayer = exports.qbx_core:GetPlayer(kidnapedSrc)
    if not player or not escortPlayer then return end

    if escortPlayer.PlayerData.metadata.ishandcuffed or escortPlayer.PlayerData.metadata.isdead or escortPlayer.PlayerData.metadata.inlaststand then
        TriggerClientEvent('police:client:GetKidnappedTarget', escortPlayer.PlayerData.source, player.PlayerData.source)
        TriggerClientEvent('police:client:GetKidnappedDragger', player.PlayerData.source, escortPlayer.PlayerData.source)
    else
        exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end
end)

RegisterNetEvent('police:server:SetPlayerOutVehicle', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local escortPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not escortPlayer then return end
    local metadata = escortPlayer.PlayerData.metadata
    if not (metadata.ishandcuffed or metadata.isdead or metadata.inlaststand) then
        return exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end

    -- Gửi draggerId cho target để tự động hộ tống
    TriggerClientEvent('police:client:SetOutVehicleAndEscort', escortPlayer.PlayerData.source, src)
end)

-- Event riêng cho EMS kéo người ra xe và vác lên vai
RegisterNetEvent('ambulance:server:SetPlayerOutVehicle', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.name ~= 'ambulance' then return end

    local escortPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not escortPlayer then return end
    local metadata = escortPlayer.PlayerData.metadata
    
    -- TẮT KIỂM TRA - Cho phép kéo ra xe bất kể trạng thái
    -- if not (metadata.isdead or metadata.inlaststand) then
    --     return exports.qbx_core:Notify(src, 'Người chơi phải chết hoặc bất tỉnh!', 'error')
    -- end

    -- Lưu trạng thái carry: bệnh nhân targetSrc đang được bác sĩ src vác
    carryingTable[targetSrc] = src

    -- Kéo ra xe trước
    TriggerClientEvent('ambulance:client:SetOutVehicleAndCarry', escortPlayer.PlayerData.source, src)
    
    -- Trigger animation cho bác sĩ (người kéo)
    TriggerClientEvent('ambulance:client:CarryingPlayer', src)
end)

RegisterNetEvent('police:server:PutPlayerInVehicle', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local escortPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not escortPlayer then return end
    local metadata = escortPlayer.PlayerData.metadata

    if not (metadata.ishandcuffed or metadata.isdead or metadata.inlaststand) then
        return exports.qbx_core:Notify(src, locale('error.not_cuffed_dead'), 'error')
    end

    TriggerClientEvent('police:client:PutInVehicle', escortPlayer.PlayerData.source)
end)

RegisterNetEvent('police:server:CancelEscortBeforePutInVehicle', function()
    local src = source

    -- Tìm tất cả người chơi và kiểm tra ai đang hộ tống/bế người này
    local allPlayers = exports.qbx_core:GetQBPlayers()
    for _, player in pairs(allPlayers) do
        if player.PlayerData.source ~= src then
            -- Gửi event để force stop carrying/escorting cho tất cả người chơi khác
            TriggerClientEvent('police:client:CheckAndReleaseTarget', player.PlayerData.source, src)
        end
    end
end)

RegisterNetEvent('police:server:BillPlayer', function(targetSrc, price)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.type ~= 'leo' then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    if not targetPlayer.Functions.RemoveMoney('bank', price, 'paid-bills') then return end
    exports['Renewed-Banking']:addAccountMoney('police', price)
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.fine_received', price), 'inform')
end)

RegisterNetEvent('police:server:JailPlayer', function(targetSrc, time)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player or player.PlayerData.job.type ~= 'leo' then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    local currentDate = os.date('*t')
    if currentDate.day == 31 then
        currentDate.day = 30
    end

    targetPlayer.Functions.SetMetaData('injail', time)
    targetPlayer.Functions.SetMetaData('criminalrecord', {
        hasRecord = true,
        date = currentDate
    })
    if GetResourceState('qbx_prison') == 'started' then
        exports.qbx_prison:JailPlayer(targetPlayer.PlayerData.source, time)
    else
        TriggerClientEvent('police:client:SendToJail', targetPlayer.PlayerData.source, time)
    end
    exports.qbx_core:Notify(src, locale('info.sent_jail_for', time), 'inform')
end)

RegisterNetEvent('police:server:SetHandcuffStatus', function(isHandcuffed)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    player.Functions.SetMetaData('ishandcuffed', isHandcuffed)

    -- Tracking thời gian handcuff
    TriggerEvent('police:server:TrackHandcuffTime', isHandcuffed)
end)

-- Event để khôi phục trạng thái handcuff khi người chơi reconnect
RegisterNetEvent('police:server:RestoreHandcuffStatus', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    -- Kiểm tra nếu người chơi vẫn đang bị còng tay trong database
    if player.PlayerData.metadata.ishandcuffed then
        -- Thông báo cho client rằng người chơi vẫn bị còng
        TriggerClientEvent('police:client:RestoreHandcuffedState', src)
    end
end)

RegisterNetEvent('heli:spotlight', function(state)
    TriggerClientEvent('heli:spotlight', -1, source, state)
end)

RegisterNetEvent('police:server:FlaggedPlateTriggered', function(radar, plate, street)
    local src = tonumber(source)
    if not src then return end
    local coords = GetEntityCoords(GetPlayerPed(src))
    local players = exports.qbx_core:GetQBPlayers()
    for i = 1, #players do
        if IsLeoAndOnDuty(players[i]) then
            local alertData = {title = locale('info.new_call'), coords = coords, description = locale('info.plate_triggered', plate, street, radar)}
            TriggerClientEvent('qb-phone:client:addPoliceAlert', i, alertData)
            TriggerClientEvent('police:client:policeAlert', i, coords, locale('info.plate_triggered_blip', radar))
        end
    end
end)

-- Event yêu cầu xác nhận lục soát từ người chơi
RegisterNetEvent('police:server:RequestSearchPermission', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    -- Gửi thông báo cho người chơi bị yêu cầu lục soát
    TriggerClientEvent('police:client:ShowSearchDialog', targetSrc, src)
end)

-- Event xử lý phản hồi từ người chơi
RegisterNetEvent('police:server:SearchResponse', function(policeSrc, accepted)
    local targetSrc = source
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    local policePlayer = exports.qbx_core:GetPlayer(policeSrc)
    if not policePlayer then return end

    if accepted then
        -- Người chơi đồng ý -> Thực hiện lục soát
        -- Kiểm tra khoảng cách
        if isTargetTooFar(policeSrc, targetSrc) then return end

        -- Lấy thông tin inventory của người chơi bị lục soát
        local targetInventory = exports.ox_inventory:GetInventory(targetSrc)
        local itemsList = {}

        if targetInventory and targetInventory.items then
            for slot, item in pairs(targetInventory.items) do
                if item and item.name then
                    -- Kiểm tra có phải vật phẩm bất hợp pháp không
                    local isIllegal = false
                    for _, illegalItem in ipairs(sharedConfig.illegalItems) do
                        if item.name == illegalItem then
                            isIllegal = true
                            break
                        end
                    end

                    -- CHỈ thêm vào list nếu là vật phẩm bất hợp pháp
                    if isIllegal then
                        table.insert(itemsList, {
                            slot = slot,
                            name = item.name,
                            label = item.label or item.name,
                            count = item.count or 1,
                            metadata = item.metadata
                        })
                    end
                end
            end
        end

        -- Kiểm tra nếu không có vật phẩm bất hợp pháp
        if #itemsList == 0 then
            exports.qbx_core:Notify(policeSrc, 'Người chơi này không có đồ bẩn trong người!', 'inform')
            exports.qbx_core:Notify(targetSrc, locale('info.being_searched'), 'inform')
            return
        end

        -- Gửi danh sách items về client CÔNG AN để hiển thị context menu (kèm targetSrc)
        TriggerClientEvent('police:client:ShowSearchResults', policeSrc, itemsList, GetPlayerName(targetSrc), targetSrc)

        exports.qbx_core:Notify(policeSrc, locale('info.searched_success'), 'inform')
        exports.qbx_core:Notify(targetSrc, locale('info.being_searched'), 'inform')
    else
        -- Người chơi từ chối
        exports.qbx_core:Notify(policeSrc, 'Người chơi đã từ chối lục soát!', 'error')
        exports.qbx_core:Notify(targetSrc, 'Bạn đã từ chối lục soát!', 'inform')
    end
end)

RegisterNetEvent('police:server:SearchPlayer', function(targetSrc, overrideSrc)
    local src = overrideSrc or source
    if isTargetTooFar(src, targetSrc) then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    -- Lấy thông tin inventory của người chơi bị lục soát
    local targetInventory = exports.ox_inventory:GetInventory(targetSrc)
    local itemsList = {}

    if targetInventory and targetInventory.items then
        for slot, item in pairs(targetInventory.items) do
            if item and item.name then
                -- Kiểm tra có phải vật phẩm bất hợp pháp không
                local isIllegal = false
                for _, illegalItem in ipairs(sharedConfig.illegalItems) do
                    if item.name == illegalItem then
                        isIllegal = true
                        break
                    end
                end

                -- CHỈ thêm vào list nếu là vật phẩm bất hợp pháp
                if isIllegal then
                    table.insert(itemsList, {
                        slot = slot,
                        name = item.name,
                        label = item.label or item.name,
                        count = item.count or 1,
                        metadata = item.metadata
                    })
                end
            end
        end
    end

    -- Kiểm tra nếu không có vật phẩm bất hợp pháp
    if #itemsList == 0 then
        exports.qbx_core:Notify(src, 'Người chơi này không có đồ bẩn trong người!', 'inform')
        return
    end

    -- Gửi danh sách items về client để hiển thị context menu (kèm targetSrc)
    TriggerClientEvent('police:client:ShowSearchResults', src, itemsList, GetPlayerName(targetSrc), targetSrc)

    exports.qbx_core:Notify(src, locale('info.searched_success'), 'inform')
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.being_searched'), 'inform')
end)

-- Event thu đồ về kho công an
RegisterNetEvent('police:server:ConfiscateItem', function(targetSrc, slot, itemName, itemCount, itemMetadata)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end

    -- Kiểm tra có phải công an không
    if not (player.PlayerData.job.name == 'police' or player.PlayerData.job.name == 'sheriff') then
        return exports.qbx_core:Notify(src, 'Bạn không phải là công an!', 'error')
    end

    -- Kiểm tra khoảng cách
    if isTargetTooFar(src, targetSrc) then return end

    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    -- Xóa item từ người chơi
    local success = exports.ox_inventory:RemoveItem(targetSrc, itemName, itemCount, itemMetadata, slot)

    if success then
        -- Thêm item vào kho boss_police
        local stashSuccess = exports.ox_inventory:AddItem('boss_police', itemName, itemCount, itemMetadata)

        if stashSuccess then
            exports.qbx_core:Notify(src, 'Đã thu ' .. itemCount .. 'x ' .. itemName .. ' về kho công an!', 'success')
            exports.qbx_core:Notify(targetSrc, 'Công an đã thu ' .. itemCount .. 'x ' .. itemName .. ' của bạn!', 'inform')
        else
            -- Nếu thêm vào kho thất bại, trả lại cho người chơi
            exports.ox_inventory:AddItem(targetSrc, itemName, itemCount, itemMetadata)
            exports.qbx_core:Notify(src, 'Kho công an đã đầy!', 'error')
        end
    else
        exports.qbx_core:Notify(src, 'Không thể thu vật phẩm này!', 'error')
    end
end)

-- Event lục soát cốp xe
RegisterNetEvent('police:server:SearchVehicleTrunk', function(plate, netId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end

    -- Kiểm tra có phải công an không
    if not (player.PlayerData.job.name == 'police' or player.PlayerData.job.name == 'sheriff') then
        return exports.qbx_core:Notify(src, 'Bạn không phải là công an!', 'error')
    end

    if not player.PlayerData.job.onduty then
        return exports.qbx_core:Notify(src, 'Bạn phải đang on duty!', 'error')
    end

    -- Lấy trunk inventory của xe theo format: trunk + plate (không có dấu gạch dưới)
    local cleanPlate = plate:gsub("%s+", "") -- Xóa khoảng trắng
    local trunkId = 'trunk' .. cleanPlate

    local trunkInventory = exports.ox_inventory:GetInventory(trunkId)
    local itemsList = {}

    if trunkInventory and trunkInventory.items then
        for slot, item in pairs(trunkInventory.items) do
            if item and item.name then
                -- Kiểm tra có phải vật phẩm bất hợp pháp không
                local isIllegal = false
                for _, illegalItem in ipairs(sharedConfig.illegalItems) do
                    if item.name == illegalItem then
                        isIllegal = true
                        break
                    end
                end

                -- CHỈ thêm vào list nếu là vật phẩm bất hợp pháp
                if isIllegal then
                    table.insert(itemsList, {
                        slot = slot,
                        name = item.name,
                        label = item.label or item.name,
                        count = item.count or 1,
                        metadata = item.metadata
                    })
                end
            end
        end
    end

    -- Kiểm tra nếu không có vật phẩm bất hợp pháp
    if #itemsList == 0 then
        exports.qbx_core:Notify(src, 'Cốp xe không có đồ bẩn!', 'inform')
        return
    end

    -- Gửi danh sách items về client để hiển thị context menu (kèm plate để thu đồ)
    TriggerClientEvent('police:client:ShowVehicleSearchResults', src, itemsList, plate)
    exports.qbx_core:Notify(src, 'Đã phát hiện đồ bẩn trong cốp xe!', 'inform')
end)

-- Event thu đồ từ cốp xe về kho công an
RegisterNetEvent('police:server:ConfiscateItemFromVehicle', function(plate, slot, itemName, itemCount, itemMetadata)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end

    -- Kiểm tra có phải công an không
    if not (player.PlayerData.job.name == 'police' or player.PlayerData.job.name == 'sheriff') then
        return exports.qbx_core:Notify(src, 'Bạn không phải là công an!', 'error')
    end

    local cleanPlate = plate:gsub("%s+", "")
    local trunkId = 'trunk' .. cleanPlate

    -- Xóa item từ cốp xe
    local success = exports.ox_inventory:RemoveItem(trunkId, itemName, itemCount, itemMetadata, slot)

    if success then
        -- Thêm item vào kho boss_police
        local stashSuccess = exports.ox_inventory:AddItem('boss_police', itemName, itemCount, itemMetadata)

        if stashSuccess then
            exports.qbx_core:Notify(src, 'Đã thu ' .. itemCount .. 'x ' .. itemName .. ' từ cốp xe về kho công an!', 'success')
        else
            -- Nếu thêm vào kho thất bại, trả lại cốp xe
            exports.ox_inventory:AddItem(trunkId, itemName, itemCount, itemMetadata)
            exports.qbx_core:Notify(src, 'Kho công an đã đầy!', 'error')
        end
    else
        exports.qbx_core:Notify(src, 'Không thể thu vật phẩm này!', 'error')
    end
end)

-- Event mở kho boss_police
RegisterNetEvent('police:server:OpenBossPoliceStash', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)

    if not player then return end

    -- Kiểm tra có phải công an không
    if not (player.PlayerData.job.name == 'police' or player.PlayerData.job.name == 'sheriff') then
        return exports.qbx_core:Notify(src, 'Bạn không phải là công an!', 'error')
    end

    if not player.PlayerData.job.onduty then
        return exports.qbx_core:Notify(src, 'Bạn phải on duty!', 'error')
    end

    -- Kiểm tra grade phải từ 13 trở lên (boss)
    if player.PlayerData.job.grade.level < 13 then
        return exports.qbx_core:Notify(src, 'Chỉ Boss (Grade 13) mới được mở kho này!', 'error')
    end

    -- Mở stash boss_police

    exports.ox_inventory:forceOpenInventory(src, 'stash', 'boss_police')
end)

RegisterNetEvent('police:server:SeizeCash', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not targetPlayer then return end

    local moneyAmount = targetPlayer.PlayerData.money.cash
    targetPlayer.Functions.RemoveMoney('cash', moneyAmount, 'police-cash-seized')
    player.Functions.AddItem('moneybag', 1, false, { cash = moneyAmount })
    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.cash_confiscated'), 'inform')
end)

RegisterNetEvent('police:server:RobPlayer', function(targetSrc)
    local src = source
    if isTargetTooFar(src, targetSrc) then return end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    local targetPlayer = exports.qbx_core:GetPlayer(targetSrc)
    if not player or not targetPlayer then return end

    local money = targetPlayer.PlayerData.money.cash
    if targetPlayer.Functions.RemoveMoney('cash', money, 'police-player-robbed') then
        player.Functions.AddMoney('cash', money, 'police-player-robbed')
    end

    exports.qbx_core:Notify(targetPlayer.PlayerData.source, locale('info.cash_robbed', money), 'inform')
    exports.qbx_core:Notify(player.PlayerData.source, locale('info.stolen_money', money), 'inform')
end)

RegisterNetEvent('police:server:Impound', function(plate, fullImpound, price, body, engine, fuel)
    local src = source
    price = price or 0
    if not IsVehicleOwned(plate) then return end
    if not fullImpound then
        ImpoundWithPrice(price, body, engine, fuel, plate)
        exports.qbx_core:Notify(src, locale('info.vehicle_taken_depot', price), 'inform')
    else
        ImpoundForever(body, engine, fuel, plate)
        exports.qbx_core:Notify(src, locale('info.vehicle_seized'), 'inform')
    end
end)

RegisterNetEvent('evidence:server:UpdateStatus', function(data)
    playerStatus[source] = data
end)

RegisterNetEvent('evidence:server:CreateBloodDrop', function(citizenid, bloodtype, coords)
    local bloodId = generateId(bloodDrops)
    bloodDrops[bloodId] = {
        dna = citizenid,
        bloodtype = bloodtype
    }
    TriggerClientEvent('evidence:client:AddBlooddrop', -1, bloodId, citizenid, bloodtype, coords)
end)

RegisterNetEvent('evidence:server:CreateFingerDrop', function(coords)
    local player = exports.qbx_core:GetPlayer(source)
    local fingerId = generateId(fingerDrops)
    fingerDrops[fingerId] = player.PlayerData.metadata.fingerprint
    TriggerClientEvent('evidence:client:AddFingerPrint', -1, fingerId, player.PlayerData.metadata.fingerprint, coords)
end)

RegisterNetEvent('evidence:server:ClearBlooddrops', function(bloodDropList)
    if not bloodDropList or not next(bloodDropList) then return end
    for _, v in pairs(bloodDropList) do
        TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, v)
        bloodDrops[v] = nil
    end
end)

RegisterNetEvent('evidence:server:AddBlooddropToInventory', function(bloodId, bloodInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local streetName = bloodInfo.street
    local bloodType = bloodInfo.bloodtype
    local bloodDNA = bloodInfo.dnalabel
    local metadata = {}
    metadata.type = 'Blood Evidence'
    metadata.description = 'DNA ID: '..bloodDNA
    metadata.description = metadata.description..'\n\nBlood Type: '..bloodType
    metadata.description = metadata.description..'\n\nCollected By: '..playerName
    metadata.description = metadata.description..'\n\nCollected At: '..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveBlooddrop', -1, bloodId)
        bloodDrops[bloodId] = nil
    end
end)

RegisterNetEvent('evidence:server:AddFingerprintToInventory', function(fingerId, fingerInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local streetName = fingerInfo.street
    local fingerprint = fingerInfo.fingerprint
    local metadata = {}
    metadata.type = 'Fingerprint Evidence'
    metadata.description = 'Fingerprint ID: '..fingerprint
    metadata.description = metadata.description..'\n\nCollected By: '..playerName
    metadata.description = metadata.description..'\n\nCollected At: '..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveFingerprint', -1, fingerId)
        fingerDrops[fingerId] = nil
    end
end)

RegisterNetEvent('evidence:server:CreateCasing', function(weapon, serial, coords)
    local casingId = generateId(casings)
    local serieNumber = exports.ox_inventory:GetCurrentWeapon(source).metadata.serial
    if not serieNumber then
    serieNumber = serial
    end
    TriggerClientEvent('evidence:client:AddCasing', -1, casingId, weapon, coords, serieNumber)
end)

RegisterNetEvent('evidence:server:ClearCasings', function(casingList)
    if casingList and next(casingList) then
        for _, v in pairs(casingList) do
            TriggerClientEvent('evidence:client:RemoveCasing', -1, v)
            casings[v] = nil
        end
    end
end)

RegisterNetEvent('evidence:server:AddCasingToInventory', function(casingId, casingInfo)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local playerName = player.PlayerData.charinfo.firstname..' '..player.PlayerData.charinfo.lastname
    local streetName = casingInfo.street
    local ammoType = casingInfo.ammolabel
    local serialNumber = casingInfo.serie
    local metadata = {}
    metadata.type = 'Casing Evidence'
    metadata.description = 'Ammo Type: '..ammoType
    metadata.description = metadata.description..'\n\nSerial #: '..serialNumber
    metadata.description = metadata.description..'\n\nCollected By: '..playerName
    metadata.description = metadata.description..'\n\nCollected At: '..streetName
    if not exports.ox_inventory:RemoveItem(src, 'empty_evidence_bag', 1) then
        return exports.qbx_core:Notify(src, locale('error.have_evidence_bag'), 'error')
    end
    if exports.ox_inventory:AddItem(src, 'filled_evidence_bag', 1, metadata) then
        TriggerClientEvent('evidence:client:RemoveCasing', -1, casingId)
        casings[casingId] = nil
    end
end)

RegisterNetEvent('police:server:showFingerprint', function(playerId)
    TriggerClientEvent('police:client:showFingerprint', playerId, source)
    TriggerClientEvent('police:client:showFingerprint', source, playerId)
end)

RegisterNetEvent('police:server:showFingerprintId', function(sessionId)
    local player = exports.qbx_core:GetPlayer(source)
    local fid = player.PlayerData.metadata.fingerprint
    TriggerClientEvent('police:client:showFingerprintId', sessionId, fid)
    TriggerClientEvent('police:client:showFingerprintId', source, fid)
end)

RegisterNetEvent('police:server:SetTracker', function(targetId)
    local src = source
    if isTargetTooFar(src, targetId) then return end

    local target = exports.qbx_core:GetPlayer(targetId)
    if not exports.qbx_core:GetPlayer(src) or not target then return end

    local trackerMeta = target.PlayerData.metadata.tracker
    if trackerMeta then
        target.Functions.SetMetaData('tracker', false)
        exports.qbx_core:Notify(targetId, locale('success.anklet_taken_off'), 'success')
        exports.qbx_core:Notify(src, locale('success.took_anklet_from', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname), 'success')
        TriggerClientEvent('police:client:SetTracker', targetId, false)
    else
        target.Functions.SetMetaData('tracker', true)
        exports.qbx_core:Notify(targetId, locale('success.put_anklet'), 'success')
        exports.qbx_core:Notify(src, locale('success.put_anklet_on', target.PlayerData.charinfo.firstname, target.PlayerData.charinfo.lastname), 'success')
        TriggerClientEvent('police:client:SetTracker', targetId, true)
    end
end)

-- Hàm đăng ký stashes
local function registerPoliceStashes()
    local jobs = {}
    for k, v in pairs(exports.qbx_core:GetJobs()) do
        if v.type == 'leo' then
            jobs[k] = 0
        end
    end

    for i = 1, #sharedConfig.locations.trash do
        exports.ox_inventory:RegisterStash(('policetrash_%s'):format(i), 'Police Trash', 300, 4000000, nil, jobs, sharedConfig.locations.trash[i])
    end
    exports.ox_inventory:RegisterStash('policelocker', 'Police Locker', 30, 100000, true)

    -- Đăng ký kho boss_police (kho thu đồ) - 500 slots, 10000kg - Chỉ boss (grade 13)
    local bossJobs = {}
    for k, v in pairs(exports.qbx_core:GetJobs()) do
        if v.type == 'leo' then
            bossJobs[k] = 13  -- Chỉ grade 13 trở lên
        end
    end
    exports.ox_inventory:RegisterStash('boss_police', 'Kho Thu Đồ Công An', 500, 10000000, nil, bossJobs)

    print('[qbx_police] Đã đăng ký tất cả stashes thành công!')
end

-- Đăng ký khi ox_inventory khởi động
AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= 'ox_inventory' then return end
    registerPoliceStashes()
end)

-- Đăng ký ngay khi qbx_police khởi động (nếu ox_inventory đã chạy)
CreateThread(function()
    if GetResourceState('ox_inventory') == 'started' then
        registerPoliceStashes()
    end
end)

-- Threads
CreateThread(function()
    Wait(1000)
    for i = 1, #sharedConfig.locations.trash do
        exports.ox_inventory:ClearInventory(('policetrash_%s'):format(i))
    end
end)

-- Table để lưu thời gian handcuff của người chơi
local handcuffTimeTracker = {}

-- Event để theo dõi thời gian handcuff
RegisterNetEvent('police:server:TrackHandcuffTime', function(isHandcuffed)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if isHandcuffed then
        -- Ghi lại thời gian bắt đầu bị còng
        handcuffTimeTracker[src] = {
            startTime = os.time(),
            citizenid = player.PlayerData.citizenid
        }
    else
        -- Xóa tracking khi được mở còng
        handcuffTimeTracker[src] = nil
    end
end)

-- Xóa tracking khi người chơi thoát game
AddEventHandler('playerDropped', function()
    local src = source
    if handcuffTimeTracker[src] then
        handcuffTimeTracker[src] = nil
    end
end)
