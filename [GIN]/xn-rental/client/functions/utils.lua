local CreateVehicle                   = CreateVehicle
local SetVehicleNeedsToBeHotwired     = SetVehicleNeedsToBeHotwired
local NetworkFadeInEntity             = NetworkFadeInEntity
local SetModelAsNoLongerNeeded        = SetModelAsNoLongerNeeded
local CreatePed                       = CreatePed
local FreezeEntityPosition            = FreezeEntityPosition
local SetEntityInvincible             = SetEntityInvincible
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents

utils                                 = {}

function utils.createVehicle(vehicleModel, ...)
    local model = lib.requestModel(vehicleModel)

    if not model then return end

    local vehicle = CreateVehicle(model, ...)

      -- 🔥 Set xăng 100%
     exports['cdn-fuel']:SetFuel(vehicle, 100.0)

    SetVehicleNeedsToBeHotwired(vehicle, false)
    NetworkFadeInEntity(vehicle, true)
    SetModelAsNoLongerNeeded(model)
    local plate = GetVehicleNumberPlateText(vehicle)
	exports['Renewed-Vehiclekeys']:addKey(plate)

    return vehicle
end

function utils.createPed(name, coords)
    local model = lib.requestModel(name)

    if not model then return end

    local ped = CreatePed(0, model, coords, false, false)

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    return ped
end

function utils.showNotification(msg, type)
    lib.notify({
        title = 'Ars Rental',
        description = msg,
        type = type and type or 'info'
    })
end
