local config = require 'config.shared'
IsEscorted = false

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    -- Không tự động reset trạng thái handcuff khi người chơi load vào game
    -- TriggerServerEvent('police:server:SetHandcuffStatus', false)

    -- Thay vào đó, yêu cầu server khôi phục trạng thái handcuff từ database
    TriggerServerEvent('police:server:RestoreHandcuffStatus')

    local trackerClothingData = {}

    if QBX.PlayerData.metadata.tracker then
        trackerClothingData.outfitData = {
            accessory = {
                item = 13,
                texture = 0
            }
        }
    else
        trackerClothingData.outfitData = {
            accessory = {
                item = -1,
                texture = 0
            }
        }
    end

    TriggerEvent('qb-clothing:client:loadOutfit', trackerClothingData)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    -- Chỉ reset handcuff status nếu người chơi không thực sự bị còng
    -- Điều này tránh việc mất trạng thái còng tay khi disconnect/reconnect
    if not QBX.PlayerData.metadata.ishandcuffed then
        TriggerServerEvent('police:server:SetHandcuffStatus', false)
    end
    IsEscorted = false
    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, true, false)
end)

RegisterNetEvent('police:client:sendBillingMail', function(amount)
    SetTimeout(math.random(2500, 4000), function()
        local charinfo = QBX.PlayerData.charinfo
        local gender = locale(charinfo.gender == 1 and 'info.mrs' or 'info.mr')
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = locale('email.sender'),
            subject = locale('email.subject'),
            message = locale('email.message', gender, charinfo.lastname, amount),
            button = {}
        })
    end)
end)


RegisterNetEvent('police:client:policeAlert', function(coords, text, camId)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)
    if camId then
        exports.qbx_core:Notify(text, 'inform', 5000, street1name.. ' ' ..street2name.. '- Camera ID: ' .. camId)
    else
        exports.qbx_core:Notify(text,'inform', 5000, street1name.. ' ' ..street2name)
    end
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, 0, true)
    local transG = 250
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)
    local blipText = locale('info.blip_text', text)
    SetBlipSprite(blip, 60)
    SetBlipSprite(blip2, 161)
    SetBlipColour(blip, 0)
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
        Wait(180 * 4)
        transG -= 1
        SetBlipAlpha(blip, transG)
        SetBlipAlpha(blip2, transG)
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)

RegisterNetEvent('police:client:SendToJail', function(time)
    TriggerServerEvent('police:server:SetHandcuffStatus', false)
    IsEscorted = false
    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, true, false)
    TriggerEvent('prison:client:Enter', time)
end)

RegisterNetEvent('police:client:SendPoliceEmergencyAlert', function()
    TriggerServerEvent('police:server:policeAlert', locale('info.officer_down', QBX.PlayerData.charinfo.lastname, QBX.PlayerData.metadata.callsign))
    TriggerServerEvent('hospital:server:ambulanceAlert', locale('info.officer_down', QBX.PlayerData.charinfo.lastname, QBX.PlayerData.metadata.callsign))
end)

CreateThread(function()
    for i = 1, #config.locations.stations do
        local station = config.locations.stations[i]
        local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
        SetBlipSprite(blip, station.sprite or 58)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, 3)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(station.label)
        EndTextCommandSetBlipName(blip)
    end
end)
