if not lib then return end

lib.locale()

require(('bridge.%s.client'):format(Shared.framework))
require 'client.impound'

local Edit = require 'edit_functions'
local GaragesData = lib.load 'config.garages'
local General = lib.load 'config.general'
local Interior = lib.load 'config.interior'
local Garage = require 'client.garage'
local NUI = require 'client.nui'
local Points = { enter = {}, exit = {}, park = {}, blip = {}, edit = {} }
local hasTextUI

local function nearbyPark(point)
    if cache.seat == -1 then
        ---@diagnostic disable-next-line: param-type-mismatch
		DrawMarker(General.Markers.DeleteVehicle.id, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, General.Markers.DeleteVehicle.scaleX, General.Markers.DeleteVehicle.scaleY, General.Markers.DeleteVehicle.scaleZ, General.Markers.DeleteVehicle.red, General.Markers.DeleteVehicle.green, General.Markers.DeleteVehicle.blue, 222, false, false, 0, true, false, false, false)

        if point.isClosest and point.currentDistance < 2.4 then
            if not hasTextUI then
                hasTextUI = point
                lib.showTextUI(locale('park_vehicle'))
            end

            if IsControlJustReleased(0, 38) then
                local plate = GetVehicleNumberPlateText(cache.vehicle)
                local class = GetVehicleClass(cache.vehicle)
                local properties = lib.getVehicleProperties(cache.vehicle)
                
                -- Add fuel level to properties using cdn-fuel
                properties.fuelLevel = Edit.GetFuel(cache.vehicle)
                ----debugprint('^3[GARAGE STORE]^7 Saving fuel level:', properties.fuelLevel)
                
                local cb, msg = lib.callback.await('mh_garage:cb:CanStore', 1000, point.garage, plate, class, properties)

                if not cb then
                    -- Chỉ hiển thị notify nếu có message (tránh duplicate notify)
                    if msg and msg ~= '' then
                        return Edit.Notify(locale(msg), 'warning')
                    end
                    return
                end

                -- Force delete the vehicle to prevent duplicates
                local vehicle = cache.vehicle
                if DoesEntityExist(vehicle) then
                    DeleteEntity(vehicle)
                    -- Add a small delay to ensure deletion is processed
                    Wait(100)
                end
            end
        elseif hasTextUI == point then
            hasTextUI = nil
            lib.hideTextUI()
        end
    elseif hasTextUI == point then
        hasTextUI = nil
        lib.hideTextUI()
    end
end

local function nearbyEnter(point)
    ---@diagnostic disable-next-line: param-type-mismatch
	DrawMarker(General.Markers.Enter.id, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, General.Markers.Enter.scaleX, General.Markers.Enter.scaleY, General.Markers.Enter.scaleZ, General.Markers.Enter.red, General.Markers.Enter.green, General.Markers.Enter.blue, 222, false, false, 0, true, false, false, false)

    if point.isClosest and point.currentDistance < 1.2 then
        if not hasTextUI then
            hasTextUI = point
            lib.showTextUI(locale('enter_garage', point.garage))
        end

        if IsControlJustPressed(0, 38) then
            if cache.vehicle then
                return Edit.Notify(locale('leave_vehicle_first'))
            end

            -- Open NUI instead of context menu
            NUI.OpenGarageNUI(point.garage, point.interior)
            hasTextUI = nil
            lib.hideTextUI()
        end
    elseif hasTextUI == point then
        hasTextUI = nil
        lib.hideTextUI()
    end
end

