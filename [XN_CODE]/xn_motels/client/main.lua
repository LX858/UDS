local kvpname = GetCurrentServerEndpoint()..'_inshells'
local maxRentDaysLimit = 365
-- Create blips on map for motels
-- Config: Use 'blipLabel' field to customize blip name (fallback to 'label' if not set)
CreateBlips = function()
	for k,v in pairs(config.motels) do
		local blip = AddBlipForCoord(v.rentcoord.x,v.rentcoord.y,v.rentcoord.z)
		SetBlipSprite(blip,475)
		SetBlipColour(blip,2)
		SetBlipAsShortRange(blip,true)
		SetBlipScale(blip,0.6)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.blipLabel or v.label)
		EndTextCommandSetBlipName(blip)
	end
end



-- Callback for confirming occupant addition
lib.callback.register('renzu_motels:confirmoccupant', function(data)
	local motels = GlobalState.Motels
	local motelData = motels[data.motel]
	local motelLabel = 'Unknown Motel'
	
	-- Find motel label from config
	for k, v in pairs(config.motels) do
		if v.motel == data.motel then
			motelLabel = v.label
			break
		end
	end
	
	local confirm = lib.alertDialog({
		header = 'Xác nhận thuê phòng trọ',
		content = '## THÔNG TIN \n **Motel:** '..motelLabel..' \n **Phòng:** #'..data.index..' \n **Thời gian thuê:** '..data.duration..' '..data.rental_period..'(s) \n **Giá:** $'..data.rate..' / '..data.rental_period..' \n **Tổng tiền:** $'..data.amount..' \n **Phương thức thanh toán:** '..data.payment,
		centered = true,
		labels = {
			cancel = 'Từ chối',
			confirm = 'Xác nhận & Thanh toán'
		},
		cancel = true
	})
	
	if confirm == 'confirm' then
		return true
	else
		return false
	end
end)

DoesPlayerHaveAccess = function(data)
	if config.debug then
		print('^3[DEBUG] DoesPlayerHaveAccess checking:^7')
		print('  Room players: ' .. json.encode(data or {}))
		print('  Current player: ' .. tostring(PlayerData?.identifier))
	end
    for identifier, _ in pairs(data or {}) do
        if identifier == PlayerData?.identifier then 
			if config.debug then
				print('^2[DEBUG] Player has direct access to room!^7')
			end
			return true 
		end
    end
	if config.debug then
		print('^1[DEBUG] Player does NOT have direct access to room^7')
	end
    return false
end

DoesPlayerHaveKey = function(data,room)
	local items = GetInventoryItems('keys')
	if not items then return false end
	for k,v in pairs(items) do
		-- Debug information
		if config.debug then
			print('^3[DEBUG] Checking key:^7')
			print('  Key type: ' .. tostring(v.metadata?.type) .. ' | Required: ' .. tostring(data.motel))
			print('  Key serial: ' .. tostring(v.metadata?.serial) .. ' (' .. type(v.metadata?.serial) .. ') | Required: ' .. tostring(data.index) .. ' (' .. type(data.index) .. ')')
			print('  Key owner: ' .. tostring(v.metadata?.owner) .. ' | Player: ' .. tostring(PlayerData?.identifier))
			print('  Room players: ' .. json.encode(room?.players or {}))
		end
		
		-- Convert both to numbers for proper comparison
		local keySerial = tonumber(v.metadata?.serial)
		local requiredIndex = tonumber(data.index)
		
		if v.metadata?.type == data.motel and keySerial == requiredIndex then
			-- Check if the key's owner matches the current player AND the owner is in the room's player list
			if v.metadata?.owner == PlayerData?.identifier and room?.players[v.metadata?.owner] then
				if config.debug then
					print('^2[DEBUG] Key validation successful!^7')
				end
				return room.players[v.metadata.owner]
			else
				if config.debug then
					print('^1[DEBUG] Key validation failed - owner mismatch or not in room^7')
				end
			end
		end
	end
	if config.debug then
		print('^1[DEBUG] No valid key found^7')
	end
	return false
end

GetPlayerKeys = function(data,room)
	local items = GetInventoryItems('keys')
	if not items then return false end
	local keys = {}
	for k,v in pairs(items) do
		if v.metadata?.type == data.motel and v.metadata?.serial == data.index then
			-- Only include keys that belong to the current player
			if v.metadata?.owner == PlayerData?.identifier and room?.players[v.metadata?.owner] then
				keys[v.metadata.owner] = room.players[v.metadata.owner].name
			end
		end
	end
	return keys
end

SetDoorState = function(data)
	local motels = GlobalState.Motels or {}
	local doorindex = data.index + (joaat(data.motel))
	DoorSystemSetDoorState(doorindex, 1)
end

RegisterNetEvent('renzu_motels:Door', function(data)
	if not data.Mlo then return end
	local doorindex = data.doorindex + (joaat(data.motel))
	DoorSystemSetDoorState(doorindex, DoorSystemGetDoorState(doorindex) == 0 and 1 or 0, false, false)
end)

-- Áp dụng ped được admin gán ngay lập tức
RegisterNetEvent('renzu_motels:applyPed', function(pedModel, comps, texs)
	local model = GetHashKey(pedModel)
	RequestModel(model)
	while not HasModelLoaded(model) do Wait(100) end
	SetPlayerModel(PlayerId(), model)
	SetModelAsNoLongerNeeded(model)

	local ped = PlayerPedId()
	for i = 0, 11 do
		SetPedComponentVariation(ped, i, comps[i] or 0, texs[i] or 0, 0)
	end
	for i = 0, 2 do ClearPedProp(ped, i) end
	ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

	-- Lưu vào illenium-appearance để giữ khi reconnect
	lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
		if not appearance then appearance = {} end
		appearance.model        = pedModel
		appearance.headBlend    = nil
		appearance.faceFeatures = nil
		appearance.headOverlays = nil
		appearance.hair         = nil
		appearance.tattoos      = nil
		local components = {}
		for i = 0, 11 do
			components[i + 1] = {
				componentId = i,
				drawableId  = comps[i] or 0,
				textureId   = texs[i]  or 0,
				paletteId   = 0,
			}
		end
		appearance.components = components
		appearance.props = {
			{ propId = 0, drawableId = -1, textureId = -1 },
			{ propId = 1, drawableId = -1, textureId = -1 },
			{ propId = 2, drawableId = -1, textureId = -1 },
			{ propId = 6, drawableId = -1, textureId = -1 },
			{ propId = 7, drawableId = -1, textureId = -1 },
		}
		TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
	end)

	Notify('Admin đã gán ped "' .. pedModel .. '" cho bạn', 'inform')
end)

-- Thông báo chung từ server (dùng cho resetped admin)
RegisterNetEvent('renzu_motels:notify', function(msg, type)
	Notify(msg, type or 'inform')
end)

RegisterNetEvent('renzu_motels:client:openStorageStash', function(stashId, slots, weight)
	TriggerEvent('ox_inventory:openInventory', 'stash', {
		id = stashId,
		name = 'Kho ký gửi phòng trọ',
		slots = slots,
		weight = weight,
		coords = GetEntityCoords(cache.ped)
	})
end)

Door = function(data)
    local dist = #(data.coord - GetEntityCoords(cache.ped)) < 2
    local motel = GlobalState.Motels[data.motel]
	local moteldoor = motel and motel.rooms[data.index]
	
	-- Debug access checks
	if config.debug then
		print('^3[DEBUG] Door access check for room ' .. data.index .. ':^7')
		print('  Motel Name: ' .. tostring(data.motel))
		print('  Player ID: ' .. tostring(PlayerData?.identifier))
		print('  Motel exists: ' .. tostring(motel ~= nil))
		print('  Room exists: ' .. tostring(moteldoor ~= nil))
		if moteldoor then
			print('  Room players: ' .. json.encode(moteldoor.players or {}))
		end
	end
	
	local hasDirectAccess = moteldoor and DoesPlayerHaveAccess(motel.rooms[data.index].players)
	local hasValidKey = moteldoor and DoesPlayerHaveKey(data,moteldoor)
	local isOwnerEmployee = IsOwnerOrEmployee(data.motel)
	-- Check if player is in the room's players list (this means they rented/own the room)
	local isRoomPlayer = moteldoor and moteldoor.players and moteldoor.players[PlayerData?.identifier]
	
	-- Check if rent is expired (only for players who rented the room, not owner/employee)
	local rentExpired = false
	if isRoomPlayer and not isOwnerEmployee then
		rentExpired = isRentExpired(data)
		if config.debug then
			print('  Rent Expired: ' .. tostring(rentExpired))
		end
	end
	
	if config.debug then
		print('  Has Direct Access: ' .. tostring(hasDirectAccess))
		print('  Has Valid Key: ' .. tostring(hasValidKey))
		print('  Is Owner/Employee: ' .. tostring(isOwnerEmployee))
		print('  Is Room Player: ' .. tostring(isRoomPlayer ~= nil))
		if moteldoor and moteldoor.players then
			print('  Player in room list: ' .. tostring(moteldoor.players[PlayerData?.identifier] ~= nil))
		end
		print('  Final Access: ' .. tostring((hasDirectAccess or hasValidKey or isOwnerEmployee or isRoomPlayer) and not rentExpired))
	end
	
	-- Block access if rent expired (unless owner/employee)
	if rentExpired then
		Notify('Tiền thuê của bạn đã đến hạn!\nVui lòng thanh toán để truy cập phòng.', 'error')
		return
	end
	
    if hasDirectAccess or hasValidKey or isOwnerEmployee or isRoomPlayer then
		-- Access granted - Enter the room
		lib.RequestAnimDict('mp_doorbell')
		TaskPlayAnim(PlayerPedId(), "mp_doorbell", "open_door", 1.0, 1.0, 1000, 1, 1, 0, 0, 0)
        
		-- Play door sound
		local soundData = {
			file = 'door',
			volume = 0.5
		}
		SendNUIMessage({
			type = "playsound",
			content = soundData
		})
		
		-- Enter the room (shell or MLO)
		if data.Mlo then
			-- For MLO, just notify (coordinates handled by target system)
			Notify('Bạn đã vào phòng #' .. data.index, 'success')
		else
			-- For shell-based rooms, enter the shell
			EnterShell(data)
		end
		
		if config.debug then
			print('^2[DEBUG] Successfully entered room #' .. data.index .. '^7')
		end
	else
		-- Access denied
		Notify('Bạn không có quyền truy cập vào phòng này!', 'error')
		if config.debug then
			print('^1[DEBUG] Access DENIED - No valid credentials for room #' .. data.index .. '^7')
		end
	end
end

isRentExpired = function(data)
	if data and data.isQuickSleep then return false end
	local motels = GlobalState.Motels[data.motel]
	local room = motels?.rooms[data.index] or {}
	local player = room?.players[PlayerData.identifier] or {}
	return player?.duration and player?.duration < GlobalState.MotelTimer
end

