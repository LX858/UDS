-- Client-side code

local isUIOpen = false

-- Event để mở UI từ server
RegisterNetEvent('xn_adminitem:openUI', function()
    if not isUIOpen then
        openUI()
    end
end)

-- Hàm mở UI
function openUI()
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open'
    })
    TriggerServerEvent('xn_adminitem:getAllItems')
end

-- Hàm đóng UI
function closeUI()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    closeUI()
    cb('ok')
end)

RegisterNUICallback('searchItem', function(data, cb)
    TriggerServerEvent('xn_adminitem:searchItem', data.searchTerm)
    cb('ok')
end)

RegisterNUICallback('searchByDoHiem', function(data, cb)
    TriggerServerEvent('xn_adminitem:searchByDoHiem', data.doHiem)
    cb('ok')
end)

RegisterNUICallback('searchByCapDo', function(data, cb)
    TriggerServerEvent('xn_adminitem:searchByCapDo', data.itemName, data.capDo)
    cb('ok')
end)

RegisterNUICallback('searchByCloth', function(data, cb)
    TriggerServerEvent('xn_adminitem:searchByCloth', data.clothType, data.drawable, data.sex)
    cb('ok')
end)

RegisterNUICallback('getItemDetails', function(data, cb)
    TriggerServerEvent('xn_adminitem:getItemDetails', data.itemName, data.pageType, data.pageNumber, data.metadata)
    cb('ok')
end)

RegisterNUICallback('getAllItems', function(data, cb)
    TriggerServerEvent('xn_adminitem:getAllItems')
    cb('ok')
end)

RegisterNUICallback('getServerItem', function(data, cb)
    TriggerServerEvent('xn_adminitem:getServerItem', data.itemName, data.count, data.reason)
    cb('ok')
end)

RegisterNUICallback('setItemLimit', function(data, cb)
    TriggerServerEvent('xn_adminitem:setItemLimit', data.itemName, data.limit)
    cb('ok')
end)

RegisterNUICallback('setItemBlacklist', function(data, cb)
    TriggerServerEvent('xn_adminitem:setItemBlacklist', data.itemName, data.isBlacklisted)
    cb('ok')
end)



RegisterNUICallback('deleteItem', function(data, cb)
    TriggerServerEvent('xn_adminitem:deleteItem', data.itemName, data.quantity, data.type, data.data, data.metadata)
    cb('ok')
end)

-- New Tab Callbacks
RegisterNUICallback('getPlayers', function(data, cb)
    print('[CLIENT] getPlayers callback - data:', json.encode(data))
    print('[CLIENT] page:', data.page, 'searchTerm:', data.searchTerm)
    TriggerServerEvent('xn_adminitem:getPlayers', {
        page = data.page or 1,
        searchTerm = data.searchTerm or ''
    })
    cb('ok')
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    TriggerServerEvent('xn_adminitem:getPlayerInventory', data.citizenid)
    cb('ok')
end)

RegisterNUICallback('getVehicles', function(data, cb)
    print('[CLIENT] getVehicles callback - data:', json.encode(data))
    print('[CLIENT] page:', data.page, 'searchTerm:', data.searchTerm)
    TriggerServerEvent('xn_adminitem:getVehicles', {
        page = data.page or 1,
        searchTerm = data.searchTerm or ''
    })
    cb('ok')
end)

RegisterNUICallback('getVehicleTrunk', function(data, cb)
    TriggerServerEvent('xn_adminitem:getVehicleTrunk', data.plate)
    cb('ok')
end)

RegisterNUICallback('getMotels', function(data, cb)
    TriggerServerEvent('xn_adminitem:getMotels')
    cb('ok')
end)

RegisterNUICallback('getMotelRoomInventory', function(data, cb)
    TriggerServerEvent('xn_adminitem:getMotelRoomInventory', data.motelName, data.roomNumber)
    cb('ok')
end)

RegisterNUICallback('getOtherStashes', function(data, cb)
    print('[CLIENT] getOtherStashes callback - data:', json.encode(data))
    print('[CLIENT] page:', data.page, 'searchTerm:', data.searchTerm)
    TriggerServerEvent('xn_adminitem:getOtherStashes', {
        page = data.page or 1,
        searchTerm = data.searchTerm or ''
    })
    cb('ok')
end)

