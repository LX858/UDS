local Framework, frameworkName = getFramework()

function getPlayer(source)
    if GetResourceState('qbx_core') == 'started' then
        local success, p = pcall(function() return exports.qbx_core:GetPlayer(source) end)
        if success and p then return p end
    end
    if frameworkName == "esx" then
        return Framework.GetPlayerFromId(source)
    elseif Framework and Framework.Functions then
        return Framework.Functions.GetPlayer(source)
    end
end

function removeItem(Player, item, count)
    if frameworkName == "esx" then
        Player.removeInventoryItem(item, count)
    else
        Player.Functions.RemoveItem(item, count)
    end
end

function getJob(Player)
    if frameworkName == "esx" then
        return Player.job
    else
        return Player.PlayerData.job
    end
end

function getPlayers()
    return GetPlayers()
end

function RegisterItem(itemName, callback)
    if frameworkName == "esx" then
        Framework.RegisterUsableItem(itemName, function(source)
            callback(source)
        end)
    else
        Framework.Functions.CreateUseableItem(itemName, function(source)
            callback(source)
        end)
    end
end

function getMoney(Player, method)
    if frameworkName == "esx" then
        if method == "cash" then
            return Player.getMoney()
        else
            return Player.getAccount('bank').money
        end
    else
        if method == "cash" then
            return Player.PlayerData.money["cash"]
        else
            return Player.PlayerData.money["bank"]
        end
    end
end

function getName(identifier, Player)
    if identifier then
        if frameworkName == "esx" then
            local Info = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {["@identifier"] = identifier})
            return Info[1].firstname.." "..Info[1].lastname
        else
            if Player then 
                return Player.PlayerData.charinfo.firstname.." "..Player.PlayerData.charinfo.lastname
            else
                return "Not Found"
            end
        end
    else
        return "Not Found"
    end
end