RoomFunction = function(data,identifier,targetCoords)
	if isRentExpired(data) then
		return Notify('Tiền thuê của bạn đã đến hạn.  \n  Vui lòng thanh toán để truy cập')
	end
	if data.type == 'door' then
		return Door(data)
	elseif data.type == 'exit' then
		if config.debug then
			print('^3[DEBUG] Exit function called, teleporting back^7')
		end
		return Teleport(data.lastloc.x, data.lastloc.y, data.lastloc.z, data.lastloc.w or 0.0, true)
	elseif data.type == 'stash' then
		if data.isQuickSleep then
			return Notify('Phòng ngủ nhanh không có kho đồ riêng!', 'inform')
		end
		local stashid = identifier or data.uniquestash and PlayerData.identifier or 'room'
		return OpenStash(data,stashid)
	elseif data.type == 'wardrobe' then
		if not data.isQuickSleep then
			local motels = GlobalState.Motels
			local rooms = motels[data.motel] and motels[data.motel].rooms
			local room = rooms and (rooms[data.index] or rooms[tostring(data.index)] or rooms[tonumber(data.index)])
			local trashCount = room and room.trashCount or 0
			
			if trashCount >= 6 then
				return Notify('Bạn không thể ngủ ở nơi bẩn như thế này được!', 'error')
			end
		end

		-- Wardrobe is now the sleep location
		local coords = targetCoords or data.coord or GetEntityCoords(cache.ped)
		local quickCfg = config.quickSleep or {}
		local maxSleep = data.isQuickSleep and (quickCfg.maxSleepiness or 50) or 100
		local location = {
			coords = vec4(coords.x, coords.y, coords.z - 0.5, 5.0),
			maxSleepiness = maxSleep
		}
		return exports['sleep_system']:StartSleepAtLocation(location)
	elseif config.extrafunction[data.type] then
		local stashid = identifier or data.uniquestash and PlayerData.identifier or 'room'
		return config.extrafunction[data.type](data,stashid)
	end
end

-- =============================================
-- Thay đổi ped của player từ target trong phòng
-- =============================================
ChangePedFunction = function(data)
	if isRentExpired(data) then
		return Notify('Tiền thuê của bạn đã đến hạn.', 'error')
	end

	local pedData = lib.callback.await('renzu_motels:getPed', false)

	-- Không có ped đặc biệt trong SQL
	if not pedData or not pedData.ped_model then
		return Notify('Bạn không có ped đặc biệt', 'inform')
	end

	-- Kiểm tra player có đang dùng ped mod không
	local currentModel = GetEntityModel(PlayerPedId())
	local isUsingPedMod = currentModel == GetHashKey(pedData.ped_model)

	local options = {}

	if isUsingPedMod then
		-- Đang dùng ped mod → cho đổi về mặc định
		table.insert(options, {
			title = 'Đổi về nhân vật mặc định',
			description = 'Trở về ped mặc định của nhân vật',
			icon = 'fas fa-undo',
			onSelect = function()
				-- Lấy appearance mặc định từ playerskins
				local defaultRow = lib.callback.await('renzu_motels:getDefaultAppearance', false)
				if not defaultRow or not defaultRow.model then
					TriggerServerEvent('renzu_motels:resetPed')
					return Notify('Không tìm thấy dữ liệu mặc định. Vui lòng reconnect để áp dụng.', 'inform')
				end

				-- Đổi model về freemode đúng giới tính
				local model = GetHashKey(defaultRow.model)
				RequestModel(model)
				while not HasModelLoaded(model) do Wait(100) end
				SetPlayerModel(PlayerId(), model)
				SetModelAsNoLongerNeeded(model)

				-- Áp dụng skin từ playerskins bằng natives (format: component_id/drawable/texture)
				local skin = defaultRow.skin and json.decode(defaultRow.skin) or nil
				if skin then
					local ped = PlayerPedId()

					-- Components
					if skin.components then
						for _, comp in ipairs(skin.components) do
							SetPedComponentVariation(ped, comp.component_id, comp.drawable or 0, comp.texture or 0, 0)
						end
					end

					-- Props
					if skin.props then
						for _, prop in ipairs(skin.props) do
							if prop.drawable == -1 then
								ClearPedProp(ped, prop.prop_id)
							else
								SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture or 0, true)
							end
						end
					end

					-- HeadBlend (chỉ cho freemode)
					if skin.headBlend then
						local hb = skin.headBlend
						SetPedHeadBlendData(ped,
							hb.shapeFirst or 0, hb.shapeSecond or 0, hb.shapeThird or 0,
							hb.skinFirst  or 0, hb.skinSecond  or 0, hb.skinThird  or 0,
							hb.shapeMix   or 0, hb.skinMix     or 0, hb.thirdMix   or 0,
							false
						)
					end

					-- Hair
					if skin.hair then
						SetPedHairColor(ped, skin.hair.color or 0, skin.hair.highlight or 0)
					end

					-- Eye color
					if skin.eyeColor and skin.eyeColor >= 0 then
						SetPedEyeColor(ped, skin.eyeColor)
					end

					-- Head overlays
					if skin.headOverlays then
						local overlayMap = {
							blemishes       = 0, facialHair = 1, eyebrows = 2,
							ageing          = 3, makeUp     = 4, blush    = 5,
							complexion      = 6, sunDamage  = 7, lipstick = 8,
							moleAndFreckles = 9, chestHair  = 10, bodyBlemishes = 11,
						}
						for name, idx in pairs(overlayMap) do
							local o = skin.headOverlays[name]
							if o then
								SetPedHeadOverlay(ped, idx, o.style or 0, o.opacity or 0)
								SetPedHeadOverlayColor(ped, idx, 1, o.color or 0, o.secondColor or 0)
							end
						end
					end

					-- Lưu lại vào illenium-appearance để giữ khi reconnect
					TriggerServerEvent('illenium-appearance:server:saveAppearance', skin)
				end

				-- KHÔNG xóa motel_ped để player có thể đổi lại
				Notify('Đã đổi về nhân vật mặc định (' .. defaultRow.model .. ')', 'success')

				-- Sau 1s reload lại quần áo mặc định
				SetTimeout(1000, function()
					TriggerServerEvent('clothes:reloadPlayerClothes')
				end)
			end
		})
	else
		-- Có ped mod nhưng chưa dùng → cho đổi sang ped mod
		table.insert(options, {
			title = 'Đổi sang: ' .. pedData.ped_model,
			description = 'Áp dụng nhân vật đặc biệt được gán cho bạn',
			icon = 'fas fa-user-check',
			onSelect = function()
				local model = GetHashKey(pedData.ped_model)
				RequestModel(model)
				while not HasModelLoaded(model) do Wait(100) end
				SetPlayerModel(PlayerId(), model)
				SetModelAsNoLongerNeeded(model)

				local ped = PlayerPedId()
				for i = 0, 11 do
					SetPedComponentVariation(ped, i, pedData['comp'..i] or 0, pedData['tex'..i] or 0, 0)
				end
				for i = 0, 2 do ClearPedProp(ped, i) end
				ClearPedProp(ped, 6) ; ClearPedProp(ped, 7)

				-- Lưu vào illenium-appearance để giữ khi reconnect
				lib.callback('illenium-appearance:server:getAppearance', false, function(appearance)
					if not appearance then appearance = {} end
					appearance.model        = pedData.ped_model
					appearance.headBlend    = nil
					appearance.faceFeatures = nil
					appearance.headOverlays = nil
					appearance.hair         = nil
					appearance.tattoos      = nil
					local components = {}
					for i = 0, 11 do
						components[i + 1] = {
							componentId = i,
							drawableId  = pedData['comp'..i] or 0,
							textureId   = pedData['tex'..i]  or 0,
							paletteId   = 0,
						}
					end
					appearance.components = components
					appearance.props = {
						{ propId = 0, drawableId = -1, textureId = -1 },
						{ propId = 1, drawableId = -1, textureId = -1 },
						{ propId = 2, drawableId = -1, textureId = -1 },
						{ propId = 6, drawableId = -1, textureId = -1 },
						{ propId = 7, drawableId = -1, textureId = -1 },
					}
					TriggerServerEvent('illenium-appearance:server:saveAppearance', appearance)
				end)

				Notify('Đã đổi sang nhân vật: ' .. pedData.ped_model, 'success')

				-- Sau 1s reload lại quần áo
				SetTimeout(1000, function()
					TriggerServerEvent('clothes:reloadPlayerClothes')
				end)
			end
		})
	end

	lib.registerContext({
		id      = 'changePed_menu',
		title   = 'Thay đổi ngoại hình nhân vật',
		options = options,
	})
	lib.showContext('changePed_menu')
end

LockPick = function(data)
	local success = nil
	SetTimeout(1000,function()
		repeat
		local lockpick = lib.progressBar({
			duration = 10000,
			label = 'Breaking in..',
			useWhileDead = false,
			canCancel = true,
			anim = {
				dict = 'veh@break_in@0h@p_m_one@',
				clip = 'low_force_entry_ds' 
			},
		})
		Wait(0)
		until success ~= nil
	end)
	success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'easy'})
	if lib.progressActive() then
		lib.cancelProgress()
	end
	if success then
		TriggerServerEvent('renzu_motels:Door', {
            motel = data.motel,
            index = data.index,
			doorindex = data.doorindex,
            coord = data.coord,
			Mlo = data.Mlo
        })
		local doorindex = data.index + (joaat(data.motel))
		Notify(DoorSystemGetDoorState(doorindex) == 0 and 'Bạn đã khóa cửa nhà nghỉ' or 'Bạn đã mở khóa cửa nhà nghỉ', 'inform')
	end
end

Notify = function(msg,type)
	lib.notify({
		description = msg,
		type = type or 'inform'
	})
end

MyRoomMenu = function(data)
	local motels = GlobalState.Motels
	local rate = motels[data.motel].hour_rate or data.rate

	local options = {
		{
			title = 'Phòng của tôi ['..data.index..'] - Trả tiền thuê nhà',
			description = 'Trả tiền thuê nhà của bạn đến hạn hoặc nâng cao đến cửa '..data.index..' \n Thời gian thuê: '..data.duration..' \n '..data.rental_period..' Tỷ lệ: $ '..rate,
			icon = 'money-bill-wave-alt',
			onSelect = function()
				local input = lib.inputDialog('Thanh toán hoặc gửi tiền cho nhà nghỉ', {
					{type = 'number', label = 'Số tiền để ký gửi', description = '$ '..rate..' per '..data.rental_period..'  \n  Phương thức thanh toán: '..data.payment, icon = 'money', default = rate},
				})
				if not input then return end
				local success = lib.callback.await('renzu_motels:payrent',false,{
					payment = data.payment,
					index = data.index,
					motel = data.motel,
					amount = input[1],
					rate = rate,
					rental_period = data.rental_period
				})
				if success then
					Notify('Trả thành công tiền thuê nhà', 'success')
				else
					Notify('Không trả tiền thuê nhà', 'error')
				end
			end,
			arrow = true,
		},
		{
			title = 'Generate Key Item',
			description = 'Request a Door Key',
			icon = 'key',
			onSelect = function()
				local success = lib.callback.await('renzu_motels:motelkey',false,{
					index = data.index,
					motel = data.motel,
				})
				if success then
					Notify('Yêu cầu thành công một khóa nhà trọ có thể chia sẻ', 'success')
				else
					Notify('Không tạo khóa', 'error')
				end
			end,
			arrow = true,
		},
		{
			title = 'End Rent',
			description = 'End your rental period',
			icon = 'ban',
			onSelect = function()
				if isRentExpired(data) then
					Notify('Không thể kết thúc tiền thuê nhà '..data.index..'  \n  Reason: your have a Balance Debt to pay','error')
					return
				end
				local End = lib.alertDialog({
					header = '## Warning',
					content = ' Bạn sẽ không còn có quyền truy cập vào cửa và vào két sắt của bạn.',
					centered = true,
					labels = {
						cancel = 'đóng',
						confirm = 'Kết thúc',
					},
					cancel = true
				})
				if End == 'cancel' then return end
				local success = lib.callback.await('renzu_motels:removeoccupant',false,data,data.index,PlayerData.identifier)
				if success then
					Notify('Kết thúc thành công tiền thuê nhà của bạn vào phòng '..data.index,'success')
				else
					Notify('Không thể kết thúc tiền thuê nhà '..data.index,'error')
				end
			end,
			arrow = true,
		},
	}
	lib.registerContext({
        id = 'myroom',
		menu = 'roomlist',
        title = 'Tùy chọn phòng nhà nghỉ của tôi',
        options = options
    })
	lib.showContext('myroom')
