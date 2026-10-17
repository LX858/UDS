local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

Config = Config or {}

INPUT_CONTEXT = 51
TimeoutCallbacks = {}
local isSentenced = false
local communityServiceFinished = false
local actionsRemaining = 0
local availableActions = {}
local disable_actions = false

local vassoumodel = "prop_tool_broom"
local vassour_net = nil

local spatulamodel = "bkr_prop_coke_spatula_04"
local spatula_net = nil
local shit = nil
local object = {}
-- local showtext = false

-- Tối ưu resmon variables
local nearObj = nil
local lastPlayerCoords = vector3(0, 0, 0)
local coordsUpdateTimer = 0

RegisterNetEvent('esx_communityservice:inCommunityService', function(actions_remaining)
	local playerPed = PlayerPedId()

	if isSentenced then
		return
	end

	actionsRemaining = actions_remaining

	FillActionTable()

	ApplyPrisonerSkin()
	Teleport(playerPed, Config.ServiceLocation)
	isSentenced = true
	communityServiceFinished = false
	
	-- Set player state để deathscreen biết đang ở tù
	LocalPlayer.state:set('isSentenced', true, true)
	
	-- Set metadata injail để hệ thống respawn hoạt động
	TriggerServerEvent('nl_hotcut:server:setInjail', 1)
	
	-- Tạo marker hình trụ cao 50m để hiển thị phạm vi tù
	CreateThread(function()
		while isSentenced and not communityServiceFinished do
			local x, y, z = Config.ZoneMarkerLocation.x, Config.ZoneMarkerLocation.y, Config.ZoneMarkerLocation.z
			
			-- Marker hình trụ đỏ (type 1)
			DrawMarker(
				1, -- type: cylinder
				x, y, z - 1.0, -- vị trí (hạ xuống 1m để không bị chìm)
				0.0, 0.0, 0.0, -- direction
				0.0, 0.0, 0.0, -- rotation
				Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, 50.0, -- scale: diameter = radius * 2, height 50m
				255, 0, 0, 80, -- color: đỏ, alpha 80 (trong suốt vừa)
				false, false, 2, false, nil, nil, false
			)
			Wait(0) -- Vẽ mượt vì chỉ chạy cho người ở tù
		end
	end)
	
	-- Thread 2: Vẽ markers bãi làm việc (CHỈ bật khi vào tù)
	CreateThread(function()
		while isSentenced and not communityServiceFinished do
			local playerCoords = GetEntityCoords(PlayerPedId())
			
			-- Chỉ vẽ marker gần player (trong phạm vi 50m)
			for i = 1, #availableActions do
				local coords = availableActions[i].coords
				local distance = #(playerCoords - coords)
				
				if distance < 50.0 then
					DrawAvailableActions()
					break
				end
			end
			
			Wait(0) -- Vẽ mượt vì chỉ chạy cho người ở tù
		end
	end)
	
	-- Thread 3: Kiểm tra đánh nhau trong tù (CHỈ phát hiện người TẤN CÔNG)
	CreateThread(function()
		local lastAttackTime = 0
		
		while isSentenced and not communityServiceFinished do
			local playerPed = PlayerPedId()
			local currentTime = GetGameTimer()
			
			-- Chỉ kiểm tra nếu đã qua 10s từ lần phạt trước (tránh spam)
			if currentTime - lastAttackTime > 10000 then
				-- Kiểm tra nếu player ĐANG TẤN CÔNG (không phải bị tấn công)
				if IsPedInMeleeCombat(playerPed) then
					local target = GetMeleeTargetForPed(playerPed)
					
					-- Nếu có target và target là player khác
					if target and DoesEntityExist(target) and IsPedAPlayer(target) then
						-- Kiểm tra player đang ĐÁNH (không phải bị đánh)
						-- Nếu player đang thực hiện hành động tấn công
						if IsEntityPlayingAnim(playerPed, "melee@unarmed@streamed_core", "plyr_takedown_front", 3) or
						   IsPedPerformingMeleeAction(playerPed) or
						   HasEntityBeenDamagedByEntity(target, playerPed, 1) then
							
							-- Đã tấn công! Báo server
							TriggerServerEvent('esx_communityservice:fightInPrison')
							lastAttackTime = currentTime
							Wait(10000) -- Đợi 10s
						end
					end
				end
			end
			
			Wait(500)
		end
	end)

	while actionsRemaining > 0 and communityServiceFinished ~= true do

		if IsPedInAnyVehicle(playerPed, false) then
			ClearPedTasksImmediately(playerPed)
		end
		Wait(3000)
		-- Kiểm tra lại trạng thái trước khi teleport (tránh teleport sau khi đã thả)
		if isSentenced and actionsRemaining > 0 and communityServiceFinished ~= true then
			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.ZoneMarkerLocation.x, Config.ZoneMarkerLocation.y, Config.ZoneMarkerLocation.z) > Config.ZoneRadius then
				Teleport(playerPed, Config.ServiceLocation)
				TriggerEvent('chat:addMessage', { args = { _U('judge'), _U('escape_attempt') }, color = { 147, 196, 109 } })
				TriggerServerEvent('esx_communityservice:extendService')
				actionsRemaining = actionsRemaining + Config.ServiceExtensionOnEscape
			end
		end

	end

	CleanupCommunityService() -- Cleanup tất cả objects và reset variables

	-- Chỉ gọi server nếu player TỰ hoàn thành (không phải cảnh sát thả hay admin)
	if not communityServiceFinished then
		exports.qbx_core:Notify("Bạn đã được tự do", "success", 10000)
		TriggerServerEvent('esx_communityservice:finishCommunityService', -1)
		Teleport(playerPed, Config.ReleaseLocation)
	end
	
	isSentenced = false
	
	-- Clear player state
	LocalPlayer.state:set('isSentenced', false, true)
	
	-- Clear metadata injail
	TriggerServerEvent('nl_hotcut:server:setInjail', 0)
	
	TriggerServerEvent('clothes:reloadPlayerClothes') --thay ham tra quan ao cua suoc quan ao vao day
