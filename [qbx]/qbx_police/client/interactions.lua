local config = require 'config.client'
local isEscorting = false
local cuffType = 1

exports('IsHandcuffed', function()
    return QBX.PlayerData.metadata.ishandcuffed
end)

local function isTargetDead(playerId)
    return lib.callback.await('police:server:isPlayerDead', false, playerId)
end

local function handCuffAnimation()
    TriggerServerEvent('InteractSound_SV:PlayOnSource', QBX.PlayerData.metadata.ishandcuffed and 'Cuff' or 'Uncuff', 0.2)
    lib.requestAnimDict('mp_arrest_paired')
    Wait(100)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'cop_p2_back_right', 3.0, 3.0, -1, 48, 0, false, false, false)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Cuff', 0.2)
    Wait(3500)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'exit', 3.0, 3.0, -1, 48, 0, false, false, false)
    RemoveAnimDict('mp_arrest_paired')
end

local function getCuffedAnimation(playerId)
    local cuffer = GetPlayerPed(GetPlayerFromServerId(playerId))
    local heading = GetEntityHeading(cuffer)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Cuff', 0.2)
    lib.requestAnimDict('mp_arrest_paired')
    local offset = GetOffsetFromEntityInWorldCoords(cuffer, 0.0, 0.45, 0.0)
    SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)
    Wait(100)
    SetEntityHeading(cache.ped, heading)
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'crook_p2_back_right', 3.0, 3.0, -1, 32, 0, false, false, false)
    Wait(2500)
    RemoveAnimDict('mp_arrest_paired')

    -- Tự động attach người bị còng vào cảnh sát sau khi hoàn thành animation còng tay
    if DoesEntityExist(cuffer) then
        -- Đảm bảo entity hiển thị trước khi attach
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)

        -- Xóa tất cả task hiện tại
        ClearPedTasksImmediately(cache.ped)

        -- Attach vào cảnh sát với vị trí phù hợp
        AttachEntityToEntity(cache.ped, cuffer, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        -- Kiểm tra và đồng bộ hóa visibility sau khi attach
        Wait(100)
        if not IsEntityVisible(cache.ped) then
            SetEntityVisible(cache.ped, true, false)
        end
    end
end

local function escortActions()
    DisableAllControlActions(0)

    -- Explicitly disable hands up and weapon controls to prevent spam
    DisableControlAction(0, 323, true) -- Hands up (X key)
    DisableControlAction(0, 47, true)  -- Weapon wheel
    DisableControlAction(0, 157, true) -- Weapon select
    DisableControlAction(0, 37, true)  -- Select weapon
    DisableControlAction(0, 24, true)  -- Attack
    DisableControlAction(0, 25, true)  -- Aim
    DisableControlAction(0, 44, true)  -- Cover
    DisableControlAction(0, 21, true)  -- Sprint
    DisableControlAction(0, 22, true)  -- Jump
    DisableControlAction(0, 36, true)  -- Stealth

    -- Disable các animation controls có thể gây detach
    DisableControlAction(0, 170, true) -- Animations menu
    DisableControlAction(0, 73, true)  -- Clear animation

    -- Enable only necessary controls for escort
    EnableControlAction(0, 1, true)   -- Look LR
    EnableControlAction(0, 2, true)   -- Look UD
    EnableControlAction(0, 245, true) -- Chat
    EnableControlAction(0, 38, true)  -- E key
    EnableControlAction(0, 249, true) -- N key (talking)
    EnableControlAction(0, 46, true)  -- E key (talking)
end

local function handcuffActions()
    -- Disable weapons & combat
    DisableControlAction(0, 24, true)  -- Attack
    DisableControlAction(0, 25, true)  -- Aim
    DisableControlAction(0, 44, true)  -- Cover
    DisableControlAction(0, 37, true)  -- Select weapon
    DisableControlAction(0, 47, true)  -- Weapon wheel
    DisableControlAction(0, 157, true) -- Weapon select
    DisableControlAction(0, 140, true) -- Melee attack
    DisableControlAction(0, 141, true) -- Melee attack alt
    DisableControlAction(0, 142, true) -- Melee attack heavy
    -- Disable running (shift)
    DisableControlAction(0, 21, true)  -- Sprint
    -- Disable jump, stealth, prone
    DisableControlAction(0, 22, true)  -- Jump
    DisableControlAction(0, 36, true)  -- Stealth
    -- Disable hands up & animations
    DisableControlAction(0, 323, true) -- Hands up
    DisableControlAction(0, 170, true) -- Animations menu
    DisableControlAction(0, 73, true)  -- Clear animation
    -- Disable exit vehicle
    DisableControlAction(27, 75, true)
    -- Allow talking
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
end

local function syncEscortedMovement()
    -- Kiểm tra attachment thực tế thay vì dựa vào biến IsEscorted
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    if not attachedEntity or not DoesEntityExist(attachedEntity) then return end

    local dragger = attachedEntity

    -- Sử dụng logic tương tự như ví dụ nhưng với animation phù hợp cho người bị còng tay
    if IsPedWalking(dragger) then
        if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) then
            lib.requestAnimDict('anim@move_m@prisoner_cuffed')
            TaskPlayAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 8.0, -8, -1, 1, 0.0, false, false, false)
        end
    elseif IsPedRunning(dragger) or IsPedSprinting(dragger) then
        -- Sử dụng animation chạy với tốc độ nhanh hơn của prisoner_cuffed hoặc animation khác phù hợp
        if not IsEntityPlayingAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 3) then
            lib.requestAnimDict('anim@move_m@prisoner_cuffed')
            -- Sử dụng cùng animation walk nhưng với tốc độ cao hơn để mô phỏng chạy
            TaskPlayAnim(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', 12.0, -12, -1, 1, 0.0, false, false, false)
        end
    else
        -- Khi dừng lại, dừng tất cả animation di chuyển
        StopAnimTask(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)

        -- Đặt animation idle nếu chưa có
        if not IsEntityPlayingAnim(cache.ped, 'mp_arresting', 'idle', 3) then
            lib.requestAnimDict('mp_arresting')
            TaskPlayAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, cuffType or 16, 0, false, false, false)
        end
    end

    -- Đồng bộ hóa góc nhìn với người hộ tống
    local draggerHeading = GetEntityHeading(dragger)
    SetEntityHeading(cache.ped, draggerHeading)
end

local function handcuffedEscorted()
    local sleep = 1000
    local anim = {{dict = 'mp_arresting', anim = 'idle'}, {dict = 'mp_arrest_paired', anim = 'crook_p2_back_right'}}

    if not LocalPlayer.state.isLoggedIn then return sleep end

    -- Kiểm tra attachment thực tế thay vì dựa vào biến IsEscorted
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    local isCurrentlyAttached = attachedEntity and DoesEntityExist(attachedEntity)

    -- Xử lý khi đang bị vác (bác sĩ) - kiểm tra animation firemans_carry
    if isCurrentlyAttached and IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
        sleep = 0

        -- Disable tất cả controls để không thể huỷ animation
        DisableAllControlActions(0)
        DisableControlAction(0, 323, true) -- X key - Hands up
        DisableControlAction(0, 73, true)  -- Clear animation
        DisableControlAction(0, 170, true) -- Animation menu
        DisableControlAction(0, 288, true) -- Phone
        DisableControlAction(0, 289, true) -- Inventory
        DisableControlAction(0, 37, true)  -- Weapon wheel
        DisableControlAction(0, 157, true) -- Weapon select

        -- Enable controls cần thiết
        EnableControlAction(0, 1, true)   -- Look LR
        EnableControlAction(0, 2, true)   -- Look UD
        EnableControlAction(0, 245, true) -- Chat
        EnableControlAction(0, 249, true) -- Talk
        EnableControlAction(0, 46, true)  -- Talk 2

        -- Đảm bảo entity hiển thị khi đang bị vác
        if not IsEntityVisible(cache.ped) then
            SetEntityVisible(cache.ped, true, false)
            SetEntityAlpha(cache.ped, 255, false)
        end

        -- Kiểm tra và khôi phục animation nếu bị huỷ
        if not IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
            lib.requestAnimDict('nm')
            TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
        end

        return sleep
    end

    if isCurrentlyAttached and QBX.PlayerData.metadata.ishandcuffed then
        -- Đang bị hộ tống (attached)
        sleep = 0
        escortActions()

        -- Đảm bảo entity hiển thị khi đang bị hộ tống
        if not IsEntityVisible(cache.ped) then
            SetEntityVisible(cache.ped, true, false)
            SetEntityAlpha(cache.ped, 255, false)
        end

        -- Đồng bộ hóa chuyển động và góc nhìn khi bị hộ tống
        syncEscortedMovement()
        return sleep -- Return sớm để tránh bị ghi đè bởi logic handcuff bên dưới
    end

    if not QBX.PlayerData.metadata.ishandcuffed then return sleep end
    sleep = 0
    handcuffActions()
    if QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand then return sleep end
    for i = 1, #anim do
        if IsEntityPlayingAnim(cache.ped, anim[i].dict, anim[i].anim, 3) then return sleep end
    end
    lib.playAnim(cache.ped, 'mp_arresting', 'idle', 8.0, -8, -1, cuffType, 0, false, false, false)

    return sleep