end

CountOccupants = function(players)
	local count = 0
	for k,v in pairs(players or {}) do
		count += 1
	end
	return count
end

RoomList = function(data)
	local motels , time, maxRentDays = lib.callback.await('renzu_motels:getMotels', false, { motel = data.motel })
	if maxRentDays then maxRentDaysLimit = maxRentDays end
	local rate = motels[data.motel].hour_rate or data.rate
	local options = {}
	--local motels = GlobalState.Motels
	for doorindex,v in ipairs(data.doors) do
		local playerroom = motels[data.motel].rooms[doorindex].players[PlayerData.identifier]
		local duration = playerroom?.duration
		local occupants = CountOccupants(motels[data.motel].rooms[doorindex].players)
		if occupants < data.maxoccupants and not duration then
			table.insert(options,{
				title = 'Thuê phòng trọ #'..doorindex,
				description = 'Chọn phòng #'..doorindex..' \n Số người: '..occupants..'/'..data.maxoccupants,
				icon = 'door-closed',
				onSelect = function()
					local input = lib.inputDialog('Thời gian thuê', {
						{type = 'number', label = 'Chọn thời gian trong '..data.rental_period..'s', description = '$ '..rate..' mỗi '..data.rental_period..'   \n   Phương thức thanh toán: '..data.payment, icon = 'clock', default = 1},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:rentaroom',false,{
						index = doorindex,
						motel = data.motel,
						duration = input[1],
						rate = rate,
						rental_period = data.rental_period,
						payment = data.payment,
						uniquestash = data.uniquestash
					})
					if success == 'hasroom' then
						Notify('Bạn đã có một phòng trọ rồi. Mỗi người chỉ được sở hữu một phòng duy nhất!', 'error')
					elseif success then
						Notify('Thuê thành công một phòng', 'success')
					else
						Notify('Không thuê phòng', 'error')
					end
				end,
				arrow = true,
			})
		elseif duration then
			local hour = math.floor((duration - time) / 3600)
			local duration_left = hour .. ' Hours : '..math.floor(((duration - time) / 60) - (60 * hour))..' Minutes'
			table.insert(options,{
				title = 'My Room Door #'..doorindex..' Options',
				description = 'Pay your rent or request a motel key',
				icon = 'cog',
				onSelect = function()
					return MyRoomMenu({
						payment = data.payment,
						index = doorindex,
						motel = data.motel,
						duration = duration_left,
						rate = rate,
						rental_period = data.rental_period
					})
				end,
				arrow = true,
			})
		end
	end
    lib.registerContext({
        id = 'roomlist',
		menu = 'rentmenu',
        title = 'Chọn một phòng',
        options = options
    })
	lib.showContext('roomlist')
end

IsOwnerOrEmployee = function(motel)
	local motels = GlobalState.Motels
	if not motels or not motels[motel] or not PlayerData or not PlayerData.identifier then
		if config.debug then
			print('^1[DEBUG] IsOwnerOrEmployee - Missing data:^7')
			print('  Motels: ' .. tostring(motels ~= nil))
			print('  Motel exists: ' .. tostring(motels and motels[motel] ~= nil))
			print('  PlayerData: ' .. tostring(PlayerData ~= nil))
			print('  PlayerData.identifier: ' .. tostring(PlayerData and PlayerData.identifier))
		end
		return false
	end
	
	local isOwner = motels[motel].owned == PlayerData.identifier
	local employees = motels[motel].employees or {}
	local isEmployee = employees[PlayerData.identifier] ~= nil
	local result = isOwner or isEmployee
	
	if config.debug then
		print('^3[DEBUG] IsOwnerOrEmployee check:^7')
		print('  Motel: ' .. tostring(motel))
		print('  Player ID: ' .. tostring(PlayerData.identifier))
		print('  Motel Owner: ' .. tostring(motels[motel].owned))
		print('  Is Owner: ' .. tostring(isOwner))
		print('  Employees: ' .. json.encode(employees))
		print('  Is Employee: ' .. tostring(isEmployee))
		print('  Result: ' .. tostring(result))
	end
	
	return result
end

MotelRentalMenu = function(data)
	-- Open new modern UI (handles both tenant and owner)
	OpenMotelUI(data)
end

SendMessageApi = function(motel)
	local message = lib.alertDialog({
		header = 'Bạn có muốn nhắn tin cho chủ sở hữu không ?',
		content = '## Nhắn tin cho chủ sở hữu nhà nghỉ',
		centered = true,
		labels = {
			cancel = 'Đóng',
			confirm = 'Nhắn tin',
		},
		cancel = true
	})
	if message == 'cancel' then return end
	local input = lib.inputDialog('Message', {
		{type = 'input', label = 'Title', description = 'Tiêu đề của tin nhắn của bạn', icon = 'hash', required = true},
		{type = 'textarea', label = 'Sự miêu tả', description = 'Nội dung tin nhắn của bạn', icon = 'mail', required = true},
		{type = 'number', label = 'Số liên lạc', icon = 'phone', required = false},
	})
	
	config.messageApi({title = input[1], message = input[2], motel = motel})
end

