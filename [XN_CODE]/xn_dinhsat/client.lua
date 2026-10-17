local function notify(title, description, type)
    if lib and lib.notify then
        lib.notify({ title = title, description = description, type = type or 'inform' })
    else
        print(('[%s] %s'):format(title, description))
    end
end

local function getNearestVehicle(maxDistance)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    maxDistance = maxDistance or 5.0
    
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    
    local vehicle = GetClosestVehicle(pedCoords.x, pedCoords.y, pedCoords.z, maxDistance, 0, 70)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        return vehicle
    end
    
    local closestVehicle = 0
    local closestDistance = maxDistance
    
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local distance = #(pedCoords - vehCoords)
            if distance < closestDistance then
                closestVehicle = veh
                closestDistance = distance
            end
        end
    end
    
    return closestVehicle
end

local function getTireStatus(vehicle, tireIndex)
    if IsVehicleTyreBurst(vehicle, tireIndex, false) then
        return '❌ Da bi troc'
    else
        return '✅ Con tot'
    end
end

local tireNames = {
    [0] = 'Banh truoc trai',
    [1] = 'Banh truoc phai',
    [4] = 'Banh sau trai',
    [5] = 'Banh sau phai'
}

local function getWheelPosition(vehicle, wheelIndex)
    local boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_lf')
    if wheelIndex == 0 then
        boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_lf')
    elseif wheelIndex == 1 then
        boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_rf')
    elseif wheelIndex == 4 then
        boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_lr')
    elseif wheelIndex == 5 then
        boneIndex = GetEntityBoneIndexByName(vehicle, 'wheel_rr')
    end
    
    if boneIndex ~= -1 then
        return GetWorldPositionOfEntityBone(vehicle, boneIndex)
    end
    
    return GetEntityCoords(vehicle)
end

local function moveToPunctureTire(vehicle, tireIndex)
    local ped = PlayerPedId()
    local wheelPos = getWheelPosition(vehicle, tireIndex)
    
    TaskGoToCoordAnyMeans(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1.0, 0, 0, 786603, 0xbf800000)
    
    local timeout = 0
    while timeout < 100 do
        local pedPos = GetEntityCoords(ped)
        local distance = #(pedPos - wheelPos)
        
        if distance < 1.5 then
            break
        end
        
        Wait(100)
        timeout = timeout + 1
    end
    
    ClearPedTasks(ped)
    TaskTurnPedToFaceCoord(ped, wheelPos.x, wheelPos.y, wheelPos.z, 1000)
    Wait(1000)
    
    RequestAnimDict('amb@medic@standing@kneel@base')
    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') do
        Wait(10)
    end
    
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = 3000,
        label = 'Dang troc lop xe...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    })
    
    ClearPedTasks(ped)
    
    if not success then
        notify('Dinhsat', 'Da huy troc lop.', 'error')
        return false
    end
    
    return true
end

local function useDinhsat()
    local vehicle = getNearestVehicle(6.0)
    if vehicle == 0 then
        notify('Dinhsat', 'Khong tim thay xe gan ban.', 'error')
        return
    end

    local options = {}
    for tireIndex, tireName in pairs(tireNames) do
        local status = getTireStatus(vehicle, tireIndex)
        table.insert(options, {
            title = tireName,
            description = 'Tinh trang banh: ' .. status,
            icon = 'fa-solid fa-circle-dot',
            disabled = IsVehicleTyreBurst(vehicle, tireIndex, false),
            onSelect = function()
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                if moveToPunctureTire(vehicle, tireIndex) then
                    TriggerServerEvent('xn_dinhsat:server:burstTires', netId, tireIndex)
                end
            end
        })
    end

    lib.registerContext({
        id = 'dinhsat_menu',
        title = '🔧 Chon banh xe de troc',
        options = options
    })

    lib.showContext('dinhsat_menu')
end

RegisterNetEvent('xn_dinhsat:client:burstTireSync', function(netId, tireIndex)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        if tireIndex then
            SetVehicleTyreBurst(vehicle, tireIndex, true, 1000.0)
        else
            for i = 0, 7 do
                SetVehicleTyreBurst(vehicle, i, true, 1000.0)
            end
        end
    end
end)

RegisterNetEvent('xn_dinhsat:client:useDinhsat', useDinhsat)
