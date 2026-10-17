if not lib then return end

local tradeOpen = false
local tradeSessionId = nil
local currentTradeData = nil
local tradeUiReady = false
local pendingTradeDeltas = {}
local resyncInProgress = false
local resyncAttempts = 0
local processTradeDeltas
local closingFromServer = false -- Flag to prevent double handling
local slotsInTrade = {} -- Track which player slots are in trade: playerSlot -> {tradeSlot, item}
local originalItems = {} -- Store original items for restoration

--- Check if trade UI is open
---@return boolean
local function isTradeOpen()
    return tradeOpen
end

--- Update player inventory slot in UI (hide item when in trade)
---@param slot number
---@param item table|nil
local function updatePlayerSlotUI(slot, item)
    SendNUIMessage({
        action = 'refreshSlots',
        data = {
            items = {
                {
                    item = item or { slot = slot },
                    inventory = 'player'
                }
            }
        }
    })
end

--- Convert trade items to inventory slot format
---@param myItems table
---@param theirItems table
---@return table
local function convertTradeItemsToSlots(myItems, theirItems)
    local items = {}
    
    -- Slots 1-5: My trade items
    for i = 1, 5 do
        if myItems and myItems[i] then
            items[i] = {
                slot = i,
                name = myItems[i].name,
                count = myItems[i].count,
                weight = myItems[i].weight,
                metadata = myItems[i].metadata,
                label = myItems[i].label
            }
        else
            items[i] = { slot = i }
        end
    end
    
    -- Slots 6-10: Their trade items
    for i = 1, 5 do
        local slot = i + 5
        if theirItems and theirItems[i] then
            items[slot] = {
                slot = slot,
                name = theirItems[i].name,
                count = theirItems[i].count,
                weight = theirItems[i].weight,
                metadata = theirItems[i].metadata,
                label = theirItems[i].label
            }
        else
            items[slot] = { slot = slot }
        end
    end
    
    return items
end

local function sendTradeState()
    if not currentTradeData then return end
    local data = currentTradeData
    SendNUIMessage({
        action = 'updateTradeState',
        data = {
            myMoney = data.myMoney or 0,
            theirMoney = data.theirMoney or 0,
            myLocked = data.myLocked or false,
            theirLocked = data.theirLocked or false,
            myConfirmed = data.myConfirmed or false,
            theirConfirmed = data.theirConfirmed or false,
            theirName = data.theirName or 'Đối phương'
        }
    })
end

--- Open trade using inventory UI
---@param data table
local function openTrade(data)
    if tradeOpen then return end
    
    tradeOpen = true
    tradeSessionId = data.sessionId
    currentTradeData = data
    currentTradeData.revision = data.revision or 0
    tradeUiReady = false
    pendingTradeDeltas = {}
    resyncInProgress = false
    resyncAttempts = 0
    
    -- Clear tracking tables
    slotsInTrade = {}
    originalItems = {}
    
    -- Create trade inventory slots
    local tradeItems = convertTradeItemsToSlots(data.myItems, data.theirItems)
    
    -- Get accurate player inventory data from server
    local playerInvData = lib.callback.await('ox_inventory:getInventory', false)
    if not tradeOpen or tradeSessionId ~= data.sessionId then return end
    
    -- Calculate weight from items if not available
    local currentWeight = 0
    if playerInvData and playerInvData.weight then
        currentWeight = playerInvData.weight
    else
        for _, item in pairs(PlayerData.inventory) do
            if item and item.weight then
                currentWeight = currentWeight + item.weight
            end
        end
    end
    
    -- Use inventory setupInventory to show trade UI
    local left = {
        id = cache.serverId,
        type = 'player',
        slots = playerInvData and playerInvData.slots or shared.playerslots,
        label = data.myName or GetPlayerName(PlayerId()),
        weight = currentWeight,
        maxWeight = playerInvData and playerInvData.maxWeight or shared.playerweight,
        items = PlayerData.inventory,
        groups = PlayerData.groups
    }
    
    local right = {
        id = 'trade_' .. data.sessionId,
        type = 'trade',
        slots = 10,
        label = 'Giao dịch với ' .. (data.theirName or 'Người chơi'),
        items = tradeItems
    }
    
    -- Open inventory with trade
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    
    SendNUIMessage({
        action = 'setupInventory',
        data = {
            leftInventory = left,
            rightInventory = right
        }
    })
    
    -- Send trade state
    sendTradeState()
    
    LocalPlayer.state.invOpen = true
    tradeUiReady = true
    if processTradeDeltas then processTradeDeltas() end
end

