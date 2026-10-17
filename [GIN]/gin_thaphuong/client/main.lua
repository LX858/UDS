local isPraying = false

-- Helper vẽ chữ 3D trên màn hình
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 215, 0, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Helper load Animation Dictionary
local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Citizen.Wait(50)
            timeout = timeout + 1
        end
    end
    return HasAnimDictLoaded(dict)
end

-- Helper load Prop Model
local function LoadModel(model)
    local modelHash = type(model) == 'number' and model or GetHashKey(model)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 100 do
            Citizen.Wait(50)
            timeout = timeout + 1
        end
    end
    return HasModelLoaded(modelHash)
end

-- Prop object tracker & helpers
local incenseObj = nil
local testPropObj = nil

local function DeleteIncenseProp()
    if incenseObj and DoesEntityExist(incenseObj) then
        DeleteEntity(incenseObj)
        incenseObj = nil
    end
end
local function CreateIncenseProp(playerPed, itemType)
    DeleteIncenseProp()

    local incenseConfig = Config.IncenseTypes and Config.IncenseTypes[itemType or Config.DefaultIncenseType or 'cay_huong']
    local model = incenseConfig and incenseConfig.propModel or Config.IncensePropModel or `jr_nhanhuonglv1`
    if not model then return nil end

    local modelHash = type(model) == 'number' and model or GetHashKey(model)
    if LoadModel(modelHash) then
        local pCoords = GetEntityCoords(playerPed)
        incenseObj = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
        if DoesEntityExist(incenseObj) then
            local bone = Config.IncenseBone or 57005
            local boneIndex = GetPedBoneIndex(playerPed, bone)
            
            local off = Config.IncenseOffset or vector3(0.12, 0.02, -0.02)
            local rot = Config.IncenseRotation or vector3(-90.0, 0.0, 0.0)
            
            AttachEntityToEntity(
                incenseObj, playerPed, boneIndex,
                off.x, off.y, off.z,
                rot.x, rot.y, rot.z,
                true, true, false, true, 1, true
            )
        end
    end
    return incenseObj
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteIncenseProp()
        if testPropObj and DoesEntityExist(testPropObj) then
            DeleteEntity(testPropObj)
            testPropObj = nil
        end
    end
end)

-- Helper load PTFX Asset
local function LoadPtfxAsset(asset)
    if not HasNamedPtfxAssetLoaded(asset) then
        RequestNamedPtfxAsset(asset)
        local timeout = 0
        while not HasNamedPtfxAssetLoaded(asset) and timeout < 100 do
            Citizen.Wait(50)
            timeout = timeout + 1
        end
    end
    return HasNamedPtfxAssetLoaded(asset)
end

-- Helper set PTFX Asset Next Call compatibility
local function SetPtfxAssetNext(asset)
    if UseParticleFxAssetNextParam then
        UseParticleFxAssetNextParam(asset)
    elseif UseParticleFxAsset then
        UseParticleFxAsset(asset)
    elseif SetPtfxAssetNextCall then
        SetPtfxAssetNextCall(asset)
    end
end

