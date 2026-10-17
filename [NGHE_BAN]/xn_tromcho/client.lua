local player = PlayerPedId()
local entities = {} 
local Catching = false
local Holding = false
local CurrentHolding = nil
local IconBlip = nil
local RadiusBlip = nil
local InDogZone = false
local IsCorrectTime = false
local DogModels = {}
local NearestDog = nil -- Lưu con chó gần nhất để sử dụng item

-- V3.2: Biến cho hệ thống auto display dog
local CurrentDogPed = nil -- Chó đang theo
local CurrentDogItem = nil -- Item chó hiện tại
local LastInventoryCheck = 0
local getCops = 0

-- Function để get số lượng cảnh sát an toàn
local function GetPoliceCount()
	return GlobalState['police_count'] or 0
end

-- Pre-hash dog models for performance
local function InitDogModels()
	if next(DogModels) == nil then
		for i, ped in ipairs(Config.Peds) do
			DogModels[GetHashKey(ped)] = true
		end
	end
end

local function PoliceCall()
	TriggerEvent('mini-mdt:client:setCooldown', 30, "Bị cấm vào Red Zone do vừa trong tình huống phó bản khác") 
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    exports['ld-dispatch']:sendDispatch(
        {
            title = "TRỘM CHÓA NÈ",
            code = "11-10B",
            values = {
                {
                    text = "NHÀ CHÓA",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "2 sao",
                    icon = "fa-solid fa-hashtag",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = plyCoords,
            blip = {
                blipid = 463,
                blipcolor = 1,
            }
        }
    ) 
end

function IsPlayerInDogZone()
    local myPos = GetEntityCoords(PlayerPedId())
    return #(myPos - Config.ToaDo) <= Config.PhamVi
end

-- Blip management with time check
local function ManageBlips()
	local Hours = GetClockHours()
	local shouldShow = false
	
	-- Xử lý trường hợp qua nửa đêm (ví dụ: 18h đến 6h sáng)
	if Config.MinTime > Config.MaxTime then
		-- Qua nửa đêm: 18-23 HOẶC 0-6
		shouldShow = Hours >= Config.MinTime or Hours <= Config.MaxTime
	else
		-- Trong cùng ngày: 18-23
		shouldShow = Hours >= Config.MinTime and Hours <= Config.MaxTime
	end
	
	IsCorrectTime = shouldShow
	
	if Config.Debug then
		print("[DEBUG] Current Hour: " .. Hours .. " | MinTime: " .. Config.MinTime .. " | MaxTime: " .. Config.MaxTime .. " | shouldShow: " .. tostring(shouldShow))
	end
	
	if Config.HienBlip then
		if shouldShow then
			if not DoesBlipExist(IconBlip) then
				IconBlip = AddBlipForCoord(Config.ToaDo)
				RadiusBlip = AddBlipForRadius(Config.ToaDo, Config.PhamVi)        
				SetBlipRotation(RadiusBlip, 0)
				SetBlipColour(RadiusBlip, Config.BigColour)
				SetBlipAlpha(RadiusBlip, Config.BigAlpha)
				SetBlipSprite (IconBlip, Config.Icon)
				SetBlipDisplay(IconBlip, 4)
				SetBlipScale  (IconBlip, Config.Scale)
				SetBlipAsShortRange(IconBlip, true)
				SetBlipColour(IconBlip, Config.Colour)
				SetBlipAlpha(IconBlip, Config.Alpha)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentSubstringPlayerName(Config.Title)	
				EndTextCommandSetBlipName(IconBlip)
			end
		else
			if DoesBlipExist(IconBlip) then
				RemoveBlip(IconBlip)
				RemoveBlip(RadiusBlip)
				IconBlip = nil
				RadiusBlip = nil
			end
		end
	end
end

-- Event-driven blip management using timer
local blipTimer = nil

local function StartBlipTimer()
	if blipTimer then return end
	
	ManageBlips() -- Initial setup
	
	blipTimer = SetTimeout(5000, function() -- Giảm từ 60s xuống 5s để responsive hơn
		blipTimer = nil
		ManageBlips()
		StartBlipTimer() -- Restart timer
	end)
end

-- Đảm bảo blip được tạo ngay khi resource start
CreateThread(function()
	Wait(1000) -- Đợi 1 giây để game load xong
	StartBlipTimer()
	if Config.Debug then
		print("[DEBUG BLIP] Blip management started!")
	end
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() ~= name then
        return
    end

    for key, value in pairs(entities) do
        DeleteEntity(value)
    end
end)

function RequestAnimationDict(AnimDict)
	if not HasAnimDictLoaded(AnimDict) then
		RequestAnimDict(AnimDict)
		while not HasAnimDictLoaded(AnimDict) do
			Wait(10)
		end
	end
end

-- Holding animation handler (event-driven)
local function HandleHoldingAnimation()
	if Holding then
		local playerPed = PlayerPedId()
		if not IsEntityPlayingAnim(playerPed, 'anim@heists@box_carry@', 'idle', 3) then
			RequestAnimationDict("anim@heists@box_carry@")
			TaskPlayAnim(playerPed, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
		end
		
		-- Giới hạn di chuyển: chỉ đi bộ, không chạy/nhảy/đấm
		-- DisableControlAction(0, 21, true)  -- Disable Sprint
		DisableControlAction(0, 22, true)  -- Disable Jump
		DisableControlAction(0, 36, true)  -- Disable Ctrl (duck)
		DisableControlAction(0, 24, true)  -- Disable Attack (left click/R2)
		DisableControlAction(0, 25, true)  -- Disable Aim (right click/L2)
		DisableControlAction(0, 140, true) -- Disable Melee Attack (R/Circle)
		DisableControlAction(0, 141, true) -- Disable Melee Attack Alternate
		DisableControlAction(0, 142, true) -- Disable Melee Attack Light
		DisableControlAction(0, 143, true) -- Disable Melee Attack Heavy
		
		-- CHỈ CHẶN LÊN XE KHI ĐANG VÁC CHÓ VÀ XE KHÔNG HỢP LỆ
		if not IsPedInAnyVehicle(playerPed, false) then
			local nearbyVehicle = GetVehiclePedIsTryingToEnter(playerPed)
			if nearbyVehicle and DoesEntityExist(nearbyVehicle) then
				local vehicleModel = GetEntityModel(nearbyVehicle)
				
				-- Kiểm tra xe có trong danh sách cho phép không (so sánh model hash)
				local isAllowed = false
				if Config.AllowedVehicles then
					for _, allowedVehicle in pairs(Config.AllowedVehicles) do
						if vehicleModel == GetHashKey(allowedVehicle) then
							isAllowed = true
							break
						end
					end
				end
				
				-- Nếu xe không hợp lệ → CHẶN LÊN XE
				if not isAllowed then
					DisableControlAction(0, 23, true) -- Disable Enter Vehicle (F)
					ClearPedTasks(playerPed)
					exports.ox_lib:notify({
						title = 'Cảnh báo!',
						description = 'Phương tiện này không thể thực hiện hành vi trộm chó!',
						type = 'error'
					})
				end
			end
		end
	end
end

-- Combined animation and metadata handler (merged 2 threads into 1)
CreateThread(function()
	local lastBarkTime = 0
	local lastMetaCheck = 0
	local lastVehicleCheck = 0
	local lastCameraFix = 0
	
	while true do
		local currentTime = GetGameTimer()
		
		if Holding then
			-- Kiểm tra entity còn tồn tại không (có thể mất do đổi routing bucket)
			if CurrentHolding and not DoesEntityExist(CurrentHolding) then
				if CurrentDogNetId then
					TriggerServerEvent('xn_tromcho:server:DeleteOrphanEntity', CurrentDogNetId)
					CurrentDogNetId = nil
				end
				CurrentHolding = nil
				CurrentDogPed = nil
				CurrentDogItem = nil
				Holding = false
				ClearPedTasksImmediately(PlayerPedId())
				if Config.Debug then
					print("[DEBUG] Anim thread: entity mất do đổi bucket → reset Holding")
				end
				Wait(2000)
				goto continue
			end
			
			Wait(0) -- Phải chạy mỗi frame để disable controls liên tục
			HandleHoldingAnimation()
			
			-- Fix camera khi vác chó trên xe (chạy mỗi 100ms)
			if currentTime - lastCameraFix >= 100 then
				lastCameraFix = currentTime
				local playerPed = PlayerPedId()
				
				if IsPedInAnyVehicle(playerPed, false) and CurrentHolding and DoesEntityExist(CurrentHolding) then
					-- Tạm thời disable collision của chó để không ảnh hưởng camera
					SetEntityCollision(CurrentHolding, false, false)
					
					-- Đảm bảo chó không ảnh hưởng đến vehicle physics
					SetEntityProofs(CurrentHolding, true, true, true, true, true, true, true, true)
					
					-- FREEZE CHÓ để không xoay và giật trên xe - HƯỚNG RA NGOÀI
					FreezeEntityPosition(CurrentHolding, true)
					SetEntityRotation(CurrentHolding, -90.0, 0.0, 90.0, 2, true) -- Nằm ngang hướng ra ngoài
					SetPedCanRagdoll(CurrentHolding, false)
					
					-- Adjust attachment để camera không bị conflict - CHÓ NẰM NGANG RA TRƯỚC
					local bone = GetPedBoneIndex(playerPed, 28422)
					-- Dời chó xa hơn và thấp hơn khi đang trên xe, rotation để nằm ngang
					AttachEntityToEntity(CurrentHolding, playerPed, bone, 0.2, -0.1, -0.2, -90.0, 0.0, 90.0, true, false, false, false, 1, true)
				elseif CurrentHolding and DoesEntityExist(CurrentHolding) then
					-- Khôi phục collision khi không trên xe (nhưng vẫn freeze vì đang vác)
					SetEntityCollision(CurrentHolding, true, true)
					SetEntityProofs(CurrentHolding, false, false, false, false, false, false, false, false)
					
					-- VẪN FREEZE CHÓ khi đi bộ để không xoay giật - HƯỚNG RA NGOÀI
					FreezeEntityPosition(CurrentHolding, true)
					SetEntityRotation(CurrentHolding, -90.0, 0.0, 90.0, 2, true) -- Nằm ngang hướng ra ngoài
					SetPedCanRagdoll(CurrentHolding, false)
					
					-- Attachment khi đi bộ - CHÓ NẰM NGANG RA TRƯỚC
					local bone = GetPedBoneIndex(playerPed, 28422)
					AttachEntityToEntity(CurrentHolding, playerPed, bone, 0.2, -0.1, -0.1, -90.0, 0.0, 90.0, true, false, false, false, 1, true)
				end
			end
			
			-- Kiểm tra xe không hợp lệ khi vác chó
			if currentTime - lastVehicleCheck >= 100 then
				lastVehicleCheck = currentTime
				local playerPed = PlayerPedId()
				
				if IsPedInAnyVehicle(playerPed, false) then
					local vehicle = GetVehiclePedIsIn(playerPed, false)
					local vehicleModel = GetEntityModel(vehicle)
				local seatIndex = -1
				
				-- Tìm vị trí ghế của player
				for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
					if GetPedInVehicleSeat(vehicle, i) == playerPed then
						seatIndex = i
						break
					end
				end
				
				-- Kiểm tra xe có trong danh sách cho phép không (so sánh model hash)
				local isAllowed = false
				if Config.AllowedVehicles then
					for _, allowedVehicle in pairs(Config.AllowedVehicles) do
						if vehicleModel == GetHashKey(allowedVehicle) then
							isAllowed = true
							break
						end
					end
				end
				
				local shouldKick = false
				local kickReason = ""
					
					-- Nếu không phải xe được phép → Kick
					if not isAllowed then
						shouldKick = true
						kickReason = "Phương tiện này không thể thực hiện hành vi trộm chó."
					-- Nếu đang ngồi ghế lái (seat -1) → Kick
					elseif seatIndex == -1 then
						shouldKick = true
						kickReason = "Không thể lái xe khi đang vác chó! Chỉ được ngồi ghế sau."
					end
					
					-- Kick khỏi xe và thả chó
					if shouldKick then
						TaskLeaveVehicle(playerPed, vehicle, 16) -- Force exit
						
						exports.ox_lib:notify({
							title = 'Cảnh báo!',
							description = kickReason,
							type = 'error'
						})
						
						-- Thả chó xuống
						if DoesEntityExist(CurrentHolding) then
							DetachEntity(CurrentHolding, true, true)
							DeleteEntity(CurrentHolding)
							SetPedAsNoLongerNeeded(CurrentHolding)
							CurrentHolding = nil
							Holding = false
							ClearPedTasksImmediately(playerPed)
							
							-- Reset auto-display variables
							if CurrentDogPed then
								DeleteEntity(CurrentDogPed)
								CurrentDogPed = nil
								CurrentDogItem = nil
							end
						end
					end
				end
			end
			
			-- Dog barking sound
			if DoesEntityExist(CurrentHolding) then
				if currentTime - lastBarkTime >= 15000 then
					local nextBark = math.random(15000, 30000)
					if currentTime - lastBarkTime >= nextBark then
						TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 6.5, "chosua", 0.18)
						lastBarkTime = currentTime
					end
				end
			end
			
			-- Metadata check (merged from separate thread)
			if currentTime - lastMetaCheck >= 1000 then
				lastMetaCheck = currentTime
				local pdata = CoreName.Functions.GetPlayerData()
				local meta = pdata and pdata.metadata
				
				if meta and (meta["ishandcuffed"] or meta["isdead"] or meta["inlaststand"]) then 
					if DoesEntityExist(CurrentHolding) then
						DetachEntity(CurrentHolding, true, true)
						SetPedAsNoLongerNeeded(CurrentHolding)
						CurrentHolding = nil
						Holding = false
						ClearPedTasksImmediately(PlayerPedId())
						
						-- Reset auto-display variables
						if CurrentDogPed then
							DeleteEntity(CurrentDogPed)
							CurrentDogPed = nil
							CurrentDogItem = nil
						end
					end 
				end
			end
		else
			Wait(2000) -- Sleep longer when not holding
		end
		::continue::
	end
end)

-- Optimized dog check using pre-hashed models
function IsDog(entity)
	InitDogModels() -- Ensure models are initialized
	return DogModels[GetEntityModel(entity)] == true
end

function GetNearbyPed()
	local PlayerPeds = {}
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        table.insert(PlayerPeds, ped)
    end
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
	local closestPed, closestDistance = CoreName.Functions.GetClosestPed(coords, PlayerPeds)
	
	if closestPed and closestDistance < 2.0 then
		if not IsEntityDead(closestPed) and not IsPedHuman(closestPed) and IsDog(closestPed) then
			return closestPed
		end
	end
	return nil
end

-- Metadata check merged into animation thread above (removed duplicate thread)

-- Chọn chó theo độ hiếm (rarity system)
function SelectDogByRarity()
	if not Config.DogRarity then
		-- Fallback về random cũ nếu không có config
		return Config.Peds[math.random(#Config.Peds)]
	end
	
	local random = math.random(1, 100)
	local cumulative = 0
	
	for pedModel, chance in pairs(Config.DogRarity) do
		cumulative = cumulative + chance
		if random <= cumulative then
			return GetHashKey(pedModel)
		end
	end
	
	-- Fallback nếu có lỗi
	return GetHashKey(Config.Peds[1])
end

-- Optimized dog spawning system
local function CleanupDogs()
	for i = #entities, 1, -1 do
		local ped = entities[i]
		if DoesEntityExist(ped) then
			local model = GetEntityModel(ped)
			SetEntityAsNoLongerNeeded(ped)
			SetModelAsNoLongerNeeded(model)
			DeleteEntity(ped)
		end
		table.remove(entities, i)
	end
	
	if Holding then
		Holding = false
		CurrentHolding = nil
	end
end

local function SpawnDog()
	-- Sử dụng hệ thống độ hiếm để chọn chó
	local model = SelectDogByRarity()
	if not model then return end
	
	RequestModel(model)
	
	local timeout = 0
	while not HasModelLoaded(model) and timeout < 100 do
		Wait(10)
		timeout = timeout + 1
	end
	
	if not HasModelLoaded(model) then return end
	
	local posX = Config.ToaDo.x + math.random(-Config.PhamVi/2, Config.PhamVi/2)
	local posY = Config.ToaDo.y + math.random(-Config.PhamVi/2, Config.PhamVi/2)
	local Z = Config.ToaDo.z + 999.0
	local heading = math.random(0, 359) + 0.0
	
	local Ground, posZ = GetGroundZFor_3dCoord(posX, posY, Z, true)
	
	if Ground then
		local ped = CreatePed(28, model, posX, posY, posZ, heading, true, true)
		SetEntityAsMissionEntity(ped, true, true)
		TaskWanderStandard(ped, 10.0, 10)
		SetModelAsNoLongerNeeded(model)
		table.insert(entities, ped)
		-- Đặt entity vào đúng routing bucket của player
		local dogNetId = NetworkGetNetworkIdFromEntity(ped)
		TriggerServerEvent('xn_tromcho:server:RegisterEntityBucket', dogNetId)
		
		-- GPS của từng con chó đã được tắt
	else
		SetModelAsNoLongerNeeded(model)
	end
end

-- Event-driven dog spawning system using recursive timer
local dogSpawnTimer = nil

local function ManageDogSpawning()
	local Hours = GetClockHours()
	local correctTime = Hours >= Config.MinTime and Hours <= Config.MaxTime
	local inZone = IsPlayerInDogZone()
	
	if Config.Debug then
		print("[DEBUG DOG SPAWN] Hour: " .. Hours .. " | correctTime: " .. tostring(correctTime) .. " | inZone: " .. tostring(inZone) .. " | Current Dogs: " .. #entities .. "/" .. Config.MaxSpawn)
	end
	
	if correctTime and inZone then
		if #entities < Config.MaxSpawn then
			SpawnDog()
		end
		
		for i = #entities, 1, -1 do
			local ped = entities[i]
			if DoesEntityExist(ped) then 
				if not IsEntityAttached(ped) then 
					if IsEntityDead(ped) or IsEntityInWater(ped) then
						local model = GetEntityModel(ped)
						SetEntityAsNoLongerNeeded(ped)
						SetModelAsNoLongerNeeded(model)
						DeleteEntity(ped)
						table.remove(entities, i)
					end 
				else 
					table.remove(entities, i)
				end
			else 
				table.remove(entities, i)
			end
		end
	else
		if #entities > 0 then
			CleanupDogs()
		end
	end
	
	-- Restart timer
	dogSpawnTimer = SetTimeout(5000, ManageDogSpawning)
end

-- Start dog spawning system
SetTimeout(2000, function()
	ManageDogSpawning()
end)

local SucceededAttempts = 0

-- Function huấn luyện chó
function TrainDog()
	local dogItemName = nil
	local isCarrying = false
	
	-- TH1: Đang vác chó (Holding = true)
	if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
		local dogModel = GetEntityModel(CurrentHolding)
		for pedModel, itemName in pairs(Config.PedToItem) do
			if GetHashKey(pedModel) == dogModel then
				dogItemName = itemName
				isCarrying = true
				break
			end
		end
	end
	
	-- TH2: Có item chó trong inventory (auto-display đang active)
	if not dogItemName and CurrentDogItem then
		dogItemName = CurrentDogItem
		isCarrying = true
	end
	
	-- TH3: Quét inventory trực tiếp để tìm item chó
	if not dogItemName then
		for itemName, pedModel in pairs(Config.ItemToPed) do
			if exports.ox_inventory then
				local count = exports.ox_inventory:Search('count', itemName)
				if count and count > 0 then
					dogItemName = itemName
					break
				end
			end
		end
	end
	
	if not dogItemName then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Bạn không có chó nào để huấn luyện!',
			type = 'error'
		})
		return
	end

	exports['progressbar']:Progress({
		name = "xn_tromcho_train",
		duration = Config.HuanLuyenCho.TrainTime or 30000,
		label = 'Đang huấn luyện chó...',
		useWhileDead = false,
		canCancel = true,
		controlDisables = {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		},
		animation = {
			animDict = 'mini@repair',
			animClip = 'fixing_a_ped',
		},
		prop = {},
		propTwo = {}
	}, function(cancelled)
	if not cancelled then
		CoreName.Functions.TriggerCallback('xn_tromcho:server:TrainDog', function(success, isTrained)
			if success then
				-- Xóa chó đang vác (nếu có)
				if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
					DetachEntity(CurrentHolding, true, true)
					DeleteEntity(CurrentHolding)
					SetPedAsNoLongerNeeded(CurrentHolding)
				end
				
				-- Xóa chó auto-display (nếu có)
				if CurrentDogPed and DoesEntityExist(CurrentDogPed) then
					if IsEntityAttachedToEntity(CurrentDogPed, PlayerPedId()) then
						DetachEntity(CurrentDogPed, true, true)
					end
					DeleteEntity(CurrentDogPed)
				end
				
				CurrentHolding = nil
				Holding = false
				CurrentDogPed = nil
				CurrentDogItem = nil
				ClearPedTasksImmediately(PlayerPedId())
				
				if isTrained then
					exports.ox_lib:notify({
						title = 'Thành công!',
						description = 'Chúc mừng, huấn luyện chó thành công',
						type = 'success'
					})
				else
					local failMsgs = Config.HuanLuyenCho.FailMessages
					local randomMsg = "Rất tiếc, chú chó này đã ngỏm trong quá trình huấn luyện"
					if failMsgs and #failMsgs > 0 then
						randomMsg = failMsgs[math.random(1, #failMsgs)]
					end
					
					exports.ox_lib:notify({
						title = 'Thất bại!',
						description = randomMsg,
						type = 'error'
					})
				end
				
				-- Quét lại inventory sau 1 giây
				SetTimeout(1000, function()
					LastInventoryCheck = 0
				end)
			else
				exports.ox_lib:notify({
					title = 'Lỗi!',
					description = 'Bạn không có item chó này trong kho!',
					type = 'error'
				})
			end
		end, dogItemName)
	else
		exports.ox_lib:notify({
			title = 'Đã hủy',
			description = 'Hủy huấn luyện chó',
			type = 'error'
		})
	end
	end)
end

-- Function bán chó (dùng cho ox_target)
function SellDog()
	-- Kiểm tra 2 trường hợp: vác chó (Holding) hoặc có item trong inventory
	local dogItemName = nil
	local isCarrying = false
	
	-- TH1: Đang vác chó (Holding = true)
	if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
		local dogModel = GetEntityModel(CurrentHolding)
		
		-- Tìm item name từ model
		for pedModel, itemName in pairs(Config.PedToItem) do
			if GetHashKey(pedModel) == dogModel then
				dogItemName = itemName
				isCarrying = true
				break
			end
		end
	end
	
	-- TH2: Có item chó trong inventory (auto-display đang active)
	if not dogItemName and CurrentDogItem then
		dogItemName = CurrentDogItem
		isCarrying = true
	end
	
	-- TH3: Quét inventory trực tiếp để tìm item chó
	if not dogItemName then
		for itemName, pedModel in pairs(Config.ItemToPed) do
			if exports.ox_inventory then
				local count = exports.ox_inventory:Search('count', itemName)
				if count and count > 0 then
					dogItemName = itemName
					break
				end
			end
		end
	end
	
	if not dogItemName then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Bạn không có chó nào để bán!',
			type = 'error'
		})
		return
	end
	
	-- Debug log
	if Config.Debug then
		print("[DEBUG] Selling dog: " .. dogItemName .. " | isCarrying: " .. tostring(isCarrying))
	end
	
	-- Callback từ server kiểm tra có item không
	CoreName.Functions.TriggerCallback('xn_tromcho:server:CheckAndSellDog', function(success)
		if success then
			-- Xóa chó đang vác (nếu có)
			if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
				DetachEntity(CurrentHolding, true, true)
				DeleteEntity(CurrentHolding)
				SetPedAsNoLongerNeeded(CurrentHolding)
			end
			
			-- Xóa chó auto-display (nếu có)
			if CurrentDogPed and DoesEntityExist(CurrentDogPed) then
				if IsEntityAttachedToEntity(CurrentDogPed, PlayerPedId()) then
					DetachEntity(CurrentDogPed, true, true)
				end
				DeleteEntity(CurrentDogPed)
			end
			
			CurrentHolding = nil
			Holding = false
			CurrentDogPed = nil
			CurrentDogItem = nil
			ClearPedTasksImmediately(PlayerPedId())
			
			exports.ox_lib:notify({
				title = 'Thành công!',
				description = 'Đã bán chó thành công!',
				type = 'success'
			})
			
			-- Quét lại inventory sau 1 giây
			SetTimeout(1000, function()
				LastInventoryCheck = 0
			end)
		else
			exports.ox_lib:notify({
				title = 'Lỗi!',
				description = 'Bạn không có item chó này trong kho!',
				type = 'error'
			})
		end
	end, dogItemName)
end

-- Main interaction loop (dog catching only, NPC selling moved to ox_target)
CreateThread(function()
	-- Spawn NPC first
	local npcModel = GetHashKey(Config.BanCho.NPC)
	RequestModel(npcModel)
	
	local timeout = 0
	while not HasModelLoaded(npcModel) and timeout < 100 do 
		Wait(50)
		timeout = timeout + 1
	end
	
	if HasModelLoaded(npcModel) then
		local NPC = CreatePed(4, npcModel, Config.BanCho.ViTri.x, Config.BanCho.ViTri.y, Config.BanCho.ViTri.z-1, Config.BanCho.ViTri.w, false, true)
		SetEntityInvincible(NPC, true)
		SetEntityAsMissionEntity(NPC, true, true)
		SetBlockingOfNonTemporaryEvents(NPC, true)
		FreezeEntityPosition(NPC, true)
		SetModelAsNoLongerNeeded(npcModel)
		
		-- Tạo ox_target cho NPC bán chó
		if GetResourceState('ox_target') == 'started' then
			exports.ox_target:addLocalEntity(NPC, {
				{
					name = 'xn_tromcho_sell',
					icon = 'fas fa-dog',
					label = 'Bán Chó',
					canInteract = function(entity, distance, coords, name, bone)
						-- TH1: Đang vác chó
						if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
							return true
						end
						
						-- TH2: Có item chó trong inventory (auto-display)
						if CurrentDogItem and CurrentDogPed then
							return true
						end
						
						-- TH3: Quét inventory trực tiếp
						if exports.ox_inventory then
							for itemName, pedModel in pairs(Config.ItemToPed) do
								local count = exports.ox_inventory:Search('count', itemName)
								if count and count > 0 then
									return true
								end
							end
						end
						
						return false
					end,
					onSelect = function()
						SellDog()
					end
				}
			})
			
			if Config.Debug then
				print("[DEBUG] ox_target added to NPC: " .. NPC)
			end
		else
			print("[ERROR] ox_target is not started! Cannot add target to NPC.")
		end
		
		-- Create blip once
		if Config.BanCho.HienBlip then 
			local Icon = AddBlipForCoord(Config.BanCho.ViTri.x, Config.BanCho.ViTri.y, Config.BanCho.ViTri.z)
			SetBlipSprite(Icon, Config.BanCho.Icon)
			SetBlipDisplay(Icon, 4)
			SetBlipScale(Icon, 0.8)
			SetBlipAsShortRange(Icon, true)
			SetBlipColour(Icon, Config.BanCho.MauIcon)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentSubstringPlayerName(Config.BanCho.TenIcon)	
			EndTextCommandSetBlipName(Icon)
		end
	end

	-- Spawn HuanLuyenCho NPC
	if Config.HuanLuyenCho then
		local trainNpcModel = GetHashKey(Config.HuanLuyenCho.NPC)
		RequestModel(trainNpcModel)
		
		local timeout2 = 0
		while not HasModelLoaded(trainNpcModel) and timeout2 < 100 do 
			Wait(50)
			timeout2 = timeout2 + 1
		end
		
		if HasModelLoaded(trainNpcModel) then
			local TrainNPC = CreatePed(4, trainNpcModel, Config.HuanLuyenCho.ViTri.x, Config.HuanLuyenCho.ViTri.y, Config.HuanLuyenCho.ViTri.z-1, Config.HuanLuyenCho.ViTri.w, false, true)
			SetEntityInvincible(TrainNPC, true)
			SetEntityAsMissionEntity(TrainNPC, true, true)
			SetBlockingOfNonTemporaryEvents(TrainNPC, true)
			FreezeEntityPosition(TrainNPC, true)
			SetModelAsNoLongerNeeded(trainNpcModel)
			
			-- Spawn chó trang trí (a_c_rottweiler) bên phải NPC
			local decoDogModel = GetHashKey("a_c_rottweiler")
			RequestModel(decoDogModel)
			local timeout3 = 0
			while not HasModelLoaded(decoDogModel) and timeout3 < 100 do 
				Wait(50)
				timeout3 = timeout3 + 1
			end
			
			if HasModelLoaded(decoDogModel) then
				local rightCoords = GetOffsetFromEntityInWorldCoords(TrainNPC, 1.0, 0.0, 0.0)
				local Ground, posZ = GetGroundZFor_3dCoord(rightCoords.x, rightCoords.y, rightCoords.z + 1.0, true)
				local dogNPC = CreatePed(28, decoDogModel, rightCoords.x, rightCoords.y, Ground and posZ or (Config.HuanLuyenCho.ViTri.z - 1), Config.HuanLuyenCho.ViTri.w, false, true)
				SetEntityInvincible(dogNPC, true)
				SetEntityAsMissionEntity(dogNPC, true, true)
				SetBlockingOfNonTemporaryEvents(dogNPC, true)
				FreezeEntityPosition(dogNPC, true)
				SetModelAsNoLongerNeeded(decoDogModel)
				-- Đặt decoration dog vào đúng routing bucket của player
				local decoDogNetId = NetworkGetNetworkIdFromEntity(dogNPC)
				TriggerServerEvent('xn_tromcho:server:RegisterEntityBucket', decoDogNetId)
			end
			
			-- Tạo ox_target cho NPC huấn luyện chó
			if GetResourceState('ox_target') == 'started' then
				exports.ox_target:addLocalEntity(TrainNPC, {
					{
						name = 'xn_tromcho_train',
						icon = 'fas fa-graduation-cap',
						label = 'Huấn Luyện Chó',
						canInteract = function(entity, distance, coords, name, bone)
							-- TH1: Đang vác chó
							if Holding and CurrentHolding and DoesEntityExist(CurrentHolding) then
								return true
							end
							
							-- TH2: Có item chó trong inventory (auto-display)
							if CurrentDogItem and CurrentDogPed then
								return true
							end
							
							-- TH3: Quét inventory trực tiếp
							if exports.ox_inventory then
								for itemName, pedModel in pairs(Config.ItemToPed) do
									local count = exports.ox_inventory:Search('count', itemName)
									if count and count > 0 then
										return true
									end
								end
							end
							
							return false
						end,
						onSelect = function()
							TrainDog()
						end
					}
				})
			end
			
			-- Create blip once
			if Config.HuanLuyenCho.HienBlip then 
				local Icon = AddBlipForCoord(Config.HuanLuyenCho.ViTri.x, Config.HuanLuyenCho.ViTri.y, Config.HuanLuyenCho.ViTri.z)
				SetBlipSprite(Icon, Config.HuanLuyenCho.Icon)
				SetBlipDisplay(Icon, 4)
				SetBlipScale(Icon, 0.8)
				SetBlipAsShortRange(Icon, true)
				SetBlipColour(Icon, Config.HuanLuyenCho.MauIcon)
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentSubstringPlayerName(Config.HuanLuyenCho.TenIcon)	
				EndTextCommandSetBlipName(Icon)
			end
		end
	end
	
	-- Combined interaction loop
	while true do
		local sleep = 1000
		local playerPed = PlayerPedId()
		local playerPos = GetEntityCoords(playerPed)
		
		local Hours = GetClockHours()
		local inDogZone = IsPlayerInDogZone() and Hours >= Config.MinTime and Hours <= Config.MaxTime
		
		-- Check dog interaction first
		if inDogZone then
			local ped = GetNearbyPed()
			
			if ped and DoesEntityExist(ped) then
				sleep = 0
				local dogPos = GetEntityCoords(ped)
				local dist = #(playerPos - dogPos)
				
				-- Lưu con chó gần nhất và hiển thị text hướng dẫn
				if not IsPedInAnyVehicle(PlayerPedId(), false) then
					if dist <= 1.5 and not IsEntityAttached(ped) and not Catching and not Holding then
						NearestDog = ped -- Lưu con chó gần nhất
						DrawText3Ds(dogPos.x, dogPos.y, dogPos.z+0.5, "~y~Sử dụng [Xích Chó]~w~ để bắt")
					else
						if NearestDog == ped then
							NearestDog = nil
						end
					end
				else 
					-- Khi đang trên phương tiện
					if Config.PhuongTien.Allow then
						local MyVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
						if GetVehicleClass(MyVehicle) == 8 then 
							if GetEntityModel(MyVehicle) == GetHashKey(Config.PhuongTien.Xe) then 
								if GetPedInVehicleSeat(GetVehiclePedIsIn(PlayerPedId()), -1) ~= PlayerPedId() then
									if dist <= Config.PhuongTien.Distance and not IsEntityAttached(ped) and not Catching and not Holding then
										NearestDog = ped
										DrawText3Ds(dogPos.x, dogPos.y, dogPos.z+0.5, "~y~Sử dụng [Thòng Lọng]~w~ để bắt")
									else
										if NearestDog == ped then
											NearestDog = nil
										end
									end
								else
									NearestDog = nil
								end
							else
								NearestDog = nil
							end
						else
							NearestDog = nil
						end
					else
						NearestDog = nil
						if dist <= 2.0 then
							DrawText3Ds(dogPos.x, dogPos.y, dogPos.z+0.5, "~r~Vui lòng xuống xe để bắt chó")
						end
					end
				end
			else
				sleep = 200 -- Near zone but no dogs
			end
		end
		
		Wait(sleep)
	end
end)


function CopsCall()
	if Config.BCS.Enable then
		if math.random(1,10) <= Config.BCS.Chance then
			if Config.Framework == "QBCore" then
				TriggerServerEvent("police:server:policeAlert", "TRỘM CHÓ")
			else 
				local StreetLabel = CoreName.Functions.GetStreetLabel()
				TriggerServerEvent(Config.BCS.Event, GetEntityCoords(PlayerPedId()), StreetLabel)
			end 
		end
	end
end

function DrawText3Ds(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local factor = #text / 460
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	
	SetTextScale(0.3, 0.3)
	SetTextFont(6)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 160)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
end

-- Function xử lý bắt chó (được gọi từ item use)
local function StartCatchingDog(ped, onFoot)
	-- Kiểm tra + atomic lock toàn server
	local canSteal = lib.callback.await('xn_tromcho:sv:CheckCanRob', false)
	if not canSteal then return end

	-- Kiểm tra số lượng cảnh sát an toàn
	local currentPoliceCount = GetPoliceCount()
	if currentPoliceCount < (Config.PoliceOnDutyRequired or Config.CopRequired or 0) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = "Không đủ cảnh sát (cần " .. (Config.PoliceOnDutyRequired or Config.CopRequired or 0) .. " trở lên)",
			type = 'error'
		})
		return
	end
	
	if not ped or not DoesEntityExist(ped) then
			exports.ox_lib:notify({
				title = 'Lỗi!',
				description = 'Không tìm thấy chó gần đây',
				type = 'error'
			})
			return
		end
		
		if Catching or Holding then
			exports.ox_lib:notify({
				title = 'Lỗi!',
				description = 'Bạn đang bắt hoặc đang cầm chó rồi!',
				type = 'error'
			})
			return
		end
		
		local playerPed = PlayerPedId()
		local playerPos = GetEntityCoords(playerPed)
		local dogPos = GetEntityCoords(ped)
		local dist = #(playerPos - dogPos)
		
		-- Kiểm tra khoảng cách
		local maxDist = onFoot and 1.5 or Config.PhuongTien.Distance
		if dist > maxDist then
			exports.ox_lib:notify({
				title = 'Lỗi!',
				description = 'Bạn đứng quá xa chó!',
				type = 'error'
			})
			return
		end
		

		
		CopsCall()
		
		Catching = true
		FreezeEntityPosition(ped, true)
		if onFoot then
			FreezeEntityPosition(playerPed, true)
		end
		
		-- Lấy độ khó minigame dựa theo loại chó (CHẠY TRƯỚC)
		local pedModel = GetEntityModel(ped)
		local pedModelName = nil
		for _, modelName in ipairs(Config.Peds) do
			if GetHashKey(modelName) == pedModel then
				pedModelName = modelName
				break
			end
		end
		
		local difficulty = "normal"
		local keys = 4
		
		if pedModelName and Config.DogMinigameDifficulty and Config.DogMinigameDifficulty[pedModelName] then
			difficulty = Config.DogMinigameDifficulty[pedModelName].difficulty
			keys = Config.DogMinigameDifficulty[pedModelName].keys
		end
		
		-- Sử dụng 1307_MinigameWASD (TRƯỚC PROGRESSBAR)
		local minigameResult = exports["1307_MinigameWASD"]:gameCheck(difficulty, keys)
		
		if not minigameResult then
			-- Minigame thất bại → Xử lý chó cắn hoặc chạy đi
			SucceededAttempts = 0
			FreezeEntityPosition(ped, false)
			FreezeEntityPosition(playerPed, false)
			
			if Config.ChoCan then 
				if math.random(1,10) <= Config.ChanceChoCan then 
					-- CHÓ CẮN - Hành động tự nhiên và hung dữ
					local model = GetEntityModel(ped)
					
					-- Bỏ freeze và cho chó tự do hành động
					SetBlockingOfNonTemporaryEvents(ped, false)
					SetPedFleeAttributes(ped, 0, false)
					SetPedCombatAttributes(ped, 46, true) -- Always fight
					SetPedCombatAttributes(ped, 5, true)  -- Can fight armed peds when not armed
					
					-- Cho chó tấn công người chơi (tự nhiên, không xóa entity)
					TaskCombatPed(ped, playerPed, 0, 16)
					SetPedRelationshipGroupHash(ped, GetHashKey("COUGAR"))
					SetRelationshipBetweenGroups(5, GetHashKey("COUGAR"), GetHashKey("PLAYER"))
					SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("COUGAR"))
					
					-- Làm player bị sốc và mất máu
					-- SetPedToRagdoll(playerPed, 2000, 2000, 0, true, true, false)
					-- SetEntityHealth(playerPed, GetEntityHealth(playerPed) - Config.MauBiCan)
					
					TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 6.5, "chocan", 0.18)
					exports.ox_lib:notify({
						title = 'Nguy hiểm!',
						description = 'Bạn đã bị chó cắn! Chó đang tấn công bạn!',
						type = 'error'
					})
					
					-- Cho chó tự động xóa sau 15 giây (đủ thời gian tấn công và chạy đuổi)
					SetTimeout(15000, function()
						if DoesEntityExist(ped) then
							SetEntityAsNoLongerNeeded(ped)
							SetModelAsNoLongerNeeded(model)
							DeleteEntity(ped)
						end
					end)
				else 
					-- CHÓ CHẠY ĐI - Bỏ chạy nhanh và tự nhiên
					local model = GetEntityModel(ped)
					
					-- Cho chó sợ hãi và bỏ chạy
					SetPedFleeAttributes(ped, 0, true)
					TaskSmartFleePed(ped, playerPed, 100.0, -1, false, false)
					
					exports.ox_lib:notify({
						title = 'Thất bại!',
						description = 'Chó đã sợ và bỏ chạy!',
						type = 'error'
					})
					
					-- Tự động xóa chó sau 10 giây
					SetTimeout(10000, function()
						if DoesEntityExist(ped) then
							SetEntityAsNoLongerNeeded(ped)
							SetModelAsNoLongerNeeded(model)
							DeleteEntity(ped)
						end
					end)
				end
			else 
				-- Không có config chó cắn - chỉ chạy đi
				local model = GetEntityModel(ped)
				SetPedFleeAttributes(ped, 0, true)
				TaskSmartFleePed(ped, playerPed, 100.0, -1, false, false)
				
				exports.ox_lib:notify({
					title = 'Thất bại!',
					description = 'Chó đã chạy đi!',
					type = 'error'
				})
				
				SetTimeout(10000, function()
					if DoesEntityExist(ped) then
						SetEntityAsNoLongerNeeded(ped)
						SetModelAsNoLongerNeeded(model)
						DeleteEntity(ped)
					end
				end)
			end
			
			TriggerServerEvent('xn_tromcho:server:FailRob')
			Catching = false
			return
		end
		
		-- Minigame thành công → Chạy progressbar
		local progressLabel = onFoot and 'Đang bắt chó...' or 'Đang bắt chó bằng thòng lọng...'
		PoliceCall()
		exports['progressbar']:Progress({
			name = "xn_tromcho_catch",
			duration = Config.ThoiGianBatCho or 10000,
			label = progressLabel,
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
				animClip = "machinic_loop_mechandplayer",
			},
			prop = {},
			propTwo = {}
		}, function(cancelled)
		if not cancelled then
			-- Progressbar hoàn thành → Bắt chó thành công
			SucceededAttempts = SucceededAttempts + 1
				
				if SucceededAttempts >= Config.Skillbar.Solan then 
					SucceededAttempts = 0
					Catching = false
					-- KHÔNG VÁC CHÓ NGAY - CHỈ GIVE ITEM
					local pedModel = GetEntityModel(ped)
					local pedModelName = nil
					for _, modelName in ipairs(Config.Peds) do
						if GetHashKey(modelName) == pedModel then
							pedModelName = modelName
							break
						end
					end
					
					if pedModelName and Config.PedToItem[pedModelName] then
						local itemName = Config.PedToItem[pedModelName]
						local usedItem = onFoot and Config.VatPham or Config.PhuongTien.VatPham
						TriggerServerEvent('xn_tromcho:server:SuccessRob')
						TriggerServerEvent('xn_tromcho:server:GiveChoItem', itemName, usedItem)
						
						-- Xóa ped chó sau khi bắt
						FreezeEntityPosition(ped, false)
						FreezeEntityPosition(playerPed, false)
						DeleteEntity(ped)
						
						TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 6.5, "chosua", 0.18)
						exports.ox_lib:notify({
							title = 'Thành công!',
							description = 'Đã bắt thành công một con chó! Kiểm tra inventory.',
							type = 'success'
						})
					else
						exports.ox_lib:notify({
							title = 'Lỗi!',
							description = 'Không xác định được loại chó!',
							type = 'error'
						})
						FreezeEntityPosition(ped, false)
						FreezeEntityPosition(playerPed, false)
					end
				else
					exports.ox_lib:notify({
						title = 'Tiếp tục',
						description = 'Cần thực hiện thêm ' .. (Config.Skillbar.Solan - SucceededAttempts) .. ' lần nữa',
						type = 'inform'
					})
					FreezeEntityPosition(ped, false)
					FreezeEntityPosition(playerPed, false)
					Catching = false
				end
		else
			-- Progress bar bị hủy
			TriggerServerEvent('xn_tromcho:server:ResetRob')
			Catching = false
			FreezeEntityPosition(ped, false)
			FreezeEntityPosition(playerPed, false)
			TriggerEvent('animations:client:EmoteCommandStart', {"c"})
		end
		end)
