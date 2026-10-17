if not lib then return end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

---@class TradeSession
---@field id string
---@field playerA number
---@field playerB number
---@field playerAItems table<number, SlotWithItem>
---@field playerBItems table<number, SlotWithItem>
---@field playerAMoney number
---@field playerBMoney number
---@field playerALocked boolean
---@field playerBLocked boolean
---@field playerAConfirmed boolean
---@field playerBConfirmed boolean

---@type table<string, TradeSession>
local TradeSessions = {}

---@type table<number, string> -- playerId -> sessionId
local PlayerInTrade = {}

---@type table<string, boolean> -- Lock for trade slot operations
local activeTradeSlots = {}
local pendingRequests = {}
local cachedQBCore
local QBX = shared.framework == 'qbx' and exports.qbx_core or nil

local function getQBCore()
    if not cachedQBCore then cachedQBCore = exports['qb-core']:GetCoreObject() end
    return cachedQBCore
end

AddEventHandler('onResourceStop', function(resource)
    if resource == 'qb-core' then cachedQBCore = nil end
end)

--- Generate unique trade session ID
---@return string
local function generateTradeId()
    local id
    repeat id = ('%s_%s'):format(os.time(), math.random(1000, 999999)) until not TradeSessions[id]
    return id
end

--- Get player money (cash)
---@param playerId number
---@return number
local function getPlayerMoney(playerId)
    local inv = Inventory(playerId)
    if not inv or not inv.player then return 0 end
    
    if shared.framework == 'qbx' then
        return QBX:GetMoney(playerId, 'cash') or 0
    elseif shared.framework == 'qb' then
        local player = getQBCore().Functions.GetPlayer(playerId)
        if player then return player.Functions.GetMoney('cash') or 0 end
    end
    
    -- Check for ESX
    if shared.framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(playerId)
        if xPlayer then
            return xPlayer.getMoney()
        end
    end
    
    -- Fallback: check account items in inventory
    local accounts = exports.ox_inventory:GetAccountItemCounts(playerId)
    if accounts and accounts.money then
        return accounts.money
    end
    
    return 0
end

--- Remove money from player
---@param playerId number
---@param amount number
---@return boolean
local function removePlayerMoney(playerId, amount)
    if amount <= 0 then return true end
    
    local inv = Inventory(playerId)
    if not inv or not inv.player then return false end
    
    if shared.framework == 'qbx' then
        return QBX:RemoveMoney(playerId, 'cash', amount, 'trade')
    elseif shared.framework == 'qb' then
        local player = getQBCore().Functions.GetPlayer(playerId)
        if player then return player.Functions.RemoveMoney('cash', amount, 'trade') end
    end
    
    -- Check for ESX
    if shared.framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.removeMoney(amount)
            return true
        end
    end
    
    return false
end

--- Add money to player
---@param playerId number
---@param amount number
---@return boolean
local function addPlayerMoney(playerId, amount)
    if amount <= 0 then return true end
    
    local inv = Inventory(playerId)
    if not inv or not inv.player then return false end
    
    if shared.framework == 'qbx' then
        return QBX:AddMoney(playerId, 'cash', amount, 'trade')
    elseif shared.framework == 'qb' then
        local player = getQBCore().Functions.GetPlayer(playerId)
        if player then return player.Functions.AddMoney('cash', amount, 'trade') end
    end
    
    -- Check for ESX
    if shared.framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.addMoney(amount)
            return true
        end
    end
    
    return false
end

--- Request a framework save after a transfer; qbx_core persists asynchronously.
---@param playerId number
local function savePlayerMoney(playerId)
    if shared.framework == 'qbx' then
        QBX:Save(playerId)
    elseif shared.framework == 'qb' then
        local player = getQBCore().Functions.GetPlayer(playerId)
        if player then
            -- Try using Save function first (if available in the framework version)
            if player.Functions.Save then
                player.Functions.Save()
                return
            end
            -- Fallback: directly update money column in database
            local citizenid = player.PlayerData.citizenid
            local money = json.encode(player.PlayerData.money)
            MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', { money, citizenid })
        end
    elseif shared.framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(playerId)
        if xPlayer then
            if xPlayer.save then
                xPlayer.save()
                return
            end
            -- Fallback: directly update accounts in database
            local identifier = xPlayer.getIdentifier()
            local accounts = json.encode(xPlayer.getAccounts())
            MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', { accounts, identifier })
        end
    end
end

--- Check distance between two players
---@param playerA number
---@param playerB number
---@param maxDistance number
---@return boolean
local function isPlayerNear(playerA, playerB, maxDistance)
    local pedA = GetPlayerPed(playerA)
    local pedB = GetPlayerPed(playerB)
    
    if not pedA or pedA == 0 or not pedB or pedB == 0 then return false end
    
    local coordsA = GetEntityCoords(pedA)
    local coordsB = GetEntityCoords(pedB)
    
    return #(coordsA - coordsB) <= maxDistance
