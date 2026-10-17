-- NUI Handler cho Housing System
local QBX = exports.qbx_core
local nuiOpen = false
local currentNuiHouseId = nil

-- Map loại nhà sang label tiếng Việt
local houseLabels = {
    ['slum'] = {
        type = 'Nhà Ổ Chuột',
        category = 'Căn hộ Giá Rẻ',
        garage = 'tiết kiệm'
    },
    ['regular'] = {
        type = 'Nhà Thường',
        category = 'Căn hộ Tiêu Chuẩn',
        garage = 'trung cấp'
    },
    ['apartment'] = {
        type = 'Nhà Chung Cư',
        category = 'Căn hộ Cao Cấp',
        garage = 'cao cấp'
    },
    ['homestay'] = {
        type = 'Homestay',
        category = 'Căn hộ Luxury Seductive',
        garage = 'cao cấp'
    }
}

-- Mở NUI
function OpenHousingNUI(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then 
        return 
    end
    
    local houseType = Config.HouseTypes[houseConfig.type]
    local labels = houseLabels[houseConfig.type] or {
        type = houseConfig.type,
        category = 'Căn hộ Tiêu Chuẩn',
        garage = 'tiêu chuẩn'
    }
    
    -- Check if player is realestate on duty
    local PlayerData = QBX:GetPlayerData()
    local isRealestate = PlayerData.job and PlayerData.job.name == 'realestate' and PlayerData.job.onduty
    
    -- Get house data từ server
    lib.callback('qbx_housing:server:getHouseInfo', false, function(houseData)
        local isGang = (houseConfig and houseConfig.gang and houseConfig.gang ~= '' and houseConfig.gang ~= 'none') or (houseData and (houseData.isGangHouse or (houseData.gang and houseData.gang ~= '' and houseData.gang ~= 'none'))) or (houseConfig and houseConfig.type == 'gang')
        local gangName = (houseData and houseData.gangLabel) or (houseData and houseData.gang) or (houseConfig and houseConfig.gang)
        local gangLvl = tonumber(houseConfig and houseConfig.level) or 1
        
        local displayTypeLabel = labels.type
        local displayCategoryLabel = labels.category
        if isGang and gangName then
            displayTypeLabel = 'Nhà ' .. tostring(gangName)
            displayCategoryLabel = 'Trụ Sở Xã Đoàn (Cấp ' .. tostring(gangLvl) .. ')'
        end

        local data = {
            houseId = houseId,
            houseType = houseConfig.type,
            typeLabel = displayTypeLabel,
            categoryLabel = displayCategoryLabel,
            garageLabel = labels.garage,
            maxVehicles = houseType and houseType.garage and houseType.garage.maxVehicles or 2,
            maxSharedKeys = houseType and houseType.maxSharedKeys or 0,
            storageSlots = houseType and houseType.storage and houseType.storage.slots or 25,
            storageWeight = houseType and houseType.storage and houseType.storage.weight or 100000,
            price = houseData and houseData.price or (houseType and houseType.price or 50000),
            isGangHouse = isGang or false,
            gang = houseData and houseData.gang or houseConfig.gang,
            gangLabel = (houseData and houseData.gangLabel) or gangName,
            gangLevel = gangLvl,
            isGangMember = houseData and houseData.isGangMember or false,
            isBoss = houseData and houseData.isBoss or false,
            gangGrade = houseData and houseData.gangGrade or 0,
            isOwned = isGang or false,
            isOwner = isGang and (houseData and houseData.isBoss) or false,
            hasKeys = isGang and (houseData and houseData.isGangMember) or false,
            isRealestate = isRealestate,
            ownerName = isGang and ('Xã Đoàn ' .. tostring(gangName)) or 'Trống',
            image = 'images/' .. houseConfig.type .. '.png',
            robbery = houseData and houseData.robbery or nil
        }
        
        if houseData and houseData.owner_name then
            data.isOwned = true
            data.isOwner = houseData.isOwner or false
            data.hasKeys = houseData.hasKeys or false
            data.ownerName = houseData.owner_name
        end

        -- Kiem tra quyen Trom Nha Gang (xn_ganghouserob)
        local playerGangName = PlayerData.gang and PlayerData.gang.name or nil
        local playerGangGrade = 0
        if PlayerData.gang and PlayerData.gang.grade then
            if type(PlayerData.gang.grade) == 'table' then
                playerGangGrade = tonumber(PlayerData.gang.grade.level) or 0
            elseif type(PlayerData.gang.grade) == 'number' then
                playerGangGrade = PlayerData.gang.grade
            end
        end

        local targetHouseGang = houseData and houseData.gang or houseConfig.gang
        local canRob = false
        if isGang and targetHouseGang and playerGangName and playerGangName ~= 'none' and playerGangName ~= '' then
            if playerGangName ~= targetHouseGang and playerGangGrade >= 2 then
                canRob = true
            end
        end
        data.canRob = canRob

        currentNuiHouseId = houseId
        
        -- Send to NUI
        SendNUIMessage({
            action = 'showUI',
            houseData = data
        })
        
        SetNuiFocus(true, true)
        nuiOpen = true
    end, houseId)
end

-- Đóng NUI
function CloseHousingNUI()
    SendNUIMessage({
        action = 'hideUI'
    })
    
    SetNuiFocus(false, false)
    nuiOpen = false
    currentNuiHouseId = nil
end

-- REAL-TIME SYNC: Lắng nghe event đồng bộ từ server
RegisterNetEvent('qbx_housing:client:syncHouseData', function(houseId, updatedData)
    if not houseId then return end
    
    -- Nếu đang mở NUI cho đúng nhà này -> cập nhật NUI tức thì
    if nuiOpen and currentNuiHouseId == houseId then
        local houseConfig = GetHouseConfigClient(houseId)
        if houseConfig then
            local houseType = Config.HouseTypes[houseConfig.type]
            local labels = houseLabels[houseConfig.type] or {
                type = houseConfig.type,
                category = 'Căn hộ Tiêu Chuẩn',
                garage = 'tiêu chuẩn'
            }
            
            local PlayerData = QBX:GetPlayerData()
            local isRealestate = PlayerData.job and PlayerData.job.name == 'realestate' and PlayerData.job.onduty
            
            local data = {
                houseId = houseId,
                houseType = houseConfig.type,
                typeLabel = labels.type,
                categoryLabel = labels.category,
                garageLabel = labels.garage,
                maxVehicles = houseType and houseType.garage and houseType.garage.maxVehicles or 2,
                maxSharedKeys = houseType and houseType.maxSharedKeys or 0,
                storageSlots = houseType and houseType.storage and houseType.storage.slots or 25,
                storageWeight = houseType and houseType.storage and houseType.storage.weight or 100000,
                price = updatedData and updatedData.price or (houseType and houseType.price or 50000),
                isOwned = false,
                isOwner = false,
                hasKeys = false,
                isRealestate = isRealestate,
                ownerName = 'Trống',
                image = 'images/' .. houseConfig.type .. '.png'
            }
            
            if updatedData and updatedData.owner_name then
                data.isOwned = true
                data.isOwner = (updatedData.owner == PlayerData.citizenid)
                data.ownerName = updatedData.owner_name
            end
            
            SendNUIMessage({
                action = 'updateHouse',
                houseData = data
            })
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('buyHouse', function(data, cb)
    CloseHousingNUI()
    
    local paymentType = data.paymentType or 'bank'
    
    -- Xác nhận mua nhà
    local alert = lib.alertDialog({
        header = 'Xác nhận mua nhà',
        content = 'Bạn có chắc muốn mua ngôi nhà này bằng ' .. (paymentType == 'cash' and 'tiền mặt' or 'chuyển khoản') .. '?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        lib.callback('qbx_housing:server:buyHouse', false, function(success, message)
            if success then
                lib.notify({
                    title = 'Mua nhà',
                    description = message,
                    type = 'success',
                    duration = 5000
                })
                
                Wait(500)
                lib.notify({
                    title = 'Garage',
                    description = 'Garage đã sẵn sàng! Bạn có thể vào nhà và sử dụng garage ngay.',
                    type = 'info',
                    duration = 5000
                })
            else
                lib.notify({
                    title = 'Mua nhà',
                    description = message,
                    type = 'error',
                    duration = 5000
                })
            end
        end, data.houseId, paymentType)
    end
    
    cb({ success = true })
end)

RegisterNUICallback('previewHouse', function(data, cb)
    lib.notify({
        title = 'Xem thử',
        description = 'Đang đưa bạn vào nhà để xem...',
        type = 'info'
    })
    
    -- Teleport vào nhà để xem
    local houseConfig = GetHouseConfigClient(data.houseId)
    if houseConfig then
        DoScreenFadeOut(500)
        Wait(500)
        
        SetEntityCoords(PlayerPedId(), houseConfig.interior.x, houseConfig.interior.y, houseConfig.interior.z)
        
        Wait(500)
        DoScreenFadeIn(500)
        
        -- Tạo exit point tạm thời cho preview
        CreateNUIPreviewExitPoint(data.houseId)
        
        -- Tạo timer để tự động đưa ra ngoài sau 60 giây
        SetTimeout(60000, function()
            RemoveNUIPreviewExitPoint(data.houseId)
            
            lib.notify({
                title = 'Xem thử',
                description = 'Hết thời gian xem thử, đang đưa bạn ra ngoài...',
                type = 'info'
            })
            
            DoScreenFadeOut(500)
            Wait(500)
            
            SetEntityCoords(PlayerPedId(), houseConfig.door.x, houseConfig.door.y, houseConfig.door.z)
            
            Wait(500)
            DoScreenFadeIn(500)
        end)
    end
    
    cb({ success = true })
end)

RegisterNUICallback('closeUI', function(data, cb)
    CloseHousingNUI()
    cb({ success = true })
end)

-- Enter house callback (for owner)
RegisterNUICallback('enterHouse', function(data, cb)
    CloseHousingNUI()
    EnterHouse(data.houseId)
    cb({ success = true })
end)

-- Open garage callback
RegisterNUICallback('openGarage', function(data, cb)
    CloseHousingNUI()
    cb({ success = true })
    
    CreateThread(function()
        Wait(50)
        OpenGarage(data.houseId)
    end)
end)

-- Manage house callback
RegisterNUICallback('manageHouse', function(data, cb)
    CloseHousingNUI()
    OpenHouseManagement(data.houseId)
    cb({ success = true })
end)

-- Open mailbox callback (for owner)
RegisterNUICallback('openMailbox', function(data, cb)
    CloseHousingNUI()
    TriggerEvent('xn_buucuc:openbuucuc')
    cb({ success = true })
end)

-- Open gang menu callback (for gang members/bosses)
RegisterNUICallback('openGangMenu', function(data, cb)
    CloseHousingNUI()
    cb({ success = true })
    
    CreateThread(function()
        Wait(100)
        TriggerEvent('xn_gangmenu:client:OpenMenu')
    end)
end)

-- Callback: Trom Nha Gang (Tich hop voi xn_ganghouserob)
RegisterNUICallback('robGangHouse', function(data, cb)
    CloseHousingNUI()
    if data and data.houseId then
        TriggerServerEvent('xn_ganghouserob:server:startRobbery', data.houseId)
    end
    cb({ success = true })
end)

-- Preview Exit Point Management
local previewZones = {}

function CreateNUIPreviewExitPoint(houseId)
    local houseConfig = GetHouseConfigClient(houseId)
    if not houseConfig then return end
    
    if Config.UseTarget then
        local zoneName = 'preview_exit_' .. houseId
        previewZones[houseId] = zoneName
        
        exports.ox_target:addSphereZone({
            name = zoneName,
            coords = houseConfig.interior,
            radius = 1.5,
            debug = Config.DebugPoly,
            options = {
                {
                    name = 'preview_exit_action_' .. houseId,
                    icon = 'fa-solid fa-door-open',
                    label = 'Thoát khỏi preview',
                    onSelect = function()
                        RemoveNUIPreviewExitPoint(houseId)
                        
                        DoScreenFadeOut(500)
                        Wait(500)
                        
                        SetEntityCoords(PlayerPedId(), houseConfig.door.x, houseConfig.door.y, houseConfig.door.z)
                        
                        Wait(500)
                        DoScreenFadeIn(500)
                    end
                }
            }
        })
    end
end

function RemoveNUIPreviewExitPoint(houseId)
    local zoneName = previewZones[houseId]
    if zoneName and Config.UseTarget then
        exports.ox_target:removeZone(zoneName)
        previewZones[houseId] = nil
    end
end

-- ========== REALESTATE NUI CALLBACKS ==========

-- Transfer house (realestate)
RegisterNUICallback('transferHouse', function(data, cb)
    CloseHousingNUI()
    
    -- Get nearby players
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({
                title = 'Chuyển Nhượng',
                description = 'Không có người chơi nào gần đây',
                type = 'error'
            })
            cb({ success = false, message = 'Không có người chơi gần đây' })
            return
        end
        
        -- Create options list for lib.inputDialog
        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                value = player.id,
                label = player.name .. ' (PID: ' .. (player.pid or 'N/A') .. ') - ' .. player.distance .. 'm'
            })
        end
        
        -- Show player selection dialog
        local input = lib.inputDialog('Chuyển Nhượng Nhà', {
            {
                type = 'select',
                label = 'Chọn người mua',
                description = 'Người chơi gần nhất',
                options = options,
                required = true
            }
        })
        
        if not input then
            cb({ success = false })
            return
        end
        
        local targetId = tonumber(input[1])
        
        -- Confirm transfer
        local alert = lib.alertDialog({
            header = 'Xác nhận chuyển nhượng',
            content = 'Bạn có chắc muốn chuyển nhượng nhà này? Bạn sẽ nhận 10% hoa hồng.',
            centered = true,
            cancel = true
        })
        
        if alert == 'confirm' then
            lib.callback('qbx_housing:server:transferHouse', false, function(success, message)
                lib.notify({
                    title = 'Chuyển Nhượng',
                    description = message,
                    type = success and 'success' or 'error'
                })
            end, data.houseId, targetId)
        end
    end, nil, 5.0)
    
    cb({ success = true })
end)

