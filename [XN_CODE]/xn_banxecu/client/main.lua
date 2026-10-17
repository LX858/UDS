local QBX = exports.qbx_core
local saleZone = nil
local listedVehicles = {} -- {[plate] = {vehicle, price, owner, targetId, drawThread}}
local unlistingVehicles = {} -- {[plate] = true} Track xe đang được hủy bán để tránh State Bag re-trigger
local playerVehicle = nil
local isInZone = false
local DEBUG = Config.Debug -- Bật/tắt debug logs

-- Helper: Lấy biển số xe
local function GetPlate(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    return plate:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
end

-- Helper: Scan tất cả xe có State Bag listedVehicle (cho người chơi join sau)
local function ScanListedVehicles()
    if DEBUG then print('^3[DEBUG] Scanning for listed vehicles...') end
    
    local coords = GetEntityCoords(cache.ped)
    local vehicles = lib.getNearbyVehicles(coords, 200.0, true) -- Scan trong bán kính 200m
    
    for _, veh in pairs(vehicles) do
        local vehicle = veh.vehicle
        if DoesEntityExist(vehicle) then
            local plate = GetPlate(vehicle)
            
            -- Kiểm tra xe đã có trong danh sách chưa
            if not listedVehicles[plate] then
                -- Kiểm tra State Bag của xe
                local stateBag = Entity(vehicle).state.listedVehicle
                
                if stateBag then
                    if DEBUG then print('^2[DEBUG] Found listed vehicle:', plate) end
                    
                    -- Setup xe giống như State Bag Handler
                    SetVehicleEngineOn(vehicle, false, true, true)
                    SetVehicleDoorsLocked(vehicle, 2)
                    FreezeEntityPosition(vehicle, true)
                    
                    -- Lưu vào danh sách local
                    listedVehicles[plate] = {
                        vehicle = vehicle,
                        price = stateBag.price,
                        owner = stateBag.owner,
                        model = stateBag.model
                    }
                    
                    CreateListedVehicleTarget(vehicle, plate)
                end
            end
        end
    end
    
    if DEBUG then print('^2[DEBUG] Scan complete. Found', #listedVehicles, 'listed vehicles') end
end

-- State Bag Handler: Lắng nghe xe được list
AddStateBagChangeHandler('listedVehicle', nil, function(bagName, key, value)
    if value then
        -- Kiểm tra bagName có phải entity bag không
        if not bagName:find('entity:') then return end
        
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
        if not netId then return end
        
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        
        if not DoesEntityExist(vehicle) then return end
        
        local plate = GetPlate(vehicle)
        
        -- QUAN TRỌNG: Bỏ qua nếu xe đang trong quá trình unlist
        if unlistingVehicles[plate] then
            if DEBUG then print('^3[DEBUG] Ignoring State Bag for unlisting vehicle:', plate) end
            return
        end
        
        -- Bỏ qua nếu xe đã có trong danh sách local (tránh re-process)
        if listedVehicles[plate] then
            if DEBUG then print('^3[DEBUG] Vehicle already in local list:', plate) end
            return
        end
        
        local parkingSpot = value.parkingSpot
        
        -- Nếu không phải owner, teleport xe về parking spot
        if value.owner ~= cache.serverId and parkingSpot then
            Wait(100)
            NetworkRequestControlOfEntity(vehicle)
            Wait(100)
            
            SetEntityCoords(vehicle, parkingSpot.x, parkingSpot.y, parkingSpot.z, false, false, false, false)
            SetEntityHeading(vehicle, parkingSpot.w)
        end
        
        -- Setup xe
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleDoorsLocked(vehicle, 2)
        FreezeEntityPosition(vehicle, true)
        
        -- Lưu vào danh sách local
        listedVehicles[plate] = {
            vehicle = vehicle,
            price = value.price,
            owner = value.owner,
            model = value.model
        }
        
        CreateListedVehicleTarget(vehicle, plate)
        -- KHÔNG tạo scaleform ngay - sẽ tạo khi player gần
    end
end)

-- State Bag Handler: Lắng nghe xe bị unlist
AddStateBagChangeHandler('listedVehicle', nil, function(bagName, key, value)
    if not value then
        -- Kiểm tra bagName có phải entity bag không
        if not bagName:find('entity:') then return end
        
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
        if not netId then return end
        
        local vehicle = NetworkGetEntityFromNetworkId(netId)
        
        if DoesEntityExist(vehicle) then
            local plate = GetPlate(vehicle)
            local data = listedVehicles[plate]
            
            if data then
                if DEBUG then print('^2[DEBUG] State Bag unlist received for:', plate) end
                
                -- Cleanup UI flag
                data.hasUI = nil
                
                NetworkRequestControlOfEntity(vehicle)
                FreezeEntityPosition(vehicle, false)
                SetVehicleDoorsLocked(vehicle, 1)
                exports.ox_target:removeLocalEntity(vehicle, {'sell_vehicle', 'unlist_vehicle'})
                
                listedVehicles[plate] = nil
            end
            
            -- Xóa khỏi unlisting list sau 5 giây (đảm bảo State Bag đã sync xong)
            if unlistingVehicles[plate] then
                SetTimeout(5000, function()
                    unlistingVehicles[plate] = nil
                    if DEBUG then print('^2[DEBUG] Removed from unlistingVehicles:', plate) end
                end)
            end
        end
    end
end)

-- Tạo zone bán xe
saleZone = lib.zones.poly({
    points = Config.SaleZonePoints,
    thickness = Config.ZoneThickness,
    debug = false, -- TẮT debug để giảm resmon
    onEnter = function()
        isInZone = true
        if DEBUG then print('ENTERED SALE ZONE') end
        
        -- Scan xe listed cho người chơi mới join
        ScanListedVehicles()
        
        -- Thêm targets cho tất cả xe trong zone
        local coords = GetEntityCoords(cache.ped)
        local vehicles = lib.getNearbyVehicles(coords, 50.0, true)
        
        for _, veh in pairs(vehicles) do
            local vehicle = veh.vehicle
            local plate = GetPlate(vehicle)
            
            if not listedVehicles[plate] then
                AddVehicleTarget(vehicle, plate)
            end
        end
    end,
    onExit = function()
        isInZone = false
        if DEBUG then print('EXITED SALE ZONE') end
    end
})

-- Thêm target cho xe
function AddVehicleTarget(vehicle, plate)
    if DEBUG then print('Adding target to vehicle:', vehicle, 'plate:', plate) end
    
    exports.ox_target:addLocalEntity(vehicle, {
        {
            name = 'list_vehicle_sale',
            icon = 'fa-solid fa-dollar-sign',
            label = 'Đăng bán xe',
            distance = 5.0,
            onSelect = function(data)
                if DEBUG then print('Target selected!') end
                OpenListVehicleDialog(data.entity)
            end
        }
    })
end

-- Mở dialog đăng bán xe
function OpenListVehicleDialog(vehicle)
    local plate = GetPlate(vehicle)
    
    -- Lấy thông tin xe từ server
    lib.callback('xn_banxecu:getVehicleInfo', false, function(data)
        if not data then
            lib.notify({
                title = 'Lỗi',
                description = 'Không thể lấy thông tin xe',
                type = 'error'
            })
            return
        end
        
        -- Kiểm tra xe có trong blacklist không
        local isBlacklisted = Config.IsVehicleBlacklisted(data.vehicleName)
        if isBlacklisted then
            if not Config.VIPItem or not Config.VIPItem.enabled then
                lib.notify({
                    title = 'Lỗi',
                    description = 'Xe này không được phép bán',
                    type = 'error'
                })
                return
            end

            local vipCount = exports.ox_inventory:GetItemCount(Config.VIPItem.item) or 0
            if vipCount < Config.VIPItem.count then
                lib.notify({
                    title = 'Lỗi',
                    description = string.format('Xe này thuộc danh sách đặc biệt! Bạn cần có %dx %s để bán.', Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
                    type = 'error'
                })
                return
            end
        end
        
        local minPrice = isBlacklisted and ((Config.VIPItem and Config.VIPItem.minPrice) or 1000000) or math.floor(data.dealerPrice * Config.PricePercentage)
        local tax = Config.TransactionTax * 100
        
        local dialogRows = {
            {
                type = 'input',
                label = 'Tên xe',
                default = data.vehicleName,
                disabled = true
            },
            {
                type = 'input',
                label = 'Biển số',
                default = plate,
                disabled = true
            }
        }

        if isBlacklisted then
            table.insert(dialogRows, {
                type = 'input',
                label = 'Yêu cầu xe VIP',
                default = string.format('Tiêu hao %dx %s khi bán', Config.VIPItem.count, Config.VIPItem.label),
                disabled = true,
                icon = 'ticket'
            })
        end

        local priceIndex = #dialogRows + 1
        table.insert(dialogRows, {
            type = 'number',
            label = 'Giá bán',
            description = string.format('Lưu ý: Giá tối thiểu $%s - Thuế giao dịch %.0f%%%s', lib.math.groupdigits(minPrice), tax, isBlacklisted and (' - Mất 1x ' .. Config.VIPItem.label) or ''),
            required = true,
            min = minPrice,
            icon = 'dollar-sign'
        })

        local input = lib.inputDialog('Đăng bán xe', dialogRows)
        
        if not input then return end
        
        local price = tonumber(input[priceIndex])
        if not price or price < minPrice then
            lib.notify({
                title = 'Lỗi',
                description = string.format('Giá bán tối thiểu là $%s', lib.math.groupdigits(minPrice)),
                type = 'error'
            })
            return
        end
        
        -- Tìm vị trí đỗ xe trống
        local parkingSpot = nil
        for _, spot in ipairs(Config.ParkingSpots) do
            local spotCoords = vec3(spot.x, spot.y, spot.z)
            local nearbyVehicles = lib.getNearbyVehicles(spotCoords, Config.ParkingCheckRadius, true)
            
            -- Kiểm tra vị trí có xe không
            local isOccupied = false
            for _, v in pairs(nearbyVehicles) do
                if v.vehicle ~= vehicle then
                    isOccupied = true
                    break
                end
            end
            
            if not isOccupied then
                parkingSpot = spot
                break
            end
        end
        
        if not parkingSpot then
            lib.notify({
                title = 'Lỗi',
                description = 'Tất cả vị trí đỗ xe đều đã đầy, vui lòng quay lại sau',
                type = 'error'
            })
            return
        end
        
        -- Đăng bán xe
        lib.callback('xn_banxecu:listVehicle', false, function(success)
            if success then
                -- Request network control để freeze hoạt động với tất cả clients
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                SetNetworkIdExistsOnAllMachines(netId, true)
                SetNetworkIdCanMigrate(netId, false)
                NetworkRequestControlOfEntity(vehicle)
                
                Wait(100) -- Đợi network control
                
                -- Fade out
                DoScreenFadeOut(500)
                Wait(500)
                
                -- Teleport xe đến vị trí đỗ
                SetEntityCoords(vehicle, parkingSpot.x, parkingSpot.y, parkingSpot.z, false, false, false, false)
                SetEntityHeading(vehicle, parkingSpot.w)
                
                -- Tắt máy xe và khóa cửa
                SetVehicleEngineOn(vehicle, false, true, true)
                SetVehicleDoorsLocked(vehicle, 2)
                
                -- Freeze xe
                FreezeEntityPosition(vehicle, true)
                
                -- Teleport người chơi ra ngoài xe (bên cạnh cửa lái)
                local offsetX = GetEntityForwardX(vehicle) * -2.0
                local offsetY = GetEntityForwardY(vehicle) * -2.0
                local playerPos = vec3(parkingSpot.x + offsetX, parkingSpot.y + offsetY, parkingSpot.z)
                SetEntityCoords(cache.ped, playerPos.x, playerPos.y, playerPos.z, false, false, false, false)
                
                -- Fade in
                Wait(500)
                DoScreenFadeIn(500)
                
                -- Thêm vào danh sách xe đang bán
                listedVehicles[plate] = {
                    vehicle = vehicle,
                    price = price,
                    owner = cache.serverId,
                    model = data.vehicleName
                }
                
                -- Set State Bag cho xe để tự động sync với clients khác
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                Entity(vehicle).state:set('listedVehicle', {
                    price = price,
                    owner = cache.serverId,
                    model = data.vehicleName,
                    parkingSpot = parkingSpot
                }, true) -- replicated = true
                
                -- Tạo target mới cho xe đang bán
                CreateListedVehicleTarget(vehicle, plate)
                
                -- KHÔNG tạo scaleform ngay - sẽ tạo khi player gần
                
                lib.notify({
                    title = 'Thành công',
                    description = 'Đã đăng bán xe thành công',
                    type = 'success'
                })
            else
                lib.notify({
                    title = 'Lỗi',
                    description = 'Không thể đăng bán xe',
                    type = 'error'
                })
            end
        end, plate, price, parkingSpot)
        
    end, plate)
end

-- Tạo target cho xe đang được treo bán
function CreateListedVehicleTarget(vehicle, plate)
    exports.ox_target:addLocalEntity(vehicle, {
        {
            name = 'sell_vehicle',
            icon = 'fa-solid fa-handshake',
            label = 'Bán xe',
            canInteract = function()
                local data = listedVehicles[plate]
                return data and data.owner == cache.serverId
            end,
            onSelect = function()
                OpenSellVehicleDialog(plate)
            end
        },
        {
            name = 'unlist_vehicle',
            icon = 'fa-solid fa-times',
            label = 'Gỡ đăng bán',
            canInteract = function()
                local data = listedVehicles[plate]
                return data and data.owner == cache.serverId
            end,
            onSelect = function()
                UnlistVehicle(plate)
            end
        }
    })
end

-- Mở dialog bán xe cho người chơi khác
function OpenSellVehicleDialog(plate)
    local data = listedVehicles[plate]
    if not data then return end
    
    -- Lấy danh sách người chơi gần vị trí của bạn
    local playerCoords = GetEntityCoords(cache.ped)
    local nearbyPlayers = lib.getNearbyPlayers(playerCoords, Config.NearbyRadius, true)
    
    if #nearbyPlayers == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Không có người chơi nào gần đây',
            type = 'error'
        })
        return
    end
    
    local playerOptions = {}
    local validPlayerCount = 0
    
    -- Đếm số player hợp lệ (không phải mình)
    for _, player in ipairs(nearbyPlayers) do
        local targetServerId = GetPlayerServerId(player.id)
        if targetServerId ~= cache.serverId then
            validPlayerCount = validPlayerCount + 1
        end
    end
    
    if validPlayerCount == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Không có người chơi nào gần đây',
            type = 'error'
        })
        return
    end
    
    -- Lấy thông tin player ĐỒNG BỘ (dùng lib.callback.await)
    for _, player in ipairs(nearbyPlayers) do
        local targetServerId = GetPlayerServerId(player.id)
        if targetServerId ~= cache.serverId then
            -- Dùng await để đảm bảo data được load đầy đủ
            local playerData = lib.callback.await('xn_banxecu:getPlayerName', false, targetServerId)
            if playerData then
                table.insert(playerOptions, {
                    value = targetServerId,
                    label = string.format('[%s] %s', playerData.citizenid, playerData.name)
                })
            end
        end
    end
    
    if #playerOptions == 0 then
        lib.notify({
            title = 'Lỗi',
            description = 'Không thể lấy thông tin người chơi',
            type = 'error'
        })
        return
    end
    
    local isBlacklisted = Config.IsVehicleBlacklisted(data.model)
    if isBlacklisted and Config.VIPItem and Config.VIPItem.enabled then
        local vipCount = exports.ox_inventory:GetItemCount(Config.VIPItem.item) or 0
        if vipCount < Config.VIPItem.count then
            lib.notify({
                title = 'Lỗi',
                description = string.format('Bạn cần có %dx %s trong balo để bán xe VIP này!', Config.VIPItem.count, Config.VIPItem.label or Config.VIPItem.item),
                type = 'error'
            })
            return
        end
    end

    local tax = math.floor(data.price * Config.TransactionTax)
    local sellerReceive = data.price - tax
    
    local dialogRows = {
        {
            type = 'input',
            label = 'Tên xe',
            default = data.model,
            disabled = true
        },
        {
            type = 'input',
            label = 'Biển số',
            default = plate,
            disabled = true
        },
        {
            type = 'input',
            label = 'Giá bán',
            default = '$' .. lib.math.groupdigits(data.price),
            disabled = true
        },
        {
            type = 'input',
            label = 'Thuế giao dịch',
            default = string.format('%.0f%% ($%s)', Config.TransactionTax * 100, lib.math.groupdigits(tax)),
            disabled = true
        },
        {
            type = 'input',
            label = 'Bạn nhận được',
            default = '$' .. lib.math.groupdigits(sellerReceive),
            disabled = true,
            icon = 'money-bill-wave'
        }
    }

    if isBlacklisted and Config.VIPItem and Config.VIPItem.enabled then
        table.insert(dialogRows, {
            type = 'input',
            label = 'Vé VIP tiêu hao',
            default = string.format('Mất %dx %s khi hoàn tất', Config.VIPItem.count, Config.VIPItem.label),
            disabled = true,
            icon = 'ticket'
        })
    end

    local buyerSelectIndex = #dialogRows + 1
    table.insert(dialogRows, {
        type = 'select',
        label = 'Chọn người mua',
        options = playerOptions,
        required = true
    })

    local input = lib.inputDialog('Bán xe', dialogRows)
    
    if not input then return end
    
    local buyerId = tonumber(input[buyerSelectIndex])
    if not buyerId then return end
    
    -- Gửi yêu cầu bán xe đến server
    TriggerServerEvent('xn_banxecu:sellVehicle', plate, buyerId, data.price)