--- Close trade UI
---@param reason string|nil
---@param fromServer boolean|nil -- true if called from server event
local function closeTrade(reason, fromServer)
    if not tradeOpen then return end
    
    -- Set flag to prevent StateBagChangeHandler from double-triggering
    if fromServer then
        closingFromServer = true
    end
    
    tradeOpen = false
    tradeSessionId = nil
    currentTradeData = nil
    tradeUiReady = false
    pendingTradeDeltas = {}
    resyncInProgress = false
    resyncAttempts = 0
    
    -- If trade was NOT successful, restore PlayerData.inventory
    -- Items were never removed from server, so server state is correct
    -- We just need to restore client PlayerData to match server
    if reason ~= 'success' then
        for playerSlot, origData in pairs(originalItems) do
            -- Handle both old format (item) and new format ({item, tradedCount})
            local origItem = origData.item or origData
            
            -- Deep copy the item to ensure we have a clean copy
            local restoredItem = {
                slot = origItem.slot or playerSlot,
                name = origItem.name,
                count = origItem.count,
                weight = origItem.weight,
                metadata = origItem.metadata,
                label = origItem.label
            }
            
            -- Restore PlayerData.inventory to match server state
            PlayerData.inventory[playerSlot] = restoredItem
        end
    end
    
    -- Clear tracking tables
    slotsInTrade = {}
    originalItems = {}
    
    -- Close inventory
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeInventory' })
    LocalPlayer.state.invOpen = false
    
    -- Reset flag after a short delay
    SetTimeout(100, function()
        closingFromServer = false
    end)
    
    -- Show notification based on reason
    if reason == 'success' then
        lib.notify({ type = 'success', description = 'Giao dịch thành công!' })
    elseif reason == 'cancelled' then
        lib.notify({ type = 'error', description = 'Giao dịch đã bị hủy' })
    elseif reason == 'too_far' then
        lib.notify({ type = 'error', description = 'Khoảng cách quá xa' })
    elseif reason == 'invalid_inventory' then
        lib.notify({ type = 'error', description = 'Lỗi inventory' })
    elseif reason == 'insufficient_money' then
        lib.notify({ type = 'error', description = 'Không đủ tiền' })
    elseif reason == 'invalid_items' then
        lib.notify({ type = 'error', description = 'Vật phẩm không hợp lệ' })
    elseif reason == 'player_left' then
        lib.notify({ type = 'error', description = 'Người chơi đã rời đi' })
    elseif reason == 'insufficient_weight_a' or reason == 'insufficient_weight_b' then
        lib.notify({ type = 'error', description = 'Người chơi không đủ sức chứa (quá cân)' })
    elseif reason == 'insufficient_slots_a' or reason == 'insufficient_slots_b' then
        lib.notify({ type = 'error', description = 'Người chơi không đủ ô chứa' })
    elseif reason == 'item_changed' then
        lib.notify({ type = 'error', description = 'Vật phẩm trong giao dịch đã thay đổi' })
    elseif reason == 'transfer_failed' then
        lib.notify({ type = 'error', description = 'Giao dịch thất bại khi chuyển vật phẩm hoặc tiền' })
    end
end

--- Update trade slots
---@param data table
local function updateTradeSlots(data)
    if not tradeOpen then return end
    
    currentTradeData = currentTradeData or {}
    currentTradeData.myItems = data.myItems
    currentTradeData.theirItems = data.theirItems
    currentTradeData.myMoney = data.myMoney
    currentTradeData.theirMoney = data.theirMoney
    currentTradeData.myLocked = data.myLocked
    currentTradeData.theirLocked = data.theirLocked
    currentTradeData.myConfirmed = data.myConfirmed
    currentTradeData.theirConfirmed = data.theirConfirmed
    -- Update theirName from server data
    if data.theirName then
        currentTradeData.theirName = data.theirName
    end
    
    -- Update trade inventory slots
    local tradeItems = convertTradeItemsToSlots(data.myItems, data.theirItems)
    
    -- Send refresh slots
    local slots = {}
    for i = 1, 10 do
        table.insert(slots, {
            item = tradeItems[i],
            inventory = 'trade_' .. tradeSessionId
        })
    end
    
    SendNUIMessage({
        action = 'refreshSlots',
        data = { items = slots }
    })
    
    -- Update trade state
    SendNUIMessage({
        action = 'updateTradeState',
        data = {
            myMoney = data.myMoney or 0,
            theirMoney = data.theirMoney or 0,
            myLocked = data.myLocked or false,
            theirLocked = data.theirLocked or false,
            myConfirmed = data.myConfirmed or false,
            theirConfirmed = data.theirConfirmed or false,
            theirName = currentTradeData.theirName or 'Đối phương'
        }
    })
end

