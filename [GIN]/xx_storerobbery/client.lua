local QBCore = exports['qb-core']:GetCoreObject()

local shops = {
    [1] = {
        ["basic_kasa"] = vector3(373.49, 328.49, 103.37),
        ["hard_kasa"] = vector3(378.21, 333.79, 103.57),
        ["pc_kasa"] = vector3(379.4170, 333.5009, 103.4022)
    },
    [2] = {
        ["basic_kasa"] = vector3(-1486.45, -378.24, 40.16),
        ["hard_kasa"] = vector3(-1478.71, -375.61, 39.16),
        ["pc_kasa"] = vector3(-1479.6833496094,-375.42144775391,39.643260955811)
    },
	[3] = {
        ["basic_kasa"] = vector3(1134.26, -982.52, 46.42),
        ["hard_kasa"] = vector3(1126.8, -979.78, 45.42),
        ["pc_kasa"] = vector3(1127.3978271484,-980.55017089844,45.913555145264)
    },
	[4] = {
        ["basic_kasa"] = vector3(-1222.2528076172,-907.88568115234,12.49410533905),
        ["hard_kasa"] = vector3(-1221.0880126953,-916.18347167969,11.232238769531),
        ["pc_kasa"] = vector3(-1220.775390625,-915.32653808594,11.870693206787)
    },
}

local kasa = nil
local kasaNo = nil
local collectmoney = false
local PlayerJob = {}

-- Function để get số lượng cảnh sát an toàn
local function GetPoliceCount()
    return GlobalState["police_count"] or 0
end

