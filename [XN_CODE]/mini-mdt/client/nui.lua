-- MINI MDT Client NUI Bridge
local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil

if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

local function GetPlayerData()
    if Config.Framework == 'qbx' and QBX then
        local data = QBX:GetPlayerData()
        if data and data.job then return data end
    end
    if QBCore and QBCore.Functions then
        local data = QBCore.Functions.GetPlayerData()
        if data and data.job then return data end
    end
    return {}
end

local function GetPlayerGradeLevel()
    local PlayerData = GetPlayerData()
    if not PlayerData or not PlayerData.job then
        return 0
    end
    local grade = PlayerData.job.grade
    if grade == nil then return 0 end
    
    if type(grade) == 'table' then
        local lvl = grade.level
        if lvl == nil then lvl = grade.grade end
        if lvl == nil then lvl = grade.number end
        return tonumber(lvl) or 0
    end
    return tonumber(grade) or 0
end

-- Search players
RegisterNUICallback('searchPlayers', function(data, cb)
    lib.callback('mini-mdt:searchPlayers', false, function(result)
        cb(result)
    end, data.searchTerm)
end)

RegisterNUICallback('searchOfflinePrisonPlayers', function(data, cb)
    lib.callback('mini-mdt:searchOfflinePrisonPlayers', false, function(result)
        cb(result or {})
    end, data)
end)

-- Get nearby players (tìm người xung quanh)
RegisterNUICallback('getNearbyPlayers', function(data, cb)
    lib.callback('mini-mdt:getNearbyPlayers', false, function(result)
        cb(result or {})
    end, data)
end)

-- Get records
RegisterNUICallback('getRecords', function(data, cb)
    lib.callback('mini-mdt:getRecords', false, function(result)
        cb(result)
    end)
end)

-- Get today records
RegisterNUICallback('getTodayRecords', function(data, cb)
    lib.callback('mini-mdt:getTodayRecords', false, function(result)
        cb(result)
    end)
end)

-- Get offline prison history
RegisterNUICallback('getOfflinePrisonHistory', function(data, cb)
    lib.callback('mini-mdt:getOfflinePrisonHistory', false, function(result)
        cb(result)
    end)
end)

-- Add offline prison
RegisterNUICallback('addOfflinePrison', function(data, cb)
    lib.callback('mini-mdt:addOfflinePrison', false, function(result)
        cb(result)
    end, data)
end)

-- Release offline prison
RegisterNUICallback('releaseOfflinePrison', function(data, cb)
    lib.callback('mini-mdt:releaseOfflinePrison', false, function(result)
        cb(result)
    end, data)
end)

-- Search offline prison
RegisterNUICallback('searchOfflinePrison', function(data, cb)
    lib.callback('mini-mdt:searchOfflinePrison', false, function(result)
        cb(result)
    end, data)
end)

-- Search records by handler
RegisterNUICallback('searchRecordsByHandler', function(data, cb)
    lib.callback('mini-mdt:searchRecordsByHandler', false, function(result)
        cb(result)
    end, data)
end)

-- Search records by offender
RegisterNUICallback('searchRecordsByOffender', function(data, cb)
    lib.callback('mini-mdt:searchRecordsByOffender', false, function(result)
        cb(result)
    end, data)
end)

-- Get record detail
RegisterNUICallback('getRecordDetail', function(data, cb)
    lib.callback('mini-mdt:getRecordDetail', false, function(result)
        cb(result)
    end, data.recordId)
end)

-- Create record
RegisterNUICallback('createRecord', function(data, cb)
    lib.callback('mini-mdt:createRecord', false, function(result)
        cb(result)
    end, data)
end)

-- Add offender
RegisterNUICallback('addOffender', function(data, cb)
    lib.callback('mini-mdt:addOffender', false, function(result)
        cb(result)
    end, data)
end)

-- Add fine
RegisterNUICallback('addFine', function(data, cb)
    lib.callback('mini-mdt:addFine', false, function(result)
        cb(result)
    end, data)
end)

-- Get online officers
RegisterNUICallback('getOnlineOfficers', function(data, cb)
    lib.callback('mini-mdt:getOnlineOfficers', false, function(result)
        cb(result)
    end)
end)

-- Add officer
RegisterNUICallback('addOfficer', function(data, cb)
    lib.callback('mini-mdt:addOfficer', false, function(result)
        cb(result)
    end, data)
end)

-- ========== CHARGES CALLBACKS ==========

-- Get charges
RegisterNUICallback('getCharges', function(data, cb)
    lib.callback('mini-mdt:getCharges', false, function(result)
        cb(result)
    end)
end)

-- Create charge
RegisterNUICallback('createCharge', function(data, cb)
    lib.callback('mini-mdt:createCharge', false, function(result)
        cb(result)
    end, data)
end)

