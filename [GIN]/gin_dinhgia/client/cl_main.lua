local isUIOpen = false
local isProcessing = false
local tableEntity = nil
local mapBlip = nil
local radiusBlip = nil

-- Khởi tạo Blip và Vùng đỏ (Radius) trên bản đồ
CreateThread(function()
    if Config.Blip and Config.Blip.enabled then
        local loc = Config.Location
        
        -- Tạo Vùng đỏ (Radius Circle) trên bản đồ
        if Config.Blip.showRadius then
            radiusBlip = AddBlipForRadius(loc.x, loc.y, loc.z, Config.Blip.radius or 25.0)
            SetBlipColour(radiusBlip, Config.Blip.radiusColor or 1)
            SetBlipAlpha(radiusBlip, Config.Blip.radiusAlpha or 120)
        end

        -- Tạo Icon Blip chính
        mapBlip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(mapBlip, Config.Blip.sprite or 500)
        SetBlipDisplay(mapBlip, Config.Blip.display or 4)
        SetBlipScale(mapBlip, Config.Blip.scale or 0.8)
        SetBlipColour(mapBlip, Config.Blip.color or 1)
        SetBlipAsShortRange(mapBlip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(Config.Blip.name or "Bàn Định Giá & Quy Đổi")
        EndTextCommandSetBlipName(mapBlip)
    end
end)

-- Spawning Prop cái bàn và khởi tạo ox_target
CreateThread(function()
    local loc = Config.Location
    
    if Config.SpawnProp and Config.PropModel then
        lib.requestModel(Config.PropModel)
        tableEntity = CreateObject(Config.PropModel, loc.x, loc.y, loc.z - 1.0, false, false, false)
        SetEntityHeading(tableEntity, loc.w or 0.0)
        FreezeEntityPosition(tableEntity, true)
        SetEntityAsMissionEntity(tableEntity, true, true)

        -- Ox target trên Prop
        exports.ox_target:addLocalEntity(tableEntity, {
            {
                name = 'gin_dinhgia_target',
                icon = 'fas fa-coins',
                label = 'Định Giá & Quy Đổi Vật Phẩm',
                distance = 2.5,
                onSelect = function()
                    OpenValuationUI()
                end
            }
        })
    else
        -- Ox target bằng Sphere Zone nếu không dùng Prop
        exports.ox_target:addSphereZone({
            coords = vec3(loc.x, loc.y, loc.z),
            radius = Config.Zone.radius,
            debug = false,
            options = {
                {
                    name = 'gin_dinhgia_zone_target',
                    icon = 'fas fa-coins',
                    label = 'Định Giá & Quy Đổi Vật Phẩm',
                    onSelect = function()
                        OpenValuationUI()
                    end
                }
            }
        })
    end
end)

-- Vẽ Red Zone tại điểm quy đổi (Tối ưu Resmon CPU 0.00ms)
CreateThread(function()
    if not Config.Zone or not Config.Zone.drawMarker then return end

    local loc = vec3(Config.Location.x, Config.Location.y, Config.Location.z)
    local zPos = loc.z - 1.0
    local diameter = (Config.Zone.radius or 1.8) * 2.0
    local height = Config.Zone.height or 0.6
    local r = Config.Zone.color and Config.Zone.color.r or 220
    local g = Config.Zone.color and Config.Zone.color.g or 38
    local b = Config.Zone.color and Config.Zone.color.b or 38
    local a = Config.Zone.color and Config.Zone.color.a or 140
    local markerType = Config.Zone.markerType or 1

    while true do
        local sleep = 1000
        local pCoords = GetEntityCoords(PlayerPedId())
        local dist = #(pCoords - loc)

        if dist < 12.0 then
            sleep = 0
            DrawMarker(
                markerType, 
                loc.x, loc.y, zPos, 
                0.0, 0.0, 0.0, 
                0.0, 0.0, 0.0, 
                diameter, diameter, height, 
                r, g, b, a, 
                false, false, 2, false, nil, nil, false
            )
        else
            sleep = math.min(2000, math.floor(dist * 50))
        end
        Wait(sleep)
    end
end)

-- Mở UI Định giá & Quy đổi
function OpenValuationUI()
    if isUIOpen then
        CloseUI()
        Wait(100)
    end

    -- Yêu cầu lock từ server và kiểm tra khung giờ đồng bộ
    local locked, msg, currentMode = lib.callback.await('gin_dinhgia:server:requestLock', false)
    if not locked then
        lib.notify({
            title = 'Bàn Định Giá & Rửa',
            description = msg or 'Khu vực hiện đang đóng cửa hoặc có người sử dụng!',
            type = 'error'
        })
        return
    end

    -- Lấy danh sách item hợp lệ trong túi đồ và thời gian đổi giá tiếp theo
    local res = lib.callback.await('gin_dinhgia:server:getPlayerItems', false) or {}
    local items = res.items or (type(res) == 'table' and res or {})
    local nextUpdateIn = res.nextUpdateIn or 0
    local dynamicEnabled = res.dynamicEnabled
    local serverMode = res.currentMode or currentMode or 'washing'

    isUIOpen = true
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openUI',
        items = items,
        nextUpdateIn = nextUpdateIn,
        dynamicEnabled = dynamicEnabled,
        currentMode = serverMode,
        timeRestrictions = {
            enabled = Config.TimeRestrictions and Config.TimeRestrictions.enabled,
            appraisalLabel = Config.TimeRestrictions and Config.TimeRestrictions.appraisal and Config.TimeRestrictions.appraisal.label or '14:00 - 15:00',
            washingLabel = Config.TimeRestrictions and Config.TimeRestrictions.washing and Config.TimeRestrictions.washing.label or '20:00 - 23:00'
        },
        config = {
            minItems = Config.MinItems,
            maxItems = Config.MaxItems,
            totalSlots = Config.TotalSlots,
            processTime = Config.ProcessTime,
            showRealPayoutPreview = Config.ShowRealPayoutPreview,
            showPriceTrend = Config.ShowPriceTrend,
            minPayoutPercent = Config.MinPayoutPercent,
            maxPayoutPercent = Config.MaxPayoutPercent,
            itemImagePath = Config.ItemImagePath
        }
    })