end

-- Gỡ đăng bán xe
function UnlistVehicle(plate)
    local data = listedVehicles[plate]
    if not data then return end
    
    local alert = lib.alertDialog({
        header = 'Gỡ đăng bán',
        content = 'Bạn có chắc muốn gỡ đăng bán xe này?',
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        -- QUAN TRỌNG: Đánh dấu xe đang được unlist TRƯỚC KHI gọi callback
        unlistingVehicles[plate] = true
        if DEBUG then print('^3[DEBUG] Marking vehicle as unlisting:', plate) end
        
        lib.callback('xn_banxecu:unlistVehicle', false, function(success)
            if success then
                local vehicle = data.vehicle
                
                -- Xóa khỏi danh sách local NGAY LẬP TỨC
                listedVehicles[plate] = nil
                
                -- Request network control
                NetworkRequestControlOfEntity(vehicle)
                Wait(100)
                
                -- Unfreeze xe và mở khóa TRƯỚC KHI xóa State Bag
                FreezeEntityPosition(vehicle, false)
                SetVehicleDoorsLocked(vehicle, 1)
                
                -- Xóa target
                exports.ox_target:removeLocalEntity(vehicle, {'sell_vehicle', 'unlist_vehicle', 'list_vehicle_sale'})
                
                -- Xóa State Bag SAU CÙNG
                Entity(vehicle).state:set('listedVehicle', nil, true)
                
                lib.notify({
                    title = 'Thành công',
                    description = 'Đã gỡ đăng bán xe',
                    type = 'success'
                })
                
                if DEBUG then print('^2[DEBUG] Vehicle unlisted successfully:', plate) end
            else
                -- Nếu thất bại, xóa flag
                unlistingVehicles[plate] = nil
            end
        end, plate)
    end
end

-- Hiển thị UI cho xe
function StartDrawText3D(vehicle, plate)
    if not listedVehicles[plate] then return end
    
    -- Đánh dấu đã kích hoạt UI
    if listedVehicles[plate].hasUI then 
        if DEBUG then print('^3[DEBUG] Plate ' .. plate .. ' đã có UI') end
        return 
    end
    
    listedVehicles[plate].hasUI = true
    if DEBUG then print('^2[DEBUG] UI enabled for plate: ' .. plate) end
end

function StopDrawText3D(plate)
    if listedVehicles[plate] and listedVehicles[plate].hasUI then
        if DEBUG then print('^1[DEBUG] Cleanup UI for plate: ' .. plate) end
        listedVehicles[plate].hasUI = nil
    end
end

-- Thread: Hiển thị NUI cho xe gần nhất
CreateThread(function()
    local currentVehicle = nil
    
    while true do
        -- Kiểm tra có xe nào listed không
        local hasAnyVehicle = next(listedVehicles) ~= nil
        
        -- Nếu KHÔNG có xe nào, sleep và ẩn NUI
        if not hasAnyVehicle then
            if currentVehicle then
                SendNUIMessage({
                    action = 'hideVehicleInfo'
                })
                currentVehicle = nil
            end
            Wait(1000)
            goto continue
        end
        
        local playerCoords = GetEntityCoords(cache.ped)
        local closestVehicle = nil
        local closestDistance = 999999
        
        -- Tìm xe gần nhất (KHÔNG cần kiểm tra hasUI)
        for plate, data in pairs(listedVehicles) do
            if DoesEntityExist(data.vehicle) then
                local vehicleCoords = GetEntityCoords(data.vehicle)
                local distance = #(playerCoords - vehicleCoords)
                
                -- CHỈ hiển thị khi: player gần (≤4m) VÀ xe trên màn hình
                if distance <= 4.0 and IsEntityOnScreen(data.vehicle) and distance < closestDistance then
                    closestDistance = distance
                    closestVehicle = plate
                end
            end
        end
        
        -- Cập nhật NUI nếu xe thay đổi HOẶC xe hiện tại không còn trong danh sách
        if closestVehicle ~= currentVehicle then
            -- Ẩn NUI cũ trước
            if currentVehicle and not listedVehicles[currentVehicle] then
                SendNUIMessage({
                    action = 'hideVehicleInfo'
                })
                currentVehicle = nil
            end
            
            if closestVehicle then
                local data = listedVehicles[closestVehicle]
                
                -- Lấy thông số handling từ GTA V
                local fMaxFlatVel = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
                local fDriveForce = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fInitialDriveForce')
                local fBrakeForce = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fBrakeForce')
                local fTractionCurveMax = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fTractionCurveMax')
                local fTractionCurveMin = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fTractionCurveMin')
                local fTractionCurveLateral = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fTractionCurveLateral')
                local fTractionLossMult = GetVehicleHandlingFloat(data.vehicle, 'CHandlingData', 'fTractionLossMult')
                
                -- TỐC ĐỘ TỐI ĐA (km/h) - Công thức chính xác
                -- TopSpeed (km/h) ≈ fInitialDriveMaxFlatVel × 1.5
                local topSpeedKmh = math.floor(fMaxFlatVel * 1.1)
                local speedRating = math.floor(math.min(100, (topSpeedKmh / 350) * 100))
                
                -- GIA TỐC: Tính thời gian 0-100 km/h (giây)
                -- AccelTime (s) ≈ 1.2 / fDriveForce
                -- fDriveForce cao = tăng tốc nhanh = thời gian ngắn
                local accelTime = 1.2 / fDriveForce
                local accelRating = math.floor(math.max(0, math.min(100, 100 - ((accelTime / 10) * 100))))
                
                -- PHANH: fBrakeForce thường từ 0.5 - 3.0
                local brakeRating = math.floor(math.min(100, (fBrakeForce / 2.5) * 100))
                
                -- ĐỘ BÁM ĐƯỜNG: Đơn giản hóa - chỉ dùng fTractionCurveMax
                -- fTractionCurveMax: 1.0 (kém) -> 3.5 (xuất sắc)
                -- Rating: số càng cao = bám đường càng tốt
                local gripRating = math.floor(math.min(100, (fTractionCurveMax / 3.5) * 100))
                
                -- Lấy thông tin owner từ server
                lib.callback('xn_banxecu:getOwnerInfo', false, function(ownerInfo)
                    -- Gửi dữ liệu đến NUI
                    SendNUIMessage({
                        action = 'showVehicleInfo',
                        vehicle = {
                            model = data.model,
                            plate = closestVehicle,
                            price = data.price,
                            owner = ownerInfo or {},
                            stats = {
                                speed = speedRating,
                                speedKmh = topSpeedKmh,
                                acceleration = accelRating,
                                accelTime = string.format("%.1fs", accelTime),
                                braking = brakeRating,
                                handling = gripRating
                            }
                        }
                    })
                    
                    if DEBUG then print('^2[DEBUG] Showing NUI for plate: ' .. closestVehicle) end
                end, closestVehicle)
            else
                -- Ẩn NUI nếu không có xe nào gần
                SendNUIMessage({
                    action = 'hideVehicleInfo'
                })
            end
            
            currentVehicle = closestVehicle
        end
        
        Wait(500) -- Cập nhật mỗi 0.5 giây
        
        ::continue::
    end
end)
-- Nhận thông báo khi có người muốn mua xe
RegisterNetEvent('xn_banxecu:receiveBuyRequest', function(sellerName, vehicleName, plate, price)
    local tax = math.floor(price * Config.TransactionTax)
    local totalPrice = price
    
    local input = lib.inputDialog('Xác nhận mua xe', {
        {
            type = 'input',
            label = 'Người bán',
            default = sellerName,
            disabled = true
        },
        {
            type = 'input',
            label = 'Tên xe',
            default = vehicleName,
            disabled = true
        },
        {
            type = 'input',
            label = 'Biển số',
            default = plate,
            disabled = true
        },
        {
            type = 'input',
            label = 'Giá mua',
            default = '$' .. lib.math.groupdigits(totalPrice),
            disabled = true,
            icon = 'money-bill-wave'
        }
    })
    
    if input then
        TriggerServerEvent('xn_banxecu:confirmBuy', plate)
    else
        TriggerServerEvent('xn_banxecu:cancelBuy', plate)
    end
end)

-- Nhận thông báo khi giao dịch thành công
RegisterNetEvent('xn_banxecu:transactionComplete', function(plate, isSeller)
    local data = listedVehicles[plate]
    
    -- Ẩn NUI ngay lập tức nếu đang hiển thị xe này
    SendNUIMessage({
        action = 'hideVehicleInfo'
    })
    
    -- QUAN TRỌNG: Đánh dấu xe đang được unlist để tránh State Bag re-trigger
    unlistingVehicles[plate] = true
    if DEBUG then print('^3[DEBUG] Transaction complete - marking as unlisting:', plate) end
    
    if isSeller and data then
        local vehicle = data.vehicle
        
        -- Xóa khỏi danh sách local NGAY LẬP TỨC
        listedVehicles[plate] = nil
        
        -- Request network control
        NetworkRequestControlOfEntity(vehicle)
        Wait(100)
        
        -- Unfreeze xe và mở khóa TRƯỚC
        FreezeEntityPosition(vehicle, false)
        SetVehicleDoorsLocked(vehicle, 1)
        
        -- Xóa target
        exports.ox_target:removeLocalEntity(vehicle, {'sell_vehicle', 'unlist_vehicle', 'list_vehicle_sale'})
        
        -- Xóa State Bag SAU CÙNG
        Entity(vehicle).state:set('listedVehicle', nil, true)
        
        if DEBUG then print('^2[DEBUG] Seller - vehicle sold and unlisted:', plate) end
    elseif data then
        -- Người mua: Xóa xe khỏi danh sách
        local vehicle = data.vehicle
        listedVehicles[plate] = nil
        
        -- Đợi State Bag sync
        Wait(500)
        
        -- Nếu đang trong zone, add target để có thể bán lại
        if isInZone and DoesEntityExist(vehicle) then
            exports.ox_target:removeLocalEntity(vehicle, {'sell_vehicle', 'unlist_vehicle'})
            AddVehicleTarget(vehicle, plate)
        end
        
        if DEBUG then print('^2[DEBUG] Buyer - vehicle purchased:', plate) end
    end
    
    lib.notify({
        title = 'Thành công',
        description = isSeller and 'Đã bán xe thành công' or 'Đã mua xe thành công',
        type = 'success'
    })
end)

-- Nhận thông báo khi giao dịch bị hủy
RegisterNetEvent('xn_banxecu:transactionCancelled', function()
    lib.notify({
        title = 'Thông báo',
        description = 'Giao dịch đã bị hủy',
        type = 'info'
    })
end)

-- Event: Khi resource start, đăng ký State Bag listener
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if DEBUG then print('^2[DEBUG] Resource started, waiting for player spawn...') end
end)

-- State Bag Handler: Lắng nghe khi player login (tối ưu hơn vòng lặp while)
AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(cache.serverId), function(bagName, key, value)
    if value then
        if DEBUG then print('^2[DEBUG] Player logged in, scanning for listed vehicles...') end
        
        -- Đợi 2 giây để entity network sync
        Wait(2000)
        ScanListedVehicles()
        
        -- Kiểm tra xem player có đang trong zone không (fix cho trường hợp spawn trong zone)
        Wait(500)
        if saleZone and saleZone:contains(GetEntityCoords(cache.ped)) then
            isInZone = true
            if DEBUG then print('^3[DEBUG] Player spawned inside sale zone - adding targets') end
            
            -- Thêm targets cho tất cả xe trong zone
            local coords = GetEntityCoords(cache.ped)
            local vehicles = lib.getNearbyVehicles(coords, 50.0, true)
            
            for _, veh in pairs(vehicles) do
                local vehicle = veh.vehicle
                local plate = GetPlate(vehicle)
                
                if not listedVehicles[plate] then
                    AddVehicleTarget(vehicle, plate)
                end
            end
        end
    end
end)