end

--- Get formatted player name with citizenid and character name
---@param playerId number
---@return string
local function getFormattedPlayerName(playerId)
    if shared.framework == 'qbx' or shared.framework == 'qb' then
        local player = shared.framework == 'qbx' and QBX:GetPlayer(playerId) or getQBCore().Functions.GetPlayer(playerId)
        if player then
            local citizenid = player.PlayerData.pid or 'Unknown'
            local charinfo = player.PlayerData.charinfo
            local firstName = charinfo and charinfo.firstname or ''
            local lastName = charinfo and charinfo.lastname or ''
            local fullName = ('%s %s'):format(firstName, lastName):gsub('^%s*(.-)%s*$', '%1')
            if fullName == '' then
                fullName = GetPlayerName(playerId) or 'Unknown'
            end
            return ('[%s] %s'):format(citizenid, fullName)
        end
    end
    
    -- Fallback to Steam name
    return GetPlayerName(playerId) or ('Player ' .. playerId)
end

--- Create a new trade session
---@param playerA number
---@param playerB number
---@return string|nil sessionId
local function createTradeSession(playerA, playerB, playerAName)
    if PlayerInTrade[playerA] or PlayerInTrade[playerB] then
        return nil
    end
    
    local sessionId = generateTradeId()
    
    -- Get player names with citizenid
    playerAName = playerAName or getFormattedPlayerName(playerA)
    local playerBName = getFormattedPlayerName(playerB)
    
    TradeSessions[sessionId] = {
        id = sessionId,
        playerA = playerA,
        playerB = playerB,
        playerAName = playerAName,
        playerBName = playerBName,
        playerAItems = {},
        playerBItems = {},
        playerAMoney = 0,
        playerBMoney = 0,
        playerALocked = false,
        playerBLocked = false,
        playerAConfirmed = false,
        playerBConfirmed = false,
        revision = 0,
        executing = false
    }
    
    PlayerInTrade[playerA] = sessionId
    PlayerInTrade[playerB] = sessionId
    
    return sessionId
end

--- Get trade session by player
---@param playerId number
---@return TradeSession|nil
local function getTradeSession(playerId)
    local sessionId = PlayerInTrade[playerId]
    if not sessionId then return nil end
    return TradeSessions[sessionId]
end

local function getTradeSnapshot(session, playerId)
    local snapshot = { sessionId = session.id, revision = session.revision }
    if session.playerA == playerId then
        snapshot.myName, snapshot.theirName = session.playerAName, session.playerBName
        snapshot.myItems, snapshot.theirItems = session.playerAItems, session.playerBItems
        snapshot.myMoney, snapshot.theirMoney = session.playerAMoney, session.playerBMoney
        snapshot.myLocked, snapshot.theirLocked = session.playerALocked, session.playerBLocked
        snapshot.myConfirmed, snapshot.theirConfirmed = session.playerAConfirmed, session.playerBConfirmed
    else
        snapshot.myName, snapshot.theirName = session.playerBName, session.playerAName
        snapshot.myItems, snapshot.theirItems = session.playerBItems, session.playerAItems
        snapshot.myMoney, snapshot.theirMoney = session.playerBMoney, session.playerAMoney
        snapshot.myLocked, snapshot.theirLocked = session.playerBLocked, session.playerALocked
        snapshot.myConfirmed, snapshot.theirConfirmed = session.playerBConfirmed, session.playerAConfirmed
    end
    return snapshot
end

local function broadcastTradeDelta(session, eventName, actor, fields, resetConfirm)
    session.revision += 1
    for _, recipient in ipairs({ session.playerA, session.playerB }) do
        local delta = { sessionId = session.id, revision = session.revision, mine = recipient == actor }
        for key, value in pairs(fields) do delta[key] = value end
        if resetConfirm then
            if recipient == session.playerA then
                delta.myConfirmed, delta.theirConfirmed = session.playerAConfirmed, session.playerBConfirmed
            else
                delta.myConfirmed, delta.theirConfirmed = session.playerBConfirmed, session.playerAConfirmed
            end
        end
        TriggerClientEvent(eventName, recipient, delta)
    end
end

--- Close trade session
---@param sessionId string
---@param reason string|nil
local function closeTradeSession(sessionId, reason)
    local session = TradeSessions[sessionId]
    if not session then return end
    
    -- Items were NEVER removed from players' inventories during trade
    -- So NO need to return items - they're already where they belong
    -- Just notify and cleanup
    
    -- Clear any remaining slot locks for this session
    for key, _ in pairs(activeTradeSlots) do
        if key:find(('trade:%s:'):format(sessionId)) then
            activeTradeSlots[key] = nil
        end
    end
    
    -- Notify both players to close trade and refresh their inventory UI
    TriggerClientEvent('ox_inventory:closeTrade', session.playerA, reason, session.id)
    TriggerClientEvent('ox_inventory:closeTrade', session.playerB, reason, session.id)
    
    -- Cleanup
    PlayerInTrade[session.playerA] = nil
    PlayerInTrade[session.playerB] = nil
    TradeSessions[sessionId] = nil
