Trace                       = function(...)
    if not Config.DEBUG then
        return
    end

    local logLine = ""
    local logString = { ... }

    if IsDuplicityVersion() then
        logLine = os.date('%Y-%m-%d %H:%M:%S', os.time())
    end

    logLine = logLine .. " [" .. (GetCurrentResourceName() or "LOG") .. "] "

    for i = 1, #logString do
        logLine = logLine .. tostring(logString[i]) .. " "
    end

    print(logLine)
end

TableLength                 = function(tbl)
    if type(tbl) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

Shuffle                     = function(tbl)
    local n = #tbl
    for i = n, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

SelectRandomItem            = function(lootTable)
    local totalChance = 0
    for _, item in pairs(lootTable) do
        totalChance = totalChance + item.chance
    end

    local randomChance = math.random(1, totalChance)

    local cumulativeChance = 0
    for _, item in pairs(lootTable) do
        cumulativeChance = cumulativeChance + item.chance
        if randomChance <= cumulativeChance then
            return item
        end
    end
end

Translate                   = function(key, args)
    if not Config.Locale then
        return key
    end

    local translation = Locales[Config.Locale] and Locales[Config.Locale][key]

    if not translation then
        return key
    else
        if args then
            local i = 1
            translation = translation:gsub("%%s", function()
                local arg = args[i]
                print("Replacing %s with:", arg)
                i = i + 1
                return tostring(arg)
            end)
        end
    end

    return translation
end

IsResourceStartedOrStarting = function(resource)
    local state = GetResourceState(resource)
    return state == "started" or state == "starting"
end

GetContractTypeForCount     = function(count)
    local numericCount = tonumber(count) or 0

    local closestKey = nil
    local closestDistance = nil

    for key, data in pairs(Config.Contracts or {}) do
        local minCount = tonumber(data.min) or 0
        local maxCount = tonumber(data.max) or minCount

        if numericCount >= minCount and numericCount <= maxCount then
            return key, ("CONTRACT_DIFFICULTY_" .. string.upper(key))
        end

        local distance
        if numericCount < minCount then
            distance = (minCount - numericCount)
        else
            distance = (numericCount - maxCount)
        end

        if closestDistance == nil or distance < closestDistance then
            closestDistance = distance
            closestKey = key
        end
    end

    if closestKey then
        return closestKey, ("CONTRACT_DIFFICULTY_" .. string.upper(closestKey))
    end

    return "easy", "CONTRACT_DIFFICULTY_EASY"
end

if Config.Framework == "auto" then
    Trace("Detecting framework")

    if IsResourceStartedOrStarting("qbx_core") then
        Config.Framework = "qbox"
    elseif IsResourceStartedOrStarting("qb-core") then
        Config.Framework = "qbcore"
    elseif IsResourceStartedOrStarting("es_extended") then
        Config.Framework = "esx"
    else
        Config.Framework = "standalone"
    end
    Trace("Detected framework: " .. Config.Framework)
end

if Config.Inventory == "auto" then
    Trace("Detecting inventory")

    if IsResourceStartedOrStarting("ox_inventory") then
        Config.Inventory = "ox_inventory"
    elseif IsResourceStartedOrStarting("qb-inventory") then
        Config.Inventory = "qb-inventory"
    elseif IsResourceStartedOrStarting("tgiann-inventory") then
        Config.Inventory = "tgiann-inventory"
    elseif IsResourceStartedOrStarting("qs-inventory") then
        Config.Inventory = "qs-inventory"
    elseif IsResourceStartedOrStarting("ps-inventory") then
        Config.Inventory = "ps-inventory"
    elseif IsResourceStartedOrStarting("origen_inventory") then
        Config.Inventory = "origen_inventory"
    elseif IsResourceStartedOrStarting("core_inventory") then
        Config.Inventory = "core_inventory"
    elseif IsResourceStartedOrStarting("codem-inventory") then
        Config.Inventory = "codem-inventory"
    elseif Config.Framework == "qbcore" or Config.Framework == "qbox" then
        Config.Inventory = "qb-inventory"
    elseif Config.Framework == "esx" then
        Config.Inventory = "ox_inventory"
    end

    Trace("Detected inventory: " .. Config.Inventory)
end

if Config.Target == "auto" then
    Trace("Detecting interactions")

    if IsResourceStartedOrStarting("qb-target") then
        Config.Target = "qb-target"
    elseif IsResourceStartedOrStarting("ox_target") then
        Config.Target = "ox_target"
    else
        Config.Target = "standalone"
    end

    Trace("Detected interactions: " .. Config.Target)
end