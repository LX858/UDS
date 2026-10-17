local QBCore = exports['qb-core']:GetCoreObject()
local currentPrices = {}
local availableItems = {} -- Danh sách vật phẩm có sẵn từ server
local spawnedNPCs = {}
local npcBlips = {}
local isNearNPC = false
local isNPCSpawned = false
local activeNPCLocationIndex = nil

-- Helper: Giải mã payload từ BroadcastLatent (JSON array)
local function UnpackLatent(payload)
    local ok, data = pcall(json.decode, payload)
    if ok and type(data) == 'table' then
        return table.unpack(data)
    end
    return payload -- fallback nếu không phải latent
end

-- Check if current time is within allowed hours
local function IsTimeAllowed()
    if not Config.TimeRestrictions.enabled then
        return true
    end
    
    local hour = GetClockHours()
    local startHour = Config.TimeRestrictions.startHour
    local endHour = Config.TimeRestrictions.endHour
    
    -- Handle overnight time range (e.g., 19:00 to 04:00)
    if startHour > endHour then
        return hour >= startHour or hour < endHour
    else
        return hour >= startHour and hour < endHour
    end
end

-- Despawn NPC
local function DespawnNPC()
    for _, npcEntity in ipairs(spawnedNPCs) do
        if DoesEntityExist(npcEntity) then
            DeleteEntity(npcEntity)
        end
    end
    spawnedNPCs = {}
    
    for _, blip in ipairs(npcBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    npcBlips = {}
    
    isNPCSpawned = false
end

-- Clean up any existing NPCs in the area (for restart scenarios)
local function CleanupExistingNPCs()
    local locations = {}
    
    if Config.NPCLocations and #Config.NPCLocations > 0 then
        for _, loc in ipairs(Config.NPCLocations) do
            table.insert(locations, vector3(loc.x, loc.y, loc.z))
        end
    elseif Config.NPCLocation then
        table.insert(locations, vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z))
    end
    
    local nearbyPeds = GetGamePool('CPed')
    for _, ped in pairs(nearbyPeds) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            local isOldNPC = false
            
            for _, loc in ipairs(locations) do
                local distance = #(loc - pedCoords)
                -- If ped is very close to our spawn location, likely our old NPC
                if distance < 2.0 then
                    local pedModel = GetEntityModel(ped)
                    local targetModel = GetHashKey(Config.NPCModel)
                    
                    if pedModel == targetModel then
                        isOldNPC = true
                        break
                    end
                end
            end
            
            if isOldNPC then
                DeleteEntity(ped)
            end
        end
    end
end