end

--- Update trade slot for a player
---@param playerId number
---@param slot number
---@param item SlotWithItem|nil
local function updateTradeSlot(playerId, slot, item)
    local session = getTradeSession(playerId)
    if not session or session.executing then return false end
    local isA = session.playerA == playerId
    if (isA and session.playerALocked) or (not isA and session.playerBLocked) then return false end
    local items = isA and session.playerAItems or session.playerBItems
    if items[slot] == item then return true end
    items[slot] = item
    session.playerAConfirmed, session.playerBConfirmed = false, false
    broadcastTradeDelta(session, 'ox_inventory:updateTradeItem', playerId, {
        slot = slot, item = item or false
    }, true)
    return true
end

--- Update trade money for a player
---@param playerId number
---@param amount number
local function updateTradeMoney(playerId, amount)
    local session = getTradeSession(playerId)
    if not session or session.executing then return false end
    local isA = session.playerA == playerId
    if (isA and session.playerALocked) or (not isA and session.playerBLocked) then return false end
    if (isA and session.playerAMoney or session.playerBMoney) == amount then return true end
    if isA then session.playerAMoney = amount else session.playerBMoney = amount end
    session.playerAConfirmed, session.playerBConfirmed = false, false
    broadcastTradeDelta(session, 'ox_inventory:updateTradeMoney', playerId, {
        amount = amount
    }, true)
    return true
end

--- Toggle lock status for a player
---@param playerId number
local function toggleTradeLock(playerId)
    local session = getTradeSession(playerId)
    if not session or session.executing then return false end
    local locked
    if session.playerA == playerId then
        session.playerALocked = not session.playerALocked
        locked = session.playerALocked
    else
        session.playerBLocked = not session.playerBLocked
        locked = session.playerBLocked
    end
    session.playerAConfirmed, session.playerBConfirmed = false, false
    broadcastTradeDelta(session, 'ox_inventory:updateTradeLock', playerId, {
        locked = locked
    }, true)
    return true
end

--- Confirm trade for a player
---@param playerId number
local function confirmTrade(playerId)
    local session = getTradeSession(playerId)
    if not session or session.executing then return false, 'invalid_session' end
    local isA = session.playerA == playerId
    if (isA and not session.playerALocked) or (not isA and not session.playerBLocked) then
        return false, 'not_locked'
    end
    if (isA and session.playerAConfirmed) or (not isA and session.playerBConfirmed) then
        return true
    end
    if isA then session.playerAConfirmed = true else session.playerBConfirmed = true end
    if session.playerAConfirmed and session.playerBConfirmed then session.executing = true end
    broadcastTradeDelta(session, 'ox_inventory:updateTradeConfirm', playerId, {
        confirmed = true
    })
    if session.executing then
        local called, success, reason = pcall(executeTrade, session)
        if not called then
            print(('[ox_inventory trade] CRITICAL execution error session=%s error=%s'):format(session.id, tostring(success)))
            closeTradeSession(session.id, 'transfer_failed')
            return false, 'transfer_failed'
        end
        return success, reason
    end
    return true
end