-- Update charge
RegisterNUICallback('updateCharge', function(data, cb)
    lib.callback('mini-mdt:updateCharge', false, function(result)
        cb(result)
    end, data)
end)

-- Delete charge
RegisterNUICallback('deleteCharge', function(data, cb)
    local responded = false
    local timeoutTimer = SetTimeout(5000, function()
        if not responded then
            responded = true
            cb({ success = false, message = 'Timeout: Server không phản hồi' })
        end
    end)
    
    lib.callback('mini-mdt:deleteCharge', false, function(result)
        if not responded then
            responded = true
            cb(result or { success = false, message = 'No response from server' })
        end
    end, data.id)
end)

-- ========== NEW CASE WORKFLOW CALLBACKS ==========

-- Get current officer
RegisterNUICallback('getCurrentOfficer', function(data, cb)
    lib.callback('mini-mdt:getCurrentOfficer', false, function(result)
        cb(result)
    end)
end)

-- Get player info
RegisterNUICallback('getPlayerInfo', function(data, cb)
    local responded = false
    local timeoutTimer = SetTimeout(5000, function()
        if not responded then
            responded = true
            cb({ success = false, error = 'Client timeout' })
        end
    end)
    
    lib.callback('mini-mdt:getPlayerInfo', false, function(result)
        if not responded then
            responded = true
            cb(result or { success = false, error = 'No data' })
        end
    end, data)
end)

-- Finalize case
RegisterNUICallback('finalizeCase', function(data, cb)
    local responded = false
    local timeoutTimer = SetTimeout(10000, function()
        if not responded then
            responded = true
            cb({ success = false, message = 'Client timeout' })
        end
    end)
    
    lib.callback('mini-mdt:finalizeCase', false, function(result)
        if not responded then
            responded = true
            
            if result and result.success then
                if data.offenders and type(data.offenders) == 'table' then
                    for _, offender in pairs(data.offenders) do
                        if offender.prisonTime and tonumber(offender.prisonTime) > 0 then
                            TriggerEvent('nl_hotcut:phatlaodong', {
                                citizenid = offender.citizenid,
                                time = tonumber(offender.prisonTime),
                                reason = data.summary or 'Kết án từ MDT'
                            })
                        end
                    end
                end
            end
            
            cb(result or { success = false, message = 'No data' })
        end
    end, data)
end)

-- Notify
RegisterNUICallback('notify', function(data, cb)
    cb('ok')
    QBCore.Functions.Notify(data.message, data.type)
end)

-- ========== PRISON CALLBACKS ==========

-- Send to prison (Phạt Tù)
RegisterNUICallback('sendToPrison', function(data, cb)
    local playerId = tonumber(data.playerId or data.pid)
    if not playerId or not data.actions then
        cb({ success = false, message = 'Thieu thong tin Player ID hoac so bai' })
        return
    end

    TriggerServerEvent('esx_communityservice:sendToCommunityService', playerId, tonumber(data.actions))

    cb({ success = true, message = 'Da gui lenh phat tu cho Player ID: ' .. playerId .. ' voi ' .. data.actions .. ' bai' })
end)

-- Cancel prison (Hủy Phạt Tù)
RegisterNUICallback('cancelPrison', function(data, cb)
    local playerId = tonumber(data.playerId or data.pid)
    if not playerId then
        cb({ success = false, message = 'Thieu thong tin Player ID' })
        return
    end

    TriggerServerEvent('esx_communityservice:processReleasePunish', playerId)

    cb({ success = true, message = 'Da gui lenh huy phat tu cho Player ID: ' .. playerId })
end)

-- Offline prison (Phạt Logout)
RegisterNUICallback('offlinePrison', function(data, cb)
    local result = lib.callback.await('mini-mdt:saveOfflinePrison', false, data)
    
    -- Then trigger server event to actually punish (bypass nl_hotcut UI)
    if result and result.success then
        -- Gửi log Discord
        lib.callback('mini-mdt:getPlayerByPID', false, function(playerResult)
            if playerResult and playerResult.success then
                TriggerServerEvent('mini-mdt:server:logPrison', {
                    name = playerResult.data.name,
                    pid = playerResult.data.pid,
                    citizenid = playerResult.data.citizenid
                }, data.reason or 'Phạt tạm giam Logout')
            end
        end, tonumber(data.playerId or data.pid))
        
        TriggerServerEvent('esx_communityservice:processOfflinePunish', (data.playerId or data.pid), data.reason)
    end
    
    cb(result or { success = false, message = 'Không có phản hồi từ server' })
end)