-- Thread chính xử lý Marker và tương tác tại vị trí gần nhất
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        
        if not isPraying and DoesEntityExist(playerPed) and not IsPedInAnyVehicle(playerPed, false) then
            local pCoords = GetEntityCoords(playerPed)
            local locations = Config.Locations or {
                { prayPos = Config.PrayPosition, burnerPos = Config.IncenseBurnerPosition }
            }

            local closestLoc = nil
            local closestIdx = 1
            local minDist = 999.0

            for idx, loc in ipairs(locations) do
                local prayPos = loc.prayPos
                local dist = #(pCoords - vector3(prayPos.x, prayPos.y, prayPos.z))

                if dist <= 10.0 then
                    sleep = 0
                    -- Vẽ marker ở tất cả các vị trí quỳ vái lạy
                    DrawMarker(2, prayPos.x, prayPos.y, prayPos.z + 0.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.3, 0.3, 0.3, 212, 175, 55, 180, false, true, 2, false, nil, nil, false)
                end

                if dist < minDist then
                    minDist = dist
                    closestLoc = loc
                    closestIdx = idx
                end
            end

            -- Chỉ hiển thị chữ tương tác và nhận nút bấm ở vị trí GẦN NHẤT với người chơi
            if closestLoc and minDist <= Config.InteractDistance then
                sleep = 0
                local prayPos = closestLoc.prayPos
                DrawText3D(prayPos.x, prayPos.y, prayPos.z + 0.5, Config.InteractKeyLabel)
                
                if IsControlJustReleased(0, Config.InteractKey) then
                    if Config.RequireItem then
                        TriggerServerEvent('gin_thaphuong:server:requestPray', closestIdx)
                    else
                        StartPrayingSequence(closestLoc, Config.DefaultIncenseType)
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Quy trình thực hiện vái lạy và thắp hương tại đúng vị trí được chọn (Progress bar xuyên suốt toàn bộ tiến trình)
function StartPrayingSequence(location, itemType)
    local playerPed = PlayerPedId()
    if isPraying or IsPedInAnyVehicle(playerPed, false) or not location then return end

    isPraying = true
    itemType = itemType or Config.DefaultIncenseType or 'cay_huong'

    local prayPos = location.prayPos
    local burnerPos = location.burnerPos

    -- Tính tổng thời gian toàn bộ quy trình: Vái lạy + Đứng dậy + Đi bộ sang lu + Thắp hương ở lu
    local prayDurationMs = Config.PrayDuration * 1000
    local standUpTimeMs = 800
    local walkTimeMs = 2000
    local thapHuongDurationMs = Config.ThapHuongDuration or 4000

    local totalDurationMs = prayDurationMs + standUpTimeMs + walkTimeMs + thapHuongDurationMs

    -- 1. Phát âm thanh nhạc hương chùa & Thanh Progress Bar chạy TOÀN BỘ TIẾN TRÌNH
    SendNUIMessage({
        action = "startPray",
        duration = totalDurationMs,
        volume = Config.SoundVolume
    })

    -- Xóa task cũ và ép hướng người chơi quay ĐÚNG 100% HƯỚNG COORD ĐÃ LÀM SẴN (prayPos.w)
    ClearPedTasks(playerPed)
    SetEntityHeading(playerPed, prayPos.w)
    Citizen.Wait(100)

    -- Tạo prop Cây Hương tương ứng cầm trên tay nhân vật ngay khi bắt đầu vái
    CreateIncenseProp(playerPed, itemType)

    local pCoords = GetEntityCoords(playerPed)

    -- 2. Bật Scenario Quỳ vái lạy tại chỗ nhưng BẮT BUỘC QUAY ĐÚNG HƯỚNG prayPos.w
    if Config.YogaScenario and Config.YogaScenario ~= '' then
        TaskStartScenarioAtPosition(playerPed, Config.YogaScenario, pCoords.x, pCoords.y, pCoords.z, prayPos.w, -1, false, false)
    else
        local animDict = Config.YogaAnimDict
        local animName = Config.YogaAnimName
        if LoadAnimDict(animDict) then
            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    -- Kiểm tra dự phòng nếu chưa vái thì kích hoạt anim dict ngay tại chỗ (quay đúng hướng prayPos.w)
    Citizen.Wait(150)
    if not IsPedUsingScenario(playerPed, Config.YogaScenario) and not IsEntityPlayingAnim(playerPed, Config.YogaAnimDict, Config.YogaAnimName, 3) then
        SetEntityHeading(playerPed, prayPos.w)
        local animDict = Config.YogaAnimDict or 'amb@world_human_yoga@female@base'
        local animName = Config.YogaAnimName or 'yoga_pose1'
        if LoadAnimDict(animDict) then
            TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end

    -- Khóa di chuyển trong thời gian vái lạy
    local startTime = GetGameTimer()

    while (GetGameTimer() - startTime) < prayDurationMs do
        Citizen.Wait(0)
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true) -- Camera Look LR
        EnableControlAction(0, 2, true) -- Camera Look UD
        
        if IsEntityDead(playerPed) then
            SendNUIMessage({ action = "stopPray" })
            ClearPedTasks(playerPed)
            DeleteIncenseProp()
            isPraying = false
            return
        end
    end

    -- Xóa task vái lạy mượt mà (không dừng NUI)
    ClearPedTasks(playerPed)
    Citizen.Wait(standUpTimeMs) -- Chờ nhân vật đứng dậy tự nhiên

    -- 3. Cho nhân vật bước đi bộ tự nhiên mượt mà sang vị trí Lu Hương
    TaskGoStraightToCoord(playerPed, burnerPos.x, burnerPos.y, burnerPos.z, 1.0, 3000, burnerPos.w, 0.2)

    local walkStartTime = GetGameTimer()
    while #(GetEntityCoords(playerPed) - vector3(burnerPos.x, burnerPos.y, burnerPos.z)) > 0.35 and (GetGameTimer() - walkStartTime) < walkTimeMs do
        Citizen.Wait(50)
        if IsEntityDead(playerPed) then
            SendNUIMessage({ action = "stopPray" })
            ClearPedTasks(playerPed)
            DeleteIncenseProp()
            isPraying = false
            return
        end
    end

    Citizen.Wait(200)

    -- 4. Play Animation Thắp Hương mượt mà
    if LoadAnimDict(Config.ThapHuongAnimDict) then
        TaskPlayAnim(playerPed, Config.ThapHuongAnimDict, Config.ThapHuongAnimName, 2.0, -2.0, thapHuongDurationMs, 1, 0, false, false, false)
    end

    -- 5. Tạo Hiệu ứng khói/pháo sáng nghi ngút ở tường lu hương tương ứng (Particle Effect)
    local ptfxHandle = nil
    local effPos = location.ptfxPos or vector4(burnerPos.x, burnerPos.y, burnerPos.z + 0.3, burnerPos.w)

    if Config.EnableSmokeEffect and LoadPtfxAsset(Config.SmokePtfxAsset) then
        SetPtfxAssetNext(Config.SmokePtfxAsset)
        ptfxHandle = StartParticleFxLoopedAtCoord(
            Config.SmokePtfxName,
            effPos.x, effPos.y, effPos.z,
            0.0, 0.0, 0.0,
            0.5, false, false, false, false
        )
    end

    -- Đợi hoàn thành động tác thắp hương ở lu
    local incenseStartTime = GetGameTimer()
    while (GetGameTimer() - incenseStartTime) < thapHuongDurationMs do
        Citizen.Wait(50)
        if IsEntityDead(playerPed) then
            DeleteIncenseProp()
            if ptfxHandle then StopParticleFxLooped(ptfxHandle, false) end
            SendNUIMessage({ action = "stopPray" })
            ClearPedTasks(playerPed)
            isPraying = false
            return
        end
    end

    -- Dọn dẹp prop Cây Hương & ptfx sau khi hoàn tất vái lạy & thắp hương
    DeleteIncenseProp()
    if ptfxHandle then
        StopParticleFxLooped(ptfxHandle, false)
    end

    -- 6. Hoàn thành TOÀN BỘ tiến trình -> Dừng Progress Bar & Nhạc NUI
    SendNUIMessage({ action = "stopPray" })

    ClearPedTasks(playerPed)
    Config.Notify("Bạn đã hoàn thành vái lạy và thắp hương thành công!", "success")

    -- Gửi sự kiện lên Server để cộng điểm uy tín & trừ item
    TriggerServerEvent('gin_thaphuong:server:completeThapHuong', itemType)
    isPraying = false