end

RegisterNetEvent('police:client:SetOutVehicle', function()
    -- Event này được gọi cho NGƯỜI BỊ KÉO RA KHỎI XE, không phải người thực hiện
    -- Kiểm tra người này có đang trong xe không
    if not cache.vehicle then return end

    -- Kiểm tra người này có đang bị còng tay, chết, hoặc bất tỉnh không
    if not (QBX.PlayerData.metadata.ishandcuffed or QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand) then
        return
    end

    TaskLeaveVehicle(cache.ped, cache.vehicle, 16)
end)

-- Event kéo ra xe và tự động hộ tống cho police
RegisterNetEvent('police:client:SetOutVehicleAndEscort', function(draggerId)
    if not cache.vehicle then return end
    
    -- Kiểm tra bị còng tay hoặc chết
    if not (QBX.PlayerData.metadata.ishandcuffed or QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand) then
        return
    end
    
    local vehicle = cache.vehicle
    local dragger = GetPlayerPed(GetPlayerFromServerId(draggerId))
    
    -- Kéo ra khỏi xe
    TaskLeaveVehicle(cache.ped, vehicle, 16)
    
    -- Đợi ra khỏi xe hoàn toàn
    local timeout = 0
    while IsPedInAnyVehicle(cache.ped, false) and timeout < 50 do
        Wait(50)
        timeout = timeout + 1
    end
    
    -- Nếu vẫn trong xe thì force ra
    if IsPedInAnyVehicle(cache.ped, false) then
        local offsetCoords = GetOffsetFromEntityInWorldCoords(vehicle, 2.0, 0.0, 0.0)
        SetEntityCoords(cache.ped, offsetCoords.x, offsetCoords.y, offsetCoords.z)
        Wait(100)
    end
    
    -- Bắt đầu hộ tống
    IsEscorted = true
    
    -- Animation hộ tống
    lib.requestAnimDict('mp_arrest_paired')
    TaskPlayAnim(cache.ped, 'mp_arrest_paired', 'crook_p2_back_left', 8.0, -8.0, -1, 33, 0, false, false, false)
    
    Wait(100)
    
    -- Attach vào người hộ tống
    AttachEntityToEntity(cache.ped, dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    
    Wait(100)
    
    TriggerEvent('hospital:client:isEscorted', IsEscorted)
    exports.qbx_core:Notify('Bạn đang bị hộ tống!', 'inform')
end)

RegisterNetEvent('police:client:PutInVehicle', function()
    -- Event này được gọi cho NGƯỜI BỊ ĐƯA VÀO XE, không phải người thực hiện
    -- Kiểm tra người này có đang bị còng tay, chết, hoặc đang bị hộ tống không
    if not (QBX.PlayerData.metadata.ishandcuffed or QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand) then
        return
    end

    -- Kiểm tra và hủy trạng thái attach trước khi đưa vào xe
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    if attachedEntity and DoesEntityExist(attachedEntity) then
        -- Gửi server event để thông báo cho người đang hộ tống/bế TRƯỚC KHI detach
        TriggerServerEvent('police:server:CancelEscortBeforePutInVehicle')

        -- Đợi một chút để server xử lý và người hộ tống/bế nhận được thông báo
        Wait(300)

        -- Force detach nếu đang bị attach
        DetachEntity(cache.ped, true, false)
        ClearPedTasksImmediately(cache.ped)

        -- Reset trạng thái hộ tống/bế
        IsEscorted = false
        beingCarried = false
        carrierPed = nil
        TriggerEvent('hospital:client:isEscorted', IsEscorted)

        -- Đảm bảo entity hiển thị
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)

        -- Đợi thêm để đảm bảo đồng bộ hoàn toàn
        Wait(200)
    end

    local coords = GetEntityCoords(cache.ped)
    local vehicle = lib.getClosestVehicle(coords, 5.0) -- Tăng khoảng cách tìm xe lên 5.0
    if not vehicle or not DoesEntityExist(vehicle) then
        exports.qbx_core:Notify('Không tìm thấy xe gần đây!', 'error')
        return
    end

    -- Đảm bảo ped không còn attach và có thể di chuyển
    DetachEntity(cache.ped, true, false)
    ClearPedTasksImmediately(cache.ped)
    SetEntityVisible(cache.ped, true, false)
    SetEntityAlpha(cache.ped, 255, false)

    -- Reset collision để đảm bảo có thể tương tác với xe
    SetEntityCollision(cache.ped, true, true)

    Wait(100)

    for i = GetVehicleMaxNumberOfPassengers(vehicle), 0, -1 do
        if IsVehicleSeatFree(vehicle, i) then
            local isDead = QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand
            
            if isDead then
                -- Người chết: nhét thẳng vào không animation
                SetPedIntoVehicle(cache.ped, vehicle, i)
            else
                -- Người còng tay: dùng animation bước vào
                TaskEnterVehicle(cache.ped, vehicle, -1, i, 1.0, 1, 0)
                Wait(2000)
                if not IsPedInVehicle(cache.ped, vehicle, false) then
                    SetPedIntoVehicle(cache.ped, vehicle, i)
                end
            end

            return
        end
    end

    exports.qbx_core:Notify('Xe không có chỗ trống!', 'error')
end)

---Check for closest player within distance or 2.5 units
---@param distance number?
---@return number? playerId
---@return number? playerPed
local function getClosestPlayer(distance)
    local coords = GetEntityCoords(cache.ped)
    local player, playerPed = lib.getClosestPlayer(coords, distance or 2.5)
    if not player then
        return exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
    end

    return player, playerPed
end

RegisterNetEvent('police:client:SearchPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    TriggerServerEvent('police:server:SearchPlayer', playerId)
end)

-- Event hiển thị dialog xác nhận lục soát cho người chơi
RegisterNetEvent('police:client:ShowSearchDialog', function(policeSrc)
    local alert = lib.alertDialog({
        header = '⚠️ Thông Báo',
        content = 'Bạn đang bị công an lục soát!\n\nBạn có đồng ý không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Xác Nhận',
            cancel = 'Hủy'
        }
    })

    if alert == 'confirm' then
        -- Người chơi đồng ý
        TriggerServerEvent('police:server:SearchResponse', policeSrc, true)
    else
        -- Người chơi từ chối
        TriggerServerEvent('police:server:SearchResponse', policeSrc, false)
    end
end)

RegisterNetEvent('police:client:ShowSearchResults', function(itemsList, targetName, targetServerId)
    if not itemsList or #itemsList == 0 then
        return exports.qbx_core:Notify('Người chơi không có vật phẩm nào', 'inform')
    end

    local sharedConfig = require 'config.shared'
    local contextMenu = {}

    -- Thêm header
    table.insert(contextMenu, {
        title = '🔍 Lục Soát: ' .. targetName,
        description = 'Tổng số vật phẩm: ' .. #itemsList,
        disabled = true
    })

    -- Thêm từng item vào menu
    for i, item in ipairs(itemsList) do
        local description = 'Số lượng: ' .. item.count

        -- Kiểm tra xem có phải vật phẩm bất hợp pháp không
        local isIllegal = false
        for _, illegalItem in ipairs(sharedConfig.illegalItems) do
            if item.name == illegalItem then
                isIllegal = true
                break
            end
        end

        -- Thêm metadata nếu có
        if item.metadata then
            if item.metadata.durability then
                description = description .. ' | Độ bền: ' .. math.floor(item.metadata.durability) .. '%'
            end
            if item.metadata.ammo then
                description = description .. ' | Đạn: ' .. item.metadata.ammo
            end
            if item.metadata.serial then
                description = description .. ' | Serial: ' .. item.metadata.serial
            end
        end

        -- Thêm cảnh báo nếu là vật phẩm bất hợp pháp
        if isIllegal then
            description = '⚠️ ILLEGAL | ' .. description
        end

        table.insert(contextMenu, {
            title = (isIllegal and '🚨 ' or '📦 ') .. 'Slot ' .. item.slot .. ': ' .. item.label,
            description = description,
            icon = isIllegal and 'exclamation-triangle' or 'box',
            iconColor = isIllegal and '#ff0000' or nil,
            onSelect = function()
                -- Thu đồ về kho công an
                TriggerServerEvent('police:server:ConfiscateItem', targetServerId, item.slot, item.name, item.count, item.metadata)

                -- Đợi một chút để server xử lý
                Wait(500)

                -- Làm mới menu lục soát
                TriggerServerEvent('police:server:SearchPlayer', targetServerId)
            end
        })
    end

    -- Hiển thị context menu
    lib.registerContext({
        id = 'police_search_results',
        title = '🔍 Kết Quả Lục Soát',
        options = contextMenu
    })

    lib.showContext('police_search_results')
end)

