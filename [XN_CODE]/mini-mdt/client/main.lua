-- MINI MDT Client Main
local QBCore = exports['qb-core']:GetCoreObject()
local QBX = nil
local isOpen = false

-- Global variable cho tablet prop (để có thể truy cập từ nui.lua)
tabletProp = nil

-- Try to load QBX if available
if GetResourceState('qbx_core') == 'started' or GetResourceState('qbx_core') == 'starting' then
    QBX = exports.qbx_core
end

-- Get Player Data based on framework
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

-- Get player job grade level safely
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

-- Helper function to notify player
local function NotifyPlayer(msg, msgType)
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(msg, msgType or 'error')
    elseif lib and lib.notify then
        lib.notify({
            title = 'MDT',
            description = msg,
            type = msgType or 'error'
        })
    end
end

-- Command mở MDT cho police job
RegisterCommand(Config.Command, function()
    local PlayerData = GetPlayerData()

    if not PlayerData or not PlayerData.job then
        NotifyPlayer('Lỗi: Không tìm thấy thông tin người chơi', 'error')
        return
    end

    if not Config.AllowedJobs[PlayerData.job.name] then
        NotifyPlayer('Bạn không có quyền sử dụng lệnh này!', 'error')
        return
    end

    if not PlayerData.job.onduty then
        NotifyPlayer('Bạn phải on duty để sử dụng!', 'error')
        return
    end

    local playerGrade = GetPlayerGradeLevel()
    local minGrade = tonumber(Config.MinGradeToOpenMDT) or 1
    if playerGrade < minGrade then
        NotifyPlayer(('Bạn không có quyền hạn để mở tính năng này!'):format(minGrade), 'error')
        return
    end

    openMDT()
end, false)

-- Open MDT function
function openMDT()
    local PlayerData = GetPlayerData()
    local playerGrade = GetPlayerGradeLevel()
    local minGrade = tonumber(Config.MinGradeToOpenMDT) or 1
    
    if playerGrade < minGrade then
        NotifyPlayer(('Bạn không có quyền hạn để mở tính năng này!'):format(minGrade), 'error')
        return
    end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMDT',
        config = {
            crimeTags = Config.CrimeTags,
            fineTypes = Config.FineTypes,
            minGradeForCharges = Config.MinGradeForCharges or 14,
            playerGrade = playerGrade,
            idCardPrice = Config.IDCardPrice or 1000
        }
    })
end

-- Close MDT function
function closeMDT()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeMDT'
    })
    
    -- Xóa tablet prop và tắt animation khi đóng MDT
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end
end

-- NUI Callback to close
RegisterNUICallback('close', function(data, cb)
    closeMDT()
    cb('ok')
end)

-- Quick Finalize command removed - use tablet item instead

-- Event khi sử dụng item tablet
RegisterNetEvent('tablet:openMenu', function()
    local PlayerData = GetPlayerData()
    
    if not PlayerData or not PlayerData.job then
        NotifyPlayer('Lỗi: Không tìm thấy thông tin người chơi', 'error')
        return
    end
    
    if not Config.AllowedJobs[PlayerData.job.name] then
        NotifyPlayer('Bạn không có quyền sử dụng thiết bị này!', 'error')
        return
    end
    
    if not PlayerData.job.onduty then
        NotifyPlayer('Bạn phải on duty để sử dụng!', 'error')
        return
    end
    
    local playerGrade = GetPlayerGradeLevel()
    local minGrade = tonumber(Config.MinGradeToOpenMDT) or 1
    if playerGrade < minGrade then
        NotifyPlayer(('Bạn không có quyền hạn để mở tính năng này!'):format(minGrade), 'error')
        return
    end
    
    -- Chỉ mở menu chọn, chưa spawn tablet
    SendNUIMessage({
        action = 'openTabletMenu',
        config = {
            playerGrade = playerGrade,
            minGradeForCharges = Config.MinGradeForCharges or 14
        }
    })
    SetNuiFocus(true, true)
end)

-- Event để gửi tù (được gọi từ server sau khi kết án)
RegisterNetEvent('mini-mdt:client:sendToJail', function(playerId, actionsCount)
    TriggerServerEvent('esx_communityservice:sendToCommunityService', playerId, actionsCount)
end)

-- Export
exports('IsOpen', function()
    return isOpen
end)

-- ========== PATROL SYSTEM CLIENT BLIPS ==========
local PatrolBlips = {}
local PatrolStates = {}

local function RemovePatrolBlips()
    for _, blips in pairs(PatrolBlips) do
        if blips.main and DoesBlipExist(blips.main) then
            RemoveBlip(blips.main)
        end
        if blips.radius and DoesBlipExist(blips.radius) then
            RemoveBlip(blips.radius)
        end
    end
    PatrolBlips = {}
end