local function reconcileTradeInventory(snapshot, inventoryData)
    if not inventoryData or not inventoryData.items then return end
    local offeredBySlot = {}
    for tradeSlot, item in pairs(snapshot.myItems or {}) do
        if item and item.slot then offeredBySlot[item.slot] = { tradeSlot = tradeSlot, item = item } end
    end
    for slot in pairs(originalItems) do
        if not offeredBySlot[slot] then
            PlayerData.inventory[slot] = inventoryData.items[slot]
            updatePlayerSlotUI(slot, inventoryData.items[slot])
        end
    end
    slotsInTrade, originalItems = {}, {}
    for slot, offer in pairs(offeredBySlot) do
        local original = inventoryData.items[slot]
        if original and original.count >= offer.item.count then
            slotsInTrade[slot] = offer.tradeSlot
            originalItems[slot] = { item = original, tradedCount = offer.item.count }
            local remaining = original.count - offer.item.count
            PlayerData.inventory[slot] = remaining > 0 and {
                slot = slot, name = original.name, count = remaining,
                weight = original.weight / original.count * remaining,
                metadata = original.metadata, label = original.label
            } or nil
            updatePlayerSlotUI(slot, PlayerData.inventory[slot])
        end
    end
end

local function applyTradeDelta(kind, delta)
    local data = currentTradeData
    local stateChanged = false
    if kind == 'item' then
        local items = delta.mine and data.myItems or data.theirItems
        items[delta.slot] = delta.item ~= false and delta.item or nil
        local slot = delta.mine and delta.slot or delta.slot + 5
        local tradeItem = items[delta.slot]
        local displayItem = tradeItem and {
            slot = slot, name = tradeItem.name, count = tradeItem.count,
            weight = tradeItem.weight, metadata = tradeItem.metadata, label = tradeItem.label
        } or { slot = slot }
        SendNUIMessage({ action = 'refreshSlots', data = {
            items = {{ item = displayItem, inventory = 'trade_' .. tradeSessionId }}
        } })
    elseif kind == 'money' then
        if delta.mine then data.myMoney = delta.amount else data.theirMoney = delta.amount end
        stateChanged = true
    elseif kind == 'lock' then
        if delta.mine then data.myLocked = delta.locked else data.theirLocked = delta.locked end
        stateChanged = true
    elseif kind == 'confirm' then
        if delta.mine then data.myConfirmed = delta.confirmed else data.theirConfirmed = delta.confirmed end
        stateChanged = true
    end
    if delta.myConfirmed ~= nil and data.myConfirmed ~= delta.myConfirmed then
        data.myConfirmed = delta.myConfirmed
        stateChanged = true
    end
    if delta.theirConfirmed ~= nil and data.theirConfirmed ~= delta.theirConfirmed then
        data.theirConfirmed = delta.theirConfirmed
        stateChanged = true
    end
    data.revision = delta.revision
    resyncAttempts = 0
    if stateChanged then sendTradeState() end
end

processTradeDeltas = function()
    if not tradeOpen or not tradeUiReady or resyncInProgress then return end
    while true do
        local nextRevision = currentTradeData.revision + 1
        local entry = pendingTradeDeltas[nextRevision]
        if not entry then break end
        pendingTradeDeltas[nextRevision] = nil
        applyTradeDelta(entry.kind, entry.delta)
    end
    if not next(pendingTradeDeltas) then return end
    resyncInProgress = true
    local sessionId = tradeSessionId
    CreateThread(function()
        local snapshot = lib.callback.await('ox_inventory:getTradeSnapshot', false, sessionId)
        if not tradeOpen or tradeSessionId ~= sessionId then return end
        if not snapshot then
            TriggerServerEvent('ox_inventory:cancelTrade', sessionId)
            closeTrade('cancelled', true)
            return
        end
        local oldRevision = currentTradeData.revision
        if snapshot.revision >= oldRevision then
            local inventoryData = lib.callback.await('ox_inventory:getInventory', false)
            if not tradeOpen or tradeSessionId ~= sessionId then return end
            currentTradeData = snapshot
            reconcileTradeInventory(snapshot, inventoryData)
            updateTradeSlots(snapshot)
            for revision in pairs(pendingTradeDeltas) do
                if revision <= snapshot.revision then pendingTradeDeltas[revision] = nil end
            end
        end
        if snapshot.revision <= oldRevision and not pendingTradeDeltas[oldRevision + 1] then
            resyncAttempts += 1
            if resyncAttempts >= 3 then
                TriggerServerEvent('ox_inventory:cancelTrade', sessionId)
                closeTrade('cancelled', true)
                return
            end
            Wait(500)
        end
        resyncInProgress = false
        processTradeDeltas()
    end)
