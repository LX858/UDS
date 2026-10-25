if GetResourceState('ox_target') ~= 'started' or not config.target then return end

MotelFunction = function(data)
	if not data.Mlo and data.type ~= 'door' then return end
	local options = {}
	if data.type == 'door' then
		local doorIndex = data.doorindex + (joaat(data.motel))
		AddDoorToSystem(doorIndex, data.door, data.coord)
		SetDoorState(data)
		local blip = AddBlipForCoord(data.coord.x,data.coord.y,data.coord.z)
		SetBlipSprite(blip,685+data.index)
		SetBlipColour(blip,0)
		SetBlipSecondaryColour(blip,255,255,255)
		SetBlipAsShortRange(blip,true)
		SetBlipScale(blip,0.3)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString('Door '..data.index)
		EndTextCommandSetBlipName(blip)
		table.insert(blips,blip)
		if not data.Mlo then
			table.insert(options,{
				name = data.index .. '_' .. data.type..'_enter',
				onSelect = function() 
					return EnterShell(data)
				end,
				icon = 'fas fa-person-booth',
				label = 'Vào - Phòng #' .. data.index
			})
		end
	end
	-- table.insert(options,{
	-- 	name = data.index .. '_' .. data.type,
	-- 	onSelect = function() 
	-- 		return RoomFunction(data)
	-- 	end,
	-- 	icon = config.icons[data.type],
	-- 	label = data.label .. ' - Phòng #' .. data.index
	-- })
    local targetid = exports.ox_target:addBoxZone({
		coords = data.coord,
		size = vec3(2, 2, 2),
		rotation = 45,
		debug = false,
		options = options
	})
	table.insert(zones,targetid)
end

removeTargetZone = function(id)
	return exports['ox_target']:removeZone(id)
end

ShellTargets = function(data,offsets,loc,house)
	Wait(2000)
	for k,v in pairs(offsets) do
		if not (data.isCleaning and k ~= 'exit') then
			local targetCoords = loc+v
			local options = {}
			
			if k == 'stash' then
				if not data.isQuickSleep then
					-- Target stash chỉ hiển thị cho chủ phòng
					local canInteractFn = function(entity, distance, coords, name, bone)
						local motels = GetMotelSnapshot()[data.motel]
						if not motels then return false end
						local room = motels.rooms and motels.rooms[data.index]
						if not room then return false end
						if not PlayerData or not PlayerData.identifier then return false end
						return room.players and room.players[PlayerData.identifier] ~= nil
					end

					table.insert(options,{
						name = data.motel .. '_' .. k..'_'..data.index,
						onSelect = function()
							print('^3[STASH] Target clicked!^7')
							data.type = k
							-- Nếu uniquestash = true, dùng citizenid. Nếu false, dùng 'room'
							local identifier = data.uniquestash and (PlayerData and PlayerData.identifier or nil) or 'room'
							print('^3[STASH] Opening stash for identifier: ' .. tostring(identifier) .. '^7')
							return RoomFunction(data, identifier, targetCoords)
						end,
						icon = config.icons[k],
						label = config.Text[k] .. ' - Room #' .. data.index,
						canInteract = canInteractFn
					})

					-- Target thay đổi ped — cùng khu vực với stash
					table.insert(options,{
						name = data.motel .. '_changePed_'..data.index,
						onSelect = function()
							return ChangePedFunction(data)
						end,
						icon = config.icons['changePed'] or 'fas fa-user-circle',
						label = (config.Text['changePed'] or 'Thay đổi Ped') .. ' - Room #' .. data.index,
						canInteract = canInteractFn
					})
				end
			else
				local labelText = config.Text[k]
				if data.isQuickSleep then
					if k == 'wardrobe' then
						labelText = 'Giường Ngủ (Nghỉ ngơi - Tối đa 50% năng lượng)'
					elseif k == 'exit' then
						labelText = 'Rời khỏi phòng'
					end
				else
					labelText = config.Text[k] .. ' - Room #' .. data.index
				end

				table.insert(options,{
					name = data.motel .. '_' .. k..'_'..data.index,
					onSelect = function() 
						data.type = k
						return RoomFunction(data, nil, targetCoords)
					end,
					icon = config.icons[k],
					label = labelText
				})
			end

			-- Chỉ tạo target nếu có options
			if #options > 0 then
				local targetid = exports.ox_target:addBoxZone({
					coords = loc+v,
					size = vec3(2, 2, 2),
					rotation = 45,
					debug = false,
					options = options
				})
				table.insert(shelzones,targetid)
			end
		end
	end
end