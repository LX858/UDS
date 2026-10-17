local defaultMods = {}
local vehicle = nil

openLightsController = function()
    if not IsPedInAnyVehicle(cache.ped, false) then notify(locale('notify_error_no_vehicle_in'), 'error') return end
    vehicle = GetVehiclePedIsIn(cache.ped, false)
    defaultMods = getVehicleMods(vehicle)
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local enabled, xr, xg, xb = GetVehicleXenonLightsCustomColor(vehicle)
    local xenonColors = {}

    for _, v in pairs(Config.xenonColors) do
        xenonColors[#xenonColors + 1] = v.rgb
    end

    SendNUI('lightsMenu', {
        neons = string.format("rgb(%s, %s, %s)", nr and nr or 255, ng and ng or 255, nb and nb or 255),
        xenons = string.format("rgb(%s, %s, %s)", xr and xr or 255, xg and xg or 255, xb and xb or 255),
        defaultColors = Config.neonsColors,
        defaultXenonColors = xenonColors,
        xenonsEnabled = IsToggleModOn(vehicle, 22) and true or false,
        neonsEnabled = IsVehicleNeonLightEnabled(vehicle, 2) and true or false,
    })
    ShowNUI('setVisibleLightsMenu', true)
end
exports("openLightsController", openLightsController)
lib.callback.register('mt_workshops:client:openLightsController', openLightsController)

RegisterNuiCallback('installLights', function(data, cb)
    if data.type == 'neons' then
        for i = 0, 4 do
            SetVehicleNeonLightEnabled(vehicle, i, data.enabled)
        end
    else
        ToggleVehicleMod(vehicle, 22, data.enabled)
    end
    cb(true)
end)

RegisterNuiCallback('lightsChange', function(data, cb)
    local r, g, b = string.match(data.color, "rgb%((%d+), (%d+), (%d+)%)")
    if data.type == 'neons' then
        SetVehicleNeonLightsColour(vehicle, tonumber(r), tonumber(g), tonumber(b))
    else
        local color = 0

        --print(data.color)

        for _, v in pairs(Config.xenonColors) do
            if v.rgb == data.color then
                color = v.value
                break
            end
        end

        ClearVehicleXenonLightsCustomColor(vehicle)
        SetVehicleXenonLightsColor(vehicle, color)
    end
    cb(true)
end)

RegisterNuiCallback('closeLightsMenu', function(data, cb)
    ShowNUI('setVisibleLightsMenu', false)
    local newMods = getVehicleMods(vehicle)
    setVehicleMods(vehicle, defaultMods)
    cb(true)
end)

RegisterNuiCallback('saveLights', function(data, cb)
    local itemName = data.type == 'neons' and 'neon_custom' or 'cosmetics'
    local tuningType = data.type == 'neons' and 'Neons' or 'Xenons'
    
    -- Check if player has required item
    if not getHasItem(itemName, 1) then
        local itemLabel = Config.itemLabels[itemName] or itemName
        notify(locale('notify_missing_item') .. ' ' .. itemLabel, 'error')
        cb(true)
        return
    end
    
    ShowNUI('setVisibleLightsMenu', false)
    
    -- Remove item
    lib.callback.await('mt_workshops:server:removeItem', false, itemName, 1)
    
    local newMods = getVehicleMods(vehicle)
    TriggerServerEvent('mt_workshops:server:setVehicleMods', VehToNet(vehicle), newMods, cache.serverId, tuningType)
    vehicle = nil
    defaultMods = {}
    cb(true)
end)

RegisterNetEvent('mt_workshops:client:setVehicleMods', function(vehicle, newMods, player, tuningType)
    if not NetworkDoesEntityExistWithNetworkId(vehicle) then return end
    setVehicleMods(NetToVeh(vehicle), newMods)
    if cache.serverId == player then
        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        local itemUsed = 'cosmetics'
        if tuningType == 'Extras' then
            itemUsed = 'extras_controller'
        elseif tuningType == 'Neons' then
            itemUsed = 'neon_custom'
        end
        lib.callback.await('mt_workshops:server:saveVehicleMods', false, NetToVeh(vehicle), newMods, true, { x = coords.x, y = coords.y, z = coords.z, w = heading }, tuningType or 'Lights', itemUsed)
    end
end)