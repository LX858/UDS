-- Biến lưu trạng thái gear
local currentGear = {
	mask = 0,
	tank = 0,
	enabled = false,
	timerActive = false,
	itemType = nil, -- 'binhlannghanh' hoặc 'diving_gear'
	currentTimerId = nil -- ID để track timer hiện tại
}

local GEAR_DURATION = 300 -- 5 phút = 300 giây

-- Function để xóa gear cũ
function DeleteGear()
	if currentGear.mask ~= 0 then
		DeleteEntity(currentGear.mask)
		currentGear.mask = 0
	end
	if currentGear.tank ~= 0 then
		DeleteEntity(currentGear.tank)
		currentGear.tank = 0
	end
end

-- Function đếm thời gian và tự động tháo bình lặn
local function StartGearTimer(itemType)
	-- Tạo timer ID mới để thread cũ có thể tự dừng
	local timerId = math.random(1, 999999)
	currentGear.currentTimerId = timerId
	currentGear.timerActive = true
	currentGear.itemType = itemType
	
	CreateThread(function()
		local timeLeft = GEAR_DURATION
		
		-- Check cả timerId để đảm bảo thread cũ dừng khi có timer mới
		while timeLeft > 0 and currentGear.enabled and currentGear.currentTimerId == timerId do
			Wait(1000)
			timeLeft = timeLeft - 1
			
			-- Double check timer ID sau mỗi lần wait
			if currentGear.currentTimerId ~= timerId then
				print("[Bình Lặn] Timer cũ bị thay thế, dừng thread")
				return
			end
			
			-- Cập nhật UI với thời gian còn lại
			local minutes = math.floor(timeLeft / 60)
			local seconds = timeLeft % 60
			local timeText = string.format("⏱ %02d:%02d", minutes, seconds)
			local displayName = itemType == 'diving_gear' and "Bình Lặn" or "Bình Lặn Ngành"
			
			exports["orbit-ui"]:Show(displayName, timeText .. " - /coibinhlan để tháo")
			print(string.format("[Bình Lặn] Thời gian còn lại: %02d:%02d", minutes, seconds))
		end
		
		-- Chỉ tự động tháo nếu timer ID vẫn đúng (không bị thay thế)
		if currentGear.enabled and currentGear.currentTimerId == timerId then
			local playerPed = PlayerPedId()
			
			DeleteGear()
			SetEnableScuba(playerPed, false)
			SetPedDiesInWater(playerPed, true)
			currentGear.enabled = false
			currentGear.timerActive = false
			currentGear.currentTimerId = nil
			ClearPedTasks(playerPed)
			exports["orbit-ui"]:Close()
			
			exports.qbx_core:Notify('Bình lặn đã hết', 'error')
			print("[Bình Lặn] Đã hết thời gian")
		else
			print("[Bình Lặn] Thread dừng do timer bị thay thế")
		end
		
		-- Chỉ reset nếu timer này vẫn là timer hiện tại
		if currentGear.currentTimerId == timerId then
			currentGear.timerActive = false
			currentGear.itemType = nil
			currentGear.currentTimerId = nil
		end
	end)
end