local function PoliceCall(callType) 
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    local title = "CƯỚP TẠP HÓA"
    local desc = "Báo Động Cướp Tạp Hóa"

    if callType == "basic" or callType == "till" then
        title = "CƯỚP MÁY TÍNH TIỀN TẠP HÓA"
        desc = "Báo Động Cướp Két Tiền Tạp Hóa"
    elseif callType == "hard" or callType == "safe" then
        title = "CƯỚP KÉT SẮT TẠP HÓA"
        desc = "Báo Động Đột Nhập & Hack Két Sắt"
    end

    exports['ld-dispatch']:sendDispatch(
        {
            title = title,
            code = "10-90",
            values = {
                {
                    text = "Cửa Hàng Tạp Hóa",
                    icon = "fa-solid fa-store",
                },
                {
                    text = desc,
                    icon = "fa-solid fa-triangle-exclamation",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = plyCoords,
            blip = {
                blipid = 52,
                blipcolor = 1,
            }
        }
    ) 
end

local isRobbingTill = false

local function HasLockpickItem()
    local itemName = Config.LockpickItem or 'advalockpicknced'
    -- 1. Kiểm tra qua ox_inventory
    if exports.ox_inventory then
        local count = exports.ox_inventory:Search('count', itemName)
        if type(count) == 'number' and count > 0 then
            return true
        end
        local slots = exports.ox_inventory:Search('slots', itemName)
        if slots and #slots > 0 then
            return true
        end
    end
    -- 2. Fallback kiểm tra qua QBCore nếu ox_inventory không trả về
    if QBCore and QBCore.Functions and QBCore.Functions.HasItem then
        local has = QBCore.Functions.HasItem(itemName)
        if has then return true end
    end
    return false
end

local function PlayLockpickAnimation()
    local animDict = 'veh@break_in@0h@p_m_one@'
    local animClip = 'low_force_entry_ds'
    lib.requestAnimDict(animDict)
    TaskPlayAnim(PlayerPedId(), animDict, animClip, 3.0, 3.0, -1, 16, 0, false, false, false)
end

RegisterNetEvent('xx_shoprobbery:onrobbery')
AddEventHandler('xx_shoprobbery:onrobbery', function(data)
    if isRobbingTill then
        QBCore.Functions.Notify("Bạn đang trong quá trình bẻ khóa két!", "error")
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = (data and data.coords) 
        or (data and data.entity and DoesEntityExist(data.entity) and GetEntityCoords(data.entity)) 
        or playerCoords

    -- Tìm cửa hàng gần nhất với máy tính tiền được tương tác
    kasa = "basic"
    kasaNo = nil
    local minDistance = 15.0
    for i = 1, #shops do
        local dist = #(targetCoords - shops[i]["basic_kasa"])
        if dist < minDistance then
            minDistance = dist
            kasaNo = i
        end
    end

    if not kasaNo then
        for i = 1, #shops do
            local dist = #(playerCoords - shops[i]["basic_kasa"])
            if dist < 15.0 then
                kasaNo = i
                break
            end
        end
    end

    if not kasaNo then
        QBCore.Functions.Notify("Không tìm thấy cửa hàng hợp lệ gần đây!", "error")
        return
    end

    -- Bắt buộc phải có item bẻ khóa (advancedlockpick) mới được cướp két tiền ngoài
    if not HasLockpickItem() then
        local label = Config.LockpickLabel or Config.LockpickItem or "Bộ Bẻ Khóa Cao Cấp (advancedlockpick)"
        QBCore.Functions.Notify(string.format("Bạn bắt buộc phải có %s mới có thể bẻ khóa két tiền ngoài!", label), "error")
        return
    end

    isRobbingTill = true

    lib.callback('xx_shoprobbery:serversidecooldown', false, function(canRob)
        if not canRob then
            isRobbingTill = false
            return
        end

        local policeCount = GetPoliceCount()
        local requiredCops = Config.MinimumStoreRobberyPolice or 0
        if policeCount < requiredCops then
            QBCore.Functions.Notify("Không đủ cảnh sát trực tuyến!", "error")
            isRobbingTill = false
            return
        end

        -- Báo cảnh sát
        PoliceCall("basic")

        -- Bắt đầu diễn hoạt bẻ khóa và chạy minigame ox_lib
        PlayLockpickAnimation()

        local skillSuccess = lib.skillCheck(Config.SkillCheckDifficulty or {'easy', 'medium'}, Config.SkillCheckKeys or {'w', 'a', 's', 'd'})
        ClearPedTasks(PlayerPedId())

        if not skillSuccess then
            QBCore.Functions.Notify("Bẻ khóa thất bại!", "error")
            if Config.RemoveLockpickOnFail then
                TriggerServerEvent("xx_storerobbery:server:removeLockpick")
            end
            isRobbingTill = false
            return
        end

        -- Minigame thành công -> Mới cho phép lấy tiền
        QBCore.Functions.Notify("Bẻ khóa thành công! Bắt đầu lấy tiền...", "success")
        if Config.RemoveLockpickOnSuccess then
            TriggerServerEvent("xx_storerobbery:server:removeLockpick")
        end

        Anim = true
        Citizen.CreateThread(function()
            while Anim do
                TriggerServerEvent('hud:server:GainStress', math.random(5, 7))
                Citizen.Wait(12000)
            end
        end)

        if lib.progressBar({
            duration = Config.Progress_BasicCooldown,
            label = 'Đang lấy tiền khỏi máy tính tiền...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = {
                dict = 'anim@heists@ornate_bank@grab_cash_heels',
                clip = 'grab'
            },
            prop = {
                model = `prop_cs_heist_bag_02`,
                bone = 57005,
                pos = vec3(-0.005, 0.00, -0.16),
                rot = vec3(250.0, -30.0, 0.0)
            },
        }) then
            TriggerServerEvent("xx_shoprobbery:givereward", "basic", kasaNo)
            Anim = false
            StopAnimTask(PlayerPedId(), "anim@heists@ornate_bank@grab_cash_heels", "grab", 1.0)
            SetPedComponentVariation(PlayerPedId(), 5, 40, 8, 0)
            ClearPedTasks(PlayerPedId())
        else
            Anim = false
            StopAnimTask(PlayerPedId(), "anim@heists@ornate_bank@grab_cash_heels", "grab", 1.0)
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.Notify("Đã hủy lấy tiền!", "error")
        end

        isRobbingTill = false
    end, kasaNo, "basic")
end)

RegisterNetEvent('xx_shoprobbery:collectmoney')
AddEventHandler('xx_shoprobbery:collectmoney', function(data)
    local targetShopId = (type(data) == 'table' and data.shopId) or (type(data) == 'number' and data) or currentShopId or kasaNo or 1
    if collectmoney then
        Anim = true
        
        if lib.progressBar({
            duration = Config.Progress_HardCooldown,
            label = 'Đang lấy tiền khỏi két sắt...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
            },
            anim = {
                dict = 'anim@heists@ornate_bank@grab_cash_heels',
                clip = 'grab'
            },
            prop = {
                model = `prop_cs_heist_bag_02`,
                bone = 57005,
                pos = vec3(-0.005, 0.00, -0.16),
                rot = vec3(250.0, -30.0, 0.0)
            },
        }) then
            TriggerServerEvent("xx_shoprobbery:givereward", "hard", targetShopId)
            TriggerServerEvent('xx_shoprobbery:Server:BeginCooldown', targetShopId)
            Anim = false
            collectmoney = false
            StopAnimTask(PlayerPedId(), "anim@heists@ornate_bank@grab_cash_heels", "grab", 1.0)
            SetPedComponentVariation((PlayerPedId()), 5, 40, 8, 0)
        else
            Anim = false
            collectmoney = false
            StopAnimTask(PlayerPedId(), "anim@heists@ornate_bank@grab_cash_heels", "grab", 1.0)   
        end
        Citizen.CreateThread(function()
        while Anim do
            TriggerServerEvent('hud:client:UpdateStress', math.random(5, 7))
            Citizen.Wait(12000)
            end
        end)
    else
        QBCore.Functions.Notify("Đầu tiên bạn phải vượt qua mật khẩu của két!!!!", "error")
    end       
end)