-- Buy item function
local function BuyItem(itemName, itemLabel, price)
    local input = exports.ox_lib:inputDialog(Config.Lang['quantity_input'], {
        {
            type = 'number',
            label = 'Số lượng',
            placeholder = Config.Lang['quantity_placeholder'],
            min = 1,
            max = 10,
            required = true
        }
    })
    
    if not input or not input[1] then
        exports.ox_lib:notify({
            title = 'Thông báo',
            description = Config.Lang['purchase_cancelled'],
            type = 'error'
        })
        return
    end
    
    local quantity = tonumber(input[1])
    
    if not quantity or quantity <= 0 then
        exports.ox_lib:notify({
            title = 'Lỗi',
            description = Config.Lang['invalid_quantity'],
            type = 'error'
        })
        return
    end
    
    -- Kiểm tra giới hạn số lượng
    if quantity > Config.MaxPurchaseQuantity then
        exports.ox_lib:notify({
            title = 'Lỗi',
            description = string.format(Config.Lang['max_quantity_exceeded'], Config.MaxPurchaseQuantity),
            type = 'error'
        })
        return
    end
    
    local totalCost = price * quantity
    
    -- Confirm purchase
    local confirm = exports.ox_lib:alertDialog({
        header = 'Xác nhận mua hàng',
        content = string.format(Config.Lang['confirm_purchase'], quantity, itemLabel, totalCost, Config.CurrencyLabel),
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        TriggerServerEvent('nl_blackitem:server:buyItem', itemName, quantity, price)
    else
        exports.ox_lib:notify({
            title = 'Thông báo',
            description = Config.Lang['purchase_cancelled'],
            type = 'inform'
        })
    end
end

-- Open shop menu using ox_lib context
local function OpenShopMenu()
    if not IsTimeAllowed() then
        exports['qb-core']:GetCoreObject().Functions.Notify(Config.Lang['time_restriction'], 'error')
        return
    end
    
    local options = {}
    
    -- Sử dụng availableItems thay vì Config.Items
    for _, item in pairs(availableItems) do
        local currentPrice = currentPrices[item.item] or math.random(item.minPrice, item.maxPrice)
        
        table.insert(options, {
            title = item.label,
            description = string.format('%s\n%s', item.description, string.format(Config.Lang['price_info'], currentPrice, Config.CurrencyLabel)),
            icon = item.icon,
            onSelect = function()
                BuyItem(item.item, item.label, currentPrice)
            end,
            metadata = {
                {label = 'Giá hiện tại', value = currentPrice .. ' ' .. Config.CurrencyLabel}
            }
        })
    end
    
    -- Kiểm tra nếu không có vật phẩm nào
    if #options == 0 then
        exports['qb-core']:GetCoreObject().Functions.Notify(Config.Lang['no_items_available'], 'error')
        return
    end
    
    exports.ox_lib:registerContext({
        id = 'blackmarket_shop',
        title = Config.Lang['shop_title'],
        options = options
    })
    
    exports.ox_lib:showContext('blackmarket_shop')
end

-- Spawn NPC
local function SpawnNPC()
    if not IsTimeAllowed() then
        return
    end
    
    -- Clean up any existing NPC first
    DespawnNPC()
    
    local model = GetHashKey(Config.NPCModel)
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    local locationsToSpawn = {}
    if Config.RandomNPCLocation then
        -- Spawn tại vị trí được đồng bộ từ server
        local index = activeNPCLocationIndex or 1
        if Config.NPCLocations and Config.NPCLocations[index] then
            table.insert(locationsToSpawn, Config.NPCLocations[index])
        elseif Config.NPCLocation then
            table.insert(locationsToSpawn, Config.NPCLocation)
        end
    elseif Config.NPCLocations and #Config.NPCLocations > 0 then
        -- Spawn tại tất cả các vị trí trong danh sách
        for _, loc in ipairs(Config.NPCLocations) do
            table.insert(locationsToSpawn, loc)
        end
    elseif Config.NPCLocation then
        -- Vị trí fallback nếu không có NPCLocations
        table.insert(locationsToSpawn, Config.NPCLocation)
    end
    
    for _, loc in ipairs(locationsToSpawn) do
        local npcPed = CreatePed(4, model, loc.x, loc.y, loc.z - 1.0, loc.w, false, true)
        
        SetEntityHeading(npcPed, loc.w)
        FreezeEntityPosition(npcPed, true)
        SetEntityInvincible(npcPed, true)
        SetBlockingOfNonTemporaryEvents(npcPed, true)
        
        table.insert(spawnedNPCs, npcPed)
        
        -- Add blip (giữ lại code mẫu blip nếu sau này người dùng muốn mở)
        --[[
        local blip = AddBlipForEntity(npcPed)
        SetBlipSprite(blip, 378)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 1)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.NPCName)
        EndTextCommandSetBlipName(blip)
        table.insert(npcBlips, blip)
        --]]
        
        -- Setup ox_target for NPC
        exports.ox_target:addLocalEntity(npcPed, {
            {
                name = 'blackmarket_shop',
                icon = 'fas fa-shopping-cart',
                label = Config.Lang['npc_label'],
                onSelect = function()
                    OpenShopMenu()
                end,
                distance = 2.0
            }
        })
    end
    
    isNPCSpawned = #spawnedNPCs > 0
end

-- Initialize prices from server (hỗ trợ cả latent và normal event)
RegisterNetEvent('nl_blackitem:client:updatePrices', function(payload)
    local prices = UnpackLatent(payload)
    if type(prices) == 'table' then
        currentPrices = prices
    end
end)

