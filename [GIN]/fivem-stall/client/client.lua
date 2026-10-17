local QBCore = exports['qb-core']:GetCoreObject()

-- Lấy inventory của player với TOÀN BỘ metadata và slot
-- Danh sách item_name đặc biệt (Clothes) - KHÔNG CẦN TRONG CLIENT VÌ CLIENT ĐÃ CÓ LABEL TỪ OX_INVENTORY

-- Lấy inventory của player với TOÀN BỘ metadata và slot
function GetPlayerInventory()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local inventory = {}
    
    print("^3[StallSystem] GetPlayerInventory called^7")
    print("^3[StallSystem] PlayerData items count: " .. (#(PlayerData.items or {}) or 0) .. "^7")
    
    if PlayerData.items then
        for _, item in pairs(PlayerData.items) do
            if not Config.BlacklistItems or not Config.BlacklistItems[item.name] then
                -- Client đã có label từ ox_inventory thông qua QBCore
                local itemLabel = item.label or item.name
                
                local itemInfo = {
                    name = item.name,
                    label = itemLabel,
                    count = item.count or 1,
                    slot = item.slot,
                    metadata = item.metadata or {},
                    imageurl = nil,
                    durability = nil,
                    DoHiem = '',
                    drawable = nil,
                    texture = nil,
                    type = nil,
                    sex = nil,
                    id = nil,
                    description = nil,
                    fullMetadata = {}
                }
                
                -- Copy TOÀN BỘ metadata
                if item.metadata then
                    for k, v in pairs(item.metadata) do
                        itemInfo.fullMetadata[k] = v
                        
                        if k == 'imageurl' then
                            itemInfo.imageurl = v
                        elseif k == 'durability' then
                            itemInfo.durability = v
                        elseif k == 'DoHiem' then
                            itemInfo.DoHiem = v
                        elseif k == 'label' then
                            -- Nếu có label trong metadata, ưu tiên dùng metadata label
                            itemInfo.label = v
                            itemInfo.fullMetadata.label = v
                        elseif k == 'drawable' then
                            itemInfo.drawable = v
                        elseif k == 'texture' then
                            itemInfo.texture = v
                        elseif k == 'type' then
                            itemInfo.type = v
                        elseif k == 'sex' then
                            itemInfo.sex = v
                        elseif k == 'id' then
                            itemInfo.id = v
                        elseif k == 'description' then
                            itemInfo.description = v
                        end
                    end
                end
                
                if not itemInfo.DoHiem or itemInfo.DoHiem == '' then
                    itemInfo.DoHiem = ''
                    itemInfo.fullMetadata.DoHiem = ''
                end
                
                if itemInfo.imageurl and not itemInfo.fullMetadata.imageurl then
                    itemInfo.fullMetadata.imageurl = itemInfo.imageurl
                end
                if itemInfo.durability and not itemInfo.fullMetadata.durability then
                    itemInfo.fullMetadata.durability = itemInfo.durability
                end
                if itemInfo.label and not itemInfo.fullMetadata.label then
                    itemInfo.fullMetadata.label = itemInfo.label
                end
                
                table.insert(inventory, itemInfo)
            end
        end
    end
    
    return inventory
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    print("^3[StallSystem] NUI: Buy item - " .. json.encode(data) .. "^7")
    TriggerServerEvent('stall:buyItem', data.stallId, data.itemIndex, data.quantity)
    cb('ok')
end)

RegisterNUICallback('rentStall', function(data, cb)
    print("^3[StallSystem] NUI: Rent stall - " .. json.encode(data) .. "^7")
    TriggerServerEvent('stall:rentStall', data.stallId, data.hours)
    cb('ok')
end)

RegisterNUICallback('renewStall', function(data, cb)
    print("^3[StallSystem] NUI: Renew stall - " .. json.encode(data) .. "^7")
    TriggerServerEvent('stall:renewStall', data.stallId, data.hours)
    cb('ok')
end)

RegisterNUICallback('addItem', function(data, cb)
    print("^3[StallSystem] NUI: Add item - " .. json.encode(data) .. "^7")
    print("^3[StallSystem] Slot received from client: " .. (data.slot or "N/A") .. "^7")
    TriggerServerEvent('stall:addItem', data.stallId, data.itemName, data.price, data.quantity, data.metadata, data.slot, data.itemLabel)
    cb('ok')
end)

RegisterNUICallback('removeItem', function(data, cb)
    print("^3[StallSystem] NUI: Remove item - " .. json.encode(data) .. "^7")
    TriggerServerEvent('stall:removeItem', data.stallId, data.itemIndex)
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    print("^3[StallSystem] NUI: Withdraw money - " .. json.encode(data) .. "^7")
    TriggerServerEvent('stall:withdrawMoney', data.stallId)
    cb('ok')
end)

RegisterNUICallback('getTransactionHistory', function(data, cb)
    QBCore.Functions.TriggerCallback('stall:getTransactionHistory', function(result)
        if result == nil then
            cb({})
        else
            cb(json.decode(json.encode(result)) or {})
        end
    end, data.stallId)
end)

RegisterNUICallback('getPlayerInventory', function(_, cb)
    local inventory = GetPlayerInventory()
    print("^3[StallSystem] getPlayerInventory returning " .. #inventory .. " items^7")
    if inventory == nil then
        cb({})
    else
        cb(json.decode(json.encode(inventory)) or {})
    end
end)

RegisterNUICallback('getStallItems', function(data, cb)
    QBCore.Functions.TriggerCallback('stall:getStallItems', function(result)
        if result == nil then
            cb({})
        else
            cb(json.decode(json.encode(result)) or {})
        end
    end, data.stallId)
end)

RegisterNUICallback('getStallData', function(data, cb)
    QBCore.Functions.TriggerCallback('stall:getStallData', function(result)
        if result == nil then
            cb(false)
        else
            cb(json.decode(json.encode(result)) or {})
        end
    end, data.stallId)
end)


-- Event handlers từ server
RegisterNetEvent('stall:refreshTargets', function()
    SendNUIMessage({
        action = 'refresh'
    })
end)

RegisterNetEvent('stall:closeUI', function()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
end)

RegisterNetEvent('QBCore:Notify', function(message, type)
    SendNUIMessage({
        action = 'notification',
        message = message,
        type = type or 'success'
    })
end)

-- ============================================
-- HÀM MỞ UI CHÍNH
-- ============================================

local PedList = nil

-- Lấy PedList từ target.lua
Citizen.CreateThread(function()
    while not PedList do
        PedList = _G.PedList or nil
        if not PedList then
            Wait(100)
        end
    end
    print("^2[StallSystem] PedList loaded in client.lua^7")
end)

function OpenStallUI(stallId)
    CreateThread(function()
        print("^3[StallSystem] OpenStallUI called for stall: " .. stallId .. "^7")
        
        -- Lấy thông tin stall từ PedList
        local stallConfig = nil
        if PedList then
            for _, v in ipairs(PedList) do
                if v.id == stallId then
                    stallConfig = {
                        id = v.id,
                        name = v.name or v.label,
                        rentPrice = v.rentPrice or 1000,
                        maxHours = v.maxHours or 24
                    }
                    break
                end
            end
        end
        
        if not stallConfig then
            print("^1[StallSystem] Stall config not found for ID: " .. stallId .. "^7")
            QBCore.Functions.Notify('Gian hàng không tồn tại!', 'error')
            return
        end
        
        -- Lấy dữ liệu stall từ server
        local stallData = nil
        local p = promise.new()
        
        QBCore.Functions.TriggerCallback('stall:getStallData', function(result)
            p:resolve(result)
        end, stallId)
        
        stallData = Citizen.Await(p)
        
        -- MỞ UI
        SetNuiFocus(true, true)
        
        if stallData then
            -- Đã có chủ
            local PlayerData = QBCore.Functions.GetPlayerData()
            local isOwner = (PlayerData.citizenid == stallData.citizenid)
            
            SendNUIMessage(json.decode(json.encode({
                action = 'openStall',
                stallData = stallData,
                isOwner = isOwner,
                stallConfig = stallConfig
            })))
        else
            -- CHƯA CÓ CHỦ -> MỞ UI THUÊ
            SendNUIMessage(json.decode(json.encode({
                action = 'openRent',
                stallId = stallId,
                stallConfig = stallConfig
            })))
        end
    end)
end

-- HÀM MỞ UI THUÊ
function OpenRentUI(stallId)
    CreateThread(function()
        print("^3[StallSystem] OpenRentUI called for stall: " .. stallId .. "^7")
        
        local stall = nil
        if PedList then
            for _, v in ipairs(PedList) do
                if v.id == stallId then
                    stall = v
                    break
                end
            end
        end
        
        if not stall then 
            print("^1[StallSystem] Stall not found in PedList: " .. stallId .. "^7")
            return 
        end
        
        -- Kiểm tra lại xem stall đã có chủ chưa
        local p = promise.new()
        QBCore.Functions.TriggerCallback('stall:getStallData', function(result)
            p:resolve(result)
        end, stallId)
        local stallData = Citizen.Await(p)
        
        if stallData then
            QBCore.Functions.Notify('Gian hàng này đã có người thuê!', 'error')
            return
        end
        
        SetNuiFocus(true, true)
        SendNUIMessage(json.decode(json.encode({
            action = 'openRent',
            stallId = stallId,
            stallConfig = {
                id = stall.id,
                name = stall.name or stall.label,
                rentPrice = stall.rentPrice or 1000,
                maxHours = stall.maxHours or 24
            }
        })))
    end)
end

-- Export hàm ra global
_G.OpenStallUI = OpenStallUI
_G.OpenRentUI = OpenRentUI

-- Luồng tạo Blip chỉ vị trí gian hàng trên bản đồ
CreateThread(function()
    if Config.Blip and Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        -- SetBlipColor(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)