-- Invite to house (realestate)
RegisterNUICallback('inviteToHouse', function(data, cb)
    CloseHousingNUI()
    
    -- Get nearby players
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({
                title = 'Mời Thăm Quan',
                description = 'Không có người chơi nào gần đây',
                type = 'error'
            })
            cb({ success = false, message = 'Không có người chơi gần đây' })
            return
        end
        
        -- Create options list
        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            table.insert(options, {
                value = player.id,
                label = player.name .. ' (PID: ' .. (player.pid or 'N/A') .. ') - ' .. player.distance .. 'm'
            })
        end
        
        -- Show player selection dialog
        local input = lib.inputDialog('Mời Thăm Quan', {
            {
                type = 'select',
                label = 'Chọn người mời',
                description = 'Người chơi gần nhất',
                options = options,
                required = true
            }
        })
        
        if not input then
            cb({ success = false })
            return
        end
        
        local targetId = tonumber(input[1])
        
        lib.callback('qbx_housing:server:inviteToHouse', false, function(success, message)
            lib.notify({
                title = 'Mời Thăm Quan',
                description = message,
                type = success and 'success' or 'error'
            })
        end, data.houseId, targetId)
    end, nil, 5.0)
    
    cb({ success = true })
end)

-- Export
exports('OpenHousingNUI', OpenHousingNUI)
exports('CloseHousingNUI', CloseHousingNUI)

