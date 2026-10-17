
local Config = require 'config.config'

-- Hàm kiểm tra xe (dùng chung)
local function CheckVehicleRestriction(ped, vehicle)
	if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
	
	local vehicleClass = GetVehicleClass(vehicle)
	local vehicleModel = GetEntityModel(vehicle)
	local isOnDuty = QBX.PlayerData.job.onduty
	
	-- Kiểm tra xe nghành (Class 18)
	if vehicleClass == 18 then
		if not isJobWhitelisted(QBX.PlayerData.job.name) or not isOnDuty then
			ClearPedTasksImmediately(ped)
			TaskLeaveVehicle(ped, vehicle, 0)
			exports.qbx_core:Notify(not isOnDuty and "Bạn phải onduty để sử dụng xe nghành" or "Không thể ăn trộm xe nghành", "error")
			return
		end
	end

	-- Kiểm tra Blacklist (Xe Tòa Thị Chính)
	if Config.Blacklist[vehicleModel] == true then
		if not IsAuthorized() and (not isJobWhitelisted2(QBX.PlayerData.job.name) or not isOnDuty) then
			ClearPedTasksImmediately(ped)
			TaskLeaveVehicle(ped, vehicle, 0)
			exports.qbx_core:Notify(not isOnDuty and "Bạn phải onduty để sử dụng xe này" or "Phương tiện này thuộc về Tòa Thị Chính", "error")
			return
		end
	end

	-- Kiểm tra BlacklistPolice (Xe cảnh sát)
	if Config.BlacklistPolice[vehicleModel] == true then
		if not isJobWhitelisted3(QBX.PlayerData.job.name) or not isOnDuty then
			ClearPedTasksImmediately(ped)
			TaskLeaveVehicle(ped, vehicle, 0)
			exports.qbx_core:Notify(not isOnDuty and "Bạn phải onduty để sử dụng xe này" or "Bạn không đủ thẩm quyền để sử dụng phương tiện này!", "error")
			return
		end
	end
	
	-- Kiểm tra BlacklistTaxi (Xe taxi)
	if Config.BlacklistTaxi[vehicleModel] == true then
		if QBX.PlayerData.job.name ~= "taxi" or not isOnDuty then
			ClearPedTasksImmediately(ped)
			TaskLeaveVehicle(ped, vehicle, 0)
			exports.qbx_core:Notify(not isOnDuty and "Bạn phải onduty để sử dụng xe taxi" or "Chỉ tài xế taxi mới được lái xe này!", "error")
			return
		end
	end
	
	-- Kiểm tra BlacklistAmbulance (Xe cứu thương)
	if Config.BlacklistAmbulance[vehicleModel] == true then
		if not isJobWhitelistedAmbulance(QBX.PlayerData.job.name) or not isOnDuty then
			ClearPedTasksImmediately(ped)
			TaskLeaveVehicle(ped, vehicle, 0)
			exports.qbx_core:Notify(not isOnDuty and "Bạn phải onduty để sử dụng xe cứu thương" or "Chỉ nhân viên y tế mới được lái xe này!", "error")
			return
		end
	end
end

-- Kiểm tra khi vào xe hoặc đổi ghế
Citizen.CreateThread(function()
	local lastVehicle = 0
	local wasDriver = false
	
	while true do
		Citizen.Wait(500)
		local ped = PlayerPedId()
		local vehicle = GetVehiclePedIsIn(ped, false)
		local isDriver = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
		
		-- Kiểm tra khi: vào xe mới HOẶC chuyển sang ghế lái
		if vehicle ~= 0 and isDriver and (vehicle ~= lastVehicle or not wasDriver) then
			lastVehicle = vehicle
			wasDriver = true
			CheckVehicleRestriction(ped, vehicle)
		elseif vehicle == 0 then
			lastVehicle = 0
			wasDriver = false
		elseif not isDriver then
			wasDriver = false
		end
	end
end)


function isJobWhitelisted(jobName)
	for _, whitelistedJob in pairs(Config.whitelistedJobs) do
		if jobName == whitelistedJob then
			return true
		end
	end

	return false
end

function isJobWhitelisted2(jobName)
	for _, whitelistedJob2 in pairs(Config.whitelistedJobs2) do
		if jobName == whitelistedJob2 then
			return true
		end
	end

	return false
end

function isJobWhitelisted3(jobName)
	for _, whitelistedJob3 in pairs(Config.whitelistedJobs3) do
		if jobName == whitelistedJob3 then
			return true
		end
	end

	return false
end

function isJobWhitelistedAmbulance(jobName)
	if not Config.whitelistedJobsAmbulance then return jobName == "ambulance" or jobName == "mechanic" end
	for _, whitelistedJob in pairs(Config.whitelistedJobsAmbulance) do
		if jobName == whitelistedJob then
			return true
		end
	end

	return false
end

function IsAuthorized(CitizenId)
    local retval = false
    local CitizenId = QBX.PlayerData.citizenid
    for k, cid in pairs(Config.CitizenID_List) do
        if cid == CitizenId then
            retval = true
            break
        end
    end
    return retval
end