local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentSelectedBag = nil

local tmpCamera = nil
local initialBagDrawable = nil
local initialBagTexture = nil
local initialBagPalette = nil
local initialPedHeading = nil
local currentCamFov = 48.0

-- Function để lấy giới tính từ ped model với error handling
local function getPlayerGender()
    local success, result = pcall(function()
        local ped = PlayerPedId()
        local pedModel = GetEntityModel(ped)
        local femalePedHash = GetHashKey("mp_f_freemode_01")
        
        if pedModel == femalePedHash then
            return "female"
        else
            return "male"
        end
    end)
    
    if success then
        return result
    else
        return "male"
    end
end

-- Lưu trạng thái ban đầu của ped (balo & heading)
local function saveInitialPedState()
    local playerPed = PlayerPedId()
    initialBagDrawable = GetPedDrawableVariation(playerPed, 5)
    initialBagTexture = GetPedTextureVariation(playerPed, 5)
    initialBagPalette = GetPedPaletteVariation(playerPed, 5)
    initialPedHeading = GetEntityHeading(playerPed)
end

-- Khôi phục trạng thái ban đầu của ped
local function restoreInitialPedState()
    local playerPed = PlayerPedId()
    if initialBagDrawable ~= nil then
        SetPedComponentVariation(playerPed, 5, initialBagDrawable, initialBagTexture or 0, initialBagPalette or 0)
    end
    if initialPedHeading ~= nil then
        SetEntityHeading(playerPed, initialPedHeading)
    end
end

-- Tạo Camera xem sau lưng Balo (căn giữa trong khung nhìn thoáng bên trái)
local function createCameraForBag()
    local playerPed = PlayerPedId()
    -- Offset X ~0.45 để nhân vật nằm cân đối ở giữa khung nhìn bên trái (khoảng 36-38% màn hình)
    local coords = vector3(0.48, -2.35, 0.26)
    local point = vector3(0.42, 0.0, 0.12)
    
    local camCoords = GetOffsetFromEntityInWorldCoords(playerPed, coords.x, coords.y, coords.z)
    local camPoint = GetOffsetFromEntityInWorldCoords(playerPed, point.x, point.y, point.z)
    
    currentCamFov = 43.0
    if tmpCamera then
        DestroyCam(tmpCamera, false)
        tmpCamera = nil
    end
    
    tmpCamera = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camCoords.x, camCoords.y, camCoords.z, 0.0, 0.0, 0.0, currentCamFov, false, 0)
    PointCamAtCoord(tmpCamera, camPoint.x, camPoint.y, camPoint.z)
    SetCamActive(tmpCamera, true)
    RenderScriptCams(true, true, 500, true, true)
end

-- Khôi phục Camera bình thường
local function restoreCamera()
    RenderScriptCams(false, true, 500, true, true)
    if tmpCamera then
        DestroyCam(tmpCamera, false)
        tmpCamera = nil
    end
end

-- Vòng lặp ánh sáng & điều khiển khi UI mở
local function startUIEnvironmentLoop()
    CreateThread(function()
        while isUIOpen do
            local playerPed = PlayerPedId()
            local pCoords = GetEntityCoords(playerPed)
            
            -- Đèn chiếu sáng studio xung quanh người và balo
            DrawLightWithRange(pCoords.x, pCoords.y, pCoords.z + 0.6, 255, 255, 255, 3.5, 1.2)
            
            -- Vô hiệu hóa điều khiển di chuyển trong khi xem
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 30, true)  -- MoveLeftRight
            DisableControlAction(0, 31, true)  -- MoveUpDown
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 23, true)  -- Enter vehicle
            DisableControlAction(0, 75, true)  -- Exit vehicle
            
            Wait(0)
        end
    end)
end

-- Mở UI
local function openUI()
    if isUIOpen then return end
    
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData then return end
    
    local playerPed = PlayerPedId()
    saveInitialPedState()
    FreezeEntityPosition(playerPed, true)
    createCameraForBag()
    
    local playerGender = getPlayerGender()
    
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:getBagData', function(bagData)
        if bagData then
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'openUI',
                data = bagData
            })
            isUIOpen = true
            startUIEnvironmentLoop()
        else
            FreezeEntityPosition(playerPed, false)
            restoreCamera()
        end
    end, playerGender)
end

-- Refresh bag data mà không check isUIOpen (dùng sau khi upgrade)
local function refreshBagData()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData then return end
    
    local playerGender = getPlayerGender()
    
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:getBagData', function(bagData)
        if bagData then
            SendNUIMessage({
                action = 'openUI',
                data = bagData
            })
        end
    end, playerGender)
