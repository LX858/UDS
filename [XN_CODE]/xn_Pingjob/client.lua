local currentHud = ""
local currentData = {}

function ToggleNUI(isShow, hud, job)
    SetNuiFocus(isShow, isShow)
    SendNUIMessage({
        action = "display_" .. hud,
        isShow = isShow,
        JobCheck = job or "default"
    })
    currentHud = isShow and hud or ""
end

-- Tính toán khoảng cách và thời gian trôi qua trên client
local function processCallList(list)
    if not list or type(list) ~= 'table' then return {} end
    local ped = PlayerPedId()
    local plyCoords = GetEntityCoords(ped)
    local now = GetCloudTimeAsInt()

    local processed = {}
    for i = 1, #list do
        local item = list[i]
        local coords = item.coords
        local distance = 0
        if coords then
            distance = #(plyCoords - vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3]))
        end

        local elapsedTime = now - (item.lastTime or now)
        if elapsedTime < 0 then elapsedTime = 0 end

        processed[#processed + 1] = {
            callerId = item.callerId,
            callerName = item.callerName,
            citizenId = item.citizenId,
            bucket = item.bucket or 0,
            accepterId = item.accepterId,
            accepterName = item.accepterName,
            blacklist = item.blacklist,
            coords = coords,
            distance = distance,
            time = elapsedTime,
            lastTime = item.lastTime
        }
    end
    return processed
end

function LoadCallData(directList)
    if not QBX or not QBX.PlayerData or not QBX.PlayerData.job or not QBX.PlayerData.job.onduty then
        currentData = {}
        SendNUIMessage({
            action = "update_menu",
            list = {},
            playerId = lib.cache("serverId") or GetPlayerServerId(PlayerId()),
            job = "",
        })
        return
    end

    local rawData = directList
    if not rawData then
        rawData = lib.callback.await('xn_pingjob:getData', false)
    end

    if rawData then
        currentData = processCallList(rawData)
        SendNUIMessage({
            action = "update_menu",
            list = currentData,
            playerId = lib.cache("serverId") or GetPlayerServerId(PlayerId()),
            job = QBX.PlayerData.job and QBX.PlayerData.job.label or "",
        })
    end
end

function LoadBlacklistData()
    local data = lib.callback.await('xn_pingjob:getBlacklist', false)
    if data then
        SendNUIMessage({
            action = "update_blacklist",
            list = data,
            job = (QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.label) or "",
        })
    end
end

-- Server chủ động push dữ liệu danh sách đơn tới các nhân viên trực
RegisterNetEvent("xn_pingjob:updateJobData", function(jobName, list)
    if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name == jobName and QBX.PlayerData.job.onduty then
        LoadCallData(list)
    end
end)

