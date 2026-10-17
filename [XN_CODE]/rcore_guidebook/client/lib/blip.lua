Blips = {}

---@param name string
---@param blip number
---@param coords vector3
---@param options table
---@return number
function createBlip(name, blip, coords, options)
    local x, y, z = table.unpack(coords)

    if blip == -1 then
        return
    end

    local ourBlip
    if GetGameName() == GameType.FIVEM then
        ourBlip = AddBlipForCoord(x, y, z)
        SetBlipSprite(ourBlip, blip)
        SetBlipDisplay(ourBlip, options.type or 2)
        SetBlipScale(ourBlip, options.scale or 1.0)
        SetBlipColour(ourBlip, options.color or 4)
        SetBlipAsShortRange(ourBlip, options.shortRange or false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(name)
        EndTextCommandSetBlipName(ourBlip)
        Blips[ourBlip] = ourBlip
    elseif GetGameName() == GameType.REDM then
        ourBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
        SetBlipSprite(ourBlip, blip, true)
        SetBlipScale(ourBlip, options.scale or 1.0)

        Citizen.InvokeNative(0x9CB1A1623062F402, ourBlip, name)
    end


    return ourBlip
end

function removeBlip(id)
    if DoesBlipExist(Blips[id]) then
        RemoveBlip(Blips[id])
        dbg.debug('Deleted blip %s', id)
    end
end

function removeAllBlips()
    for _, blip in pairs(Blips) do
        removeBlip(blip)
    end
end

---@param instance number
---@return nil|number
function getBlip(instance)
    if Blips[instance] ~= nil then
        return Blips[instance]
    end
    return nil
end

---@return table
function getBlips()
    return Blips
end
