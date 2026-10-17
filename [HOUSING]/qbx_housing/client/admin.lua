-- Client-side admin UI handler

local isCapturingCoords = false
local captureTarget = nil
local isCapturingVec3 = false

-- Command: Mở admin panel
RegisterNetEvent('qbx_housing:client:createHouse', function()
    if adminUIOpen then return end
    
    adminUIOpen = true
    isCapturingCoords = false
    captureTarget = nil
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdmin'
    })
end)

-- NUI Callback: Close admin
RegisterNUICallback('closeAdmin', function(data, cb)
    adminUIOpen = false
    isCapturingCoords = false
    captureTarget = nil
    SetNuiFocus(false, false)
    cb({ success = true })
end)

-- NUI Callback: Bắt đầu lấy tọa độ (thu gọn panel và mở chế độ bấm E)
RegisterNUICallback('getCoords', function(data, cb)
    local target = data.target
    if not target then
        cb({ success = false })
        return
    end
    
    local vec3Fields = {'door', 'exit', 'garage', 'edit_door', 'edit_exit', 'edit_garage', 'juicer', 'packaging', 'edit_juicer', 'edit_packaging'}
    local isVec3 = false
    for _, field in ipairs(vec3Fields) do
        if target == field then
            isVec3 = true
            break
        end
    end
    
    isCapturingCoords = true
    captureTarget = target
    isCapturingVec3 = isVec3
    
    -- Tắt focus để player có thể di chuyển / đi lại tự do
    SetNuiFocus(false, false)
    
    cb({ success = true })
    
    -- Thread lắng nghe bấm phím E (38) hoặc ESC (177/200/202)
    CreateThread(function()
        while isCapturingCoords do
            Wait(0)
            
            -- Bấm E để lấy tọa độ tại vị trí hiện tại
            if IsControlJustPressed(0, 38) then -- E key
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                local coordsData = {
                    x = math.floor(coords.x * 100) / 100,
                    y = math.floor(coords.y * 100) / 100,
                    z = math.floor(coords.z * 100) / 100
                }
                
                if not isCapturingVec3 then
                    coordsData.h = math.floor(heading * 100) / 100
                end
                
                isCapturingCoords = false
                
                -- Bật lại NUI Focus và mở lại panel
                SetNuiFocus(true, true)
                
                SendNUIMessage({
                    action = 'setCoords',
                    target = captureTarget,
                    coords = coordsData
                })
                
                SendNUIMessage({
                    action = 'stopCoordsCapture'
                })
                
                captureTarget = nil
                break
            end
            
            -- Bấm ESC hoặc Backspace để hủy lấy tọa độ
            if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 200) or IsControlJustPressed(0, 202) then
                isCapturingCoords = false
                
                -- Bật lại NUI Focus và mở lại panel
                SetNuiFocus(true, true)
                
                SendNUIMessage({
                    action = 'stopCoordsCapture'
                })
                
                captureTarget = nil
                break
            end
        end
    end)
end)

-- NUI Callback: Hủy lấy tọa độ thủ công từ UI
RegisterNUICallback('cancelCoordsCapture', function(data, cb)
    isCapturingCoords = false
    captureTarget = nil
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'stopCoordsCapture'
    })
    cb({ success = true })
end)

-- NUI Callback: Create house
RegisterNUICallback('createHouse', function(data, cb)
    lib.callback('qbx_housing:server:adminCreateHouse', false, function(success, message)
        cb({ success = success, message = message })
        
        if success then
            lib.notify({
                title = 'Admin Housing',
                description = message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Admin Housing',
                description = message,
                type = 'error'
            })
        end
    end, data)
end)

-- NUI Callback: Get houses list
RegisterNUICallback('getHousesList', function(data, cb)
    lib.callback('qbx_housing:server:adminGetHousesList', false, function(houses)
        cb({ houses = houses or {} })
    end)
end)

-- NUI Callback: Update house
RegisterNUICallback('updateHouse', function(data, cb)
    lib.callback('qbx_housing:server:adminUpdateHouse', false, function(success, message)
        cb({ success = success, message = message })
        
        if success then
            lib.notify({
                title = 'Admin Housing',
                description = message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Admin Housing',
                description = message,
                type = 'error'
            })
        end
    end, data)
end)

-- NUI Callback: Delete house
RegisterNUICallback('deleteHouse', function(data, cb)
    lib.callback('qbx_housing:server:adminDeleteHouse', false, function(success, message)
        cb({ success = success, message = message })
        
        if success then
            lib.notify({
                title = 'Admin Housing',
                description = 'Đã xóa nhà: ' .. (data.id or ''),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Admin Housing',
                description = message,
                type = 'error'
            })
        end
    end, data.id)
end)

-- ========== REAL-TIME BROADCAST RECEIVERS ==========

RegisterNetEvent('qbx_housing:client:adminHouseCreated', function(house)
    SendNUIMessage({
        action = 'adminHouseCreated',
        house = house
    })
end)

RegisterNetEvent('qbx_housing:client:adminHouseDeleted', function(houseId)
    SendNUIMessage({
        action = 'adminHouseDeleted',
        houseId = houseId
    })
end)

RegisterNetEvent('qbx_housing:client:syncHousesList', function(houses)
    SendNUIMessage({
        action = 'syncHousesList',
        houses = houses
    })
end)

-- ========== GANG CLOTHING NUI CALLBACKS ==========

-- Lấy thông tin trang phục hiện tại của nhân vật admin
RegisterNUICallback('getPedClothing', function(data, cb)
    local clothingData = GetCurrentPedClothingData()
    cb(clothingData or {
        gender = 'male',
        components = {},
        props = {}
    })
end)

-- Lấy danh sách outfits của gang cho Admin UI
RegisterNUICallback('getGangOutfits', function(data, cb)
    local gangName = data and data.gang
    lib.callback('qbx_housing:server:adminGetGangOutfits', false, function(outfits)
        cb({ outfits = outfits or {} })
    end, gangName)
end)

-- Lưu outfit (Tạo mới hoặc cập nhật)
RegisterNUICallback('saveGangOutfit', function(data, cb)
    lib.callback('qbx_housing:server:adminSaveGangOutfit', false, function(success, message, outfitId)
        cb({ success = success, message = message, outfitId = outfitId })
        if success then
            lib.notify({
                title = 'Trang Phục Xã Đoàn',
                description = message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Trang Phục Xã Đoàn',
                description = message,
                type = 'error'
            })
        end
    end, data)
end)

-- Xóa outfit
RegisterNUICallback('deleteGangOutfit', function(data, cb)
    local outfitId = data and data.id
    lib.callback('qbx_housing:server:adminDeleteGangOutfit', false, function(success, message)
        cb({ success = success, message = message })
        if success then
            lib.notify({
                title = 'Trang Phục Xã Đoàn',
                description = message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Trang Phục Xã Đoàn',
                description = message,
                type = 'error'
            })
        end
    end, outfitId)
end)

