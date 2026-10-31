local QBCore = exports["qb-core"]:GetCoreObject()
local farmRentalPed = nil
local currentCamera = nil
local isInCameraMode = false

-- Helper function để format timestamp thành date string 
local function formatTimestamp(timestamp)
    local days = {"CN", "T2", "T3", "T4", "T5", "T6", "T7"}
    local months = {"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"}
    
    local currentTime = GetCloudTimeAsInt()
    local diffSeconds = currentTime - timestamp
    local diffMinutes = math.floor(diffSeconds / 60)
    local diffHours = math.floor(diffMinutes / 60)
    local diffDays = math.floor(diffHours / 24)
    
    if diffDays == 0 then
        if diffHours == 0 then
            return diffMinutes .. " phút trước"
        else
            return diffHours .. " giờ trước"
        end
    elseif diffDays == 1 then
        return "Hôm qua"
    elseif diffDays < 7 then
        return diffDays .. " ngày trước"
    else
        return "Lâu rồi"
    end
end

-- Tạo ped cho thuê ruộng
local function CreateFarmRentalPed()
    if not FarmRental or not FarmRental.PedModel or not FarmRental.PedLocation then
        ----print("Error: FarmRental config not found!")
        return
    end
    
    local pedModel = FarmRental.PedModel
    local pedCoords = FarmRental.PedLocation
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(1)
    end
    
    farmRentalPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, true)
    FreezeEntityPosition(farmRentalPed, true)
    SetEntityInvincible(farmRentalPed, true)
    SetBlockingOfNonTemporaryEvents(farmRentalPed, true)
    
    -- Tạo blip cho ped thuê ruộng và cửa hàng
    local farmRentalBlip = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)
    SetBlipSprite(farmRentalBlip, 285) -- Icon số 285
    SetBlipDisplay(farmRentalBlip, 4)
    SetBlipScale(farmRentalBlip, 0.8)
    SetBlipAsShortRange(farmRentalBlip, true)
    SetBlipColour(farmRentalBlip, 1) -- Màu đỏ
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Nông Nghiệp")
    EndTextCommandSetBlipName(farmRentalBlip)
    
    -- Tạo target interaction
    exports.ox_target:addLocalEntity(farmRentalPed, {
        {
            name = 'farm_rental_rent',
            icon = 'fas fa-tractor',
            label = 'Thuê ruộng canh tác',
            distance = 3.0,
            canInteract = function()
                return not IsPedInAnyVehicle(PlayerPedId(), false)
            end,
            onSelect = function()
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    QBCore.Functions.Notify("Không thể tương tác khi đang ngồi trên xe!", "error")
                    return
                end
                TriggerEvent('xx_farming:openFarmRentalMenu')
            end
        },
        {
            name = 'farm_rental_manage',
            icon = 'fas fa-seedling',
            label = 'Quản lý ruộng đã thuê',
            distance = 3.0,
            canInteract = function()
                return not IsPedInAnyVehicle(PlayerPedId(), false)
            end,
            onSelect = function()
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    QBCore.Functions.Notify("Không thể tương tác khi đang ngồi trên xe!", "error")
                    return
                end
                TriggerEvent('xx_farming:openFarmManagement')
            end
        }
    })
end

-- Hàm xem camera ruộng
local function ViewFarmZone(zoneId)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    local zone = FarmRental.FarmZones[zoneId]
    if not zone then return end
    
    isInCameraMode = true
    
    -- Tạo camera
    currentCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(currentCamera, zone.cameraPos.x, zone.cameraPos.y, zone.cameraPos.z)
    SetCamRot(currentCamera, zone.cameraRot.x, zone.cameraRot.y, zone.cameraRot.z, 2)
    SetCamActive(currentCamera, true)
    RenderScriptCams(true, true, 500, true, false)
    
    -- Hiển thị thông báo
    QBCore.Functions.Notify("Đang xem " .. zone.name .. " - Nhấn [ESC] để thoát", "primary", 5000)
    
    -- Vòng lặp chờ người chơi nhấn ESC
    CreateThread(function()
        while isInCameraMode do
            Wait(0)
            if IsControlJustPressed(0, 322) then -- ESC key
                ExitCameraMode()
                break
            end
        end
    end)
end

-- Thoát chế độ camera
function ExitCameraMode()
    if currentCamera then
        SetCamActive(currentCamera, false)
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(currentCamera, false)
        currentCamera = nil
    end
    isInCameraMode = false
end