Owner = {}
Owner.Rooms = {}
Owner.Rooms.Occupants = function(data,index)
	local motels , time, maxRentDays = lib.callback.await('renzu_motels:getMotels', false, { motel = data.motel })
	if maxRentDays then maxRentDaysLimit = maxRentDays end
	local motel = motels[data.motel]
	local players = motel.rooms[index] and motel.rooms[index].players or {}
	local options = {}
	for player,char in pairs(players) do
		local hour = math.floor((char.duration - time) / 3600)
		local name = char.name or 'No Name'
		local duration_left = hour .. ' Hours : '..math.floor(((char.duration - time) / 60) - (60 * hour))..' Minutes'
		table.insert(options,{
			title = 'Occupant '..name,
			description = 'Thời gian thuê: '..duration_left,
			icon = 'hotel',
			onSelect = function()
				local kick = lib.alertDialog({
					header = 'Confirmation',
					content = '## Kick Occupant \n  **Name:** '..name,
					centered = true,
					labels = {
						cancel = 'Đóng',
						confirm = 'Kick',
						waw = 'waw'
					},
					cancel = true
				})
				if kick == 'cancel' then return end
				local success = lib.callback.await('renzu_motels:removeoccupant',false,data,index,player)
				if success then
					Notify('Đá thành công '..name..' from room '..index,'success')
				else
					Notify('Thất bại để đá '..name..' from room '..index,'error')
				end
			end,
			arrow = true,
		})
	end
	if data.maxoccupants > #options then
		for i = 1, data.maxoccupants-#options do
			table.insert(options,{
				title = 'Vacant Slot ',
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('New Occupant', {
						{type = 'number', label = 'PID (Player ID)', description = 'PID của người chơi (VD: 1234)', icon = 'id-card', required = true},
						{type = 'number', label = 'Chọn một thời lượng trong '..data.rental_period..'s', description = 'bao nhiêu '..data.rental_period..'s', icon = 'clock', default = 1},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:addoccupant',false,data,index,input)
					if success == 'exist' then
						Notify('Đã tồn tại từ phòng '..index,'error')
					elseif success == 'hasroom' then
						Notify('Người chơi đã có một phòng trọ rồi. Mỗi người chỉ được sở hữu một phòng!','error')
					elseif success == 'declined' then
						Notify('Người chơi đã từ chối thuê phòng','error')
					elseif success == 'nomoney' then
						Notify('Người chơi không đủ tiền để thuê phòng','error')
					elseif success then
						Notify('Thêm thành công '..input[1]..' vào phòng '..index,'success')
					else
						Notify('Failed to Add '..input[1]..' from room '..index,'error')
					end
				end,
				arrow = true,
			})
		end
	end
	lib.registerContext({
		menu = 'owner_rooms',
        id = 'occupants_lists',
        title = 'Room #'..index..' Người cư ngụ',
        options = options
    })
	lib.showContext('occupants_lists')
end

Owner.Rooms.List = function(data)
	local motels = GlobalState.Motels
	local options = {}
	for doorindex,v in ipairs(data.doors) do
		local occupants = CountOccupants(motels[data.motel].rooms[doorindex].players)
		table.insert(options,{
			title = 'Room #'..doorindex,
			description = 'Thêm hoặc đá người cư ngụ từ phòng #'..doorindex..' \n ***Occupants:*** '..occupants,
			icon = 'hotel',
			onSelect = function()
				return Owner.Rooms.Occupants(data,doorindex)
			end,
			arrow = true,
		})
	end
	lib.registerContext({
		menu = 'motelmenu',
        id = 'owner_rooms',
        title = data.label,
        options = options
    })
	lib.showContext('owner_rooms')
end

Owner.Employee = {}
Owner.Employee.Manage = function(data)
	local motel = GlobalState.Motels[data.motel]
	local options = {
		{
			title = 'Thêm nhân viên',
			description = 'Thêm công dân gần đó vào nhân viên nhà nghỉ của bạn',
			icon = 'hotel',
			onSelect = function()
				local input = lib.inputDialog('Add Employee', {
					{type = 'number', label = 'PID (Player ID)', description = 'PID của người chơi (VD: 1234)', icon = 'id-card', required = true},
				})
				if not input then return end
				local success = lib.callback.await('renzu_motels:addemployee',false,data.motel,input[1])
				if success then
					Notify('Thêm thành công vào danh sách nhân viên','success')
				else
					Notify('Không thể thêm vào nhân viên','error')
				end
			end,
			arrow = true,
		}
	}
    if motel and motel.employees then
       for identifier,name in pairs(motel.employees) do
          table.insert(options,{
			title = name,
			description = 'remove '..name..' to your Employee Lists',
			icon = 'hotel',
			onSelect = function()
				local success = lib.callback.await('renzu_motels:removeemployee',false,data.motel,identifier)
					if success then
						Notify('Hủy bỏ thành công khỏi danh sách nhân viên','success')
					else
						Notify('Không thể loại bỏ khỏi nhân viên','error')
					end
			end,
			arrow = true,
		})
	   end
	end
	lib.registerContext({
        id = 'employee_manage',
        title = 'Quản lý nhân viên',
        options = options
    })
	lib.showContext('employee_manage')
end

MotelOwner = function(data)
	local motels = GlobalState.Motels
	if not motels[data.motel].owned then
		local buy = lib.alertDialog({
			header = data.label,
			content = '![motel](nui://renzu_motels/data/image/'..data.motel..'.png) \n ## INFO \n **Rooms:** '..#data.doors..'  \n  **Người cư ngụ tối đa:** '..#data.doors * data.maxoccupants..'  \n  **Giá:** $'..data.businessprice,
			centered = true,
			labels = {
				cancel = 'close',
				confirm = 'buy'
			},
			cancel = true
		})
		if buy ~= 'cancel' then
			local success = lib.callback.await('renzu_motels:buymotel',false,data)
			if success then
				Notify('You Successfully buy the motel','success')
			else
				Notify('Fail to buy the motel','error')
			end
		end
	elseif IsOwnerOrEmployee(data.motel) then
		local revenue = motels[data.motel].revenue or 0
		local rate = motels[data.motel].hour_rate or data.rate
		local options = {
			{
				title = 'Phòng trọ',
				description = 'Thêm hoặc đá người cư ngụ',
				icon = 'hotel',
				onSelect = function()
					return Owner.Rooms.List(data)
				end,
				arrow = true,
			},
			{
				title = 'Gửi hóa đơn',
				description = 'Hóa đơn những công dân gần đó',
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Send Invoice', {
						{type = 'number', label = 'PID (Player ID)', description = 'PID của người chơi (VD: 1234)', icon = 'money', required = true},
						{type = 'number', label = 'Amount', description = 'total amount to request', icon = 'money', required = true},
						{type = 'input', label = 'Describe', description = 'Description of Invoice', icon = 'info'},
						{type = 'checkbox', label = 'Payment Bank'},
					})
					if not input then return end
					Notify('You Successfully Send the Invoice to '..input[1],'success')
					local success = lib.callback.await('renzu_motels:sendinvoice',false,data.motel,input)
					if success then
						Notify('Invoice has been paid','success')
					else
						Notify('Invoice is not paid','error')
					end
				end,
				arrow = true,
			}
		}
		if motels[data.motel].owned == PlayerData.identifier then
			table.insert(options,{
				title = 'Điều chỉnh tỷ lệ giờ',
				description = 'Modify current '..data.rental_period..' rates. \n '..data.rental_period..' Rates: '..rate,
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Edit '..data.rental_period..' Rate', {
						{type = 'number', label = 'Rate', description = 'Rate per '..data.rental_period..'', icon = 'money', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:editrate',false,data.motel,input[1])
					if success then
						Notify('Bạn thay đổi thành công '..data.rental_period..' Rate','success')
					else
						Notify('Không sửa đổi','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Doanh thu nhà nghỉ',
				description = 'Tổng cộng: '..revenue,
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Withdraw Funds', {
						{type = 'number', label = 'Số tiền quỹ', icon = 'money', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:withdrawfund',false,data.motel,input[1])
					if success then
						Notify('Bạn rút tiền thành công','success')
					else
						Notify('Không rút tiền','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Quản lý nhân viên',
				description = 'Thêm / xóa nhân viên',
				icon = 'hotel',
				onSelect = function()
					return Owner.Employee.Manage(data)
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Quyền sở hữu chuyển nhượng',
				description = 'Chuyển sang các công dân gần đó',
				icon = 'hotel',
				onSelect = function()
					local input = lib.inputDialog('Chuyển nhà trọ', {
						{type = 'number', label = 'PID (Player ID)', description = 'PID của người chơi (VD: 1234)', icon = 'id-card', required = true},
					})
					if not input then return end
					local success = lib.callback.await('renzu_motels:transfermotel',false,data.motel,input[1])
					if success then
						Notify('Chuyển giao quyền sở hữu Motel thành công','success')
					else
						Notify('Không chuyển giao','error')
					end
				end,
				arrow = true,
			})
			table.insert(options,{
				title = 'Bán nhà trọ',
				description = 'Bán Motel với giá một nửa',
				icon = 'hotel',
				onSelect = function()
					local sell = lib.alertDialog({
						header = data.label,
						content = '![motel](nui://renzu_motels/data/image/'..data.motel..'.png) \n ## INFO \n  **Selling Value:** $'..data.businessprice / 2,
						centered = true,
						labels = {
							cancel = 'close',
							confirm = 'Sell'
						},
						cancel = true
					})
					if sell ~= 'cancel' then
						local success = lib.callback.await('renzu_motels:sellmotel',false,data)
						if success then
							Notify('Bạn bán thành công nhà trọ','success')
						else
							Notify('Không bán được nhà nghỉ','error')
						end
					end
				end,
				arrow = true,
			})
		end
		lib.registerContext({
			id = 'motelmenu',
			menu = 'rentmenu',
			title = data.label,
			options = options
		})
		lib.showContext('motelmenu')
	end
end

-- =============================================
-- Tính năng phòng ngủ nhanh mặc định (Quick Sleep)
-- =============================================
local function EnterQuickSleep(data)
	local motelName = data.motel
	local quickCfg = data.quickSleep or config.quickSleep or {}
	local price = quickCfg.price or 1500

	local alert = lib.alertDialog({
		header = 'Nghỉ ngơi nhanh',
		content = ('Bạn có muốn trả **$%s** để vào phòng nghỉ ngơi (ngủ) tại khách sạn **%s** không? (Hồi phục tối đa 50%% năng lượng)'):format(price, data.label or motelName),
		centered = true,
		cancel = true,
		labels = {
			confirm = 'Vào phòng ($' .. price .. ')',
			cancel = 'Hủy'
		}
	})

	if alert ~= 'confirm' then return end

	local success, result = lib.callback.await('renzu_motels:enterQuickSleep', false, motelName)
	if not success then
		if result == 'not_enough_money' then
			Notify('Bạn không có đủ $' .. price .. ' để vào phòng nghỉ ngơi!', 'error')
		else
			Notify('Không thể vào phòng nghỉ ngơi lúc này!', 'error')
		end
		return
	end

	Notify('Đã thanh toán $' .. price .. ' và vào phòng nghỉ ngơi.', 'success')

	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelName then
			motelConfig = v
			break
		end
	end

	local enterData = {
		motel = motelName,
		index = 0,
		isQuickSleep = true,
		shell = (result and result.shell) or (motelConfig and motelConfig.shell) or 'standard',
		Mlo = false,
		coord = vec3(150.0, -150.0, 1500.0),
		lastloc = GetEntityCoords(PlayerPedId())
	}

	SendNUIMessage({
		type = "playsound",
		content = {
			file = 'door',
			volume = 0.5
		}
	})

	EnterShell(enterData)
end

MotelRentalPoints = function(data)
    -- Get NPC config or use default
    local npcConfig = data.npc or {
        model = `a_m_m_business_01`,
        heading = 180.0
    }
    
    -- Spawn NPC at rental location
    local model = npcConfig.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(100)
    end
    
    local npc = CreatePed(4, model, data.rentcoord.x, data.rentcoord.y, data.rentcoord.z - 1.0, npcConfig.heading or 180.0, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedFleeAttributes(npc, 0, 0)
    SetPedDiesWhenInjured(npc, false)
    SetPedCanPlayAmbientAnims(npc, true)
    SetPedCanRagdollFromPlayerImpact(npc, false)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    
    -- Add target to NPC
    local targetOptions = {
        {
            name = 'motel_rental_' .. data.motel,
            icon = 'fas fa-hotel',
            label = 'Thuê phòng trọ - ' .. data.label,
			items = data.items_boss,
            onSelect = function()
                MotelRentalMenu(data)
            end
        },
        {
            name = 'motel_storage_' .. data.motel,
            icon = 'fas fa-box-open',
            label = 'Mở Kho ký gửi phòng trọ',
            onSelect = function()
                TriggerServerEvent('renzu_motels:server:openStorageStash', data.motel)
            end
        }
    }

    -- Option: Phòng ngủ nhanh mặc định
    local quickCfg = data.quickSleep or config.quickSleep or {}
    if quickCfg.enabled ~= false then
        local quickPrice = quickCfg.price or 1500
        table.insert(targetOptions, {
            name = 'motel_quicksleep_' .. data.motel,
            icon = 'fas fa-bed',
            label = 'Nghỉ ngơi nhanh ($' .. tostring(quickPrice) .. ')',
            onSelect = function()
                EnterQuickSleep(data)
            end
        })
    end

    -- Thêm target vào công ty nếu được bật
    if data.office and data.office.enabled then
        table.insert(targetOptions, {
            name = 'motel_office_' .. data.motel,
            icon = 'fas fa-building',
            label = 'Vào Công Ty - ' .. (data.office.label or data.label),
            onSelect = function()
                EnterOffice(data.motel, data.office.label or data.label)
            end
        })
    end

    -- Use appropriate target system
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(npc, targetOptions)
    elseif GetResourceState('qb-target') == 'started' then
        local qbOptions = {
            {
                type = "client",
                action = function() MotelRentalMenu(data) end,
                icon = 'fas fa-hotel',
                label = 'Thuê phòng trọ - ' .. data.label,
            },
            {
                type = "client",
                action = function() TriggerServerEvent('renzu_motels:server:openStorageStash', data.motel) end,
                icon = 'fas fa-box-open',
                label = 'Mở Kho ký gửi phòng trọ',
            }
        }
        if quickCfg.enabled ~= false then
            local quickPrice = quickCfg.price or 1500
            table.insert(qbOptions, {
                type = "client",
                action = function() EnterQuickSleep(data) end,
                icon = 'fas fa-bed',
                label = 'Nghỉ ngơi nhanh ($' .. tostring(quickPrice) .. ')',
            })
        end
        if data.office and data.office.enabled then
            table.insert(qbOptions, {
                type = "client",
                action = function() EnterOffice(data.motel, data.office.label or data.label) end,
                icon = 'fas fa-building',
                label = 'Vào Công Ty - ' .. (data.office.label or data.label),
            })
        end
        exports['qb-target']:AddTargetEntity(npc, {
            options = qbOptions,
            distance = 2.0
        })
    end
    
    return {
        npc = npc,
        remove = function()
            if DoesEntityExist(npc) then
                if GetResourceState('ox_target') == 'started' then
                    exports.ox_target:removeLocalEntity(npc)
                elseif GetResourceState('qb-target') == 'started' then
                    exports['qb-target']:RemoveTargetEntity(npc)
                end
                DeleteEntity(npc)
            end
        end
    }
end

-- =============================================
-- Tính năng công ty (Office)
-- =============================================
local officeLastLocation = nil
local officeExitPoint = nil
local officeLockerPoint = nil

-- Translation tables for clothes component and props
local componentIdTranslation = {
	["mask"] = 1,
	["arms"] = 3,
	["pants"] = 4,
	["bag"] = 5,
	["shoes"] = 6,
	["t-shirt"] = 8,
	["torso"] = 11,
	["decals"] = 10,
	["kevlar"] = 9,
}

local propIdTranslation = {
	["hat"] = 0,
	["helmet"] = 0,
	["glasses"] = 1,
	["ears"] = 2,
	["watch"] = 6,
	["bracelet"] = 7
}

EnterOffice = function(motelId, officeLabel)
	TriggerServerEvent('renzu_motels:enterOffice', motelId)
end

RegisterNetEvent('renzu_motels:officeEnterConfirmed', function(coord)
	DoScreenFadeOut(500)
	while not IsScreenFadedOut() do Wait(10) end
	officeLastLocation = GetEntityCoords(cache.ped)
	SetEntityCoords(cache.ped, coord.x, coord.y, coord.z, false, false, false, false)
	Wait(500)
	DoScreenFadeIn(500)
	Notify('Đã vào' .. (coord.label and (' ' .. coord.label) or ' công ty'), 'success')

	-- Tạo điểm thoát công ty
	if officeExitPoint then
		officeExitPoint:remove()
		officeExitPoint = nil
	end
	officeExitPoint = lib.points.new({
		coords = vec3(coord.x, coord.y, coord.z),
		distance = 3.0,
	})
	function officeExitPoint:onEnter()
		lib.showTextUI('[E] - Rời công ty')
	end
	function officeExitPoint:onExit()
		lib.hideTextUI()
	end
	function officeExitPoint:nearby()
		if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then
			lib.hideTextUI()
			DoScreenFadeOut(500)
			while not IsScreenFadedOut() do Wait(10) end
			TriggerServerEvent('renzu_motels:exitOffice')
		end
	end

	-- Tạo điểm thay đồ công ty
	local motelId = coord.motelId
	local motelCfg = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelId then motelCfg = v break end
	end

	if motelCfg and motelCfg.office and motelCfg.office.enabled then
		local lockerCoord = motelCfg.office.locker or vec3(-138.2, -623.5, 168.82) -- Tủ CEO mặc định
		
		if officeLockerPoint then
			officeLockerPoint:remove()
			officeLockerPoint = nil
		end
		
		officeLockerPoint = lib.points.new({
			coords = lockerCoord,
			distance = 3.0,
		})
		
		function officeLockerPoint:onEnter()
			-- Kiểm tra xem người chơi có quyền không
			local motels = GlobalState.Motels
			local motelData = motels[motelId]
			if motelData then
				local identifier = PlayerData?.identifier
				local isOwner = motelData.owned == identifier
				local employees = motelData.employees or {}
				local isEmployee = employees[identifier] ~= nil
				if isOwner or isEmployee then
					lib.showTextUI('[E] - Tủ đồ công ty')
				end
			end
		end
		
		function officeLockerPoint:onExit()
			lib.hideTextUI()
		end
		
		function officeLockerPoint:nearby()
			if self.currentDistance < 1.5 and IsControlJustReleased(0, 38) then
				lib.hideTextUI()
				OpenLockerMenu(motelId)
			end
		end
	end
end)

RegisterNetEvent('renzu_motels:officeExitConfirmed', function()
	if officeLastLocation then
		SetEntityCoords(cache.ped, officeLastLocation.x, officeLastLocation.y, officeLastLocation.z, false, false, false, false)
	end
	Wait(500)
	DoScreenFadeIn(500)
	Notify('Đã rời công ty', 'success')
	if officeExitPoint then
		officeExitPoint:remove()
		officeExitPoint = nil
	end
	if officeLockerPoint then
		officeLockerPoint:remove()
		officeLockerPoint = nil
	end
	officeLastLocation = nil
end)

PlayChangeClothesAnimation = function()
	RequestAnimDict("clothingshirt")
	while not HasAnimDictLoaded("clothingshirt") do Wait(10) end
	local ped = PlayerPedId()
	TaskPlayAnim(ped, "clothingshirt", "try_shirt_positive_d", 8.0, 1.0, -1, 49, 0, false, false, false)
	Wait(1000)
	ClearPedTasks(ped)
end

RestoreCitizenClothes = function()
	PlayChangeClothesAnimation()

	if QBCORE then
		TriggerServerEvent('qb-clothes:loadPlayerSkin')
	elseif ESX then
		ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
			TriggerEvent('skinchanger:loadSkin', skin)
		end)
	end

	-- Trigger appearance events
	TriggerEvent("fivem-appearance:client:reloadSkin")
	TriggerEvent("fivem-appearance:ReloadSkin")
	TriggerEvent("illenium-appearance:client:reloadSkin")
	TriggerEvent("illenium-appearance:ReloadSkin")
	TriggerEvent("qb-clothing:client:loadPlayerSkin")

	Notify('Đã mặc lại trang phục thường dân', 'success')
end

ApplyWorkClothes = function(motelId, role)
	local motelCfg = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelId then motelCfg = v break end
	end
	if not motelCfg or not motelCfg.clothes or not motelCfg.clothes[role] then
		Notify('Không tìm thấy cấu hình trang phục cho chức vụ này!', 'error')
		return
	end

	local clothesConfig = motelCfg.clothes[role]
	local ped = PlayerPedId()
	local currentModel = GetEntityModel(ped)
	local isMale = currentModel == `mp_m_freemode_01`
	local isFemale = currentModel == `mp_f_freemode_01`

	if not isMale and not isFemale then
		Notify('Bạn phải sử dụng nhân vật mặc định (Freemode) mới có thể thay trang phục làm việc!', 'error')
		return
	end

	local genderConfig = isMale and clothesConfig.male or clothesConfig.female
	if not genderConfig then
		Notify('Không có trang phục phù hợp với giới tính của bạn!', 'error')
		return
	end

	PlayChangeClothesAnimation()

	-- Clear props before applying
	for _, propId in pairs(propIdTranslation) do
		ClearPedProp(ped, propId)
	end

	-- Apply components
	for compName, compData in pairs(genderConfig) do
		local componentId = componentIdTranslation[compName]
		if componentId then
			SetPedComponentVariation(ped, componentId, compData.clotheId or compData.drawable or 0, compData.variation or compData.texture or 0, 0)
		else
			local propId = propIdTranslation[compName]
			if propId then
				SetPedPropIndex(ped, propId, compData.clotheId or compData.drawable or 0, compData.variation or compData.texture or 0, true)
			end
		end
	end

	-- Apply props outside male/female tables (17mov_BuilderJob format: maleHelmet, femaleHelmet)
	for propName, propData in pairs(clothesConfig) do
		if propName == (isMale and 'maleHelmet' or 'femaleHelmet') or propName == (isMale and 'maleHat' or 'femaleHat') then
			SetPedPropIndex(ped, 0, propData.clotheId or propData.drawable or 0, propData.variation or propData.texture or 0, true)
		elseif propName == (isMale and 'maleGlasses' or 'femaleGlasses') then
			SetPedPropIndex(ped, 1, propData.clotheId or propData.drawable or 0, propData.variation or propData.texture or 0, true)
		end
	end
	
	Notify('Đã thay trang phục làm việc', 'success')
end

OpenLockerMenu = function(motelId)
	local motels = GlobalState.Motels
	local motelData = motels[motelId]
	if not motelData then return end
	
	local identifier = PlayerData?.identifier
	local isOwner = motelData.owned == identifier
	local employees = motelData.employees or {}
	local isEmployee = employees[identifier] ~= nil
	local employeeGrade = 0
	if isEmployee then
		local empInfo = employees[identifier]
		employeeGrade = type(empInfo) == 'table' and (empInfo.grade or 1) or 1
	end

	if not isOwner and not isEmployee then
		Notify('Bạn không phải nhân viên của công ty này!', 'error')
		return
	end

	local motelCfg = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelId then motelCfg = v break end
	end
	if not motelCfg then return end

	local options = {
		{
			title = 'Trang phục thường dân',
			description = 'Mặc lại trang phục thường ngày của bạn',
			icon = 'fas fa-tshirt',
			onSelect = function()
				RestoreCitizenClothes()
			end
		}
	}

	if motelCfg.clothes then
		-- Quét dọn (Grade >= 1 hoặc Owner)
		if isOwner or employeeGrade >= 1 then
			if motelCfg.clothes['quet_don'] then
				table.insert(options, {
					title = 'Trang phục Quét dọn',
					description = 'Thay trang phục dọn dẹp vệ sinh',
					icon = 'fas fa-broom',
					onSelect = function()
						ApplyWorkClothes(motelId, 'quet_don')
					end
				})
			end
		end

		-- Nhân viên (Grade >= 2 hoặc Owner)
		if isOwner or employeeGrade >= 2 then
			if motelCfg.clothes['nhan_vien'] then
				table.insert(options, {
					title = 'Trang phục Nhân viên',
					description = 'Thay trang phục nhân viên khách sạn',
					icon = 'fas fa-user-tie',
					onSelect = function()
						ApplyWorkClothes(motelId, 'nhan_vien')
					end
				})
			end
		end

		-- Quản lý (Grade >= 3 hoặc Owner)
		if isOwner or employeeGrade >= 3 then
			if motelCfg.clothes['quan_ly'] then
				table.insert(options, {
					title = 'Trang phục Quản lý',
					description = 'Thay trang phục quản lý khách sạn',
					icon = 'fas fa-briefcase',
					onSelect = function()
						ApplyWorkClothes(motelId, 'quan_ly')
					end
				})
			end
		end
	end

	lib.registerContext({
		id = 'office_locker_menu',
		title = 'Tủ Đồ Công Ty',
		options = options
	})
	lib.showContext('office_locker_menu')
end

local inMotelZone = false
local rentalPoints = {} -- Store rental points separately

-- Create motel rooms zone (must be near motel location)
MotelZone = function(data)
    function onEnter(self) 
		inMotelZone = true
		Citizen.CreateThreadNow(function()
			for index, doors in pairs(data.doors) do
				if type(doors) == 'table' then
					for type, door in pairs(doors) do
						if type == 'door' then
							for doorindex,v in pairs(door) do
								MotelFunction({
									payment = data.payment or 'money',
									uniquestash = data.uniquestash, 
									shell = data.shell, 
									Mlo = data.Mlo, 
									type = type, 
									index = index,
									doorindex = index + doorindex,
									coord = v.coord, 
									label = config.Text[type], 
									motel = data.motel, 
									door = v.model
								})
							end
						else
							MotelFunction({
								payment = data.payment or 'money',
								uniquestash = data.uniquestash, 
								shell = data.shell, 
								Mlo = data.Mlo, 
								type = type, 
								index = index, 
								coord = door, 
								label = config.Text[type], 
								motel = data.motel, 
								door = data.door
							})
						end
					end
				end
			end
		end)
	end

    function onExit(self)
		inMotelZone = false
		for k,id in pairs(zones) do
			removeTargetZone(id)
		end
		for k,id in pairs(blips) do
			if DoesBlipExist(id) then
				RemoveBlip(id)
			end
		end
		zones = {}
	end

    local sphere = lib.zones.sphere({
        coords = data.coord,
        radius = data.radius,
        debug = false,
        inside = inside,
        onEnter = onEnter,
        onExit = onExit
    })
end

--qb-interior func
--qb-interior func
local house
local inhouse = false
local spawnedTrash = {}
local isCleaningTrash = false
local isTextUIShown = false

function CleanTrashPile(data, entity, trashIndex)
	if isCleaningTrash then return end
	isCleaningTrash = true
	if isTextUIShown then
		lib.hideTextUI()
		isTextUIShown = false
	end

	local success = lib.progressBar({
		duration = 4000,
		label = 'Đang dọn dẹp rác..',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = true,
			move = true,
			combat = true
		},
		anim = {
			dict = 'amb@world_human_janitor@male@idle_a',
			clip = 'idle_a'
		},
		prop = {
			model = 'prop_tool_broom',
			bone = 28422,
			pos = vec3(0.0, 0.0, 0.0),
			rot = vec3(0.0, 0.0, 0.0)
		}
	})
	
	if success then
		if DoesEntityExist(entity) then
			DeleteEntity(entity)
		end
		
		-- Remove this trash from spawnedTrash list
		for i, trash in ipairs(spawnedTrash) do
			if trash.obj == entity then
				table.remove(spawnedTrash, i)
				break
			end
		end
		
		local cleanedAll = lib.callback.await('renzu_motels:cleanTrashPile', false, data.motel, data.index)
		if cleanedAll then
			lib.notify({ title = 'Dọn dẹp', description = 'Phòng trọ hiện đã hoàn toàn sạch sẽ!', type = 'success' })
		else
			lib.notify({ title = 'Dọn dẹp', description = 'Đã dọn dẹp bãi rác này.', type = 'success' })
		end
	end
	isCleaningTrash = false
end

function SpawnRoomTrash(data, spawn, house)
	-- Cleanup any previously spawned trash before spawning new ones
	for _, trash in ipairs(spawnedTrash) do
		if DoesEntityExist(trash.obj) then
			DeleteEntity(trash.obj)
		end
	end
	spawnedTrash = {}

	local motels = GlobalState.Motels
	local rooms = motels[data.motel] and motels[data.motel].rooms
	local room = rooms and (rooms[data.index] or rooms[tostring(data.index)] or rooms[tonumber(data.index)])
	local trashCount = room and room.trashCount or 0
	
	if trashCount == 0 then return end
	
	local shellType = data.shell or 'standard'
	local trashOffsets = config.trashOffsets[shellType] or config.trashOffsets['standard']
	local model = `prop_rub_litter_03`
	
	RequestModel(model)
	while not HasModelLoaded(model) do Wait(10) end
	
	for i = 1, trashCount do
		local offset = trashOffsets[i]
		if offset then
			local x, y, z = spawn.x + offset.x, spawn.y + offset.y, spawn.z + offset.z
			local trashObj = CreateObject(model, x, y, z, false, false, false)
			PlaceObjectOnGroundProperly(trashObj)
			FreezeEntityPosition(trashObj, true)
			
			table.insert(spawnedTrash, { obj = trashObj, index = i })
		end
	end

	-- Thread xử lý phím [E] để dọn dẹp rác (không dùng target, không spam TextUI)
	CreateThread(function()
		while inhouse and #spawnedTrash > 0 do
			local sleep = 300
			if not isCleaningTrash then
				local playerPed = cache.ped or PlayerPedId()
				local playerCoords = GetEntityCoords(playerPed)
				local closestTrash = nil
				local closestDist = 999.0

				for _, trash in ipairs(spawnedTrash) do
					if DoesEntityExist(trash.obj) then
						local coords = GetEntityCoords(trash.obj)
						local dist = #(playerCoords - coords)
						if dist < 1.5 and dist < closestDist then
							closestDist = dist
							closestTrash = trash
						end
					end
				end

				if closestTrash then
					sleep = 0
					if not isTextUIShown then
						lib.showTextUI('[E] - Dọn dẹp rác')
						isTextUIShown = true
					end
					if IsControlJustReleased(0, 38) then
						CleanTrashPile(data, closestTrash.obj, closestTrash.index)
					end
				else
					if isTextUIShown then
						lib.hideTextUI()
						isTextUIShown = false
					end
				end
			else
				if isTextUIShown then
					lib.hideTextUI()
					isTextUIShown = false
				end
			end
			Wait(sleep)
		end
		if isTextUIShown then
			lib.hideTextUI()
			isTextUIShown = false
		end
	end)
end

function Teleport(x, y, z, h ,exit)
    CreateThread(function()
        SetEntityCoords(cache.ped, x, y, z, 0, 0, 0, false)
        SetEntityHeading(cache.ped, h or 0.0)
        Wait(1001)
        DoScreenFadeIn(1000)
    end)
	if exit then
		inhouse = false
		TriggerEvent('qb-weathersync:client:EnableSync')
		if isTextUIShown then
			lib.hideTextUI()
			isTextUIShown = false
		end
		
		-- Delete all spawned trash entities
		for _, trash in ipairs(spawnedTrash) do
			if DoesEntityExist(trash.obj) then
				DeleteEntity(trash.obj)
			end
		end
		spawnedTrash = {}

		for k,id in pairs(shelzones) do
			removeTargetZone(id)
		end
		DeleteEntity(house)
		lib.callback.await('renzu_motels:SetRouting',false,data,'exit')
		shelzones = {}
		DeleteResourceKvp(kvpname)
		LocalPlayer.state:set('inshell',false,true)
	end
end

EnterShell = function(data,login)
	-- Security check - only allow entry if login or quicksleep or has proper access
	if not login and not data.isQuickSleep then
		local motel = GlobalState.Motels[data.motel]
		local moteldoor = motel and motel.rooms[data.index]
		
		if not moteldoor then
			Notify('Phòng không tồn tại!', 'error')
			return false
		end
		
		-- Check access permissions
		local hasDirectAccess = DoesPlayerHaveAccess(motel.rooms[data.index].players)
		local hasValidKey = DoesPlayerHaveKey(data,moteldoor)
		local isOwnerEmployee = IsOwnerOrEmployee(data.motel)
		local isRoomPlayer = moteldoor.players and moteldoor.players[PlayerData?.identifier]
		
		-- Check if rent is expired (only for players who rented the room, not owner/employee)
		if isRoomPlayer and not isOwnerEmployee then
			if isRentExpired(data) then
				Notify('Tiền thuê của bạn đã đến hạn!\nVui lòng thanh toán để truy cập phòng.', 'error')
				if config.debug then
					print('^1[DEBUG] EnterShell - Access DENIED - Rent expired for room #' .. data.index .. '^7')
				end
				return false
			end
		end
		
		if not (hasDirectAccess or hasValidKey or isOwnerEmployee or isRoomPlayer) then
			Notify('Bạn không có quyền truy cập vào phòng này!', 'error')
			if config.debug then
				print('^1[DEBUG] EnterShell - Access DENIED for room #' .. data.index .. '^7')
			end
			return false
		end
		
		if config.debug then
			print('^2[DEBUG] EnterShell - Access granted for room #' .. data.index .. '^7')
		end
	end
	
	local shelldata = config.shells[data.shell or data.motel]
	if not shelldata then 
		warn('Shell is not configure')
		return 
	end
	lib.callback.await('renzu_motels:SetRouting',false,data,'enter')
	inhouse = true
	Wait(1000)
	local spawn = vec3(150.0, -150.0, 1500.0)
    local offsets = shelldata.offsets
	local model = shelldata.shell
	DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end
	inhouse = true
	TriggerEvent('qb-weathersync:client:DisableSync')
	RequestModel(model)
	while not HasModelLoaded(model) do
	    Wait(1000)
	end
	local lastloc = GetEntityCoords(cache.ped)
	house = CreateObject(model, spawn.x, spawn.y, spawn.z, false, false, false)
    FreezeEntityPosition(house, true)
	LocalPlayer.state:set('lastloc',data.lastloc or lastloc,false)
	data.lastloc = data.lastloc or lastloc
	if not login then
		SendNUIMessage({
			type = 'door'
		})
	end
	Teleport(spawn.x + offsets.exit.x, spawn.y + offsets.exit.y, spawn.z+0.1, offsets.exit.h)
	SetResourceKvp(kvpname,json.encode(data))

	Citizen.CreateThreadNow(function()
		ShellTargets(data,offsets,spawn,house)
		SpawnRoomTrash(data,spawn,house)
		while inhouse do
			SetWeatherTypePersist('CLEAR')
			SetWeatherTypeNow('CLEAR')
			SetWeatherTypeNowPersist('CLEAR')
			NetworkOverrideClockTime(18, 0, 0)
			Wait(1000)
		end
	end)
    return house
end

function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance,flag)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =  vector3(cameraCoord.x + direction.x * distance, 
		cameraCoord.y + direction.y * distance, 
		cameraCoord.z + direction.z * distance 
    )
    if not flag then
        flag = 1
    end

	local a, b, c, d, e = GetShapeTestResultIncludingMaterial(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, flag, -1, 1))
	return b, c, e, destination
end

local lastweapon = nil
lib.onCache('weapon', function(weapon)
	if not inMotelZone then return end
	if not PlayerData.job then return end
	if not config.breakinJobs[PlayerData.job.name] then return end
	lastweapon = weapon
    while weapon and weapon == lastweapon and inMotelZone do
		Wait(100)
		if IsPedShooting(cache.ped) then
			local _, bullet, _ = RayCastGamePlayCamera(200.0, 1)
			local motels = GlobalState.Motels or {}
			for _, data in pairs(config.motels) do
				if data.doors and motels[data.motel] and motels[data.motel].rooms then
					for k, v in pairs(data.doors) do
						if v.door then
							for k2, v2 in pairs(v.door) do
								if #(vec3(bullet.x, bullet.y, bullet.z) - vec3(v2.coord.x, v2.coord.y, v2.coord.z)) < 2 and motels[data.motel].rooms[k] and motels[data.motel].rooms[k].lock then
									TriggerServerEvent('renzu_motels:Door', {
										motel = data.motel,
										index = k,
										doorindex = k + k2,
										coord = v2.coord,
										Mlo = data.Mlo,
									})
									local text
									if data.Mlo then
										local doorindex = (k + k2) + (joaat(data.motel))
										text = DoorSystemGetDoorState(doorindex) == 0 and 'Bạn phá hủy cửa nhà nghỉ'
									else
										text = 'Bạn phá hủy cửa nhà nghỉ'
									end
									Notify(text, 'warning')
								end
							end
						end
					end
				end
			end
			Wait(500)
		end
	end
end)

RegisterNetEvent('renzu_motels:MessageOwner', function(data)
	AddTextEntry('esxAdvancedNotification', data.message)
    BeginTextCommandThefeedPost('esxAdvancedNotification')
	ThefeedSetNextPostBackgroundColor(1)
	AddTextComponentSubstringPlayerName(data.message)
    EndTextCommandThefeedPostMessagetext('CHAR_FACEBOOK', 'CHAR_FACEBOOK', false, 1, data.motel, data.title)
    EndTextCommandThefeedPostTicker(flash or false, true)
end)

-- Interior Position Helper Function
RegisterCommand('getinteriorpos', function()
	if not inhouse then
		Notify('You must be inside a motel room to use this command!', 'error')
		return
	end
	
	local coords = GetEntityCoords(cache.ped)
	local heading = GetEntityHeading(cache.ped)
	local spawn = vec3(150.0, -150.0, 1500.0)
	local offset = coords - spawn
	
	print('^3[Motel Interior Position]^7')
	print('Absolute Coordinates: vec3(' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z .. ')')
	print('Relative Offset (for config.shells): vec3(' .. offset.x .. ', ' .. offset.y .. ', ' .. offset.z .. ')')
	print('Current Heading: ' .. heading)
	
	Notify('Tọa độ đã được ghi nhận trong console F8!', 'success')
end, false)

RegisterCommand('saveinteriorpos', function(source, args)
	if not inhouse then
		Notify('You must be inside a motel room to use this command!', 'error')
		return
	end
	
	local coords = GetEntityCoords(cache.ped)
	local heading = GetEntityHeading(cache.ped)
	local label = args[1] or 'Custom Position'
	
	-- Create formatted output for easy copying
	local output = string.format('{\n\tcoord = vec3(%.2f, %.2f, %.2f),\n\theading = %.2f,\n\tlabel = "%s"\n}', 
		coords.x, coords.y, coords.z, heading, label)
	
	print('^3[Motel Interior Position - ' .. label .. ']^7')
	print(output)
	
	Notify('Position saved to console as: ' .. label, 'success')
end, false)

Citizen.CreateThread(function()
	while GlobalState.Motels == nil do Wait(1) end
    for motel, data in pairs(config.motels) do
		-- Spawn NPC immediately on startup
		local point = MotelRentalPoints(data)
		rentalPoints[data.motel] = { point = point }
		-- Create motel rooms zone (must be near motel)
        MotelZone(data)
    end
	CreateBlips()
end)

-- =============================================
-- Dùng item chuotdonhatro → lấy lại đồ bị tịch thu
-- ox_inventory gọi: exports['xn_motels']:claimConfiscated(data)
-- =============================================
exports('claimConfiscated', function(data)
	local success, totalItems, itemsToBuucuc = lib.callback.await('renzu_motels:claimConfiscated', false)
	if success then
		local message = 'Đã nhận lại ' .. tostring(totalItems) .. ' vật phẩm bị tịch thu.'
		
		if itemsToBuucuc and itemsToBuucuc > 0 then
			message = message .. '\n\n⚠️ ' .. tostring(itemsToBuucuc) .. ' items đã được gửi về Bưu cục (kho đồ không đủ chỗ)'
		end
		
		lib.notify({ 
			title = 'Tòa Thị Chính', 
			description = message, 
			type = 'success', 
			duration = itemsToBuucuc and itemsToBuucuc > 0 and 8000 or 6000
		})
	elseif totalItems == 'noitems' then
		lib.notify({ title = 'Tòa Thị Chính', description = 'Không tìm thấy đồ bị tịch thu của bạn.', type = 'error', duration = 5000 })
	elseif totalItems == 'expired' then
		lib.notify({ title = 'Tòa Thị Chính', description = 'Đồ của bạn đã bị tiêu hủy do quá 7 ngày không đến chuộc.', type = 'error', duration = 6000 })
	else
		lib.notify({ title = 'Tòa Thị Chính', description = 'Có lỗi xảy ra, vui lòng thử lại.', type = 'error', duration = 4000 })
	end
end)

-- =============================================
-- NUI Callbacks for New UI
-- =============================================
RegisterNUICallback('closeUI', function(data, cb)
	-- Respond to callback FIRST
	cb('ok')
	
	-- Then release focus
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	currentOpenedMotelData = nil
end)

-- Command to emergency reset NUI focus in case player mouse gets stuck
RegisterCommand('resetnui', function()
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	SendNUIMessage({ type = 'closeUI' })
end, false)

-- Emergency reset on resource stop/restart
AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
	end
end)