-- Event hiển thị kết quả lục soát cốp xe
RegisterNetEvent('police:client:ShowVehicleSearchResults', function(itemsList, plate)
    if not itemsList or #itemsList == 0 then
        return exports.qbx_core:Notify('Cốp xe không có vật phẩm nào', 'inform')
    end

    local sharedConfig = require 'config.shared'
    local contextMenu = {}

    -- Thêm header
    table.insert(contextMenu, {
        title = '🚗 Lục Soát Cốp Xe: ' .. plate,
        description = 'Tổng số vật phẩm: ' .. #itemsList,
        disabled = true
    })

    -- Thêm từng item vào menu
    for i, item in ipairs(itemsList) do
        local description = 'Số lượng: ' .. item.count

        -- Kiểm tra xem có phải vật phẩm bất hợp pháp không
        local isIllegal = false
        for _, illegalItem in ipairs(sharedConfig.illegalItems) do
            if item.name == illegalItem then
                isIllegal = true
                break
            end
        end

        -- Thêm metadata nếu có
        if item.metadata then
            if item.metadata.durability then
                description = description .. ' | Độ bền: ' .. math.floor(item.metadata.durability) .. '%'
            end
            if item.metadata.ammo then
                description = description .. ' | Đạn: ' .. item.metadata.ammo
            end
            if item.metadata.serial then
                description = description .. ' | Serial: ' .. item.metadata.serial
            end
        end

        -- Thêm cảnh báo nếu là vật phẩm bất hợp pháp
        if isIllegal then
            description = '⚠️ ILLEGAL | ' .. description
        end

        table.insert(contextMenu, {
            title = (isIllegal and '🚨 ' or '📦 ') .. 'Slot ' .. item.slot .. ': ' .. item.label,
            description = description,
            icon = isIllegal and 'exclamation-triangle' or 'box',
            iconColor = isIllegal and '#ff0000' or nil,
            onSelect = function()
                -- Thu đồ về kho công an
                TriggerServerEvent('police:server:ConfiscateItemFromVehicle', plate, item.slot, item.name, item.count, item.metadata)

                -- Đợi một chút để server xử lý
                Wait(500)

                -- Làm mới menu lục soát cốp xe
                TriggerServerEvent('police:server:SearchVehicleTrunk', plate)
            end
        })
    end

    -- Hiển thị context menu
    lib.registerContext({
        id = 'police_vehicle_search_results',
        title = '🚗 Kết Quả Lục Soát Cốp Xe',
        options = contextMenu
    })

    lib.showContext('police_vehicle_search_results')
end)

RegisterNetEvent('police:client:SeizeCash', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    TriggerServerEvent('police:server:SeizeCash', playerId)
end)

RegisterNetEvent('police:client:RobPlayer', function()
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)

    if not (IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 3)
        or IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3)
        or isTargetDead(playerId))
    then
        return exports.qbx_core:Notify(locale('error.no_rob'), 'error')
    end

    if lib.progressCircle({
        duration = math.random(5000, 7000),
        position = 'bottom',
        label = locale('progressbar.robbing'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        },
        anim = {
            dict = 'random@shop_robbery',
            clip = 'robbery_action_b',
            flags = 16
        }
    })
    then
        local playerCoords = GetEntityCoords(playerPed)
        local pos = GetEntityCoords(cache.ped)
        if #(pos - playerCoords) < 2.5 then
            StopAnimTask(cache.ped, 'random@shop_robbery', 'robbery_action_b', 1.0)
            exports.ox_inventory:openNearbyInventory()
            TriggerServerEvent('police:server:RobPlayer', playerId)
        else
            exports.qbx_core:Notify(locale('error.none_nearby'), 'error')
        end
    else
        StopAnimTask(cache.ped, 'random@shop_robbery', 'robbery_action_b', 1.0)
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end)

RegisterNetEvent('police:client:JailPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    local dialog = lib.inputDialog(locale('info.jail_time_input'), {
        {type = 'number', label = locale('info.time_months'), min = 0}
    })
    if dialog and dialog[1] > 0 then
        TriggerServerEvent('police:server:JailPlayer', playerId, dialog[1])
    else
        exports.qbx_core:Notify(locale('error.time_higher'), 'error')
    end
end)

RegisterNetEvent('police:client:BillPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    local dialog = lib.inputDialog(locale('info.bill'), {
        {type = 'number', label = locale('info.amount'), min = 0}
    })
    if dialog and dialog[1] > 0 then
        TriggerServerEvent('police:server:BillPlayer', playerId, dialog[1])
    else
        exports.qbx_core:Notify(locale('error.time_higher'), 'error')
    end
end)

local function triggerIfHandsFree(eventName)
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent(eventName, playerId)
end

RegisterNetEvent('police:client:PutPlayerInVehicle', function()
    triggerIfHandsFree('police:server:PutPlayerInVehicle')
end)

RegisterNetEvent('police:client:SetPlayerOutVehicle', function()
    triggerIfHandsFree('police:server:SetPlayerOutVehicle')
end)

RegisterNetEvent('police:client:EscortPlayer', function()
    triggerIfHandsFree('police:server:EscortPlayer')
end)

RegisterNetEvent('police:client:UncuffFromMenu', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    
    lib.callback.await('police:server:CuffPlayer', false, playerId, false)
    handCuffAnimation()
end)

RegisterNetEvent('ambulance:client:EscortPlayer', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent('ambulance:server:EscortPlayer', playerId)
end)

local isCarrying = false
local beingCarried = false
local carrierPed = nil

-- Event riêng cho EMS kéo người ra xe
RegisterNetEvent('ambulance:client:SetPlayerOutVehicle', function()
    local player = getClosestPlayer()
    if not player then return end
    local playerId = GetPlayerServerId(player)
    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent('ambulance:server:SetPlayerOutVehicle', playerId)
end)

-- Event kéo người chết ra xe và tự động vác lên vai
RegisterNetEvent('ambulance:client:SetOutVehicleAndCarry', function(draggerId)
    if not cache.vehicle then return end
    
    -- TẮT KIỂM TRA - Cho phép kéo ra bất kể trạng thái
    -- local isDead = QBX.PlayerData.metadata.isdead or QBX.PlayerData.metadata.inlaststand
    -- if not isDead then return end
    
    local vehicle = cache.vehicle
    local dragger = GetPlayerPed(GetPlayerFromServerId(draggerId))
    
    -- Kiểm tra dragger có tồn tại không
    if not DoesEntityExist(dragger) then
        exports.qbx_core:Notify('Bác sĩ không còn gần!', 'error')
        return
    end
    
    -- Tăng cường network sync trước khi kéo ra
    SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(cache.ped), false)
    
    -- Kéo ra khỏi xe với flag 16 (instant)
    TaskLeaveVehicle(cache.ped, vehicle, 16)
    
    -- Đợi ra khỏi xe hoàn toàn (tăng timeout lên 5 giây cho server nhiều người)
    local timeout = 0
    while IsPedInAnyVehicle(cache.ped, false) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    
    -- Đảm bảo đã ra khỏi xe
    if IsPedInAnyVehicle(cache.ped, false) then
        -- Force ra khỏi xe với vị trí chính xác hơn
        local draggerCoords = GetEntityCoords(dragger)
        local heading = GetEntityHeading(dragger)
        local forwardX = math.sin(math.rad(-heading))
        local forwardY = math.cos(math.rad(-heading))
        local spawnCoords = vector3(draggerCoords.x + forwardX * 1.0, draggerCoords.y + forwardY * 1.0, draggerCoords.z)
        
        SetEntityCoords(cache.ped, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, true)
        Wait(200)
    end
    
    -- Network sync sau khi ra xe
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
    NetworkSetEntityInvisibleToNetwork(cache.ped, false)
    
    -- Bắt đầu vác
    IsEscorted = true
    beingCarried = true
    carrierPed = dragger
    
    SetEntityVisible(cache.ped, true, false)
    SetEntityAlpha(cache.ped, 255, false)
    
    -- Disable targeting và collision cho người bị vác
    SetPedCanBeTargetted(cache.ped, false)
    SetPedCanBeTargettedByTeam(cache.ped, false)
    SetPedCanBeTargettedByPlayer(cache.ped, PlayerId(), false)
    
    -- Disable collision hoàn toàn để không có hitbox -> không target được
    SetEntityCollision(cache.ped, false, false)
    SetEntityCompletelyDisableCollision(cache.ped, false, false)
    
    -- Cố định người chơi mạnh hơn
    SetEntityCollision(cache.ped, false, false)
    SetBlockingOfNonTemporaryEvents(cache.ped, true)
    SetPedCanRagdoll(cache.ped, false)
    SetPedConfigFlag(cache.ped, 32, false) -- Disable movement
    SetPedConfigFlag(cache.ped, 281, true) -- Disable ragdoll from player
    
    lib.requestAnimDict('nm')
    TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
    
    Wait(100)
    
    -- Tăng cường network sync
    SetEntityAsMissionEntity(cache.ped, true, true)
    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
    NetworkSetEntityInvisibleToNetwork(cache.ped, false)
    
    -- Disable collision giữa 2 entity mạnh hơn
    SetEntityNoCollisionEntity(cache.ped, carrierPed, true)
    SetEntityNoCollisionEntity(carrierPed, cache.ped, true)
    SetEntityCompletelyDisableCollision(cache.ped, false, true)
    
    -- Attach với flags mạnh hơn (tham số cuối = true để hard attach) - DÙNG carrierPed
    AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
    
    -- Thread liên tục cố định và kiểm tra attachment - KHÔNG dùng FreezeEntityPosition
    CreateThread(function()
        while beingCarried and IsEscorted do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            
            -- Disable targeting và collision liên tục
            SetPedCanBeTargetted(cache.ped, false)
            SetPedCanBeTargettedByTeam(cache.ped, false)
            SetEntityCollision(cache.ped, false, false)
            
            -- Disable ragdoll mạnh hơn
            SetPedCanRagdoll(cache.ped, false)
            SetPedToRagdoll(cache.ped, 0, 0, 0, false, false, false)
            
            -- Kiểm tra xem còn đang attach không - kiểm tra chặt chẽ hơn
            if DoesEntityExist(carrierPed) then
                local currentAttached = GetEntityAttachedTo(cache.ped)
                local isAttached = IsEntityAttached(cache.ped)
                
                -- Nếu không attach hoặc attach sai người hoặc IsEntityAttached trả về false
                if not isAttached or not currentAttached or not DoesEntityExist(currentAttached) or currentAttached ~= carrierPed then
                    -- Bị detach, attach lại ngay với hard attach
                    DetachEntity(cache.ped, true, false)  -- Detach trước để reset
                    Wait(10)
                    AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
                    
                    -- Force network sync lại
                    SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
                end
            end
            
            -- Đảm bảo animation không bị hủy
            if not IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
                TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
            end
            
            Wait(0)
        end
    end)
    
    Wait(100)
    if not IsEntityVisible(cache.ped) then
        SetEntityVisible(cache.ped, true, false)
    end
    
    exports.qbx_core:Notify('Bạn đang được bác sĩ vác!', 'inform')