end

local function queueTradeDelta(kind, delta)
    if not tradeOpen or not currentTradeData or type(delta) ~= 'table'
        or delta.sessionId ~= tradeSessionId or type(delta.revision) ~= 'number'
        or delta.revision <= currentTradeData.revision then return end
    if kind == 'item' and (type(delta.slot) ~= 'number' or delta.slot < 1 or delta.slot > 5) then return end
    pendingTradeDeltas[delta.revision] = { kind = kind, delta = delta }
    processTradeDeltas()
end

--- Request trade with target player
---@param targetId number
local function requestTrade(targetId)
    if tradeOpen then
        lib.notify({ type = 'error', description = 'Bạn đang trong giao dịch khác' })
        return
    end
    
    local success, reason = lib.callback.await('ox_inventory:requestTrade', false, targetId)
    
    if not success then
        if reason == 'invalid_target' then
            lib.notify({ type = 'error', description = 'Mục tiêu không hợp lệ' })
        elseif reason == 'already_in_trade' then
            lib.notify({ type = 'error', description = 'Một trong hai người đang trong giao dịch' })
        elseif reason == 'too_far' then
            lib.notify({ type = 'error', description = 'Người chơi quá xa' })
        elseif reason == 'player_not_found' then
            lib.notify({ type = 'error', description = 'Không tìm thấy người chơi' })
        else
            lib.notify({ type = 'error', description = 'Không thể yêu cầu giao dịch' })
        end
        return
    end
    
    -- The callback has already registered and delivered the request.
end

-- Check if in test mode
local function isTestMode()
    return tradeSessionId and tradeSessionId:find('^test_')
end

-- Listen for inventory close (ESC, click outside, etc.) to cancel trade
AddStateBagChangeHandler('invOpen', ('player:%s'):format(cache.serverId), function(_, _, value)
    -- Skip if closing is already handled by server event
    if closingFromServer then return end
    
    -- If inventory closed while trade is open, cancel trade (user pressed ESC or closed UI manually)
    if tradeOpen and value == false then
        local wasTestMode = isTestMode()
        local sessionId = tradeSessionId
        
        -- CRITICAL: Restore PlayerData.inventory BEFORE clearing originalItems
        -- This ensures items are restored when trade is cancelled by ESC
        for playerSlot, origData in pairs(originalItems) do
            local origItem = origData.item or origData
            
            -- Deep copy the item to restore
            local restoredItem = {
                slot = origItem.slot or playerSlot,
                name = origItem.name,
                count = origItem.count,
                weight = origItem.weight,
                metadata = origItem.metadata,
                label = origItem.label
            }
            
            PlayerData.inventory[playerSlot] = restoredItem
        end
        
        -- Reset local state
        tradeOpen = false
        tradeSessionId = nil
        currentTradeData = nil
        tradeUiReady = false
        pendingTradeDeltas = {}
        resyncInProgress = false
        resyncAttempts = 0
        slotsInTrade = {}
        originalItems = {}
        
        -- Notify server to cancel trade for both players (only if not test mode)
        if not wasTestMode and sessionId then
            TriggerServerEvent('ox_inventory:cancelTrade', sessionId)
        end
        
        lib.notify({ type = 'error', description = 'Giao dịch đã bị hủy' })
    end
end)

-- Event: Open trade UI
RegisterNetEvent('ox_inventory:openTrade', openTrade)

-- Event: Close trade UI (from server - notify both players)
RegisterNetEvent('ox_inventory:closeTrade', function(reason, sessionId)
    if sessionId and sessionId ~= tradeSessionId then return end
    closeTrade(reason, true) -- fromServer = true
end)

RegisterNetEvent('ox_inventory:updateTradeItem', function(delta) queueTradeDelta('item', delta) end)
RegisterNetEvent('ox_inventory:updateTradeMoney', function(delta) queueTradeDelta('money', delta) end)
RegisterNetEvent('ox_inventory:updateTradeLock', function(delta) queueTradeDelta('lock', delta) end)
RegisterNetEvent('ox_inventory:updateTradeConfirm', function(delta) queueTradeDelta('confirm', delta) end)

-- Event: Receive trade request
RegisterNetEvent('ox_inventory:receiveTradeRequest', function(requesterId, requesterName)
    local alert = lib.alertDialog({
        header = 'Yêu cầu giao dịch',
        content = ('**%s** muốn giao dịch với bạn. Bạn có đồng ý không?'):format(requesterName),
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Đồng ý',
            cancel = 'Từ chối'
        }
    })
    
    if alert == 'confirm' then
        local success, sessionIdOrReason = lib.callback.await('ox_inventory:acceptTrade', false, requesterId)
        
        if not success then
            lib.notify({ type = 'error', description = 'Không thể chấp nhận giao dịch' })
        end
    else
        TriggerServerEvent('ox_inventory:declineTradeRequest', requesterId)
    end