local currentShopId = nil
local isHackingUIOpen = false

local function GetCardBlueHideNumber()
    local cardItem = Config.CardItem or 'blue_card'
    local items = exports.ox_inventory:Search('slots', cardItem)
    if (not items or #items == 0) and cardItem ~= 'blue_card' then
        items = exports.ox_inventory:Search('slots', 'blue_card')
    end
    if (not items or #items == 0) and cardItem ~= 'card_blue' then
        items = exports.ox_inventory:Search('slots', 'card_blue')
    end
    if items and #items > 0 then
        for _, item in pairs(items) do
            if item and item.metadata and item.metadata.hidenumber then
                return tostring(item.metadata.hidenumber)
            else
                local autoHide = ""
                for i = 1, 10 do autoHide = autoHide .. tostring(math.random(0, 9)) end
                return autoHide
            end
        end
    end
    return nil
end

RegisterNetEvent('xx_storerobbery:client:targetPC', function(data)
    local shopId = (type(data) == 'table' and data.shopId) or (type(data) == 'number' and data) or 1
    currentShopId = shopId
    lib.callback('xx_shoprobbery:Cooldown', false, function(cooldown, remainingSecs)
        if not cooldown then
            TriggerServerEvent('xx_storerobbery:server:joinSession', shopId, 'pc')
        else
            local remainingText = (remainingSecs and remainingSecs > 0) and string.format(" (%d giây)", remainingSecs) or ""
            QBCore.Functions.Notify("Vừa có một tiệm tạp hóa bị cướp xong! Vui lòng đợi" .. remainingText .. " để thử lại!", "error")
        end
    end, shopId)
end)

RegisterNetEvent('xx_storerobbery:client:targetSafe', function(data)
    local shopId = (type(data) == 'table' and data.shopId) or (type(data) == 'number' and data) or 1
    currentShopId = shopId
    local hidenumber = GetCardBlueHideNumber()
    lib.callback('xx_shoprobbery:Cooldown', false, function(cooldown, remainingSecs)
        if not cooldown then 
            if not hidenumber then
                local cardName = Config.CardLabel or Config.CardItem or "thẻ giải mã"
                QBCore.Functions.Notify(string.format("Bạn không có %s!", cardName), "error")
                return
            end
            local policeCount = GetPoliceCount()
            local requiredCops = Config.MinimumStoreRobberyPolice 
            if policeCount >= requiredCops then 
                TriggerServerEvent('xx_storerobbery:server:joinSession', shopId, 'safe', hidenumber)
            else
                QBCore.Functions.Notify("Không đủ cảnh sát!", "error")
            end
        else
            local remainingText = (remainingSecs and remainingSecs > 0) and string.format(" (%d giây)", remainingSecs) or ""
            QBCore.Functions.Notify("Vừa có một tiệm tạp hóa bị cướp xong! Vui lòng đợi" .. remainingText .. " để thử lại!", "error")
        end
    end, shopId)
end)


local hackingCam = nil

local function DestroyHackingCamera()
    if hackingCam then
        RenderScriptCams(false, true, 800, true, true)
        local camToDestroy = hackingCam
        hackingCam = nil
        SetTimeout(800, function()
            if camToDestroy and DoesCamExist(camToDestroy) then
                DestroyCam(camToDestroy, false)
            end
        end)
    end
end

local function CreateHackingCamera(role, shopId)
    DestroyHackingCamera()
    
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    
    local targetPoint
    if role == 'pc' then
        local propCoords = (shopId and shops[shopId] and shops[shopId]["pc_kasa"])
        if propCoords then
            targetPoint = propCoords - vec3(0.0, 0.0, 0.15)
        else
            targetPoint = pedCoords + forward * 0.65 - vec3(0.0, 0.0, 0.1)
        end
    else
        local propCoords = (shopId and shops[shopId] and shops[shopId]["hard_kasa"])
        if propCoords then
            targetPoint = propCoords - vec3(0.0, 0.0, 0.2)
        else
            targetPoint = pedCoords + forward * 0.65 - vec3(0.0, 0.0, 0.25)
        end
    end
    
    -- Vị trí camera tiến gần hơn (+ forward * 0.15) và góc nhìn hạ xuống (targetPoint thấp hơn)
    local camPos = pedCoords + forward * 0.15 + vec3(0.0, 0.0, 0.45)
    
    hackingCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(hackingCam, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(hackingCam, targetPoint.x, targetPoint.y, targetPoint.z)
    SetCamFov(hackingCam, 35.0)
    
    SetCamActive(hackingCam, true)
    RenderScriptCams(true, true, 900, true, true)
end

RegisterNetEvent('xx_storerobbery:client:startHackingUI', function(role, hidenumber, attempts, debugPass, safeAttempts)
    isHackingUIOpen = true
    if role == 'safe' then
        PoliceCall("safe")
    end
    CreateHackingCamera(role, currentShopId)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        role = role,
        hidenumber = hidenumber,
        attempts = attempts or {},
        safeAttempts = safeAttempts or 0,
        debugPass = debugPass,
        loadTime = Config.CheckPassLoadTime or 5000,
        maxAttempts = Config.MaxPassAttempts or 8,
        maxSafeAttempts = Config.MaxSafePassAttempts or 3
    })
    if role == 'pc' then
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_STAND_MOBILE", 0, true)
    end
end)

RegisterNetEvent('xx_storerobbery:client:updateAttempts', function(attempts)
    SendNUIMessage({
        action = 'updateAttempts',
        attempts = attempts
    })
end)

RegisterNetEvent('xx_storerobbery:client:updateSafeAttempts', function(safeAttempts)
    SendNUIMessage({
        action = 'updateSafeAttempts',
        safeAttempts = safeAttempts
    })
end)

RegisterNetEvent('xx_storerobbery:client:hackSuccess', function()
    collectmoney = true
    isHackingUIOpen = false
    DestroyHackingCamera()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('xx_storerobbery:client:closeHackingUI', function()
    isHackingUIOpen = false
    DestroyHackingCamera()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    ClearPedTasks(PlayerPedId())
end)

RegisterNUICallback('submitAttempt', function(data, cb)
    if currentShopId and data and data.guess then
        TriggerServerEvent('xx_storerobbery:server:submitGuess', currentShopId, data.guess)
    end
    cb('ok')
end)

RegisterNUICallback('submitFinalUnlock', function(data, cb)
    if currentShopId and data and data.pass then
        TriggerServerEvent('xx_storerobbery:server:submitFinalUnlock', currentShopId, data.pass)
    end
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    if currentShopId then
        TriggerServerEvent('xx_storerobbery:server:closeSession', currentShopId)
    end
    isHackingUIOpen = false
    DestroyHackingCamera()
    SetNuiFocus(false, false)
    ClearPedTasks(PlayerPedId())
    cb('ok')
end)

Citizen.CreateThread(function()
    local tillModels = {
        `prop_till_01`,
        `prop_till_02`,
        `prop_till_03`,
    }

    exports.ox_target:addModel(tillModels, {
        {
            name = 'storerobbery_till',
            icon = 'fas fa-sack-dollar',
            label = "Bẻ khóa két tiền",
            event = "xx_shoprobbery:onrobbery",
            distance = 2.0
        }
    })

    for i = 1, #shops do
        local shop = shops[i]
        local pcCoords = shop["pc_kasa"] 
        local safeCoords = shop["hard_kasa"]

        -- Target Màn hình Máy tính (Người chơi 1)
        if pcCoords then
            exports.ox_target:addSphereZone({
                coords = pcCoords,
                radius = 1.2,
                debug = false,
                options = {
                    {
                        name = 'storerobbery_pc_' .. i,
                        distance = 2.0,
                        icon = 'fas fa-laptop-code',
                        label = 'Tương tác Màn hình Máy tính',
                        event = "xx_storerobbery:client:targetPC",
                        shopId = i
                    }
                }
            })
        end

        -- Target Két sắt (Người chơi 2)
        if safeCoords then
            exports.ox_target:addSphereZone({
                coords = safeCoords,
                radius = 1.2,
                debug = false,
                options = {
                    {
                        name = 'storerobbery_safe_' .. i,
                        distance = 2.0,
                        icon = 'fas fa-keycard',
                        label = 'Quẹt ' .. (Config.CardLabel or 'Thẻ Giải Mã') .. ' Két Sắt',
                        event = "xx_storerobbery:client:targetSafe",
                        shopId = i
                    },
                    {
                        name = 'storerobbery_collect_' .. i,
                        distance = 2.0,
                        icon = 'fas fa-sack-dollar',
                        label = 'Thu tiền trong Két',
                        event = "xx_shoprobbery:collectmoney",
                        shopId = i
                    }
                }
            })
        end
    end
end)