end)

RegisterNetEvent('ambulance:client:GetCarried', function(draggerId)
    -- Kiểm tra trạng thái attach hiện tại
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    local isCurrentlyCarried = attachedEntity and DoesEntityExist(attachedEntity)

    if not isCurrentlyCarried then
        -- Bắt đầu bị vác
        IsEscorted = true
        beingCarried = true
        local dragger = GetPlayerPed(GetPlayerFromServerId(draggerId))
        carrierPed = dragger

        -- Đảm bảo entity hiển thị trước khi thực hiện các thao tác
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)
        
        -- Disable targeting và collision cho người bị vác
        SetPedCanBeTargetted(cache.ped, false)
        SetPedCanBeTargettedByTeam(cache.ped, false)
        SetPedCanBeTargettedByPlayer(cache.ped, PlayerId(), false)
        
        -- Disable collision hoàn toàn để không có hitbox -> không target được
        SetEntityCollision(cache.ped, false, false)
        SetEntityCompletelyDisableCollision(cache.ped, false, false)
        
        -- Cố định người chơi mạnh hơn
        SetEntityCollision(cache.ped, false, false)
        SetBlockingOfNonTemporaryEvents(cache.ped, true)
        SetPedCanRagdoll(cache.ped, false)
        SetPedConfigFlag(cache.ped, 32, false) -- Disable movement
        SetPedConfigFlag(cache.ped, 281, true) -- Disable ragdoll from player

        -- Animation người bị vác (firemans carry)
        lib.requestAnimDict('nm')
        TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)

        -- Tăng cường network sync
        SetEntityAsMissionEntity(cache.ped, true, true)
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
        NetworkSetEntityInvisibleToNetwork(cache.ped, false)
        
        -- Disable collision giữa 2 entity mạnh hơn - DÙNG carrierPed
        SetEntityNoCollisionEntity(cache.ped, carrierPed, true)
        SetEntityNoCollisionEntity(carrierPed, cache.ped, true)
        SetEntityCompletelyDisableCollision(cache.ped, false, true)
        
        -- Attach với flags mạnh hơn (tham số cuối = true để hard attach) - DÙNG carrierPed
        AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
        
        -- Thread liên tục cố định và kiểm tra attachment - KHÔNG dùng FreezeEntityPosition
        CreateThread(function()
            while beingCarried and IsEscorted do
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                
                -- Disable targeting và collision liên tục
                SetPedCanBeTargetted(cache.ped, false)
                SetPedCanBeTargettedByTeam(cache.ped, false)
                SetEntityCollision(cache.ped, false, false)
                
                -- Disable ragdoll mạnh hơn
                SetPedCanRagdoll(cache.ped, false)
                SetPedToRagdoll(cache.ped, 0, 0, 0, false, false, false)
                
                -- Kiểm tra xem còn đang attach không - kiểm tra chặt chẽ hơn
                if DoesEntityExist(carrierPed) then
                    local currentAttached = GetEntityAttachedTo(cache.ped)
                    local isAttached = IsEntityAttached(cache.ped)
                    
                    -- Nếu không attach hoặc attach sai người hoặc IsEntityAttached trả về false
                    if not isAttached or not currentAttached or not DoesEntityExist(currentAttached) or currentAttached ~= carrierPed then
                        -- Bị detach, attach lại ngay với hard attach
                        DetachEntity(cache.ped, true, false)  -- Detach trước để reset
                        Wait(10)
                        AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, true, false, 2, true)
                        
                        -- Force network sync lại
                        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(cache.ped), true)
                    end
                end
                
                -- Đảm bảo animation không bị hủy
                if not IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
                    TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
                end
                
                Wait(0)
            end
        end)

        -- Kiểm tra và đồng bộ hóa visibility sau khi attach
        Wait(100)
        if not IsEntityVisible(cache.ped) then
            SetEntityVisible(cache.ped, true, false)
        end

        exports.qbx_core:Notify('Bạn đang được bác sĩ vác!', 'inform')
    else
        -- Kết thúc bị vác - hủy hoàn toàn cả 2 bên
        IsEscorted = false
        beingCarried = false
        
        -- Re-enable targeting
        SetPedCanBeTargetted(cache.ped, true)
        SetPedCanBeTargettedByTeam(cache.ped, true)
        SetPedCanBeTargettedByPlayer(cache.ped, PlayerId(), true)
        
        Wait(50)
        
        SetEntityCollision(cache.ped, true, true)
        SetEntityCanBeDamaged(cache.ped, true)
        SetBlockingOfNonTemporaryEvents(cache.ped, false)
        SetPedCanRagdoll(cache.ped, true)
        SetPedConfigFlag(cache.ped, 32, true) -- Enable movement
        SetPedConfigFlag(cache.ped, 281, false) -- Enable ragdoll
        SetEntityVisible(cache.ped, true, false)
        SetEveryoneIgnorePlayer(cache.playerId, false)

        -- Stop animation trước
        ClearPedTasksImmediately(cache.ped)

        -- Force detach nhiều lần để đảm bảo
        if IsEntityAttachedToAnyPed(cache.ped) or IsEntityAttachedToAnyVehicle(cache.ped) then
            DetachEntity(cache.ped, true, true)
        end

        -- Kiểm tra lại và detach lần nữa nếu vẫn còn attach
        Wait(50)
        if IsEntityAttached(cache.ped) then
            local attachedTo = GetEntityAttachedTo(cache.ped)
            if DoesEntityExist(attachedTo) then
                DetachEntity(cache.ped, true, true)
            end
        end

        -- Reset carrierPed sau khi detach
        carrierPed = nil
        
        -- *** QUAN TRỌNG: RE-ENABLE collision với TẤT CẢ entities ***
        -- Clear no-collision với tất cả players
        local allPlayers = GetActivePlayers()
        for _, playerId in ipairs(allPlayers) do
            local otherPed = GetPlayerPed(playerId)
            if otherPed ~= cache.ped and DoesEntityExist(otherPed) then
                SetEntityNoCollisionEntity(cache.ped, otherPed, true)
                SetEntityNoCollisionEntity(otherPed, cache.ped, true)
            end
        end

        -- Đảm bảo entity vẫn hiển thị
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)

        -- Đặt lại coords để đảm bảo hoàn toàn tách rời
        local coords = GetEntityCoords(cache.ped)
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, true)

        -- Freeze ped ngắn để coords apply đúng
        FreezeEntityPosition(cache.ped, true)
        Wait(100)
        FreezeEntityPosition(cache.ped, false)
        
        -- FORCE reset collision HOÀN TOÀN giống revive
        Wait(100)
        
        -- Request network control để đảm bảo sync
        NetworkRequestControlOfEntity(cache.ped)
        Wait(50)
        
        SetEntityCollision(cache.ped, true, true)
        Wait(50)
        
        SetEntityInvincible(cache.ped, false)
        SetEntityCanBeDamaged(cache.ped, true)
        SetPedCanRagdoll(cache.ped, true)
        
        SetPedConfigFlag(cache.ped, 281, false)
        Wait(50)
        
        SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false)
        SetEntityVisible(cache.ped, true, false)
        NetworkSetEntityInvisibleToNetwork(cache.ped, false)
        SetEveryoneIgnorePlayer(cache.playerId, false)
        SetPoliceIgnorePlayer(cache.playerId, false)
        ResetEntityAlpha(cache.ped)
        
        -- Force refresh collision bằng freeze/unfreeze trick - NHIỀU LẦN
        FreezeEntityPosition(cache.ped, true)
        Wait(100)
        FreezeEntityPosition(cache.ped, false)
        
        Wait(100)
        SetEntityCollision(cache.ped, true, true)
        
        Wait(100)
        FreezeEntityPosition(cache.ped, true)
        Wait(100)
        FreezeEntityPosition(cache.ped, false)
        
        Wait(100)
        SetEntityCollision(cache.ped, true, true)
        SetPedConfigFlag(cache.ped, 281, false)
        
        exports.qbx_core:Notify('Bạn đã được đặt xuống!', 'inform')

        -- Gửi server event để reset trạng thái bác sĩ
        TriggerServerEvent('ambulance:server:StopCarrying')
    end
    TriggerEvent('hospital:client:isEscorted', IsEscorted)
