function GetFuel(vehicle)
	return DecorGetFloat(vehicle, Config.FuelDecor)
end

-- Reads the vehicle's fuel in a way that is consistent across clients.
-- The native GetVehicleFuelLevel is only accurate on the network owner's machine, so a player
-- refueling someone else's car would read a stale/default value (e.g. 100%) while the driver sees the real level.
-- The decorator is broadcast by the engine, so prefer it; fall back to the native value only when no decor exists yet.
function GetSyncedFuel(vehicle)
	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return 0 end
	if DecorExistOn(vehicle, Config.FuelDecor) then
		return DecorGetFloat(vehicle, Config.FuelDecor)
	end
	return GetVehicleFuelLevel(vehicle)
end

-- Fuel level/decor is only reliably broadcast by the machine that owns the vehicle's network entity.
-- Without this, refueling a vehicle you're not driving (e.g. Player A refueling Player B's car) only
-- updates your own local copy, which then gets overwritten once the real owner syncs again (e.g. Player B getting in).
function EnsureNetworkControl(vehicle)
	if not NetworkHasControlOfEntity(vehicle) then
		NetworkRequestControlOfEntity(vehicle)
		local attempts = 0
		while not NetworkHasControlOfEntity(vehicle) and attempts < 50 do
			Wait(0)
			attempts = attempts + 1
		end
	end
end

function SetFuel(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
		EnsureNetworkControl(vehicle)
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, Config.FuelDecor, GetVehicleFuelLevel(vehicle))
	end
end

function LoadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Wait(5)
	end
end

function GlobalTax(value)
	if Config.GlobalTax < 0.1 then
		return 0
	end
	local tax = (value / 100 * Config.GlobalTax)
	return tax
end

function Comma_Value(amount)
	local formatted = amount
	while true do
	  formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	  if (k==0) then
		break
	  end
	end
	return formatted
end

function math.percent(percent, maxvalue)
	if tonumber(percent) and tonumber(maxvalue) then
		return (maxvalue*percent)/100
	end
	return false
end

function Round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function GetCurrentVehicleType(vehicle)
	if not vehicle then
		vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
	end
	if not vehicle then return false end
	local vehModel = GetEntityModel(vehicle)
	local vehiclename = string.lower(GetDisplayNameFromVehicleModel(vehModel))

	if Config.ElectricVehicles[vehiclename] and Config.ElectricVehicles[vehiclename].isElectric then
		return 'electricvehicle'
	else
		return 'gasvehicle'
	end
end



function CreateBlip(coords, label)
	local blip = AddBlipForCoord(coords)
	SetBlipSprite(blip, 361)
	SetBlipColour(blip, 1) -- Red
	SetBlipScale(blip, 0.7)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(label)
	EndTextCommandSetBlipName(blip)
	return blip
end



-- function CreateBlip(coords, label)
-- 	local blip = AddBlipForCoord(coords)
-- 	local vehicle = GetCurrentVehicleType()
-- 	local electricbolt = Config.ElectricSprite -- Sprite
-- 	if vehicle == 'electricvehicle' then
-- 		SetBlipSprite(blip, electricbolt) -- This is where the fuel thing will get changed into the electric bolt instead of the pump.
-- 		SetBlipColour(blip, 0)
-- 	else
-- 		SetBlipSprite(blip, 361)
-- 		SetBlipColour(blip, 0)
-- 	end
-- 	SetBlipScale(blip, 0.8)
-- 	SetBlipDisplay(blip, 4)
-- 	SetBlipAsShortRange(blip, true)
-- 	BeginTextCommandSetBlipName("STRING")
-- 	AddTextComponentString(label)
-- 	EndTextCommandSetBlipName(blip)
-- 	return blip
-- end

function GetClosestVehicle(coords)
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if currentVehicle and currentVehicle ~= 0 and DoesEntityExist(currentVehicle) then
        return currentVehicle, 0.0
    end

    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = 0
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end

    for i = 1, #vehicles, 1 do
        local vehicle = vehicles[i]
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(vehicleCoords - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestVehicle = vehicle
                closestDistance = distance
            end
        end
    end

    return closestVehicle, closestDistance
end


function IsPlayerNearVehicle()
	if Config.FuelDebug then
		print("Checking if player is near a vehicle!")
	end
	local vehicle = GetClosestVehicle()
	if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
		return false
	end
	local pedCoords = GetEntityCoords(PlayerPedId())
	local vehicleCoords = GetEntityCoords(vehicle)
	return #(pedCoords - vehicleCoords) <= 3.0
end

function IsVehicleBlacklisted(veh)
	if Config.FuelDebug then print("IsVehicleBlacklisted("..tostring(veh)..")") end
	if veh and veh ~= 0 then
		veh = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
		if Config.FuelDebug then print("Vehicle: "..veh) end
		-- Puts Vehicles In Blacklist if you have electric charging on.
		if not Config.ElectricVehicleCharging then
			if Config.ElectricVehicles[veh] and Config.ElectricVehicles[veh].isElectric then
				if Config.FuelDebug then print("Vehicle: "..veh.." is in the Blacklist.") end
				return true
			end
		end

		if Config.NoFuelUsage[veh] and Config.NoFuelUsage[veh].blacklisted then
			if Config.FuelDebug then print("Vehicle: "..veh.." is in the Blacklist.") end
			-- If the veh equals a vehicle in the list then return true.
			return true
		end

		-- Default False
		if Config.FuelDebug then print("Vehicle is not blacklisted.") end
		return false
	else
		if Config.FuelDebug then print("veh is nil!") end
		return false
	end
	-- return true
end