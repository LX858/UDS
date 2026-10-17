local QBCore = exports['qb-core']:GetCoreObject()
local searchedTrash = {} -- Store searched trash cans with cooldown

-- Function to generate unique trash ID based on entity handle
local function getTrashId(entity)
    if not DoesEntityExist(entity) then return nil end
    return tostring(entity) -- Entity handle is unique per trash can
end

-- Function to check if trash can is on cooldown
local function isTrashOnCooldown(entity)
    if not DoesEntityExist(entity) then return false, 0 end
    
    local trashId = getTrashId(entity)
    if not trashId then return false, 0 end
    
    if searchedTrash[trashId] then
        local timePassed = GetGameTimer() - searchedTrash[trashId]
        if timePassed < Config.CooldownTime then
            return true, math.ceil((Config.CooldownTime - timePassed) / 1000 / 60) -- Return remaining minutes
        else
            searchedTrash[trashId] = nil
            return false, 0
        end
    end
    return false, 0
end

-- Function to add trash can to cooldown
local function addTrashToCooldown(entity)
    if not DoesEntityExist(entity) then return end
    
    local trashId = getTrashId(entity)
    if not trashId then return end
    
    searchedTrash[trashId] = GetGameTimer()
end

-- Function to search trash can
local function searchTrashCan(entity)
    if not DoesEntityExist(entity) then return end
    
    -- Check if player is in a vehicle
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify('Không thể lục rác khi đang ngồi trên xe!', 'error')
        return
    end
    
    local onCooldown, remainingTime = isTrashOnCooldown(entity)
    
    if onCooldown then
        QBCore.Functions.Notify('Thùng rác này đã được lục rồi! Chờ ' .. remainingTime .. ' phút nữa.', 'error')
        return
    end
    
    -- Start minigame
    local success = lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'})
    
    if not success then
        QBCore.Functions.Notify('Thất bại! Không thể lục thùng rác.', 'error')
        return
    end
    
    -- Start progress bar after minigame success
    QBCore.Functions.Progressbar("search_trash", "Đang lục thùng rác...", Config.SearchTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 16,
    }, {}, {}, function() -- Done
        ClearPedTasks(PlayerPedId())
        addTrashToCooldown(entity)
        local coords = GetEntityCoords(entity)
        exports['monitors']:TriggerProtectedServerEvent('xn_lucrac:searchTrash', coords)
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify('Đã hủy lục thùng rác!', 'error')
    end)
end

-- Initialize qtarget when resource starts
CreateThread(function()
    Wait(1000) -- Wait for qtarget to load
    
    -- Try different target systems
    local targetResource = nil
    if GetResourceState('qtarget') == 'started' then
        targetResource = 'qtarget'
    elseif GetResourceState('qb-target') == 'started' then
        targetResource = 'qb-target'
    end
    
    if targetResource then
        exports[targetResource]:AddTargetModel(Config.Trashcans, {
            options = {
                {
                    type = "client",
                    event = "xn_lucrac:searchTrash",
                    icon = "fas fa-search",
                    label = "Lục thùng rác",
                },
            },
            distance = 2.0
        })
        --print("^2[XN_LUCRAC]^7 Đã tải thành công với " .. targetResource)
    else
        --print("^1[XN_LUCRAC]^7 Không tìm thấy qtarget hoặc qb-target!")
    end
end)

-- Event handler for qtarget
RegisterNetEvent('xn_lucrac:searchTrash')
AddEventHandler('xn_lucrac:searchTrash', function(data)
    local entity = data.entity
    if entity then
        --print('1111')
        searchTrashCan(entity)
    end
end)

-- Refining system
local function startRefining(recipe)
    local recipeData = Config.RefiningRecipes[recipe]
    if not recipeData then return end
    
    QBCore.Functions.Progressbar("refining_process", "Đang tinh luyện " .. recipeData.output .. "...", Config.RefiningTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        flags = 16,
    }, {}, {}, function() -- Done
        ClearPedTasks(PlayerPedId())
        TriggerServerEvent('xn_lucrac:refineItem', recipe)
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify('Đã hủy tinh luyện!', 'error')
    end)
end

local function openRefiningMenu()
    local refiningOptions = {}
    
    for recipeId, recipe in pairs(Config.RefiningRecipes) do
        -- Check if player has enough materials
        local itemCount = exports.ox_inventory:Search('count', recipe.input) or 0
        
        print("^3[DEBUG] Total", recipe.input, "found:", itemCount, "needed:", recipe.inputAmount)
        
        local hasEnoughMaterials = itemCount >= recipe.inputAmount
        
        if hasEnoughMaterials then
            -- Can craft - normal option
            table.insert(refiningOptions, {
                title = recipe.label,
                description = recipe.inputAmount .. " " .. recipe.input .. " → " .. recipe.outputAmount .. " " .. recipe.output .. " ✅ (Có: " .. itemCount .. ")",
                icon = 'fire',
                onSelect = function()
                    startRefining(recipeId)
                end
            })
        else
            -- Cannot craft - disabled option
            table.insert(refiningOptions, {
                title = recipe.label .. " ❌",
                description = recipe.inputAmount .. " " .. recipe.input .. " → " .. recipe.outputAmount .. " " .. recipe.output .. " (Thiếu: " .. (recipe.inputAmount - itemCount) .. ")",
                icon = 'fire',
                disabled = true
            })
        end
    end
    
    exports.ox_lib:registerContext({
        id = 'refining_menu',
        title = '🔥 Lò Tinh Luyện',
        options = refiningOptions
    })
    
    exports.ox_lib:showContext('refining_menu')
end

-- Initialize refining location
CreateThread(function()
    Wait(2000)
    
    -- Try different target systems
    local targetResource = nil
    if GetResourceState('qtarget') == 'started' then
        targetResource = 'qtarget'
    elseif GetResourceState('qb-target') == 'started' then
        targetResource = 'qb-target'
    end
    
    if targetResource then
        exports[targetResource]:AddBoxZone("refining_station", Config.RefiningLocation, 2.0, 2.0, {
            name = "refining_station",
            heading = 0,
            debugPoly = false,
        }, {
            options = {
                {
                    type = "client",
                    event = "xn_lucrac:openRefiningMenu",
                    icon = "fas fa-fire",
                    label = "Mở lò tinh luyện",
                },
            },
            distance = 2.0
        })
        print("^2[XN_LUCRAC]^7 Đã tải refining station với " .. targetResource)
    else
        print("^1[XN_LUCRAC]^7 Không tìm thấy target system cho refining!")
    end
end)

-- Events
RegisterNetEvent('xn_lucrac:openRefiningMenu')
AddEventHandler('xn_lucrac:openRefiningMenu', function()
    openRefiningMenu()
end)

-- Clean up old cooldowns every 30 minutes
CreateThread(function()
    while true do
        Wait(30 * 60 * 1000) -- 30 minutes
        local currentTime = GetGameTimer()
        for trashId, timestamp in pairs(searchedTrash) do
            if currentTime - timestamp > Config.CooldownTime then
                searchedTrash[trashId] = nil
            end
        end
    end
end)
