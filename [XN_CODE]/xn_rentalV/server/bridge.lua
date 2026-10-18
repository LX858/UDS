-- ALLGAMERS SERVER BRIDGE
-- The only server file to touch for integrations. config.lua picks what is used:
--   framework = 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone' | 'custom'
--   keys      = 'auto' | 'qbx' | 'qb' | 'none' | 'custom'
-- Built-in choices need no edits. Choose 'custom' and fill in the CUSTOM block below.
ScootServerBridge = {}
local M, Config = ScootServerBridge, ScootConfig

-------------------------------------------------------------------------------
-- CUSTOM: your own framework identity, money and vehicle keys. Used only with 'custom'.
-------------------------------------------------------------------------------
local Custom = {}

-- Return a stable character key for rentals.json persistence (string), or nil if not ready.
function Custom.getIdentifier(source)
    return nil
end

-- Return { cash = number, bank = number } balances for the player.
function Custom.getBalances(source)
    return { cash = 0, bank = 0 }
end

-- Remove amount from account ('cash' or 'bank'). Return true on success.
function Custom.removeMoney(source, account, amount)
    return false
end

-- Refund amount to account. Return true on success.
function Custom.addMoney(source, account, amount)
    return false
end

-- Give keys for a freshly spawned rental vehicle entity.
function Custom.giveKeys(source, vehicle, plate)
end

-- Remove keys when a rental ends.
function Custom.removeKeys(source, vehicle, plate)
end

-------------------------------------------------------------------------------
-- Built-in behaviour. Nothing below needs changes.
-------------------------------------------------------------------------------
function resourceStarted(name)
    return GetResourceState(name) == "started"
end

function resolveFramework()
    local mode = Config.framework
    if mode == "custom" then
        return "custom"
    end
    if mode == "auto" then
        if resourceStarted("qbx_core") then
            return "qbx"
        end
        if resourceStarted("qb-core") then
            return "qb"
        end
        if resourceStarted("es_extended") then
            return "esx"
        end
        return "standalone"
    end
    return mode
end

function resolveKeys()
    local mode = Config.keys
    if mode == "custom" then
        return "custom"
    end
    if mode == "auto" then
        if resourceStarted("qbx_vehiclekeys") then
            return "qbx"
        end
        if resourceStarted("qb-vehiclekeys") then
            return "qb"
        end
        return "none"
    end
    return mode
end

local framework = resolveFramework()
local QBCore, ESX

if framework == "qbx" or framework == "qb" then
    local ok, core = pcall(function()
        return exports["qb-core"]:GetCoreObject()
    end)
    if ok then
        QBCore = core
    end
end

if framework == "esx" then
    local ok, obj = pcall(function()
        return exports["es_extended"]:getSharedObject()
    end)
    if ok then
        ESX = obj
    end
end

function currentKeysMode()
    return resolveKeys()
end

function trimPlate(plate)
    if not plate then
        return nil
    end
    plate = tostring(plate):match("^%s*(.-)%s*$")
    if not plate or plate == "" then
        return nil
    end
    return string.upper(plate)
end

function standaloneBucket(license)
    local key = ("standalone:%s"):format(license)
    local raw = GetResourceKvpString(key)
    if raw and raw ~= "" then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == "table" then
            return data
        end
    end
    local start = Config.standalone or {}
    return {
        cash = tonumber(start.startingCash) or 1000,
        bank = tonumber(start.startingBank) or 0,
    }
end

function saveStandaloneBucket(license, data)
    SetResourceKvp(("standalone:%s"):format(license), json.encode(data))
end

