local SCRIPT_VERSION = "1.0.6"
DrinkInProggres = false
PlayersDrunkLevel = {}
ServerCallbacks = {}

function compareVersions(currentVersion, remoteVersion)
    local currentParts = {}
    local remoteParts = {}
    
    for part in string.gmatch(currentVersion, "%d+") do
        table.insert(currentParts, tonumber(part))
    end
    
    for part in string.gmatch(remoteVersion, "%d+") do
        table.insert(remoteParts, tonumber(part))
    end
    
    local minLength = math.min(#currentParts, #remoteParts)
    for i = 1, minLength do
        if currentParts[i] < remoteParts[i] then
            return false
        elseif currentParts[i] > remoteParts[i] then
            return true
        end
    end
    
    return #currentParts >= #remoteParts
end

AddEventHandler("playerDropped", function(reason)
    local playerId = source
    
    if PlayersDrunkLevel[playerId] then
        if SavePlayerDrunk then
            SavePlayerDrunk(playerId, PlayersDrunkLevel[playerId])
        elseif SaveToSQL then
            SaveToSQL(playerId, PlayersDrunkLevel[playerId])
        end
        PlayersDrunkLevel[playerId] = nil
    end
end)

RegisterServerEvent("NRG_AlcoEffect:SavePlayerDrunkLevel")
AddEventHandler("NRG_AlcoEffect:SavePlayerDrunkLevel", function(drunkLevel)
    local playerId = source
    local level = tonumber(drunkLevel) or 0
    
    PlayersDrunkLevel[playerId] = level
    
    if SavePlayerDrunk then
        SavePlayerDrunk(playerId, level)
    elseif SaveToSQL then
        SaveToSQL(playerId, level)
    end
end)

RegisterServerEvent("NRG_AlcoEffect:AskForAlcoCheck")
AddEventHandler("NRG_AlcoEffect:AskForAlcoCheck", function(targetPlayerId)
    local requesterId = source
    
    if targetPlayerId == requesterId then
        TriggerClientEvent("NRG_AlcoEffect:AnswerClientForAlcomat", source, false, source, true)
    else
        TriggerClientEvent("NRG_AlcoEffect:AskClientForAlcomat", targetPlayerId, requesterId)
    end
end)

RegisterServerEvent("NRG_AlcoEffect:AnswerForAlcoCheck")
AddEventHandler("NRG_AlcoEffect:AnswerForAlcoCheck", function(requesterId, accepted)
    TriggerClientEvent("NRG_AlcoEffect:AnswerClientForAlcomat", requesterId, accepted, source)
end)

RegisterServerEvent("NRG_AlcoEffect:ToDoStomachLavage")
AddEventHandler("NRG_AlcoEffect:ToDoStomachLavage", function(targetPlayerId)
    TriggerClientEvent("NRG_AlcoEffect:ClientStomachLavage", targetPlayerId)
end)

RegisterServerEvent("NRG_AlcoEffect:synchAnime")
AddEventHandler("NRG_AlcoEffect:synchAnime", function(targetPlayerId, coords, shouldPosition)
    TriggerClientEvent("NRG_AlcoEffect:synchAnimeC", targetPlayerId, coords, shouldPosition)
end)

function RegisterServerCallback(eventName, callback)
    ServerCallbacks[eventName] = callback
end

RegisterNetEvent("NRGalcoeffect:triggerCallback")
AddEventHandler("NRGalcoeffect:triggerCallback", function(eventName, requestId, ...)
    local playerId = source
    
    if ServerCallbacks[eventName] then
        ServerCallbacks[eventName](playerId, function(...)
            TriggerClientEvent("NRGalcoeffect:callbackResponse", playerId, requestId, ...)
        end, ...)
    end
end)

RegisterServerCallback("NRG_AlcoEffect:PlayerDrunkLevel", function(playerId, callback, targetPlayerId)
    local level = GetDrunkLevelServer(targetPlayerId)
    callback(tostring(math.floor(level)))
end)

function NRGscriptsAddDrunkLevelS(targetPlayerId)
    TriggerClientEvent("NRG_AlcoEffect:NRGscriptsAddDrunkLevel", targetPlayerId)
end

function GetDrunkLevelServer(targetPlayerId)
    if GetPlayerDrunk then
        local realDrunk = GetPlayerDrunk(targetPlayerId)
        return realDrunk
    end
    return PlayersDrunkLevel[targetPlayerId] or 0
end

function GetPlayerDrunkMetadataS(targetPlayerId)
    if GetPlayerDrunk then
        return GetPlayerDrunk(targetPlayerId)
    end
    return PlayersDrunkLevel[targetPlayerId] or 0, nil
end

exports("AddDrunkLevelServer", NRGscriptsAddDrunkLevelS)
exports("GetDrunkLevelServer", GetDrunkLevelServer)
exports("GetPlayerDrunkMetadata", GetPlayerDrunkMetadataS)

local function GetStageDescription(level)
    if level >= Config.DrunkStageFourFrom then
        return "Say bí tỉ (Giai đoạn 4)"
    elseif level >= Config.DrunkStageThreeFrom then
        return "Rất say (Giai đoạn 3)"
    elseif level >= Config.DrunkStageTwoFrom then
        return "Say (Giai đoạn 2)"
    elseif level >= Config.DrunkStageOneFrom then
        return "Hơi say (Giai đoạn 1)"
    else
        return "Tỉnh táo"
    end
end

local function HandleCheckDrunkCommand(source, args)
    local src = source
    local targetId = src
    
    if args and args[1] and tonumber(args[1]) then
        targetId = tonumber(args[1])
    end
    
    if targetId == 0 and src == 0 then
        print("Console không thể tự kiểm tra, hãy nhập ID: checkdrunk [id]")
        return
    end
    
    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 then
        if src == 0 then
            print("❌ Không tìm thấy người chơi có ID: " .. tostring(targetId))
        else
            if Config.OxLib then
                TriggerClientEvent("ox_lib:notify", src, {
                    title = "Kiểm tra nồng độ cồn",
                    description = "Không tìm thấy người chơi có ID: " .. tostring(targetId),
                    type = "error"
                })
            else
                TriggerClientEvent("QBCore:Notify", src, "Không tìm thấy người chơi ID: " .. tostring(targetId), "error")
            end
        end
        return
    end
    
    local level = GetDrunkLevelServer(targetId)
    local stageText = GetStageDescription(level)
    local msg = string.format("Nồng độ cồn: %d/100 | Trạng thái: %s", math.floor(level), stageText)
    
    if targetId ~= src then
        msg = string.format("[ID: %s] Nồng độ cồn: %d/100 | Trạng thái: %s", targetId, math.floor(level), stageText)
    end
    
    if src == 0 then
        print(msg)
    else
        if Config.OxLib then
            TriggerClientEvent("ox_lib:notify", src, {
                title = "Nồng độ cồn (Metadata)",
                description = msg,
                type = level > 0 and "warning" or "info"
            })
        else
            TriggerClientEvent("QBCore:Notify", src, msg, level > 0 and "primary" or "success")
        end
    end
end

RegisterCommand("checkdrunk", HandleCheckDrunkCommand, false)
RegisterCommand("kiemtracon", HandleCheckDrunkCommand, false)


