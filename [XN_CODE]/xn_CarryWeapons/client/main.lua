
local PlayerSlots = {
	[1] = { -- Bigger weapons such as bats, crowbars, Assaultrifles, and also good place for wet weed.
		[1] = { bone = 24817, x = 0.04, y = -0.15, z = 0.12, xr = 0.0, yr = 0.0, zr = 0.0, isBusy = false },
		[2] = { bone = 24817, x = 0.04, y = -0.17, z = 0.02, xr = 0.0, yr = 0.0, zr = 0.0, isBusy = false },
		[3] = { bone = 24817, x = 0.04, y = -0.15, z = -0.12, xr = 0.0, yr = 0.0, zr = 0.0, isBusy = false },
	},

	[2] = { -- Use this for katana knives etc. stuff that goes sideways on the players body
		[1] = { bone = 24817, x = -0.13, y = -0.16, z = -0.14, xr = 5.0, yr = 62.0, zr = 0.0, isBusy = false },
		[2] = { bone = 24817, x = -0.13, y = -0.15, z = 0.10, xr = 5.0, yr = 124.0, zr = 0.0, isBusy = false },
	},

	[3] = { -- Contraband like Drugs and shit
		[1] = { bone = 24817, x = -0.28, y = -0.14, z = 0.15, xr = 0.0, yr = 92.0, zr = -13.0 },
		[2] = { bone = 24817, x = -0.27, y = -0.14, z = 0.15, xr = 0.0, yr = 92.0, zr = 13.0 },
	},

	[4] = { -- I use this for the pelts for hunting
		[1] = { bone = 24817, x = -0.18, y = -0.26, z = -0.02, xr = 0.0, yr = 91.0, zr = 5.0 },
		[2] = { bone = 24817, x = 0.10, y = -0.26, z = -0.02, xr = 0.0, yr = 91.0, zr = 5.0 },
		[3] = { bone = 24817, x = 0.38, y = -0.21, z = -0.02, xr = 0.0, yr = 91.0, zr = 5.0 },
	},

	[5] = { -- I use this for chains, make sure your CHAIN is a CUSTOM prop, will NOT work with a clothing item, if you want to add a CHAIN make sure to have a chain = true as it will not work the same as weapons --
		[1] = { bone = 10706, x = 0.11, y = 0.080, z = -0.473, xr = -366.0, yr = 19.0, zr = -163.0 },
	},
}

