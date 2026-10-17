local PREFIX = "^5[IBONOJA]^7 "
local lastChanges = {}

local function sendMessage(target, r, g, b, msg)
    if target == 0 then
        print(PREFIX .. msg)
        return
    end

    TriggerClientEvent("chat:addMessage", target, {
        color = { r or 255, g or 255, b or 255 },
        args = { "[IBONOJA]", msg }
    })
end

local function parseBool(val)
    if type(val) ~= "string" then
        return nil
    end

    local lowerVal = val:lower()
    if lowerVal == "true" then
        return true
    elseif lowerVal == "false" then
        return false
    end

    return nil
end

local function parseSingle(args)
    local name = args[1]
    local enable = parseBool(args[2])

    if not name or enable == nil then
        return nil, "Uso: /change <entitySetName> <true|false> [color]"
    end

    local color = nil
    if args[3] then
        color = tonumber(args[3])
    end

    if args[3] and not color then
        return nil, "El color debe ser un número entero."
    end

    local item = {
        name = name,
        enable = enable
    }

    if color ~= nil then
        item.color = color
    end

    return { item }, nil
end

local function parseBulk(args)
    if #args < 2 then
        return nil, "Uso: /change bulk name:true[:color] name2:false name3:true:4 ..."
    end

    local changes = {}
    for i = 2, #args do
        local raw = args[i]
        local parts = {}
        for part in string.gmatch(raw, "([^:]+)") do
            parts[#parts + 1] = part
        end

        local name = parts[1]
        local enable = parseBool(parts[2] or "")
        local color = nil
        if parts[3] then
            color = tonumber(parts[3])
        end

        if not name or enable == nil then
            return nil, string.format("Entrada inválida: '%s' (usa name:true[:color])", raw)
        end

        if parts[3] and not color then
            return nil, string.format("Color inválido en '%s' (debe ser número)", raw)
        end

        local item = {
            name = name,
            enable = enable
        }

        if color ~= nil then
            item.color = color
        end

        changes[#changes + 1] = item
    end

    return changes, nil
end

RegisterCommand("change", function(source, args, rawCommand)
    if not args or #args == 0 then
        sendMessage(source, 255, 0, 0, "Uso: /change <entitySetName> <true|false> [color]  |  /change bulk name:true[:color] ...")
        return
    end

    local changes, err
    if tostring(args[1]):lower() == "bulk" then
        changes, err = parseBulk(args)
    else
        changes, err = parseSingle(args)
    end

    if err then
        sendMessage(source, 255, 0, 0, err)
        return
    end

    lastChanges = changes
    SetResourceKvp("ibonoja:lastChanges", json.encode(lastChanges))
    TriggerClientEvent("ibonoja:setEntitySets", -1, lastChanges)

    local details = {}
    for _, item in ipairs(changes) do
        local colorStr = item.color and (" (color " .. item.color .. ")") or ""
        details[#details + 1] = item.name .. " -> " .. tostring(item.enable) .. colorStr
    end

    sendMessage(source, 0, 255, 0, "Cambio enviado: " .. table.concat(details, " | "))
end, false)

RegisterNetEvent("ibonoja:requestSync", function()
    local src = source
    if #lastChanges > 0 then
        TriggerClientEvent("ibonoja:setEntitySets", src, lastChanges)
    end
end)

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local savedChanges = GetResourceKvpString("ibonoja:lastChanges")
    if savedChanges then
        local decoded = json.decode(savedChanges)
        if decoded and #decoded > 0 then
            lastChanges = decoded
            TriggerClientEvent("ibonoja:setEntitySets", -1, lastChanges)
            print(PREFIX .. "Estado restaurado: " .. #lastChanges .. " cambios.")
        end
    end
end)

CreateThread(function()
    print(PREFIX .. "Server script cargado. Comando disponible: /change (sin permisos)")
end)