-- Scan nearby players within 5.0 radius and resolve names
RegisterNUICallback('getNearbyPlayers', function(data, cb)
	local players = GetActivePlayers()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local nearbyList = {}
	
	for _, player in ipairs(players) do
		local targetPed = GetPlayerPed(player)
		if targetPed ~= playerPed then
			local targetCoords = GetEntityCoords(targetPed)
			local dist = #(playerCoords - targetCoords)
			if dist <= 5.0 then
				local serverId = GetPlayerServerId(player)
				table.insert(nearbyList, {
					id = serverId,
					name = 'Người chơi #' .. serverId,
					dist = math.floor(dist * 10) / 10
				})
			end
		end
	end
	
	if #nearbyList > 0 then
		local resolvedList = lib.callback.await('renzu_motels:getNearbyNames', false, nearbyList)
		cb({ players = resolvedList or nearbyList })
	else
		cb({ players = {} })
	end
end)

-- Callback to enter the room directly from the NUI
RegisterNUICallback('enterRoom', function(data, cb)
	local motelName = data.motel
	local roomIndex = tonumber(data.roomIndex)
	
	if not motelName or not roomIndex then
		cb({ success = false })
		return
	end
	
	local motels, serverTime, maxRentDays = lib.callback.await('renzu_motels:getMotels', false, { motel = motelName })
	if maxRentDays then maxRentDaysLimit = maxRentDays end
	local motel = motels[motelName]
	if not motel then
		cb({ success = false })
		return
	end
	
	local room = motel.rooms[roomIndex]
	if not room then
		cb({ success = false })
		return
	end
	
	local hasDirectAccess = DoesPlayerHaveAccess(room.players)
	local isOwnerEmployee = IsOwnerOrEmployee(motelName)
	local isRoomPlayer = room.players and room.players[PlayerData?.identifier]
	
	local rentExpired = false
	if isRoomPlayer and not isOwnerEmployee then
		local rentData = { motel = motelName, index = roomIndex }
		rentExpired = isRentExpired(rentData)
	end
	
	if (hasDirectAccess or isOwnerEmployee or isRoomPlayer) and not rentExpired then
		local motelConfig = nil
		for k, v in pairs(config.motels) do
			if v.motel == motelName then
				motelConfig = v
				break
			end
		end
		
		if not motelConfig then
			cb({ success = false })
			return
		end
		
		local enterData = {
			motel = motelName,
			index = roomIndex,
			shell = motelConfig.shell or 'standard',
			Mlo = false, -- Force shell mode for all motels
			coord = vec3(150.0, -150.0, 1500.0), -- Shared spawn coordinates
			lastloc = GetEntityCoords(PlayerPedId())
		}
		
		SendNUIMessage({
			type = "playsound",
			content = {
				file = 'door',
				volume = 0.5
			}
		})
		
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		SendNUIMessage({ type = 'closeUI' })
		
		EnterShell(enterData)
		
		cb({ success = true })
	else
		Notify('Bạn không có quyền truy cập hoặc phòng đã hết hạn!', 'error')
		cb({ success = false })
	end
end)