-- Server push cập nhật blacklist
RegisterNetEvent('xn_pingjob:refreshBlackList', function(jobName)
    if currentHud == "blacklist" and QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name == jobName then
        LoadBlacklistData()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(1500)
        if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.onduty then
            LoadCallData()
        end
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    CreateThread(function()
        Wait(500)
        if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.onduty then
            LoadCallData()
        else
            LoadCallData({})
        end
    end)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function()
    CreateThread(function()
        Wait(500)
        if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.onduty then
            LoadCallData()
        else
            LoadCallData({})
        end
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CreateThread(function()
            Wait(1000)
            if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.onduty then
                LoadCallData()
            end
        end)
    end
end)

lib.addKeybind({
    name = 'goibacsi',
    description = 'THAO TÁC MỞ MENU PINGJOB',
    defaultKey = 'F4',
    onPressed = function(self)
        if not QBX.PlayerData or not QBX.PlayerData.job or not QBX.PlayerData.job.onduty then
            exports.qbx_core:Notify("Bạn cần onduty để mở menu!", "error")
            return
        end
        
        local jobName = QBX.PlayerData.job.name
        if jobName == 'ambulance' or jobName == 'police' or jobName == 'taxi' or jobName == 'mechanic' then
            TriggerEvent('xn_pingjob:openMenu', jobName)
        else
            TriggerEvent('xn_pingjob:openMenu', 'ambulance')
        end
    end
})

RegisterNetEvent("xn_pingjob:pingTaxi", function()
    ExecuteCommand('goitaxi')
end)

RegisterCommand('blacklistmed', function()
    TriggerEvent('xn_pingjob:openBlacklist', 'ambulance')
end)

RegisterCommand('menumed', function()
    TriggerEvent('xn_pingjob:openMenu', 'ambulance')
end)

RegisterCommand('menutaxi', function()
    TriggerEvent('xn_pingjob:openMenu', 'taxi')
end)

RegisterNetEvent("xn_pingjob:pingSound", function()
    SendNUIMessage({
        action = "ping_sound"
    })
end)

AddEventHandler("xn_pingjob:openMenu", function(job)
    if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name == job then
        if not QBX.PlayerData.job.onduty then
            exports.qbx_core:Notify("Bạn cần onduty để mở menu!", "error")
            return
        end
        LoadCallData()
        ToggleNUI(true, "menu", QBX.PlayerData.job.name)
    end
end)

AddEventHandler("xn_pingjob:openBlacklist", function(job)
    if QBX.PlayerData and QBX.PlayerData.job and QBX.PlayerData.job.name == job then
        if not QBX.PlayerData.job.onduty then
            exports.qbx_core:Notify("Bạn cần onduty để mở blacklist!", "error")
            return
        end
        LoadBlacklistData()
        ToggleNUI(true, "blacklist", QBX.PlayerData.job.name)
    end
end)

RegisterNUICallback("call_service", function(data)
    if data.job == 'ambulance' then
        local playerState = LocalPlayer.state
        if playerState and playerState.inPvP then 
            return exports.qbx_core:Notify('Bạn đang ở trong PvP', 'success')
        end
    end
    TriggerServerEvent('xn_pingjob:callService', data.job)
    ToggleNUI(false, "ping")
end)

RegisterNUICallback("gps_service", function(data)
    GetGPS(data.id)
end)

RegisterNUICallback("accept_service", function(data)
    TriggerServerEvent("xn_pingjob:acceptService", data.id)
end)

RegisterNUICallback("cancel_service", function(data)
    TriggerServerEvent("xn_pingjob:cancelService", data.id)
end)

RegisterNUICallback("delete_service", function(data)
    TriggerServerEvent("xn_pingjob:deleteService", data.id)
end)

RegisterNUICallback("reset_bucket", function(data, cb)
    if data and data.id then
        TriggerServerEvent("xn_pingjob:resetPlayerBucket", data.id)
    end
    if cb then cb('ok') end
end)

RegisterNUICallback("pull_service", function(data, cb)
    if data and data.id then
        TriggerServerEvent("xn_pingjob:pullPlayerBody", data.id)
    end
    if cb then cb('ok') end
end)

RegisterNetEvent('xn_pingjob:pulledToCoords', function(coords)
    if coords then
        local ped = PlayerPedId()
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        CreateThread(function()
            Wait(150)
            local ground, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, true)
            if ground then
                SetEntityCoords(ped, coords.x, coords.y, groundZ + 0.1, false, false, false, true)
            end
        end)
    end
end)

local activeGpsTarget = nil
local isDrawing3D = false

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 100)
    ClearDrawOrigin()
end

