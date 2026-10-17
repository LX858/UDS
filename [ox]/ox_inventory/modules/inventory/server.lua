if not lib then return end

local Inventory = {}

---@type table<any, OxInventory>
local Inventories = {}

---@class OxInventory
local OxInventory = {}
OxInventory.__index = OxInventory

---Open a player's inventory, optionally with a secondary inventory.
---@param inv? inventory
function OxInventory:openInventory(inv)
	if not self?.player then return end

	inv = Inventory(inv)

	if not inv then return end

	inv:set('open', true)
	inv.openedBy[self.id] = true
	self.open = inv.id

	TriggerEvent('ox_inventory:openedInventory', self.id, inv.id)
end

---Close a player's inventory.
---@param noEvent? boolean
function OxInventory:closeInventory(noEvent)
	if not self.player or not self.open then return end

	local inv = Inventory(self.open)

	if not inv then return end

	inv.openedBy[self.id] = nil
	inv:set('open', false)
	self.open = false
	self.currentShop = nil
	self.containerSlot = nil

	if not noEvent then
		TriggerClientEvent('ox_inventory:closeInventory', self.id, true)
	end

	TriggerEvent('ox_inventory:closedInventory', self.id, inv.id)
end

---@alias updateSlot { item: SlotWithItem | { slot: number }, inventory: string|number }

---Sync a player's inventory state.
---@param slots updateSlot[]
---@param weight { left?: number, right?: number } | number
function OxInventory:syncSlotsWithPlayer(slots, weight)
	TriggerClientEvent('ox_inventory:updateSlots', self.id, slots, weight)
end

---Sync an inventory's state with all player's accessing it.
---@param slots updateSlot[]
---@param syncOwner? boolean
function OxInventory:syncSlotsWithClients(slots, syncOwner)
	for playerId in pairs(self.openedBy) do
		if self.id ~= playerId then
            local target = Inventories[playerId]

            if target then
			    TriggerClientEvent('ox_inventory:updateSlots', playerId, slots, target.weight)
            end
		end
	end

	if syncOwner and self.player then
		TriggerClientEvent('ox_inventory:updateSlots', self.id, slots, self.weight)
	end
end

local Vehicles = lib.load('data.vehicles')
local RegisteredStashes = {}

for _, stash in pairs(lib.load('data.stashes') or {}) do
	RegisteredStashes[stash.name] = {
		name = stash.name,
		label = stash.label,
		owner = stash.owner,
		slots = stash.slots,
		maxWeight = stash.weight,
		groups = stash.groups or stash.jobs,
		coords = shared.target and stash.target?.loc or stash.coords,
        distance = stash.distance or 10
	}
end

local GetVehicleNumberPlateText = GetVehicleNumberPlateText

---Atempts to lazily load inventory data from the database or create a new player-owned instance for "personal" stashes
---@param data table
---@param player table
---@param ignoreSecurityChecks boolean
---@return OxInventory | false | nil
local function loadInventoryData(data, player, ignoreSecurityChecks)
	local source = source
	local inventory

	if not data.type and type(data.id) == 'string' then
		if data.id:find('^glove') then
			data.type = 'glovebox'
		elseif data.id:find('^trunk') then
			data.type = 'trunk'
		elseif data.id:find('^evidence-') then
			data.type = 'policeevidence'
		end
	end

	if data.type == 'trunk' or data.type == 'glovebox' then
		local plate = data.id:sub(6)

		if server.trimplate then
			plate = string.strtrim(plate)
			data.id = ('%s%s'):format(data.id:sub(1, 5), plate)
		end

		inventory = Inventories[data.id]

		if not inventory then
			local entity

			if data.netid then
				entity = NetworkGetEntityFromNetworkId(data.netid)

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given netid).')
				end

                data.entityId = entity
			else
				local vehicles = GetAllVehicles()

				for i = 1, #vehicles do
					local vehicle = vehicles[i]
					local _plate = GetVehicleNumberPlateText(vehicle)

					if _plate:find(plate) then
						entity = vehicle
                        data.entityId = entity
						data.netid = NetworkGetNetworkIdFromEntity(entity)
						break
					end
				end

				if not entity then
					return shared.info('Failed to load vehicle inventory data (no entity exists with given plate).')
				end
			end

			if not source then
				source = NetworkGetEntityOwner(entity)

				if not source then
					return shared.info('Failed to load vehicle inventory data (entity is unowned).')
				end
			end

			local model, class = lib.callback.await('ox_inventory:getVehicleData', source, data.netid)
			local storage = Vehicles[data.type].models[model] or Vehicles[data.type][class]
            local dbId

            if server.getOwnedVehicleId then
                dbId = server.getOwnedVehicleId(entity)
            else
                dbId = data.id:sub(6)
            end

            inventory = Inventory.Create(data.id, plate, data.type, storage[1], 0, storage[2], false, nil, nil, dbId)
		end
	elseif data.type == 'policeevidence' then
		inventory = Inventory.Create(data.id, locale('police_evidence'), data.type, 100, 0, 100000, false)
	else
		local stash = RegisteredStashes[data.id]

		if stash then
			if stash.jobs then stash.groups = stash.jobs end
			if not ignoreSecurityChecks and player and stash.groups and not server.hasGroup(player, stash.groups) then return end

			local owner

			if stash.owner then
				if stash.owner == true then
					owner = data.owner or player?.owner
				else
					owner = stash.owner
				end
			end

			inventory = Inventories[owner and ('%s:%s'):format(stash.name, owner) or stash.name]

			if not inventory then
				inventory = Inventory.Create(stash.name, stash.label or stash.name, 'stash', stash.slots, 0, stash.maxWeight, owner, nil, stash.groups)
                inventory.coords = stash.coords
                inventory.distance = stash.distance
			end
		end
	end

	if data.netid then
        inventory.entityId = data.entityId or NetworkGetEntityFromNetworkId(data.netid)
		inventory.netid = data.netid
	end

	return inventory or false
end

setmetatable(Inventory, {
	__call = function(self, inv, player, ignoreSecurityChecks)
        if Inventory.Lock then return false end

		if not inv then
			return self
		elseif type(inv) == 'table' then
			if inv.__index then return inv end

			return not inv.owner and Inventories[inv.id] or loadInventoryData(inv, player, ignoreSecurityChecks)
		end

		return Inventories[inv] or loadInventoryData({ id = inv }, player, ignoreSecurityChecks)
	end
})

---@cast Inventory +fun(inv: inventory, player?: inventory, ignoreSecurityChecks?: boolean): OxInventory|false|nil

---@param inv inventory
---@param owner? string | number
local function getInventory(inv, owner)
	if not inv then return Inventory end

	local type = type(inv)

	if type == 'table' or type == 'number' then
		return Inventory(inv)
	else
		return Inventory({ id = inv, owner = owner })
	end
end

exports('Inventory', getInventory)
exports('GetInventory', getInventory)

---@param inv inventory
---@param owner? string | number
---@return table?
exports('GetInventoryItems', function(inv, owner)
	return getInventory(inv, owner)?.items
end)

---@param inv inventory
---@param slotId number
---@return OxInventory?
function Inventory.GetContainerFromSlot(inv, slotId)
	local inventory = Inventory(inv)
	local slotData = inventory and inventory.items[slotId]

	if not slotData then return end

	local container = Inventory(slotData.metadata.container)

	if not container then
		container = Inventory.Create(slotData.metadata.container, slotData.label, 'container', slotData.metadata.size[1], 0, slotData.metadata.size[2], false)
	end

	return container
end

exports('GetContainerFromSlot', Inventory.GetContainerFromSlot)

---@param inv? inventory
---@param ignoreId? number|false
function Inventory.CloseAll(inv, ignoreId)
	if not inv then
		for _, data in pairs(Inventories) do
			for playerId in pairs(data.openedBy) do
				local playerInv = Inventory(playerId)

				if playerInv then playerInv:closeInventory(true) end
			end
		end

		return TriggerClientEvent('ox_inventory:closeInventory', -1, true)
	end

	inv = Inventory(inv) --[[@as OxInventory?]]

	if not inv then return end

	for playerId in pairs(inv.openedBy) do
		local playerInv = Inventory(playerId)

		if playerInv and playerId ~= ignoreId then
            playerInv:closeInventory()
        end
	end
end

---@param inv inventory
---@param k string
---@param v any
function Inventory.Set(inv, k, v)
	inv = Inventory(inv) --[[@as OxInventory]]

	if inv then
		if type(v) == 'number' then
			v = math.floor(v + 0.5)
		end

		if k == 'open' and v == false then
			if inv.type ~= 'player' then
				if inv.player then
					inv.type = 'player'
				elseif inv.type == 'drop' and not next(inv.items) and not next(inv.openedBy) then
					return Inventory.Remove(inv)
				else
					inv.time = os.time()
				end
			end

			if inv.player then
				inv.containerSlot = nil
			end
		elseif k == 'maxWeight' and v < 1000 then
			v *= 1000
		end

		inv[k] = v
	end
end

---@param inv inventory
---@param key string
function Inventory.Get(inv, key)
	inv = Inventory(inv) --[[@as OxInventory]]
	if inv then
		return inv[key]
	end
end

---@class MinimalInventorySlot
---@field name string
---@field count number
---@field slot number
---@field metadata? table

---@param inv inventory
---@return MinimalInventorySlot[] items
local function minimal(inv)
	inv = Inventory(inv) --[[@as OxInventory]]
	local inventory, count = {}, 0
	for k, v in pairs(inv.items) do
		if v.name and v.count > 0 then
			count += 1
			local metadata = next(v.metadata) and table.clone(v.metadata) or nil
			
			-- Convert components sparse array to object for proper JSON serialization
			if metadata and metadata.components then
				--print("[MINIMAL SAVE] Converting components for item:", v.name)
				--print("[MINIMAL SAVE] Before convert:", json.encode(metadata.components))
				local componentsObj = {}
				for i, component in pairs(metadata.components) do
					componentsObj[tostring(i)] = component
					--print("[MINIMAL SAVE] Slot", i, "→", component)
				end
				metadata.components = componentsObj
				--print("[MINIMAL SAVE] After convert:", json.encode(metadata.components))
			end
			
			inventory[count] = {
				name = v.name,
				count = v.count,
				slot = k,
				metadata = metadata
			}
		end
	end
	return inventory
end

---@param inv inventory
---@param item table
---@param count number
---@param metadata any
---@param slot any
function Inventory.SetSlot(inv, item, count, metadata, slot)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local currentSlot = inv.items[slot]
	local newCount = currentSlot and currentSlot.count + count or count
	local newWeight = currentSlot and inv.weight - currentSlot.weight or inv.weight

	if currentSlot and newCount < 1 then
		TriggerClientEvent('ox_inventory:itemNotify', inv.id, { currentSlot, 'ui_removed', currentSlot.count })
		currentSlot = nil
	else
		currentSlot = {name = item.name, label = item.label, weight = item.weight, slot = slot, count = newCount, description = item.description, metadata = metadata, stack = item.stack, close = item.close, do_hiem = item.do_hiem}
		local slotWeight = Inventory.SlotWeight(item, currentSlot)
		currentSlot.weight = slotWeight
		newWeight += slotWeight

		TriggerClientEvent('ox_inventory:itemNotify', inv.id, { currentSlot, count < 0 and 'ui_removed' or 'ui_added', math.abs(count) })
	end

	inv.weight = newWeight
	inv.items[slot] = currentSlot
	inv.changed = true

	return currentSlot
end

local Items = require 'modules.items.server'

CreateThread(function()
    Inventory.accounts = server.accounts
    TriggerEvent('ox_inventory:loadInventory', Inventory)
end)

function Inventory.GetAccountItemCounts(inv)
    inv = Inventory(inv)

    if not inv then return end

    local accounts = table.clone(server.accounts)

	for _, v in pairs(inv.items) do
		if accounts[v.name] then
			accounts[v.name] += v.count
		end
	end

    return accounts
end