end)

RegisterNetEvent('ambulance:client:CarryingPlayer', function()
    if not isCarrying then
        -- Bắt đầu vác người - animation giống kidnapping (đã được test ổn định)
        lib.requestAnimDict('missfinale_c2mcs_1')
        TaskPlayAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)
        isCarrying = true
        
        -- Tắt collision giữa bác sĩ và người bị vác (giống như người chết đang dùng)
        CreateThread(function()
            Wait(500) -- Đợi người được attach
            local allPlayers = GetActivePlayers()
            for _, playerId in ipairs(allPlayers) do
                local otherPed = GetPlayerPed(playerId)
                if otherPed ~= cache.ped then
                    local attachedTo = GetEntityAttachedTo(otherPed)
                    if attachedTo == cache.ped then
                        -- Đây là người đang bị vác bởi mình
                        SetEntityNoCollisionEntity(cache.ped, otherPed, false)
                        SetEntityNoCollisionEntity(otherPed, cache.ped, false)
                    end
                end
            end
        end)
        
        -- Thread cố định animation và disable controls
        CreateThread(function()
            while isCarrying do
                -- Đảm bảo animation không bị hủy
                if not IsEntityPlayingAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 3) then
                    TaskPlayAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, -1, 49, 0, false, false, false)
                end
                
                -- Disable các phím có thể làm gián đoạn
                DisableControlAction(0, 24, true) -- Attack
                DisableControlAction(0, 25, true) -- Aim
                DisableControlAction(0, 140, true) -- Melee Attack Light
                DisableControlAction(0, 141, true) -- Melee Attack Heavy
                DisableControlAction(0, 142, true) -- Melee Attack Alternate
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 44, true) -- Cover
                DisableControlAction(0, 37, true) -- Select Weapon
                DisableControlAction(0, 45, true) -- Reload
                DisableControlAction(0, 22, true) -- Jump
                
                Wait(0)
            end
        end)
        
        exports.qbx_core:Notify('Đang vác người chơi!', 'inform')
    else
        -- Dừng vác người
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasksImmediately(cache.ped)
        isCarrying = false
        
        -- FORCE reset collision cho bác sĩ
        Wait(50)
        SetEntityCollision(cache.ped, true, true)
        SetEntityInvincible(cache.ped, false)
        SetEntityCanBeDamaged(cache.ped, true)
        SetPedCanRagdoll(cache.ped, true)
        SetPedConfigFlag(cache.ped, 281, false)
        SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false)
        SetEntityVisible(cache.ped, true, false)
        NetworkSetEntityInvisibleToNetwork(cache.ped, false)
        SetEveryoneIgnorePlayer(cache.playerId, false)
        SetPoliceIgnorePlayer(cache.playerId, false)
        ResetEntityAlpha(cache.ped)
        
        -- Force refresh collision bằng freeze/unfreeze trick
        FreezeEntityPosition(cache.ped, true)
        Wait(50)
        FreezeEntityPosition(cache.ped, false)
        
        exports.qbx_core:Notify('Đã thả người chơi xuống!', 'inform')
    end
end)

-- Event để force stop carrying từ server
RegisterNetEvent('ambulance:client:ForceStopCarrying', function()
    if isCarrying then
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasksImmediately(cache.ped)
        isCarrying = false
    end

    -- Kiểm tra xem có ai đang attach vào mình không và detach họ
    local myPed = cache.ped
    local allPlayers = GetActivePlayers()
    for _, playerId in ipairs(allPlayers) do
        local otherPed = GetPlayerPed(playerId)
        if otherPed ~= myPed and IsEntityAttached(otherPed) then
            local attachedTo = GetEntityAttachedTo(otherPed)
            if attachedTo == myPed then
                -- Detach người này khỏi mình
                DetachEntity(otherPed, true, true)
            end
        end
    end
end)

-- Event để force detach người bị vác
RegisterNetEvent('ambulance:client:ForceDetach', function()
    if beingCarried or IsEscorted then
        IsEscorted = false
        beingCarried = false

        -- Stop animation trước
        ClearPedTasksImmediately(cache.ped)

        -- Force detach nhiều lần để đảm bảo
        if IsEntityAttachedToAnyPed(cache.ped) or IsEntityAttachedToAnyVehicle(cache.ped) then
            DetachEntity(cache.ped, true, true)
        end

        -- Kiểm tra lại và detach lần nữa nếu vẫn còn attach
        Wait(50)
        if IsEntityAttached(cache.ped) then
            local attachedTo = GetEntityAttachedTo(cache.ped)
            if DoesEntityExist(attachedTo) then
                DetachEntity(cache.ped, true, true)
            end
        end

        -- Reset carrierPed sau khi detach
        carrierPed = nil
        
        -- *** QUAN TRỌNG: RE-ENABLE collision với TẤT CẢ entities ***
        local allPlayers = GetActivePlayers()
        for _, playerId in ipairs(allPlayers) do
            local otherPed = GetPlayerPed(playerId)
            if otherPed ~= cache.ped and DoesEntityExist(otherPed) then
                SetEntityNoCollisionEntity(cache.ped, otherPed, true)
                SetEntityNoCollisionEntity(otherPed, cache.ped, true)
            end
        end

        -- Đảm bảo entity hiển thị và đặt lại vị trí
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)

        -- Đặt lại coords để đảm bảo hoàn toàn tách rời
        local coords = GetEntityCoords(cache.ped)
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, true)

        -- Freeze ped ngắn để coords apply đúng
        FreezeEntityPosition(cache.ped, true)
        Wait(100)
        FreezeEntityPosition(cache.ped, false)
        
        -- FORCE reset collision HOÀN TOÀN
        Wait(50)
        SetEntityCollision(cache.ped, true, true)
        SetEntityInvincible(cache.ped, false)
        SetEntityCanBeDamaged(cache.ped, true)
        SetPedCanRagdoll(cache.ped, true)
        SetPedConfigFlag(cache.ped, 281, false) -- TẮT NO_COLLISION
        SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false)
        SetEntityVisible(cache.ped, true, false)
        NetworkSetEntityInvisibleToNetwork(cache.ped, false)
        SetEveryoneIgnorePlayer(cache.playerId, false)
        SetPoliceIgnorePlayer(cache.playerId, false)
        ResetEntityAlpha(cache.ped)
        SetBlockingOfNonTemporaryEvents(cache.ped, false)
        SetPedCanBeTargetted(cache.ped, true)
        SetPedCanBeTargettedByPlayer(cache.ped, PlayerId(), true)
        SetPedConfigFlag(cache.ped, 32, true) -- Enable movement
        
        -- Force refresh collision
        FreezeEntityPosition(cache.ped, true)
        Wait(50)
        FreezeEntityPosition(cache.ped, false)

        TriggerEvent('hospital:client:isEscorted', IsEscorted)
        exports.qbx_core:Notify('Đã được thả xuống!', 'inform')
    end
end)

RegisterNetEvent('police:client:KidnapPlayer', function()
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)
    if IsPedInAnyVehicle(playerPed, false) or QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return end
    TriggerServerEvent('police:server:KidnapPlayer', playerId)
end)

RegisterNetEvent('police:client:CuffPlayerSoft', function()
    if IsPedRagdoll(cache.ped) then return end

    -- Kiểm tra xem có đang bơi không (bao gồm cả trên và dưới nước)
    if not IsPedSwimming(cache.ped) then
        return exports.qbx_core:Notify('Bạn phải đang bơi trong nước để sử dụng chức năng này!', 'error')
    end

    local player, playerPed = getClosestPlayer(1.5)
    if not player or not playerPed then return end
    local playerId = GetPlayerServerId(player)

    if IsPedInAnyVehicle(playerPed, false) or cache.vehicle then
        return exports.qbx_core:Notify(locale('error.vehicle_cuff'), 'error')
    end

    if lib.callback.await('police:server:CuffPlayer', false, playerId, true) then
        handCuffAnimation()
    end
end)

RegisterNetEvent('police:client:CuffPlayer', function()
    if IsPedRagdoll(cache.ped) then return end
    local player, playerPed = getClosestPlayer()
    if not player or not playerPed then return end

    if exports.ox_inventory:Search('count', config.handcuffItems) == 0 then
        return exports.qbx_core:Notify(locale('error.no_cuff'), 'error')
    end

    local playerId = GetPlayerServerId(player)

    if IsPedInAnyVehicle(playerPed, false) or cache.vehicle then
        return exports.qbx_core:Notify(locale('error.vehicle_cuff'), 'error')
    end

    if lib.callback.await('police:server:CuffPlayer', false, playerId, false) then
        handCuffAnimation()
    end
end)