local props = {
	-- ========== VŨ KHÍ CẦM TAY (Đeo hông khi không cầm - Tier 2) ==========
	
	-- -- Dao machete
	-- ["weapon_machete"] = {
	-- 	model = "w_me_machette_lr",
	-- 	hash = 0xDD5DF8D9,
	-- 	tier = 2,
	-- },
	
	-- -- Dao
	-- ["weapon_knife"] = {
	-- 	model = "prop_w_me_knife_01",
	-- 	hash = 0x99B507EA,
	-- 	tier = 2,
	-- },
	
	-- -- Gậy bóng chày
	-- ["weapon_bat"] = {
	-- 	model = "w_me_bat",
	-- 	hash = 0x958A4A8F,
	-- 	tier = 2,
	-- },
	
	-- -- Xà beng
	-- ["weapon_crowbar"] = {
	-- 	model = "w_me_crowbar",
	-- 	hash = 0x84BD7BFD,
	-- 	tier = 2,
	-- },
	
	-- -- Búa
	-- ["weapon_hammer"] = {
	-- 	model = "w_me_hammer",
	-- 	hash = 0x4E875F73,
	-- 	tier = 2,
	-- },
	
	-- -- Rìu
	-- ["weapon_hatchet"] = {
	-- 	model = "w_me_hatchet",
	-- 	hash = 0xF9DCBF2D,
	-- 	tier = 2,
	-- },
	
	-- -- Dao găm
	-- ["weapon_dagger"] = {
	-- 	model = "w_me_dagger",
	-- 	hash = 0x92A27487,
	-- 	tier = 2,
	-- },
	
	-- -- Gậy golf
	-- ["weapon_golfclub"] = {
	-- 	model = "w_me_gclub",
	-- 	hash = 0x440E4788,
	-- 	tier = 2,
	-- },
	
	-- -- Cờ lê
	-- ["weapon_wrench"] = {
	-- 	model = "w_me_wrench",
	-- 	hash = 0x19044EE0,
	-- 	tier = 2,
	-- },
	
	-- -- Rìu đá
	-- ["weapon_stone_hatchet"] = {
	-- 	model = "w_me_stonehatchet",
	-- 	hash = 0x3813FC08,
	-- 	tier = 2,
	-- },

	-- ========== VẬT PHẨM BÊ VÁC (Carry items) ==========
	
	["lovisong"] = { 
		carry = true, 
		model = "prop_microwave_1", 
		bone = 24817, 
		x = -0.10, y = 0.40, z = 0.00, 
		xr = 0.0, yr = -90.0, zr = 180.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = false,    -- [TẮT] Cho phép lên xe
		blockRun = true      -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	
	-- TV: Cấm đánh, cho phép lên xe, cấm chạy
	["tv"] = { 
		carry = true, 
		model = "prop_tv_flat_02b", 
		bone = 24817, 
		x = -0.00, y = 0.40, z = 0.00, 
		xr = 0.0, yr = -90.0, zr = 180.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = false,    -- [TẮT] Cho phép lên xe
		blockRun = true      -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	
	-- Nắp cống: Cấm đánh, cho phép lên xe, cho phép chạy
	["nap_cong"] = { 
		carry = true, 
		model = "napcong", 
		bone = 24817, 
		x = -0.00, y = 0.40, z = 0.00, 
		xr = 0.0, yr = -90.0, zr = 180.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = false,    -- [TẮT] Cho phép lên xe
		blockRun = false     -- [TẮT] Cho phép chạy
	},

	["package"] = { 
		carry = true, 
		model = "hei_prop_heist_box", 
		bone = 24817, 
		x = -0.00, y = 0.40, z = 0.00, 
		xr = 0.0, yr = -90.0, zr = 180.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [TẮT] Cho phép lên xe
		blockRun = false     -- [TẮT] Cho phép chạy
	},
	
	-- Bồn cầu: Cấm đánh, cấm lên xe, cấm chạy (nặng nhất)
	["boncau"] = { 
		carry = true, 
		model = "prop_toilet_01", 
		bone = 28422, 
		x = 0.0, y = -0.15, z = -0.1, 
		xr = 0.0, yr = 0.0, zr = 90.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,     -- [BẬT] Cấm lên xe
		blockRun = true      -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	["banhxecu"] = { 
		carry = true, 
		model = "prop_wheel_01", 
		bone = 18905, 
		x = 0.039, y = 0.158, z = 0.292, 
		xr = 0.0, yr = 0.0, zr = 118.818085, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	-- Capo (Nắp ca-pô): vec3(0.020, 0.030, -0.500), rot(0.0, 0.0, 134.0)
	["capocu"] = { 
		carry = true, 
		model = "prop_car_bonnet_01", 
		bone = 18905, 
		x = 0.020, y = 0.030, z = -0.500, 
		xr = 0.0, yr = 0.0, zr = 134.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	-- Cửa xe cũ: vec3(0.188, 0.0, 0.846), rot(-301.784973, -0.000005, 221.990677)
	["cuaxecu"] = { 
		carry = true, 
		model = "imp_prop_impexp_car_door_01a", 
		bone = 18905, 
		x = 0.188, y = 0.0, z = 0.846, 
		xr = -301.784973, yr = -0.000005, zr = 221.990677, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	-- Động cơ cũ: vec3(0.330, -0.066, 0.396), rot(-69.0, 0.0, 26.0)
	["dongcocu"] = { 
		carry = true, 
		model = "prop_car_engine_01", 
		bone = 18905, 
		x = 0.330, y = -0.066, z = 0.396, 
		xr = -69.0, yr = 0.0, zr = 26.0, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	-- Trục truyền động: vec3(0.330, 0.077, 0.319), rot(0.0, -76.907967, -5.916)
	["tructruyendong"] = { 
		carry = true, 
		model = "imp_prop_impexp_diff_01", 
		bone = 18905, 
		x = 0.330, y = 0.077, z = 0.319, 
		xr = 0.0, yr = -76.907967, zr = -5.916, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},

	-- Box điện tử cũ (Exhaust): vec3(0.174, 0.0, 0.232), rot(-66.120026, 0.0, 1.102)
	["boxecu"] = { 
		carry = true, 
		model = "imp_prop_impexp_exhaust_01", 
		bone = 18905, 
		x = 0.174, y = 0.0, z = 0.232, 
		xr = -66.120026, yr = 0.0, zr = 1.102, 
		blockAttack = true,  -- [BẬT] Cấm đánh/bắn khi bê
		blockCar = true,    -- [BẬT] Cấm lên xe
		blockRun = true     -- [BẬT] Cấm chạy, chỉ đi bộ
	},
	

}

local items_attatched = {}
local itemSlots = {}
local override = false


local FullyLoaded = LocalPlayer.state.isLoggedIn



local function loadmodel(hash)
	if HasModelLoaded(hash) then return end
	RequestModel(hash)
	while not HasModelLoaded(hash) do
		Wait(0)
	end
end

----------------------------------------------------------------------------------------

local function getFreeSlot(tier)
	local amount = 0

	for i = 1, #PlayerSlots[tier] do
		if not PlayerSlots[tier][i].isBusy then
			amount = amount + 1
		end
	end

	return amount
end

local function UseSlot(tier)
	local slot = nil
	for i = 1, #PlayerSlots[tier] do
		if not PlayerSlots[tier][i].isBusy then
			PlayerSlots[tier][i].isBusy = true
			slot = i
			break
		end
	end

	return slot
end

local function calcOffsets(x, y, z, xr, yr, zr, item)
	local X, Y, Z, XR, YR, ZR = x, y, z, xr, yr, zr

	if props[item].x then
		X = props[item].x
	end

	if props[item].y then
		Y = props[item].y
	end

	if props[item].z then
		Z = props[item].z
	end

	if props[item].xr then
		XR = props[item].xr
	end


	if props[item].yr then
		YR = props[item].yr
	end

	if props[item].zr then
		ZR = props[item].zr
	end

	return X, Y, Z, XR, YR, ZR
end

local function AttachWeapon(attachModel, modelHash, tier, item)
	local hash = joaat(attachModel)
	local slot = UseSlot(tier)
	if not slot then return end

	local v = PlayerSlots[tier][slot]
	local bone = GetPedBoneIndex(PlayerPedId(), v.bone)

	loadmodel(hash)

	items_attatched[attachModel] = {
		hash = modelHash,
		handle = CreateObject(attachModel, 1.0, 1.0, 1.0, true, true, false),
		slot = slot,
		tier = tier
	}

	local x, y, z, xr, yr, zr = calcOffsets(v.x, v.y, v.z, v.xr, v.yr, v.zr, item)

	AttachEntityToEntity(items_attatched[attachModel].handle, PlayerPedId(), bone, x, y, z, xr, yr, zr, 1, 1, 0, 0, 2, 1)
	SetModelAsNoLongerNeeded(hash)
	SetEntityCompletelyDisableCollision(items_attatched[attachModel].handle, false, true)
end

local WeapDelete = false
local function DeleteWeapon(item)
	local ped = PlayerPedId()
	local hash = items_attatched[item].hash
	if WeapDelete then return end

	WeapDelete = true
	local wait = 0 
	while GetSelectedPedWeapon(ped) ~= hash do
		Wait(100)
		wait = wait + 1
		if wait >= 30 then 
			return 
		end 
	end

	if items_attatched[item] then

		DeleteObject(items_attatched[item].handle)

		if items_attatched[item].slot then
			PlayerSlots[items_attatched[item].tier][items_attatched[item].slot].isBusy = false
		end

		items_attatched[item] = nil

	end
	WeapDelete = false
end

-----------------------------------------------------------------
local carryingBox = nil

local function requestAnimDict(animDict)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end
end

local function doAnim(item)
	if carryingBox then return end 
	carryingBox = item
	local ped = PlayerPedId()
	local dict, anim = props[item].dict or 'anim@heists@box_carry@', props[item].anim or 'idle'
	if not anim or not dict then return end

	requestAnimDict(dict)
	CreateThread(function()
		while carryingBox do
			if not IsEntityPlayingAnim(ped, dict, anim, 3) then
				TaskPlayAnim(ped, dict, anim, 8.0, -8, -1, 49, 0, 0, 0, 0)
			end

			if props[carryingBox].blockAttack then
				DisableControlAction(0, 24, true) -- disable attack
				DisableControlAction(0, 25, true) -- disable aim
				DisableControlAction(0, 47, true) -- disable weapon
				DisableControlAction(0, 58, true) -- disable weapon
				DisableControlAction(0, 263, true) -- disable melee
				DisableControlAction(0, 264, true) -- disable melee
				DisableControlAction(0, 257, true) -- disable melee
				DisableControlAction(0, 140, true) -- disable melee
				DisableControlAction(0, 141, true) -- disable melee
				DisableControlAction(0, 142, true) -- disable melee
				DisableControlAction(0, 143, true) -- disable melee
			end

			if props[carryingBox].blockCar and IsPedGettingIntoAVehicle(ped) then
				ClearPedTasksImmediately(ped) -- Stops all tasks for the ped
			end

			if props[carryingBox].blockRun then
				DisableControlAction(0, 22, true) -- disable jumping
				DisableControlAction(0, 21, true) -- disable sprinting
			end

			Wait(1)
		end

		ClearPedTasks(ped)
	end)
end

local function AttatchProp(item)
	if carryingBox then return end
	local ped = PlayerPedId()
	local attachModel = props[item].model
	local hash = joaat(props[item].model)
	local bone = GetPedBoneIndex(ped, props[item].bone)
	SetCurrentPedWeapon(ped, 0xA2719263)
	loadmodel(hash)

	items_attatched[attachModel] = {
		hash = hash,
		handle = CreateObject(attachModel, 1.0, 1.0, 1.0, true, true, false),
		carry = true
	}

	local x, y, z, xr, yr, zr = props[item].x, props[item].y, props[item].z, props[item].xr, props[item].yr, props[item].zr
	AttachEntityToEntity(items_attatched[attachModel].handle, ped, bone, x, y, z, xr, yr, zr, 1, 1, 0, 0, 2, 1)
	SetModelAsNoLongerNeeded(hash)
	SetEntityCompletelyDisableCollision(items_attatched[attachModel].handle, false, true)
	doAnim(item)
	
	-- Nếu là bồn cầu, bắt đầu add target vào xe
	if item == 'boncau' then
		AddVehicleTargetsForToilet()
	end
end

local tempBox = nil

local function carryProp(item)
	if not item then return print("ITEM NOT DEFINED") end
	if not props[item] then return print("ITEM NOT REGISTERED IN THE CONFIG") end
	if carryingBox then return print("PED IS ALREADY CARRYING AN OBJECT") end
	tempBox = item
	AttatchProp(item)
end

exports('carryProp', carryProp)

local function removeProp(item)
	if not item then return print("ITEM NOT DEFINED") end
	if not props[item] then return print("ITEM NOT REGISTERED IN THE CONFIG") end
	if carryingBox ~= item then return print("Item is not whats being carried...") end
	DeleteObject(items_attatched[props[item].model].handle)
	items_attatched[props[item].model] = nil
	carryingBox = nil
	tempBox = nil
end

exports('removeProp', removeProp)



local carryingChain = nil

local function AttatchChain(attachModel, modelHash, tier, item)
	if carryingChain then return end
	carryingChain = attachModel
	local slot = UseSlot(tier)
	if not slot then return end

	local v = PlayerSlots[tier][slot]
	local bone = GetPedBoneIndex(PlayerPedId(), v.bone)

	loadmodel(modelHash)

	ClearPedTasks(PlayerPedId())


	items_attatched[attachModel] = {
		hash = modelHash,
		handle = CreateObject(attachModel, 1.0, 1.0, 1.0, true, true, false),
		slot = slot,
		tier = tier,
		chain = true,
	}

	local x, y, z, xr, yr, zr = calcOffsets(v.x, v.y, v.z, v.xr, v.yr, v.zr, item)

	AttachEntityToEntity(items_attatched[attachModel].handle, PlayerPedId(), bone, x, y, z, xr, yr, zr, 1, 1, 0, 0, 2, 1)
	SetModelAsNoLongerNeeded(modelHash)
	SetEntityCompletelyDisableCollision(items_attatched[attachModel].handle, false, true)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--** Generic Functions **--

local function getItemByhash(hash)
	for k, v in pairs(props) do
		if v.hash == hash or hash == joaat(v.model) then
			return k
		end
	end
end

local function removeItems()
	if items_attatched then
		for k, v in pairs(items_attatched) do
			local hasitem = false
			local item = getItemByhash(v.hash)
			if item then
				if tempBox ~= item then
					if itemSlots[item] then
						hasitem = true
					end

					if not hasitem or (props[item] and props[item].busy) then
						DeleteObject(v.handle)

						if v.slot then
							PlayerSlots[v.tier][v.slot].isBusy = false
						end

						if v.chain then
							carryingChain = nil
						end

						if v.carry then
							carryingBox = nil
						end

						items_attatched[k] = nil
					end
				end
			end
		end
	end
end

local PlayerId = PlayerId()
local doingCheck = false
local function DoItemCheck()
	if not FullyLoaded then return end
	if doingCheck then return end
	if IsPedShooting(ped) or IsPlayerFreeAiming(PlayerId) then return end 
	doingCheck = true
	Wait(math.random(1, 100)) 
	local ped = PlayerPedId()
	local items = QBX.PlayerData.items
	itemSlots = {}
	if items then
		for _, item in pairs(items) do
			item.name = item.name:lower()
			if item and item.name and props and props[item.name] and not itemSlots[item.name] then
				itemSlots[item.name] = props[item.name]
				if props[item.name].carry then
					if not carryingBox then
						AttatchProp(item.name)
					end
				elseif props[item.name].chain then
					if not carryingChain then
						AttatchChain(props[item.name].model, props[item.name].hash, props[item.name].tier, item.name)
					end
				elseif not items_attatched[props[item.name].model] and GetSelectedPedWeapon(ped) ~= props[item.name].hash and
					getFreeSlot(props[item.name].tier) >= 1 then
					AttachWeapon(props[item.name].model, props[item.name].hash, props[item.name].tier, item.name)
				end
			end
		end
	end

	removeItems()

	Wait(math.random(1, 100)) 
	doingCheck = false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ** EXPORTS ** --
local function toggleProps()
	if override then
		if items_attatched then
			for k, v in pairs(items_attatched) do

				DeleteObject(v.handle)

				if v.slot then
					PlayerSlots[v.tier][v.slot].isBusy = false
				end

				if v.carry then
					carryingBox = nil
				end

				if v.chain then
					carryingChain = nil
				end

				items_attatched[k] = nil
			end
		end
		override = false
	else
		override = true

		if items_attatched then
			for k, v in pairs(items_attatched) do

				DeleteObject(v.handle)

				if v.slot then
					PlayerSlots[v.tier][v.slot].isBusy = false
				end

				if v.carry then
					carryingBox = nil
				end

				if v.chain then
					carryingChain = nil
				end

				items_attatched[k] = nil
			end
		end
	end
end

exports("toggleProps", toggleProps)

local function isCarryingObject()
	return carryingBox ~= nil and true or false
end

exports('isCarryingObject', isCarryingObject)

local function isCarryingAnObject(item)
	if items_attatched[props[item].model] then return true else return false end
end

exports('isCarryingAnObject', isCarryingAnObject)

local function GetPlayerCarryItems()
	return items_attatched
end

exports('GetPlayerCarryItems', GetPlayerCarryItems)

local function refreshProps()
	if not FullyLoaded then return end
	if items_attatched then
		for k, v in pairs(items_attatched) do
			DeleteObject(v.handle)

			if v.slot then
				PlayerSlots[v.tier][v.slot].isBusy = false
			end

			if v.carry then
				carryingBox = nil
			end

			if v.chain then
				carryingChain = nil
			end

			items_attatched[k] = nil
		end
	end

	DoItemCheck()
end

exports('refreshProps', refreshProps)

local function makeObjectBusy(item, state)
	if not FullyLoaded then return end
	if not item or not state then return print("YOU ARE MISSING ARGS FOR THIS EXPORT") end
	if not props[item] then return print("ITEM: " .. item .. " DOES NOT EXIST") end
	if props[item] and props[item].busy == nil then return print("ITEM: " .. item .. " CANNOT BE SET TO BUSY") end
	props[item].busy = state
	DoItemCheck()
end

exports('makeObjectBusy', makeObjectBusy)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ** GENERIC EVENTS ** --
AddEventHandler('ox_inventory:currentWeapon', function(data)
	if not FullyLoaded then return end
	if override then return end
	if data then
		data.name = data.name:lower()
		if props[data.name] and items_attatched[props[data.name].model] then
			DeleteWeapon(props[data.name].model)
		end
	else
		Wait(1000)
		DoItemCheck()
	end
end)

RegisterNetEvent('weapons:client:SetCurrentWeapon', function(data)
	if data and LocalPlayer.state.isLoggedIn then
		if props[data.name] and items_attatched[props[data.name].model] then
			DeleteWeapon(props[data.name].model)
		end
	elseif not data and LocalPlayer.state.isLoggedIn then
		Wait(1000)
		if not override then DoItemCheck() elseif override and QBX.PlayerData.metadata.inside.apartment.apartmentId then DoItemCheck() end
	end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	Wait(20000)
	FullyLoaded = true
	Wait(250)
	if not override then 
		DoItemCheck() 
	elseif override and QBX.PlayerData.metadata.inside.apartment.apartmentId then 
		DoItemCheck() 
	end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
	FullyLoaded = false
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
	Wait(50)
	if not override then
		DoItemCheck()
	elseif override and QBX.PlayerData.metadata.inside.apartment.apartmentId then
		DoItemCheck()
	end
end)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key)
	if key == 'items' then
		Wait(50)
		if not override or QBX.PlayerData.metadata.inside.apartment.apartmentId then DoItemCheck() end
	end
end)

AddEventHandler('ox_inventory:updateInventory', function()
	if not FullyLoaded then return end
	Wait(50)
	if not override or QBX.PlayerData.metadata.inside.apartment.apartmentId then DoItemCheck() end
end)

-- Handles state if resource is restarted live.
AddEventHandler('onResourceStart', function(resource)
	if GetCurrentResourceName() == resource then
		Wait(100)
		if not FullyLoaded then return end
		DoItemCheck()
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for key, attached_object in pairs(items_attatched) do
			DeleteObject(attached_object.handle)
			items_attatched[key] = nil
		end
	end
end)

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ** TOILET TARGET ** --
local vehiclesWithToiletTarget = {}
local tablesWithToiletTarget = {}

-- Function để add target vào xe khi bê bồn cầu
function AddVehicleTargetsForToilet()
	CreateThread(function()
		while carryingBox == 'boncau' do
			Wait(500)
			local ped = PlayerPedId()
			local pedCoords = GetEntityCoords(ped)
			
			-- Tìm xe gần nhất
			local vehicles = GetGamePool('CVehicle')
			for _, vehicle in pairs(vehicles) do
				if DoesEntityExist(vehicle) then
					local vehCoords = GetEntityCoords(vehicle)
					local dist = #(pedCoords - vehCoords)
					
					if dist <= 5.0 then
						-- Chỉ add nếu chưa có target
						if not vehiclesWithToiletTarget[vehicle] then
							exports.ox_target:addLocalEntity(vehicle, {
								{
									name = 'place_boncau_on_vehicle',
									label = 'Đặt Bồn Cầu Lên Xe',
									icon = 'fas fa-truck-loading',
									distance = 3.0,
									onSelect = function()
										TriggerEvent('xn_carryweapons:place_boncau_on_vehicle', {vehicle = vehicle})
									end,
									canInteract = function()
										return carryingBox == 'boncau'
									end
								}
							})
							vehiclesWithToiletTarget[vehicle] = true
						end
					end
				end
			end
		end
		
		-- Cleanup khi không còn bê bồn cầu
		for vehicle, _ in pairs(vehiclesWithToiletTarget) do
			if DoesEntityExist(vehicle) then
				exports.ox_target:removeLocalEntity(vehicle, {'place_boncau_on_vehicle'})
			end
		end
		vehiclesWithToiletTarget = {}
	end)
end



-- Event để đặt bồn cầu lên xe
RegisterNetEvent('xn_carryweapons:place_boncau_on_vehicle')
AddEventHandler('xn_carryweapons:place_boncau_on_vehicle', function(data)
	if carryingBox ~= 'boncau' then
		return
	end
	
	local vehicle = data.vehicle
	local ped = PlayerPedId()
	
	if not DoesEntityExist(vehicle) then
		return
	end
	
	-- Xóa prop từ tay
	if items_attatched['prop_toilet_01'] then
		DeleteObject(items_attatched['prop_toilet_01'].handle)
		items_attatched['prop_toilet_01'] = nil
	end
	
	-- Reset carrying state và clear animation
	carryingBox = nil
	tempBox = nil
	ClearPedTasks(ped)
	
	-- Đảm bảo enable lại tất cả controls (phòng trường hợp thread chưa kịp dọn dẹp)
	Wait(100)
	EnableAllControlActions(0)
	
	-- Animation đặt lên xe
	TaskTurnPedToFaceEntity(ped, vehicle, 1000)
	Wait(500)
	
	-- Spawn prop bồn cầu lên nóc xe
	local toiletHash = joaat('prop_toilet_01')
	RequestModel(toiletHash)
	while not HasModelLoaded(toiletHash) do Wait(0) end
	
	local vehCoords = GetEntityCoords(vehicle)
	local vehDimMin, vehDimMax = GetModelDimensions(GetEntityModel(vehicle))
	local roofHeight = vehDimMax.z - 0.15
	
	if vehDimMax.z < 0.8 then
		roofHeight = vehDimMax.z - 0.05
	end
	
	local toiletProp = CreateObject(toiletHash, vehCoords.x, vehCoords.y, vehCoords.z, true, true, false)
	SetEntityAsMissionEntity(toiletProp, true, true)
	AttachEntityToEntity(toiletProp, vehicle, 0, 0.0, 0.0, roofHeight, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
	SetModelAsNoLongerNeeded(toiletHash)
	
	-- Xóa item bồn cầu khỏi túi
	print('[CLIENT] Triggering RemoveItem for boncau')
	TriggerServerEvent('QBCore:Server:RemoveItem', 'boncau', 1)
	
	-- Add target vào xe để lấy bồn cầu xuống
	exports.ox_target:addLocalEntity(vehicle, {
		{
			name = 'take_boncau_from_vehicle',
			label = 'Lấy Bồn Cầu Từ Xe',
			icon = 'fas fa-hand-holding',
			distance = 3.0,
			onSelect = function()
				TriggerEvent('xn_carryweapons:take_boncau_from_vehicle', {toilet = toiletProp, vehicle = vehicle})
			end,
			canInteract = function()
				return DoesEntityExist(toiletProp) and IsEntityAttachedToEntity(toiletProp, vehicle)
			end
		}
	})
	
	-- Cleanup target xe
	for veh, _ in pairs(vehiclesWithToiletTarget) do
		if DoesEntityExist(veh) then
			exports.ox_target:removeLocalEntity(veh, {'place_boncau_on_vehicle'})
		end
	end
	vehiclesWithToiletTarget = {}
end)

-- Event để lấy bồn cầu từ xe xuống
RegisterNetEvent('xn_carryweapons:take_boncau_from_vehicle')
AddEventHandler('xn_carryweapons:take_boncau_from_vehicle', function(data)
	local toiletProp = data.toilet
	local vehicle = data.vehicle
	
	if not DoesEntityExist(toiletProp) or not DoesEntityExist(vehicle) then
		return
	end
	
	local ped = PlayerPedId()
	
	-- Animation lấy xuống
	TaskTurnPedToFaceEntity(ped, vehicle, 1000)
	Wait(500)
	
	TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 2000, 0, 0, false, false, false)
	Wait(2000)
	
	-- Xóa target xe
	exports.ox_target:removeLocalEntity(vehicle, {'take_boncau_from_vehicle'})
	
	-- Xóa prop từ xe
	SetEntityVisible(toiletProp, false, false)
	SetEntityCollision(toiletProp, false, false)
	DeleteEntity(toiletProp)
	
	-- Thêm item bồn cầu vào túi
	print('[CLIENT] Triggering AddItem for boncau')
	TriggerServerEvent('QBCore:Server:AddItem', 'boncau', 1)
	
	-- Gọi quét item 1 lần sau khi lấy bồn cầu từ xe
	Wait(500)
	DoItemCheck()
end)