local function StartGpsMarkerThread()
    if isDrawing3D then return end
    isDrawing3D = true

    CreateThread(function()
        while activeGpsTarget and activeGpsTarget.coords do
            local sleep = 1000
            local ped = PlayerPedId()
            local plyCoords = GetEntityCoords(ped)
            local targetCoords = vector3(activeGpsTarget.coords.x or activeGpsTarget.coords[1], activeGpsTarget.coords.y or activeGpsTarget.coords[2], activeGpsTarget.coords.z or activeGpsTarget.coords[3])
            local dist = #(plyCoords - targetCoords)

            if dist < 250.0 then
                if dist < 60.0 then
                    sleep = 0
                    -- Marker chỉ điểm hướng xuống
                    DrawMarker(2, targetCoords.x, targetCoords.y, targetCoords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 255, 60, 60, 200, false, true, 2, false, nil, nil, false)
                    
                    -- DrawText 3D
                    local targetId = activeGpsTarget.id or ""
                    local bucketInfo = (activeGpsTarget.bucket and activeGpsTarget.bucket ~= 0) and (" | ~y~Bucket: " .. activeGpsTarget.bucket .. "~s~") or ""
                    
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.5, "~r~[VỊ TRÍ CẦN CỨU]~s~")
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.3, "~w~ID: ~y~" .. targetId .. "~s~" .. bucketInfo)
                    DrawText3D(targetCoords.x, targetCoords.y, targetCoords.z + 1.1, "~g~Khoảng cách: ~w~" .. math.floor(dist) .. "m~s~")
                else
                    sleep = 400
                end
            else
                sleep = 1500
            end

            -- Nếu đã đến rất sát mục tiêu (< 3m) và đã ở gần hơn 15 giây thì tự tắt marker
            if dist < 3.0 then
                if not activeGpsTarget.arrivedTime then
                    activeGpsTarget.arrivedTime = GetCloudTimeAsInt()
                elseif (GetCloudTimeAsInt() - activeGpsTarget.arrivedTime) > 15 then
                    activeGpsTarget = nil
                    break
                end
            end

            Wait(sleep)
        end
        isDrawing3D = false
    end)
end

local function SetTargetWaypointAndMarker(playerId, coords, callerName, bucket)
    if not coords then return end
    local x = coords.x or coords[1]
    local y = coords.y or coords[2]
    local z = coords.z or coords[3]
    
    SetNewWaypoint(x, y)
    activeGpsTarget = {
        id = playerId,
        name = callerName or "Người cần cứu",
        coords = vector3(x, y, z),
        bucket = bucket or 0
    }
    StartGpsMarkerThread()
end

RegisterNetEvent('xn_pingjob:setWaypoint', function(coords, callerName, callerId, bucket)
    if coords then
        SetTargetWaypointAndMarker(callerId, coords, callerName, bucket)
        exports.qbx_core:Notify("Đã nhận đơn và đặt waypoint tới ID: " .. (callerId or ""), "success")
    end
end)

RegisterCommand('keoxac', function(source, args)
    if not QBX or not QBX.PlayerData or not QBX.PlayerData.job or not QBX.PlayerData.job.onduty then
        return exports.qbx_core:Notify("Bạn cần On-Duty để dùng lệnh này!", "error")
    end
    local targetId = (args and tonumber(args[1])) or (activeGpsTarget and activeGpsTarget.id)
    if not targetId then
        return exports.qbx_core:Notify("Vui lòng nhập ID hoặc bấm GPS người cần kéo trên bảng F4!", "error")
    end
    TriggerServerEvent("xn_pingjob:pullPlayerBody", targetId)
end, false)

TriggerEvent('chat:addSuggestion', '/keoxac', 'Kéo người ngất dưới lòng đất về vị trí của bạn (Dành cho bác sĩ)', {
    { name = "targetId", help = "ID người chơi cần kéo (Để trống sẽ lấy người đang có GPS)" }
})