end)

-- Event: Trade request declined
RegisterNetEvent('ox_inventory:tradeRequestDeclined', function()
    lib.notify({ type = 'error', description = 'Yêu cầu giao dịch đã bị từ chối' })
end)

-- NUI Callbacks
RegisterNUICallback('tradeAddItem', function(data, cb)
    local playerSlot = data.slot
    local tradeSlot = data.tradeSlot
    local tradeCount = data.count or 1
    
    -- Get item from current PlayerData or from originalItems if already trading some
    local item = PlayerData.inventory[playerSlot]
    local existingOrigData = originalItems[playerSlot]
    
    -- If item is nil but we have original data, this slot is already being traded
    -- We need to use the CURRENT remaining item, not the original
    if not item and existingOrigData then
        -- No remaining items in player slot - can't trade more
        cb({ success = false })
        return
    elseif not item then
        cb({ success = false })
        return
    end
    
    -- Determine actual count to trade (from current remaining count)
    local actualCount = math.min(tradeCount, item.count)
    local remainingCount = item.count - actualCount
    
    -- Get the original full item for tracking (deep copy on first trade to avoid reference issues)
    local originalItem
    if existingOrigData then
        originalItem = existingOrigData.item
    else
        -- Deep copy the item on first trade to preserve original count
        originalItem = {
            slot = item.slot,
            name = item.name,
            count = item.count,
            weight = item.weight,
            metadata = item.metadata,
            label = item.label
        }
    end
    local previousTradedCount = existingOrigData and existingOrigData.tradedCount or 0
    local newTotalTradedCount = previousTradedCount + actualCount
    
    -- Helper function to restore UI on failure
    local function restoreUI()
        -- Restore player slot với count trước khi kéo
        updatePlayerSlotUI(playerSlot, item)
        -- If this was first trade, clear trade slot
        if not existingOrigData then
            SendNUIMessage({
                action = 'refreshSlots',
                data = {
                    items = {
                        {
                            item = { slot = tradeSlot },
                            inventory = 'trade'
                        }
                    }
                }
            })
        end
    end
    
    if not tradeOpen then
        restoreUI()
        cb({ success = false })
        return
    end
    
    -- Check if locked - block adding items when locked
    if currentTradeData and currentTradeData.myLocked then
        restoreUI()
        cb({ success = false })
        lib.notify({ type = 'error', description = 'Không thể thêm vật phẩm khi đã khóa giao dịch' })
        return
    end
    
    -- Check if this slot is already in trade for a DIFFERENT trade slot
    if slotsInTrade[playerSlot] and slotsInTrade[playerSlot] ~= tradeSlot then
        restoreUI()
        cb({ success = false })
        lib.notify({ type = 'error', description = 'Vật phẩm này đã được thêm vào slot khác' })
        return
    end
    
    -- Test mode - handle locally
    if isTestMode() then
        currentTradeData = currentTradeData or { myItems = {}, theirItems = {} }
        currentTradeData.myItems = currentTradeData.myItems or {}
        
        -- Get existing or create new
        local existingTradeItem = currentTradeData.myItems[tradeSlot]
        local newCount = newTotalTradedCount
        
        currentTradeData.myItems[tradeSlot] = {
            slot = playerSlot,
            name = originalItem.name,
            count = newCount,
            weight = originalItem.weight / originalItem.count * newCount,
            metadata = originalItem.metadata,
            label = originalItem.label
        }
        
        -- Track slot with original item info and total traded count
        originalItems[playerSlot] = {
            item = originalItem,
            tradedCount = newTotalTradedCount
        }
        slotsInTrade[playerSlot] = tradeSlot
        
        -- Update PlayerData based on remaining count
        if remainingCount <= 0 then
            PlayerData.inventory[playerSlot] = nil
            updatePlayerSlotUI(playerSlot, nil)
        else
            PlayerData.inventory[playerSlot] = {
                slot = playerSlot,
                name = originalItem.name,
                count = remainingCount,
                weight = originalItem.weight / originalItem.count * remainingCount,
                metadata = originalItem.metadata,
                label = originalItem.label
            }
            updatePlayerSlotUI(playerSlot, PlayerData.inventory[playerSlot])
        end
        
        updateTradeSlots(currentTradeData)
        cb({ success = true })
        return
    end
    
    -- Forward to server
    local requestSessionId = tradeSessionId
    data.sessionId = requestSessionId
    local result = lib.callback.await('ox_inventory:tradeAddItem', false, data)
    if tradeSessionId ~= requestSessionId then
        cb({ success = false })
        return
    end
    
    -- Handle success - track the slot with traded count info
    if result and result.success then
        -- Update originalItems with cumulative traded count
        originalItems[playerSlot] = {
            item = originalItem,
            tradedCount = newTotalTradedCount
        }
        slotsInTrade[playerSlot] = tradeSlot
        
        -- Update PlayerData based on remaining count
        if remainingCount <= 0 then
            PlayerData.inventory[playerSlot] = nil
        else
            PlayerData.inventory[playerSlot] = {
                slot = playerSlot,
                name = originalItem.name,
                count = remainingCount,
                weight = originalItem.weight / originalItem.count * remainingCount,
                metadata = originalItem.metadata,
                label = originalItem.label
            }
        end
        -- Don't call updatePlayerSlotUI here - UI was already updated in onDrop
    end
    
    -- Handle errors - restore UI since optimistic update was wrong
    if result and not result.success then
        if result.reason == 'item_not_tradeable' then
            lib.notify({ type = 'error', description = 'Vật phẩm này không thể giao dịch' })
        elseif result.reason == 'locked' then
            lib.notify({ type = 'error', description = 'Không thể thêm vật phẩm khi đã khóa giao dịch' })
        elseif result.reason == 'no_items_available' then
            lib.notify({ type = 'error', description = 'Không còn vật phẩm để giao dịch' })
        elseif result.reason == 'different_item' then
            lib.notify({ type = 'error', description = 'Slot giao dịch đã có vật phẩm khác' })
        elseif result.reason == 'different_source_slot' then
            lib.notify({ type = 'error', description = 'Mỗi slot giao dịch chỉ nhận vật phẩm từ một slot túi đồ. Kéo sang slot trống!' })
        elseif result.reason == 'clothing_no_serial' then
            lib.notify({ type = 'error', description = 'Quần áo không có serial không thể giao dịch' })
        elseif result.reason == 'clothing_invalid_serial' then
            lib.notify({ type = 'error', description = 'Quần áo phải có serial bắt đầu bằng MH, MI, GC hoặc AD mới có thể giao dịch' })
        end
        -- Restore player slot UI với count trước khi kéo
        updatePlayerSlotUI(playerSlot, item)
        -- If first trade attempt AND trade slot is empty (not different_source_slot error), clear trade slot
        -- Don't clear if different_source_slot - trade slot already has item from another player slot
        if not existingOrigData and result.reason ~= 'different_source_slot' then
            SendNUIMessage({
                action = 'refreshSlots',
                data = {
                    items = {
                        {
                            item = { slot = tradeSlot },
                            inventory = 'trade'
                        }
                    }
                }
            })
        end
    end
    
    cb(result or { success = false })
end)