end)

-- Event khi player spawn (thoát game vào lại)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
	Wait(5000) -- Đợi 5 giây để tất cả load xong
	--print("Player đã load xong, kiểm tra trạng thái phạt lao động...")
	TriggerServerEvent('esx_communityservice:checkIfSentenced')
end)

-- Export function để lấy tọa độ respawn trong tù
exports('GetRespawnLocation', function()
	-- Kiểm tra cả biến local và state để đảm bảo
	local isInJail = isSentenced or (LocalPlayer.state.isSentenced == true)
	if isInJail then
		return Config.RespawnLocation
	end
	return nil
end)

-- Event nhận update số bãi còn lại từ server
RegisterNetEvent('esx_communityservice:updateActions', function(newActions)
	actionsRemaining = newActions
	
	-- Nếu hết bãi thì đóng menu (nếu đang mở)
	if newActions <= 0 then
		lib.hideContext()
	end
end)

-- Tạo NPC chuộc tù (TRONG TÙ)
CreateThread(function()
	local npcModel = 's_m_m_prisguard_01'
	local npcHash = GetHashKey(npcModel)
	
	RequestModel(npcHash)
	while not HasModelLoaded(npcHash) do
		Wait(10)
	end
	
	local npc = CreatePed(4, npcHash, Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1.0, Config.NPCLocation.w, false, true)
	FreezeEntityPosition(npc, true)
	SetEntityInvincible(npc, true)
	SetBlockingOfNonTemporaryEvents(npc, true)
	
	-- Thêm target cho NPC trong tù
	exports.ox_target:addLocalEntity(npc, {
		{
			name = 'prison_buyout_inside',
			label = 'Kiểm tra & Chuộc tù',
			icon = 'fa-solid fa-sack-dollar',
			canInteract = function()
				return isSentenced
			end,
			onSelect = function()
				-- Hiển thị menu
				local options = {
					{
						title = 'Số bãi còn lại: ' .. actionsRemaining,
						icon = 'fa-solid fa-info-circle',
						disabled = true
					},
					{
						title = 'Chuộc tù',
						description = 'Giá: $' .. Config.BuyoutPrice .. ' / 1 bãi',
						icon = 'fa-solid fa-money-bill-wave',
						onSelect = function()
							local input = lib.inputDialog('Chuộc Tù', {
								{type = 'number', label = 'Số bãi muốn chuộc', description = 'Giá: $' .. Config.BuyoutPrice .. '/bãi', required = true, min = 1, max = actionsRemaining}
							})
							
							if input then
								local amount = input[1]
								local totalPrice = amount * Config.BuyoutPrice
								
								-- Xác nhận
								local alert = lib.alertDialog({
									header = 'Xác nhận chuộc tù',
									content = 'Chuộc ' .. amount .. ' bãi với giá $' .. totalPrice .. '?',
									centered = true,
									cancel = true
								})
								
								if alert == 'confirm' then
									TriggerServerEvent('esx_communityservice:buyoutService', amount)
								end
							end
						end
					},
					{
						title = 'Đặt lại nhiệm vụ',
						description = 'Refresh danh sách bãi làm việc',
						icon = 'fa-solid fa-rotate',
						onSelect = function()
							-- Reset lại bảng nhiệm vụ
							FillActionTable()
						exports.qbx_core:Notify('Đã làm mới danh sách nhiệm vụ', 'success')
						end
					}
				}
				
				lib.registerContext({
					id = 'prison_buyout_menu',
					title = 'Chuộc Tù',
					options = options
				})
				
				lib.showContext('prison_buyout_menu')
			end
		},
		{
			name = 'prison_end_visit',
			label = 'Kết thúc thăm tù',
			icon = 'fa-solid fa-door-open',
			canInteract = function()
				return LocalPlayer.state.isVisiting or false
			end,
			onSelect = function()
				TriggerServerEvent('esx_communityservice:endVisit')
			end
		}
	})
end)

