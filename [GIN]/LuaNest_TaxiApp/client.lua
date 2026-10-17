local function register()
    if GetResourceState('lb-phone') ~= 'started' then return end
    print("[LuaNest_TaxiApp] Đang đăng ký Custom App vào lb-phone...")
    if Config.CustomApps then
        for identifier, appData in pairs(Config.CustomApps) do
            local app = {}
            for k, v in pairs(appData) do app[k] = v end
            app.identifier = identifier
            local success, err = exports["lb-phone"]:AddCustomApp(app)
            if not success and err then
                print(("[LuaNest_TaxiApp] Không thể thêm custom app '%s': %s"):format(identifier, tostring(err)))
            end
        end
    elseif Config.App then
        exports["lb-phone"]:AddCustomApp(Config.App)
    end
end

CreateThread(function()
    while GetResourceState('lb-phone') ~= 'started' do
        Wait(500)
    end
    Wait(500)
    register()
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'lb-phone' then
        Wait(500)
        register()
    end
end)

AddEventHandler('phone:requestApps', register)

RegisterNetEvent('ubee:makeCall', function(number)
    if GetResourceState('lb-phone') == 'started' and number then
        exports['lb-phone']:CreateCall({ number = tostring(number) })
    end
end)

local state = { ride = nil, job = nil, invite = nil, driver = nil, error = nil }

local blips = {}
local function trackBlip(key, p, sprite, label)
    if not p then
        if blips[key] then RemoveBlip(blips[key]); blips[key] = nil end
        return
    end
    local b = blips[key]
    if b then return SetBlipCoords(b, p.x + 0.0, p.y + 0.0, 0.0) end
    b = AddBlipForCoord(p.x + 0.0, p.y + 0.0, 0.0)
    SetBlipSprite(b, sprite); SetBlipColour(b, 5); SetBlipScale(b, 0.9)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName(label); EndTextCommandSetBlipName(b)
    blips[key] = b
end

RegisterNetEvent('ubee:ride', function(r)
    trackBlip('ride', r and r.status == 'accepted' and r.driverPos, 198, 'Ubee · Tài xế')
    state.ride = r
    if r and (r.status == 'done' or r.status == 'cancelled') then state.lastRide = r; state.ride = nil end
end)

RegisterNetEvent('ubee:job', function(r)
    local prev = state.job and state.job.status
    state.job = (r and (r.status == 'accepted' or r.status == 'onTrip')) and r or nil
    trackBlip('job', state.job and r.status == 'accepted' and r.passengerPos, 280, 'Ubee · Khách')
    if state.job and r.status ~= prev then -- server re-pushes every tick; only route once per status
        local t = r.status == 'accepted' and r.pickup or r.dest
        SetNewWaypoint(t.x + 0.0, t.y + 0.0)
    end
end)

RegisterNetEvent('ubee:pos', function(dx, dy, px, py)
    local d, p = { x = dx, y = dy }, { x = px, y = py }
    local r, j = state.ride, state.job
    if r then r.driverPos, r.passengerPos = d, p; trackBlip('ride', r.status == 'accepted' and d, 198, 'Ubee · Tài xế') end
    if j then j.driverPos, j.passengerPos = d, p; trackBlip('job', j.status == 'accepted' and p, 280, 'Ubee · Khách') end
end)

RegisterNetEvent('ubee:invite', function(r) state.invite = r end)
RegisterNetEvent('ubee:driver', function(d, err) state.driver, state.error = d, err end)

local historyWait = {}
RegisterNetEvent('ubee:history', function(role, rows)
    if historyWait[role] then historyWait[role]:resolve(rows) end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then for _, b in pairs(blips) do RemoveBlip(b) end end
end)

RegisterNUICallback('getState', function(_, cb)
    cb(state)
    state.lastRide, state.error = nil, nil -- one-shot
end)

RegisterNUICallback('getConfig', function(_, cb)
    cb({ rates = Config.Rates, minFare = Config.MinFare, registerFee = Config.RegisterFee })
end)

RegisterNUICallback('getHistory', function(data, cb)
    local role = data.role == 'driven' and 'driven' or 'booked'
    local p = promise.new()
    historyWait[role] = p
    SetTimeout(5000, function() p:resolve({}) end)
    TriggerServerEvent('ubee:history', role)
    cb(Citizen.Await(p))
    historyWait[role] = nil
end)

local actions = {
    requestRide = 'ubee:requestRide', cancelRide = 'ubee:cancelRide', completeRide = 'ubee:completeRide',
    registerDriver = 'ubee:registerDriver', setPaused = 'ubee:setPaused', unregisterDriver = 'ubee:unregisterDriver',
    answerInvite = 'ubee:answerInvite', driverCancel = 'ubee:driverCancel', contact = 'ubee:contact',
}
for name, event in pairs(actions) do
    RegisterNUICallback(name, function(data, cb)
        TriggerServerEvent(event, data and data.value)
        cb({ ok = true })
    end)
end

local function streetLabel(x, y)
    local a, b = GetStreetNameAtCoord(x + 0.0, y + 0.0, 0.0)
    local label = GetStreetNameFromHashKey(a)
    if b ~= 0 then label = label .. ' - ' .. GetStreetNameFromHashKey(b) end
    return { x = x, y = y, label = label }
end

RegisterNUICallback('getLocation', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    cb(streetLabel(c.x, c.y))
end)

RegisterNUICallback('getWaypoint', function(_, cb)
    local blip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(blip) then return cb({}) end
    local c = GetBlipInfoIdCoord(blip)
    cb(streetLabel(c.x, c.y))
end)

RegisterNUICallback('streetAt', function(data, cb)
    cb(streetLabel(data.x, data.y))
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    SetNewWaypoint(data.x + 0.0, data.y + 0.0)
    cb({ ok = true })
end)

RegisterNUICallback('getVehicle', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return cb({ isDriver = false }) end
    local model = GetEntityModel(veh)
    cb({
        model = GetLabelText(GetDisplayNameFromVehicleModel(model)),
        plate = (GetVehicleNumberPlateText(veh):gsub('^%s*(.-)%s*$', '%1')),
        type = IsThisModelABike(model) and 'bike' or 'car',
        isDriver = GetPedInVehicleSeat(veh, -1) == ped,
    })
end)