-- ================= HOUSE MANAGEMENT NUI CALLBACKS =================

RegisterNUICallback('closeManagementUI', function(data, cb)
    SetNuiFocus(false, false)
    cb({ success = true })
end)

RegisterNUICallback('manageGiveKey', function(data, cb)
    lib.callback('qbx_housing:server:giveKeys', false, function(success, message)
        if success then
            lib.callback('qbx_housing:server:getSharedKeys', false, function(sharedKeys)
                cb({ success = true, message = message, sharedKeys = sharedKeys })
            end, data.houseId)
        else
            cb({ success = false, message = message })
        end
    end, data.houseId, data.targetId)
end)

RegisterNUICallback('manageRemoveKey', function(data, cb)
    lib.callback('qbx_housing:server:removeKeys', false, function(success, message)
        cb({ success = success, message = message })
    end, data.houseId, data.citizenid)
end)

RegisterNUICallback('manageInvitePlayer', function(data, cb)
    lib.callback('qbx_housing:server:inviteToHouseOwner', false, function(success, message)
        cb({ success = success, message = message })
    end, data.houseId, data.targetId)
end)

RegisterNUICallback('managePurchaseJuicer', function(data, cb)
    lib.callback('qbx_housing:server:purchaseJuicer', false, function(success, message, remainingCoins)
        cb({ success = success, message = message, playerCoin = remainingCoins })
    end, data.houseId)
end)

