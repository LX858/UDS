-- Get config values
local item_pool = Config.ItemPool
local dig_locations = Config.DigLocations

-- Track which location is assigned to which player
local playerAssignedLocations = {}

-- Choose a random item based on weight/rarity
function GetNewRandomItem()
    local totalWeight = 0
    for _, item in ipairs(item_pool) do
        totalWeight = totalWeight + item.weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, item in ipairs(item_pool) do
        currentWeight = currentWeight + item.weight
        if random <= currentWeight then
            return {item = item.item, label = item.label}
        end
    end
    
    -- Fallback
    return {item = item_pool[1].item, label = item_pool[1].label}
end

-- Assign a random location from the fixed list to a player
function AssignRandomLocationToPlayer(player)
    local randomIndex = math.random(1, #dig_locations)
    local location = dig_locations[randomIndex]
    local itemData = GetNewRandomItem()
    
    if Config.debug then
        print(string.format("^3[SERVER] Assigning location %d to player %s: %s", randomIndex, player, tostring(location)))
        print(string.format("^3[SERVER] Item data: %s", json.encode(itemData)))
    end
    
    -- Set target for this specific player (removes their old target if exists)
    SetPlayerProspectingTarget(player, location.x, location.y, location.z, itemData)
    
    -- Store assignment
    playerAssignedLocations[player] = randomIndex
    
    -- Send update to this specific player
    if Config.debug then
        print(string.format("^3[SERVER] Sending target update to player %s", player))
    end
    UpdateProspectingTargets(player)
    if Config.debug then
        print(string.format("^2[SERVER] Assignment complete for player %s", player))
    end
end

-- Function to count police on duty
function CountPoliceOnDuty()
    local count = 0
    local players = exports.qbx_core:GetQBPlayers()
    
    for _, player in pairs(players) do
        if player and player.PlayerData and player.PlayerData.job then
            if player.PlayerData.job.name == 'police' and player.PlayerData.job.onduty then
                count = count + 1
            end
        end
    end
    
    return count
end

RegisterNetEvent('r3_prospecting:activateProspecting', function()
    local player = source
    
    -- Check police requirement
    if Config.RequirePolice then
        local policeCount = CountPoliceOnDuty()
        
        if policeCount < Config.MinimumPolice then
            TriggerClientEvent('ox_lib:notify', player, {
                description = 'Cần có ít nhất ' .. Config.MinimumPolice .. ' cảnh sát đang onduty! (Hiện tại: ' .. policeCount .. ')',
                type = 'error',
                duration = 5000
            })
            return
        end
    end
    
    -- Assign a random location when player starts prospecting
    AssignRandomLocationToPlayer(player)
    -- Trigger prospecting start directly without requesting locations again
    if Config.debug then
        print(string.format("^3[SERVER] Triggering forceStart for player %s", player))
    end
    TriggerClientEvent("prospecting:forceStart", player)
end)

CreateThread(function()
    -- Default difficulty
    SetDifficulty(1.0)

    -- The player collected something
    AddEventHandler("prospecting:onCollected", function(player, resource, data, x, y, z)
        if resource == GetCurrentResourceName() then
            FoundItem(player, data)
            -- Don't assign new location - player must use detector again
        end
    end)

    -- The player started prospecting
    AddEventHandler("prospecting:onStart", function(player)
		TriggerClientEvent('ox_lib:notify', player, {
            description = 'Started prospecting',
            type = 'inform',
            duration = 2500
        })
    end)

    -- The player stopped prospecting
    -- time in milliseconds
    AddEventHandler("prospecting:onStop", function(player, time)
		TriggerClientEvent('ox_lib:notify', player, {
            description = 'Stopped prospecting',
            type = 'inform',
            duration = 2500
        })
    end)
end)


exports.qbx_core:CreateUseableItem('maydomin', function(source)
    exports['XN_DevMode']:ActiveRemoveDurability(source, 'maydomin')
    TriggerClientEvent('r3_prospecting:useDetector', source)
end)

function FoundItem(player, data)
	-- 10% chance to trigger trap (no item, lose health)
	local trapChance = math.random(1, 100)
	
	if trapChance <= 10 then
		-- Trigger trap - no item, lose health (trigger client-side)
		TriggerClientEvent('xn_domin:applyTrapDamage', player, 25) -- Lose 60 HP
		
		TriggerClientEvent('ox_lib:notify', player, {
			description = '💥 Bạn đã đạp phải bẫy chuột! Mất 30 HP',
			type = 'error',
			duration = 5000
		})
		
		if Config.debug then
			print(string.format("^1[SERVER] Player %s triggered trap!", player))
		end
	else
		-- Normal item drop (90% chance)
		local success = exports.ox_inventory:AddItem(player, data.item, 1)
        if data.item == 'traimin' then
            if Config.Event and Config.Event.enabled then
                if math.random(1, 100) <= Config.Event.chance then
                    local roll = math.random(1, 100)
                    local cumulativeChance = 0
                    for _, reward in ipairs(Config.Event.rewards) do
                        cumulativeChance = cumulativeChance + reward.chance
                        if roll <= cumulativeChance then
                            exports.ox_inventory:AddItem(src, reward.item, 1)
                            break
                        end
                    end
                end
            end
            TriggerClientEvent('client:doramin', player)
        end
		if success then
			TriggerClientEvent('ox_lib:notify', player, {
				description = 'Bạn tìm thấy ' .. data.label .. '!',
				type = 'success',
				duration = 5000
			})
		else
			TriggerClientEvent('ox_lib:notify', player, {
				description = 'Bạn tìm thấy ' .. data.label .. ' nhưng túi đồ đầy!',
				type = 'error',
				duration = 5000
			})
		end
	end
end