RegisterNUICallback('getStashInventory', function(data, cb)
    TriggerServerEvent('xn_adminitem:getStashInventory', data.stashName)
    cb('ok')
end)

RegisterNUICallback('takeItemFromPlayer', function(data, cb)
    print('[CLIENT] takeItemFromPlayer - citizenid:', data.citizenid, 'item:', data.itemName, 'count:', data.count)
    TriggerServerEvent('xn_adminitem:takeItemFromPlayer', {
        citizenid = data.citizenid,
        slot = data.slot,
        itemName = data.itemName,
        count = data.count,
        metadata = data.metadata
    })
    cb('ok')
end)

RegisterNUICallback('takeItemFromStash', function(data, cb)
    print('[CLIENT] takeItemFromStash - stashName:', data.stashName, 'item:', data.itemName, 'count:', data.count)
    TriggerServerEvent('xn_adminitem:takeItemFromStash', {
        stashName = data.stashName,
        slot = data.slot,
        itemName = data.itemName,
        count = data.count,
        metadata = data.metadata
    })
    cb('ok')
end)

-- Client Events to receive data from server
RegisterNetEvent('xn_adminitem:playersData', function(data)
    SendNUIMessage({
        action = 'playersData',
        players = data.players,
        totalPages = data.totalPages,
        currentPage = data.currentPage
    })
end)

RegisterNetEvent('xn_adminitem:playerInventoryData', function(data)
    SendNUIMessage({
        action = 'playerInventoryData',
        citizenid = data.citizenid,
        inventory = data.inventory
    })
end)

RegisterNetEvent('xn_adminitem:vehiclesData', function(data)
    SendNUIMessage({
        action = 'vehiclesData',
        vehicles = data.vehicles,
        totalPages = data.totalPages,
        currentPage = data.currentPage
    })
end)

RegisterNetEvent('xn_adminitem:vehicleTrunkData', function(data)
    SendNUIMessage({
        action = 'vehicleTrunkData',
        plate = data.plate,
        trunk = data.trunk
    })
end)

RegisterNetEvent('xn_adminitem:motelsData', function(data)
    SendNUIMessage({
        action = 'motelsData',
        motels = data
    })
end)

RegisterNetEvent('xn_adminitem:motelRoomInventoryData', function(data)
    SendNUIMessage({
        action = 'motelRoomInventoryData',
        motelName = data.motelName,
        roomNumber = data.roomNumber,
        inventory = data.inventory
    })
end)

RegisterNetEvent('xn_adminitem:otherStashesData', function(data)
    SendNUIMessage({
        action = 'otherStashesData',
        stashes = data.stashes,
        totalPages = data.totalPages,
        currentPage = data.currentPage
    })
end)

RegisterNetEvent('xn_adminitem:stashInventoryData', function(data)
    SendNUIMessage({
        action = 'stashInventoryData',
        stashName = data.stashName,
        inventory = data.inventory
    })
end)

-- Nhận kết quả tìm kiếm
RegisterNetEvent('xn_adminitem:searchResults', function(results)
    SendNUIMessage({
        action = 'searchResults',
        results = results
    })
end)

-- Nhận chi tiết item
RegisterNetEvent('xn_adminitem:itemDetails', function(details)
    SendNUIMessage({
        action = 'itemDetails',
        details = details
    })
end)

-- Nhận danh sách tất cả items
RegisterNetEvent('xn_adminitem:allItems', function(data)
    SendNUIMessage({
        action = 'allItems',
        items = data.items,
        canGet = data.canGet,
        canEdit = data.canEdit
    })
end)

-- Nhận kết quả xóa item
RegisterNetEvent('xn_adminitem:deleteResult', function(success)
    SendNUIMessage({
        action = 'deleteResult',
        success = success
    })
end)

-- Đóng UI khi nhấn ESC
RegisterCommand('closeui', function()
    if isUIOpen then
        closeUI()
    end
end, false)

RegisterKeyMapping('closeui', 'Đóng Admin Item UI', 'keyboard', 'ESCAPE')