local function UpdateBlipColors()
    local gameTimer = GetGameTimer()
    for _, point in ipairs(Config.PatrolPoints) do
        local blips = PatrolBlips[point.id]
        if blips and blips.radius and DoesBlipExist(blips.radius) then
            local state = PatrolStates[point.id]
            local isGreen = false
            if state and state.lastPatrolled and state.lastPatrolled > 0 then
                local totalElapsed = (state.serverTime - state.lastPatrolled) + (gameTimer - state.receivedAt) / 1000
                local cooldownSec = (point.cooldown or 15) * 60
                if totalElapsed < cooldownSec then
                    isGreen = true
                end
            end

            if isGreen then
                SetBlipColour(blips.radius, 47) -- Orange
            else
                SetBlipColour(blips.radius, 1) -- Red
            end
        end
    end
end

local function CreatePatrolBlips()
    RemovePatrolBlips()
    
    local PlayerData = GetPlayerData()
    if not PlayerData then
        return
    end

    lib.callback('mini-mdt:getPatrolStates', false, function(states)
        if not states then return end
        
        local gameTimer = GetGameTimer()
        for id, state in pairs(states) do
            PatrolStates[id] = {
                lastPatrolled = state.lastPatrolled,
                officerName = state.officerName,
                officerRank = state.officerRank,
                officerCallsign = state.officerCallsign,
                serverTime = state.serverTime,
                receivedAt = gameTimer
            }
        end

        for _, point in ipairs(Config.PatrolPoints) do
            local mainBlip = AddBlipForCoord(point.coords.x, point.coords.y, point.coords.z)
            SetBlipSprite(mainBlip, point.sprite or 140)
            SetBlipDisplay(mainBlip, 4)
            SetBlipScale(mainBlip, 0.8)
            SetBlipColour(mainBlip, 1) -- Red
            SetBlipAsShortRange(mainBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("[NGHỀ BẨN]: " .. point.name)
            EndTextCommandSetBlipName(mainBlip)

            local radiusBlip = AddBlipForRadius(point.coords.x, point.coords.y, point.coords.z, point.radius or 100.0)
            SetBlipRotation(radiusBlip, 0)
            SetBlipAlpha(radiusBlip, 128)

            PatrolBlips[point.id] = {
                main = mainBlip,
                radius = radiusBlip
            }
        end
        
        UpdateBlipColors()
    end)
end

-- Server Event updates
RegisterNetEvent('mini-mdt:client:updatePatrolState', function(pointId, state)
    PatrolStates[pointId] = {
        lastPatrolled = state.lastPatrolled,
        officerName = state.officerName,
        officerRank = state.officerRank,
        officerCallsign = state.officerCallsign,
        serverTime = state.serverTime,
        receivedAt = GetGameTimer()
    }
    UpdateBlipColors()
end)

-- Background thread to update colors (ticks back to red automatically)
CreateThread(function()
    while true do
        Wait(5000)
        local PlayerData = GetPlayerData()
        if PlayerData then
            if next(PatrolBlips) then
                UpdateBlipColors()
            else
                CreatePatrolBlips()
            end
        else
            if next(PatrolBlips) then
                RemovePatrolBlips()
            end
        end
    end
end)

-- Job and login handlers
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Wait(1000)
    CreatePatrolBlips()
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    Wait(1000)
    CreatePatrolBlips()
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    CreatePatrolBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(2000)
        CreatePatrolBlips()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        RemovePatrolBlips()
    end
end)

-- ========== PERSONAL COOLDOWN & ZONE PUSH SYSTEM ==========
local personalCooldownEndTime = 0
local lastPushWarning = 0

local function FormatTime(seconds)
    if seconds <= 0 then return "0 giây" end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    if m > 0 and s > 0 then
        return string.format("%d phút %d giây", m, s)
    elseif m > 0 then
        return string.format("%d phút", m)
    else
        return string.format("%d giây", s)
    end
end

local function HasPersonalCooldown()
    return GetGameTimer() < personalCooldownEndTime
end

local function GetRemainingCooldown()
    if not HasPersonalCooldown() then return 0 end
    return math.max(0, math.floor((personalCooldownEndTime - GetGameTimer()) / 1000))
end

local function SetPersonalCooldown(minutes, reason)
    local mins = tonumber(minutes) or (Config.PersonalCooldown and Config.PersonalCooldown.DefaultDuration) or 30
    local durationMs = mins * 60 * 1000
    personalCooldownEndTime = GetGameTimer() + durationMs
    
    local timeStr = FormatTime(mins * 60)
    local msg = "Bạn đã bị áp dụng thời gian cấm vào các khu vực nghề/zone trong " .. timeStr
    if reason and reason ~= "" then
        msg = msg .. " (Lý do: " .. reason .. ")"
    end
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(msg, 'warning', 6000)
    end
end

local function ClearPersonalCooldown()
    personalCooldownEndTime = 0
    if QBCore and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify('Thời gian cấm vào khu vực của bạn đã được gỡ bỏ.', 'success')
    end
end

-- Client Exports
exports('SetPlayerCooldown', function(minutes, reason)
    SetPersonalCooldown(minutes, reason)
end)

exports('GetPlayerCooldown', function()
    return GetRemainingCooldown()
end)

exports('HasPlayerCooldown', function()
    return HasPersonalCooldown()
end)

