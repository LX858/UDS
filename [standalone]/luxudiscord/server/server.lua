local function GetConfig()
    return Config
end

Locales = require(string.format("locales/%s", Config.Locale))

Locale = function(key)
    local localeTable = Locales[Config.Locale]
    if not localeTable then
        return "Lang Doesn't Exist"
    end
    return localeTable[key] or key
end

exports("GetLocales", function()
    return Locales
end)

GetPlayerMugshot = function(playerId)
    local playerName = GetPlayerName(playerId)
    if not playerName then
        return false
    end
    
    local mugshot = lib.callback.await("LuxuModules:Client:GetMugshot", playerId)
    return mugshot or false
end

GetPlayersInt = function()
    local playerList = {}
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(playerList, tonumber(playerId))
    end
    return playerList
end

local function GetPlayerJobExport(playerId)
    if not playerId then
        return false
    end
    return Luxu.GetPlayerJob(playerId)
end

local function SetPlayerJobExport(playerId, job, grade)
    if not playerId then
        return false
    end
    return Luxu.SetPlayerJob(playerId, job, grade)
end

local function SetMetadataExport(playerId, metaKey, metaValue)
    local playerName = GetPlayerName(playerId)
    if not playerName then
        return false
    end
    
    local playerObject = Luxu.GetPlayerObject(playerId)
    if Framework == "qb" and playerObject then
        playerObject.Functions.SetMetaData(metaKey, metaValue)
        playerObject.Functions.Save()
    end
end

exports("GetConfig", GetConfig)
exports("GetPlayers", GetPlayersInt)
exports("GetPlayerMugshot", GetPlayerMugshot)
exports("GetPlayerJob", GetPlayerJobExport)
exports("SetPlayerJob", SetPlayerJobExport)
exports("setMetadata", SetMetadataExport)