-- Mở menu thuê ruộng
RegisterNetEvent('xx_farming:openFarmRentalMenu')
AddEventHandler('xx_farming:openFarmRentalMenu', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể tương tác khi đang ngồi trên xe!", "error")
        return
    end
    
    -- Lấy thông tin ruộng đã thuê của người chơi
    local rentals = lib.callback.await('xx_farming:getPlayerRentals', false)
    
    -- Lấy trạng thái tất cả ruộng
    local farmStatus = lib.callback.await('xx_farming:getAllFarmStatus', false)
    
    local options = {}
    
    -- Thêm tùy chọn xem ruộng đã thuê
    if rentals and #rentals > 0 then
        table.insert(options, {
            title = '📋 Ruộng đã thuê',
            description = 'Xem danh sách ruộng bạn đã thuê',
            icon = 'list',
            onSelect = function()
                ShowRentedFarms(rentals)
            end
        })
        table.insert(options, {
            title = '➖➖➖➖➖➖➖➖➖➖',
            disabled = true
        })
    end
    
    -- Thêm các ruộng với trạng thái
    if FarmRental and FarmRental.FarmZones then
        for zoneId, zone in pairs(FarmRental.FarmZones) do
            local status = farmStatus[zoneId]
            
            if zone.capture then
                table.insert(options, {
                    title = '⚔️ ' .. zone.name .. ' (Chiếm khu)',
                    description = 'Không thuê được, xã đoàn chiếm khu bằng cách bấm E tại vòng tròn đỏ',
                    icon = 'flag',
                    disabled = true
                })
            -- Ruộng không cho thuê (công cộng)
            elseif zone.no_rent then
                table.insert(options, {
                    title = '🌿 ' .. zone.name .. ' (Công Cộng)',
                    description = 'Ruộng này mở tự do, ai cũng có thể trồng cây',
                    icon = 'globe',
                    disabled = true
                })
            elseif status and status.isRented then
                if status.isOwnedByPlayer then
                    -- Ruộng của người chơi - có thể quản lý
                    table.insert(options, {
                        title = '✅ ' .. zone.name .. ' (Của bạn)',
                        description = 'Còn lại: ' .. math.floor(status.timeLeft / 3600) .. ' giờ',
                        icon = 'check-circle',
                        onSelect = function()
                            ShowOwnedFarmMenu(zoneId)
                        end
                    })
                else
                    -- Ruộng của người khác - không thể click
                    table.insert(options, {
                        title = '🔒 ' .. zone.name .. ' (Đã thuê)',
                        description = 'Ruộng này đã có chủ',
                        icon = 'lock',
                        disabled = true
                    })
                end
            else
                -- Ruộng trống - có thể thuê
                table.insert(options, {
                    title = '🌾 ' .. zone.name,
                    description = 'Giá: $' .. zone.rentalPrice .. '/giờ - Có thể thuê',
                    icon = 'seedling',
                    onSelect = function()
                        ShowFarmZoneMenu(zoneId)
                    end
                })
            end
        end
    end
    
    lib.registerContext({
        id = 'farm_rental_main',
        title = '🚜 Hệ thống thuê ruộng',
        options = options
    })
    
    lib.showContext('farm_rental_main')
end)

-- Hiển thị menu cho một ruộng cụ thể
function ShowFarmZoneMenu(zoneId)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    
    local zone = FarmRental.FarmZones[zoneId]
    
    if not zone then
        --print("Error: Zone not found for ID:", zoneId)
        return
    end
    
    lib.registerContext({
        id = 'farm_zone_menu',
        title = '🌾 ' .. zone.name,
        menu = 'farm_rental_main',
        options = {
            {
                title = '👁️ Xem ruộng',
                description = 'Xem ruộng từ trên cao',
                icon = 'eye',
                onSelect = function()
                    ViewFarmZone(zoneId)
                end
            },
            {
                title = '💰 Thuê ruộng',
                description = 'Thuê ruộng để canh tác',
                icon = 'money-bill',
                onSelect = function()
                    ShowRentalMenu(zoneId)
                end
            }
        }
    })
    
    lib.showContext('farm_zone_menu')
end

-- Hiển thị menu thuê ruộng
function ShowRentalMenu(zoneId)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    
    local zone = FarmRental.FarmZones[zoneId]
    
    if not zone then
        --print("Error: Zone not found for ID:", zoneId)
        return
    end
    
    local input = lib.inputDialog('Thuê ' .. zone.name, {
        {
            type = 'number',
            label = 'Số giờ thuê',
            description = 'Giá: $' .. zone.rentalPrice .. '/giờ',
            required = true,
            min = 1,
            max = 168 -- Tối đa 1 tuần
        }
    })
    
    if input and input[1] then
        local hours = tonumber(input[1])
        if hours and hours > 0 then
            TriggerServerEvent('xx_farming:rentFarm', zoneId, hours)
        end
    end
