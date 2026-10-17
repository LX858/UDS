local ox_inventory = exports.ox_inventory
local core = Bridge.core
local framework = Bridge.frameWork

if not core then
    print("error: no core found")
    return
end

local function getPlayer(src)

    if framework == "esx" then
        return core.GetPlayerFromId(src)
    elseif framework == "qb" then
        return core.Functions.GetPlayer(src)
    end
end

function Bridge.getItemCount(src, item)
    if GetResourceState("ox_inventory") == "started" then
        return ox_inventory:GetItemCount(src, item)
    end

    local Player = getPlayer(src)

    if not Player then return end

    if framework == "esx" then
        local itemData = Player.getInventoryItem(item)
        return (itemData and itemData.count) or 0
    elseif framework == "qb" then
        local itemData = Player.Functions.GetItemByName(item)
        return (itemData and itemData.amount) or 0
    end
end

function Bridge.removeItem(src, item, amount, slot)
    amount = amount or 1

    if GetResourceState("ox_inventory") == "started" then
        return ox_inventory:RemoveItem(src, item, amount, nil, slot)
    end

    local Player = getPlayer(src)

    if not Player then return end

    local hasEnough = Bridge.getItemCount(src, item) >= amount

    if not hasEnough then return false end

    if framework == "esx" then
        if hasEnough then
            Player.removeInventoryItem(item, amount)
        end
        return hasEnough
    elseif framework == "qb" then
        TriggerClientEvent("inventory:client:ItemBox", src, core?.Shared.Items[item], "remove", amount)
        return Player.Functions.RemoveItem(item, amount, slot)
    end
end

function Bridge.addMoney(src, amount)
    local Player = Bridge.getPlayer(src)

    if not Player then return end

    if framework == 'esx' then
        Player.addAccountMoney("money", amount)
    elseif framework == 'qb' then
        return Player.Functions.AddMoney("cash", amount)
    end
end

function Bridge.giveItem(src, item, amount, metadata, checkWeight)
    if not item or not amount or amount <= 0 then return end

    local PlayerState = Player(src).state
    if PlayerState.isFishing then
        PlayerState:set("isFishing", false, true)
    end

    local Player = getPlayer(src)
    local citizenid = nil
    if Player then
        if framework == "qb" and Player.PlayerData then
            citizenid = Player.PlayerData.citizenid
        elseif framework == "esx" then
            citizenid = Player.identifier
        end
    end

    local itemLabel = Bridge.getitemLabel(item) or item

    if GetResourceState("ox_inventory") == "started" then
        if ox_inventory:CanCarryItem(src, item, amount, metadata) then
            local success = ox_inventory:AddItem(src, item, amount, metadata)
            if success then
                TriggerClientEvent('xn_buucuc:client:notify', src, {
                    title = 'Nhận vật phẩm',
                    description = 'Bạn đã nhận được ' .. itemLabel .. (amount > 1 and (' (x' .. amount .. ')') or ''),
                    type = 'success'
                })
            end
            return success
        else
            -- Player không thể mang, chuyển vào kho bưu cục
            if citizenid and GetResourceState("xn_buucuc") == "started" then
                local success = exports.xn_buucuc:AddItemToPersonalStorage(citizenid, item, amount, metadata or {})
                if success then
                    TriggerClientEvent('xn_buucuc:client:notify', src, {
                        title = 'Bưu cục',
                        description = 'Kho đồ cá nhân đầy! Vật phẩm đã được chuyển về bưu cục',
                        type = 'success'
                    })
                    return true
                else
                    TriggerClientEvent('xn_buucuc:client:notify', src, {
                        title = 'Lỗi',
                        description = 'Không thể thêm vật phẩm vào bưu cục',
                        type = 'error'
                    })
                end
            end

            -- Fallback nếu không có bưu cục: rơi phần thưởng dưới chân player
            local ped = GetPlayerPed(src)
            local coords = GetEntityCoords(ped)
            return ox_inventory:CustomDrop("Phần thưởng", {
                { item, amount, metadata }
            }, coords)
        end
    end

    local Player = getPlayer(src)

    if not Player then return end

    if item == 'money' then
        Bridge.addMoney(src, amount)
        return
    end
    
    if framework == "esx" then
        if not checkWeight or Player.canCarryItem(item, amount) then
            Player.addInventoryItem(item, amount, metadata or {})
        end
    elseif framework == "qb" then
        TriggerClientEvent("inventory:client:ItemBox", src, core?.Shared.Items[item], "add", amount)
        Player.Functions.AddItem(item, amount, false, metadata or {})
    end
end

function Bridge.getitemLabel(item)
    if GetResourceState("ox_inventory") == "started" then
        local item = ox_inventory:Items()[item]
        return (item and item.label) or "ERROR"
    end

    if framework == "esx" then
        return core.GetItemLabel(item)
    elseif framework == "qb" then
        if not core.Shared.Items[item] then
            print(string.format('ERROR: the item %s does not exist in shared items', item))
            return
        end
        return core.Shared.Items[item].label
    end
end

function Bridge.RegisterUsableItem(item, cb)
    if framework == "esx" then
        core.RegisterUsableItem(item, cb)
    elseif framework == "qb" then
        core.Functions.CreateUseableItem(item, cb)
    end
end