function CreateGarages()
    for k, v in pairs(GaragesData) do
        local enter = lib.points.new({
            coords = v.enter,
            distance = 30.0,
            nearby = nearbyEnter,
            garage = k,
            interior = v.interior
        })

        local park = lib.points.new({
            coords = v.parkVehicle,
            distance = 30.0,
            nearby = nearbyPark,
            garage = k
        })

        local exit = lib.points.new({
            coords = Interior[v.interior].insideSpawn,
            distance = 20.0,
            nearby = Garage.NearbyExit,
        })

        if Interior[v.interior].customizationMenu then
            local edit = lib.points.new({
                coords = Interior[v.interior].customizationMenu,
                distance = 20.0,
                nearby = Garage.NearbyCustomization,
                garage = k,
                interior = v.interior
            })

            Points.edit[#Points.edit + 1] = edit
        end

        local blip = AddBlipForCoord(v.enter.x, v.enter.y, v.enter.z)
        SetBlipSprite(blip, v.blip.id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, v.blip.scale)
        SetBlipColour(blip, v.blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(k)
        EndTextCommandSetBlipName(blip)
        SetBlipCategory(blip, 10)

        Points.enter[#Points.enter + 1] = enter
        Points.exit[#Points.exit + 1] = exit
        Points.park[#Points.park + 1] = park
        Points.blip[#Points.blip + 1] = blip
    end
end

-- ========== QBX HOUSING INTEGRATION EXPORTS ==========
-- CRITICAL: Đặt exports NGAY SAU CreateGarages() để đảm bảo chúng được load
-- Export để inject garage mới và tạo points/zones
exports('InjectGarage', function(garageName, garageConfig)
    if not garageName or not garageConfig then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: Missing garageName or garageConfig')
        return false
    end
    
    --debugprint('^3[MH_GARAGE CLIENT]^7 InjectGarage called for: ' .. garageName)
    
    -- CRITICAL VALIDATION: Kiểm tra vehicleSpawnPoint trước khi inject
    if not garageConfig.vehicleSpawnPoint then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: vehicleSpawnPoint is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.vehicleSpawnPoint.x or not garageConfig.vehicleSpawnPoint.y or not garageConfig.vehicleSpawnPoint.z then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: vehicleSpawnPoint invalid coords for ' .. garageName)
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 vehicleSpawnPoint: ' .. json.encode(garageConfig.vehicleSpawnPoint))
        return false
    end
    
    if not garageConfig.parkVehicle then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: parkVehicle is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.enter then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: enter is NULL for ' .. garageName)
        return false
    end
    
    if not garageConfig.interior then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: interior is NULL for ' .. garageName)
        return false
    end
    
    -- Validate Interior exists
    if not Interior[garageConfig.interior] then
        --debugprint('^1[MH_GARAGE CLIENT ERROR]^7 InjectGarage: Interior "' .. tostring(garageConfig.interior) .. '" not found for ' .. garageName)
        return false
    end
    
    -- Inject vào GaragesData (KHÔNG GHI ĐÈ garages khác)
    GaragesData[garageName] = garageConfig
    
    --debugprint('^2[MH_GARAGE CLIENT]^7 Injected garage "' .. garageName .. '" into GaragesData')
    --debugprint('^3[MH_GARAGE CLIENT]^7   vehicleSpawnPoint: ' .. json.encode(garageConfig.vehicleSpawnPoint))
    
    -- Kiểm tra xem có phải house garage không (bắt đầu với "house_")
    local isHouseGarage = garageName:find('^house_') ~= nil
    
    -- CHỈ TẠO ENTER POINT cho garages KHÔNG PHẢI house (house dùng NUI)
    local enter = nil
    if not isHouseGarage then
        enter = lib.points.new({
            coords = garageConfig.enter,
            distance = 30.0,
            nearby = nearbyEnter,
            garage = garageName,
            interior = garageConfig.interior
        })
    end
    
    -- LUÔN TẠO PARK POINT (marker cất xe - màu xanh lá)
    local park = lib.points.new({
        coords = garageConfig.parkVehicle,
        distance = 30.0,
        nearby = nearbyPark,
        garage = garageName
    })
    
    -- Tạo exit point (interior)
    local exit = lib.points.new({
        coords = Interior[garageConfig.interior].insideSpawn,
        distance = 20.0,
        nearby = Garage.NearbyExit,
    })
    
    -- Tạo customization point nếu có
    local edit = nil
    if Interior[garageConfig.interior].customizationMenu then
        edit = lib.points.new({
            coords = Interior[garageConfig.interior].customizationMenu,
            distance = 20.0,
            nearby = Garage.NearbyCustomization,
            garage = garageName,
            interior = garageConfig.interior
        })
    end
    
    -- CHỈ TẠO BLIP cho garages KHÔNG PHẢI house
    local blip = nil
    if not isHouseGarage and garageConfig.blip and garageConfig.blip.id and garageConfig.blip.id > 0 then
        blip = AddBlipForCoord(garageConfig.enter.x, garageConfig.enter.y, garageConfig.enter.z)
        SetBlipSprite(blip, garageConfig.blip.id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, garageConfig.blip.scale)
        SetBlipColour(blip, garageConfig.blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(garageName)
        EndTextCommandSetBlipName(blip)
        SetBlipCategory(blip, 10)
    end
    
    -- Ensure Points tables exist
    Points.enter = Points.enter or {}
    Points.park = Points.park or {}
    Points.exit = Points.exit or {}
    Points.edit = Points.edit or {}
    Points.blip = Points.blip or {}
    
    -- Lưu với key là garageName (CHỈ LƯU NẾU TỒN TẠI)
    if enter then Points.enter[garageName] = enter end
    Points.park[garageName] = park
    Points.exit[garageName] = exit
    if edit then Points.edit[garageName] = edit end
    if blip then Points.blip[garageName] = blip end
    
    -- if isHouseGarage then
    --     --debugprint('^2[MH_GARAGE CLIENT]^7 Injected house garage "' .. garageName .. '" (PARK marker only, no ENTER marker)')
    -- else
    --     --debugprint('^2[MH_GARAGE CLIENT]^7 Injected public garage "' .. garageName .. '" with all points/zones')
    -- end
    return true
end)

-- Export để remove garage và xóa points/zones
exports('RemoveGarage', function(garageName)
    if not garageName then return false end
    
    --debugprint('^3[MH_GARAGE CLIENT]^7 RemoveGarage called for: ' .. garageName)
    
    -- Remove points
    if Points.enter and Points.enter[garageName] then
        Points.enter[garageName]:remove()
        Points.enter[garageName] = nil
    end
    
    if Points.park and Points.park[garageName] then
        Points.park[garageName]:remove()
        Points.park[garageName] = nil
    end
    
    if Points.exit and Points.exit[garageName] then
        Points.exit[garageName]:remove()
        Points.exit[garageName] = nil
    end
    
    if Points.edit and Points.edit[garageName] then
        Points.edit[garageName]:remove()
        Points.edit[garageName] = nil
    end
    
    -- Remove blip
    if Points.blip and Points.blip[garageName] then
        RemoveBlip(Points.blip[garageName])
        Points.blip[garageName] = nil
    end
    
    -- Remove from GaragesData
    GaragesData[garageName] = nil
    
    --debugprint('^2[MH_GARAGE CLIENT]^7 Removed garage "' .. garageName .. '" and all points')
    return true
end)

function ClearAll()
    for i = 1, #Points.enter do Points.enter[i]:remove() end
    for i = 1, #Points.park do Points.park[i]:remove() end
    for i = 1, #Points.exit do Points.exit[i]:remove() end
    for i = 1, #Points.edit do Points.edit[i]:remove() end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        ClearAll()
    end
end)