RegisterNUICallback('cleanRoom', function(data, cb)
	local roomIndex = tonumber(data.roomIndex)
	local motelName = data.motel
	
	if not roomIndex or not motelName then
		cb({ success = false })
		return
	end
	
	local motels, serverTime = lib.callback.await('renzu_motels:getMotels', false, { motel = motelName })
	local motel = motels and motels[motelName]
	local room = motel and motel.rooms and (motel.rooms[roomIndex] or motel.rooms[tostring(roomIndex)] or motel.rooms[tonumber(roomIndex)])
	local isOwnerEmployee = IsOwnerOrEmployee(motelName)
	local isRoomPlayer = room and room.players and room.players[PlayerData?.identifier]
	
	if not isOwnerEmployee and not isRoomPlayer then
		Notify('Bạn không có quyền truy cập vào phòng này!', 'error')
		cb({ success = false })
		return
	end
	
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelName then
			motelConfig = v
			break
		end
	end
	
	if not motelConfig then
		cb({ success = false })
		return
	end
	
	local enterData = {
		motel = motelName,
		index = roomIndex,
		shell = motelConfig.shell or 'standard',
		Mlo = false,
		coord = vec3(150.0, -150.0, 1500.0),
		lastloc = GetEntityCoords(PlayerPedId()),
		isCleaning = true
	}
	
	SendNUIMessage({
		type = "playsound",
		content = {
			file = 'door',
			volume = 0.5
		}
	})
	
	SetNuiFocus(false, false)
	SetNuiFocusKeepInput(false)
	SendNUIMessage({ type = 'closeUI' })
	
	EnterShell(enterData)
	
	cb({ success = true })
end)