RegisterNUICallback('manageSellHouse', function(data, cb)
    lib.callback('qbx_housing:server:sellHouseToPlayer', false, function(success, message)
        cb({ success = success, message = message })
    end, data.houseId, data.buyerId, data.price)
end)

RegisterNUICallback('manageGetNearbyPlayers', function(data, cb)
    local houseConfig = GetHouseConfigClient(data.houseId)
    local doorCoords = houseConfig and houseConfig.door or GetEntityCoords(PlayerPedId())
    lib.callback('qbx_housing:server:getNearbyPlayers', false, function(nearbyPlayers)
        cb({ nearbyPlayers = nearbyPlayers or {} })
    end, doorCoords, 10.0)
end)


RegisterNUICallback('manageUpgradeGangHouse', function(data, cb)
    local houseId = data and data.houseId
    if not houseId then
        cb({ success = false, message = 'Thiếu mã nhà!' })
        return
    end
    
    lib.callback('qbx_housing:server:upgradeGangHouse', false, function(success, message, newLevel)
        if success then
            lib.notify({
                title = 'Nâng Cấp Trụ Sở',
                description = message or 'Nâng cấp thành công!',
                type = 'success'
            })
            -- Refresh lại management data
            lib.callback('qbx_housing:server:getManagementData', false, function(mData)
                if mData then
                    SendNUIMessage({
                        action = 'showManagementUI',
                        managementData = mData,
                        data = { managementData = mData }
                    })
                end
            end, houseId)
        else
            lib.notify({
                title = 'Nâng Cấp Trụ Sở',
                description = message or 'Nâng cấp thất bại!',
                type = 'error'
            })
        end
        cb({ success = success, message = message, newLevel = newLevel })
    end, houseId)
end)

-- Callbacks: Trom Nha Gang Party Actions
RegisterNUICallback('joinRobberyParty', function(data, cb)
    CloseHousingNUI()
    if data and data.robberyId then
        TriggerServerEvent('xn_ganghouserob:server:joinParty', data.robberyId)
    end
    cb({ success = true })
end)

RegisterNUICallback('leaveRobberyParty', function(data, cb)
    CloseHousingNUI()
    if data and data.robberyId then
        TriggerServerEvent('xn_ganghouserob:server:leaveParty', data.robberyId)
    end
    cb({ success = true })
end)

RegisterNUICallback('cancelRobbery', function(data, cb)
    CloseHousingNUI()
    if data and data.robberyId then
        TriggerServerEvent('xn_ganghouserob:server:cancelRobbery', data.robberyId)
    end
    cb({ success = true })
end)

RegisterNUICallback('readyRobbery', function(data, cb)
    CloseHousingNUI()
    if data and data.robberyId then
        TriggerServerEvent('xn_ganghouserob:server:readyRobbery', data.robberyId)
    end
    cb({ success = true })
end)