end

-- Lắng nghe sự kiện từ Server khi tỷ giá tự động cập nhật
RegisterNetEvent('gin_dinhgia:client:onPricesUpdated', function()
    if isUIOpen and not isProcessing then
        local res = lib.callback.await('gin_dinhgia:server:getPlayerItems', false) or {}
        local items = res.items or {}
        local nextUpdateIn = res.nextUpdateIn or 0
        local dynamicEnabled = res.dynamicEnabled

        SendNUIMessage({
            action = 'updatePrices',
            items = items,
            nextUpdateIn = nextUpdateIn,
            dynamicEnabled = dynamicEnabled
        })
    end
end)

-- Khóa/Mở khóa trạng thái túi đồ ox_inventory
local function SetInventoryBusy(busy)
    LocalPlayer.state:set('invBusy', busy, true)
    if busy then
        if exports.ox_inventory and exports.ox_inventory.closeInventory then
            pcall(function()
                exports.ox_inventory:closeInventory()
            end)
        end
    end
end

local processStartHealth = 0
local processStartArmour = 0
local processStartCoords = nil

-- Hàm ngắt tiến trình quy đổi khi bị tác động từ bên ngoài
local function InterruptProcessing(reason)
    if not isProcessing then return end
    isProcessing = false

    local ped = PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    SetInventoryBusy(false)
    FreezeEntityPosition(ped, false)
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)

    -- Đóng toàn bộ UI NUI và hủy bỏ progressbar
    CloseUI()

    lib.notify({
        title = 'Bàn Quy Đổi',
        description = reason or 'Tiến trình quy đổi đã bị hủy do bị người khác hoặc ngoại cảnh tác động!',
        type = 'error'
    })
end

-- Bắt sự kiện sát thương từ Game Engine (Cực nhanh và chuẩn xác)
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' and isProcessing then
        local victim = args[1]
        if victim == PlayerPedId() then
            InterruptProcessing('Tiến trình quy đổi bị hủy do bạn bị tấn công/chịu sát thương!')
        end
    end
end)