end

-- Export function để item có thể gọi với ox_inventory durability
exports('UseXichCho', function(data, slot)
	-- Kiểm tra có chó gần đây không
	if not NearestDog or not DoesEntityExist(NearestDog) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Không có chó nào gần đây! Hãy đứng gần chó trước.',
			type = 'error'
		})
		return
	end
	
	-- Kiểm tra không được trên xe
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Không thể sử dụng xích chó khi đang trên xe!',
			type = 'error'
		})
		return
	end

	exports.ox_inventory:useItem(data, function(data) 
		if data then
			CreateThread(function()
				-- Bắt đầu bắt chó - độ bền sẽ được trừ tự động bởi ox_inventory (hoặc server khi trộm thành công)
				StartCatchingDog(NearestDog, true)
			end)
		end
	end)
end)

exports('UseThongLong', function(data, slot)
	-- Kiểm tra có chó gần đây không
	if not NearestDog or not DoesEntityExist(NearestDog) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Không có chó nào gần đây! Hãy đến gần chó trước.',
			type = 'error'
		})
		return
	end
	
	-- Kiểm tra phải trên xe máy
	if not IsPedInAnyVehicle(PlayerPedId(), false) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Chỉ có thể sử dụng thòng lọng khi đang trên xe máy!',
			type = 'error'
		})
		return
	end
	
	local MyVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
	if GetVehicleClass(MyVehicle) ~= 8 then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Chỉ có thể sử dụng với xe máy!',
			type = 'error'
		})
		return
	end
	
	if GetEntityModel(MyVehicle) ~= GetHashKey(Config.PhuongTien.Xe) then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Phải sử dụng xe: ' .. Config.PhuongTien.Xe,
			type = 'error'
		})
		return
	end
	
	if GetPedInVehicleSeat(MyVehicle, -1) == PlayerPedId() then
		exports.ox_lib:notify({
			title = 'Lỗi!',
			description = 'Không thể bắt chó khi đang lái xe! Hãy ngồi sau.',
			type = 'error'
		})
		return
	end

	exports.ox_inventory:useItem(data, function(data) 
		if data then
			CreateThread(function()
				-- Bắt đầu bắt chó bằng thòng lọng - độ bền sẽ được trừ tự động
				StartCatchingDog(NearestDog, false)
			end)
		end
	end)
