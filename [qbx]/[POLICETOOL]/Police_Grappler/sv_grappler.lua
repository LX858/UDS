grapplers = {}
handBrakeEnabled = {}

grapplerActions = {
    install = "install",
    deploy = "deploy",
    remove = "remove",
    reset = "reset"
}

grapplerModes = {
    installed = "installed",
    deployed = "deployed",
    used = "used",
    inactive = "inactive"
}

function generateEventKey()
    local randomFunc = math.random
    local template = "xxxxxxx"
    
    local result = string.gsub(template, "[xy]", function(char)
        local value
        if char == "x" then
            value = randomFunc(0, 15)
        else
            value = randomFunc(8, 11)
        end
        return string.format("%x", value)
    end)
    
    return result
end

eventKey = tostring(generateEventKey())
SetConvarReplicated("EKey2", eventKey)

if grapplerCommand.enabled then
    RegisterCommand(grapplerCommand.commandName, function(source, args)
        local playerId = source
        
        if userHasPermission(playerId, grapplerCommand) then
            local action = args[1]
            
            if action == nil then
                TriggerClientEvent("Client:grapplerNotification", playerId, translations.invalidGrapplerArguments)
            elseif action == grapplerCommand.install then
                TriggerClientEvent("Client:grapplerCommand", playerId, grapplerActions.install)
            elseif action == grapplerCommand.deploy then
                TriggerClientEvent("Client:grapplerCommand", playerId, grapplerActions.deploy)
            elseif action == grapplerCommand.remove then
                TriggerClientEvent("Client:grapplerCommand", playerId, grapplerActions.remove)
            elseif action == grapplerCommand.reset then
                TriggerClientEvent("Client:grapplerCommand", playerId, grapplerActions.reset)
            else
                TriggerClientEvent("Client:grapplerNotification", playerId, translations.invalidGrapplerArguments)
            end
        else
            TriggerClientEvent("Client:grapplerNotification", playerId, translations.noPermission)
        end
    end, grapplerCommand.acePermissions.enabled)
end

RegisterServerEvent("Server:requestGrapplerTable")
AddEventHandler("Server:requestGrapplerTable", function()
    local playerId = source
    TriggerClientEvent("Client:receiveGrapplerTable", playerId, grapplers)
end)

RegisterServerEvent("Server:newGrapplerLog")
AddEventHandler("Server:newGrapplerLog", function(key, logMessage, additionalInfo)
    local playerId = source
    
    if key == eventKey then
        normalLog(playerId, logMessage, additionalInfo)
    end
end)

RegisterServerEvent("Server:updateGrapplerTable")
AddEventHandler("Server:updateGrapplerTable", function(key, vehicleNetId, mode, vehicleModel)
    local playerId = source
    
    if key == eventKey then
        if grapplers[vehicleNetId] == nil then
            grapplers[vehicleNetId] = {}
        end
        
        grapplers[vehicleNetId].mode = mode
        grapplers[vehicleNetId].model = vehicleModel
        grapplers[vehicleNetId].owner = playerId
        
        if vehicleModel == nil then
            TriggerClientEvent("Client:updateGrapplerTable", -1, vehicleNetId, mode, playerId)
        else
            TriggerClientEvent("Client:updateGrapplerTable", -1, vehicleNetId, mode, playerId, vehicleModel)
        end
    end
end)

RegisterServerEvent("Server:deployGrapplerOnVehicle")
AddEventHandler("Server:deployGrapplerOnVehicle", function(key, policeVehicleNetId, targetVehicleNetId, wheelBoneName)
    if key == eventKey then
        if grapplers[policeVehicleNetId] ~= nil then
            if grapplers[policeVehicleNetId].mode == grapplerModes.deployed then
                grapplers[policeVehicleNetId].targetVehicle = targetVehicleNetId
                grapplers[policeVehicleNetId].mode = grapplerModes.used
                
                TriggerClientEvent("Client:deployGrapplerOnVehicle", -1, policeVehicleNetId, targetVehicleNetId, wheelBoneName)
            end
        end
    end
end)

RegisterServerEvent("Server:updateHandBrakeTable")
AddEventHandler("Server:updateHandBrakeTable", function(policeVehicleNetId, targetVehicleNetId)
    handBrakeEnabled[policeVehicleNetId] = {
        targetNetId = targetVehicleNetId
    }
end)

RegisterServerEvent("Server:requestHandbrakeTable")
AddEventHandler("Server:requestHandbrakeTable", function(vehicleNetId)
    TriggerClientEvent("Client:updateHandBrakeTable", -1, handBrakeEnabled, vehicleNetId)
end)

AddEventHandler("playerEnteredScope", function(data)
    local enteringPlayer = data.player
    local targetPlayer = data["for"]
    
    for netId, grapplerData in pairs(grapplers) do
        local ownerPlayerId = tonumber(grapplerData.owner)
        local targetPlayerId = tonumber(targetPlayer)
        
        if ownerPlayerId == targetPlayerId then
            TriggerClientEvent("Client:GrapplerInstallForOutOfScope", enteringPlayer, grapplers, netId)
        end
    end
end)