RegisterNUICallback("new_blacklist", function(data)
    local player 
    while not player do
        local input = lib.inputDialog('Tạo blacklist', {
            {type = 'input', label = 'ID hoặc SteamID', description = 'Nếu người chơi Offline có thể nhập citizenid', required = true},
        })
        if not input then return end
        player = lib.callback.await('xn_pingjob:getPlayerName', false, tonumber(input[1]) or input[1])
        if not player then
            local alert = lib.alertDialog({
                header = 'Tạo blacklist',
                content = 'Không tìm thấy người chơi. Bạn có muốn thử lại không?',
                centered = true,
                cancel = true
            })
            if alert == "cancel" then return end
        end
    end
    
    local charinfo = player.PlayerData and player.PlayerData.charinfo or {}
    local defaultName = (charinfo.firstname or '') .. ' ' .. (charinfo.lastname or '')
    if defaultName == ' ' then defaultName = player.name or 'Người chơi' end

    local citizenId = (player.PlayerData and (player.PlayerData.pid or player.PlayerData.citizenid)) or player.citizenid or input[1]

    local input2 = lib.inputDialog('Tạo blacklist', {
        {type = 'input', label = 'Người chơi', default = defaultName, disabled = true},
        {type = 'date', required = true, label = 'Ngày hết hạn', icon = {'far', 'calendar'}, format = "DD/MM/YYYY"},
        {type = 'textarea', required = true, label = 'Lý do', placeholder = "Nhập lý do..."},
    })

    if not input2 then return end 

    local change = lib.callback.await('xn_pingjob:newBlacklist', false, citizenId, defaultName, input2[2], input2[3])
    
    if change then
        LoadBlacklistData()
        exports.qbx_core:Notify("Đã thêm blacklist thành công", "success")
    else
        local alert = lib.alertDialog({
            header = 'Tạo blacklist',
            content = 'Có lỗi. Vui lòng nhập lại!',
            centered = true,
            cancel = true
        })
        if alert == "cancel" then return end
    end
end)

RegisterNUICallback("delete_blacklist", function(data)
    local change = lib.callback.await('xn_pingjob:deleteBlacklist', false, data.player)
    if change then
        LoadBlacklistData()
        exports.qbx_core:Notify("Đã xóa blacklist", "success")
    end
end)

RegisterNUICallback("edit_blacklist", function(data)
    local input = lib.inputDialog('Chỉnh sửa blacklist', {
        {type = 'input', label = 'Người chơi', default = data.name, disabled = true},
        {type = 'date', required = true, label = 'Ngày hết hạn', icon = {'far', 'calendar'}, format = "DD/MM/YYYY"},
        {type = 'textarea', required = true, label = 'Lý do', placeholder = "Nhập lý do..."},
    })

    if not input then return end 

    local change = lib.callback.await('xn_pingjob:editBlacklist', false, data.player, input[2], input[3])
    if change then
        LoadBlacklistData()
        exports.qbx_core:Notify("Đã cập nhật blacklist", "success")
    else
        local alert = lib.alertDialog({
            header = 'Tạo blacklist',
            content = 'Có lỗi. Vui lòng nhập lại!',
            centered = true,
            cancel = true
        })
        if alert == "cancel" then return end
    end
end)

RegisterNUICallback("close", function()
    ToggleNUI(false, "ping")
    ToggleNUI(false, "menu")
    ToggleNUI(false, "blacklist")
end)

function GetGPS(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end

    -- Gọi callback server để lấy live coords thời gian thực
    local liveData = lib.callback.await('xn_pingjob:getLivePlayerCoords', false, playerId)
    if liveData and liveData.success and liveData.coords then
        SetTargetWaypointAndMarker(playerId, liveData.coords, liveData.name, liveData.bucket)
        local bucketMsg = (liveData.bucket and liveData.bucket ~= 0) and (" (Bucket: " .. liveData.bucket .. ")") or ""
        exports.qbx_core:Notify("Đã cập nhật GPS thời gian thực tới ID: " .. playerId .. bucketMsg, "success")
        return true
    end

    -- Fallback nếu không lấy được live coords từ server
    for _, v in pairs(currentData) do
        if v.callerId == playerId and v.coords then
            SetTargetWaypointAndMarker(playerId, v.coords, v.callerName, v.bucket)
            exports.qbx_core:Notify("Tọa độ GPS đã được cài đặt tới ID: " .. playerId, "success")
            return true
        end
    end
    exports.qbx_core:Notify("Không tìm thấy người chơi hoặc tọa độ!", "error")
end