end

-- Hiển thị menu quản lý ruộng của người chơi
function ShowOwnedFarmMenu(zoneId)
    if not FarmRental or not FarmRental.FarmZones then
        return
    end
    
    local zone = FarmRental.FarmZones[zoneId]
    if not zone then
        return
    end
    
    lib.registerContext({
        id = 'owned_farm_menu',
        title = '✅ ' .. zone.name .. ' (Của bạn)',
        menu = 'farm_rental_main',
        options = {
            {
                title = '👁️ Xem ruộng',
                description = 'Xem ruộng từ trên cao',
                icon = 'eye',
                onSelect = function()
                    ViewFarmZone(zoneId)
                end
            },
            {
                title = '⏱️ Gia hạn thuê',
                description = 'Gia hạn thời gian thuê ruộng',
                icon = 'clock',
                onSelect = function()
                    openExtendRentalMenu(zoneId)
                end
            },
            {
                title = '👥 Chia sẻ quyền',
                description = 'Chia sẻ quyền trồng cây cho người khác',
                icon = 'users',
                onSelect = function()
                    openSharePermissionMenu(zoneId)
                end
            },
            {
                title = '🗑️ Dọn dẹp và trả ruộng',
                description = 'Xóa tất cả cây trồng và trả ruộng',
                icon = 'trash',
                onSelect = function()
                    TriggerServerEvent('xx_farming:cleanupFarm', zoneId)
                end
            }
        }
    })
    
    lib.showContext('owned_farm_menu')
end

-- Hiển thị ruộng đã thuê
function ShowRentedFarms(rentals)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    
    local options = {}
    
    for _, rental in pairs(rentals) do
        local zone = FarmRental.FarmZones[rental.zone_id]
        if zone then
            local timeLeft = rental.end_time - GetCloudTimeAsInt()
            local hoursLeft = math.floor(timeLeft / 3600)
            local minutesLeft = math.floor((timeLeft % 3600) / 60)
            
            local timeText = ""
            if timeLeft > 0 then
                timeText = string.format("Còn: %dh %dm", hoursLeft, minutesLeft)
            else
                timeText = "Đã hết hạn"
            end
            
            table.insert(options, {
                title = '🌾 ' .. zone.name,
                description = timeText,
                icon = 'clock',
                onSelect = function()
                    ShowRentedFarmMenu(rental)
                end
            })
        end
    end
    
    lib.registerContext({
        id = 'rented_farms',
        title = '📋 Ruộng đã thuê',
        menu = 'farm_rental_main',
        options = options
    })
    
    lib.showContext('rented_farms')
end

-- Menu cho ruộng đã thuê
function ShowRentedFarmMenu(rental)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    
    local zone = FarmRental.FarmZones[rental.zone_id]
    
    if not zone then
        --print("Error: Zone not found for ID:", rental.zone_id)
        return
    end
    
    local timeLeft = rental.end_time - GetCloudTimeAsInt()
    local hoursLeft = math.floor(timeLeft / 3600)
    local minutesLeft = math.floor((timeLeft % 3600) / 60)
    
    local options = {
        {
            title = '👁️ Xem ruộng',
            description = 'Xem ruộng từ trên cao',
            icon = 'eye',
            onSelect = function()
                ViewFarmZone(rental.zone_id)
            end
        }
    }
    
    if timeLeft > 0 then
        table.insert(options, {
            title = '⏰ Gia hạn thuê',
            description = 'Thuê thêm thời gian',
            icon = 'plus-circle',
            onSelect = function()
                ExtendRental(rental.zone_id)
            end
        })
    else
        table.insert(options, {
            title = '🗑️ Thu dọn ruộng',
            description = 'Dọn dẹp và trả ruộng',
            icon = 'trash',
            onSelect = function()
                TriggerServerEvent('xx_farming:cleanupFarm', rental.zone_id)
            end
        })
    end
    
    local timeText = timeLeft > 0 and string.format("Còn: %dh %dm", hoursLeft, minutesLeft) or "Đã hết hạn"
    
    lib.registerContext({
        id = 'rented_farm_menu',
        title = '🌾 ' .. zone.name .. ' - ' .. timeText,
        menu = 'rented_farms',
        options = options
    })
    
    lib.showContext('rented_farm_menu')
end