end

-- Đóng UI
local function closeUI()
    if not isUIOpen then return end
    
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeUI'
    })
    isUIOpen = false
    currentSelectedBag = nil
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    restoreCamera()
    restoreInitialPedState()
    
    -- Reload lại trang phục từ hệ thống nếu có
    pcall(function()
        local currentGender = getPlayerGender()
        TriggerServerEvent('clothes:reloadPlayerClothes', currentGender)
    end)
end

-- Tạo URL ảnh cho balo
local function createBagImageURL(drawable, gender)
    gender = gender or "mp_m"
    local prefix = Config.ImageSettings.prefix
    local component = Config.componentMapping[Config.BagItem].component
    return string.format("%s%s%s%d_%d.webp", 
        Config.ImageSettings.base_url, 
        gender, 
        prefix, 
        component, 
        drawable
    )
end

-- ox_target setup
if Config.Target and Config.Target.enabled then
    exports.ox_target:addModel(Config.Target.model, {
        {
            name = 'thamdinh_balo',
            icon = 'fa-solid fa-suitcase',
            label = Config.Target.label,
            onSelect = function()
                openUI()
            end,
            distance = Config.Target.distance
        }
    })
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    closeUI()
    cb('ok')
end)

-- Preview balo trực tiếp lên người ped
RegisterNUICallback('previewBag', function(data, cb)
    local playerPed = PlayerPedId()
    local drawable = nil
    local texture = 0
    
    if type(data) == 'table' then
        drawable = data.drawable or (data.metadata and data.metadata.drawable)
        texture = data.texture or (data.metadata and data.metadata.texture) or 0
    elseif type(data) == 'number' or type(data) == 'string' then
        drawable = tonumber(data)
    end
    
    if drawable ~= nil then
        local drawNum = tonumber(drawable) or 0
        local texNum = tonumber(texture) or 0
        SetPedComponentVariation(playerPed, 5, drawNum, texNum, 0)
    end
    cb('ok')
end)

-- Xoay nhân vật hoặc điều chỉnh góc cam
RegisterNUICallback('rotatePed', function(data, cb)
    local playerPed = PlayerPedId()
    if data and data.headingDelta then
        local currentHeading = GetEntityHeading(playerPed)
        SetEntityHeading(playerPed, (currentHeading + tonumber(data.headingDelta)) % 360.0)
    elseif data and data.direction == 'left' then
        local currentHeading = GetEntityHeading(playerPed)
        SetEntityHeading(playerPed, (currentHeading - 15.0) % 360.0)
    elseif data and data.direction == 'right' then
        local currentHeading = GetEntityHeading(playerPed)
        SetEntityHeading(playerPed, (currentHeading + 15.0) % 360.0)
    elseif data and data.direction == 'toggleView' then
        local currentHeading = GetEntityHeading(playerPed)
        SetEntityHeading(playerPed, (currentHeading + 180.0) % 360.0)
    elseif data and data.direction == 'zoomIn' then
        if tmpCamera then
            currentCamFov = math.max(25.0, currentCamFov - 5.0)
            SetCamFov(tmpCamera, currentCamFov)
        end
    elseif data and data.direction == 'zoomOut' then
        if tmpCamera then
            currentCamFov = math.min(65.0, currentCamFov + 5.0)
            SetCamFov(tmpCamera, currentCamFov)
        end
    end
    cb('ok')
end)

-- Khôi phục balo ban đầu
RegisterNUICallback('resetPed', function(data, cb)
    restoreInitialPedState()
    cb('ok')
end)

RegisterNUICallback('selectBag', function(data, cb)
    local success, error_msg = pcall(function()
        currentSelectedBag = data.slot
        cb('ok')
        
        local bagSlot = data.slot
        local isCustom = data.isCustom or false
        if not bagSlot then
            SendNUIMessage({
                action = 'updateUpgradeOptions',
                upgradeOptions = {},
                canUpgrade = false,
                message = "Slot không hợp lệ"
            })
            return
        end
        
        local playerGender = getPlayerGender()
        
        QBCore.Functions.TriggerCallback('xn_thamdinhbalo:getUpgradeOptions', function(result)
            if result and result.canUpgrade then
                -- Tự động mặc mẫu balo đang chọn lên người ped
                if result.currentDrawable then
                    SetPedComponentVariation(PlayerPedId(), 5, tonumber(result.currentDrawable) or 0, 0, 0)
                end
                
                SendNUIMessage({
                    action = 'updateUpgradeOptions',
                    data = {
                        canUpgrade = true,
                        options = result.options,
                        coinCost = result.coinCost,
                        playerCoin = result.playerCoin,
                        appraisalCost = result.appraisalCost,
                        currentLevel = result.currentLevel,
                        currentDrawable = result.currentDrawable,
                        requirements = result.requirements,
                        gender = playerGender,
                        coinUpgradeEnabled = Config.CoinUpgrade.enabled
                    }
                })
            else
                SendNUIMessage({
                    action = 'updateUpgradeOptions',
                    data = {
                        canUpgrade = false,
                        options = {},
                        message = result and result.message or "Không thể trao đổi balo này"
                    }
                })
            end
        end, bagSlot, playerGender, isCustom)
    end)
    
    if not success then
        cb('error')
    end
end)

