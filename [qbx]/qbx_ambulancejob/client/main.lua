local sharedConfig = require 'config.shared'
InBedDict = 'anim@gangops@morgue@table@'
InBedAnim = 'body_search'
IsInHospitalBed = false
HealAnimDict = 'mini@cpr@char_a@cpr_str'
HealAnim = 'cpr_pumpchest'
EmsNotified = false
CanLeaveBed = true
OnPainKillers = false

---Notifies EMS of a injury at a location
---@param coords vector3
---@param text string
RegisterNetEvent('hospital:client:ambulanceAlert', function(coords, text)
    if GetInvokingResource() then return end
    local streets = qbx.getStreetName(coords)
    exports.qbx_core:Notify(locale('text.alert'), 'inform', nil, text .. ' | ' .. streets.main .. ' ' .. streets.cross)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = locale('info.ems_alert', text)
    SetBlipSprite(blip, 153)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 1)
    SetBlipColour(blip2, 1)
    SetBlipDisplay(blip, 4)
    SetBlipDisplay(blip2, 8)
    SetBlipAlpha(blip, transG)
    SetBlipAlpha(blip2, transG)
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    SetBlipAsShortRange(blip, false)
    SetBlipAsShortRange(blip2, false)
    PulseBlip(blip2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(blipText)
    EndTextCommandSetBlipName(blip)
    while transG ~= 0 do
        Wait(720)
        transG -= 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)

---Revives player, healing all injuries
---Intended to be called from client or server.
RegisterNetEvent('hospital:client:Revive', function()
    if IsInHospitalBed then
        lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
        CanLeaveBed = true
    end

    EmsNotified = false
end)

RegisterNetEvent('qbx_medical:client:playerRevived', function()
    EmsNotified = false
end)

---Sends player phone email with hospital bill.
---@param amount number
RegisterNetEvent('hospital:client:SendBillEmail', function(amount)
    if GetInvokingResource() then return end
    SetTimeout(math.random(2500, 4000), function()
        local charInfo = GetPlayerCharInfo()
        local lastname = charInfo.lastname or ''
        local gender = charInfo.gender == 1 and locale('info.mrs') or locale('info.mr')
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('mail.sender'),
            subject = locale('mail.subject'),
            message = locale('mail.message', gender, lastname, amount),
            button = {}
        })
    end)
end)

---Sets blips for stations on map
CreateThread(function()
    for _, station in pairs(sharedConfig.locations.stations) do
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, 489)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 1.2)
        SetBlipColour(blip, 8)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)

function GetClosestPlayer()
    return lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
end

function OnKeyPress(cb)
    if IsControlJustPressed(0, 38) then
        lib.hideTextUI()
        cb()
    end
end

-- Callback để lấy tọa độ của người chơi
lib.callback.register('qbx_ambulancejob:client:getPlayerCoords', function()
    return GetEntityCoords(cache.ped)
end)

-- Event để khởi tạo quá trình kéo người chơi ngất/chết
RegisterNetEvent('hospital:client:initDragDownedPlayers', function()
    if GetInvokingResource() then return end

    local myPed = cache.ped
    local myCoords = GetEntityCoords(myPed)

    -- Lấy danh sách người chơi gần trong bán kính 10m (tối ưu hơn là duyệt tất cả)
    local nearbyPlayers = lib.getNearbyPlayers(myCoords, 10.0, true)
    local nearbyPlayerIds = {}

    for _, playerData in pairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(playerData.id)
        if serverId and serverId > 0 then
            table.insert(nearbyPlayerIds, serverId)
        end
    end

    -- Gửi danh sách người chơi gần lên server để kiểm tra trạng thái
    TriggerServerEvent('hospital:server:dragAllDownedPlayers', nearbyPlayerIds)
end)

---Event để kéo tất cả người chơi đang ngất/chết về phía chân người sử dụng
---@param downedPlayers table Danh sách người chơi đang ngất/chết với tọa độ
RegisterNetEvent('hospital:client:dragDownedPlayers', function(downedPlayers)
    if GetInvokingResource() then return end

    local myPed = cache.ped
    local myCoords = GetEntityCoords(myPed)
    local myForwardVector = GetEntityForwardVector(myPed)

    -- Tính vị trí ở phía trước chân người dùng (khoảng 1.5m)
    local targetPos = vector3(
        myCoords.x + myForwardVector.x * 1.5,
        myCoords.y + myForwardVector.y * 1.5,
        myCoords.z
    )

    local draggedCount = 0
    for _, playerData in pairs(downedPlayers) do
        local targetPed = GetPlayerPed(GetPlayerFromServerId(playerData.source))
        if DoesEntityExist(targetPed) then
            -- Di chuyển ped trực tiếp đến vị trí đích
            SetEntityCoords(targetPed, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)

            draggedCount = draggedCount + 1
        end
    end

    if draggedCount > 0 then
        exports.qbx_core:Notify(locale('success.dragged_players', draggedCount), 'success')
    else
        exports.qbx_core:Notify(locale('error.no_downed_players'), 'error')
    end
end)

---Cho bệnh nhân nằm thẳng để chuẩn bị CPR
RegisterNetEvent('hospital:client:prepareForCPR', function()
    if GetInvokingResource() then return end

    -- Clear animation chết (nằm co) ngay lập tức
    ClearPedTasksImmediately(cache.ped)
    Wait(100)

    -- Freeze người chơi
    FreezeEntityPosition(cache.ped, true)

    -- Load animation nằm ngửa (dùng animation CPR victim)
    lib.requestAnimDict('mini@cpr@char_b@cpr_def')
    TaskPlayAnim(cache.ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, -8.0, -1, 1, 0, false, false, false)

    exports.qbx_core:Notify('Bác sĩ đang chuẩn bị cứu bạn...', 'inform')

    -- Unfreeze và clear animation sau 15 giây (thời gian CPR)
    SetTimeout(16000, function()
        FreezeEntityPosition(cache.ped, false)
        ClearPedTasksImmediately(cache.ped)
    end)
end)

---Nhận CPR từ bác sĩ (synced animation)
RegisterNetEvent('hospital:client:receiveCPR', function(cprTime)
    if GetInvokingResource() then return end

    -- Play animation bệnh nhân đang được CPR - ngực sẽ nhảy lên xuống khi bác sĩ ấn
    lib.requestAnimDict('mini@cpr@char_b@cpr_str')
    TaskPlayAnim(cache.ped, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 33, 0, false, false, false)

    -- Tự động dừng animation sau khi hết thời gian CPR
    Wait(cprTime * 1000)
    RemoveAnimDict('mini@cpr@char_b@cpr_str')
    ClearPedTasks(cache.ped)
end)