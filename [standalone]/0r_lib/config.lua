Config = {}

Config.CoreName = {
    ["ESX"] = 'es_extended',
    ["QBCore"] = 'qb-core'
}

Config.PlayerLoadedEvents = {
    ["ESX"] = 'esx:playerLoaded',
    ["QBCore"] = 'QBCore:Client:OnPlayerLoaded',
}

Config.PlayerJobEvents = {
    ["ESX"] = 'esx:setJob',
    ["QBCore"] = 'QBCore:Client:OnJobUpdate'
}

Config.PlayerSetLoadedEvents = {}

Config.CustomNotify = false -- If you want to set up a different notify system, you can integrate it via the function below.

Config.CustomTextUI = false -- If you have a TextUI that you use, you can place it in the function below.

Config.CustomTextUIFunc = function(message)
    exports['okokTextUI']:Open(message, 'red', 'top') -- for example
end

Config.CustomNotifyFunc = function(message, type)
    exports['okokNotify']:Alert('Info', message, 3000, type)
end

Config.CustomTextUIHide = function()
    exports['okokTextUI']:Close()
end

Config.VehicleUpdateSQLESX = {'owned_vehicles', 'owner', 'stored'}
Config.VehicleUpdateSQLQBCore = {'player_vehicles', 'citizenid', 'state'}