RegisterNUICallback('tradeRemoveItem', function(data, cb)
    local tradeSlot = data.tradeSlot
    
    -- Find which player slot was used for this trade slot
    local playerSlot = nil
    for slot, tSlot in pairs(slotsInTrade) do
        if tSlot == tradeSlot then
            playerSlot = slot
            break
        end
    end
    
    -- Helper function to restore trade slot UI on failure
    local function restoreTradeSlotUI()
        if playerSlot and originalItems[playerSlot] then
            local origData = originalItems[playerSlot]
            local item = origData.item or origData
            local tradedCount = origData.tradedCount or item.count
            SendNUIMessage({
                action = 'refreshSlots',
                data = {
                    items = {
                        {
                            item = {
                                slot = tradeSlot,
                                name = item.name,
                                count = tradedCount,
                                weight = item.weight / item.count * tradedCount,
                                metadata = item.metadata,
                                label = item.label
                            },
                            inventory = 'trade'
                        }
                    }
                }
            })
        end
    end
    
    if not tradeOpen then
        restoreTradeSlotUI()
        cb({ success = false })
        return
    end
    
    -- Check if locked - block removing items when locked
    if currentTradeData and currentTradeData.myLocked then
        restoreTradeSlotUI()
        cb({ success = false })
        lib.notify({ type = 'error', description = 'Không thể loại bỏ vật phẩm khi đã khóa giao dịch' })
        return
    end
    
    -- Test mode - handle locally
    if isTestMode() then
        if currentTradeData and currentTradeData.myItems then
            currentTradeData.myItems[tradeSlot] = nil
            
            -- Restore item to player inventory UI
            if playerSlot and originalItems[playerSlot] then
                local origData = originalItems[playerSlot]
                local origItem = origData.item or origData
                -- CRITICAL: Restore PlayerData with full original item
                PlayerData.inventory[playerSlot] = origItem
                updatePlayerSlotUI(playerSlot, origItem)
                slotsInTrade[playerSlot] = nil
                originalItems[playerSlot] = nil
            end
            
            updateTradeSlots(currentTradeData)
        end
        cb({ success = true })
        return
    end
    
    -- Forward to server
    local requestSessionId = tradeSessionId
    data.sessionId = requestSessionId
    local result = lib.callback.await('ox_inventory:tradeRemoveItem', false, data)
    if tradeSessionId ~= requestSessionId then
        cb({ success = false })
        return
    end
    
    -- Handle success - restore item to player inventory UI and clear tracking
    if result and result.success and playerSlot and originalItems[playerSlot] then
        local origData = originalItems[playerSlot]
        local origItem = origData.item or origData
        -- CRITICAL: Restore PlayerData with full original item
        PlayerData.inventory[playerSlot] = origItem
        updatePlayerSlotUI(playerSlot, origItem)
        slotsInTrade[playerSlot] = nil
        originalItems[playerSlot] = nil
    end
    
    -- Handle errors - restore trade slot UI since optimistic update was wrong
    if result and not result.success then
        if result.reason == 'locked' then
            lib.notify({ type = 'error', description = 'Không thể loại bỏ vật phẩm khi đã khóa giao dịch' })
        end
        restoreTradeSlotUI()
    end
    
    cb(result or { success = false })
end)