---@param item table
---@param slot table
function Inventory.SlotWeight(item, slot, ignoreCount)
	local weight = ignoreCount and item.weight or item.weight * (slot.count or 1)

	if not slot.metadata then slot.metadata = {} end

	if item.ammoname and slot.metadata.ammo then
		local ammoWeight = Items(item.ammoname)?.weight

		if ammoWeight then
			weight += (ammoWeight * slot.metadata.ammo)
		end
	end

    if item.hash == `WEAPON_PETROLCAN` then
        slot.metadata.weight = 15000 * (slot.metadata.ammo / 100)
    end

	if slot.metadata.components then
		for i = #slot.metadata.components, 1, -1 do
			local componentWeight = Items(slot.metadata.components[i])?.weight

			if componentWeight then
				weight += componentWeight
			end
		end
	end

	if slot.metadata.weight then
		weight += ignoreCount and slot.metadata.weight or (slot.metadata.weight * (slot.count or 1))
	end

	return weight
end

---@param items table
function Inventory.CalculateWeight(items)
	local weight = 0
	for _, v in pairs(items) do
		local item = Items(v.name)
		if item then
			weight = weight + Inventory.SlotWeight(item, v)
		end
	end
	return weight
end

-- This should be handled by frameworks, but sometimes isn't or is exploitable in some way.
local activeIdentifiers = {}

local function hasActiveInventory(playerId, owner)
	local activePlayer = activeIdentifiers[owner]

	if activePlayer then
        if activePlayer == playerId then
            error('attempted to load active player\'s inventory a secondary time', 0)
        end

		local inventory = Inventory(activePlayer)

		if inventory then
			local endpoint = GetPlayerEndpoint(activePlayer)

			if endpoint then
				DropPlayer(playerId, ("Character identifier '%s' is already active."):format(owner))

                -- Supposedly still getting stuck? Print info and hope somebody reports back (lol)
				print(('kicked player.%s (charid is already in use)'):format(playerId), json.encode({
					oldId = activePlayer,
					newId = playerId,
					charid = owner,
					endpoint = endpoint,
					playerName = GetPlayerName(activePlayer),
					fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
					license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
				}, {
					indent = true,
                    sort_keys = true
				}))

				return true
			end

			Inventory.CloseAll(inventory)
			db.savePlayer(owner, json.encode(inventory:minimal()))
			Inventory.Remove(inventory)
			Wait(100)
		end
	end

	activeIdentifiers[owner] = playerId
end

---Manually clear an inventory state tied to the given identifier.
---Temporary workaround until somebody actually gives me info.
RegisterCommand('clearActiveIdentifier', function(source, args)
    ---Server console only.
    if source ~= 0 then return end

	local activePlayer = activeIdentifiers[args[1]] or activeIdentifiers[tonumber(args[1])]
    local inventory = activePlayer and Inventory(activePlayer)

    if not inventory then return end

    local endpoint = GetPlayerEndpoint(activePlayer)

    if endpoint then
        DropPlayer(activePlayer, 'Kicked')

        -- Supposedly still getting stuck? Print info and hope somebody reports back (lol)
        print(('kicked player.%s (clearActiveIdentifier)'):format(activePlayer), json.encode({
            oldId = activePlayer,
            charid = inventory.owner,
            endpoint = endpoint,
            playerName = GetPlayerName(activePlayer),
            fivem = GetPlayerIdentifierByType(activePlayer, 'fivem'),
            license = GetPlayerIdentifierByType(activePlayer, 'license2') or GetPlayerIdentifierByType(activePlayer, 'license'),
        }, {
            indent = true,
            sort_keys = true
        }))
    end

    Inventory.CloseAll(inventory)
    db.savePlayer(inventory.owner, json.encode(inventory:minimal()))
    Inventory.Remove(inventory)
end, true)

---@param id string|number
---@param label string|nil
---@param invType string
---@param slots number
---@param weight number
---@param maxWeight number
---@param owner string | number | boolean
---@param items? table
---@param dbId? string | number
---@return OxInventory?
--- This should only be utilised internally!
--- To create a stash, please use `exports.ox_inventory:RegisterStash` instead.
function Inventory.Create(id, label, invType, slots, weight, maxWeight, owner, items, groups, dbId)
	if invType == 'player' and hasActiveInventory(id, owner) then return end

	local self = {
		id = id,
		label = label or id,
		type = invType,
		slots = slots,
		weight = weight,
		maxWeight = maxWeight or shared.playerweight,
		owner = owner,
		items = type(items) == 'table' and items,
		open = false,
		set = Inventory.Set,
		get = Inventory.Get,
		minimal = minimal,
		time = os.time(),
		groups = groups,
		openedBy = {},
        dbId = dbId
	}

	if invType == 'drop' or invType == 'temp' or invType == 'dumpster' then
		self.datastore = true
	else
		self.changed = false

		if invType ~= 'glovebox' and invType ~= 'trunk' then
			self.dbId = id

			if invType ~= 'player' and owner and type(owner) ~= 'boolean' then
				self.id = ('%s:%s'):format(self.id, owner)
			end
		end
	end

	if not items then
		self.items, self.weight = Inventory.Load(self.dbId, invType, owner)
	elseif weight == 0 and next(items) then
		self.weight = Inventory.CalculateWeight(items)
	end

	Inventories[self.id] = setmetatable(self, OxInventory)
	return Inventories[self.id]
end