RegisterNUICallback('autoCleanRoom', function(data, cb)
	local roomIndex = tonumber(data.roomIndex or data.index)
	local motelName = data.motel

	if not roomIndex or not motelName then
		lib.notify({ title = 'Dọn Dẹp', description = 'Thông tin phòng không hợp lệ!', type = 'error' })
		cb({ success = false })
		return
	end

	local success, message = lib.callback.await('renzu_motels:autoCleanRoom', false, {
		motel = motelName,
		index = roomIndex
	})

	if success then
		cb({ success = true })
	else
		lib.notify({ title = 'Dọn Dẹp', description = message or 'Không thể dọn dẹp!', type = 'error' })
		cb({ success = false, message = message })
	end
end)

RegisterNUICallback('renewRoom', function(data, cb)
	local days = tonumber(data.days) or 1
	local motelName = data.motel
	local roomIndex = tonumber(data.index)
	local amount = tonumber(data.amount) or 0
	
	if not roomIndex or not motelName then
		lib.notify({ title = 'Nhà trọ', description = 'Không tìm thấy thông tin phòng để gia hạn!', type = 'error' })
		cb({ success = false, message = 'noroom' })
		return
	end
	
	-- Call server to renew
	local success, message = lib.callback.await('renzu_motels:renewRoom', false, {
		motel = motelName,
		index = roomIndex,
		days = days,
		amount = amount
	})
	
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã gia hạn phòng thành công ' .. days .. ' ngày!', type = 'success' })
		-- Play renewal success sound
		SendNUIMessage({
			type = "playsound",
			content = {
				file = 'giahannha',
				volume = 0.5
			}
		})
		cb({ success = true })
	else
		lib.notify({ title = 'Nhà trọ', description = message or 'Không đủ tiền để gia hạn!', type = 'error' })
		cb({ success = false, message = 'fail' })
	end
end)

RegisterNUICallback('rentRoom', function(data, cb)
	-- data = { roomIndex: number, days: number, paymentMethod: string }
	local roomIndex = tonumber(data.roomIndex)
	local days = tonumber(data.days) or 1
	local paymentMethod = data.paymentMethod or 'money'
	local motelName = data.motel
	
	if not roomIndex or not motelName then
		cb({ success = false, message = 'invalid' })
		return
	end
	
	-- Find motel config
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == motelName then
			motelConfig = v
			break
		end
	end
	
	if not motelConfig then
		cb({ success = false, message = 'noconfig' })
		return
	end
	
	-- Get rate from config
	local rate = motelConfig.rate or 100
	local amount = rate * days
	
	-- Call server to rent
	local success = lib.callback.await('renzu_motels:rentRoom', false, {
		motel = motelName,
		index = roomIndex,
		days = days,
		amount = amount,
		payment = paymentMethod,
		rate = rate,
		rental_period = 'day',
		shell = motelConfig.shell,
		Mlo = motelConfig.Mlo,
		uniquestash = motelConfig.uniquestash
	})
	
	if success == 'exist' then
		lib.notify({ title = 'Nhà trọ', description = 'Phòng này đã có người thuê!', type = 'error' })
		cb({ success = false, message = 'exist' })
	elseif success == 'hasroom' then
		lib.notify({ title = 'Nhà trọ', description = 'Bạn đã có phòng rồi!', type = 'error' })
		cb({ success = false, message = 'hasroom' })
	elseif success == 'limit' then
		local maxDays = maxRentDaysLimit
		lib.notify({ title = 'Nhà trọ', description = 'Vượt quá giới hạn ngày thuê (tối đa ' .. maxDays .. ' ngày)!', type = 'error' })
		cb({ success = false, message = 'limit' })
	elseif success == 'nomoney' then
		lib.notify({ title = 'Nhà trọ', description = 'Không đủ tiền!', type = 'error' })
		cb({ success = false, message = 'nomoney' })
	elseif success == 'owned' then
		lib.notify({ title = 'Nhà trọ', description = 'Khu trọ này đã có chủ, bạn không thể tự thuê phòng!', type = 'error' })
		cb({ success = false, message = 'owned' })
	elseif success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã thuê phòng #' .. roomIndex .. ' thành công!', type = 'success' })
		-- Play rent success sound
		SendNUIMessage({
			type = "playsound",
			content = {
				file = 'thuephongthanhcong',
				volume = 0.5
			}
		})
		cb({ success = true })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Có lỗi xảy ra!', type = 'error' })
		cb({ success = false, message = 'error' })
	end
end)

RegisterNUICallback('checkoutRoom', function(data, cb)
	local motelName = data.motel
	local roomIndex = tonumber(data.index)
	
	if not roomIndex or not motelName then
		lib.notify({ title = 'Nhà trọ', description = 'Không tìm thấy thông tin phòng để trả!', type = 'error' })
		cb({ success = false, message = 'noroom' })
		return
	end
	
	-- Call server to checkout
	local success = lib.callback.await('renzu_motels:checkoutRoom', false, motelName, roomIndex)
	
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Bạn đã trả phòng thành công', type = 'success' })
		-- Play checkout success sound
		SendNUIMessage({
			type = "playsound",
			content = {
				file = 'traphong',
				volume = 0.5
			}
		})
		cb({ success = true })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể trả phòng!', type = 'error' })
		cb({ success = false, message = 'error' })
	end
end)

-- =============================================
-- Open Motel UI
-- =============================================
local currentOpenedMotelData = nil