end

-- Nhận lệnh bắt đầu thắp hương sau khi server xác nhận đủ vật phẩm
RegisterNetEvent('gin_thaphuong:client:startPray', function(locationIdx, itemType)
    local locations = Config.Locations or {}
    local loc = locations[locationIdx] or locations[1]
    if loc then
        StartPrayingSequence(loc, itemType)
    end
end)

-- Sử dụng Cây Hương trực tiếp từ túi đồ (Usable Item)
RegisterNetEvent('gin_thaphuong:client:useIncenseItem', function(itemType)
    local playerPed = PlayerPedId()
    if isPraying or IsPedInAnyVehicle(playerPed, false) then return end

    itemType = itemType or Config.DefaultIncenseType or 'cay_huong'

    local pCoords = GetEntityCoords(playerPed)
    local locations = Config.Locations or {}
    local closestLoc = nil
    local closestIdx = 1
    local minDist = 999.0

    for idx, loc in ipairs(locations) do
        local prayPos = loc.prayPos
        local dist = #(pCoords - vector3(prayPos.x, prayPos.y, prayPos.z))
        if dist < minDist then
            minDist = dist
            closestLoc = loc
            closestIdx = idx
        end
    end

    if closestLoc and minDist <= (Config.InteractDistance or 3.0) then
        if Config.RequireItem then
            TriggerServerEvent('gin_thaphuong:server:requestPray', closestIdx, itemType)
        else
            StartPrayingSequence(closestLoc, itemType)
        end
    else
        TriggerEvent('ox_lib:notify', {
            title = 'Thắp hương',
            description = 'Bạn phải đứng gần lu hương ở chùa mới có thể thắp hương!',
            type = 'error'
        })
    end
end)