RegisterNUICallback('startAppraisal', function(data, cb)
    --print("Debug: startAppraisal callback called")
    --print("Debug: currentSelectedBag:", currentSelectedBag)
    
    if not currentSelectedBag then
        --print("Debug: No bag selected")
        -- lib.notify({
        --     title = 'Lỗi',
        --     description = 'Vui lòng chọn một chiếc balo trước',
        --     type = 'error'
        -- })
        cb('error')
        return
    end
    
    cb('ok')
    
    --print("Debug: Starting appraisal for slot:", currentSelectedBag)
    
    -- Lấy gender từ ped
    local playerGender = getPlayerGender()
    --print("Debug Client: Player gender for startAppraisal:", playerGender)
    
    -- Gửi yêu cầu trao đổi lên server
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:startAppraisal', function(result)
        if result.success then
            -- Gửi message startShuffling kèm finalDrawable thực tế để vòng quay nhắm đúng vật phẩm
            SendNUIMessage({
                action = 'startShuffling',
                finalDrawable = result.newDrawable
            })
            
            -- Shuffle trong 3 giây trước khi hiển thị kết quả
            local shuffleTime = 3000 -- 3 giây
            SetTimeout(shuffleTime, function()
                SendNUIMessage({
                    action = 'showResult',
                    result = result
                })
            end)
        else
            -- Dừng shuffle ngay lập tức khi có lỗi
            SendNUIMessage({
                action = 'stopShuffling'
            })
            
            -- Hiện thông báo lỗi
            lib.notify({
                title = 'Lỗi trao đổi',
                description = result.message or 'Có lỗi xảy ra',
                type = 'error'
            })
        end
        cb('ok')
    end, currentSelectedBag, playerGender) -- Truyền gender cho server
end)

RegisterNUICallback('startCoinUpgrade', function(data, cb)
    --print("Debug: startCoinUpgrade callback called")
    --print("Debug: currentSelectedBag:", currentSelectedBag)
    
    if not currentSelectedBag then
        --print("Debug: No bag selected")
        cb('error')
        return
    end
    
    cb('ok')
    
    --print("Debug: Starting coin upgrade countdown for slot:", currentSelectedBag)
    
    -- Bắt đầu countdown
    SendNUIMessage({
        action = 'startCoinCountdown',
        countdown = Config.CoinUpgrade.countdown_time or 3
    })
end)

RegisterNUICallback('executeCoinUpgrade', function(data, cb)
    --print("Debug: executeCoinUpgrade callback called")
    --print("Debug: currentSelectedBag:", currentSelectedBag)
    
    if not currentSelectedBag then
        --print("Debug: No bag selected")
        cb('error')
        return
    end
    
    cb('ok')
    
    --print("Debug: Executing coin upgrade for slot:", currentSelectedBag)
    
    -- Lấy gender từ ped
    local playerGender = getPlayerGender()
    --print("Debug Client: Player gender for coinUpgrade:", playerGender)
    
    -- Gửi yêu cầu trao đổi bằng coin lên server
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:coinUpgrade', function(result)
        if result.success then
            SendNUIMessage({
                action = 'startShuffling',
                finalDrawable = result.newDrawable
            })
            
            -- Shuffle trong 3 giây trước khi hiển thị kết quả
            local shuffleTime = 3000 -- 3 giây
            SetTimeout(shuffleTime, function()
                -- Hiển thị kết quả thành công sau shuffle
                SendNUIMessage({
                    action = 'showResult',
                    result = {
                        success = true,
                        title = 'Trao Đổi Thành Công!',
                        message = result.message,
                        newDrawable = result.newDrawable,
                        newType = result.newType,
                        newRarity = result.newRarity,
                        newLevel = result.newLevel,
                        playerGender = getPlayerGender(),
                        oldMetadata = result.oldMetadata,
                        upgradeType = 'coin',
                        gender = result.gender or playerGender,
                        slot = result.slot
                    }
                })
            end)
        else
            SendNUIMessage({
                action = 'stopShuffling'
            })
            
            lib.notify({
                title = 'Lỗi trao đổi',
                description = result.message or 'Không thể trao đổi bằng coin',
                type = 'error'
            })
        end
        cb('ok')
    end, currentSelectedBag, playerGender) -- Truyền gender cho server