-- Vòng lặp khóa di chuyển, cấm mọi hành động & kiểm tra tương tác/tác động bên ngoài
CreateThread(function()
    while true do
        local sleep = 500
        if isProcessing then
            sleep = 0
            local ped = PlayerPedId()

            -- 1. KIỂM TRA MỌI HÌNH THỨC TƯƠNG TÁC / TẤN CÔNG / TÔNG XE / VA CHẠM TỪ BÊN NGOÀI
            local currentHealth = GetEntityHealth(ped)
            local currentArmour = GetPedArmour(ped)
            local currentCoords = GetEntityCoords(ped)
            local dist = processStartCoords and #(currentCoords - processStartCoords) or 0.0

            local isInterrupted = false
            local reason = ""

            if IsPedDeadOrDying(ped, true) or currentHealth <= 0 then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bạn đã gục ngã!"
            elseif currentHealth < processStartHealth or currentArmour < processStartArmour then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị đánh/bắn hoặc chịu sát thương!"
            elseif HasEntityBeenDamagedByAnyPed(ped) or HasEntityBeenDamagedByAnyVehicle(ped) or HasEntityBeenDamagedByAnyObject(ped) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị tác động từ bên ngoài!"
            elseif IsPedRagdoll(ped) or IsPedGettingUp(ped) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị tông trúng hoặc té ngã!"
            elseif IsPedInMeleeCombat(ped) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị người khác cận chiến/đánh trúng!"
            elseif IsPedBeingStunned(ped) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị chích điện!"
            elseif IsPedCuffed(ped) or (LocalPlayer.state and (LocalPlayer.state.isCuffed or LocalPlayer.state.isCarried or LocalPlayer.state.isEscorted)) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị còng tay hoặc bế vác!"
            elseif IsEntityAttached(ped) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị người khác tương tác/lôi kéo!"
            elseif IsPedInAnyVehicle(ped, false) then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị đưa lên phương tiện!"
            elseif dist > 1.8 then
                isInterrupted = true
                reason = "Tiến trình bị hủy do bị tông/va chạm văng khỏi bàn!"
            end

            if isInterrupted then
                InterruptProcessing(reason)
            else
                SetNuiFocusKeepInput(true)

                -- Đảm bảo ox_inventory luôn ở trạng thái bận không thể mở
                LocalPlayer.state:set('invBusy', true, true)

                -- Cưỡng chế đóng ox_inventory nếu lỡ đang mở
                if exports.ox_inventory and exports.ox_inventory.closeInventory then
                    pcall(function()
                        exports.ox_inventory:closeInventory()
                    end)
                end

                -- Đảm bảo Animation nhân vật luôn phát khi đang trong quá trình quy đổi
                if Config.Animation and Config.Animation.enabled then
                    local dict = Config.Animation.dict or "anim@gangops@morgue@table@"
                    local anim = Config.Animation.anim or "player_search"
                    if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                        RequestAnimDict(dict)
                        if HasAnimDictLoaded(dict) then
                            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, Config.Animation.flag or 49, 0.0, false, false, false)
                        end
                    end
                end

                -- CHẶN TOÀN BỘ TẤT CẢ CONTROL TRÊN GAME (Không cho di chuyển, nhảy, cúi, đánh đấm...)
                DisableAllControlActions(0)

                -- BẬT LẠI DUY NHẤT CÁC PHÍM TÁC VỤ XOAY CHUỘT XEM XUNG QUANH (ẨN CON TRỎ CHUỘT)
                EnableControlAction(0, 1, true)   -- Look Left/Right
                EnableControlAction(0, 2, true)   -- Look Up/Down
                EnableControlAction(0, 4, true)   -- Look Left/Right
                EnableControlAction(0, 6, true)   -- Look Up/Down

                -- CẤM TRIỆT ĐỂ CHUỘT TRÁI, CHUỘT PHẢI VÀ CÁC PHÍM TẤN CÔNG / ĐÁNH ĐẤM / NGẮM BẮN
                DisableControlAction(0, 24, true)  -- Attack (Left Mouse)
                DisableControlAction(0, 25, true)  -- Aim (Right Mouse)
                DisableControlAction(0, 47, true)  -- Weapon Option
                DisableControlAction(0, 58, true)  -- Weapon Option
                DisableControlAction(0, 140, true) -- Melee Attack Light (R)
                DisableControlAction(0, 141, true) -- Melee Attack Heavy (Q)
                DisableControlAction(0, 142, true) -- Melee Attack Alternate (Left Mouse)
                DisableControlAction(0, 143, true) -- Melee Block (Space)
                DisableControlAction(0, 257, true) -- Attack 2
                DisableControlAction(0, 263, true) -- Melee Attack 1
                DisableControlAction(0, 264, true) -- Melee Attack 2
            end
        end
        Wait(sleep)
    end
end)