-- Mở menu lựa chọn nén hương khi người chơi có nhiều hơn 1 loại hương trong túi
RegisterNetEvent('gin_thaphuong:client:openIncenseMenu', function(locationIdx, availableItems)
    if lib and lib.registerContext and lib.showContext then
        local options = {}
        for _, itemData in ipairs(availableItems) do
            table.insert(options, {
                title = itemData.label,
                description = string.format('Thắp %s (+%s điểm uy tín)', itemData.label, itemData.rep),
                onSelect = function()
                    TriggerServerEvent('gin_thaphuong:server:requestPray', locationIdx, itemData.name)
                end
            })
        end

        lib.registerContext({
            id = 'gin_thaphuong_select_menu',
            title = 'Chọn loại thắp hương',
            options = options
        })

        lib.showContext('gin_thaphuong_select_menu')
    else
        TriggerServerEvent('gin_thaphuong:server:requestPray', locationIdx, availableItems[1].name)
    end
end)

-- Lệnh test xem trước prop cây hương cầm trên tay & animation vái lạy (gõ /testhuong [cay_huong|cay_huong_luxury] để bật/tắt)
RegisterCommand('testhuong', function(source, args)
    local playerPed = PlayerPedId()

    if testPropObj and DoesEntityExist(testPropObj) then
        DeleteEntity(testPropObj)
        testPropObj = nil
        ClearPedTasks(playerPed)
        Config.Notify("Đã xóa prop cây hương xem trước.", "info")
    else
        local itemType = args[1] or 'cay_huong'
        local incenseConfig = Config.IncenseTypes and Config.IncenseTypes[itemType] or Config.IncenseTypes['cay_huong']
        local model = incenseConfig and incenseConfig.propModel or Config.IncensePropModel or `jr_nhanhuonglv1`
        local modelHash = type(model) == 'number' and model or GetHashKey(model)

        if LoadModel(modelHash) then
            local pCoords = GetEntityCoords(playerPed)
            testPropObj = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
            if DoesEntityExist(testPropObj) then
                local bone = Config.IncenseBone or 57005
                local boneIndex = GetPedBoneIndex(playerPed, bone)

                local off = Config.IncenseOffset or vector3(0.12, 0.02, -0.02)
                local rot = Config.IncenseRotation or vector3(-90.0, 0.0, 0.0)

                AttachEntityToEntity(
                    testPropObj, playerPed, boneIndex,
                    off.x, off.y, off.z,
                    rot.x, rot.y, rot.z,
                    true, true, false, true, 1, true
                )

                -- Phát thử animation vái lạy để kiểm tra hướng cầm của cây hương
                local animDict = Config.YogaAnimDict or 'amb@world_human_yoga@female@base'
                local animName = Config.YogaAnimName or 'yoga_pose1'
                if LoadAnimDict(animDict) then
                    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                end

                Config.Notify("Đã spawn prop cây hương xem trước: " .. (incenseConfig and incenseConfig.label or itemType) .. " (gõ /testhuong để xóa)", "success")
            end
        else
            Config.Notify("Không thể load model prop: " .. tostring(model), "error")
        end
    end
end, false)