-- Cancel offline prison (Hủy phạt Logout)
RegisterNUICallback('cancelOfflinePrison', function(data, cb)
    local result = lib.callback.await('mini-mdt:releaseOfflinePrison', false, data)
    
    -- Then trigger server event to actually release (bypass nl_hotcut UI)
    if result and result.success then
        -- Gửi log Discord
        lib.callback('mini-mdt:getPlayerByPID', false, function(playerResult)
            if playerResult and playerResult.success then
                TriggerServerEvent('mini-mdt:server:logRelease', {
                    name = playerResult.data.name,
                    pid = playerResult.data.pid,
                    citizenid = playerResult.data.citizenid
                }, 'Hủy phạt tạm giam Logout')
            end
        end, tonumber(data.playerId or data.pid))
        
        TriggerServerEvent('esx_communityservice:processReleaseOffline', (data.playerId or data.pid))
    end
    
    cb(result or { success = false, message = 'Không có phản hồi từ server' })
end)

-- Get offline prison history
RegisterNUICallback('getOfflinePrisonHistory', function(data, cb)
    local result = lib.callback.await('mini-mdt:getOfflinePrisonHistory', false)
    cb(result or {})
end)

-- Get player by PID (unrestricted database lookup)
RegisterNUICallback('getPlayerByPID', function(data, cb)
    local result = lib.callback.await('mini-mdt:getPlayerByPID', false, (data.playerId or data.pid))
    cb(result or { success = false, error = 'Không có phản hồi từ server' })
end)

-- Quick Finalize
RegisterNUICallback('quickFinalize', function(data, cb)
    local result = lib.callback.await('mini-mdt:quickFinalize', false, data)
    cb(result or { success = false, message = 'Không có phản hồi từ server' })
end)

-- Tablet callbacks
RegisterNUICallback('tabletOption', function(data, cb)
    cb('ok')
    
    local playerGrade = GetPlayerGradeLevel()
    local minGrade = tonumber(Config.MinGradeToOpenMDT) or 1
    if playerGrade < minGrade then
        QBCore.Functions.Notify(('Cấp bậc tối thiểu (cấp %s) mới được sử dụng tablet!'):format(minGrade), 'error')
        SetNuiFocus(false, false)
        return
    end

    -- Spawn tablet và animation trước khi mở UI
    local ped = PlayerPedId()
    
    -- Load animation dict
    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    -- Load prop model
    local propModel = GetHashKey('sf_prop_sf_tablet_01a')
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do
        Wait(10)
    end
    
    -- Spawn tablet prop
    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, false)
    SetEntityAsMissionEntity(tabletProp, true, true)
    
    -- Attach to hand (bone 28422 = right hand)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- Play animation
    TaskPlayAnim(ped, animDict, "idle_a", 8.0, 8.0, -1, 49, 0, false, false, false)
    
    Wait(100)
    
    if data.option == 'mdt' then
        SetNuiFocus(false, false)
        Wait(100)
        -- Mở MDT trực tiếp bằng function
        openMDT()
    elseif data.option == 'quick' then
        SetNuiFocus(false, false)
        Wait(100)
        -- Mở Quick Finalize modal
        local PlayerData = GetPlayerData()
        if PlayerData and PlayerData.job then
            local playerGrade = GetPlayerGradeLevel()
            SendNUIMessage({
                action = 'openQuickFinalize',
                config = {
                    playerGrade = playerGrade,
                    minGradeForCharges = Config.MinGradeForCharges or 14
                }
            })
            SetNuiFocus(true, true)
        else
            -- Nếu không mở được Quick Finalize thì xóa tablet
            ClearPedTasks(ped)
            if tabletProp and DoesEntityExist(tabletProp) then
                DeleteEntity(tabletProp)
                tabletProp = nil
            end
        end
    end
end)

RegisterNUICallback('closeTabletMenu', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    -- Không cần xóa tablet vì chưa spawn khi mở menu
end)

-- Update Badge Photo
RegisterNUICallback('updateBadgePhoto', function(data, cb)
    lib.callback('mini-mdt:updateBadgePhoto', false, function(result)
        cb(result)
    end, data)
end)

-- Close Quick Finalize Modal
RegisterNUICallback('closeQuick', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    
    -- Xóa tablet prop và tắt animation khi đóng Quick Finalize
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end)

-- Issue Citizen ID
RegisterNUICallback('issueCitizenID', function(data, cb)
    lib.callback('mini-mdt:server:issueCitizenID', false, function(result)
        cb(result)
    end, data.targetPlayerId or data.targetPid)
end)

-- ========== PATROL SYSTEM NUI CALLBACKS ==========

RegisterNUICallback('getPatrolData', function(data, cb)
    lib.callback('mini-mdt:getPatrolData', false, function(result)
        cb(result or { success = false, message = "Không nhận được phản hồi từ server!" })
    end)
end)

RegisterNUICallback('patrolArea', function(data, cb)
    lib.callback('mini-mdt:patrolArea', false, function(result)
        cb(result or { success = false, message = "Không nhận được phản hồi từ server!" })
    end, tonumber(data.pointId))
end)