---@param inv inventory
function Inventory.Remove(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

    if inv.type == 'drop' then
        TriggerClientEvent('ox_inventory:removeDrop', -1, inv.id)
        Inventory.Drops[inv.id] = nil
    elseif inv.player then
        activeIdentifiers[inv.owner] = nil
    end

    for playerId in pairs(inv.openedBy) do
        if inv.id ~= playerId then
            local target = Inventories[playerId]

            if target then
                target:closeInventory()
            end
        end
    end

    if not inv.datastore and inv.changed then
        Inventory.Save(inv)
    end

    Inventories[inv.id] = nil
end

exports('RemoveInventory', Inventory.Remove)

---Update the internal reference to vehicle stashes. Does not trigger a save or update the database.
---@param oldPlate string
---@param newPlate string
function Inventory.UpdateVehicle(oldPlate, newPlate)
	oldPlate = oldPlate:upper()
	newPlate = newPlate:upper()

	if server.trimplate then
		oldPlate = string.strtrim(oldPlate)
		newPlate = string.strtrim(newPlate)
	end

	local trunk = Inventory(('trunk%s'):format(oldPlate))
	local glove = Inventory(('glove%s'):format(oldPlate))

	if trunk then
		Inventory.CloseAll(trunk)

		Inventories[trunk.id] = nil
		trunk.label = newPlate
		trunk.dbId = type(trunk.id) == 'number' and trunk.dbId or newPlate
		trunk.id = ('trunk%s'):format(newPlate)
		Inventories[trunk.id] = trunk
	end

	if glove then
		Inventory.CloseAll(glove)

		Inventories[glove.id] = nil
		glove.label = newPlate
		glove.dbId = type(glove.id) == 'number' and glove.dbId or newPlate
		glove.id = ('glove%s'):format(newPlate)
		Inventories[glove.id] = glove
	end
end

exports('UpdateVehicle', Inventory.UpdateVehicle)

function Inventory.Save(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv or inv.datastore then return end

    local buffer, n = {}, 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, os.time()) then
            n += 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
    end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false

    if inv.player then
        return shared.framework ~= 'esx' and db.savePlayer(inv.owner, data)
    elseif inv.type == 'trunk' then
        return db.saveTrunk(inv.dbId, data)
    elseif inv.type == 'glovebox' then
        return db.saveGlovebox(inv.dbId, data)
    end

    return db.saveStash(inv.owner, inv.dbId, data)
end

---@alias RandomLoot { [1]: string, [2]: number, [3]: number, [4]?: number }

---@param loot RandomLoot[]
---@param items RandomLoot[]
---@param size number
---@return RandomLoot
local function randomItem(loot, items, size)
    local itemIndex = math.random(1, size)
    local selectedItem = nil

    for _ = 1, size do
        selectedItem = loot[itemIndex]
        local found = false

        for i = 1, #items do
            if items[i][1] == selectedItem[1] then
                found = true
                break
            end
        end

        if not found then break end

        itemIndex = ((itemIndex - 1) % size) + 1
    end

    return selectedItem
end

---@param loot RandomLoot[]
---@return RandomLoot[]
local function randomLoot(loot)
    ---@type RandomLoot[]
    local items = {}
    local size = #loot
    local itemCount = math.random(0, 3)

    for _ = 1, itemCount do
        if #items >= size then break end

        local item = randomItem(loot, items, size)

        if item and math.random(1, 100) <= (item[4] or 80) then
            local count = math.random(item[2], item[3])

            if count > 0 then
                items[#items + 1] = { item[1], count }
            end
        end
    end

    return items
end

---@param inv inventory
---@param invType string
---@param items? table
---@return table returnData, number totalWeight
local function generateItems(inv, invType, items)
	if items == nil then
		if invType == 'dumpster' then
			items = randomLoot(server.dumpsterloot)
		elseif invType == 'vehicle' then
			items = randomLoot(server.vehicleloot)
		end
	end

	if not items then
		items = {}
	end

	local returnData, totalWeight = table.create(#items, 0), 0
	for i = 1, #items do
		local v = items[i]
		local item = Items(v[1])
		if not item then
			warn('unable to generate', v[1], 'item does not exist')
		else
			local metadata, count = Items.Metadata(inv, item, v[3] or {}, v[2])
			local weight = Inventory.SlotWeight(item, {count=count, metadata=metadata})
			totalWeight = totalWeight + weight
			returnData[i] = {name = item.name, label = item.label, weight = weight, slot = i, count = count, description = item.description, metadata = metadata, stack = item.stack, close = item.close, do_hiem = item.do_hiem}
		end
	end

	return returnData, totalWeight
end

---@param id string|number
---@param invType string
---@param owner string | number | boolean
function Inventory.Load(id, invType, owner)
    if not invType then return end

	local result

    if invType == 'trunk' or invType == 'glovebox' then
        result = id and (invType == 'trunk' and db.loadTrunk(id) or db.loadGlovebox(id))

        if not result then
            if server.randomloot then
                return generateItems(id, 'vehicle')
            end
        else
            result = result[invType]
        end
	elseif invType == 'dumpster' then
		if server.randomloot then
			return generateItems(id, invType)
		end
	elseif id then
		result = db.loadStash(owner or '', id)
	end

	local returnData, weight = {}, 0

	if result and type(result) == 'string' then
		result = json.decode(result)
	end

	if result then
		local ostime = os.time()

		for _, v in pairs(result) do
			local item = Items(v.name)
			if item then
				v.metadata = Items.CheckMetadata(v.metadata or {}, item, v.name, ostime)
				
				-- Convert components object back to sparse array
				if v.metadata and v.metadata.components and type(v.metadata.components) == 'table' then
					--print("[INVENTORY LOAD] Converting components for item:", v.name)
					--print("[INVENTORY LOAD] Before convert:", json.encode(v.metadata.components))
					local componentsArray = {}
					for key, component in pairs(v.metadata.components) do
						local index = tonumber(key)
						if index then
							componentsArray[index] = component
							--print("[INVENTORY LOAD] Key", key, "→ Index", index, "→", component)
						end
					end
					v.metadata.components = componentsArray
					--print("[INVENTORY LOAD] After convert:", json.encode(v.metadata.components))
				end
				
				local slotWeight = Inventory.SlotWeight(item, v)
				weight += slotWeight
				returnData[v.slot] = {name = item.name, label = item.label, weight = slotWeight, slot = v.slot, count = v.count, description = item.description, metadata = v.metadata, stack = item.stack, close = item.close, do_hiem = item.do_hiem}
			end
		end
	end

	return returnData, weight
end

local function assertMetadata(metadata)
	if metadata and type(metadata) ~= 'table' then
		metadata = metadata and { type = metadata or nil }
	end

	return metadata
end

---@param inv inventory
---@param item table | string
---@param metadata? any
---@param returnsCount? boolean
---@return table | number | nil
function Inventory.GetItem(inv, item, metadata, returnsCount)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		item = returnsCount and item or table.clone(item)
		inv = Inventory(inv) --[[@as OxInventory]]
		local count = 0

		if inv then
			local ostime = os.time()
			metadata = assertMetadata(metadata)

			for _, v in pairs(inv.items) do
				if v.name == item.name and (not metadata or table.contains(v.metadata, metadata)) and not Items.UpdateDurability(inv, v, item, nil, ostime) then
                    count += v.count
				end
			end
		end

		if returnsCount then return count else
			item.count = count
			return item
		end
	end
end
exports('GetItem', Inventory.GetItem)

---@param fromInventory any
---@param toInventory any
---@param slot1 number
---@param slot2 number
function Inventory.SwapSlots(fromInventory, toInventory, slot1, slot2)
	local fromSlot = fromInventory.items[slot1] and table.clone(fromInventory.items[slot1]) or nil
	local toSlot = toInventory.items[slot2] and table.clone(toInventory.items[slot2]) or nil

	if fromSlot then fromSlot.slot = slot2 end
	if toSlot then toSlot.slot = slot1 end

	fromInventory.items[slot1], toInventory.items[slot2] = toSlot, fromSlot
	fromInventory.changed, toInventory.changed = true, true

	return fromSlot, toSlot
end
exports('SwapSlots', Inventory.SwapSlots)

function Inventory.ContainerWeight(container, metaWeight, playerInventory)
	playerInventory.weight -= container.weight
	container.weight = Items(container.name).weight
	container.weight += metaWeight
	container.metadata.weight = metaWeight
	playerInventory.weight += container.weight
end

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table
---@return boolean? success, string|SlotWithItem|nil response
function Inventory.SetItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count < 0 then return false, 'negative_count' end

	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return false, 'invalid_inventory' end

	inv.changed = true
	local itemCount = Inventory.GetItem(inv, item.name, metadata, true) --[[@as number]]

	if count > itemCount then
		count -= itemCount
		return Inventory.AddItem(inv, item.name, count, metadata)
	elseif count < itemCount then
		itemCount -= count
		return Inventory.RemoveItem(inv, item.name, itemCount, metadata)
	end
end
exports('SetItem', Inventory.SetItem)

---@param inv inventory
function Inventory.GetCurrentWeapon(inv)
	inv = Inventory(inv) --[[@as OxInventory]]

	if inv?.player then
		local weapon = inv.items[inv.weapon]

		if weapon and Items(weapon.name).weapon then
			return weapon
		end

		inv.weapon = nil
	end
end
exports('GetCurrentWeapon', Inventory.GetCurrentWeapon)

---@param inv inventory
---@param slotId number
---@return table? item
function Inventory.GetSlot(inv, slotId)
	if not inv or type(slotId) ~= 'number' then return end

	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if slot and not Items.UpdateDurability(inv, slot, Items(slot.name), nil, os.time()) then
        return slot
	end
end
exports('GetSlot', Inventory.GetSlot)

---@param inv inventory
---@param slotId number
---@param durability number
function Inventory.SetDurability(inv, slotId, durability)
	if not inv or type(slotId) ~= 'number' or type(durability) ~= 'number' then return end

	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if not slot then return end

    Items.UpdateDurability(inv, slot, Items(slot.name), durability)

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end
end
exports('SetDurability', Inventory.SetDurability)

local Utils = require 'modules.utils.server'

---@param inv inventory
---@param slotId number
---@param metadata { [string]: any }
function Inventory.SetMetadata(inv, slotId, metadata)
	if not inv or type(slotId) ~= 'number' then return end

	inv = Inventory(inv) --[[@as OxInventory]]
	local slot = inv and inv.items[slotId]

	if not slot then return end

    local item = Items(slot.name)
    local imageurl = slot.metadata.imageurl
    slot.metadata = type(metadata) == 'table' and metadata or { type = metadata or nil }
    inv.changed = true

    if metadata.weight then
        inv.weight -= slot.weight
        slot.weight = Inventory.SlotWeight(item, slot)
        inv.weight += slot.weight
    end

    if metadata.durability ~= slot.metadata.durability then
        Items.UpdateDurability(inv, slot, item, metadata.durability)
    else
        inv:syncSlotsWithClients({
            {
                item = slot,
                inventory = inv.id
            }
        }, true)
    end

    if inv.player and server.syncInventory then
        server.syncInventory(inv)
    end

    if metadata.imageurl ~= imageurl and Utils.IsValidImageUrl then
        if Utils.IsValidImageUrl(metadata.imageurl) then
            Utils.DiscordEmbed('Valid image URL', ('Updated item "%s" (%s) with valid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 65280)
        else
            Utils.DiscordEmbed('Invalid image URL', ('Updated item "%s" (%s) with invalid url in "%s".\n%s\nid: %s\nowner: %s'):format(metadata.label or slot.label, slot.name, inv.label, metadata.imageurl, inv.id, inv.owner, metadata.imageurl), metadata.imageurl, 16711680)
            metadata.imageurl = nil
        end
    end
end

exports('SetMetadata', Inventory.SetMetadata)

---@param inv inventory
---@param slots number
function Inventory.SetSlotCount(inv, slots)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end
	if type(slots) ~= 'number' then return end

	inv.changed = true
	inv.slots = slots

	if inv.player then
        TriggerClientEvent('ox_inventory:refreshSlotCount', inv.id, {inventoryId = inv.id, slots = inv.slots})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('ox_inventory:refreshSlotCount', playerId, {inventoryId = inv.id, slots = inv.slots})
        end
	end
end

exports('SetSlotCount', Inventory.SetSlotCount)

---@param inv inventory
---@param maxWeight number
function Inventory.SetMaxWeight(inv, maxWeight)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end
	if type(maxWeight) ~= 'number' then return end

	inv.maxWeight = maxWeight

    if inv.player then
        TriggerClientEvent('ox_inventory:refreshMaxWeight', inv.id, {inventoryId = inv.id, maxWeight = inv.maxWeight})
    end

    for playerId in pairs(inv.openedBy) do
        if playerId ~= inv.id then
            TriggerClientEvent('ox_inventory:refreshMaxWeight', playerId, {inventoryId = inv.id, maxWeight = inv.maxWeight})
        end
	end
end

exports('SetMaxWeight', Inventory.SetMaxWeight)

---Map clothing items to their correct inventory slots
---@param itemName string
---@return number|nil
local function GetClothingSlot(itemName)
	-- Mapping dựa trên yêu cầu của user:
	-- Slot(7)  - Mặt nạ (cloth_mask)
	-- Slot(6)  - Mũ (cloth_helmet)
	-- Slot(16) - Tai (cloth_ears)
	-- Slot(8)  - Kính (cloth_glasses)
	-- Slot(17) - Balo (cloth_bags)
	-- Slot(18) - Áo thun (cloth_tshirt)
	-- Slot(11) - Áo khoác (cloth_torso)
	-- Slot(19) - Áo giáp chống đạn (cloth_bproof)
	-- Slot(20) - Vòng tay (cloth_bracelets)
	-- Slot(12) - Đồng hồ (cloth_watches)
	-- Slot(9)  - Dây chuyền (cloth_chain)
	-- Slot(13) - Quần (cloth_pants)
	-- Slot(21) - Giày (cloth_shoes)
	-- Slot(10) - Tay (cloth_arms)
	-- Slot(14) - Trang phục (cloth_outfit)
	
	local clothingSlots = {
		['cloth_mask'] = 7,
		['cloth_helmet'] = 6,
		['cloth_ears'] = 16,
		['cloth_glasses'] = 8,
		['cloth_bags'] = 17,
		['cloth_tshirt'] = 18,
		['cloth_torso'] = 11,
		['cloth_bproof'] = 19,
		['cloth_bracelets'] = 20,
		['cloth_watches'] = 12,
		['cloth_chain'] = 9,
		['cloth_pants'] = 13,
		['cloth_shoes'] = 21,
		['cloth_arms'] = 10,
		['cloth_outfit'] = 14,
		['cloth_decals'] = 15,  -- Thêm slot cho decals nếu cần
		['clothes'] = 14,  -- clothes generic item cũng vào slot outfit
	}
	
	return clothingSlots[itemName]
end

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table | string
---@param slot? number
---@param cb? fun(success?: boolean, response: string|SlotWithItem|nil)
---@return boolean? success, string|SlotWithItem|nil response
function Inventory.AddItem(inv, item, count, metadata, slot, cb)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count <= 0 then return false, 'negative_count' end

	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv?.slots then return false, 'invalid_inventory' end

	local toSlot, slotMetadata, slotCount
	local success, response = false
	metadata = assertMetadata(metadata)

	-- Kiểm tra giới hạn số lượng item (limit)
	if item.limit then
		-- Đếm số slot đang chứa item này
		local itemSlotCount = 0
		for _, slotData in pairs(inv.items) do
			if slotData and slotData.name == item.name then
				itemSlotCount = itemSlotCount + 1
			end
		end
		
		-- Nếu đã đạt giới hạn, không cho thêm
		if itemSlotCount >= item.limit then
			return false, 'cannot_carry_limit'
		end
	end

	-- Danh sách các item được phép vào slot 6-21
	local allowedItems = {
		-- Các item quần áo
		['cloth_outfit'] = true, ['cloth_torso'] = true, ['cloth_tshirt'] = true,
		['cloth_arms'] = true, ['cloth_pants'] = true, ['cloth_shoes'] = true,
		['cloth_decals'] = true, ['cloth_ears'] = true, ['cloth_mask'] = true,
		['cloth_bproof'] = true, ['cloth_chain'] = true, ['cloth_bags'] = true,
		['cloth_glasses'] = true, ['cloth_watches'] = true, ['cloth_bracelets'] = true,
		['cloth_helmet'] = true, ['clothes'] = true,
	}
	-- Kiểm tra slot cấm (6-21) nếu item không nằm trong danh sách cho phép
	if slot and slot >= 6 and slot <= 21 and not allowedItems[item.name] then
		return false, 'restricted_slot'
	end

    -- Nếu slot được chỉ định
    if slot then
        local slotData = inv.items[slot]
        slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

        -- Kiểm tra nếu là clothing item và inventory là player
        local clothingSlot = GetClothingSlot(item.name)
        if clothingSlot and inv.type == 'player' then
            -- Cho phép clothing item vào bất kỳ slot nào được chỉ định (kể cả ngoài 6-21)
            if not slotData or (item.stack and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata)) then
                toSlot = slot
            end
        else
            -- Non-clothing item, logic cũ
            if not slotData or (item.stack and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata)) then
                toSlot = slot
            end
        end
    end

    -- Tìm slot trống nếu chưa có slot được chỉ định
    if not toSlot then
        local items = inv.items
        slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)

        -- Kiểm tra nếu là clothing item và inventory là player
        local clothingSlot = GetClothingSlot(item.name)
        if clothingSlot and inv.type == 'player' then
            -- cloth_bags (balo) đặc biệt: tự động vào slot 17 nếu trống (để mở rộng inventory)
            -- Các clothing item khác: KHÔNG tự động vào 6-21, đặt vào 1-5 hoặc 22+ để player tự mặc
            if item.name == 'cloth_bags' and not items[clothingSlot] then
                toSlot = clothingSlot
            else
                -- Tìm slot trống ngoài vùng 6-21
                for i = 1, inv.slots do
                    if not items[i] and (i < 6 or i > 21) then
                        toSlot = i
                        break
                    end
                end
            end
        else
            -- Logic cũ cho non-clothing items
            for i = 1, inv.slots do
                -- Bỏ qua các slot từ 6 đến 21 khi tìm slot trống cho non-clothing items
                if i < 6 or i > 21 then
                    local slotData = items[i]

                    if item.stack and slotData ~= nil and slotData.name == item.name and table.matches(slotData.metadata, slotMetadata) then
                        toSlot = i
                        break
                    elseif not item.stack and not slotData then
                        if not toSlot then toSlot = {} end

                        toSlot[#toSlot + 1] = { slot = i, count = slotCount, metadata = slotMetadata }

                        if count == slotCount then
                            break
                        end

                        count -= 1
                        slotMetadata, slotCount = Items.Metadata(inv.id, item, metadata and table.clone(metadata) or {}, count)
                    elseif not toSlot and not slotData then
                        toSlot = i
                    end
                end
            end
        end
    end

	if not toSlot then return false, 'inventory_full' end

	inv.changed = true

	local invokingResource = server.loglevel > 1 and GetInvokingResource()
	local toSlotType = type(toSlot)

	if toSlotType == 'number' then
		Inventory.SetSlot(inv, item, slotCount, slotMetadata, toSlot)

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients({
			{
				item = inv.items[toSlot],
				inventory = inv.id
			}
		}, true)

		if invokingResource then
			local metadataStr = metadata and json.encode(metadata) or 'nil'
			lib.logger(inv.owner, 'addItem', ('"%s" thêm %sx %s tới "%s" | metadata: %s'):format(invokingResource, count, item.name, inv.label, metadataStr))
		end
		success = true
		response = inv.items[toSlot]
	elseif toSlotType == 'table' then
		local added = 0

		for i = 1, #toSlot do
			local data = toSlot[i]
			added += data.count
			Inventory.SetSlot(inv, item, data.count, data.metadata, data.slot)
			toSlot[i] = { item = inv.items[data.slot], inventory = inv.id }
		end

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		inv:syncSlotsWithClients(toSlot, true)

		if invokingResource then
			local metadataStr = metadata and json.encode(metadata) or 'nil'
			lib.logger(inv.owner, 'addItem', ('"%s" thêm %sx %s tới "%s" | metadata: %s'):format(invokingResource, added, item.name, inv.label, metadataStr))
		end
		for i = 1, #toSlot do
			toSlot[i] = toSlot[i].item
		end

		success = true
		response = toSlot
	end

	if cb then
		return cb(success, response)
	end

	return success, response
end

exports('AddItem', Inventory.AddItem)

---@param inv inventory
---@param search string|number slots|1, count|2
---@param items table | string
---@param metadata? table | string
function Inventory.Search(inv, search, items, metadata)
	if items then
		inv = Inventory(inv) --[[@as OxInventory]]

		if inv then
			inv = inv.items

			if search == 'slots' then search = 1 elseif search == 'count' then search = 2 end
			if type(items) == 'string' then items = {items} end

			metadata = assertMetadata(metadata)
			local itemCount = #items
			local returnData = {}

			for i = 1, itemCount do
				local item = string.lower(items[i])
				if item:sub(0, 7) == 'weapon_' then item = string.upper(item) end

				if search == 1 then
					returnData[item] = {}
				elseif search == 2 then
					returnData[item] = 0
				end

				for _, v in pairs(inv) do
					if v.name == item then
						if not v.metadata then v.metadata = {} end

						if not metadata or table.contains(v.metadata, metadata) then
							if search == 1 then
								returnData[item][#returnData[item]+1] = inv[v.slot]
							elseif search == 2 then
								returnData[item] += v.count
							end
						end
					end
				end
			end

			if next(returnData) then return itemCount == 1 and returnData[items[1]] or returnData end
		end
	end

	return false
end
exports('Search', Inventory.Search)

---@param inv inventory
---@param item table | string
---@param metadata? table
---@param strict? boolean
function Inventory.GetItemSlots(inv, item, metadata, strict)
	if type(item) ~= 'table' then item = Items(item) end
	if not item then return end

	inv = Inventory(inv) --[[@as OxInventory]]
	if not inv?.slots then return end

	local totalCount, slots, emptySlots = 0, {}, 0

	if strict == nil then strict = true end
	local tablematch = strict and table.matches or table.contains

	-- Kiểm tra nếu là clothing item
	local clothingSlot = GetClothingSlot(item.name)
	
	-- Đếm emptySlots dựa trên loại item
	if clothingSlot and inv.type == 'player' then
		-- Với clothing items: chỉ đếm slot đúng (clothingSlot) hoặc slots < 6 hoặc > 21
		if not inv.items[clothingSlot] then
			emptySlots = emptySlots + 1
		end
		-- Đếm slots < 6 hoặc > 21 trống
		for i = 1, inv.slots do
			if not inv.items[i] and (i < 6 or i > 21) then
				emptySlots = emptySlots + 1
			end
		end
	else
		-- Với non-clothing items: đếm tất cả slots trống ngoại trừ vùng 6-21
		for i = 1, inv.slots do
			if not inv.items[i] and (i < 6 or i > 21) then
				emptySlots = emptySlots + 1
			end
		end
	end

	for k, v in pairs(inv.items) do
		if v.name == item.name then
			if metadata and v.metadata == nil then
				v.metadata = {}
			end
			if not metadata or tablematch(v.metadata, metadata) then
				totalCount = totalCount + v.count
				slots[k] = v.count
			end
		end
	end

	return slots, totalCount, emptySlots
end
exports('GetItemSlots', Inventory.GetItemSlots)

---@param inv inventory
---@param item table | string
---@param count integer
---@param metadata? table | string
---@param slot? number
---@param ignoreTotal? boolean
---@param strict? boolean
---@return boolean? success, string? response
function Inventory.RemoveItem(inv, item, count, metadata, slot, ignoreTotal, strict)
	if type(item) ~= 'table' then item = Items(item) end

	if not item then return false, 'invalid_item' end
	if type(count) ~= 'number' then return false, 'invalid_count' end

	count = math.floor(count + 0.5)
	if count <= 0 then return false, 'negative_count' end

	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv?.slots then return false, 'invalid_inventory' end

	metadata = assertMetadata(metadata)
	if strict == nil then strict = true end
	local itemSlots, totalCount = Inventory.GetItemSlots(inv, item, metadata, strict)

	if not itemSlots then return false end

	if totalCount and count > totalCount then
		if not ignoreTotal then return false, 'not_enough_items' end

		count = totalCount
	end

	local removed, total, slots = 0, count, {}

	if slot and itemSlots[slot] then
		removed = count
		Inventory.SetSlot(inv, item, -count, inv.items[slot].metadata, slot)
		slots[#slots+1] = inv.items[slot] or slot
	elseif itemSlots and totalCount > 0 then
		for k, v in pairs(itemSlots) do
			if removed < total then
				if v == count then
					TriggerClientEvent('ox_inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = total
					inv.weight -= inv.items[k].weight
					inv.items[k] = nil
					slots[#slots+1] = inv.items[k] or k
				elseif v > count then
					Inventory.SetSlot(inv, item, -count, inv.items[k].metadata, k)
					slots[#slots+1] = inv.items[k] or k
					removed = total
					count = v - count
				else
					TriggerClientEvent('ox_inventory:itemNotify', inv.id, { inv.items[k], 'ui_removed', v })

					removed = removed + v
					count = count - v
					inv.weight -= inv.items[k].weight
					inv.items[k] = nil
					slots[#slots+1] = k
				end
			else break end
		end
	end

	if removed > 0 then
		inv.changed = true

		if inv.player and server.syncInventory then
			server.syncInventory(inv)
		end

		local array = table.create(#slots, 0)

		for k, v in pairs(slots) do
			array[k] = {item = type(v) == 'number' and { slot = v } or v, inventory = inv.id}
		end

		inv:syncSlotsWithClients(array, true)

		local invokingResource = server.loglevel > 1 and GetInvokingResource()

		if invokingResource then
			local metadataStr = metadata and json.encode(metadata) or 'nil'
			lib.logger(inv.owner, 'removeItem', ('"%s" xóa %sx %s từ "%s" | metadata: %s'):format(invokingResource, removed, item.name, inv.label, metadataStr))
		end
		return true
	end

	return false, 'not_enough_items'
end
exports('RemoveItem', Inventory.RemoveItem)

---@param inv inventory
---@param item table | string
---@param count number
---@param metadata? table | string
function Inventory.CanCarryItem(inv, item, count, metadata)
	if type(item) ~= 'table' then item = Items(item) end

	if item then
		inv = Inventory(inv) --[[@as OxInventory]]

		if inv then
			local itemSlots, _, emptySlots = Inventory.GetItemSlots(inv, item, type(metadata) == 'table' and metadata or { type = metadata or nil })

			if not itemSlots then return end

			local weight = metadata and metadata.weight or item.weight

			if next(itemSlots) or emptySlots > 0 then
				if not count then count = 1 end
				if not item.stack and emptySlots < count then return false end
				if weight == 0 then return true end

				local newWeight = inv.weight + (weight * count)

				if newWeight > inv.maxWeight then
					return false
				end

				return true
			end
		end
	end
end
exports('CanCarryItem', Inventory.CanCarryItem)

---@param inv inventory
---@param item table | string
function Inventory.CanCarryAmount(inv, item)
    if type(item) ~= 'table' then item = Items(item) end
	inv = Inventory(inv) --[[@as OxInventory]]

    if inv and item then
		local availableWeight = inv.maxWeight - inv.weight
		return math.floor(availableWeight / item.weight)
    end
end

exports('CanCarryAmount', Inventory.CanCarryAmount)

---@param inv inventory
---@param weight number
function Inventory.CanCarryWeight(inv, weight)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local availableWeight = inv.maxWeight - inv.weight
	local canHold = availableWeight >= weight
	return canHold, availableWeight
end
exports('CanCarryWeight', Inventory.CanCarryWeight)

---@param inv inventory
---@param firstItem string
---@param firstItemCount number
---@param testItem string
---@param testItemCount number
function Inventory.CanSwapItem(inv, firstItem, firstItemCount, testItem, testItemCount)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv then return end

	local firstItemData = Inventory.GetItem(inv, firstItem)
	local testItemData = Inventory.GetItem(inv, testItem)

	if firstItemData and testItemData and firstItemData.count >= firstItemCount then
		local weightWithoutFirst = inv.weight - (firstItemData.weight * firstItemCount)
		local weightWithTest = weightWithoutFirst + (testItemData.weight * testItemCount)
		return weightWithTest <= inv.maxWeight
	end
end
exports('CanSwapItem', Inventory.CanSwapItem)

---Mostly for internal use, but deprecated.
---@param name string
---@param count number
---@param metadata { [string]: any }
---@param slot number
RegisterServerEvent('ox_inventory:removeItem', function(name, count, metadata, slot)
	Inventory.RemoveItem(source, name, count, metadata, slot)
end)

Inventory.Drops = {}

---@param prefix string?
---@return string
local function generateInvId(prefix)
	while true do
		local invId = ('%s-%s'):format(prefix or 'drop', math.random(100000, 999999))

		if not Inventories[invId] then return invId end

		Wait(0)
	end
end

local function CustomDrop(prefix, items, coords, slots, maxWeight, instance, model)
	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('%s %s'):format(prefix, dropId:gsub('%D', '')), 'drop', slots or shared.dropslots, 0, maxWeight or shared.dropweight, false, {})

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', items)
	inventory.coords = coords
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = instance,
		model = model,
	}

	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

    return dropId
end

AddEventHandler('ox_inventory:customDrop', CustomDrop)
exports('CustomDrop', CustomDrop)

exports('CreateDropFromPlayer', function(playerId)
	local playerInventory = Inventory(playerId)

	if not playerInventory or not next(playerInventory.items) then return end

	local dropId = generateInvId()
	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', playerInventory.slots, playerInventory.weight, playerInventory.maxWeight, false, table.clone(playerInventory.items))

	if not inventory then return end

	local coords = GetEntityCoords(GetPlayerPed(playerId))
	inventory.coords = vec3(coords.x, coords.y, coords.z-0.2)
	Inventory.Drops[dropId] = {
		coords = inventory.coords,
		instance = Player(playerId).state.instance
	}

	Inventory.Clear(playerInventory)
	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId])

	return dropId
end)

local TriggerEventHooks = require 'modules.hooks.server'

---@class SwapSlotData
---@field count number
---@field fromSlot number
---@field toSlot number
---@field instance any
---@field fromType string
---@field toType string
---@field coords? vector3

---@param source number
---@param playerInventory OxInventory
---@param fromData SlotWithItem?
---@param data SwapSlotData
local function dropItem(source, playerInventory, fromData, data)
    if not fromData then return end

	-- Chặn vứt item có cangive = true
	local item = Items(fromData.name)
	if item and item.cangive == true then
		return false, false, { type = 'error', description = 'Không thể vứt vật phẩm này' }
	end

	local toData = table.clone(fromData)
	toData.slot = data.toSlot
	toData.count = data.count
	toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

    if toData.weight > shared.playerweight then return end

    local dropId = generateInvId('drop')

	if not TriggerEventHooks('swapItems', {
		source = source,
		fromInventory = playerInventory.id,
		fromSlot = fromData,
		fromType = playerInventory.type,
		toInventory = 'newdrop',
		toSlot = data.toSlot,
		toType = 'drop',
		count = data.count,
        action = 'move',
        dropId = dropId,
	}) then return end

    fromData.count -= data.count
    fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

    if fromData.count < 1 then
        fromData = nil
    else
        toData.metadata = table.clone(toData.metadata)
    end

	local slot = data.fromSlot
	playerInventory.weight -= toData.weight
	playerInventory.items[slot] = fromData

	if slot == playerInventory.weapon then
		playerInventory.weapon = nil
	end

	local inventory = Inventory.Create(dropId, ('Drop %s'):format(dropId:gsub('%D', '')), 'drop', shared.dropslots, toData.weight, shared.dropweight, false, {[data.toSlot] = toData})

	if not inventory then return end

	inventory.coords = data.coords
	Inventory.Drops[dropId] = {coords = inventory.coords, instance = data.instance}
	playerInventory.changed = true

	TriggerClientEvent('ox_inventory:createDrop', -1, dropId, Inventory.Drops[dropId], playerInventory.open and source, slot)

	if server.loglevel > 0 then
		local metadataStr = toData.metadata and json.encode(toData.metadata) or 'nil'
		
		lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s chuyển từ "%s" tới "%s" | metadata: %s'):format(data.count, toData.name, playerInventory.label, dropId, metadataStr))
		--print(playerInventory.owner, 'swapSlots', ('%sx %s chuyển từ "%s" tới "%s" | metadata: %s'):format(data.count, toData.name, playerInventory.label, dropId, metadataStr))
	end

	if server.syncInventory then server.syncInventory(playerInventory) end

	return true, {
		weight = playerInventory.weight,
		items = {
			{
				item = fromData or { slot = data.fromSlot },
				inventory = playerInventory.id
			}
		}
	}
end

local activeSlots = {}
--Nút xóa vật phẩm 
lib.callback.register('ox_inventory:DropItemButton', function(source, data, itemData)
	if data.count < 1 then return end
	
	if itemData.name == "money" then 
		return TriggerClientEvent('esx:showNotification', source, "Bạn không thể vứt ⭐!")
	end 

	if data.count <= itemData.count then 
		Inventory.RemoveItem(source, itemData.name, data.count, nil, data.slot)
		return true
	else 
		return false
	end 
end)

---@param source number
---@param data SwapSlotData
lib.callback.register('ox_inventory:swapItems', function(source, data)
	
	if data.toType ~= 'player' and data.fromType ~= 'player' and data.toType ~= data.fromType then
        Utils.LogExploit(source, 'swapItems', 'Sự kiện được kích hoạt với dữ liệu không hợp lệ', true)
        return
    end

	if data.count < 1 then return end

	local playerInventory = Inventory(source)

	if not playerInventory then return end

	local toInventory = (data.toType == 'player' and playerInventory) or Inventory(playerInventory.open)
	local fromInventory = (data.fromType == 'player' and playerInventory) or Inventory(playerInventory.open)

	if not fromInventory or not toInventory then
		playerInventory:closeInventory()
		return
	end

    if data.toType == 'inspect' or data.fromType == 'inspect' then return end

	-- Kiểm tra slot quần áo (6-21):
	-- Chỉ cho phép kéo vào slot 6-21 nếu nguồn LÀ túi đồ của chính người chơi (fromType == 'player')
	-- Không cho phép kéo trực tiếp từ kho ngoài (hòm xe, prop, stash...) vào ô quần áo
	if data.toType == 'player' and data.toSlot and data.toSlot >= 6 and data.toSlot <= 21 then
		-- Nếu kéo từ inventory ngoài (không phải túi đồ của player) → chặn hoàn toàn
		if data.fromType ~= 'player' then
			return false, false, { type = 'error', description = 'Chỉ có thể mặc quần áo từ túi đồ của bạn' }
		end

		local fromData = fromInventory.items[data.fromSlot]
		
		if fromData then
			-- Danh sách các item được phép vào slot 6-21
			local allowedItems = {
				['cloth_outfit'] = true, ['cloth_torso'] = true, ['cloth_tshirt'] = true,
				['cloth_arms'] = true, ['cloth_pants'] = true, ['cloth_shoes'] = true,
				['cloth_decals'] = true, ['cloth_ears'] = true, ['cloth_mask'] = true,
				['cloth_bproof'] = true, ['cloth_chain'] = true, ['cloth_bags'] = true,
				['cloth_glasses'] = true, ['cloth_watches'] = true, ['cloth_bracelets'] = true,
				['cloth_helmet'] = true, ['clothes'] = true,
			}
			
			-- Nếu item không nằm trong danh sách cho phép
			if not allowedItems[fromData.name] then
				return false, false, { type = 'error', description = 'Không thể đặt vật phẩm vào slot này' }
			end
		end
	end

	-- Chặn kéo item từ ô quần áo (6-21) ra kho ngoài (hòm xe, prop, stash...)
	-- Quần áo đang bận chỉ được di chuyển trong túi đồ của player, không được cất ra ngoài
	if data.fromType == 'player' and data.fromSlot and data.fromSlot >= 6 and data.fromSlot <= 21 and data.toType ~= 'player' then
		return false, false, { type = 'error', description = 'Không thể cất quần áo đang bận vào kho' }
	end

	-- Chặn di chuyển item có cangive = true ra khỏi inventory player
	if data.fromType == 'player' and data.toType ~= 'player' then
		local fromData = fromInventory.items[data.fromSlot]
		if fromData then
			local item = Items(fromData.name)
			if item and item.cangive == true then
				return false, false, { type = 'error', description = 'Không thể cất vật phẩm này' }
			end
		end
	end

	local fromRef = ('%s:%s'):format(fromInventory.id, data.fromSlot)
	local toRef = ('%s:%s'):format(toInventory.id, data.toSlot)

	if activeSlots[fromRef] or activeSlots[toRef] then
		return false, {
			{
				item = toInventory.items[data.toSlot] or { slot = data.toSlot },
				inventory = toInventory.id
			},
			{
				item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
				inventory = fromInventory.id
			}
		}
	end

	local sameInventory = fromInventory.id == toInventory.id
	local fromOtherPlayer = fromInventory.player and fromInventory ~= playerInventory
	local toOtherPlayer = toInventory.player and toInventory ~= playerInventory
	local toData = toInventory.items[data.toSlot]

	if not sameInventory and (fromInventory.type == 'policeevidence' or (toInventory.type == 'policeevidence' and toData)) then
		local group, rank = server.hasGroup(playerInventory, shared.police)

		if not group or server.evidencegrade > rank then
			return false, 'evidence_cannot_take'
		end
	end

	activeSlots[fromRef] = true
	activeSlots[toRef] = true

	local _ <close> = defer(function()
		activeSlots[fromRef] = nil
		activeSlots[toRef] = nil
	end)

	if toInventory and (data.toType == 'newdrop' or fromInventory ~= toInventory or data.fromSlot ~= data.toSlot) then
		local fromData = fromInventory.items[data.fromSlot]

		if not fromData then
			return false, {
				{
					item = { slot = data.fromSlot },
					inventory = fromInventory.id
				},
				{
					item = toData or { slot = data.toSlot },
					inventory = toInventory.id
				}
			}
		end

        if data.count > fromData.count then
            data.count = fromData.count
        end

        if data.toType == 'newdrop' then
            return dropItem(source, playerInventory, fromData, data)
        end

		if fromData then
            if fromData.metadata.container and toInventory.type == 'container' then return false end
            if toData and toData.metadata.container and fromInventory.type == 'container' then return false end

			local container, containerItem = (not sameInventory and playerInventory.containerSlot) and (fromInventory.type == 'container' and fromInventory or toInventory)

			if container then
				containerItem = playerInventory.items[playerInventory.containerSlot]
			end

			local hookPayload = {
				source = source,
				fromInventory = fromInventory.id,
				fromSlot = fromData,
				fromType = fromInventory.type,
				toInventory = toInventory.id,
				toSlot = toData or data.toSlot,
				toType = toInventory.type,
				count = data.count,
			}

			if toData and ((toData.name ~= fromData.name) or not toData.stack or (not table.matches(toData.metadata, fromData.metadata))) then
				-- Swap items
				local toWeight = not sameInventory and (toInventory.weight - toData.weight + fromData.weight) or 0
				local fromWeight = not sameInventory and (fromInventory.weight + toData.weight - fromData.weight) or 0
				hookPayload.action = 'swap'

				if not sameInventory then
					-- Kiểm tra limit khi swap
					local toItem = Items(fromData.name)
					local fromItem = Items(toData.name)
					
					if toItem and toItem.limit then
						local itemSlotCount = 0
						for _, slotData in pairs(toInventory.items) do
							if slotData and slotData.name == toItem.name and slotData.slot ~= data.toSlot then
								itemSlotCount = itemSlotCount + 1
							end
						end
						if itemSlotCount >= toItem.limit then
							return false, 'cannot_carry_limit'
						end
					end
					
					if fromItem and fromItem.limit then
						local itemSlotCount = 0
						for _, slotData in pairs(fromInventory.items) do
							if slotData and slotData.name == fromItem.name and slotData.slot ~= data.fromSlot then
								itemSlotCount = itemSlotCount + 1
							end
						end
						if itemSlotCount >= fromItem.limit then
							return false, 'cannot_carry_limit'
						end
					end

					if (toWeight <= toInventory.maxWeight and fromWeight <= fromInventory.maxWeight) then
						if not TriggerEventHooks('swapItems', hookPayload) then return end

						if containerItem then
							local toContainer = toInventory.type == 'container'
							local whitelist = Items.containers[containerItem.name]?.whitelist
							local blacklist = Items.containers[containerItem.name]?.blacklist
							local checkItem = toContainer and fromData.name or toData.name

							if (whitelist and not whitelist[checkItem]) or (blacklist and blacklist[checkItem]) then
								return
							end

							Inventory.ContainerWeight(containerItem, toContainer and toWeight or fromWeight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', fromData.count })
							TriggerClientEvent('ox_inventory:itemNotify', fromInventory.id, { toData, 'ui_added', toData.count })
						elseif toOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', toInventory.id, { fromData, 'ui_added', fromData.count })
							TriggerClientEvent('ox_inventory:itemNotify', toInventory.id, { toData, 'ui_removed', toData.count })
						end

						fromInventory.weight = fromWeight
						toInventory.weight = toWeight
						toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot) --[[@as table]]

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s chuyển từ "%s" tới "%s" từ %sx %s | from metadata: %s | to metadata: %s'):format(fromData.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id, toData.count, toData.name, fromData.metadata and json.encode(fromData.metadata) or 'nil', toData.metadata and json.encode(toData.metadata) or 'nil'))
						end
					else return false, 'cannot_carry' end
				else
					if not TriggerEventHooks('swapItems', hookPayload) then return end

					toData, fromData = Inventory.SwapSlots(fromInventory, toInventory, data.fromSlot, data.toSlot)
				end

			elseif toData and toData.name == fromData.name and table.matches(toData.metadata, fromData.metadata) then
				-- Stack items
				local originalCount = data.count
				
				-- Áp dụng phí 2% khi stack tiền giữa 2 người chơi
				if not sameInventory and fromData.name == 'money' and data.count > 10 then
					if (fromOtherPlayer and toInventory == playerInventory) or (toOtherPlayer and fromInventory == playerInventory) then
						local receivedAmount = math.floor(data.count * 0.98)
						local fee = data.count - receivedAmount
						
						-- Cập nhật số lượng thực tế nhận được
						toData.count += receivedAmount
						fromData.count -= data.count
						
						-- Thông báo cho người nhận
						local recipientId = toOtherPlayer and toInventory.id or playerInventory.id
						TriggerClientEvent('ox_lib:notify', recipientId, { 
							type = 'info', 
							description = ('Đã nhận $%s (phí 2%% = $%s)'):format(receivedAmount, fee)
						})
					else
						toData.count += data.count
						fromData.count -= data.count
					end
				else
					toData.count += data.count
					fromData.count -= data.count
				end
				
				local toSlotWeight = Inventory.SlotWeight(Items(toData.name), toData)
				local totalWeight = toInventory.weight - toData.weight + toSlotWeight

				if fromInventory.type == 'container' or sameInventory or totalWeight <= toInventory.maxWeight then
					hookPayload.action = 'stack'

					if not TriggerEventHooks('swapItems', hookPayload) then
						toData.count -= data.count
						fromData.count += data.count
						return
					end

					local fromSlotWeight = Inventory.SlotWeight(Items(fromData.name), fromData)
					toData.weight = toSlotWeight

					if not sameInventory then
						fromInventory.weight = fromInventory.weight - fromData.weight + fromSlotWeight
						toInventory.weight = totalWeight

						if container then
							Inventory.ContainerWeight(containerItem, toInventory.type == 'container' and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', data.count })
						elseif toOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', toInventory.id, { toData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s chuyển từ "%s" tới "%s" | metadata: %s'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id, fromData.metadata and json.encode(fromData.metadata) or 'nil'))
						end
					end

					fromData.weight = fromSlotWeight
				else
					toData.count -= data.count
					fromData.count += data.count
					return false, 'cannot_carry'
				end
			elseif data.count <= fromData.count then
				-- Move item to an empty slot
				toData = table.clone(fromData)
				toData.count = data.count
				toData.slot = data.toSlot
				toData.weight = Inventory.SlotWeight(Items(toData.name), toData)

				-- Kiểm tra limit khi move vào inventory khác
				if not sameInventory then
					local moveItem = Items(fromData.name)
					if moveItem and moveItem.limit then
						local itemSlotCount = 0
						for _, slotData in pairs(toInventory.items) do
							if slotData and slotData.name == moveItem.name then
								itemSlotCount = itemSlotCount + 1
							end
						end
						if itemSlotCount >= moveItem.limit then
							return false, 'cannot_carry_limit'
						end
					end
				end

				if fromInventory.type == 'container' or sameInventory or (toInventory.weight + toData.weight <= toInventory.maxWeight) then
					hookPayload.action = 'move'

					if not TriggerEventHooks('swapItems', hookPayload) then return end

					if not sameInventory then
						local toContainer = toInventory.type == 'container'

						if container then
							if toContainer and containerItem then
								local whitelist = Items.containers[containerItem.name]?.whitelist
								local blacklist = Items.containers[containerItem.name]?.blacklist

								if (whitelist and not whitelist[fromData.name]) or (blacklist and blacklist[fromData.name]) then
									return
								end
							end
						end

						-- Áp dụng phí 2% khi chuyển tiền giữa 2 người chơi
						if fromOtherPlayer and toInventory == playerInventory and fromData.name == 'money' and data.count > 10 then
							local receivedAmount = math.floor(data.count * 0.98)
							local fee = data.count - receivedAmount
							toData.count = receivedAmount
							toData.weight = Inventory.SlotWeight(Items(toData.name), toData)
							
							-- Thông báo cho người nhận
							TriggerClientEvent('ox_lib:notify', toInventory.id, { 
								type = 'info', 
								description = ('Đã nhận $%s (phí 2%% = $%s)'):format(receivedAmount, fee)
							})
						elseif toOtherPlayer and fromInventory == playerInventory and fromData.name == 'money' and data.count > 10 then
							local receivedAmount = math.floor(data.count * 0.98)
							local fee = data.count - receivedAmount
							toData.count = receivedAmount
							toData.weight = Inventory.SlotWeight(Items(toData.name), toData)
							
							-- Thông báo cho người nhận
							TriggerClientEvent('ox_lib:notify', toInventory.id, { 
								type = 'info', 
								description = ('Đã nhận $%s (phí 2%% = $%s)'):format(receivedAmount, fee)
							})
						end

						fromInventory.weight -= toData.weight
						toInventory.weight += toData.weight

						if container then
							Inventory.ContainerWeight(containerItem, toContainer and toInventory.weight or fromInventory.weight, playerInventory)
						end

						if fromOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', fromInventory.id, { fromData, 'ui_removed', data.count })
						elseif toOtherPlayer then
							TriggerClientEvent('ox_inventory:itemNotify', toInventory.id, { fromData, 'ui_added', data.count })
						end

						if server.loglevel > 0 then
							lib.logger(playerInventory.owner, 'swapSlots', ('%sx %s chuyển từ "%s" tới "%s" | metadata: %s'):format(data.count, fromData.name, fromInventory.owner and fromInventory.label or fromInventory.id, toInventory.owner and toInventory.label or toInventory.id, fromData.metadata and json.encode(fromData.metadata) or 'nil'))
						end
					end
					fromData.count -= data.count
					fromData.weight = Inventory.SlotWeight(Items(fromData.name), fromData)

					if fromData.count > 0 then
						toData.metadata = table.clone(toData.metadata)
					end
				else return false, 'cannot_carry_other' end
			end

			if fromData and fromData.count < 1 then fromData = nil end

			---@type updateSlot[]
			local items = {}

			if fromInventory.player and not fromOtherPlayer then
				if toInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			if toInventory.player and not toOtherPlayer then
				if fromInventory.type == 'container' and containerItem then
					items[#items + 1] = {
						item = containerItem,
						inventory = playerInventory.id
					}
				end
			end

			fromInventory.items[data.fromSlot] = fromData
			toInventory.items[data.toSlot] = toData

			if fromInventory.changed ~= nil then fromInventory.changed = true end
			if toInventory.changed ~= nil then toInventory.changed = true end

            CreateThread(function()
                if sameInventory then
                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = fromInventory.id
                        },
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true)
                else
                    toInventory:syncSlotsWithClients({
                        {
                            item = toInventory.items[data.toSlot] or { slot = data.toSlot },
                            inventory = toInventory.id
                        }
                    }, true)

                    fromInventory:syncSlotsWithClients({
                        {
                            item = fromInventory.items[data.fromSlot] or { slot = data.fromSlot },
                            inventory = fromInventory.id
                        }
                    }, true)
                end
            end)

			local resp

			if next(items) then
				resp = { weight = playerInventory.weight, items = items }
			end

			if server.syncInventory then
				if fromInventory.player then
					server.syncInventory(fromInventory)
				end

				if toInventory.player and not sameInventory then
					server.syncInventory(toInventory)
				end
			end

			local weaponSlot

			if toInventory.weapon == data.toSlot then
				if not sameInventory then
					toInventory.weapon = nil
					TriggerClientEvent('ox_inventory:disarm', toInventory.id)
				else
					weaponSlot = data.fromSlot
					toInventory.weapon = weaponSlot
				end
			end

			if fromInventory.weapon == data.fromSlot then
				if not sameInventory then
					fromInventory.weapon = nil
					TriggerClientEvent('ox_inventory:disarm', fromInventory.id)
				elseif not weaponSlot then
					weaponSlot = data.toSlot
					fromInventory.weapon = weaponSlot
				end
			end

			return containerItem and containerItem.weight or true, resp, weaponSlot
		end
	end
end)

function Inventory.Confiscate(source)
	local inv = Inventory(source)

	if inv?.player then
		db.saveStash(inv.owner, inv.owner, json.encode(minimal(inv)))
		table.wipe(inv.items)
		inv.weight = 0
		inv.changed = true

		TriggerClientEvent('ox_inventory:inventoryConfiscated', inv.id)

		if server.syncInventory then server.syncInventory(inv) end
	end
end
exports('ConfiscateInventory', Inventory.Confiscate)

function Inventory.Return(source)
	local inv = Inventory(source)

	if not inv?.player then return end

	local items = MySQL.scalar.await('SELECT data FROM ox_inventory WHERE name = ?', { inv.owner })

    if not items then return end

	MySQL.update.await('DELETE FROM ox_inventory WHERE name = ?', { inv.owner })

    items = json.decode(items)
    local inventory, totalWeight = {}, 0

    if table.type(items) == 'array' then
        for i = 1, #items do
            local data = items[i]
            if type(data) == 'number' then break end

            local item = Items(data.name)

            if item then
                local weight = Inventory.SlotWeight(item, data)
                totalWeight = totalWeight + weight
                inventory[data.slot] = {name = data.name, label = item.label, weight = weight, slot = data.slot, count = data.count, description = item.description, metadata = data.metadata, stack = item.stack, close = item.close, do_hiem = item.do_hiem}
            end
        end
    end

    inv.changed = true
    inv.weight = totalWeight
    inv.items = inventory

    TriggerClientEvent('ox_inventory:inventoryReturned', source, { inventory, totalWeight })

    if server.syncInventory then server.syncInventory(inv) end
end

exports('ReturnInventory', Inventory.Return)

---@param inv inventory
---@param keep? string | string[] an item or list of items to ignore while clearing items
function Inventory.Clear(inv, keep)
	inv = Inventory(inv) --[[@as OxInventory]]

	if not inv or not next(inv.items) then return end

	local updateSlots = {}
	local newWeight = 0
	local inc = 0

	if keep then
		local keptItems = {}
		local keepType = type(keep)

		if keepType == 'string' then
			for slot, v in pairs(inv.items) do
				if v.name == keep then
					keptItems[v.slot] = v
					newWeight += v.weight
				elseif updateSlots then
					inc += 1
					updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
				end
			end
		elseif keepType == 'table' and table.type(keep) == 'array' then
			for slot, v in pairs(inv.items) do
				for i = 1, #keep do
					if v.name == keep[i] then
						keptItems[v.slot] = v
						newWeight += v.weight
						goto foundItem
					end
				end

				if updateSlots then
					inc += 1
					updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
				end

				::foundItem::
			end
		end

		table.wipe(inv.items)
		inv.items = keptItems
	else
		if updateSlots then
			for slot in pairs(inv.items) do
				inc += 1
				updateSlots[inc] = { item = { slot = slot }, inventory = inv.id }
			end
		end

		table.wipe(inv.items)
	end

	inv.weight = newWeight
	inv.changed = true

	inv:syncSlotsWithClients(updateSlots, true)

	if not inv.player then
		if inv.open then
			local playerInv = Inventory(inv.open)

			if not playerInv then return end

			playerInv:closeInventory()
		end

		inv:openInventory(inv)

		return
	end

	if server.syncInventory then server.syncInventory(inv) end

	inv.weapon = nil
end

exports('ClearInventory', Inventory.Clear)

---@param inv inventory
---@return integer?
function Inventory.GetEmptySlot(inv)
	local inventory = Inventory(inv)

	if not inventory then return end

	local items = inventory.items

	for i = 1, inventory.slots do
		if not items[i] then
			return i
		end
	end
end

exports('GetEmptySlot', Inventory.GetEmptySlot)

---@param inv inventory
---@param itemName string
---@param metadata any
function Inventory.GetSlotForItem(inv, itemName, metadata)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local items = inventory.items
	local emptySlot
	
	-- Kiểm tra xem item có phải là clothing không
	local clothingSlot = GetClothingSlot(itemName)
	
	-- Nếu là clothing item và inventory là player inventory
	if clothingSlot and inventory.type == 'player' then
		-- Kiểm tra slot đã định sẵn có trống không
		if not items[clothingSlot] then
			return clothingSlot
		end
		-- Nếu slot đúng đã bị chiếm, tìm slot trống < 6 hoặc > 21
		for i = 1, inventory.slots do
			if not items[i] and (i < 6 or i > 21) then
				return i
			end
		end
		-- Nếu không tìm được slot, return nil
		return nil
	end

	-- Logic cũ cho non-clothing items
	for i = 1, inventory.slots do
		local slotData = items[i]

		if item.stack and slotData and slotData.name == item.name and table.matches(slotData.metadata, metadata) then
			return i
		elseif not item.stack and not slotData and not emptySlot then
			-- Bỏ qua các slot từ 6 đến 21 nếu không phải clothing item
			if i < 6 or i > 21 then
				emptySlot = i
			end
		end
	end

	return emptySlot
end

exports('GetSlotForItem', Inventory.GetSlotForItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return SlotWithItem?
function Inventory.GetSlotWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                return slotData
            end
		end
	end
end

exports('GetSlotWithItem', Inventory.GetSlotWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number?
function Inventory.GetSlotIdWithItem(inv, itemName, metadata, strict)
	return Inventory.GetSlotWithItem(inv, itemName, metadata, strict)?.slot
end

exports('GetSlotIdWithItem', Inventory.GetSlotIdWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return SlotWithItem[]?
function Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return end

	metadata = assertMetadata(metadata)
	local response = {}
	local n = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
            if not Items.UpdateDurability(inventory, slotData, item, nil, os.time()) then
                n += 1
                response[n] = slotData
            end
		end
	end

	return response
end

exports('GetSlotsWithItem', Inventory.GetSlotsWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number[]?
function Inventory.GetSlotIdsWithItem(inv, itemName, metadata, strict)
	local items = Inventory.GetSlotsWithItem(inv, itemName, metadata, strict)

	if items then
		---@cast items +number[]
		for i = 1, #items do
			items[i] = items[i].slot
		end

		return items
	end
end

exports('GetSlotIdsWithItem', Inventory.GetSlotIdsWithItem)

---@param inv inventory
---@param itemName string
---@param metadata? any
---@param strict? boolean Strictly match metadata properties, otherwise use partial matching.
---@return number
function Inventory.GetItemCount(inv, itemName, metadata, strict)
	local inventory = Inventory(inv)
	local item = Items(itemName) --[[@as OxServerItem?]]

	if not inventory or not item then return 0 end

	metadata = assertMetadata(metadata)
	local count = 0
	local tablematch = strict and table.matches or table.contains

	for _, slotData in pairs(inventory.items) do
		if slotData and slotData.name == item.name and (not metadata or tablematch(slotData.metadata, metadata)) then
			count += slotData.count
		end
	end

	return count
end

exports('GetItemCount', Inventory.GetItemCount)

---@alias InventorySaveData { [1]: MinimalInventorySlot, [2]: string | number, [3]: string | number | nil }

---@param inv OxInventory
---@param buffer table
---@param time integer
---@return integer?
---@return InventorySaveData?
local function prepareInventorySave(inv, buffer, time)
    local shouldSave = not inv.datastore and inv.changed
    local n = 0

    for k, v in pairs(inv.items) do
        if not Items.UpdateDurability(inv, v, Items(v.name), nil, time) and shouldSave then
            n += 1
            buffer[n] = {
                name = v.name,
                count = v.count,
                slot = k,
                metadata = next(v.metadata) and v.metadata or nil
            }
        end
	end

    if not shouldSave then return end

    local data = next(buffer) and json.encode(buffer) or nil
    inv.changed = false
    table.wipe(buffer)

    if inv.player then
        if shared.framework == 'esx' then return end

        return 1, { data, inv.owner }
    end

    if inv.type == 'trunk' then
        return 2, { data, inv.dbId }
    end

    if inv.type == 'glovebox' then
        return 3, { data, inv.dbId }
    end

    return 4, { data, inv.owner and tostring(inv.owner) or '', inv.dbId }
end

local isSaving = false
local inventoryClearTime = GetConvarInt('inventory:cleartime', 5) * 60

local function saveInventories(clearInventories)
	if isSaving then return end

	local time = os.time()
	local parameters = { {}, {}, {}, {} }
	local total = { 0, 0, 0, 0, 0 }
    local buffer = {}

	for _, inv in pairs(Inventories) do
        local index, data = prepareInventorySave(inv, buffer, time)

        if index and data then
            total[5] += 1

            if index == 4 and server.bulkstashsave then
                for i = 1, 3 do
					total[index] += 1
                    parameters[index][total[index]] = data[i]
                end
            else
				total[index] += 1
                parameters[index][total[index]] = data
            end
        end
	end

    if total[5] > 0 then
        isSaving = true
        local ok, err = pcall(db.saveInventories, parameters[1], parameters[2], parameters[3], parameters[4], total)
        isSaving = false

        if not ok and err then return lib.print.error(err) end
    end

    if not clearInventories then return end

    for _, inv in pairs(Inventories) do
        if not inv.open and not inv.player then
            -- clear inventory from memory if unused for x minutes, or on entity/netid mismatch
            if inv.type == 'glovebox' or inv.type == 'trunk' then
                if NetworkGetEntityFromNetworkId(inv.netid) ~= inv.entityId then
                    Inventory.Remove(inv)
                end
            elseif time - inv.time >= inventoryClearTime then
                Inventory.Remove(inv)
            end
        end
    end
end

lib.cron.new('*/5 * * * *', function()
    saveInventories(true)
end)

function Inventory.SaveInventories(lock, clearInventories)
	Inventory.Lock = lock or nil

	Inventory.CloseAll()
    saveInventories(clearInventories)
end

AddEventHandler('playerDropped', function()
	server.playerDropped(source)

	if GetNumPlayerIndices() == 0 then
		Inventory.SaveInventories(false, true)
	end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
	Inventory.SaveInventories(true, false)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining ~= 60 then return end

	Inventory.SaveInventories(true, true)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == shared.resource then
		Inventory.SaveInventories(true, false)
	end
end)

RegisterServerEvent('ox_inventory:closeInventory', function()
	local inventory = Inventories[source]

	if inventory?.open then
		local secondary = Inventories[inventory.open]

		if secondary then
			secondary:closeInventory()
		end

		inventory:closeInventory(true)
	end
end)

local function giveItem(playerId, slot, target, count)
	local fromInventory = Inventory(playerId)
	local toInventory = Inventory(target)

	if not fromInventory or not toInventory then return end

	if type(count) ~= 'number' or count <= 0 then count = 1 end

	if toInventory.player then
		local data = fromInventory.items[slot]

		if not data then return end

		-- Chặn đưa tiền qua nút Give, yêu cầu dùng target
		if data.name == 'money' then
			TriggerClientEvent('ox_lib:notify', playerId, { 
				type = 'error', 
				description = 'Vui lòng sử dụng target để đưa tiền mặt'
			})
			return { 'cannot_give', count, data.label }
		end

        local targetState = Player(target).state

        if targetState.invBusy then
            return { 'cannot_give', count, data.label }
        end

		local item = Items(data.name)

		-- Chặn đưa item có cangive = true
		if item and item.cangive == true then
			TriggerClientEvent('ox_lib:notify', playerId, { 
				type = 'error', 
				description = 'Không thể đưa vật phẩm này'
			})
			return { 'cannot_give', count, data.label }
		end

		if not item or data.count < count or not Inventory.CanCarryItem(toInventory, item, count, data.metadata) or #(GetEntityCoords(fromInventory.player.ped) - GetEntityCoords(toInventory.player.ped)) > 15 then
			return { 'cannot_give', count, data.label }
		end

		local toSlot = Inventory.GetSlotForItem(toInventory, data.name, data.metadata)
		local fromRef = ('%s:%s'):format(fromInventory.id, slot)
		local toRef = ('%s:%s'):format(toInventory.id, toSlot)

		if activeSlots[fromRef] or activeSlots[toRef] then
			return { 'cannot_give', count, data.label }
		end

		activeSlots[fromRef] = true
		activeSlots[toRef] = true

		local _ <close> = defer(function()
			activeSlots[fromRef] = nil
			activeSlots[toRef] = nil
		end)

		if TriggerEventHooks('swapItems', {
			source = fromInventory.id,
			fromInventory = fromInventory.id,
			fromType = fromInventory.type,
			toInventory = toInventory.id,
			toType = toInventory.type,
			count = count,
			action = 'give',
			fromSlot = data,
		}) then
			---@todo manually call swapItems or something?
			local actualCount = count
			
			-- Áp dụng phí 2% khi đưa tiền giữa 2 người chơi
			if data.name == 'money' and count > 10 then
				actualCount = math.floor(count * 0.98)
				local fee = count - actualCount
				
				-- Thông báo cho người nhận
				TriggerClientEvent('ox_lib:notify', toInventory.id, { 
					type = 'info', 
					description = ('Đã nhận $%s (phí 2%% = $%s)'):format(actualCount, fee)
				})
			end
			
			if Inventory.AddItem(toInventory, item, actualCount, data.metadata, toSlot) then
				if Inventory.RemoveItem(fromInventory, item, count, data.metadata, slot) then
					if server.loglevel > 0 then
						lib.logger(fromInventory.owner, 'giveItem', ('"%s" đưa %sx %s tới "%s" | metadata: %s'):format(fromInventory.label, count, data.name, toInventory.label, data.metadata and json.encode(data.metadata) or 'nil'))
					end

					return
				else
					Inventory.RemoveItem(toInventory, item, actualCount, data.metadata, toSlot)
				end
			end
		end

		return { 'cannot_give', count, data.label }
	end
end

lib.callback.register('ox_inventory:giveItem', giveItem)
RegisterServerEvent('ox_inventory:giveItem', function(...) giveItem(source, ...) end)

local function updateWeapon(source, action, value, slot, specialAmmo)
	local inventory = Inventory(source)

	if not inventory then return end

	if not action then
		inventory.weapon = nil
		return
	end

	local type = type(value)

	if type == 'table' and action == 'component' then
		local item = inventory.items[value.slot]

		if item then
			if item.metadata.components then
				for k, v in pairs(item.metadata.components) do
					if v == value.component then
						if not Inventory.AddItem(inventory, value.component, 1) then return end

						item.metadata.components[k] = false
						inventory:syncSlotsWithPlayer({
							{ item = item }
						}, inventory.weight)

			            if server.syncInventory then server.syncInventory(inventory) end

						return true
					end
				end
			end
		end
	else
		if not slot then slot = inventory.weapon end
		local weapon = inventory.items[slot]

		if weapon and weapon.metadata then
			local item = Items(weapon.name)

			if not item.weapon then
				inventory.weapon = nil
				return
			end

			if action == 'load' and weapon.metadata.durability > 0 then
				local ammo = Items(weapon.name).ammoname
				local diff = value - (weapon.metadata.ammo or 0)

				if diff <= 0 then return end

				local clip = weapon.metadata.clip or 0
				if clip >= diff then
					-- Clip-based system (hopdan/metadata.clip)
					weapon.metadata.clip = clip - diff
				elseif not Inventory.RemoveItem(inventory, ammo, diff, specialAmmo) then
					return
				end

				weapon.metadata.ammo = value
				weapon.metadata.specialAmmo = specialAmmo
				weapon.weight = Inventory.SlotWeight(item, weapon)
			elseif action == 'throw' then
				if not Inventory.RemoveItem(inventory, weapon.name, 1, weapon.metadata, weapon.slot) then return end
			elseif action == 'component' then
				if type == 'number' then
					if not Inventory.AddItem(inventory, weapon.metadata.components[value], 1) then return false end

					weapon.metadata.components[value] = false
					weapon.weight = Inventory.SlotWeight(item, weapon)
				elseif type == 'string' then
					local component = inventory.items[tonumber(value)]

					if not Inventory.RemoveItem(inventory, component.name, 1) then return false end

					table.insert(weapon.metadata.components, component.name)
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'ammo' then
				if item.hash == `WEAPON_FIREEXTINGUISHER` or item.hash == `WEAPON_PETROLCAN` or item.hash == `WEAPON_HAZARDCAN` or item.hash == `WEAPON_FERTILIZERCAN` then
					weapon.metadata.durability = math.floor(value)
					weapon.metadata.ammo = weapon.metadata.durability
				elseif value < weapon.metadata.ammo then
					local durability = Items(weapon.name).durability * math.abs((weapon.metadata.ammo or 0.1) - value)
					weapon.metadata.ammo = value
					weapon.metadata.durability = weapon.metadata.durability - durability
					weapon.weight = Inventory.SlotWeight(item, weapon)
				end
			elseif action == 'melee' and value > 0 then
				weapon.metadata.durability = weapon.metadata.durability - ((Items(weapon.name).durability or 0.05) * value)
			end

            if (weapon.metadata.durability or 0) < 0 then
                weapon.metadata.durability = 0
            end

            if item.hash == `WEAPON_PETROLCAN` then
                weapon.weight = Inventory.SlotWeight(item, weapon)
            end

			if action ~= 'throw' then
				inventory:syncSlotsWithPlayer({
					{ item = weapon }
				}, inventory.weight)
			end

			if server.syncInventory then server.syncInventory(inventory) end

			return true
		end
	end
end

lib.callback.register('ox_inventory:updateWeapon', updateWeapon)

RegisterNetEvent('ox_inventory:updateWeapon', function(action, value, slot, specialAmmo)
	updateWeapon(source, action, value, slot, specialAmmo)
end)

lib.callback.register('ox_inventory:removeAmmoFromWeapon', function(source, slot)
	local inventory = Inventory(source)

	if not inventory then return end

	local slotData = inventory.items[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo < 1 then return end

	local item = Items(slotData.name)

	if not item or not item.ammoname then return end
	local specialAmmo = slotData.metadata.specialAmmo and { type = slotData.metadata.specialAmmo } or nil

	if Inventory.AddItem(inventory, item.ammoname, slotData.metadata.ammo, specialAmmo) then
		slotData.metadata.ammo = 0
		slotData.weight = Inventory.SlotWeight(item, slotData)

		inventory:syncSlotsWithPlayer({
			{ item = slotData }
		}, inventory.weight)

		if server.syncInventory then server.syncInventory(inventory) end

		return true
	end
end)

lib.callback.register('ox_inventory:detachComponent', function(source, weaponSlot, componentSlot, componentName, targetSlot)
	local inventory = Inventory(source)

	if not inventory then return false end

	local weapon = inventory.items[weaponSlot]

	if not weapon or not weapon.metadata or not weapon.metadata.components then return false end

	-- Get component name from the slot
	local component = weapon.metadata.components[componentSlot]
	
	if not component or component ~= componentName then return false end

	-- Check if player can carry the component
	local componentItem = Items(componentName)
	if not componentItem then return false end

	if not Inventory.CanCarryItem(inventory, componentItem, 1) then
		return false
	end

	-- Create metadata with image for the component item
	local componentMetadata = {
		image = componentItem.client and componentItem.client.image or componentName
	}

	-- Add component to player inventory
	if Inventory.AddItem(inventory, componentName, 1, componentMetadata, targetSlot) then
		-- Remove component from weapon (set to false to preserve slot index)
		weapon.metadata.components[componentSlot] = false
		weapon.weight = Inventory.SlotWeight(Items(weapon.name), weapon)
		inventory.changed = true

		-- Sync with client
		inventory:syncSlotsWithPlayer({
			{ item = weapon }
		}, inventory.weight)

		if server.syncInventory then server.syncInventory(inventory) end

		-- Update weapon components on client
		TriggerClientEvent('ox_inventory:updateWeaponComponent', source, 'removed', componentName, weapon.name, weaponSlot)

		return true
	end

	return false
end)

lib.callback.register('ox_inventory:attachComponent', function(source, weaponSlot, componentSlot, componentName, targetSlot)
	local inventory = Inventory(source)

	if not inventory then 
		--print("[ATTACH] No inventory found")
		return false 
	end

	local weapon = inventory.items[weaponSlot]
	local component = inventory.items[componentSlot]

	if not weapon or not component then 
		--print("[ATTACH] Weapon or component not found. Weapon:", weapon ~= nil, "Component:", component ~= nil)
		return false 
	end
	if component.name ~= componentName then 
		--print("[ATTACH] Component name mismatch:", component.name, "vs", componentName)
		return false 
	end

	--print("[ATTACH] Starting attach process - weaponSlot:", weaponSlot, "componentSlot:", componentSlot, "componentName:", componentName, "targetSlot:", targetSlot)

	-- Check if component is compatible with weapon (validation already done on client)
	local componentData = Items(componentName)
	
	if not componentData then
		--print("[ATTACH] Component data not found:", componentName)
		return false
	end

	-- Initialize components table if not exists
	if not weapon.metadata then weapon.metadata = {} end
	if not weapon.metadata.components then weapon.metadata.components = {} end

	-- Check if component is already attached (skip false placeholders)
	for _, comp in ipairs(weapon.metadata.components) do
		if comp and comp ~= false and comp == componentName then
			--print("[ATTACH] Component already attached:", componentName)
			return false
		end
	end

	-- Check skin uniqueness: only 1 skin allowed per weapon
	if componentData.type == 'skin' then
		for _, comp in ipairs(weapon.metadata.components) do
			if comp and comp ~= false then
				local existingData = Items(comp)
				if existingData and existingData.type == 'skin' then
					--print("[ATTACH] Skin already attached:", comp)
					return false
				end
			end
		end
	end

	-- Remove component from player inventory first
	if not Inventory.RemoveItem(inventory, componentName, 1, nil, componentSlot) then
		--print("[ATTACH] Failed to remove component from player inventory")
		return false
	end

	--print("[ATTACH] Component removed from player inventory successfully")

	-- Check if target slot already has a component (not false placeholder)
	local existingComponent = nil
	if targetSlot and targetSlot > 0 and weapon.metadata.components[targetSlot] and weapon.metadata.components[targetSlot] ~= false then
		existingComponent = weapon.metadata.components[targetSlot]
		--print("[ATTACH] Target slot has existing component:", existingComponent)
	end

	-- If target slot has existing component, swap it
	if existingComponent then
		----print("[ATTACH] Swapping component at slot", targetSlot)
		-- Replace component at target slot
		weapon.metadata.components[targetSlot] = componentName
		
		-- Get component item data and add swapped component back to player
		local componentData = Items(existingComponent)
		if componentData then
			-- Add image metadata for removed component
			local metadata = { image = existingComponent }
			Inventory.AddItem(inventory, existingComponent, 1, metadata, componentSlot)
			--print("[ATTACH] Swapped component added back to player inventory")
		end
		
		-- Update weapon on client - swap components
		TriggerClientEvent('ox_inventory:updateWeaponComponent', source, 'removed', existingComponent, weapon.name, weaponSlot)
		TriggerClientEvent('ox_inventory:updateWeaponComponent', source, 'added', componentName, weapon.name, weaponSlot)
	else
		--print("[ATTACH] Adding component to slot", targetSlot or "end")
		-- Add component to weapon at specific slot (expand array if needed)
		if targetSlot and targetSlot > 0 then
			-- Fill empty slots if targetSlot is beyond current array length
			while #weapon.metadata.components < targetSlot - 1 do
				table.insert(weapon.metadata.components, false) -- Use false as placeholder
			end
			
			-- Set component at target slot
			if #weapon.metadata.components >= targetSlot then
				weapon.metadata.components[targetSlot] = componentName
				--print("[ATTACH] Set component at existing slot index", targetSlot)
			else
				table.insert(weapon.metadata.components, componentName)
				--print("[ATTACH] Inserted component at end, slot", #weapon.metadata.components)
			end
		else
			-- Add to end
			table.insert(weapon.metadata.components, componentName)
			--print("[ATTACH] Added component to end")
		end
		
		-- Update weapon component on client
		TriggerClientEvent('ox_inventory:updateWeaponComponent', source, 'added', componentName, weapon.name, weaponSlot)
	end
	
	weapon.weight = Inventory.SlotWeight(Items(weapon.name), weapon)
	inventory.changed = true

	-- Sync with client
	inventory:syncSlotsWithPlayer({
		{ item = weapon }
	}, inventory.weight)

	if server.syncInventory then server.syncInventory(inventory) end

	--print("[ATTACH] Attach completed successfully")
	return true
end)

lib.callback.register('ox_inventory:swapAttachmentComponents', function(source, weaponSlot, fromSlot, toSlot)
	local inventory = Inventories[source]
	if not inventory then return false end

	local weapon = inventory.items[weaponSlot]
	if not weapon or not weapon.metadata or not weapon.metadata.components then
		return false
	end

	-- Get components array
	local components = weapon.metadata.components
	
	-- Both slots must be valid
	if fromSlot < 1 or toSlot < 1 or fromSlot > #components or toSlot > #components then
		return false
	end

	-- Swap components
	components[fromSlot], components[toSlot] = components[toSlot], components[fromSlot]
	
	-- Update weapon weight
	weapon.weight = Inventory.SlotWeight(Items(weapon.name), weapon)
	inventory.changed = true

	-- Sync with client
	inventory:syncSlotsWithPlayer({
		{ item = weapon }
	}, inventory.weight)

	if server.syncInventory then server.syncInventory(inventory) end

	return true
end)

local function checkStashProperties(properties)
	local name = properties.name
	local slots = properties.slots
	local maxWeight = properties.maxWeight
	local coords = properties.coords

	if type(name) ~= 'string' then
		error(('received %s for stash name (expected string)'):format(type(name)))
	end

	if type(slots) ~= 'number' then
		error(('received %s for stash slots (expected number)'):format(type(slots)))
	end

	if type(maxWeight) ~= 'number' then
		error(('received %s for stash maxWeight (expected number)'):format(type(maxWeight)))
	end

	if coords then
		local typeof = type(coords)

		if typeof ~= 'vector3' then
			if typeof == 'table' and table.type(coords) ~= 'array' then
				coords = vec3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
			else
				if table.type(coords) == 'array' then
					for i = 1, #coords do
						coords[i] = vec3(coords[i].x, coords[i].y, coords[i].z)
					end
				else
					error(('received %s for stash coords (expected vector3 or array of vector3)'):format(typeof))
				end
			end
		end
	end

	return name, slots, maxWeight, coords
end

---@param name string stash identifier when loading from the database
---@param label string display name when inventory is open
---@param slots number
---@param maxWeight number
---@param owner? string|number|boolean
---@param groups? table<string, number>
---@param coords? vector3|table<vector3>
--- For simple integration with other resources that want to create valid stashes.
--- This needs to be triggered before a player can open a stash.
--- ```
--- Owner sets the stash permissions.
--- string: can only access the stash linked to the owner (usually player identifier)
--- true: each player has a unique stash, but can request other player's stashes
--- nil: always shared
---
--- groups: { ['police'] = 0 }
--- ```
local function registerStash(name, label, slots, maxWeight, owner, groups, coords)
	name, slots, maxWeight, coords = checkStashProperties({
		name = name,
		slots = slots,
		maxWeight = maxWeight,
		coords = coords,
	})

	local curStash = RegisteredStashes[name]

	if curStash then
		---@todo creating proper stash classes with inheritence would simplify updating data
		---i.e. all stashes with the same type share groups, maxweight, slots, dbid, etc.
		---only label, owner, weight, coords, and items really need to vary
		for _, stash in pairs(Inventories) do
			if stash.type == 'stash' and stash.dbId == name then
				stash.label = label or stash.label
				stash.owner = (owner and owner ~= true) and stash.owner or owner
				stash.slots = slots or stash.slots
				stash.maxWeight = maxWeight or stash.maxWeight
				stash.groups = groups or stash.groups
				stash.coords = coords or stash.coords
			end
		end
	end

	RegisteredStashes[name] = {
		name = name,
		label = label,
		owner = owner,
		slots = slots,
		maxWeight = maxWeight,
		groups = groups,
		coords = coords
	}
end

exports('RegisterStash', registerStash)

---@param properties TemporaryStashProperties
function Inventory.CreateTemporaryStash(properties)
	properties.name = generateInvId('temp')

	local name, slots, maxWeight, coords = checkStashProperties(properties)
	local inventory = Inventory.Create(name, properties.label, 'temp', slots, 0, maxWeight, properties.owner, {}, properties.groups)

	if not inventory then return end

	inventory.items, inventory.weight = generateItems(inventory, 'drop', properties.items)
	inventory.coords = coords

	return inventory.id
end

exports('CreateTemporaryStash', Inventory.CreateTemporaryStash)

function Inventory.InspectInventory(playerId, invId)
	local inventory = invId ~= playerId and Inventory(invId)
	local playerInventory = Inventory(playerId)

	if playerInventory and inventory then
		playerInventory:openInventory(inventory)
		TriggerClientEvent('ox_inventory:viewInventory', playerId, playerInventory, inventory)
	end
end

exports('InspectInventory', Inventory.InspectInventory)


--add dan va phu kien server chiem dong
RegisterServerEvent('ox_inventory:buyComponentGunshopServer', function(action, value, slot, componentName)
	local inventory = Inventories[source]
	local weapon = inventory.items[slot]
	local item = Items(weapon.name)
	if action == 'addComponent' then
		table.insert(weapon.metadata.components, componentName)
		weapon.weight = Inventory.SlotWeight(item, weapon)
	elseif action == 'removeComponent' then
		table.remove(weapon.metadata.components, value)
		weapon.weight = Inventory.SlotWeight(item, weapon)
	elseif action =='addTint' then
		weapon.metadata.tint = value
	elseif action =='addAmmo' then
		weapon.metadata.ammo = weapon.metadata.ammo + value
	elseif action =='addAmmo2' then
		weapon.metadata.ammo = 9999
	end
end)


return Inventory