-- Tạo NPC thăm/chuộc tù (NGOÀI TÙ)
CreateThread(function()
	local npcModel = 's_m_m_prisguard_01'
	local npcHash = GetHashKey(npcModel)
	
	RequestModel(npcHash)
	while not HasModelLoaded(npcHash) do
		Wait(10)
	end
	
	local npc = CreatePed(4, npcHash, Config.NPCVisitLocation.x, Config.NPCVisitLocation.y, Config.NPCVisitLocation.z - 1.0, Config.NPCVisitLocation.w, false, true)
	FreezeEntityPosition(npc, true)
	SetEntityInvincible(npc, true)
	SetBlockingOfNonTemporaryEvents(npc, true)
	
	-- Thêm target cho NPC ngoài tù
	exports.ox_target:addLocalEntity(npc, {
		{
			name = 'prison_visit',
			label = 'Thăm tù',
			icon = 'fa-solid fa-users',
			onSelect = function()
				TriggerServerEvent('esx_communityservice:requestVisitList')
			end
		},
		{
			name = 'prison_buyout_outside',
			label = 'Bảo lãnh người thân',
			icon = 'fa-solid fa-hand-holding-dollar',
			onSelect = function()
				TriggerServerEvent('esx_communityservice:requestPrisonerList')
			end
		}
	})
end)

-- Event handlers cho visit system
RegisterNetEvent('esx_communityservice:showPrisonerList', function(prisonerList)
	if not prisonerList or #prisonerList == 0 then
		exports.qbx_core:Notify('Không có tù nhân nào!', 'error', 3000)
		return
	end
	
	local options = {}
	for _, prisoner in ipairs(prisonerList) do
		local totalCost = prisoner.actionsRemaining * Config.BuyoutPrice
		table.insert(options, {
			title = prisoner.name,
			description = 'Còn ' .. prisoner.actionsRemaining .. ' bãi | Giá: $' .. totalCost,
			icon = 'fa-solid fa-user',
			onSelect = function()
				-- Bỏ input dialog, xác nhận trực tiếp
				local alert = lib.alertDialog({
					header = 'Xác nhận chuộc tù',
					content = 'Bạn có muốn chuộc tù cho ' .. prisoner.name .. ' với số tiền $' .. totalCost .. '?',
					centered = true,
					cancel = true
				})
				
				if alert == 'confirm' then
					TriggerServerEvent('esx_communityservice:buyoutForOther', prisoner.source, prisoner.actionsRemaining)
				end
			end
		})
	end
	
	lib.registerContext({
		id = 'prisoner_list_buyout',
		title = 'Danh Sách Tù Nhân',
		options = options
	})
	
	lib.showContext('prisoner_list_buyout')
end)

RegisterNetEvent('esx_communityservice:showVisitList', function(prisonerList)
	if not prisonerList or #prisonerList == 0 then
		exports.qbx_core:Notify('Không có tù nhân nào!', 'error', 3000)
		return
	end
	
	local options = {}
	for _, prisoner in ipairs(prisonerList) do
		table.insert(options, {
			title = prisoner.name,
			description = 'Gửi yêu cầu thăm tù | Phí: $' .. Config.VisitFee,
			icon = 'fa-solid fa-user-friends',
			onSelect = function()
				local alert = lib.alertDialog({
					header = 'Xác nhận thăm tù',
					content = 'Gửi yêu cầu thăm ' .. prisoner.name .. '? (Phí: $' .. Config.VisitFee .. ' khi kết thúc)',
					centered = true,
					cancel = true
				})
				
				if alert == 'confirm' then
					TriggerServerEvent('esx_communityservice:requestVisit', prisoner.source)
				end
			end
		})
	end
	
	lib.registerContext({
		id = 'prisoner_list_visit',
		title = 'Danh Sách Tù Nhân',
		options = options
	})
	
	lib.showContext('prisoner_list_visit')
end)