RegisterNetEvent('police:client:GetEscorted', function(playerId)
    if not(QBX.PlayerData.metadata.isdead
        or QBX.PlayerData.metadata.ishandcuffed
        or QBX.PlayerData.metadata.inlaststand)
    then return end

    -- Kiểm tra trạng thái attach hiện tại thay vì dựa vào biến IsEscorted
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    local isCurrentlyAttached = attachedEntity and DoesEntityExist(attachedEntity)

    if not isCurrentlyAttached then
        -- Bắt đầu hộ tống
        IsEscorted = true
        local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))
        local offset = GetOffsetFromEntityInWorldCoords(dragger, 0.0, 0.45, 0.0)
        SetEntityCoords(cache.ped, offset.x, offset.y, offset.z, true, false, false, false)

        -- Đảm bảo entity hiển thị trước khi attach
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)

        -- Xóa tất cả task hiện tại - animation sẽ được xử lý bởi syncEscortedMovement()
        ClearPedTasksImmediately(cache.ped)

        AttachEntityToEntity(cache.ped, dragger, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        -- Kiểm tra và đồng bộ hóa visibility sau khi attach
        Wait(100)
        if not IsEntityVisible(cache.ped) then
            SetEntityVisible(cache.ped, true, false)
        end
    else
        -- Kết thúc hộ tống - detach ngay lập tức
        DetachEntity(cache.ped, true, false)

        -- Dừng tất cả animation di chuyển
        StopAnimTask(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)
        ClearPedTasksImmediately(cache.ped)

        -- LUÔN set IsEscorted = false khi detach, bất kể trạng thái còng tay
        IsEscorted = false

        -- Đảm bảo entity vẫn hiển thị sau khi detach
        SetEntityVisible(cache.ped, true, false)
        SetEntityAlpha(cache.ped, 255, false)
    end
    TriggerEvent('hospital:client:isEscorted', IsEscorted)
end)

RegisterNetEvent('police:client:DeEscort', function()
    -- Force detach ngay lập tức, không kiểm tra điều kiện
    DetachEntity(cache.ped, true, false)

    -- Dừng tất cả animation di chuyển
    StopAnimTask(cache.ped, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)
    ClearPedTasksImmediately(cache.ped)

    -- Force set IsEscorted = false để dừng auto-reattach
    IsEscorted = false
    TriggerEvent('hospital:client:isEscorted', IsEscorted)

    -- Đảm bảo entity hiển thị sau khi detach
    SetEntityVisible(cache.ped, true, false)
    SetEntityAlpha(cache.ped, 255, false)

    -- Xác nhận đã detach
    local attachedEntity = GetEntityAttachedTo(cache.ped)
    if not attachedEntity then
        exports.qbx_core:Notify('Đã được thả hộ tống!', 'success')
    else
        DetachEntity(cache.ped, true, false)
    end
end)

RegisterNetEvent('police:client:GetKidnappedTarget', function(playerId)
    if     QBX.PlayerData.metadata.isdead
        or QBX.PlayerData.metadata.ishandcuffed
        or QBX.PlayerData.metadata.inlaststand
    then
        if not IsEscorted then
            IsEscorted = true
            local dragger = GetPlayerPed(GetPlayerFromServerId(playerId))

            -- Đảm bảo entity hiển thị trước khi thực hiện các thao tác
            SetEntityVisible(cache.ped, true, false)
            SetEntityAlpha(cache.ped, 255, false)

            lib.playAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, 100000, 33, 0, false, false, false)
            AttachEntityToEntity(cache.ped, dragger, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)

            -- Kiểm tra và đồng bộ hóa visibility sau khi attach
            Wait(100)
            if not IsEntityVisible(cache.ped) then
                SetEntityVisible(cache.ped, true, false)
            end
        else
            IsEscorted = false
            DetachEntity(cache.ped, true, false)
            ClearPedTasksImmediately(cache.ped)

            -- Đảm bảo entity vẫn hiển thị sau khi detach
            SetEntityVisible(cache.ped, true, false)
            SetEntityAlpha(cache.ped, 255, false)
        end
        TriggerEvent('hospital:client:isEscorted', IsEscorted)
    end
end)

