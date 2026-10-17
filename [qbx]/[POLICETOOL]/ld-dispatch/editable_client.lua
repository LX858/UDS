local QBCore = exports['qb-core']:GetCoreObject()

local function getCoords(c)
    if not c then return nil, nil, nil end
    if type(c) == 'vector3' then
        return c.x, c.y, c.z
    elseif type(c) == 'table' then
        if c.x and c.y and c.z then
            return c.x, c.y, c.z
        elseif c[1] and c[2] and c[3] then
            return c[1], c[2], c[3]
        end
    end
    return nil, nil, nil
end

local function isCoordinateList(coords)
    if type(coords) == 'table' then
        local first = coords[1]
        if first and (type(first) == 'table' or type(first) == 'vector3') then
            return true
        end
    end
    return false
end

function DispatchBlip(data)
    -- Use QBCore notification for compatibility
    QBCore.Functions.Notify(data.title .. ' - ' .. data.code, 'primary', 5000)
    PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', false, false, true)
    
    if data.coords and isCoordinateList(data.coords) then
        local blips = {}
        for i = 1, #data.coords do
            local x, y, z = getCoords(data.coords[i])
            if x and y and z then
                local blip = AddBlipForCoord(x, y, z)
                SetBlipSprite(blip, data.blip.blipid)
                SetBlipDisplay(blip, 4)
                SetBlipScale(blip, Config.BlipScale)
                SetBlipColour(blip, data.blip.blipcolor)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(data.title .. " [#".. data.dispatchnumber .."]")
                EndTextCommandSetBlipName(blip)
                PulseBlip(blip)
                table.insert(blips, blip)
            end
        end
        Wait(Config.RemoveBlipAfter)
        for i = 1, #blips do
            RemoveBlip(blips[i])
        end
    else
        local x, y, z = getCoords(data.coords)
        if x and y and z then
            local blip = AddBlipForCoord(x, y, z)
            SetBlipSprite(blip, data.blip.blipid)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, data.blip.blipcolor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(data.title .. " [#".. data.dispatchnumber .."]")
            EndTextCommandSetBlipName(blip)
            PulseBlip(blip)
            Wait(Config.RemoveBlipAfter)
            RemoveBlip(blip)
        end
    end
end