RegisterNetEvent('esx_communityservice:receiveVisitRequest', function(visitorName, visitorSource)
	local alert = lib.alertDialog({
		header = 'Yêu cầu thăm tù',
		content = visitorName .. ' muốn thăm bạn. Đồng ý?',
		centered = true,
		cancel = true
	})
	
	if alert == 'confirm' then
		TriggerServerEvent('esx_communityservice:acceptVisit', visitorSource)
	else
		TriggerServerEvent('esx_communityservice:denyVisit', visitorSource)
	end
end)

-- Event backup cho playerSpawned
AddEventHandler('playerSpawned', function()
	Wait(10000) -- Đợi 10 giây để player load hoàn toàn
	--print("Player spawned, kiểm tra trạng thái phạt lao động...")
	TriggerServerEvent('esx_communityservice:checkIfSentenced')
end)

RegisterNetEvent('esx_communityservice:finishCommunityService', function(source)
	--print("Received finishCommunityService event")
	
	-- Clear player state
	LocalPlayer.state:set('isSentenced', false, true)
	CleanupCommunityService() -- Cleanup tất cả objects
	communityServiceFinished = true
	isSentenced = false
	actionsRemaining = 0
end)

-- Event riêng cho client cleanup (không gọi lại server)
RegisterNetEvent('esx_communityservice:finishCommunityServiceClient', function()
	--print("Received finishCommunityServiceClient event - cleanup only")
	
	-- Clear player state
	LocalPlayer.state:set('isSentenced', false, true)
	CleanupCommunityService() -- Cleanup tất cả objects
	communityServiceFinished = true
	isSentenced = false
	actionsRemaining = 0
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		CleanupCommunityService() -- Sử dụng cleanup function thống nhất
	end
end)

function RequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)
		while not HasAnimDictLoaded(animDict) do
			Wait(0)
		end
	end

	if cb  then
		cb()
	end
end

function Round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

-- Helper function để tạo object an toàn
function CreateObjectSafely(modelHash, x, y, z, dynamic, hasPhysics, addToMap)
	local maxTries = 3
	local tries = 0
	local obj = nil
	
	while tries < maxTries and not DoesEntityExist(obj) do
		tries = tries + 1
		obj = CreateObject(modelHash, x, y, z, dynamic or true, hasPhysics or true, addToMap or true)
		
		if DoesEntityExist(obj) then
			--print("Tạo object thành công sau " .. tries .. " lần thử")
			return obj
		else
			--print("Lần thử " .. tries .. " thất bại, thử lại sau 100ms...")
			Wait(100)
		end
	end
	
	--print("CẢNH BÁO: Không thể tạo object sau " .. maxTries .. " lần thử!")
	return nil
end

-- Function để xóa tất cả objects và reset
function CleanupCommunityService()
	--print("Cleanup: Đang xóa tất cả objects...")
	
	-- Xóa tất cả objects
	for k, v in pairs(object) do
		if DoesEntityExist(v) then
			DeleteEntity(v)
			--print("Cleanup: Đã xóa object " .. tostring(v))
		end
	end
	object = {} -- Reset table
	
	-- Reset available actions
	availableActions = {}
	
	-- Reset các biến
	shit = nil
	nearObj = nil
	-- showtext = false
	
	-- Giải phóng đóng băng player
	local playerPed = PlayerPedId()
	FreezeEntityPosition(playerPed, false)
	
	-- Xóa chổi quét nếu có
	if vassour_net and DoesEntityExist(NetToObj(vassour_net)) then
		local broomObj = NetToObj(vassour_net)
		DetachEntity(broomObj, 1, 1)
		DeleteEntity(broomObj)
		vassour_net = nil
	end
	
	--print("Cleanup: Hoàn thành cleanup community service")
end