RegisterNUICallback('tradeUpdateMoney', function(data, cb)
    if not tradeOpen then
        cb({ success = false })
        return
    end
    
    -- Test mode - handle locally
    if isTestMode() then
        currentTradeData = currentTradeData or {}
        currentTradeData.myMoney = tonumber(data.amount) or 0
        
        SendNUIMessage({
            action = 'updateTradeState',
            data = {
                myMoney = currentTradeData.myMoney or 0,
                theirMoney = currentTradeData.theirMoney or 0,
                myLocked = currentTradeData.myLocked or false,
                theirLocked = currentTradeData.theirLocked or false,
                myConfirmed = currentTradeData.myConfirmed or false,
                theirConfirmed = currentTradeData.theirConfirmed or false,
                theirName = currentTradeData.theirName or 'Test Player'
            }
        })
        cb({ success = true })
        return
    end
    
    -- Forward to server
    local requestSessionId = tradeSessionId
    data.sessionId = requestSessionId
    local result = lib.callback.await('ox_inventory:tradeUpdateMoney', false, data)
    if tradeSessionId ~= requestSessionId then
        cb({ success = false })
        return
    end
    if result and result.success and result.revision == currentTradeData.revision then
        sendTradeState()
    end
    cb(result or { success = false })
end)

RegisterNUICallback('tradeLock', function(data, cb)
    if not tradeOpen then
        cb({ success = false })
        return
    end
    
    -- Test mode - handle locally
    if isTestMode() then
        currentTradeData = currentTradeData or {}
        currentTradeData.myLocked = not currentTradeData.myLocked
        
        lib.notify({ 
            type = 'info', 
            description = currentTradeData.myLocked and 'Đã khóa giao dịch' or 'Đã mở khóa giao dịch'
        })
        
        SendNUIMessage({
            action = 'updateTradeState',
            data = {
                myMoney = currentTradeData.myMoney or 0,
                theirMoney = currentTradeData.theirMoney or 0,
                myLocked = currentTradeData.myLocked or false,
                theirLocked = currentTradeData.theirLocked or false,
                myConfirmed = currentTradeData.myConfirmed or false,
                theirConfirmed = currentTradeData.theirConfirmed or false,
                theirName = currentTradeData.theirName or 'Test Player'
            }
        })
        cb({ success = true })
        return
    end
    
    local requestSessionId = tradeSessionId
    local result = lib.callback.await('ox_inventory:tradeLock', false, requestSessionId)
    cb(tradeSessionId == requestSessionId and result or { success = false })
end)

RegisterNUICallback('tradeConfirm', function(data, cb)
    if not tradeOpen then
        cb({ success = false })
        return
    end
    
    -- Test mode - handle locally
    if isTestMode() then
        currentTradeData = currentTradeData or {}
        currentTradeData.myConfirmed = true
        lib.notify({ type = 'success', description = 'Đã xác nhận giao dịch (test mode)' })
        
        SendNUIMessage({
            action = 'updateTradeState',
            data = {
                myMoney = currentTradeData.myMoney or 0,
                theirMoney = currentTradeData.theirMoney or 0,
                myLocked = currentTradeData.myLocked or false,
                theirLocked = currentTradeData.theirLocked or false,
                myConfirmed = currentTradeData.myConfirmed or false,
                theirConfirmed = currentTradeData.theirConfirmed or false,
                theirName = currentTradeData.theirName or 'Test Player'
            }
        })
        
        -- Check if both confirmed
        if currentTradeData.theirConfirmed then
            Wait(500)
            closeTrade('success')
        end
        cb({ success = true })
        return
    end
    
    local requestSessionId = tradeSessionId
    local result = lib.callback.await('ox_inventory:tradeConfirm', false, requestSessionId)
    cb(result or { success = false })
end)