-- Function để đeo bình lặn (item đã bị xóa bởi server)
local function EquipDivingGear(itemType)
	local playerPed = PlayerPedId()
	itemType = itemType or 'binhlannghanh' -- default là bình lặn ngành
	
	-- Nếu đang đeo gear cùng loại, chỉ reset timer (vẫn chạy progress bar)
	local isRefill = currentGear.enabled
	
	print("[Bình Lặn] Bắt đầu progress - isRefill: " .. tostring(isRefill))
	
	local playerPed = PlayerPedId()
	local isUnderwater = IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed) or IsEntityInWater(playerPed)
	
	print("[Bình Lặn] Player under water: " .. tostring(isUnderwater))
	
	if isUnderwater then
		-- Dưới nước: Dùng progressbar export
		exports['progressbar']:Progress({
			name = "diving_gear",
			duration = 5000,
			label = isRefill and 'Đang nạp bình lặn...' or 'Đang đeo bình lặn...',
			useWhileDead = false,
			canCancel = false,
			controlDisables = {
				disableMovement = false,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
		}, function(cancelled)
			if cancelled then
				print("[Bình Lặn] Progress bị cancel")
			else
				print("[Bình Lặn] Progress hoàn thành")
			end
		end)
		
		Wait(5000)  -- Chờ progress bar hoàn thành
	else
		-- Trên cạn: Dùng ox_lib progress bar
		local success = lib.progressBar({
			duration = 5000,
			label = isRefill and 'Đang nạp bình lặn...' or 'Đang đeo bình lặn...',
			useWhileDead = false,
			canCancel = false,
			disable = {
				move = false,
				car = true,
			},
			anim = {
				dict = 'clothingshirt',
				clip = 'try_shirt_positive_d'
			},
		})
		
		print("[Bình Lặn] Progress bar kết thúc - success: " .. tostring(success))
		
		if not (success or success == nil) then
			return  -- Bị cancel
		end
	end
	
	-- Tiếp tục đeo/nạp bình
	if true then
		-- Nếu là refill, chỉ reset timer (timer cũ sẽ tự dừng do timerId thay đổi)
		if isRefill then
			local displayName = itemType == 'diving_gear' and "Bình Lặn" or "Bình Lặn Ngành"
			exports["orbit-ui"]:Show(displayName, "/coibinhlan để tháo bình lặn ra")
			
			-- Reset timer hoàn toàn với thời gian mới
			StartGearTimer(itemType)
			exports.qbx_core:Notify('Đã nạp bình lặn mới - thời gian đã được reset', 'success')
			print("[Bình Lặn] Đã reset timer với thời gian mới")
			return
		end
		
		-- Nếu không, đeo mới
		DeleteGear()
		
		local maskModel = GetHashKey("p_d_scuba_mask_s")
		local tankModel = GetHashKey("p_s_scuba_tank_s")
		
		RequestModel(tankModel)
		while not HasModelLoaded(tankModel) do
			Wait(1)
		end
		TankObject = CreateObject(tankModel, 1.0, 1.0, 1.0, 1, 1, 0)
		local bone1 = GetPedBoneIndex(playerPed, 24818)
		AttachEntityToEntity(TankObject, playerPed, bone1, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0, 1, 1, 0, 0, 2, 1)
		currentGear.tank = TankObject

		RequestModel(maskModel)
		while not HasModelLoaded(maskModel) do
			Wait(1)
		end

		MaskObject = CreateObject(maskModel, 1.0, 1.0, 1.0, 1, 1, 0)
		local bone2 = GetPedBoneIndex(playerPed, 12844)
		AttachEntityToEntity(MaskObject, playerPed, bone2, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0, 1, 1, 0, 0, 2, 1)
		currentGear.mask = MaskObject

		SetEnableScuba(playerPed, true)
		SetPedDiesInWater(playerPed, false)
		currentGear.enabled = true
		ClearPedTasks(playerPed)
		
		local displayName = itemType == 'diving_gear' and "Bình Lặn" or "Bình Lặn Ngành"
		exports["orbit-ui"]:Show(displayName, "/coibinhlan để tháo bình lặn ra")
		
		-- Item đã được server xóa rồi, không cần xóa nữa
		
		-- Bắt đầu đếm thời gian 10 phút
		StartGearTimer(itemType)
	end
end

-- Function để tháo bình lặn
local function RemoveDivingGear()
	local playerPed = PlayerPedId()
	
	if not currentGear.enabled then
		exports.qbx_core:Notify('Bạn không có thiết bị lặn', 'error')
		return
	end
	
	-- Kiểm tra xem player có đang dưới nước không
	if IsPedSwimming(playerPed) or IsPedSwimmingUnderWater(playerPed) or IsEntityInWater(playerPed) then
		exports.qbx_core:Notify('Bạn không thể cởi bình lặn do đang dưới nước', 'error')
		return
	end
	
	if lib.progressBar({
		duration = 5000,
		label = 'Đang tháo bình lặn...',
		useWhileDead = false,
		canCancel = false,
		disable = {
			move = false,
			car = true,
		},
		anim = {
			dict = 'clothingshirt',
			clip = 'try_shirt_positive_d'
		},
	}) then 
		local itemType = currentGear.itemType
		
		DeleteGear()
		SetEnableScuba(playerPed, false)
		SetPedDiesInWater(playerPed, true)
		currentGear.enabled = false
		currentGear.timerActive = false
		currentGear.currentTimerId = nil
		ClearPedTasks(playerPed)
		exports.qbx_core:Notify('Đã cất bình lặn', 'success')
		exports["orbit-ui"]:Close()
		
		if itemType then
			TriggerServerEvent('binhlanpd:server:returnGear', itemType)
		end
		currentGear.itemType = nil
	end
end

-- Event nhận từ server khi dùng item bình lặn ngành
RegisterNetEvent('binhlanpd:client:useGear', function(itemType)
	itemType = itemType or 'binhlannghanh'
	
	-- Đeo/Nạp bình lặn (chạy progress bar)
	-- Job/duty đã được check ở export function rồi
	EquipDivingGear(itemType)
end)

-- Command để tháo bình lặn
RegisterCommand('coibinhlan', function()
	RemoveDivingGear()
end, false)



-- Event để đeo/tháo bình lặn (giữ lại để tương thích với code cũ nếu có)
RegisterNetEvent('xx_diving:client:UseGear')
AddEventHandler('xx_diving:client:UseGear', function(bool)
	if bool then
		EquipDivingGear('binhlannghanh')
	else
		RemoveDivingGear()
	end
end)

function GearAnim()
    loadAnimDict("clothingshirt")    	
	TaskPlayAnim(PlayerPedId(), "clothingshirt", "try_shirt_positive_d", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
end

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Export functions được gọi từ ox_inventory khi dùng item
exports('UseDivingGear', function(data, slot)
	-- Bình lặn ngành - Luôn xóa item trước
	TriggerServerEvent('binhlanpd:server:deleteItemOnly', slot, 'binhlannghanh')
	
	-- Kiểm tra nếu đang đeo bình loại khác
	if currentGear.enabled and currentGear.itemType ~= 'binhlannghanh' then
		exports.qbx_core:Notify('Bạn phải onduty để sử dụng bình lặn ngành', 'error')
		return
	end
	
	-- Check data
	if not QBX or not QBX.PlayerData or not QBX.PlayerData.job then
		exports.qbx_core:Notify('Có lỗi xảy ra', 'error')
		return
	end
	
	-- Check onduty
	if not QBX.PlayerData.job.onduty then
		exports.qbx_core:Notify('Bạn phải onduty để sử dụng bình lặn ngành', 'error')
		return
	end
	
	-- Check job
	if QBX.PlayerData.job.name ~= 'police' and QBX.PlayerData.job.name ~= 'ambulance' then
		exports.qbx_core:Notify('Bạn không có quyền sử dụng bình lặn này', 'error')
		return
	end
	
	-- OK → Gọi server trigger client (item đã xóa rồi)
	TriggerServerEvent('binhlanpd:server:triggerUseGear', 'binhlannghanh')
end)

exports('UseDivingGearCivilian', function(data, slot)
	-- Bình lặn dân
	-- Kiểm tra nếu đang đeo bình loại khác
	if currentGear.enabled and currentGear.itemType ~= 'diving_gear' then
		-- Xóa item nhưng không cho đổi loại bình
		TriggerServerEvent('binhlanpd:server:deleteItemOnly', slot, 'diving_gear')
		exports.qbx_core:Notify('Bạn đang đeo bình lặn khác, không thể thay đổi', 'error')
		return
	end
	
	-- OK → Đeo mới hoặc refill
	TriggerServerEvent('binhlanpd:server:useGear', slot, 'diving_gear')
end) 