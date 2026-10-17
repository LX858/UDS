if IsDuplicityVersion() then return end

QBX = {} -- luacheck: ignore
QBX.PlayerData = exports.qbx_core:GetPlayerData() or {}

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    for key in pairs(QBX.PlayerData) do QBX.PlayerData[key] = nil end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(value)
    if type(value) ~= 'table' or value == QBX.PlayerData then return end
    for key in pairs(QBX.PlayerData) do QBX.PlayerData[key] = nil end
    for key, field in pairs(value) do QBX.PlayerData[key] = field end
end)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    if type(key) ~= 'string' then return end
    QBX.PlayerData[key] = value
end)

RegisterNetEvent('qbx_core:client:metadataUpdated', function(key, value)
    if type(key) ~= 'string' then return end
    QBX.PlayerData.metadata = QBX.PlayerData.metadata or {}
    QBX.PlayerData.metadata[key] = value
end)

RegisterNetEvent('qbx_core:client:moneyUpdated', function(moneyType, balance)
    if type(moneyType) ~= 'string' or type(balance) ~= 'number' then return end
    QBX.PlayerData.money = QBX.PlayerData.money or {}
    QBX.PlayerData.money[moneyType] = balance
end)

AddEventHandler('ox_inventory:updateInventory', function()
    if not QBX.PlayerData.citizenid or GetResourceState('ox_inventory') ~= 'started' then return end
    QBX.PlayerData.items = exports.ox_inventory:GetPlayerItems()
end)