-- Callback NUI: Người chơi bấm XÁC NHẬN quy đổi
RegisterNUICallback('startProcess', function(data, cb)
    cb('ok')
    isProcessing = true
    SetInventoryBusy(true)

    -- Ẩn con trỏ chuột NUI hoàn toàn khi chạy progressbar
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)

    local ped = PlayerPedId()
    -- Ghi nhận trạng thái ban đầu để phát hiện va chạm/tấn công/tương tác
    processStartHealth = GetEntityHealth(ped)
    processStartArmour = GetPedArmour(ped)
    processStartCoords = GetEntityCoords(ped)
    ClearEntityLastDamageEntity(ped)

    -- Không dùng FreezeEntityPosition để GTA V không hủy Animation nhân vật
    FreezeEntityPosition(ped, false)

    if Config.Animation and Config.Animation.enabled then
        local dict = Config.Animation.dict or "anim@gangops@morgue@table@"
        local anim = Config.Animation.anim or "player_search"
        CreateThread(function()
            RequestAnimDict(dict)
            local attempts = 0
            while not HasAnimDictLoaded(dict) and attempts < 100 do
                Wait(10)
                attempts = attempts + 1
            end
            if HasAnimDictLoaded(dict) and isProcessing then
                TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, Config.Animation.flag or 49, 0.0, false, false, false)
            end
        end)
    end
end)

-- Callback NUI: Hoàn tất quá trình progressbar -> Chuẩn bị số tiền thực nhận và mở UI kết quả
RegisterNUICallback('completeExchange', function(data, cb)
    if not isProcessing then
        cb({ success = false, message = 'Tiến trình quy đổi đã bị hủy bỏ!' })
        return
    end
    local slotItems = data.slotItems
    local res = lib.callback.await('gin_dinhgia:server:prepareExchange', false, slotItems)

    local ped = PlayerPedId()
    isProcessing = false
    SetInventoryBusy(false)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    SetNuiFocusKeepInput(false)

    if res and res.success then
        -- Mở lại con trỏ chuột NUI để người chơi bấm nút XÁC NHẬN NHẬN TIỀN
        SetNuiFocus(true, true)
        cb({ success = true, amount = res.amount, slotItems = res.slotItems })
    else
        cb({ success = false, message = res and res.message or 'Có lỗi xảy ra khi quy đổi!' })
        lib.notify({
            title = 'Định Giá Vật Phẩm',
            description = res and res.message or 'Có lỗi xảy ra khi quy đổi!',
            type = 'error'
        })
        CloseUI()
    end
end)

-- Callback NUI: Người chơi nhấn XÁC NHẬN NHẬN TIỀN trên UI kết quả -> Mới nhận tiền vào túi đồ
RegisterNUICallback('claimReward', function(data, cb)
    local res = lib.callback.await('gin_dinhgia:server:claimReward', false)

    if res and res.success then
        cb({ success = true })
        lib.notify({
            title = 'Định Giá Vật Phẩm',
            description = res.message,
            type = 'success'
        })
    else
        cb({ success = false, message = res and res.message or 'Có lỗi xảy ra khi nhận tiền!' })
        lib.notify({
            title = 'Định Giá Vật Phẩm',
            description = res and res.message or 'Có lỗi xảy ra khi nhận tiền!',
            type = 'error'
        })
    end
    CloseUI()
end)

-- Callback NUI: Người chơi bấm Hủy Bỏ / Nút X
RegisterNUICallback('cancelProcess', function(data, cb)
    cb('ok')
    local ped = PlayerPedId()
    isProcessing = false
    SetInventoryBusy(false)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    SetNuiFocusKeepInput(false)
    lib.notify({
        title = 'Bàn Định Giá',
        description = 'Đã hủy bỏ quá trình định giá.',
        type = 'inform'
    })
    CloseUI()
end)

-- Callback NUI: Đóng UI
RegisterNUICallback('closeUI', function(data, cb)
    cb('ok')
    CloseUI()
end)

function CloseUI()
    local ped = PlayerPedId()
    isUIOpen = false
    isProcessing = false
    SetInventoryBusy(false)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    ClearEntityLastDamageEntity(ped)
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeUI' })
    TriggerServerEvent('gin_dinhgia:server:releaseLock')
end

-- Cleanup khi stop resource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetInventoryBusy(false)
    if mapBlip and DoesBlipExist(mapBlip) then RemoveBlip(mapBlip) end
    if radiusBlip and DoesBlipExist(radiusBlip) then RemoveBlip(radiusBlip) end
    if tableEntity and DoesEntityExist(tableEntity) then
        DeleteEntity(tableEntity)
    end
    if isUIOpen then
        CloseUI()
    end
end)