-- Gia hạn thuê ruộng
function ExtendRental(zoneId)
    if not FarmRental or not FarmRental.FarmZones then
        --print("Error: FarmRental.FarmZones not found!")
        return
    end
    
    
    local zone = FarmRental.FarmZones[zoneId]
    
    if not zone then
        --print("Error: Zone not found for ID:", zoneId)
        return
    end
    
    local input = lib.inputDialog('Gia hạn ' .. zone.name, {
        {
            type = 'number',
            label = 'Số giờ gia hạn',
            description = 'Giá: $' .. zone.rentalPrice .. '/giờ',
            required = true,
            min = 1,
            max = 168
        }
    })
    
    if input and input[1] then
        local hours = tonumber(input[1])
        if hours and hours > 0 then
            TriggerServerEvent('xx_farming:extendRental', zoneId, hours)
        end
    end
end

-- Khởi tạo khi script load
CreateThread(function()
    CreateFarmRentalPed()
end)

-- Cleanup khi script unload
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if farmRentalPed then
            DeleteEntity(farmRentalPed)
        end
        if currentCamera then
            ExitCameraMode()
        end
    end
end)

-- QUẢN LÝ RUỘNG ĐÃ THUÊ --

-- Mở menu quản lý ruộng
RegisterNetEvent('xx_farming:openFarmManagement', function()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        QBCore.Functions.Notify("Không thể tương tác khi đang ngồi trên xe!", "error")
        return
    end
    local playerData = QBCore.Functions.GetPlayerData()
    lib.callback('xx_farming:getPlayerRentals', false, function(rentals)
        local options = {}
        
        if #rentals == 0 then
            options[#options + 1] = {
                title = "Không có ruộng nào",
                description = "Bạn chưa thuê ruộng nào",
                icon = "fas fa-info-circle",
                disabled = true
            }
        else
            for _, rental in ipairs(rentals) do
                local timeLeft = rental.end_time - GetCloudTimeAsInt()
                local hoursLeft = math.floor(timeLeft / 3600)
                local minutesLeft = math.floor((timeLeft % 3600) / 60)
                
                -- Lấy tên ruộng từ config
                local zone = FarmRental.FarmZones[rental.zone_id]
                local zoneName = zone and zone.name or ("Ruộng #" .. rental.zone_id)
                
                local timeLeftText = ""
                if timeLeft > 0 then
                    timeLeftText = string.format("%dh %dm còn lại", hoursLeft, minutesLeft)
                else
                    timeLeftText = "Đã hết hạn"
                end
                
                options[#options + 1] = {
                    title = "🌾 " .. zoneName,
                    description = timeLeftText .. " | Giá đã trả: $" .. rental.price_paid,
                    icon = "fas fa-leaf",
                    args = rental,
                    onSelect = function()
                        openFarmDetailsMenu(rental)
                    end
                }
            end
        end
        
        lib.registerContext({
            id = 'farm_management_menu',
            title = 'Quản lý ruộng',
            options = options
        })
        
        lib.showContext('farm_management_menu')
    end)
end)

-- Menu chi tiết ruộng
function openFarmDetailsMenu(rental)
    local timeLeft = rental.end_time - GetCloudTimeAsInt()
    local hoursLeft = math.floor(timeLeft / 3600)
    local minutesLeft = math.floor((timeLeft % 3600) / 60)
    
    -- Lấy thông tin zone để có giá thuê
    local zone = FarmRental.FarmZones[rental.zone_id]
    local rentalPrice = zone and zone.rentalPrice or 1000 -- fallback price
    
    local options = {}
    
    -- Thông tin thời gian
    if timeLeft > 0 then
        options[#options + 1] = {
            title = "⏰ Thời gian còn lại",
            description = string.format("%d giờ %d phút", hoursLeft, minutesLeft),
            icon = "fas fa-clock",
            disabled = true
        }
    else
        options[#options + 1] = {
            title = "⚠️ Trạng thái",
            description = "Đã hết hạn",
            icon = "fas fa-exclamation-triangle",
            disabled = true
        }
    end
    
    -- Gia hạn
    options[#options + 1] = {
        title = "➕ Gia hạn thêm",
        description = "Thêm thời gian thuê ($" .. rentalPrice .. "/giờ)",
        icon = "fas fa-plus-circle",
        onSelect = function()
            openExtendRentalMenu(rental.zone_id)
        end
    }
    
    -- -- Chó bảo vệ
    -- options[#options + 1] = {
    --     title = "🐕 Chó bảo vệ",
    --     description = "Thuê chó bảo vệ để ngăn chặn ăn cắp",
    --     icon = "fas fa-shield-alt",
    --     onSelect = function()
    --         exports['xn_farming']:ShowDogProtectionMenu(rental.zone_id)
    --     end
    -- }
    
    -- Chia sẻ quyền
    options[#options + 1] = {
        title = "👥 Chia sẻ quyền trồng",
        description = "Cho phép người khác trồng cây",
        icon = "fas fa-users",
        onSelect = function()
            openSharePermissionMenu(rental.zone_id)
        end
    }
    
    -- Xem danh sách người được chia sẻ
    options[#options + 1] = {
        title = "📋 Người được chia sẻ",
        description = "Xem danh sách có quyền trồng",
        icon = "fas fa-list",
        onSelect = function()
            openSharedUsersMenu(rental.zone_id)
        end
    }
    
    -- Lấy tên ruộng từ config
    local zoneName = zone and zone.name or ("Ruộng #" .. rental.zone_id)
    
    lib.registerContext({
        id = 'farm_details_menu',
        title = "🌾 " .. zoneName,
        menu = 'farm_management_menu',
        options = options
    })
    
    lib.showContext('farm_details_menu')