exports('ClearPlayerCooldown', function()
    ClearPersonalCooldown()
end)

-- Client Events
RegisterNetEvent('mini-mdt:client:setCooldown', function(minutes, reason)
    SetPersonalCooldown(minutes, reason)
end)

RegisterNetEvent('mini-mdt:client:clearCooldown', function()
    ClearPersonalCooldown()
end)

-- Background Thread: Kiểm tra & đưa người chơi ra ngoài an toàn nếu đang dính cooldown
CreateThread(function()
    while true do
        if HasPersonalCooldown() then
            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local closestDist = 99999.0
            local inAnyZone = false

            -- Gom tất cả các zone cần bảo vệ (PatrolPoints + RedZones)
            local allProtectedZones = {}
            if Config.PatrolPoints then
                for _, pt in ipairs(Config.PatrolPoints) do
                    allProtectedZones[#allProtectedZones + 1] = pt
                end
            end
            if Config.RedZones then
                for _, rz in ipairs(Config.RedZones) do
                    allProtectedZones[#allProtectedZones + 1] = rz
                end
            end

            for _, point in ipairs(allProtectedZones) do
                local zoneCoords = point.coords or point.robberyZone or point.door
                if zoneCoords then
                    local zoneRadius = point.radius or 100.0
                    local dist = #(pCoords - zoneCoords)

                    if dist < closestDist then
                        closestDist = dist
                    end

                    if dist <= zoneRadius then
                        inAnyZone = true
                        
                        -- Tính vector hướng từ tâm zone ra ngoài
                        local dx = pCoords.x - zoneCoords.x
                        local dy = pCoords.y - zoneCoords.y
                        local len = math.sqrt(dx * dx + dy * dy)
                        if len < 0.001 then
                            dx = 1.0
                            dy = 0.0
                            len = 1.0
                        end
                        local normX = dx / len
                        local normY = dy / len

                        -- Cấu hình khoảng cách an toàn đưa ra ngoài (mặc định 10.0m ngoài mép zone)
                        local cfg = Config.PersonalCooldown or {}
                        local bufferDist = cfg.BufferDistance or 10.0
                        local safeRadius = zoneRadius + bufferDist
                        local safeX = zoneCoords.x + (normX * safeRadius)
                        local safeY = zoneCoords.y + (normY * safeRadius)

                        -- Lấy cao độ mặt đất an toàn
                        local groundZ = pCoords.z
                        local foundGround, zPos = GetGroundZFor_3dCoord(safeX, safeY, pCoords.z + 50.0, false)
                        if foundGround and zPos > 0.0 then
                            groundZ = zPos
                        end

                        -- Hướng quay lưng ra khỏi zone
                        local heading = GetHeadingFromVector_2d(normX, normY)

                        -- Kiểm tra xem đang lái xe hay đi bộ
                        local inVeh = IsPedInAnyVehicle(ped, false)
                        local veh = inVeh and GetVehiclePedIsIn(ped, false) or 0

                        if inVeh and DoesEntityExist(veh) then
                            -- Đưa xe ra ngoài mép an toàn, triệt tiêu vận tốc để tránh va chạm/tai nạn
                            SetEntityCoords(veh, safeX, safeY, groundZ + 0.5, false, false, false, false)
                            SetEntityHeading(veh, heading)
                            SetEntityVelocity(veh, 0.0, 0.0, 0.0)
                            SetVehicleForwardSpeed(veh, 0.0)
                        else
                            -- Đưa người chơi ra ngoài an toàn, đứng vững không bị ngất/ngã
                            SetEntityCoords(ped, safeX, safeY, groundZ + 0.1, false, false, false, false)
                            SetEntityHeading(ped, heading)
                            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                        end

                        -- Gửi thông báo cảnh báo (chống spam)
                        local now = GetGameTimer()
                        local warnCooldown = cfg.WarningCooldown or 4000
                        if now - lastPushWarning >= warnCooldown then
                            lastPushWarning = now
                            local remSec = GetRemainingCooldown()
                            local timeStr = FormatTime(remSec)
                            local template = cfg.WarningMessage or "Bạn đang trong thời gian bị cấm vào khu vực này! Còn lại: %s"
                            local msg = string.format(template, timeStr)
                            local msgType = cfg.WarningType or 'error'

                            if QBCore and QBCore.Functions and QBCore.Functions.Notify then
                                QBCore.Functions.Notify(msg, msgType, 4000)
                            else
                                TriggerEvent('chat:addMessage', { args = { '^1[HỆ THỐNG]', msg } })
                            end
                        end

                        Wait(150)
                    end
                end
            end

            -- Dynamic sleep để tối ưu CPU
            if inAnyZone then
                Wait(50)
            elseif closestDist < 150.0 then
                Wait(200)
            elseif closestDist < 300.0 then
                Wait(500)
            else
                Wait(1000)
            end
        else
            -- Khi không có cooldown, chỉ cần check 1 giây 1 lần (0.00ms CPU)
            Wait(1000)
        end
    end
end)


