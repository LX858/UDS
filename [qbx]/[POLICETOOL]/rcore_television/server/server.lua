ESX = nil
QBCore = nil

if Config.FrameWork == 1 then
    ESX = GetEsxObject()
end

if Config.FrameWork == 2 then
    QBCore = Config.GetQBCoreObject()
end

--- Will send a print when debug is enabled
--- @param ... object
function Debug(...)
    if Config.Debug then
        print(...)
    end
end

TelevisionCache = {}
PlayerBucketCache = {}

RegisterNetEvent("rcore_television:stopTelevisionAtCoords", function(coords)
    if not source then
        print("Event: \"rcore_television:stopTelevisionAtCoords\" has to be called from client side only!")
    end

    local playerBucket = GetPlayerRoutingBucket(source)

    if not TelevisionCache[playerBucket] then
        TelevisionCache[playerBucket] = {}
    end

    for k, v in pairs(TelevisionCache[playerBucket]) do
        if #(v.tvPos - coords) < 1.5 then
            table.remove(TelevisionCache[playerBucket], k)
            TriggerClientEvent("rcore_television:stopTelevisionAtCoords", -1, coords)
            break
        end
    end
end)

RegisterNetEvent("rcore_television:fetchCache", function()
    local playerBucket = GetPlayerRoutingBucket(source)

    if not TelevisionCache[playerBucket] then
        TelevisionCache[playerBucket] = {}
    end

    TriggerClientEvent("rcore_television:fetchCache", source, TelevisionCache[playerBucket])
end)

-- adding time thread
CreateThread(function()
    while true do
        Wait(1000)
        for _, val in pairs(TelevisionCache) do
            for _, v in pairs(val) do
                if v.time then
                    v.time = v.time + 1
                end
            end
        end
    end
end)

-- updating bucket thread
CreateThread(function()
    while true do
        Wait(500)
        for k, v in pairs(GetPlayers()) do
            Wait(2)
            local bucketID = GetPlayerRoutingBucket(k)
            if PlayerBucketCache[k] ~= bucketID then
                PlayerBucketCache[k] = bucketID
                TriggerClientEvent(TriggerName("UpdatePlayerBucketID"), k, bucketID)
                Debug("Updating player bucket ID cache", bucketID, "player ID", k)
            end
        end
    end
end)

RegisterNetEvent("rcore_television:AddTelevisionToCache", function(data)
    if not source then
        print("Event: \"rcore_television:AddTelevisionToCache\" has to be called from client side only!")
    end

    local found = false
    local key
    local playerBucket = GetPlayerRoutingBucket(source)

    if not TelevisionCache[playerBucket] then
        TelevisionCache[playerBucket] = {}
    end

    for k, v in pairs(TelevisionCache[playerBucket]) do
        if data.NetID then
            if v.NetID == data.NetID then
                found = true
                key = k
                break
            end
        end
        if #(v.tvPos - data.tvPos) < 1.5 then
            found = true
            key = k
            break
        end
    end

    if not found then
        table.insert(TelevisionCache[playerBucket], data)
        TriggerClientEvent("rcore_television:AddTelevisionToCache", -1, data)
    else
        TelevisionCache[playerBucket][key].URL = data.URL
        TelevisionCache[playerBucket][key].time = 0

        TriggerClientEvent("rcore_television:UpdateTelevisionCache", -1, key, TelevisionCache[playerBucket][key])
    end
end)

registerCallback(TriggerName("DoesPlayerHaveCertain"), function(source, cb, items)
    if Config.FrameWork == 1 then
        local xPlayer = ESX.GetPlayerFromId(source)
        for k, v in pairs(items) do
            local item = xPlayer.getInventoryItem(v)
            if item then
                if item.count ~= 0 then
                    cb(true)
                    return
                end
            end
        end
        cb(false)
    end
    if Config.FrameWork == 2 then
        local qbPlayer = QBCore.Functions.GetPlayer(source)
        for k, v in pairs(items) do
            if qbPlayer.Functions.GetItemByName(v) then
                cb(true)
                return
            end
        end
        cb(false)
    end
end)