OpenMotelUI = function(motelData, isRefresh)
	currentOpenedMotelData = motelData
	-- Get current state
	local motels, serverTime, maxRentDays = lib.callback.await('renzu_motels:getMotels', false, { motel = motelData.motel })
	if maxRentDays then maxRentDaysLimit = maxRentDays end
	local motelName = motelData.motel
	local motel = motels[motelName]
	
	if not motel then
		lib.notify({ title = 'Nhà trọ', description = 'Không tìm thấy thông tin nhà trọ!', type = 'error' })
		return
	end
	
	-- Find player's rooms (up to 3) in this motel
	local myRooms = {}
	for index, room in pairs(motel.rooms or {}) do
		if DoesPlayerHaveAccess(room.players) then
			local playerDuration = 0
			local isAdditional = false
			for identifier, playerData in pairs(room.players or {}) do
				if identifier == PlayerData?.identifier and playerData.duration then
					playerDuration = playerData.duration
					isAdditional = playerData.additional or false
					break
				end
			end
			table.insert(myRooms, {
				roomNumber = index,
				expiresAt = playerDuration,
				additional = isAdditional,
				trashCount = room and room.trashCount or 0,
				lastCleaned = room and room.lastCleaned or nil
			})
		end
	end
	local myRoom = myRooms[1] or nil
	
	-- Prepare rooms list
	local rooms = {}
	-- Count rooms from doors table
	local roomCount = 0
	for _ in pairs(motelData.doors or {}) do
		roomCount = roomCount + 1
	end
	
	for i = 1, roomCount do
		local room = motel.rooms[i]
		local status = 'available'
		
		if room and room.players then
			-- Check if room has active rental
			local hasActiveRental = false
			for _, playerData in pairs(room.players) do
				if playerData.duration and playerData.duration > serverTime then
					hasActiveRental = true
					break
				end
			end
			
			if hasActiveRental then
				status = 'rented'
			else
				status = 'available'
			end
		end
		
		table.insert(rooms, {
			number = i,
			status = status,
			lastCleaned = room and room.lastCleaned or nil,
			trashCount = room and room.trashCount or 0
		})
	end
	
	-- Play sound based on whether player has a room
	if not isRefresh then
		local soundFile = myRoom and 'giahan' or 'thuetro'
		SendNUIMessage({
			type = "playsound",
			content = {
				file = soundFile,
				volume = 0.5
			}
		})
	end
	
	-- Build ownerData for NUI
	local isOwner = motel.owned == PlayerData?.identifier
	local employees = motel.employees or {}
	local isEmployee = employees[PlayerData?.identifier] ~= nil
	local employeeGrade = 0
	if isEmployee then
		local empInfo = employees[PlayerData?.identifier]
		if type(empInfo) == 'table' then
			employeeGrade = empInfo.grade or 1
		else
			employeeGrade = 1
		end
	end

	-- Format the entire employees list to ensure { name, grade } structure is sent to NUI
	local formattedEmployees = {}
	for k, v in pairs(employees) do
		if type(v) == 'table' then
			formattedEmployees[k] = {
				name = v.name or 'Unknown',
				grade = tonumber(v.grade) or 1
			}
		else
			formattedEmployees[k] = {
				name = v or 'Unknown',
				grade = 1
			}
		end
	end

	local motelNotOwned = not motel.owned or motel.owned == "" or motel.owned == 0 or motel.owned == "0"
	local isOwnedByOthers = motel.owned and motel.owned ~= "" and motel.owned ~= 0 and motel.owned ~= "0" and motel.owned ~= PlayerData?.identifier
	local ownerDataNUI = {
		isOwner = isOwner,
		isEmployee = isEmployee,
		employeeGrade = employeeGrade,
		motelNotOwned = motelNotOwned,
		isOwnedByOthers = isOwnedByOthers,
		hasOwner = not motelNotOwned,
		revenue = motel.revenue or 0,
		hourRate = motel.hour_rate or motelData.rate or 0,
		businessPrice = motelData.businessprice or 0,
		employees = formattedEmployees,
		additionalPremium = motel.additional_premium or 10,
		clothesEnabled = motelData.clothesEnabled == true,
	}

	-- Calculate max rent days based on serverTime
	local maxRentDays = Config.GetMaxRentDays(serverTime)

	-- Get contact list for owned motel
	local contacts = {}
	if not motelNotOwned then
		contacts = lib.callback.await('renzu_motels:getMotelContacts', false, motelName) or {}
	end

	-- Xây dựng dữ liệu công ty (office)
	local officeEnabled = motelData.office and motelData.office.enabled or false
	local officeLabel = motelData.office and motelData.office.label or ''
	local officeIsOpen = true
	if officeEnabled then
		local offices = GlobalState.MotelOffices
		if offices and offices[motelName] then
			officeIsOpen = offices[motelName].isOpen ~= false
		end
	end

	-- Send to UI
	local uiData = {
		type = 'openUI',
		motelName = motelData.blipLabel or motelData.label or motelName,
		motelId = motelName,
		serverTime = serverTime,
		myRoom = myRoom,
		myRooms = myRooms,
		rooms = rooms,
		dayRate = motelData.rate or 100,
		rentalPeriod = motelData.rental_period or 'day',
		resourceName = GetCurrentResourceName(),
		ownerData = ownerDataNUI,
		maxRentDays = maxRentDays,
		maxDailyRent = Config.maxDailyRent or 10000,
		additionalPremium = motel.additional_premium or 10,
		contacts = contacts,
		officeData = {
			enabled = officeEnabled,
			isOpen = officeIsOpen,
			label = officeLabel,
		},
	}
	
	SendNUIMessage(uiData)
	
	if not isRefresh then
		SetNuiFocus(true, true)
	end
end

-- =============================================
-- NUI Callbacks: Owner features
-- =============================================

RegisterNUICallback('buyMotel', function(data, cb)
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == data.motel then motelConfig = v break end
	end
	if not motelConfig then cb({ success = false }) return end
	local success = lib.callback.await('renzu_motels:buymotel', false, motelConfig)
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Bạn đã mua khu trọ thành công!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không đủ tiền hoặc khu trọ đã có chủ!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('withdrawFund', function(data, cb)
	local success = lib.callback.await('renzu_motels:withdrawfund', false, data.motel, tonumber(data.amount))
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Rút tiền thành công!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không đủ doanh thu hoặc lỗi!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('editRate', function(data, cb)
	local success = lib.callback.await('renzu_motels:editrate', false, data.motel, tonumber(data.rate), tonumber(data.premium))
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã cập nhật giá thuê!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể cập nhật giá!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('transferMotel', function(data, cb)
	local success = lib.callback.await('renzu_motels:transfermotel', false, data.motel, tonumber(data.pid))
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã chuyển nhượng khu trọ!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể chuyển nhượng!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('sellMotel', function(data, cb)
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == data.motel then motelConfig = v break end
	end
	if not motelConfig then cb({ success = false }) return end
	local success = lib.callback.await('renzu_motels:sellmotel', false, motelConfig)
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã bán khu trọ thành công!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể bán khu trọ!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('changeClothesNUI', function(data, cb)
	local motelId = data.motel
	local role = data.role

	if role == 'citizen' then
		RestoreCitizenClothes()
	else
		ApplyWorkClothes(motelId, role)
	end
	cb({ success = true })
end)

RegisterNUICallback('getOccupants', function(data, cb)
	local serverOccupants = lib.callback.await('renzu_motels:getOccupantNames', false, data.motel, data.roomIndex) or {}
	
	local currentTime = GetCloudTimeAsInt()
	local occupants = {}
	for _, charData in ipairs(serverOccupants) do
		local duration = tonumber(charData.duration) or 0
		local secondsLeft = duration - currentTime
		local timeLeftStr = ""
		if secondsLeft > 0 then
			local days = math.floor(secondsLeft / 86400)
			local hours = math.floor((secondsLeft % 86400) / 3600)
			local minutes = math.floor((secondsLeft % 3600) / 60)
			if days > 0 then
				timeLeftStr = string.format("Còn lại: %d ngày %d giờ", days, hours)
			elseif hours > 0 then
				timeLeftStr = string.format("Còn lại: %d giờ %d phút", hours, minutes)
			else
				timeLeftStr = string.format("Còn lại: %d phút", minutes)
			end
		else
			timeLeftStr = "Hết hạn"
		end
		table.insert(occupants, { 
			identifier = charData.identifier, 
			name = charData.name or 'Unknown',
			timeLeft = timeLeftStr,
			additional = charData.additional or false
		})
	end
	cb({ occupants = occupants })
end)

RegisterNUICallback('getTargetRoomsCount', function(data, cb)
	local count = lib.callback.await('renzu_motels:getTargetRoomsCount', false, data.motel, data.pid) or 0
	cb({ count = count })
end)


RegisterNUICallback('kickOccupant', function(data, cb)
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == data.motel then motelConfig = v break end
	end
	if not motelConfig then cb({ success = false }) return end
	local success = lib.callback.await('renzu_motels:removeoccupant', false, motelConfig, tonumber(data.roomIndex), data.identifier)
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã đá người thuê khỏi phòng!', type = 'success' })
		if currentOpenedMotelData then
			OpenMotelUI(currentOpenedMotelData, true)
		end
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể đá người thuê!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('addOccupant', function(data, cb)
	local motelConfig = nil
	for k, v in pairs(config.motels) do
		if v.motel == data.motel then motelConfig = v break end
	end
	if not motelConfig then cb({ success = false }) return end
	local input = { data.pid, data.days, data.customRate }
	local success = lib.callback.await('renzu_motels:addoccupant', false, motelConfig, tonumber(data.roomIndex), input)
	if success == 'exist' then
		lib.notify({ title = 'Nhà trọ', description = 'Người chơi đã ở phòng này!', type = 'error' })
	elseif success == 'hasroom' then
		lib.notify({ title = 'Nhà trọ', description = 'Người chơi đã có phòng rồi!', type = 'error' })
	elseif success == 'rented' then
		lib.notify({ title = 'Nhà trọ', description = 'Phòng này đã có người thuê rồi!', type = 'error' })
	elseif success == 'limit' then
		local maxDays = maxRentDaysLimit
		lib.notify({ title = 'Nhà trọ', description = 'Vượt quá giới hạn ngày thuê (tối đa ' .. maxDays .. ' ngày)!', type = 'error' })
	elseif success == 'declined' then
		lib.notify({ title = 'Nhà trọ', description = 'Người chơi từ chối thuê phòng!', type = 'error' })
	elseif success == 'nomoney' then
		lib.notify({ title = 'Nhà trọ', description = 'Người chơi không đủ tiền!', type = 'error' })
	elseif success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã thêm người thuê vào phòng!', type = 'success' })
		if currentOpenedMotelData then
			OpenMotelUI(currentOpenedMotelData, true)
		end
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể thêm người thuê!', type = 'error' })
	end
	cb({ success = success == true })
end)

RegisterNUICallback('renewOccupant', function(data, cb)
	-- data = { motel: string, roomIndex: number, days: number }
	local success, message = lib.callback.await('renzu_motels:ownerRenewRoom', false, {
		motel = data.motel,
		index = tonumber(data.roomIndex),
		days = tonumber(data.days),
		customRate = tonumber(data.customRate)
	})
	
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã gia hạn phòng trọ thành công!', type = 'success' })
		if currentOpenedMotelData then
			OpenMotelUI(currentOpenedMotelData, true)
		end
	else
		lib.notify({ title = 'Nhà trọ', description = message or 'Không thể gia hạn phòng trọ!', type = 'error' })
	end
	cb({ success = success == true })
end)

RegisterNUICallback('addEmployee', function(data, cb)
	local success = lib.callback.await('renzu_motels:addemployee', false, data.motel, tonumber(data.pid))
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã thêm nhân viên!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể thêm nhân viên!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('removeEmployee', function(data, cb)
	local success = lib.callback.await('renzu_motels:removeemployee', false, data.motel, data.identifier)
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã xóa nhân viên!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể xóa nhân viên!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('promoteEmployee', function(data, cb)
	local success = lib.callback.await('renzu_motels:promoteemployee', false, data.motel, data.identifier, tonumber(data.grade))
	if success then
		lib.notify({ title = 'Nhà trọ', description = 'Đã thăng cấp/thay đổi chức vụ nhân viên!', type = 'success' })
	else
		lib.notify({ title = 'Nhà trọ', description = 'Không thể thay đổi chức vụ!', type = 'error' })
	end
	cb({ success = success })
end)

RegisterNUICallback('callContact', function(data, cb)
	local phone = tostring(data.phone)
	if phone and phone ~= "N/A" and phone ~= "" then
		exports["lb-phone"]:CreateCall({ number = phone })
	end
	cb({ success = true })
end)

RegisterNUICallback('toggleOffice', function(data, cb)
	local success = lib.callback.await('renzu_motels:toggleOffice', false, data.motel, data.isOpen)
	if success then
		lib.notify({ title = 'Công ty', description = data.isOpen and 'Đã mở cửa công ty!' or 'Đã đóng cửa công ty!', type = 'success' })
	else
		lib.notify({ title = 'Công ty', description = 'Không có quyền thực hiện!', type = 'error' })
	end
	cb({ success = success })
end)