function playerLicense(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find("license:") == 1 then
            return id
        end
    end
    return ("src:%s"):format(source)
end

function M.getIdentifier(source)
    if framework == "custom" then
        return Custom.getIdentifier(source)
    end

    if framework == "qbx" or framework == "qb" then
        if not QBCore then
            return nil
        end
        local player = QBCore.Functions.GetPlayer(source)
        if not player then
            return nil
        end
        return player.PlayerData.citizenid
    end

    if framework == "esx" then
        if not ESX then
            return nil
        end
        local player = ESX.GetPlayerFromId(source)
        if not player then
            return nil
        end
        return player.getIdentifier()
    end

    return playerLicense(source)
end

function M.getBalances(source)
    if framework == "custom" then
        return Custom.getBalances(source)
    end

    if framework == "qbx" or framework == "qb" then
        local player = QBCore and QBCore.Functions.GetPlayer(source)
        if not player then
            return { cash = 0, bank = 0 }
        end
        local money = player.PlayerData.money or {}
        return {
            cash = tonumber(money.cash) or 0,
            bank = tonumber(money.bank) or 0,
        }
    end

    if framework == "esx" then
        local player = ESX and ESX.GetPlayerFromId(source)
        if not player then
            return { cash = 0, bank = 0 }
        end
        local cash = player.getAccount("money")
        local bank = player.getAccount("bank")
        return {
            cash = cash and cash.money or 0,
            bank = bank and bank.money or 0,
        }
    end

    local bucket = standaloneBucket(playerLicense(source))
    return {
        cash = tonumber(bucket.cash) or 0,
        bank = tonumber(bucket.bank) or 0,
    }
end

function M.removeMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return true
    end
    account = account == "bank" and "bank" or "cash"

    if framework == "custom" then
        return Custom.removeMoney(source, account, amount) == true
    end

    if framework == "qbx" or framework == "qb" then
        local player = QBCore and QBCore.Functions.GetPlayer(source)
        if not player then
            return false
        end
        local balance = player.Functions.GetMoney(account)
        if not balance or balance < amount then
            return false
        end
        player.Functions.RemoveMoney(account, amount, "capsule-rental")
        return true
    end

    if framework == "esx" then
        local player = ESX and ESX.GetPlayerFromId(source)
        if not player then
            return false
        end
        local esxAccount = account == "cash" and "money" or "bank"
        local bal = player.getAccount(esxAccount)
        if not bal or bal.money < amount then
            return false
        end
        player.removeAccountMoney(esxAccount, amount)
        return true
    end

    local license = playerLicense(source)
    local bucket = standaloneBucket(license)
    if (tonumber(bucket[account]) or 0) < amount then
        return false
    end
    bucket[account] = (tonumber(bucket[account]) or 0) - amount
    saveStandaloneBucket(license, bucket)
    return true
end

function M.addMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return true
    end
    account = account == "bank" and "bank" or "cash"

    if framework == "custom" then
        return Custom.addMoney(source, account, amount) == true
    end

    if framework == "qbx" or framework == "qb" then
        local player = QBCore and QBCore.Functions.GetPlayer(source)
        if not player then
            return false
        end
        player.Functions.AddMoney(account, amount, "capsule-rental-refund")
        return true
    end

    if framework == "esx" then
        local player = ESX and ESX.GetPlayerFromId(source)
        if not player then
            return false
        end
        local esxAccount = account == "cash" and "money" or "bank"
        player.addAccountMoney(esxAccount, amount)
        return true
    end

    local license = playerLicense(source)
    local bucket = standaloneBucket(license)
    bucket[account] = (tonumber(bucket[account]) or 0) + amount
    saveStandaloneBucket(license, bucket)
    return true
end

function M.giveKeys(source, vehicle, plate)
    local mode = currentKeysMode()
    -- Prefer the plate we generated. Entity plate text is often still the default
    -- right after CreateVehicle / SetVehicleNumberPlateText on the server.
    plate = trimPlate(plate)
    if (not plate or plate == "") and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        plate = trimPlate(GetVehicleNumberPlateText(vehicle))
    end
    if not plate or plate == "" then
        print(("[allgamers_capsulerent] giveKeys skipped: empty plate (src=%s)"):format(tostring(source)))
        return
    end

    local netId = nil
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleNumberPlateText(vehicle, plate)
        SetVehicleDoorsLocked(vehicle, 1)
        netId = NetworkGetNetworkIdFromEntity(vehicle)
    end

    if mode == "none" then
        return
    end
    if mode == "custom" then
        Custom.giveKeys(source, vehicle, plate)
        return
    end
    if mode == "qbx" and resourceStarted("qbx_vehiclekeys") then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(source, vehicle)
        end)
        return
    end

    if resourceStarted("qb-vehiclekeys") then
        -- One GiveKeys only — it already notifies + AddKeys. Do not also fire SetOwner
        -- (that calls AcquireVehicleKeys → GiveKeys again and spams notifications).
        local ok, err = pcall(function()
            exports["qb-vehiclekeys"]:GiveKeys(source, plate)
        end)
        if not ok then
            print(("[allgamers_capsulerent] GiveKeys export failed: %s"):format(tostring(err)))
        end
        TriggerClientEvent("capsulerent:client:giveKeys", source, netId, plate)
        return
    end

    print(("[allgamers_capsulerent] giveKeys: no key resource (mode=%s plate=%s)"):format(tostring(mode), plate))