local SharedGroups = {}
if Config.Framework ~= 2 then
    SharedGroups = {
        "user", "mod", "moderator", "help", "helper", "admin", "superadmin", "god",
    }
else
    SharedGroups = QBCore.Config.Server.Permissions
end

for k, v in pairs(SharedGroups) do
    ExecuteCommand(("add_ace qbcore.%s rcore_perm.%s allow"):format(v, v))
    ExecuteCommand(("add_ace group.%s rcore_perm.%s allow"):format(v, v))
end

local grantedPermission = {}
function IsPlayerInGroup(source, groups, acePermission)
    if grantedPermission[source] then
        return true
    end

    if acePermission then
        if IsPlayerAceAllowed(source, acePermission) then
            return true
        end
    end

    if Config.FrameWork == 2 then
        for k, v in pairs(groups) do
            if IsPlayerAceAllowed(source, "rcore_perm." .. v) then
                return true
            end
        end
    end

    if Config.FrameWork == 1 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            for k, v in pairs(groups) do
                if xPlayer.getPermissions then
                    if Config.PermissionGroup.ESX[1][xPlayer.getPermissions()] then
                        return true
                    end
                end
                if xPlayer.getGroup then
                    if Config.PermissionGroup.ESX[2][xPlayer.getGroup()] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

registerCallback(TriggerName("hasPermission"), function(source, cb, groups, acePermission)
    cb(IsPlayerInGroup(source, groups, acePermission))
end)

CreateThread(function()
    local deepCopy = function(object)
        local lookup_table = {}
        local function _copy(object)
            if type(object) ~= "table" then
                return object
            elseif lookup_table[object] then
                return lookup_table[object]
            end
            local new_table = {}
            lookup_table[object] = new_table
            for index, value in pairs(object) do
                new_table[_copy(index)] = _copy(value)
            end
            return setmetatable(new_table, getmetatable(object))
        end
        return _copy(object)
    end

    local permissionGroup = deepCopy(Config.PermissionGroup)
    for framework, v in pairs(permissionGroup) do
        for index, _v in pairs(v) do
            for key, permissions in pairs(_v) do
                Config.PermissionGroup[framework][index][key] = nil
                Config.PermissionGroup[framework][index][permissions] = true
            end
        end
    end
end)

RegisterCommand('tvgrantpermission', function(source, args, user)
    if source ~= 0 then
        TriggerClientEvent('chat:addMessage', source, { args = { "This command can be used ONLY in console! The 'Live Console' in txadmin panel." } })
        return
    end

    if args[1] == nil then
        print("Please use command: /tvgrantpermission [player ID] | Example: /tvgrantpermission 7")
        return
    end

    local sourceNumber = tonumber(args[1])

    if not sourceNumber then
        print("The player ID has to be number!")
        return
    end

    if grantedPermission[sourceNumber] ~= nil then
        print("This player has already temporary permission!")
        return
    end

    grantedPermission[sourceNumber] = true
    print("You granted temporary permission to the user with server ID: ", sourceNumber, "The permission last 30 minutes")
    Wait(1000 * 60 * 30)

    grantedPermission[sourceNumber] = nil
end)

RegisterCommand("televisionversion", function(source, args, rawCommand)
    local frameworks = { [0] = "standlone", [1] = "esx", [2] = "qb-core" }
    local detection = { [1] = "Raycast", [2] = "GetClosestObject" }

    print("^3")
    print("rcore_television")

    print(string.format("^7framework: ^3%s", frameworks[Config.FrameWork]))
    print(string.format("^7detection type: ^3%s", detection[Config.DetectorType]))
    print(string.format("^7version: ^3%s", GetResourceMetadata(GetCurrentResourceName(), "version")))

    print("https://documentation.rcore.cz/paid-resources/rcore_television")
    print("^7")
end, false)