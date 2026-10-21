if not lib.checkDependency('stevo_lib', '1.7.1') then error('stevo_lib 1.7.1 required for stevo_trickortreat') end
lib.versionCheck('stevoscriptsteam/stevo_trickortreat')
lib.locale()
local config = require('config')
local stevo_lib = exports['stevo_lib']:import()
local activeCooldowns = {}

lib.callback.register('stevo_trickortreat:canKnock', function(source, houseId)
    if activeCooldowns[source] then 
        if activeCooldowns[source][houseId] then 
            if activeCooldowns[source][houseId] > os.time() then 
                return false
            end 
        end
    end

    return true
end)


local function getTreatItem(key, val)
    if type(val) == 'table' then
        return val.item or val.name
    elseif type(key) == 'string' and type(val) == 'number' then
        return key
    elseif type(val) == 'string' then
        return val
    end
    return nil
end

local function getTreatChance(key, val)
    if type(val) == 'table' then
        return tonumber(val.chance) or tonumber(val.weight) or 1
    elseif type(key) == 'string' and type(val) == 'number' then
        return val
    end
    return 1
end

local function getRandomTreat()
    local totalWeight = 0
    for k, v in pairs(config.treats) do
        local chance = getTreatChance(k, v)
        if chance > 0 then
            totalWeight = totalWeight + chance
        end
    end

    if totalWeight <= 0 then return nil end

    local roll = math.random(1, totalWeight)
    local currentWeight = 0

    for k, v in pairs(config.treats) do
        local chance = getTreatChance(k, v)
        if chance > 0 then
            currentWeight = currentWeight + chance
            if roll <= currentWeight then
                local itemName = getTreatItem(k, v)
                local customAmount = type(v) == 'table' and v.amount or nil
                return itemName, customAmount
            end
        end
    end

    return nil
end

lib.callback.register('stevo_trickortreat:knockedOnDoor', function(source, houseId)

    local location = config.houses[houseId]
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    math.randomseed(os.time())

    if #(playerCoords - location) > config.interactDistance then 
        local name = GetPlayerName(source)
        local identifier = stevo_lib.GetIdentifier(source)

        lib.print.info(('User: %s (%s) tried to exploit stevo_trickortreat'):format(name, identifier))
        if config.dropCheaters then 
            DropPlayer(source, 'Trying to exploit stevo_trickortreat')
        end

        return false
    end

    local cooldown = os.time() + config.knockCooldown * 60

    if not activeCooldowns[source] then 
        activeCooldowns[source] = {}
    end
        
    activeCooldowns[source][houseId] = cooldown

    local trickChance = math.random(1, 100)
             
    if trickChance <= config.trickChance then 
        local ped = math.random(1, #config.trickPeds)
        local weapon = math.random(1, #config.trickWeapons)

        return {ped = config.trickPeds[ped], weapon = config.trickWeapons[weapon]}
    end


    local selectedTreat, customAmount = getRandomTreat()
    if selectedTreat then
        local minAmount = customAmount and customAmount.min or config.treatAmount.min
        local maxAmount = customAmount and customAmount.max or config.treatAmount.max
        local treatAmount = math.random(minAmount, maxAmount)
        stevo_lib.AddItem(source, selectedTreat, treatAmount)
    end

    return false
end)

lib.callback.register('stevo_trickortreat:sellCandy', function(source)
    local candySold = 0 
    local profit = 0
    local soldCandy = false

    for k, v in pairs(config.treats) do 
        local candy = getTreatItem(k, v)
        if candy then
            local amount = stevo_lib.HasItem(source, candy)

            if amount and amount > 0 then 
                local payout = amount * math.random(config.candyBuyer.candySellPrice.min, config.candyBuyer.candySellPrice.max)

                stevo_lib.RemoveItem(source, candy, amount)

                candySold = candySold + amount 
                profit = profit + payout
                soldCandy = true
            end
        end
    end

    if soldCandy then 
        stevo_lib.AddItem(source, 'money', profit)
    end

    return soldCandy, profit, candySold
end)