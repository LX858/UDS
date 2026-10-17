-- lib is provided by ox_lib via fxmanifest.lua
---@diagnostic disable-next-line: undefined-global
local lib = lib

local QBCore = exports['qb-core']:GetCoreObject()
local isSmelting = false
local isBusy = false

-- Function to get random reward from gem
local function GetRandomGemReward(gemConfig)
    local random = math.random(1, 100)
    local currentChance = 0
    
    for _, reward in ipairs(gemConfig.rewards) do
        currentChance = currentChance + reward.chance
        if random <= currentChance then
            return reward
        end
    end
    
    return gemConfig.rewards[1] -- fallback
end

-- Function to get random reward
local function GetRandomReward()
    local random = math.random(1, 100)
    local currentChance = 0
    
    for _, reward in ipairs(Config.SmeltingRewards) do
        currentChance = currentChance + reward.chance
        if random <= currentChance then
            return reward
        end
    end
    
    return Config.SmeltingRewards[1] -- fallback to first reward
end

-- Function to open smelting menu
local function OpenSmeltingMenu()
    lib.registerContext({
        id = 'smelting_menu',
        title = Config.SmeltingText.menuTitle,
        options = {
            {
                title = Config.SmeltingText.regularSmelt,
                description = 'Nung đá thường để nhận quặng',
                icon = 'fa-solid fa-fire',
                onSelect = function()
                    SmeltStone()
                end
            }
            -- {
            --     title = Config.SmeltingText.gemSmelt,
            --     description = 'Nung ngọc quý để nhận vật phẩm đặc biệt',
            --     icon = 'fa-solid fa-gem',
            --     onSelect = function()
            --         OpenGemSmeltingMenu()
            --     end
            -- }
        }
    })

    lib.showContext('smelting_menu')
end

-- Function to open gem smelting menu
function OpenGemSmeltingMenu()
    local options = {}
    
    -- Add back button
    table.insert(options, {
        title = Config.SmeltingText.backButton,
        icon = 'fa-solid fa-arrow-left',
        onSelect = function()
            OpenSmeltingMenu()
        end
    })
    
    -- Add gem options
    for _, gem in ipairs(Config.GemSmelting.gems) do
        table.insert(options, {
            title = gem.name,
            description = 'Nung ' .. gem.name .. ' để nhận vật phẩm đặc biệt',
            icon = 'fa-solid fa-gem',
            onSelect = function()
                SmeltGem(gem)
            end
        })
    end

    lib.registerContext({
        id = 'gem_smelting_menu',
        title = Config.SmeltingText.gemMenuTitle,
        options = options
    })

    lib.showContext('gem_smelting_menu')
end

-- Function to smelt gem
function SmeltGem(gemConfig)
    -- Check if player is in vehicle
    if Config.IsPlayerInVehicle() then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn không thể nung ngọc khi đang ngồi trên xe!',
            type = 'error'
        })
        return
    end
    
    -- Check if player is busy with progressbar
    local busy = exports["progressbar"]:isDoingSomething()
    if busy or isBusy or isSmelting then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn đang thực hiện hành động khác!',
            type = 'error'
        })
        return
    end
    
    -- Check for gem item using ox_inventory
    local hasGem = exports.ox_inventory:Search('slots', gemConfig.item)
    if not hasGem or #hasGem == 0 then
        lib.notify({
            title = 'Lỗi',
            description = Config.SmeltingText.noGem,
            type = 'error'
        })
        return
    end
    
    -- Set busy states
    isSmelting = true
    LocalPlayer.state.invBusy = true
    isBusy = true
    
    TriggerServerEvent('xn_daoda:startSmelting', 'gem', Config.GemSmelting.duration, gemConfig.item)
    
    -- Start gem smelting with progressbar
    exports['progressbar']:Progress({
        name = "smelting_gem",
        duration = Config.GemSmelting.duration,
        label = 'Đang nung ' .. gemConfig.name .. '...',
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = Config.GemSmelting.animation.dict,
            anim = Config.GemSmelting.animation.anim,
            flags = Config.GemSmelting.animation.flag,
        }
    }, function(cancelled)
        -- Reset busy states
        isSmelting = false
        LocalPlayer.state.invBusy = false
        isBusy = false
        
        if not cancelled then
            -- Remove gem from inventory
            TriggerServerEvent('xn_daoda:removeGem', gemConfig.item)
            
            -- Get random reward
            local reward = GetRandomGemReward(gemConfig)
            
            if reward.item then
                -- Give reward item
                TriggerServerEvent('xn_daoda:giveReward', reward.item, 1)
                lib.notify({
                    title = 'Nung ngọc thành công',
                    description = 'Bạn đã nhận được ' .. Config.GetItemLabel(reward.item) .. '!',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Nung ngọc thành công',
                    description = Config.SmeltingText.noReward,
                    type = 'inform'
                })
            end
        else
            TriggerServerEvent('xn_daoda:cancelSmelting')
            lib.notify({
                title = 'Nung ngọc',
                description = 'Đã hủy việc nung ngọc!',
                type = 'error'
            })
        end
    end)