end

-- Menu gia hạn
function openExtendRentalMenu(zoneId)
    local zone = FarmRental.FarmZones[zoneId]
    local rentalPrice = zone and zone.rentalPrice or 1000 -- fallback price
    
    local input = lib.inputDialog('Gia hạn thuê ruộng', {
        {type = 'number', label = 'Số giờ muốn gia hạn', description = 'Giá: $' .. rentalPrice .. '/giờ', required = true, min = 1, max = 168}
    })
    
    if input and input[1] then
        local hours = tonumber(input[1])
        if hours then
            TriggerServerEvent('xx_farming:extendRental', zoneId, hours)
        end
    end
end

-- Menu chia sẻ quyền
function openSharePermissionMenu(zoneId)
    lib.callback('xx_farming:getNearbyPlayers', false, function(nearbyPlayers)
        if not nearbyPlayers or #nearbyPlayers == 0 then
            lib.notify({ title = 'Chia sẻ quyền', description = 'Không có người chơi nào ở gần (trong vòng 10m)!', type = 'error' })
            return
        end

        local options = {}
        for _, player in ipairs(nearbyPlayers) do
            local p = player -- capture
            options[#options + 1] = {
                title = '👤 ' .. p.name,
                description = 'PID: ' .. p.pid,
                icon = 'fas fa-user',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = 'Chia sẻ quyền trồng cây',
                        content = string.format('Chia sẻ quyền ruộng cho **%s** (%s)?', p.name, p.pid),
                        centered = true,
                        cancel = true
                    })
                    if alert == 'confirm' then
                        TriggerServerEvent('xx_farming:sharePermission', zoneId, p.pid)
                    end
                end
            }
        end

        lib.registerContext({
            id = 'share_permission_nearby',
            title = '👥 Chọn người để chia sẻ quyền',
            options = options
        })
        lib.showContext('share_permission_nearby')
    end, 10.0)
end

-- Menu xem người được chia sẻ
function openSharedUsersMenu(zoneId)
    lib.callback('xx_farming:getSharedUsers', false, function(sharedUsers)
        local options = {}
        
        if #sharedUsers == 0 then
            options[#options + 1] = {
                title = "Không có ai được chia sẻ",
                description = "Chưa chia sẻ quyền cho ai",
                icon = "fas fa-info-circle",
                disabled = true
            }
        else
            for _, user in ipairs(sharedUsers) do
                local grantedDate = formatTimestamp(user.granted_at)
                options[#options + 1] = {
                    title = "👤 " .. user.shared_with,
                    description = "Được chia sẻ lúc: " .. grantedDate,
                    icon = "fas fa-user",
                    args = user,
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = 'Xóa quyền truy cập',
                            content = 'Bạn có muốn xóa quyền trồng cây của ' .. user.shared_with .. '?',
                            centered = true,
                            cancel = true
                        })
                        
                        if alert == 'confirm' then
                            TriggerServerEvent('xx_farming:removePermission', zoneId, user.shared_with)
                        end
                    end
                }
            end
        end
        
        lib.registerContext({
            id = 'shared_users_menu',
            title = 'Người được chia sẻ quyền',
            menu = 'farm_details_menu',
            options = options
        })
        
        lib.showContext('shared_users_menu')
    end, zoneId)
end

-- Refresh menu khi có thay đổi
RegisterNetEvent('xx_farming:refreshFarmMenu', function()
    TriggerEvent('xx_farming:openFarmManagement')
end)
