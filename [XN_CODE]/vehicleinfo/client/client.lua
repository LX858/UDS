local config = lib.require('config')

local function vehicleHealthColor(progress)
    if progress >= 75 then
        return 'green'
    elseif progress < 75 and progress >= 50 then
        return 'yellow'
    elseif progress < 50 and progress >= 25 then
        return 'orange'
    elseif progress < 25 and progress >= 0 then
        return 'red'
    end
end

local function getModLabel(vehicle, modType)
    local modValue = GetVehicleMod(vehicle, modType)
    
    if modValue == -1 then
        return 'Mặc định'
    else
        local modLabel = GetLabelText(GetModTextLabel(vehicle, modType, GetVehicleMod(vehicle, modType)))
        return modLabel ~= 'NULL' and modLabel or 'Không xác định'
    end
end

local function OpenVehicleMenu(targetVehicle)
    local vehicle = targetVehicle
    if vehicle and DoesEntityExist(vehicle) then
        local fuelProgress

        local vehicleModelHash = GetEntityModel(vehicle)
        local vehicleSpawnCode = string.lower(GetDisplayNameFromVehicleModel(vehicleModelHash))
        local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(vehicleModelHash))
        local vehicleClass = config.vehicleClass[vehicleSpawnCode]

        local engineMod = GetVehicleMod(vehicle, 11)
        local brakeMod = GetVehicleMod(vehicle, 12)
        local suspensionMod = GetVehicleMod(vehicle, 13)
        local transmissionMod = GetVehicleMod(vehicle, 14)
        local armourMod = GetVehicleMod(vehicle, 16)
        local turboEnabled = IsToggleModOn(vehicle, 18)

        engineMod = engineMod ~= -1 and tostring(engineMod).." LVL" or 'Mặc định'
        brakeMod = brakeMod ~= -1 and tostring(brakeMod).." LVL" or 'Mặc định'
        suspensionMod = suspensionMod ~= -1 and tostring(suspensionMod).." LVL" or 'Mặc định'
        transmissionMod = transmissionMod ~= -1 and tostring(transmissionMod).." LVL" or 'Mặc định'
        armourMod = armourMod ~= -1 and tostring(armourMod).." LVL" or 'Mặc định'

        if config.fuel == 'ox_fuel' then
            fuelProgress = Entity(vehicle) and Entity(vehicle).state and Entity(vehicle).state.fuel or GetVehicleFuelLevel(vehicle)
        else
            fuelProgress = exports[config.fuel]:GetFuel(vehicle)
        end
    

        lib.registerContext({
            id = 'vehicle_menu',
            title = 'Thông tin xe',
            options = {
                {
                    title = vehicleName,
                    description = 'Biển số: ' .. GetVehicleNumberPlateText(vehicle),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Hạng xe',
                    description = 'Hạng: ' .. (vehicleClass or 'Không xác định'),
                    icon = 'fa-solid fa-chart-simple',
                },
                {
                    title = 'Mức nhiên liệu',
                    description = ('Mức: %s%%'):format(tostring(math.ceil(fuelProgress))),
                    progress = math.ceil(fuelProgress),
                    colorScheme = '#FFFF00',
                    icon = 'fas fa-gas-pump'
                },
                {
                    title = 'Độ bền động cơ',
                    description = ('Độ bền: %s%%'):format(tostring(math.ceil(lib.getVehicleProperties(vehicle).engineHealth / 10))),
                    progress = (lib.getVehicleProperties(vehicle).engineHealth / 10),
                    colorScheme = vehicleHealthColor(math.ceil(lib.getVehicleProperties(vehicle).engineHealth / 10)),
                    icon = 'fas fa-car-battery'
                },
                {
                    title = 'Độ bền thân xe',
                    description = ('Độ bền: %s%%'):format(tostring(math.ceil(lib.getVehicleProperties(vehicle).bodyHealth / 10))),
                    progress = (lib.getVehicleProperties(vehicle).bodyHealth / 10),
                    colorScheme = vehicleHealthColor(math.ceil(lib.getVehicleProperties(vehicle).bodyHealth / 10)),
                    icon = 'fas fa-car-burst'
                },
                {
                    title = 'Động cơ',
                    description = 'Động cơ: ' .. engineMod,
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Phanh xe',
                    description = 'Phanh: ' .. brakeMod,
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Hệ thống treo',
                    description = 'Giảm xóc: ' .. suspensionMod,
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Hộp số',
                    description = 'Hộp số: ' .. transmissionMod,
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Giáp xe',
                    description = 'Giáp: ' .. armourMod,
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Turbo',
                    description = 'Turbo: ' .. (turboEnabled and 'Bật' or 'Tắt'),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cánh gió',
                    description = 'Cánh gió: ' .. getModLabel(vehicle, 0),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cản trước',
                    description = 'Cản trước: ' .. getModLabel(vehicle, 1),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cản sau',
                    description = 'Cản sau: ' .. getModLabel(vehicle, 2),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Váy xe',
                    description = 'Váy xe: ' .. getModLabel(vehicle, 3),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Ống xả',
                    description = 'Ống xả: ' .. getModLabel(vehicle, 4),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Mặt calang',
                    description = 'Mặt calang: ' .. getModLabel(vehicle, 6),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cánh trái',
                    description = 'Cánh trái: ' .. getModLabel(vehicle, 8),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cánh phải',
                    description = 'Cánh phải: ' .. getModLabel(vehicle, 9),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Nóc xe',
                    description = 'Nóc xe: ' .. getModLabel(vehicle, 10),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Còi xe',
                    description = 'Còi xe: ' .. getModLabel(vehicle, 14),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Khói lốp',
                    description = 'Khói lốp: ' .. getModLabel(vehicle, 20),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Hệ thống thủy lực',
                    description = 'Thủy lực: ' .. getModLabel(vehicle, 21),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Đèn Xenon',
                    description = 'Đèn Xenon: ' .. getModLabel(vehicle, 22),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Bánh xe',
                    description = 'Bánh xe: ' .. getModLabel(vehicle, 23),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cửa trái',
                    description = 'Cửa trái: ' .. getModLabel(vehicle, 46),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Cửa phải',
                    description = 'Cửa phải: ' .. getModLabel(vehicle, 47),
                    icon = 'fa-solid fa-car',
                },
                {
                    title = 'Decal xe',
                    description = 'Decal: ' .. getModLabel(vehicle, 48),
                    icon = 'fa-solid fa-car',
                },
            }
        })
        lib.showContext('vehicle_menu')
    else
        lib.notify({ description = 'Không thể lấy thông tin xe', type = 'error' })
    end
end

-- Tạo ox_target cho vehicles
exports.ox_target:addGlobalVehicle({
    {
        name = 'vehicle_info',
        icon = 'fas fa-info-circle',
        label = 'Thông tin xe',
        onSelect = function(data)
            OpenVehicleMenu(data.entity)
        end,
        canInteract = function(entity)
            return DoesEntityExist(entity) and IsEntityAVehicle(entity)
        end
    }
})