end)

-- ============================================================
-- HỆ THỐNG TỰ ĐỘNG HIỂN THỊ CHÓ (V3.2)
-- Quét inventory → Nếu có item chó → Spawn chó theo sau
-- ============================================================

local CurrentDogPed = nil -- Chó đang theo
local CurrentDogItem = nil -- Item chó hiện tại
local CurrentDogNetId = nil -- Net ID của chó đang vác (để cleanup khi đổi bucket)
local LastInventoryCheck = 0

-- Function kiểm tra có item chó trong inventory
function CheckDogInventory()
	local hasDogItem = nil
	local dogPedModel = nil
	
	-- Quét qua tất cả 7 loại chó
	for itemName, pedModel in pairs(Config.ItemToPed) do
		if exports.ox_inventory then
			local count = exports.ox_inventory:Search('count', itemName)
			if count and count > 0 then
				hasDogItem = itemName
				dogPedModel = pedModel
				break
			end
		end
	end
	
	return hasDogItem, dogPedModel
end

-- Function spawn chó theo sau - NETWORKED VERSION (Tự động sync)
function SpawnFollowingDog(pedModel, itemName)
	-- Nếu đã có chó và đúng loại → Không spawn lại
	if CurrentDogPed and DoesEntityExist(CurrentDogPed) and CurrentDogItem == itemName then
		return
	end
	
	-- Xóa chó cũ nếu có (còn tồn tại client-side)
	if CurrentDogPed and DoesEntityExist(CurrentDogPed) then
		if NetworkHasControlOfEntity(CurrentDogPed) then
			NetworkRequestControlOfEntity(CurrentDogPed)
			DeleteEntity(CurrentDogPed)
		end
		CurrentDogPed = nil
		CurrentDogNetId = nil
	elseif CurrentDogPed and not DoesEntityExist(CurrentDogPed) then
		-- Entity không còn tồn tại client-side (do đổi bucket) → yêu cầu server xóa orphan
		if CurrentDogNetId then
			TriggerServerEvent('xn_tromcho:server:DeleteOrphanEntity', CurrentDogNetId)
			CurrentDogNetId = nil
		end
		CurrentDogPed = nil
	end
	
	-- Request model
	local hash = GetHashKey(pedModel)
	RequestModel(hash)
	while not HasModelLoaded(hash) do
		RequestModel(hash)
		Wait(10)
	end
	
	-- Spawn chó ở trước mặt player
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local playerHeading = GetEntityHeading(playerPed)
	
	local forwardX = math.sin(math.rad(-playerHeading))
	local forwardY = math.cos(math.rad(-playerHeading	))
	local spawnCoords = vector3(playerCoords.x + forwardX * 1.0, playerCoords.y + forwardY * 1.0, playerCoords.z)
	
	-- NETWORKED PED - Tự động sync với tất cả client!
	CurrentDogPed = CreatePed(28, hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, playerHeading, true, true)
	local netId = NetworkGetNetworkIdFromEntity(CurrentDogPed)
	SetNetworkIdCanMigrate(netId, false) -- Chỉ owner mới control được
	CurrentDogNetId = netId
	-- Đặt entity vào đúng routing bucket của player ngay từ đầu
	TriggerServerEvent('xn_tromcho:server:RegisterEntityBucket', netId)
	
	SetEntityAsMissionEntity(CurrentDogPed, true, true)
	SetBlockingOfNonTemporaryEvents(CurrentDogPed, true)
	SetPedFleeAttributes(CurrentDogPed, 0, false)
	
	-- FREEZE CHÓ để ngăn xoay và giật - XOAY CHÓ HƯỚNG RA NGOÀI
	FreezeEntityPosition(CurrentDogPed, true)
	SetEntityRotation(CurrentDogPed, -90.0, 0.0, 90.0, 2, true) -- Pitch -90, Yaw 90 để chó nằm ngang hướng ra
	SetPedCanRagdoll(CurrentDogPed, false)
	SetEntityInvincible(CurrentDogPed, true)
	
	-- VÁC CHÓ (attach entity - như ban đầu) - CÁI NÀY CŨNG TỰ ĐỘNG SYNC!
	local dict = "anim@heists@box_carry@"
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(100)
	end
	
	TaskPlayAnim(playerPed, dict, 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
	local bone = GetPedBoneIndex(playerPed, 28422)
	
	-- Set attachment position dựa trên trạng thái của player
	if IsPedInAnyVehicle(playerPed, false) then
		-- Trên xe: attachment xa và thấp hơn, disable collision
		SetEntityCollision(CurrentDogPed, false, false)
		SetEntityProofs(CurrentDogPed, true, true, true, true, true, true, true, true)
		-- X: ra trước, Y: sang phải, Z: lên cao, Pitch: nghiêng, Roll: lật, Yaw: xoay ngang
		AttachEntityToEntity(CurrentDogPed, playerPed, bone, 0.2, -0.1, -0.2, -90.0, 0.0, 90.0, true, false, false, false, 1, true)
	else
		-- Đi bộ: attachment bình thường
		SetEntityCollision(CurrentDogPed, true, true)
		SetEntityProofs(CurrentDogPed, false, false, false, false, false, false, false, false)
		-- Điều chỉnh để chó nằm ngang ra phía trước
		AttachEntityToEntity(CurrentDogPed, playerPed, bone, 0.2, -0.1, -0.1, -90.0, 0.0, 90.0, true, false, false, false, 1, true)
	end
	
	-- ĐẢM BẢO CHÓ LUÔN FREEZE khi vừa spawn để không bị xoay giật - HƯỚNG RA NGOÀI
	Wait(100) -- Chờ attachment hoàn tất
	FreezeEntityPosition(CurrentDogPed, true)
	SetEntityRotation(CurrentDogPed, -90.0, 0.0, 90.0, 2, true) -- Pitch -90, Yaw 90 để chó nằm ngang ra ngoài
	SetPedCanRagdoll(CurrentDogPed, false)
	
	CurrentDogItem = itemName
	Holding = true
	CurrentHolding = CurrentDogPed
	SetModelAsNoLongerNeeded(hash)
	
	if Config.Debug then
		print("[DEBUG] Spawned NETWORKED dog: " .. pedModel .. " (NetID: " .. netId .. ") for item: " .. itemName)
	end
end

-- Function xóa chó - NETWORKED VERSION
function RemoveFollowingDog()
	if CurrentDogPed and DoesEntityExist(CurrentDogPed) then
		-- Detach nếu đang attach
		if IsEntityAttachedToEntity(CurrentDogPed, PlayerPedId()) then
			DetachEntity(CurrentDogPed, true, true)
		end
		
		-- UNFREEZE CHÓ trước khi xóa để cleanup hoàn toàn
		FreezeEntityPosition(CurrentDogPed, false)
		SetPedCanRagdoll(CurrentDogPed, true)
		SetEntityInvincible(CurrentDogPed, false)
		
		-- XÓA NETWORKED ENTITY - Tự động sync với tất cả client!
		if NetworkHasControlOfEntity(CurrentDogPed) then
			NetworkRequestControlOfEntity(CurrentDogPed)
			DeleteEntity(CurrentDogPed)
		end
		
		CurrentDogPed = nil
		CurrentDogNetId = nil
		CurrentDogItem = nil
		Holding = false
		CurrentHolding = nil
		ClearPedTasksImmediately(PlayerPedId())
		
		if Config.Debug then
			print("[DEBUG] Removed NETWORKED carrying dog")
		end
	end
end

-- Thread quét inventory (chạy mỗi 5 giây)
CreateThread(function()
	while true do
		Wait(5000) -- Check mỗi 5 giây
		
		-- Phát hiện entity bị mất do đổi bucket (handle còn nhưng DoesEntityExist = false)
		if CurrentDogPed and not DoesEntityExist(CurrentDogPed) then
			if CurrentDogNetId then
				TriggerServerEvent('xn_tromcho:server:DeleteOrphanEntity', CurrentDogNetId)
				CurrentDogNetId = nil
			end
			CurrentDogPed = nil
			CurrentDogItem = nil
			Holding = false
			CurrentHolding = nil
			ClearPedTasksImmediately(PlayerPedId())
			if Config.Debug then
				print("[DEBUG] Phát hiện entity mất do đổi bucket → reset state")
			end
		end
		
		local currentTime = GetGameTimer()
		if currentTime - LastInventoryCheck >= 5000 then
			LastInventoryCheck = currentTime
			
			local dogItem, dogPed = CheckDogInventory()
			
			if dogItem and dogPed then
				-- Có item chó → Spawn/update chó
				SpawnFollowingDog(dogPed, dogItem)
			else
				-- Không có item → Xóa chó
				RemoveFollowingDog()
			end
		end
	end
end)