end

-- Function to smelt stone
function SmeltStone()
    -- Check if player is in vehicle
    if Config.IsPlayerInVehicle() then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn không thể nung đá khi đang ngồi trên xe!',
            type = 'error'
        })
        return
    end
    
    -- Check if player is busy with progressbar
    local busy = exports["progressbar"]:isDoingSomething()
    if busy or isBusy or isSmelting then
        lib.notify({
            title = 'Thông báo',
            description = 'Bạn đang thực hiện hành động khác!',
            type = 'error'
        })
        return
    end
    
    -- Check for stones using ox_inventory
    local hasStones = exports.ox_inventory:Search('slots', Config.Smelting.requiredItem)
    if not hasStones or #hasStones == 0 then
        lib.notify({
            title = 'Lỗi',
            description = Config.SmeltingText.noStones,
            type = 'error'
        })
        return
    end
    
    -- Check if has enough stones
    local totalStones = 0
    for _, stoneSlot in pairs(hasStones) do
        totalStones = totalStones + stoneSlot.count
    end
    
    if totalStones < Config.Smelting.requiredAmount then
        lib.notify({
            title = 'Lỗi',
            description = Config.SmeltingText.noStones,
            type = 'error'
        })
        return
    end
    
    -- Set busy states
    isSmelting = true
    isBusy = true
    
    TriggerServerEvent('xn_daoda:startSmelting', 'stone', Config.Smelting.duration)
    
    -- Start smelting with progressbar
    exports['progressbar']:Progress({
        name = "smelting_stone",
        duration = Config.Smelting.duration,
        label = Config.SmeltingText.progressLabel,
        useWhileDead = false,
        canCancel = true,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = Config.Smelting.animation.dict,
            anim = Config.Smelting.animation.anim,
            flags = Config.Smelting.animation.flag,
        }
    }, function(cancelled)
        -- Reset busy states
        isSmelting = false
        isBusy = false
        
        if not cancelled then
            -- Remove stones from inventory
            TriggerServerEvent('xn_daoda:removeStones')
            
            -- Get random reward
            local reward = GetRandomReward()
            
            if reward.item then
                -- Give reward item
                                     local hasitem = exports.ox_inventory:Search('slots', Config.RewardItem)
                     if not hasitem then
                        return
                     end
                TriggerServerEvent('xn_daoda:giveReward', reward.item, 1)
            
                lib.notify({
                    title = Config.SmeltingText.successTitle,
                    description = 'Bạn đã nhận được ' .. Config.GetItemLabel(reward.item) .. '!',
                    type = 'success'
                })
            else
                lib.notify({
                    title = Config.SmeltingText.successTitle,
                    description = Config.SmeltingText.noReward,
                    type = 'inform'
                })
            end
        else
            TriggerServerEvent('xn_daoda:cancelSmelting')
            lib.notify({
                title = Config.SmeltingText.cancelTitle,
                description = Config.SmeltingText.cancelDesc,
                type = 'error'
            })
        end
    end)
end

-- Initialize ox_target for smelting location
CreateThread(function()
    local smeltingLocation = vector3(1110.54, -2008.49, 31.83)
    
    -- Add ox_target zone for smelting
    exports.ox_target:addSphereZone({
        coords = smeltingLocation,
        radius = 2.0,
        options = {
            {
                name = 'smelting_furnace',
                icon = 'fas fa-fire',
                label = Config.SmeltingText.interaction,
                onSelect = function()
                    OpenSmeltingMenu()
                end,
                distance = 2.5
            }
        }
    })
    
    print('Debug: Smelting target zone created at:', smeltingLocation)
end)