RegisterNUICallback('tradeCancel', function(data, cb)
    local wasTestMode = isTestMode()
    local sessionId = tradeSessionId
    closeTrade('cancelled')
    
    -- Only notify server if not in test mode
    if not wasTestMode then
        TriggerServerEvent('ox_inventory:cancelTrade', sessionId)
    end
    cb({ success = true })
end)

RegisterNUICallback('tradeClose', function(data, cb)
    local wasTestMode = isTestMode()
    local sessionId = tradeSessionId
    closeTrade()
    
    -- Only notify server if not in test mode
    if not wasTestMode then
        TriggerServerEvent('ox_inventory:cancelTrade', sessionId)
    end
    cb({ success = true })
end)

-- ox_target integration (shared.target is boolean, true means ox_target is enabled)
if shared.target then
    exports.ox_target:addGlobalPlayer({
        {
            name = 'ox_inventory:trade',
            icon = 'fas fa-handshake',
            label = 'Giao dịch',
            distance = 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                return not tradeOpen and not LocalPlayer.state.invBusy
            end,
            onSelect = function(data)
                local targetId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                if targetId and targetId > 0 then
                    requestTrade(targetId)
                end
            end
        }
    })
end

-- Export functions
exports('isTradeOpen', isTradeOpen)
exports('requestTrade', requestTrade)

-- Test command
RegisterCommand('testtrade', function()
    if tradeOpen then
        closeTrade('cancelled')
        return
    end
    
    -- Mock data để test
    local mockData = {
        sessionId = 'test_' .. GetGameTimer(),
        myName = GetPlayerName(PlayerId()) or 'Bạn',
        theirName = 'Test Player',
        myItems = {},
        theirItems = {
            [1] = { slot = 1, name = 'water', count = 5, weight = 500, label = 'Nước' },
            [3] = { slot = 3, name = 'burger', count = 2, weight = 300, label = 'Burger' },
        },
        myMoney = 0,
        theirMoney = 15000,
        myLocked = false,
        theirLocked = false,
        myConfirmed = false,
        theirConfirmed = false
    }
    
    openTrade(mockData)
    lib.notify({ type = 'info', description = 'Đã mở Trade UI test mode. Gõ /testtrade để đóng.' })
end, false)

-- Test command để giả lập đối phương khóa
RegisterCommand('testtradelock', function()
    if not tradeOpen then
        lib.notify({ type = 'error', description = 'Chưa mở trade UI. Gõ /testtrade trước.' })
        return
    end
    
    currentTradeData = currentTradeData or {}
    currentTradeData.theirLocked = true
    
    SendNUIMessage({
        action = 'updateTradeState',
        data = {
            myMoney = currentTradeData.myMoney or 0,
            theirMoney = currentTradeData.theirMoney or 15000,
            myLocked = currentTradeData.myLocked or false,
            theirLocked = true,
            myConfirmed = currentTradeData.myConfirmed or false,
            theirConfirmed = false,
            theirName = currentTradeData.theirName or 'Test Player'
        }
    })
    lib.notify({ type = 'info', description = 'Đối phương đã khóa giao dịch!' })
end, false)

-- Test command để giả lập đối phương xác nhận
RegisterCommand('testtradeconfirm', function()
    if not tradeOpen then
        lib.notify({ type = 'error', description = 'Chưa mở trade UI. Gõ /testtrade trước.' })
        return
    end
    
    currentTradeData = currentTradeData or {}
    currentTradeData.theirLocked = true
    currentTradeData.theirConfirmed = true
    
    SendNUIMessage({
        action = 'updateTradeState',
        data = {
            myMoney = currentTradeData.myMoney or 0,
            theirMoney = currentTradeData.theirMoney or 15000,
            myLocked = currentTradeData.myLocked or false,
            theirLocked = true,
            myConfirmed = currentTradeData.myConfirmed or false,
            theirConfirmed = true,
            theirName = currentTradeData.theirName or 'Test Player'
        }
    })
    lib.notify({ type = 'success', description = 'Đối phương đã xác nhận giao dịch!' })
end, false)

return {
    isTradeOpen = isTradeOpen,
    requestTrade = requestTrade,
    openTrade = openTrade,
    closeTrade = closeTrade
}