end)

RegisterNUICallback('confirmAppraisal', function(data, cb)
    --print("Debug: confirmAppraisal callback called from NUI")
    
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:confirmAppraisal', function(result)
        if result and result.success then
            --print("Debug: Confirm appraisal successful:", result.message)
            cb({success = true, message = result.message})
        else
            --print("Debug: Confirm appraisal failed:", result.message or "Unknown error")
            cb({success = false, message = result.message or "Không thể thêm balo mới"})
        end
    end, data)
end)

RegisterNUICallback('confirmCoinUpgrade', function(data, cb)
    --print("Debug: confirmCoinUpgrade callback called from NUI")
    
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:confirmCoinUpgrade', function(result)
        if result and result.success then
            --print("Debug: Confirm coin upgrade successful:", result.message)
            cb({success = true, message = result.message})
        else
            --print("Debug: Confirm coin upgrade failed:", result.message or "Unknown error")
            cb({success = false, message = result.message or "Không thể thêm balo mới"})
        end
    end, data)
end)

RegisterNUICallback('claimCustomBag', function(data, cb)
    if not currentSelectedBag then
        cb({success = false, message = 'Vui lòng chọn một chiếc balo trước'})
        return
    end
    
    local targetDrawable = data.targetDrawable
    if not targetDrawable then
        cb({success = false, message = 'Vui lòng chọn mẫu balo mong muốn'})
        return
    end
    
    local playerGender = getPlayerGender()
    
    QBCore.Functions.TriggerCallback('xn_thamdinhbalo:claimCustomBag', function(result)
        if result and result.success then
            SendNUIMessage({
                action = 'customExchangeSuccess'
            })
            lib.notify({
                title = 'Đổi mẫu balo',
                description = result.message,
                type = 'success'
            })
        else
            lib.notify({
                title = 'Đổi mẫu balo',
                description = result and result.message or 'Có lỗi xảy ra',
                type = 'error'
            })
        end
        cb(result)
    end, currentSelectedBag, targetDrawable, playerGender)
end)


RegisterNUICallback('refreshUI', function(data, cb)
    --print("Debug: refreshUI callback called")
    cb('ok')
    
    -- Refresh bag list với delay để đảm bảo inventory đã cập nhật
    SetTimeout(200, function() -- Tăng delay lên 200ms
        refreshBagData()
    end)
end)

RegisterNUICallback('getBagImage', function(data, cb)
    local gender = getPlayerGender()
    local imageUrl = createBagImageURL(data.drawable, gender)
    cb(imageUrl)
end)

-- Event để debug gender detection
RegisterNetEvent('xn_thamdinhbalo:debugGender')
AddEventHandler('xn_thamdinhbalo:debugGender', function()
    local gender = getPlayerGender()
    local pedModel = GetEntityModel(PlayerPedId())
    
    --print("=== CLIENT DEBUG GENDER ===")
    --print("Detected gender:", gender)
    --print("Ped model:", pedModel)
    --print("Female hash:", GetHashKey("mp_f_freemode_01"))
    --print("Male hash:", GetHashKey("mp_m_freemode_01"))
    
    -- Send back to server for verification
    TriggerServerEvent('xn_thamdinhbalo:debugGenderResult', gender, pedModel)
end)

-- Event để test gender detection
RegisterNetEvent('xn_thamdinhbalo:testGender')
AddEventHandler('xn_thamdinhbalo:testGender', function()
    local gender = getPlayerGender()
    --print("=== GENDER TEST FROM CLIENT ===")
    --print("Detected gender:", gender)
    --print("Ped model:", GetEntityModel(PlayerPedId()))
    --print("Female hash:", GetHashKey("mp_f_freemode_01"))
    --print("Male hash:", GetHashKey("mp_m_freemode_01"))
    
    -- Send back to server for verification
    TriggerServerEvent('xn_thamdinhbalo:testGenderResult', gender)
end)

-- Export functions
exports('openUI', openUI)
exports('closeUI', closeUI)

-- Cleanup ox_target khi resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        exports.ox_target:removeModel(Config.Target.model, 'thamdinh_balo')
        --print("Debug: ox_target cleaned up for:", Config.Target.model)
    end
end)
