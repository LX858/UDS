QBCore = nil
local scriptname = GetCurrentResourceName()

-- Biến cho admin UI
local adminPanelOpen = false
local currentRoomData = {}

-- Khởi tạo QBCore
Citizen.CreateThread(function()
    while QBCore == nil do
        QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(100)
    end
end)

-- Mở Admin Panel
RegisterNetEvent(scriptname .. ':openAdminPanel')
AddEventHandler(scriptname .. ':openAdminPanel', function(roomData)
    adminPanelOpen = true
    currentRoomData = roomData
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    
    SendNUIMessage({
        type = 'setSoundURL',
        url = Config.SoundURL
    })
    
    -- Đợi 100ms rồi mới gửi message
    Citizen.Wait(100)
    
    local message = {
        type = 'openAdminPanel',
        data = roomData
    }
    SendNUIMessage(message)
end)

-- Cập nhật dữ liệu phòng
RegisterNetEvent(scriptname .. ':updateRoomData')
AddEventHandler(scriptname .. ':updateRoomData', function(roomData)
    currentRoomData = roomData
    SendNUIMessage({
        type = 'updateRoomData',
        data = roomData
    })
end)

-- Hiển thị người thắng
RegisterNetEvent(scriptname .. ':showWinner')
AddEventHandler(scriptname .. ':showWinner', function(winner)
    SendNUIMessage({
        type = 'showWinner',
        winner = winner
    })
end)

-- NUI Callbacks
RegisterNUICallback('createRoom', function(data, cb)
    TriggerServerEvent(scriptname .. ':createRoom', data)
    cb('ok')
end)

RegisterNUICallback('startBomberEvent', function(data, cb)
    TriggerServerEvent(scriptname .. ':startBomberEvent', data)
    cb('ok')
end)

RegisterNUICallback('stopBomberEvent', function(data, cb)
    TriggerServerEvent(scriptname .. ':stopBomberEvent')
    cb('ok')
end)

RegisterNUICallback('closeAdminPanel', function(data, cb)
    adminPanelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'closeAdminPanel'
    })
    cb('ok')
end)

RegisterNUICallback('sendNotificationStart', function(data, cb)
    TriggerServerEvent(scriptname .. ':sendNotificationStart')
    cb('ok')
end)

RegisterNUICallback('sendNotificationEnd', function(data, cb)
    TriggerServerEvent(scriptname .. ':sendNotificationEnd')
    cb('ok')
end)

-- =============================================
-- ADMIN FOLLOW / SPECTATE
-- =============================================
local adminFollowCam = nil
local adminFollowSource = nil
local adminFollowActive = false

local function StopAdminFollow()
    adminFollowActive = false
    adminFollowSource = nil
    if adminFollowCam then
        DestroyCam(adminFollowCam, false)
        RenderScriptCams(false, false, 0, true, false)
        adminFollowCam = nil
    end
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
end

RegisterNUICallback('adminFollowPlayer', function(data, cb)
    local targetSource = data.source
    if not targetSource then cb('err') return end

    -- Tàng hình, freeze admin
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    adminFollowSource = targetSource
    adminFollowActive = true

    -- Tạo camera
    if adminFollowCam then
        DestroyCam(adminFollowCam, false)
    end
    adminFollowCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(adminFollowCam, true)
    RenderScriptCams(true, false, 0, true, false)

    cb('ok')
end)

RegisterNUICallback('adminStopFollow', function(data, cb)
    StopAdminFollow()
    cb('ok')
end)

-- Thread cập nhật camera theo dõi người chơi
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if adminFollowActive and adminFollowCam and adminFollowSource then
            local targetPlayer = GetPlayerFromServerId(adminFollowSource)
            if targetPlayer ~= -1 then
                local targetPed = GetPlayerPed(targetPlayer)
                if DoesEntityExist(targetPed) then
                    -- Teleport admin đến vị trí target
                    local coords = GetEntityCoords(targetPed)
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)

                    -- Camera phía trên đầu, nhìn từ hơi xa + cao (kiểu txAdmin)
                    local heading = GetEntityHeading(targetPed)
                    local camX = coords.x + math.sin(math.rad(heading)) * 3.5
                    local camY = coords.y - math.cos(math.rad(heading)) * 3.5
                    local camZ = coords.z + 3.0
                    SetCamCoord(adminFollowCam, camX, camY, camZ)
                    PointCamAtEntity(adminFollowCam, targetPed, 0.0, 0.0, 0.0, true)

                    -- Hiển thị tên và phím điều hướng
                    local name = GetPlayerName(targetPlayer) or '...'
                    SetTextFont(4)
                    SetTextScale(0.45, 0.45)
                    SetTextColour(255, 215, 0, 255)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextCentre(true)
                    SetTextEntry('STRING')
                    AddTextComponentString('~y~[THEO DOI]~w~ ' .. name)
                    DrawText(0.5, 0.05)

                    SetTextFont(0)
                    SetTextScale(0.3, 0.3)
                    SetTextColour(220, 220, 220, 255)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextCentre(true)
                    SetTextEntry('STRING')
                    AddTextComponentString('~g~[A]~w~ Nguoi truoc    ~g~[D]~w~ Nguoi tiep theo    ~r~[X / ESC]~w~ Dung theo doi')
                    DrawText(0.5, 0.075)

                    -- Phím A/D để chuyển
                    if IsControlJustPressed(0, 34) then -- A
                        TriggerServerEvent(scriptname .. ':adminGetNextPlayer', adminFollowSource, -1)
                    elseif IsControlJustPressed(0, 35) then -- D
                        TriggerServerEvent(scriptname .. ':adminGetNextPlayer', adminFollowSource, 1)
                    elseif IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then -- X hoặc ESC
                        StopAdminFollow()
                        SendNUIMessage({ type = 'adminFollowStopped' })
                    end
                end
            else
                -- Player không còn online, dừng
                StopAdminFollow()
                SendNUIMessage({ type = 'adminFollowStopped' })
            end
        else
            Wait(500)
        end
    end
end)

-- Nhận player mới từ server khi ấn A/D
RegisterNetEvent(scriptname .. ':adminSwitchTarget', function(newSource)
    adminFollowSource = newSource
    SendNUIMessage({ type = 'adminFollowSwitch', source = newSource })
end)

-- ESC để đóng
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if adminPanelOpen then
            if IsControlJustReleased(0, 322) then -- ESC
                adminPanelOpen = false
                SetNuiFocus(false, false)
                TriggerServerEvent(scriptname .. ':closeAdminPanel')
                SendNUIMessage({
                    type = 'closeAdminPanel'
                })
            end
        end
    end
end)