function FillActionTable(last_action)
	-- Chỉ kiểm tra safeguard khi được gọi từ completion (có last_action)
	-- Không kiểm tra khi lần đầu bắt đầu phạt
	if last_action and (actionsRemaining <= 0 or not isSentenced) then
		--print("Không tạo prop mới vì đã hoàn thành phạt")
		return
	end
	
	--print("FillActionTable: actionsRemaining = " .. actionsRemaining .. ", isSentenced = " .. tostring(isSentenced))
	
	-- Đảm bảo model được load hoàn toàn
	local modelHash = GetHashKey('prop_weeds_nxg06b')
	RequestModel(modelHash)
	
	local timeout = 0
	while not HasModelLoaded(modelHash) and timeout < 5000 do
		Wait(10)
		timeout = timeout + 10
	end
	
	-- Nếu không load được model, thử model backup
	if not HasModelLoaded(modelHash) then
		--print("CẢNH BÁO: Không thể load model prop_weeds_nxg06b, sử dụng model backup")
		modelHash = GetHashKey('prop_cs_cardboard_01') -- Model backup
		RequestModel(modelHash)
		
		timeout = 0
		while not HasModelLoaded(modelHash) and timeout < 5000 do
			Wait(10)
			timeout = timeout + 10
		end
		
		if not HasModelLoaded(modelHash) then
			--print("LỖI: Không thể load bất kỳ model nào!")
			return
		end
	end
	
	while #availableActions < 1 do
        shit = nil
		local service_does_not_exist = true
		local random_selection = Config.ServiceLocations[math.random(1,#Config.ServiceLocations)]
		for i = 1, #availableActions do
			if random_selection.coords.x == availableActions[i].coords.x and random_selection.coords.y == availableActions[i].coords.y and random_selection.coords.z == availableActions[i].coords.z then

				service_does_not_exist = false
			end
		end
		if last_action  and random_selection.coords.x == last_action.coords.x and random_selection.coords.y == last_action.coords.y and random_selection.coords.z == last_action.coords.z then
			service_does_not_exist = false
		end
		if service_does_not_exist then
			table.insert(availableActions, random_selection)
		end
    end

	-- Tạo objects với kiểm tra lỗi - CHỈ HIỂN THỊ CHO PLAYER BỊ PHẠT
	for i = 1, #availableActions do
		local coords = availableActions[i].coords
		shit = CreateObjectSafely(modelHash, coords.x, coords.y, coords.z)
		
		-- Kiểm tra xem object có được tạo thành công không
		if shit and DoesEntityExist(shit) then
			PlaceObjectOnGroundProperly(shit) -- Đặt object đúng vị trí trên mặt đất
			FreezeEntityPosition(shit, true) -- Đóng băng object
			
			-- Đảm bảo object không bị despawn
			SetEntityAsMissionEntity(shit, true, true)
			
			-- TĂNG HIỆU SUẤT - CHỈ LOCAL OBJECT
			SetEntityAlpha(shit, 255, false) -- Đảm bảo object hiển thị đầy đủ
			SetEntityCollision(shit, false, false) -- Tắt collision để tối ưu
			
			table.insert(object, shit)
			--print("Tạo thành công object tại: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
		else
			--print("LỖI: Không thể tạo object tại: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
			-- Thử tạo một marker thay thế nếu không tạo được object
			--print("Sử dụng marker thay thế cho vị trí này")
		end
	end
	
	-- Giải phóng model sau khi sử dụng
	SetModelAsNoLongerNeeded(modelHash)
end

CreateThread(function()
	while true do
		local sleep = 1000 -- Tăng sleep mặc định
		
		if actionsRemaining > 0 and isSentenced then
			local player = PlayerPedId()
			
			-- Cache player coords để tối ưu - update thường xuyên hơn cho responsive
			coordsUpdateTimer = coordsUpdateTimer + sleep
			if coordsUpdateTimer >= 250 then -- Giảm từ 500ms → 250ms để responsive hơn
				lastPlayerCoords = GetEntityCoords(player)
				coordsUpdateTimer = 0
			end
			
			DisableViolentActions()
            
			for i = 1, #availableActions do
				-- Sử dụng tọa độ gốc từ config để tính khoảng cách
				local distance = #(lastPlayerCoords - availableActions[i].coords)

				if distance < 3.0 then -- Giảm xuống 3.0m cho chính xác
					sleep = 0 -- Set 0 để phản hồi tức thì khi ở gần
					nearObj = i
					-- if not showtext then
					--	showtext = true
					--	-- exports["qb-core"]:DrawText(_U('press_to_start'))
					-- end
					
					if IsControlJustReleased(1, 38) then
						tmp_action = availableActions[i]
						disable_actions = true

						if (tmp_action.type == "cleaning") then
							-- exports["qb-core"]:HideText()

							local cSCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
							local vassouspawn = CreateObject(GetHashKey(vassoumodel), cSCoords.x, cSCoords.y, cSCoords.z, 1, 1, 1)
							local netid = ObjToNet(vassouspawn)
							FreezeEntityPosition(player, true)
							AttachEntityToEntity(vassouspawn,GetPlayerPed(PlayerId()),GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422),-0.005,0.0,0.0,360.0,360.0,0.0,1,1,0,1,0,1)
							vassour_net = netid

							TriggerEvent("progressbar:client:progress", {		
								name = "unique_action_name",
								duration = 10000,
								label = 'Đang quét rác...',
								useWhileDead = false,
								canCancel = false,
								controlDisables = {
									disableMovement = true,
									disableCarMovement = true,
									disableMouse = false,
									disableCombat = true,
								},
								animation = {
									animDict = 'amb@world_human_janitor@male@idle_a',
									anim = 'idle_a',
									flags = 0,
								},
								}, function(status)
								if not status then
									disable_actions = false
									DetachEntity(NetToObj(vassour_net), 1, 1)
									DeleteEntity(NetToObj(vassour_net))
									vassour_net = nil
									ClearPedTasks(player)
									
									-- Xóa object cẩn thận
									if shit and DoesEntityExist(shit) then
										DeleteObject(shit)
										--print("Đã xóa object thành công")
									else
										--print("CẢNH BÁO: Object không tồn tại hoặc đã bị xóa")
									end
									shit = nil
									
									TriggerServerEvent('esx_communityservice:completeService')
									RemoveAction(tmp_action)
									FreezeEntityPosition(player, false)
									
									actionsRemaining = actionsRemaining - 1
		
									if actionsRemaining > 0 then
										-- Chỉ tạo prop mới khi còn phạt
										FillActionTable(tmp_action)
								exports.qbx_core:Notify("Bạn còn "..actionsRemaining.." bãi", "warning", 10000)
									else
										-- Đã hoàn thành tất cả, không tạo prop mới
										--print("Đã hoàn thành tất cả " .. (actionsRemaining + 1) .. " bãi lao động")
									end
								end
							end)
						end
					end
				else

					if nearObj == i then
						-- exports["qb-core"]:HideText()
						-- showtext = false
						nearObj = nil
					end
				end
			end
		end
		Wait(sleep)
	end
end)

function RemoveAction(action)
	local action_pos = -1
	for i=1, #availableActions do
		if action.coords.x == availableActions[i].coords.x and action.coords.y == availableActions[i].coords.y and action.coords.z == availableActions[i].coords.z then
			action_pos = i
		end
	end

	if action_pos ~= -1 then
		table.remove(availableActions, action_pos)
	end
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function DrawAvailableActions()
	local playerCoords = GetEntityCoords(PlayerPedId())
	
	for i = 1, #availableActions do
		local coords = availableActions[i].coords
		local distance = #(playerCoords - coords)
		
		-- Chỉ vẽ marker trong phạm vi 50m để tối ưu
		if distance < 50.0 then
			-- Vẽ marker số 2 (cone) màu xanh dương trên đầu các điểm dọn vệ sinh
			DrawMarker(2, coords.x, coords.y, coords.z + 1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 50, 150, 255, 200, false, true, 2, false, nil, nil, false)
		end
	end
end

function DisableViolentActions()
	local playerPed = PlayerPedId()

	-- Chỉ disable controls khi đang trong progress bar
	if disable_actions == true then
		DisableAllControlActions(0)
		return -- Exit early khi disable_actions = true
	end

	-- Các disable action cơ bản - tối ưu
	RemoveAllPedWeapons(playerPed, true)
    DisableControlAction(0, Keys['TAB'], true)
	DisableControlAction(0, Keys['X'], true)
	DisableControlAction(0, Keys['T'], true)
	DisableControlAction(2, 37, true) -- disable weapon wheel (Tab)
	DisablePlayerFiring(playerPed, true) -- Disables firing all together
    DisableControlAction(0, 106, true) -- Disable in-game mouse controls

	-- Kiểm tra input chỉ khi cần thiết
	if IsDisabledControlJustPressed(2, 37) then --if Tab is pressed
		SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
	end

	if IsDisabledControlJustPressed(0, 106) then --if LeftClick is pressed
		SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
	end
end

function ApplyPrisonerSkin()
	local playerPed = PlayerPedId()
	if DoesEntityExist(playerPed) then
		Citizen.CreateThread(function()
			SetPedArmour(playerPed, 0)
			ClearPedBloodDamage(playerPed)
			ResetPedVisibleDamage(playerPed)
			ClearPedLastWeaponDamage(playerPed)
			ResetPedMovementClipset(playerPed, 0)
			local gender = exports.qbx_core:GetPlayerData().charinfo.gender
			if gender == 0 then
				TriggerEvent('qb-clothing:client:loadOutfit', Config.Uniforms.male)
			else
				TriggerEvent('qb-clothing:client:loadOutfit', Config.Uniforms.female)
			end
		end)
	end
end

function draw2dText(text, pos)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.45, 0.45)
	SetTextColour(255, 255, 255, 255)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(table.unpack(pos))
end

function Teleport(entity, coords, cb)
	local vector = type(coords) == "vector4" and coords or type(coords) == "vector3" and vector4(coords, 0.0) or vec(coords.x, coords.y, coords.z, coords.heading or 0.0)

	if DoesEntityExist(entity) then
		RequestCollisionAtCoord(vector.xyz)
		while not HasCollisionLoadedAroundEntity(entity) do
			Wait(0)
		end

		SetEntityCoords(entity, vector.xyz, false, false, false, false)
		SetEntityHeading(entity, vector.w)
	end

	if cb then
		cb()
	end
end


-- Event phạt lao động
RegisterNetEvent("nl_hotcut:phatlaodong", function()
	TriggerServerEvent('esx_communityservice:openPunishDialog')
end)

-- Event hủy phạt lao động
RegisterNetEvent("nl_hotcut:huyphatlaodong", function()
	TriggerServerEvent('esx_communityservice:openReleasePunishDialog')
end)

-- Dialog phạt lao động
RegisterNetEvent('esx_communityservice:showPunishDialog', function()
	local input = lib.inputDialog('Phạt Lao Động Công Ích', {
		{type = 'number', label = 'PID người chơi', description = 'Nhập PID của người chơi cần phạt', required = true, min = 1},
		{type = 'number', label = 'Số bãi dọn dẹp', description = 'Nhập số bãi dọn dẹp', required = true, min = 1, default = 10}
	})
	
	if input then
		local targetPid = input[1]
		local actionsCount = input[2]
		
		TriggerServerEvent('esx_communityservice:sendToCommunityService', targetPid, actionsCount)
	end
end)

-- Dialog hủy phạt lao động
RegisterNetEvent('esx_communityservice:showReleasePunishDialog', function()
	local input = lib.inputDialog('Hủy Phạt Lao Động', {
		{type = 'number', label = 'PID người chơi', description = 'Nhập PID của người chơi cần hủy phạt', required = true, min = 1}
	})
	
	if input then
		local targetPid = input[1]
		
		TriggerServerEvent('esx_communityservice:processReleasePunish', targetPid)
	end
end)

RegisterNetEvent("nl_hotcut:client:acp")
AddEventHandler("nl_hotcut:client:acp", function(id_player, name)
	SendNUIMessage({
		action = "open_modal",
		id_pl = id_player,
		name_pl = name,
	})
	-- --print(id_player)
	SetNuiFocus(true, true)
end)

RegisterNUICallback('hoantat', function(data)
	
	TriggerServerEvent('esx_communityservice:sendToCommunityService', tonumber(data.id_member), tonumber(data.solan))
	SetNuiFocus(false, false)
end)

RegisterNUICallback('tat', function()
	SetNuiFocus(false, false)
end)

RegisterNUICallback('gui', function(data)
	 TriggerServerEvent('nl_hotcut:gin:send')
	SetNuiFocus(false, false)
end)

-- Command test để check trạng thái phạt lao động
-- RegisterCommand("checkcommunity", function()
-- 	--print("Đang kiểm tra trạng thái phạt lao động...")
-- 	TriggerServerEvent('esx_communityservice:checkIfSentenced')
-- end)

-- ============= COMMANDS CHO PHẠT OFFLINE =============
RegisterNetEvent("nl_hotcut:phatlogout2", function()
	TriggerServerEvent('esx_communityservice:openOfflinePunishDialog')
end)

RegisterNetEvent("nl_hotcut:huyphatoffline2", function()
	TriggerServerEvent('esx_communityservice:openReleaseOfflineDialog')
end)

-- ============= DIALOG CHO PHẠT OFFLINE =============
-- Dialog phạt offline
RegisterNetEvent('esx_communityservice:showOfflinePunishDialog', function()
	local input = lib.inputDialog('Phạt Tù Offline', {
		{type = 'number', label = 'PID người chơi', description = 'Nhập PID của người chơi cần phạt', required = true, min = 1},
		{type = 'input', label = 'Lý do phạt', description = 'Nhập lý do phạt (tùy chọn)', placeholder = 'Vi phạm khi offline'}
	})
	
	if input then
		local pid = input[1]
		local reason = input[2] or "Vi phạm khi offline"
		
		TriggerServerEvent('esx_communityservice:processOfflinePunish', pid, reason)
	end
end)

-- Dialog hủy phạt offline
RegisterNetEvent('esx_communityservice:showReleaseOfflineDialog', function()
	local input = lib.inputDialog('Thả Tù Offline', {
		{type = 'number', label = 'PID người chơi', description = 'Nhập PID của người chơi cần thả', required = true, min = 1}
	})
	
	if input then
		local pid = input[1]
		
		TriggerServerEvent('esx_communityservice:processReleaseOffline', pid)
	end
end)

-- ============= PHẠT OFFLINE SYSTEM =============
local isOfflinePunished = false
local defaultReleaseLocation = vec3(31.86, -414.01, 33.56)
local offlinePunishLocation = defaultReleaseLocation

-- Event bắt đầu phạt offline
RegisterNetEvent('esx_communityservice:startOfflinePunishment', function()
	local playerPed = PlayerPedId()
	
	isOfflinePunished = true
	
	-- Áp dụng trang phục tù nhân
	ApplyPrisonerSkin()
	
	-- Chọn vị trí giam ngẫu nhiên trong đồn PD từ Config
	if Config.OfflinePrisonLocations and #Config.OfflinePrisonLocations > 0 then
		local randomCell = Config.OfflinePrisonLocations[math.random(1, #Config.OfflinePrisonLocations)]
		offlinePunishLocation = vec3(randomCell.x, randomCell.y, randomCell.z)
		
		-- Teleport người chơi tới phòng giam ngẫu nhiên
		SetEntityCoords(playerPed, randomCell.x, randomCell.y, randomCell.z, false, false, false, true)
		SetEntityHeading(playerPed, randomCell.w)
	else
		offlinePunishLocation = defaultReleaseLocation
		SetEntityCoords(playerPed, offlinePunishLocation.x, offlinePunishLocation.y, offlinePunishLocation.z, false, false, false, true)
	end
	
	exports.qbx_core:Notify("Bạn đang bị tạm giam do vi phạm khi offline. Hãy liên hệ cảnh sát để được giải quyết!", "error", 10000)
	
	-- Bắt đầu thread kiểm tra khoảng cách
	CreateThread(function()
		while isOfflinePunished do
			Wait(1000)
			
			local currentPed = PlayerPedId()
			if currentPed and currentPed ~= 0 and DoesEntityExist(currentPed) then
				local playerCoords = GetEntityCoords(currentPed)
				local distance = #(playerCoords - offlinePunishLocation)
				
				-- Nếu đi quá 10 dist thì rollback (để tránh leo ra khỏi phòng giam)
				if distance > 10.0 then
					SetEntityCoords(currentPed, offlinePunishLocation.x, offlinePunishLocation.y, offlinePunishLocation.z, false, false, false, true)
					exports.qbx_core:Notify("Bạn không được rời khỏi phòng giam!", "error", 5000)
				end
			end
		end
	end)
end)

-- Event hủy phạt offline
RegisterNetEvent('esx_communityservice:releaseOfflinePunishment', function()
	isOfflinePunished = false
	
	-- Teleport ra ngoài phòng giam (hành lang đồn PD)
	local playerPed = PlayerPedId()
	SetEntityCoords(playerPed, defaultReleaseLocation.x, defaultReleaseLocation.y, defaultReleaseLocation.z, false, false, false, true)
	
	-- Trả lại quần áo ban đầu
	TriggerServerEvent('clothes:reloadPlayerClothes')
	
	exports.qbx_core:Notify("Phạt offline của bạn đã được hủy. Bạn có thể di chuyển tự do!", "success", 5000)
end)