end

function M.removeKeys(source, vehicle, plate)
    local mode = currentKeysMode()
    plate = trimPlate(plate)
    if (not plate or plate == "") and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        plate = trimPlate(GetVehicleNumberPlateText(vehicle))
    end
    if not plate or plate == "" then
        return
    end

    if mode == "none" then
        return
    end
    if mode == "custom" then
        Custom.removeKeys(source, vehicle, plate)
        return
    end
    if mode == "qbx" and resourceStarted("qbx_vehiclekeys") then
        pcall(function()
            exports.qbx_vehiclekeys:RemoveKeys(source, vehicle)
        end)
        return
    end
    if resourceStarted("qb-vehiclekeys") then
        pcall(function()
            exports["qb-vehiclekeys"]:RemoveKeys(source, plate)
        end)
        TriggerClientEvent("qb-vehiclekeys:client:RemoveKeys", source, plate)
    end
end

function M.canPlace(source)
    if not source or source == 0 then
        return true
    end

    local srcStr = tostring(source)

    local placeAce = Config.placeAce or "capsulerent.place"
    if IsPlayerAceAllowed(source, placeAce) or IsPlayerAceAllowed(srcStr, placeAce) then
        return true
    end

    local adminAce = Config.creator and Config.creator.adminAce
    if adminAce and (IsPlayerAceAllowed(source, adminAce) or IsPlayerAceAllowed(srcStr, adminAce)) then
        return true
    end

    local standardAces = { "command", "group.admin", "group.god", "group.superadmin", "admin", "god" }
    for _, ace in ipairs(standardAces) do
        if IsPlayerAceAllowed(source, ace) or IsPlayerAceAllowed(srcStr, ace) then
            return true
        end
    end

    if resourceStarted("qbx_core") then
        local ok1, hasGroup = pcall(function()
            return exports.qbx_core:HasGroup(source, "admin") or exports.qbx_core:HasGroup(source, "god")
        end)
        if ok1 and hasGroup then
            return true
        end

        local ok2, hasPerm = pcall(function()
            return exports.qbx_core:HasPermission(source, "admin") or exports.qbx_core:HasPermission(source, "god")
        end)
        if ok2 and hasPerm then
            return true
        end
    end

    if (framework == "qb" or framework == "qbx") and QBCore and QBCore.Functions and QBCore.Functions.HasPermission then
        local ok, hasPerm = pcall(function()
            return QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god")
        end)
        if ok and hasPerm then
            return true
        end
    end

    if framework == "esx" and ESX and ESX.GetPlayerFromId then
        local ok, xPlayer = pcall(function() return ESX.GetPlayerFromId(source) end)
        if ok and xPlayer then
            local grp = xPlayer.getGroup and xPlayer.getGroup()
            if grp == "admin" or grp == "superadmin" or grp == "god" then
                return true
            end
        end
    end

    return false
end

function M.framework()
    return framework
end

function M.keysMode()
    return currentKeysMode()
end