--- Execute the trade
--- Items stay in their original inventories until both players confirm.
---@param session TradeSession
function executeTrade(session)
    local playerA = session.playerA
    local playerB = session.playerB
    
    -- Verify distance
    if not isPlayerNear(playerA, playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return false, 'too_far'
    end
    
    local invA = Inventory(playerA)
    local invB = Inventory(playerB)
    
    if not invA or not invB then
        closeTradeSession(session.id, 'invalid_inventory')
        return false, 'invalid_inventory'
    end
    
    -- Verify player A has enough money
    if session.playerAMoney > 0 and getPlayerMoney(playerA) < session.playerAMoney then
        closeTradeSession(session.id, 'insufficient_money')
        return false, 'insufficient_money'
    end
    
    -- Verify player B has enough money
    if session.playerBMoney > 0 and getPlayerMoney(playerB) < session.playerBMoney then
        closeTradeSession(session.id, 'insufficient_money')
        return false, 'insufficient_money'
    end
    
    -- Items are STILL in player inventories during trade
    -- Verify all items still exist before transfer
    for tradeSlot, item in pairs(session.playerAItems) do
        if item and item.slot then
            local currentItem = invA.items[item.slot]
            if not currentItem or currentItem.name ~= item.name or currentItem.count < item.count
                or not table.matches(currentItem.metadata or {}, item.metadata or {})
                or not table.matches(item.metadata or {}, currentItem.metadata or {}) then
                closeTradeSession(session.id, 'item_changed')
        return false, 'item_changed'
            end
        end
    end
    
    for tradeSlot, item in pairs(session.playerBItems) do
        if item and item.slot then
            local currentItem = invB.items[item.slot]
            if not currentItem or currentItem.name ~= item.name or currentItem.count < item.count
                or not table.matches(currentItem.metadata or {}, item.metadata or {})
                or not table.matches(item.metadata or {}, currentItem.metadata or {}) then
                closeTradeSession(session.id, 'item_changed')
        return false, 'item_changed'
            end
        end
    end
    
    -- Calculate weight changes
    local itemsAToB = 0
    local itemsBToA = 0
    local weightAGaining = 0
    local weightBGaining = 0
    local weightALosing = 0
    local weightBLosing = 0
    
    for _, item in pairs(session.playerAItems) do
        local itemData = Items(item.name)
        local itemWeight = itemData and itemData.weight or item.weight or 0
        local totalWeight = itemWeight * item.count
        weightBGaining = weightBGaining + totalWeight
        weightALosing = weightALosing + totalWeight
        itemsAToB = itemsAToB + 1
    end
    
    for _, item in pairs(session.playerBItems) do
        local itemData = Items(item.name)
        local itemWeight = itemData and itemData.weight or item.weight or 0
        local totalWeight = itemWeight * item.count
        weightAGaining = weightAGaining + totalWeight
        weightBLosing = weightBLosing + totalWeight
        itemsBToA = itemsBToA + 1
    end
    
    -- Net weight change for each player (gaining from other - losing own items)
    local netWeightChangeA = weightAGaining - weightALosing
    local netWeightChangeB = weightBGaining - weightBLosing
    
    -- Check if player A can carry net weight change
    local availableWeightA = invA.maxWeight - invA.weight
    if netWeightChangeA > availableWeightA then
        closeTradeSession(session.id, 'insufficient_weight_a')
        return false, 'insufficient_weight_a'
    end
    
    -- Check if player B can carry net weight change
    local availableWeightB = invB.maxWeight - invB.weight
    if netWeightChangeB > availableWeightB then
        closeTradeSession(session.id, 'insufficient_weight_b')
        return false, 'insufficient_weight_b'
    end
    
    -- Count "net slots needed" (slots gained by receiving - slots freed by giving)
    -- Player A gives itemsAToB items (frees slots), receives itemsBToA items (needs slots)
    -- Net slots needed for A = itemsBToA - itemsAToB
    -- We need to check available empty slots
    
    local emptySlotsA = 0
    local emptySlotsB = 0
    
    for i = 1, invA.slots do
        if not invA.items[i] or not invA.items[i].name then
            if invA.type ~= 'player' or i < 6 or i > 21 then
                emptySlotsA = emptySlotsA + 1
            end
        end
    end
    
    for i = 1, invB.slots do
        if not invB.items[i] or not invB.items[i].name then
            if invB.type ~= 'player' or i < 6 or i > 21 then
                emptySlotsB = emptySlotsB + 1
            end
        end
    end
    
    -- Calculate net slots needed
    local netSlotsNeededA = itemsBToA - itemsAToB
    local netSlotsNeededB = itemsAToB - itemsBToA
    
    if netSlotsNeededA > emptySlotsA then
        closeTradeSession(session.id, 'insufficient_slots_a')
        return false, 'insufficient_slots_a'
    end
    
    if netSlotsNeededB > emptySlotsB then
        closeTradeSession(session.id, 'insufficient_slots_b')
        return false, 'insufficient_slots_b'
    end
    
    -- Each successful mutation gets a compensating operation in reverse order.
    local undo = {}
    local function failTransfer(reason)
        for i = #undo, 1, -1 do
            local ok, restored = pcall(undo[i])
            if not ok or restored == false then
                print(('[ox_inventory trade] CRITICAL rollback failed session=%s step=%s reason=%s'):format(session.id, i, reason))
            end
        end
        closeTradeSession(session.id, reason)
        return false, reason
    end

    local function removeItems(inv, items)
        for _, item in pairs(items) do
            local ok, removed = pcall(Inventory.RemoveItem, inv, item.name, item.count, item.metadata, item.slot)
            if not ok or not removed then
                if not ok then print(('[ox_inventory trade] RemoveItem error session=%s'):format(session.id)) end
                return false
            end
            undo[#undo + 1] = function()
                local current = inv.items[item.slot]
                if current and (current.name ~= item.name
                    or not table.matches(current.metadata or {}, item.metadata or {})
                    or not table.matches(item.metadata or {}, current.metadata or {})) then return false end
                local restored = Inventory.SetSlot(inv, Items(item.name), item.count, item.metadata, item.slot)
                if not restored then return false end
                if server.syncInventory then server.syncInventory(inv) end
                inv:syncSlotsWithClients({{ item = restored, inventory = inv.id }}, true)
                return true
            end
        end
        return true
    end

    if not removeItems(invA, session.playerAItems) or not removeItems(invB, session.playerBItems) then
        return failTransfer('transfer_failed')
    end

    local function canReceive(inv, items)
        for _, item in pairs(items) do
            if not Inventory.CanCarryItem(inv, item.name, item.count, item.metadata) then return false end
            local itemData = Items(item.name)
            if itemData and itemData.limit then
                local occupied = 0
                for _, slotItem in pairs(inv.items) do
                    if slotItem.name == item.name then occupied += 1 end
                end
                if occupied >= itemData.limit then return false end
            end
        end
        return true
    end

    local checkedB, canB = pcall(canReceive, invB, session.playerAItems)
    local checkedA, canA = pcall(canReceive, invA, session.playerBItems)
    if not checkedB or not checkedA then
        print(('[ox_inventory trade] CRITICAL capacity check error session=%s'):format(session.id))
        return failTransfer('transfer_failed')
    end
    if not canB or not canA then
        return failTransfer('insufficient_slots')
    end

    local function addItems(inv, items)
        for _, item in pairs(items) do
            local ok, added, response = pcall(Inventory.AddItem, inv, item.name, item.count, item.metadata)
            if not ok or not added then
                if not ok then print(('[ox_inventory trade] AddItem error session=%s'):format(session.id)) end
                return false
            end
            if response and response.slot then
                local slot, metadata = response.slot, response.metadata
                undo[#undo + 1] = function()
                    local current = inv.items[slot]
                    if not current or current.name ~= item.name or current.count < item.count
                        or not table.matches(current.metadata or {}, metadata or {})
                        or not table.matches(metadata or {}, current.metadata or {}) then return false end
                    return Inventory.RemoveItem(inv, item.name, item.count, metadata, slot)
                end
            elseif type(response) == 'table' then
                for _, slotItem in ipairs(response) do
                    local slot, count, metadata = slotItem.slot, slotItem.count, slotItem.metadata
                    undo[#undo + 1] = function()
                        local current = inv.items[slot]
                        if not current or current.name ~= item.name or current.count < count
                            or not table.matches(current.metadata or {}, metadata or {})
                            or not table.matches(metadata or {}, current.metadata or {}) then return false end
                        return Inventory.RemoveItem(inv, item.name, count, metadata, slot)
                    end
                end
            end
        end
        return true
    end

    if not addItems(invB, session.playerAItems) or not addItems(invA, session.playerBItems) then
        return failTransfer('transfer_failed')
    end

    local TAX_RATE = 0.02
    local function moveMoney(from, to, amount)
        if amount <= 0 then return true end
        local received = amount - math.floor(amount * TAX_RATE)
        local ok, removed = pcall(removePlayerMoney, from, amount)
        if not ok or not removed then return false end
        undo[#undo + 1] = function() return addPlayerMoney(from, amount) end
        ok, removed = pcall(addPlayerMoney, to, received)
        if not ok or not removed then return false end
        undo[#undo + 1] = function() return removePlayerMoney(to, received) end
        return true
    end

    if not moveMoney(playerA, playerB, session.playerAMoney)
        or not moveMoney(playerB, playerA, session.playerBMoney) then
        return failTransfer('transfer_failed')
    end

    if session.playerAMoney > 0 or session.playerBMoney > 0 then
        local savedA = pcall(savePlayerMoney, playerA)
        local savedB = pcall(savePlayerMoney, playerB)
        if not savedA or not savedB then
            print(('[ox_inventory trade] CRITICAL money save dispatch failed session=%s'):format(session.id))
        end
    end
    if next(session.playerAItems) or next(session.playerBItems) then
        local savedA = pcall(Inventory.Save, playerA)
        local savedB = pcall(Inventory.Save, playerB)
        if not savedA or not savedB then
            print(('[ox_inventory trade] CRITICAL inventory save dispatch failed session=%s'):format(session.id))
        end
    end

    -- LOG: Trade completed
    local playerAName = session.playerAName or getFormattedPlayerName(playerA)
    local playerBName = session.playerBName or getFormattedPlayerName(playerB)
    
    -- Format items from Player A to Player B
    local itemsAToBStr = ''
    for _, item in pairs(session.playerAItems) do
        if item and item.name then
            local itemData = Items(item.name)
            local label = itemData and itemData.label or item.label or item.name
            if itemsAToBStr ~= '' then itemsAToBStr = itemsAToBStr .. ', ' end
            itemsAToBStr = itemsAToBStr .. ('%sx %s'):format(item.count, label)
        end
    end
    if itemsAToBStr == '' then itemsAToBStr = 'không có' end
    
    -- Format items from Player B to Player A
    local itemsBToAStr = ''
    for _, item in pairs(session.playerBItems) do
        if item and item.name then
            local itemData = Items(item.name)
            local label = itemData and itemData.label or item.label or item.name
            if itemsBToAStr ~= '' then itemsBToAStr = itemsBToAStr .. ', ' end
            itemsBToAStr = itemsBToAStr .. ('%sx %s'):format(item.count, label)
        end
    end
    if itemsBToAStr == '' then itemsBToAStr = 'không có' end
    
    -- Format money
    local moneyAToB = session.playerAMoney > 0 and ('$%s'):format(session.playerAMoney) or ''
    local moneyBToA = session.playerBMoney > 0 and ('$%s'):format(session.playerBMoney) or ''
    
    -- Build log message
    local logMessage = ('%s giao dịch với %s | A đưa: [%s%s] | B đưa: [%s%s]'):format(
        playerAName,
        playerBName,
        itemsAToBStr,
        moneyAToB ~= '' and (', ' .. moneyAToB) or '',
        itemsBToAStr,
        moneyBToA ~= '' and (', ' .. moneyBToA) or ''
    )
    print(logMessage)
    
    -- Log trade (single entry)
    lib.logger(nil, 'trade', logMessage)
    
    -- Clear items before closing so closeTradeSession doesn't try to process them
    session.playerAItems = {}
    session.playerBItems = {}
    closeTradeSession(session.id, 'success')
    return true
end

local function requestTrade(playerId, targetId)
    targetId = tonumber(targetId)
    if not targetId or targetId % 1 ~= 0 or targetId == playerId then
        return false, 'invalid_target'
    end
    if PlayerInTrade[playerId] or PlayerInTrade[targetId] then
        return false, 'already_in_trade'
    end
    if not Inventory(playerId) or not Inventory(targetId) or GetPlayerPed(targetId) == 0 then
        return false, 'player_not_found'
    end
    if not isPlayerNear(playerId, targetId, 3.0) then return false, 'too_far' end

    local now = GetGameTimer()
    for target, request in pairs(pendingRequests) do
        if request.expiresAt <= now then
            pendingRequests[target] = nil
        elseif target == targetId or request.requesterId == playerId then
            return false, 'already_in_trade'
        end
    end
    local name = getFormattedPlayerName(playerId)
    local request = {
        requesterId = playerId,
        requesterName = name,
        expiresAt = now + 30000
    }
    pendingRequests[targetId] = request
    SetTimeout(30000, function()
        if pendingRequests[targetId] == request then pendingRequests[targetId] = nil end
    end)
    TriggerClientEvent('ox_inventory:receiveTradeRequest', targetId, playerId, name)
    return true
end

lib.callback.register('ox_inventory:requestTrade', function(source, targetId)
    return requestTrade(source, targetId)
end)

lib.callback.register('ox_inventory:acceptTrade', function(source, requesterId)
    requesterId = tonumber(requesterId)
    local request = pendingRequests[source]
    if not request or request.requesterId ~= requesterId or request.expiresAt <= GetGameTimer() then
        return false, 'invalid_requester'
    end
    pendingRequests[source] = nil
    if PlayerInTrade[source] or PlayerInTrade[requesterId] then return false, 'already_in_trade' end
    if not Inventory(source) or not Inventory(requesterId) then return false, 'player_not_found' end
    if not isPlayerNear(source, requesterId, 3.0) then return false, 'too_far' end

    local sessionId = createTradeSession(requesterId, source, request.requesterName)
    if not sessionId then return false, 'failed_to_create_session' end
    local session = TradeSessions[sessionId]
    TriggerClientEvent('ox_inventory:openTrade', requesterId, getTradeSnapshot(session, requesterId))
    TriggerClientEvent('ox_inventory:openTrade', source, getTradeSnapshot(session, source))
    return true, sessionId
end)

lib.callback.register('ox_inventory:getTradeSnapshot', function(source, sessionId)
    local session = getTradeSession(source)
    if not session or session.id ~= sessionId then return nil end
    return getTradeSnapshot(session, source)
end)

-- Keep the old event for other resources; the normal client uses requestTrade directly.
RegisterNetEvent('ox_inventory:sendTradeRequest', function(targetId)
    requestTrade(source, targetId)
end)

RegisterNetEvent('ox_inventory:declineTradeRequest', function(requesterId)
    local request = pendingRequests[source]
    if not request or request.requesterId ~= tonumber(requesterId)
        or request.expiresAt <= GetGameTimer() then return end
    pendingRequests[source] = nil
    TriggerClientEvent('ox_inventory:tradeRequestDeclined', requesterId)
end)

RegisterNetEvent('ox_inventory:cancelTrade', function(sessionId)
    local session = getTradeSession(source)
    if session and session.id == sessionId and not session.executing then
        closeTradeSession(session.id, 'cancelled')
    end
end)

-- Callback: Add item to trade
lib.callback.register('ox_inventory:tradeAddItem', function(source, data)
    if type(data) ~= 'table' then return { success = false, reason = 'invalid_data' } end
    local playerId = source
    local slot = data.slot
    local tradeSlot = data.tradeSlot
    local count = data.count or 1
    
    local session = getTradeSession(playerId)
    if not session or session.id ~= data.sessionId or session.executing then
        return { success = false }
    end
    local inv = Inventory(playerId)
    if not inv or type(slot) ~= 'number' or slot % 1 ~= 0 or slot < 1 or slot > inv.slots
        or type(tradeSlot) ~= 'number' or tradeSlot % 1 ~= 0 or tradeSlot < 1 or tradeSlot > 5
        or type(count) ~= 'number' or count % 1 ~= 0 or count < 1 or count == math.huge then
        return { success = false, reason = 'invalid_data' }
    end
    
    -- Check distance
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return { success = false, reason = 'too_far' }
    end
    
    local isPlayerA = session.playerA == playerId
    
    -- Create lock references
    local playerSlotRef = ('%s:%s'):format(playerId, slot)
    local tradeSlotRef = ('trade:%s:%s:%s'):format(session.id, isPlayerA and 'A' or 'B', tradeSlot)
    
    -- Check if slots are locked
    if activeTradeSlots[playerSlotRef] or activeTradeSlots[tradeSlotRef] then
        return { success = false, reason = 'slot_locked' }
    end
    
    -- Lock slots
    activeTradeSlots[playerSlotRef] = true
    activeTradeSlots[tradeSlotRef] = true
    
    -- Auto-unlock when function ends
    local _ <close> = defer(function()
        activeTradeSlots[playerSlotRef] = nil
        activeTradeSlots[tradeSlotRef] = nil
    end)
    
    -- Check if player is locked
    if (isPlayerA and session.playerALocked) or (not isPlayerA and session.playerBLocked) then
        return { success = false, reason = 'locked' }
    end
    
    local item = inv.items[slot]
    if not item then
        return { success = false, reason = 'item_not_found' }
    end
    
    -- Block trading items from clothing slots (6-21)
    if slot >= 6 and slot <= 21 then
        return { success = false, reason = 'clothing_slot' }
    end
    
    -- Check if item has cangive = true (cannot be traded)
    local itemData = Items(item.name)
    if itemData and itemData.cangive then
        return { success = false, reason = 'item_not_tradeable' }
    end
    
    -- Clothing items list - require metadata.serial starting with MH or MI to trade
    local clothingItems = {
        ['cloth_outfit'] = true, ['cloth_torso'] = true, ['cloth_tshirt'] = true,
        ['cloth_arms'] = true, ['cloth_pants'] = true, ['cloth_shoes'] = true,
        ['cloth_decals'] = true, ['cloth_ears'] = true, ['cloth_mask'] = true,
        ['cloth_bproof'] = true, ['cloth_chain'] = true, ['cloth_bags'] = true,
        ['cloth_glasses'] = true, ['cloth_watches'] = true, ['cloth_bracelets'] = true,
        ['cloth_helmet'] = true, ['clothes'] = true,
    }
    
    -- Check if clothing item has valid serial (must start with MH, MI, GC, or AD)
    if clothingItems[item.name] then
        local serial = item.metadata and item.metadata.serial
        if not serial then
            return { success = false, reason = 'clothing_no_serial' }
        end
        local prefix = string.sub(serial, 1, 2)
        local validPrefixes = { ['MH'] = true, ['MI'] = true, ['GC'] = true, ['AD'] = true }
        if not validPrefixes[prefix] then
            return { success = false, reason = 'clothing_invalid_serial' }
        end
    end
    
    -- Check if trade slot already has an item
    local tradeItems = isPlayerA and session.playerAItems or session.playerBItems
    local existingTradeItem = tradeItems[tradeSlot]
    
    -- If trade slot has item, only allow stacking from SAME player slot
    if existingTradeItem and existingTradeItem.name then
        -- Must be same player slot to stack
        if existingTradeItem.slot ~= slot then
            return { success = false, reason = 'different_source_slot' }
        end
        -- Must be same item name
        if existingTradeItem.name ~= item.name then
            return { success = false, reason = 'different_item' }
        end
    end
    
    -- Check if this player slot is already in trade for a DIFFERENT trade slot
    for ts, ti in pairs(tradeItems) do
        if ti and ti.slot == slot and ts ~= tradeSlot then
            return { success = false, reason = 'slot_in_different_trade' }
        end
    end
    
    -- Calculate how much already traded from this slot
    local alreadyTradedFromSlot = existingTradeItem and existingTradeItem.count or 0
    local availableCount = item.count - alreadyTradedFromSlot
    
    if availableCount <= 0 then
        return { success = false, reason = 'no_items_available' }
    end
    
    local actualCount = math.min(count, availableCount)
    local newTotalCount = alreadyTradedFromSlot + actualCount
    
    -- DO NOT remove item - just track it
    -- Create/update trade item reference
    local tradeItem = {
        slot = slot, -- original slot in player inventory (always the same for stacking)
        name = item.name,
        count = newTotalCount,
        weight = itemData and itemData.weight * newTotalCount or (item.weight / item.count) * newTotalCount,
        metadata = json.decode(json.encode(item.metadata or {})),
        label = item.label
    }
    
    updateTradeSlot(playerId, tradeSlot, tradeItem)
    
    return { success = true, playerSlot = slot, tradedCount = actualCount }
end)

-- Callback: Remove item from trade
lib.callback.register('ox_inventory:tradeRemoveItem', function(source, data)
    if type(data) ~= 'table' then return { success = false, reason = 'invalid_data' } end
    local playerId = source
    local tradeSlot = data.tradeSlot
    
    local session = getTradeSession(playerId)
    if not session or session.id ~= data.sessionId or session.executing then
        return { success = false }
    end
    if type(tradeSlot) ~= 'number' or tradeSlot % 1 ~= 0 or tradeSlot < 1 or tradeSlot > 5 then
        return { success = false, reason = 'invalid_data' }
    end
    
    -- Check distance
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return { success = false, reason = 'too_far' }
    end
    
    local isPlayerA = session.playerA == playerId
    
    -- Get the trade item first to know the original slot
    local tradeItems = isPlayerA and session.playerAItems or session.playerBItems
    local tradeItem = tradeItems[tradeSlot]
    
    if not tradeItem then
        return { success = false, reason = 'no_item' }
    end
    
    -- Create lock references
    local tradeSlotRef = ('trade:%s:%s:%s'):format(session.id, isPlayerA and 'A' or 'B', tradeSlot)
    
    -- Check if slot is locked
    if activeTradeSlots[tradeSlotRef] then
        return { success = false, reason = 'slot_locked' }
    end
    
    -- Lock slot
    activeTradeSlots[tradeSlotRef] = true
    
    -- Auto-unlock when function ends
    local _ <close> = defer(function()
        activeTradeSlots[tradeSlotRef] = nil
    end)
    
    -- Check if player is locked
    if (isPlayerA and session.playerALocked) or (not isPlayerA and session.playerBLocked) then
        return { success = false, reason = 'locked' }
    end
    
    -- Get original player slot
    local playerSlot = tradeItem.slot
    
    -- DO NOT add item back - it was never removed
    -- Just clear from trade session
    updateTradeSlot(playerId, tradeSlot, nil)
    
    return { success = true, playerSlot = playerSlot }
end)

-- Callback: Update trade money
lib.callback.register('ox_inventory:tradeUpdateMoney', function(source, data)
    if type(data) ~= 'table' then return { success = false, reason = 'invalid_data' } end
    local playerId = source
    local amount = tonumber(data.amount)
    
    local session = getTradeSession(playerId)
    if not session or session.id ~= data.sessionId or session.executing then
        return { success = false }
    end
    if not amount or amount ~= amount or amount == math.huge or amount == -math.huge then
        return { success = false, reason = 'invalid_amount' }
    end
    
    -- Check distance
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return { success = false, reason = 'too_far' }
    end
    
    amount = math.floor(math.max(0, amount))
    if amount > 0 then amount = math.min(amount, getPlayerMoney(playerId)) end
    if amount > 0 and amount < 100 then
        return { success = false, reason = 'minimum_100' }
    end
    
    if not updateTradeMoney(playerId, amount) then return { success = false, reason = 'locked' } end
    return { success = true, amount = amount, revision = session.revision }
end)

-- Callback: Toggle lock
lib.callback.register('ox_inventory:tradeLock', function(source, sessionId)
    local playerId = source
    
    local session = getTradeSession(playerId)
    if not session or session.id ~= sessionId or session.executing then
        return { success = false }
    end
    
    -- Check distance
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return { success = false, reason = 'too_far' }
    end
    
    return { success = toggleTradeLock(playerId) }
end)

-- Callback: Confirm trade
lib.callback.register('ox_inventory:tradeConfirm', function(source, sessionId)
    local playerId = source
    
    local session = getTradeSession(playerId)
    if not session or session.id ~= sessionId or session.executing then
        return { success = false }
    end
    
    -- Check distance
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return { success = false, reason = 'too_far' }
    end
    
    local success, reason = confirmTrade(playerId)
    return { success = success == true, reason = reason }
end)

-- Cleanup on player drop
AddEventHandler('playerDropped', function()
    local playerId = source
    pendingRequests[playerId] = nil
    for target, request in pairs(pendingRequests) do
        if request.requesterId == playerId then pendingRequests[target] = nil end
    end
    local session = getTradeSession(playerId)
    
    if session and not session.executing then
        closeTradeSession(session.id, 'player_left')
    end
end)

--- Check distance and close session if too far
---@param session TradeSession
---@return boolean isNear
local function checkTradeDistance(session)
    if not isPlayerNear(session.playerA, session.playerB, 5.0) then
        closeTradeSession(session.id, 'too_far')
        return false
    end
    return true
end

return {
    getTradeSession = getTradeSession,
    closeTradeSession = closeTradeSession,
    checkTradeDistance = checkTradeDistance
}