RegisterNetEvent('police:client:GetKidnappedDragger', function()
    if not isEscorting then
        lib.playAnim(cache.ped, 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman', 8.0, -8.0, 100000, 49, 0, false, false, false)
        isEscorting = true
    else
        ClearPedSecondaryTask(cache.ped)
        ClearPedTasksImmediately(cache.ped)
        isEscorting = false
    end
    TriggerEvent('hospital:client:SetEscortingState', isEscorting)
    TriggerEvent('qb-kidnapping:client:SetKidnapping', isEscorting)
end)

-- Event để kiểm tra và giải phóng target khi họ được đưa vào xe
RegisterNetEvent('police:client:CheckAndReleaseTarget', function(targetServerId)
    -- Kiểm tra xem có ai đang attach vào mình không
    local myPed = cache.ped
    local allPlayers = GetActivePlayers()

    for _, playerId in ipairs(allPlayers) do
        local otherPed = GetPlayerPed(playerId)
        local otherServerId = GetPlayerServerId(playerId)

        if otherPed ~= myPed and otherServerId == targetServerId and IsEntityAttached(otherPed) then
            local attachedTo = GetEntityAttachedTo(otherPed)
            if attachedTo == myPed then
                -- Detach người này khỏi mình
                DetachEntity(otherPed, true, true)

                -- Dừng animation của mình nếu đang vác/hộ tống
                if isEscorting then
                    ClearPedSecondaryTask(cache.ped)
                    ClearPedTasksImmediately(cache.ped)
                    isEscorting = false
                    TriggerEvent('hospital:client:SetEscortingState', isEscorting)
                end

                if isCarrying then
                    ClearPedSecondaryTask(cache.ped)
                    ClearPedTasksImmediately(cache.ped)
                    isCarrying = false
                end

                exports.qbx_core:Notify('Người chơi đã được đưa vào xe!', 'inform')
                break
            end
        end
    end
end)

RegisterNetEvent('police:client:GetCuffed', function(playerId, isSoftcuff)
    if not QBX.PlayerData.metadata.ishandcuffed then
        TriggerServerEvent('police:server:SetHandcuffStatus', true)
        ClearPedTasksImmediately(cache.ped)
        if cache.weapon ~= `WEAPON_UNARMED` then
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
        end

        -- Tắt phone khi bị còng tay
        exports["lb-phone"]:ToggleDisabled(true)

        if not isSoftcuff then
            cuffType = 16
            exports.qbx_core:Notify(locale('info.cuff'), 'success')
        else
            if config.breakCuffs == true then
                local isSuccess = lib.skillCheck(config.breakCuffsDifficulty, config.breakCuffsKeys)
                if isSuccess then
                    TriggerServerEvent('police:server:SetHandcuffStatus', false)
                    ClearPedTasksImmediately(cache.ped)
                    -- Bật lại phone khi thoát còng tay
                    exports["lb-phone"]:ToggleDisabled(false)
                    exports.qbx_core:Notify(locale('success.escapedcuff'), 'success')
                    return
                end
            end
            cuffType = 48
            exports.qbx_core:Notify(locale('info.cuffed_walk'), 'success')
        end
        getCuffedAnimation(playerId)
        LocalPlayer.state.invBusy = true
        -- Tự động đặt IsEscorted = true khi bị còng tay
        IsEscorted = true
        TriggerEvent('hospital:client:isEscorted', IsEscorted)
    else
        IsEscorted = false
        LocalPlayer.state.invBusy = false
        TriggerEvent('hospital:client:isEscorted', IsEscorted)
        DetachEntity(cache.ped, true, false)
        TriggerServerEvent('police:server:SetHandcuffStatus', false)
        ClearPedTasksImmediately(cache.ped)
        TriggerServerEvent('InteractSound_SV:PlayOnSource', 'Uncuff', 0.2)

        -- Bật lại phone khi được gỡ còng tay
        exports["lb-phone"]:ToggleDisabled(false)

        exports.qbx_core:Notify(locale('success.uncuffed'), 'success')
    end
end)

local DISABLED_CONTROLS = {
    21,  -- Sprint
    24,  -- Attack
    257, -- Attack 2
    25,  -- Aim
    263, -- Melee Attack 1
    45,  -- Reload
    22,  -- Jump
    44,  -- Cover
    37,  -- Select Weapon
    23,  -- Also 'enter'?
    288, -- Disable phone
    289, -- Inventory
    170, -- Animations
    167, -- Job
    26,  -- Disable looking behind
    73,  -- Disable clearing animation
    199, -- Disable pause screen
    59,  -- Disable steering in vehicle
    71,  -- Disable driving forward in vehicle
    72,  -- Disable reversing in vehicle
    36,  -- Disable going stealth
    264, -- Disable melee
    257, -- Disable melee
    140, -- Disable melee
    141, -- Disable melee
    142, -- Disable melee
    143, -- Disable melee
    75,  -- Disable exit vehicle
    323, -- Disable hands up (X key) to prevent escort spam
    47,  -- Disable weapon wheel
    157, -- Disable weapon select
    158, -- Disable weapon select next
    159, -- Disable weapon select prev
    160, -- Disable weapon select left
    161, -- Disable weapon select right
    162, -- Disable weapon select up
    163  -- Disable weapon select down
}

CreateThread(function()
    local hasDisabledControls = false
    while true do
        local sleep = handcuffedEscorted()
        if sleep > 0 and hasDisabledControls then --if sleep is greater than 0, activates controls
            lib.disableControls:Remove(DISABLED_CONTROLS)
            hasDisabledControls = false
        elseif sleep == 0 and not hasDisabledControls then
            lib.disableControls:Add(DISABLED_CONTROLS)
            hasDisabledControls = true
        end
        Wait(sleep)
    end
end)

-- Thread riêng để ngăn chặn hands up và X key spam
CreateThread(function()
    while true do
        -- Kiểm tra xem có đang bị attach (hộ tống hoặc vác) không
        local attachedEntity = GetEntityAttachedTo(cache.ped)
        local isCurrentlyAttached = attachedEntity and DoesEntityExist(attachedEntity)

        -- Nếu đang bị attach hoặc bị còng tay
        if isCurrentlyAttached or QBX.PlayerData.metadata.ishandcuffed then
            Wait(0) -- Check mỗi frame để disable ngay lập tức

            -- Disable X key liên tục
            DisableControlAction(0, 323, true) -- X key - Hands up

            -- Nếu đang có hands up animation, clear nó ngay lập tức
            if IsEntityPlayingAnim(cache.ped, 'missminuteman_1ig_2', 'handsup_base', 3) then
                ClearPedTasksImmediately(cache.ped)
            end
        else
            Wait(500) -- Nếu không bị attach thì check chậm hơn
        end
    end
end)

-- Thread để kiểm tra và reattach khi đang bị hộ tống hoặc vác
CreateThread(function()
    while true do
        Wait(200) -- Check mỗi 0.2s để phát hiện nhanh

        local attachedEntity = GetEntityAttachedTo(cache.ped)
        local shouldBeAttached = false
        local targetPed = nil

        -- Kiểm tra nếu đang bị vác
        if beingCarried and carrierPed and DoesEntityExist(carrierPed) then
            shouldBeAttached = true
            targetPed = carrierPed

            -- Nếu không còn attach hoặc attach sai người
            if not attachedEntity or attachedEntity ~= carrierPed then
                -- Reattach
                SetEntityVisible(cache.ped, true, false)
                SetEntityAlpha(cache.ped, 255, false)

                -- Khôi phục animation
                if not IsEntityPlayingAnim(cache.ped, 'nm', 'firemans_carry', 3) then
                    lib.requestAnimDict('nm')
                    TaskPlayAnim(cache.ped, 'nm', 'firemans_carry', 8.0, -8.0, -1, 33, 0, false, false, false)
                end

                -- Reattach
                AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
            end
        -- Kiểm tra nếu đang bị hộ tống (còng tay + IsEscorted = true)
        elseif IsEscorted and QBX.PlayerData.metadata.ishandcuffed then
            shouldBeAttached = true

            -- Tìm người công an gần nhất đang hộ tống
            if not attachedEntity or not DoesEntityExist(attachedEntity) then
                local coords = GetEntityCoords(cache.ped)
                local closestPlayer, closestPed = lib.getClosestPlayer(coords, 3.0)

                if closestPlayer and closestPed then
                    -- Kiểm tra xem người này có phải công an không
                    local targetPlayerId = GetPlayerServerId(closestPlayer)

                    -- Reattach vào công an
                    targetPed = closestPed
                    SetEntityVisible(cache.ped, true, false)
                    SetEntityAlpha(cache.ped, 255, false)

                    -- Clear task trước khi attach
                    ClearPedTasksImmediately(cache.ped)

                    -- Attach lại
                    AttachEntityToEntity(cache.ped, closestPed, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

                    Wait(100)
                    if not IsEntityVisible(cache.ped) then
                        SetEntityVisible(cache.ped, true, false)
                    end
                end
            end
        end
    end
end)

-- Quick escort keybind cho công an
lib.addKeybind({
    name = 'Ho_Tong_NhanhCan' .. math.random(1,10),
    description = '<font face="Oswald">[130] CÔNG AN HỘ TỐNG NHANH</font>',
    defaultKey = 'J',
    onPressed = function()
        -- Kiểm tra nếu là công an
        if not QBX.PlayerData.job or (QBX.PlayerData.job.name ~= 'police' and QBX.PlayerData.job.name ~= 'sheriff') then
            return exports.qbx_core:Notify('Bạn không phải là công an!', 'error')
        end

        -- Kiểm tra nếu công an không bị còng tay
        if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then
            return exports.qbx_core:Notify('Bạn không thể hộ tống khi đang bị còng tay!', 'error')
        end

        -- Kiểm tra xem có ai đang được attach vào công an này không
        local coords = GetEntityCoords(cache.ped)
        local isCurrentlyEscorting = false
        local attachedPlayer = nil

        -- Quét tất cả người chơi gần để tìm ai đang attach vào công an
        local players = GetActivePlayers()
        for _, playerId in ipairs(players) do
            local playerPed = GetPlayerPed(playerId)
            if playerPed and DoesEntityExist(playerPed) and playerPed ~= cache.ped then
                local attachedEntity = GetEntityAttachedTo(playerPed)
                if attachedEntity and attachedEntity == cache.ped then
                    isCurrentlyEscorting = true
                    attachedPlayer = playerId
                    break
                end
            end
        end

        if isCurrentlyEscorting and attachedPlayer then
            -- Đang hộ tống -> Thả hộ tống
            local playerId = GetPlayerServerId(attachedPlayer)

            -- Gọi trực tiếp event DeEscort cho người chơi bị hộ tống
            TriggerServerEvent('police:server:EscortPlayer', playerId)

            -- Force detach local ngay lập tức
            local playerPed = GetPlayerPed(attachedPlayer)
            if DoesEntityExist(playerPed) then
                DetachEntity(playerPed, true, false)
                SetEntityVisible(playerPed, true, false)
                SetEntityAlpha(playerPed, 255, false)
                StopAnimTask(playerPed, 'anim@move_m@prisoner_cuffed', 'walk', -8.0)
            end

            exports.qbx_core:Notify('Đã thả hộ tống!', 'success')
        else
            -- Chưa hộ tống -> Bắt đầu hộ tống
            local closestPlayer, closestPed = lib.getClosestPlayer(coords, 2.5)

            if not closestPlayer or not closestPed then
                return exports.qbx_core:Notify('Không có người chơi gần để hộ tống!', 'error')
            end

            local playerId = GetPlayerServerId(closestPlayer)

            -- Kích hoạt escort
            TriggerServerEvent('police:server:EscortPlayer', playerId)
            exports.qbx_core:Notify('Đã bắt đầu hộ tống!', 'success')
        end
    end,
})-- Event để khôi phục trạng thái handcuff khi người chơi reconnect
RegisterNetEvent('police:client:RestoreHandcuffedState', function()
    -- Khôi phục trạng thái visual và controls cho người chơi bị còng tay
    if QBX.PlayerData.metadata.ishandcuffed then
        -- Đảm bảo người chơi không cầm vũ khí
        if cache.weapon ~= joaat('WEAPON_UNARMED') then
            SetCurrentPedWeapon(cache.ped, joaat('WEAPON_UNARMED'), true)
        end

        -- Tắt phone khi khôi phục trạng thái còng tay
        exports["lb-phone"]:ToggleDisabled(true)

        -- Đặt animation còng tay
        cuffType = 16 -- Mặc định là hard cuff
        ClearPedTasksImmediately(cache.ped)

        -- Tự động đặt IsEscorted = true khi khôi phục trạng thái còng tay
        IsEscorted = true
        TriggerEvent('hospital:client:isEscorted', IsEscorted)

        -- Thông báo cho người chơi
        exports.qbx_core:Notify(locale('info.cuff'), 'inform')
    end
end)

-- Ox_target cho bác sĩ vác xác
CreateThread(function()
    Wait(1000)

    local success, err = pcall(function()
        print('[qbx_police] Bắt đầu đăng ký ox_target...')

        -- Target cho player (vác xác và còng tay)
        exports.ox_target:addGlobalPlayer({
            {
                name = 'ambulance_carry_player',
                icon = 'fas fa-user-injured',
                label = 'Vác Xác',
                distance = 2.5,
                canInteract = function(entity, distance, coords, name, bone)
                    -- Không thể vác chính mình
                    if entity == cache.ped then return false end

                    -- Lấy dữ liệu player hiện tại (bác sĩ)
                    local playerData = exports.qbx_core:GetPlayerData()
                    if not playerData or not playerData.job then return false end

                    -- Kiểm tra job là ems và đang on duty
                    if playerData.job.type ~= 'ems' then return false end
                    if not playerData.job.onduty then return false end

                    -- Kiểm tra bác sĩ không bị còng tay hoặc đang bị hộ tống
                    if playerData.metadata.ishandcuffed or IsEscorted then return false end

                    -- Kiểm tra target player có phải là player thật không
                    if not IsPedAPlayer(entity) then return false end

                    return true
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)

                    if targetPlayerId ~= -1 then
                        local targetServerId = GetPlayerServerId(targetPlayerId)

                        -- Kiểm tra người chơi có đang chết hoặc bất tỉnh không
                        lib.callback('police:server:isPlayerDead', false, function(isDead)
                            if not isDead then
                                exports.qbx_core:Notify('Người chơi này chưa chết hoặc bất tỉnh!', 'error')
                                return
                            end

                            if not isCarrying and not IsEscorted then
                                TriggerServerEvent('ambulance:server:EscortPlayer', targetServerId)
                            else
                                exports.qbx_core:Notify('Bạn đang bận!', 'error')
                            end
                        end, targetServerId)
                    end
                end
            },
            {
                name = 'police_cuff_player',
                icon = 'fas fa-handcuffs',
                label = 'Còng Tay / Gỡ Còng',
                distance = 1.5,
                canInteract = function(entity, distance, coords, name, bone)
                    -- Không thể còng chính mình
                    if entity == cache.ped then return false end

                    if not QBX.PlayerData.job then return false end

                    -- Chỉ công an mới được còng tay
                    if not (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') then return false end
                    if not QBX.PlayerData.job.onduty then return false end

                    -- Không được ở trong xe
                    if cache.vehicle then return false end

                    -- Kiểm tra target có trong xe không
                    local targetPlayerId = NetworkGetPlayerIndexFromPed(entity)
                    if targetPlayerId == -1 then return false end

                    if IsPedInAnyVehicle(entity, false) then return false end

                    return true
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)

                    if targetPlayerId ~= -1 then
                        local targetServerId = GetPlayerServerId(targetPlayerId)
                        local targetPlayer = exports.qbx_core:GetPlayerData(targetServerId)

                        if targetPlayer and targetPlayer.metadata then
                            -- Kiểm tra xem target đã bị còng chưa
                            if targetPlayer.metadata.ishandcuffed then
                                -- Đã bị còng -> Gỡ còng
                                if lib.callback.await('police:server:CuffPlayer', false, targetServerId, false) then
                                    handCuffAnimation()
                                end
                            else
                                -- Chưa bị còng -> Còng tay
                                if exports.ox_inventory:Search('count', config.handcuffItems) == 0 then
                                    return exports.qbx_core:Notify(locale('error.no_cuff'), 'error')
                                end

                                if lib.callback.await('police:server:CuffPlayer', false, targetServerId, false) then
                                    handCuffAnimation()
                                end
                            end
                        end
                    end
                end
            },
            {
                name = 'police_search_player',
                icon = 'fas fa-search',
                label = 'Lục Soát',
                distance = 2.5,
                canInteract = function(entity, distance, coords, name, bone)
                    -- Không thể lục soát chính mình
                    if entity == cache.ped then return false end

                    if not QBX.PlayerData.job then return false end

                    -- Chỉ công an đang on duty mới được lục soát
                    if not (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') then return false end
                    if not QBX.PlayerData.job.onduty then return false end

                    return true
                end,
                onSelect = function(data)
                    local targetPed = data.entity
                    local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)

                    if targetPlayerId ~= -1 then
                        local targetServerId = GetPlayerServerId(targetPlayerId)

                        -- Sử dụng callback để kiểm tra trạng thái còng tay từ server
                        lib.callback('police:server:isPlayerHandcuffed', false, function(isHandcuffed)
                            if isHandcuffed then
                                -- Nếu bị còng thì lục soát trực tiếp
                                TriggerServerEvent('police:server:SearchPlayer', targetServerId)
                            else
                                -- Nếu không bị còng thì yêu cầu xác nhận từ người chơi
                                TriggerServerEvent('police:server:RequestSearchPermission', targetServerId)
                            end
                        end, targetServerId)
                    end
                end
            }
        })

        -- Target cho vehicle (lục soát cốp xe, đưa vào xe và kéo khỏi xe)
        exports.ox_target:addGlobalVehicle({
            {
                name = 'police_search_vehicle_trunk',
                icon = 'fas fa-box-open',
                label = 'Lục Soát Cốp Xe',
                distance = 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if not QBX.PlayerData.job then return false end

                    -- Chỉ công an đang on duty mới được lục soát cốp xe
                    if not (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') then return false end
                    if not QBX.PlayerData.job.onduty then return false end

                    -- Không được bị còng tay hoặc đang bị hộ tống
                    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return false end

                    return true
                end,
                onSelect = function(data)
                    local vehicle = data.entity
                    local plate = GetVehicleNumberPlateText(vehicle)
                    local netId = NetworkGetNetworkIdFromEntity(vehicle)

                    if plate and netId then
                        -- Trigger server event để lục soát cốp xe (gửi cả netId)
                        TriggerServerEvent('police:server:SearchVehicleTrunk', plate, netId)
                    else
                        exports.qbx_core:Notify('Không thể lấy biển số xe!', 'error')
                    end
                end
            },
            {
                name = 'police_put_in_vehicle',
                icon = 'fas fa-car-side',
                label = 'Đưa Người Vào Xe',
                distance = 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if not QBX.PlayerData.job then return false end

                    -- Kiểm tra là công an hoặc bác sĩ đang on duty
                    local isPolice = (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') and QBX.PlayerData.job.onduty
                    local isEMS = QBX.PlayerData.job.type == 'ems' and QBX.PlayerData.job.onduty

                    if not (isPolice or isEMS) then return false end

                    -- Không được bị còng tay hoặc đang bị hộ tống
                    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return false end

                    -- Kiểm tra có ai gần đó đang bị còng tay hoặc hộ tống không
                    local playerCoords = GetEntityCoords(cache.ped)
                    local closestPlayer, closestPed = lib.getClosestPlayer(playerCoords, 2.5)
                    if not closestPlayer then return false end

                    return true
                end,
                onSelect = function(data)
                    local playerCoords = GetEntityCoords(cache.ped)
                    local closestPlayer, closestPed = lib.getClosestPlayer(playerCoords, 2.5)

                    if closestPlayer and closestPed then
                        local targetServerId = GetPlayerServerId(closestPlayer)
                        TriggerServerEvent('ambulance:server:StopCarrying')
                        Wait(500) -- Đợi một chút để tránh xung đột trạng thái
                        TriggerServerEvent('police:server:PutPlayerInVehicle', targetServerId)
                    else
                        exports.qbx_core:Notify('Không có người chơi gần để đưa vào xe!', 'error')
                    end
                end
            },
            {
                name = 'police_set_out_vehicle',
                icon = 'fas fa-person-walking-arrow-right',
                label = 'Kéo Người Khỏi Xe',
                distance = 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    if not QBX.PlayerData.job then return false end

                    -- Kiểm tra là công an hoặc bác sĩ đang on duty
                    local isPolice = (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') and QBX.PlayerData.job.onduty
                    local isEMS = QBX.PlayerData.job.type == 'ems' and QBX.PlayerData.job.onduty

                    if not (isPolice or isEMS) then return false end

                    -- Không được bị còng tay hoặc đang bị hộ tống
                    if QBX.PlayerData.metadata.ishandcuffed or IsEscorted then return false end

                    -- Kiểm tra xe có người bên trong không
                    local maxSeats = GetVehicleMaxNumberOfPassengers(entity)
                    local hasPassenger = false
                    for i = -1, maxSeats do
                        if not IsVehicleSeatFree(entity, i) then
                            local ped = GetPedInVehicleSeat(entity, i)
                            if ped and ped ~= cache.ped then
                                hasPassenger = true
                                break
                            end
                        end
                    end

                    return hasPassenger
                end,
                onSelect = function(data)
                    local vehicle = data.entity
                    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)

                    -- Tìm người chơi gần nhất trong xe
                    local targetPed = nil
                    for i = -1, maxSeats do
                        if not IsVehicleSeatFree(vehicle, i) then
                            local ped = GetPedInVehicleSeat(vehicle, i)
                            if ped and ped ~= cache.ped then
                                targetPed = ped
                                break
                            end
                        end
                    end

                    if targetPed then
                        local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
                        if targetPlayerId ~= -1 then
                            local targetServerId = GetPlayerServerId(targetPlayerId)
                            
                            -- Kiểm tra job để gọi event tương ứng
                            local isEMS = QBX.PlayerData.job.type == 'ems'
                            
                            if isEMS then
                                -- EMS: Kéo ra và vác lên vai luôn
                                TriggerServerEvent('ambulance:server:SetPlayerOutVehicle', targetServerId)
                            else
                                -- Police: Kéo ra bình thường
                                TriggerServerEvent('police:server:SetPlayerOutVehicle', targetServerId)
                            end
                        end
                    else
                        exports.qbx_core:Notify('Không tìm thấy người chơi trong xe!', 'error')
                    end
                end
            }
        })

        -- Tạo ox_target box zone cho kho boss_police
        exports.ox_target:addBoxZone({
            coords = vec3(60.16, -415.93, 39.14),
            size = vec3(2.0, 2.0, 2.0),
            rotation = 0,
            debug = false,
            options = {
                {
                    name = 'boss_police_stash',
                    icon = 'fas fa-warehouse',
                    label = 'Mở Kho Thu Đồ',
                    distance = 2.5,
                    canInteract = function(entity, distance, coords, name, bone)
                        if not QBX.PlayerData.job then return false end

                        -- Chỉ công an mới được mở kho
                        if not (QBX.PlayerData.job.name == 'police' or QBX.PlayerData.job.name == 'sheriff') then return false end
                        if not QBX.PlayerData.job.onduty then return false end

                        return true
                    end,
                    onSelect = function()
                        TriggerServerEvent('police:server:OpenBossPoliceStash')
                    end
                }
            }
        })
    end)
end)