-- Initialize available items from server (hỗ trợ cả latent và normal event)
RegisterNetEvent('nl_blackitem:client:updateAvailableItems', function(payload)
    local items = UnpackLatent(payload)
    if type(items) ~= 'table' then return end
    
    local oldItems = availableItems
    availableItems = items
    
    -- Thông báo khi vật phẩm thay đổi (chỉ khi đã có vật phẩm trước đó)
    if #oldItems > 0 and #items > 0 then
        -- So sánh để xem có thay đổi không
        local changed = false
        if #oldItems ~= #items then
            changed = true
        else
            for i, item in ipairs(items) do
                if not oldItems[i] or oldItems[i].item ~= item.item then
                    changed = true
                    break
                end
            end
        end
        
        if changed and isNearNPC then
            exports['qb-core']:GetCoreObject().Functions.Notify(Config.Lang['item_changed'], 'inform')
        end
    end
end)

-- Sync NPC Location index from server (hỗ trợ cả latent và normal event)
RegisterNetEvent('nl_blackitem:client:updateNPCLocation', function(payload)
    local locationIndex = UnpackLatent(payload)
    if type(locationIndex) ~= 'number' then return end
    
    if activeNPCLocationIndex ~= locationIndex then
        activeNPCLocationIndex = locationIndex
        if isNPCSpawned then
            DespawnNPC()
            if IsTimeAllowed() then
                SpawnNPC()
            end
        end
    end
end)

-- Handle purchase result
RegisterNetEvent('nl_blackitem:client:purchaseResult', function(success, message, itemLabel, quantity, totalCost)
    if success then
        exports.ox_lib:notify({
            title = 'Thành công',
            description = string.format(Config.Lang['purchase_success'], quantity, itemLabel, totalCost, Config.CurrencyLabel),
            type = 'success'
        })
    else
        exports.ox_lib:notify({
            title = 'Lỗi',
            description = message,
            type = 'error'
        })
    end
end)

-- Check distance to NPC for optimization and time-based spawning
CreateThread(function()
    while true do
        local timeAllowed = IsTimeAllowed()
        
        -- Handle NPC spawning/despawning based on time
        if timeAllowed and not isNPCSpawned then
            SpawnNPC()
        elseif not timeAllowed and isNPCSpawned then
            DespawnNPC()
        end
        
        -- Check distance to any spawned NPC
        if #spawnedNPCs > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearAnyNPC = false
            
            for _, npcEntity in ipairs(spawnedNPCs) do
                if DoesEntityExist(npcEntity) then
                    local npcCoords = GetEntityCoords(npcEntity)
                    local distance = #(playerCoords - npcCoords)
                    if distance <= 10.0 then
                        nearAnyNPC = true
                        break
                    end
                end
            end
            
            local wasNearNPC = isNearNPC
            isNearNPC = nearAnyNPC
            
            if isNearNPC and not wasNearNPC then
                -- Player entered range, request price update
                TriggerServerEvent('nl_blackitem:server:requestPrices')
            end
        end
        
        Wait(5000) -- Check every 5 seconds for time changes
    end
end)

-- Initialize when resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Wait(1000)
        -- Clean up any existing NPCs first
        CleanupExistingNPCs()
        Wait(500)
        
        if IsTimeAllowed() then
            SpawnNPC()
        end
        TriggerServerEvent('nl_blackitem:server:requestPrices')
    end
end)

-- Initialize when player spawns
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    -- Clean up any existing NPCs first
    CleanupExistingNPCs()
    Wait(500)
    
    if IsTimeAllowed() then
        SpawnNPC()
    end
    TriggerServerEvent('nl_blackitem:server:requestPrices')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DespawnNPC()
        CleanupExistingNPCs()
    end
end)

-- Command to manually cleanup NPCs (for admins)
RegisterCommand('cleannpc', function()
    CleanupExistingNPCs()
    DespawnNPC()
    
    exports['qb-core']:GetCoreObject().Functions.Notify('Đã dọn dẹp NPCs trong khu vực', 'success')
    
    Wait(500)
    if IsTimeAllowed() then
        SpawnNPC()
        exports['qb-core']:GetCoreObject().Functions.Notify('Đã spawn lại NPC dealer', 'inform')
    end
end, false)
