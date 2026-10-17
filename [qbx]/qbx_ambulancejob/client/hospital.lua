local config = require 'config.client'
local sharedConfig = require 'config.shared'
local bedObject
local bedOccupyingData
local cam
local hospitalOccupying
local bedIndexOccupying
local doctorNpcs = {} -- Table để lưu 3 NPC bác sĩ

---Teleports the player to lie down in bed and sets the player's camera.
---@param skipFadeOut boolean? Skip fade out if screen already black
---@param isAutoRevive boolean? Is this an auto-revive (spawn NPCs)
local function setBedCam(skipFadeOut, isAutoRevive)
    -- Chỉ tối màn hình nếu chưa tối
    if not skipFadeOut then
        DoScreenFadeOut(1000)

        while not IsScreenFadedOut() do
            Wait(100)
        end
    else
        -- Màn hình đã tối rồi, chỉ cần đợi một chút
        Wait(100)
    end

    if IsPedDeadOrDying(cache.ped, true) then
        local pos = GetEntityCoords(cache.ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
    end

    bedObject = GetClosestObjectOfType(bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z, 1.0, bedOccupyingData.model, false, false, false)
    FreezeEntityPosition(bedObject, true)

    SetEntityCoords(cache.ped, bedOccupyingData.coords.x, bedOccupyingData.coords.y, bedOccupyingData.coords.z + 0.02, true, true, true, false)
    Wait(500)
    FreezeEntityPosition(cache.ped, true)

    lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
    SetEntityHeading(cache.ped, bedOccupyingData.coords.w)

    -- Không set camera, dùng góc nhìn người chơi tự nhiên
    -- LUÔN fade in để sáng màn hình khi đã ở trên giường
    DoScreenFadeIn(1000)
    Wait(1000)

    -- Spawn 3 NPC y tá xung quanh giường SAU KHI fade in
    if isAutoRevive and sharedConfig.bedTreatment then
        local cfg = sharedConfig.bedTreatment

        -- Load model y tá
        local nurseModel = GetHashKey(cfg.nurseModel)
        RequestModel(nurseModel)
        while not HasModelLoaded(nurseModel) do Wait(10) end

        Wait(200)

        -- Tính toán vị trí dựa trên offset từ config (giống chữa trị vết thương)
        local footPos = GetOffsetFromEntityInWorldCoords(cache.ped, cfg.npcPositions.foot.x, cfg.npcPositions.foot.y, 0.0)
        local leftPos = GetOffsetFromEntityInWorldCoords(cache.ped, cfg.npcPositions.left.x, cfg.npcPositions.left.y, 0.0)
        local rightPos = GetOffsetFromEntityInWorldCoords(cache.ped, cfg.npcPositions.right.x, cfg.npcPositions.right.y, 0.0)

        local bedHeading = GetEntityHeading(cache.ped)

        -- Spawn NPC dưới chân
        local nurseFoot = CreatePed(4, nurseModel, footPos.x, footPos.y, footPos.z + cfg.npcPositions.foot.z, bedHeading + 180, false, true)
        SetEntityAsMissionEntity(nurseFoot, true, true)
        SetBlockingOfNonTemporaryEvents(nurseFoot, true)
        SetEntityInvincible(nurseFoot, true)
        FreezeEntityPosition(nurseFoot, true)
        table.insert(doctorNpcs, nurseFoot)

        -- Spawn NPC trái
        local nurseLeft = CreatePed(4, nurseModel, leftPos.x, leftPos.y, leftPos.z + cfg.npcPositions.left.z, bedHeading - 90, false, true)
        SetEntityAsMissionEntity(nurseLeft, true, true)
        SetBlockingOfNonTemporaryEvents(nurseLeft, true)
        SetEntityInvincible(nurseLeft, true)
        FreezeEntityPosition(nurseLeft, true)
        table.insert(doctorNpcs, nurseLeft)

        -- Spawn NPC phải
        local nurseRight = CreatePed(4, nurseModel, rightPos.x, rightPos.y, rightPos.z + cfg.npcPositions.right.z, bedHeading + 90, false, true)
        SetEntityAsMissionEntity(nurseRight, true, true)
        SetBlockingOfNonTemporaryEvents(nurseRight, true)
        SetEntityInvincible(nurseRight, true)
        FreezeEntityPosition(nurseRight, true)
        table.insert(doctorNpcs, nurseRight)

        Wait(500)

        -- Animation từ config
        lib.requestAnimDict(cfg.animations.foot.dict)
        TaskPlayAnim(nurseFoot, cfg.animations.foot.dict, cfg.animations.foot.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

        lib.requestAnimDict(cfg.animations.sides.dict)
        TaskPlayAnim(nurseLeft, cfg.animations.sides.dict, cfg.animations.sides.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
        TaskPlayAnim(nurseRight, cfg.animations.sides.dict, cfg.animations.sides.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
    end

    FreezeEntityPosition(cache.ped, true)
end

local function putPlayerInBed(hospitalName, bedIndex, isRevive, skipOpenCheck)
    if IsInHospitalBed then return end
    if not skipOpenCheck then
        if lib.callback.await('qbx_ambulancejob:server:isBedTaken', false, hospitalName, bedIndex) then
            exports.qbx_core:Notify(locale('error.beds_taken'), 'error')
            return
        end
    end

    hospitalOccupying = hospitalName
    bedIndexOccupying = bedIndex
    bedOccupyingData = sharedConfig.locations.hospitals[hospitalName].beds[bedIndex]
    IsInHospitalBed = true
    exports.qbx_medical:DisableDamageEffects()
    exports.qbx_medical:DisableRespawn()
    CanLeaveBed = false
    setBedCam()
    CreateThread(function()
        Wait(5)
        if isRevive then
            exports.qbx_core:Notify(locale('success.being_helped'), 'success')
            exports['progressbar']:Progress({
                name = "healing_treatment",
                duration = config.aiHealTimer * 1000,
                label = locale('progress.healing') or 'Healing...',
                useWhileDead = true,
                canCancel = false,
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                },
                animation = {},
                prop = {},
                propTwo = {}
            }, function(cancelled)
                if not cancelled then
                    TriggerEvent('hospital:client:Revive')
                end
            end)
        else
            CanLeaveBed = true
        end
    end)
    if isRevive then
        TriggerServerEvent('qbx_ambulancejob:server:playerEnteredBed', hospitalName, bedIndex)
    end
end

local function putPlayerInBedrv(hospitalName, bedIndex, isAutoRevive, skipOpenCheck)
    if IsInHospitalBed then return end
    if not skipOpenCheck then
        if lib.callback.await('qbx_ambulancejob:server:isBedTaken', false, hospitalName, bedIndex) then
            exports.qbx_core:Notify(locale('error.beds_taken'), 'error')
            return
        end
    end
    isRevive = true

    -- Dùng thời gian khác nhau: 3 phút cho autoRevive, 1 phút cho chữa trị bác sĩ
    local healDuration = isAutoRevive and sharedConfig.autoRevive and sharedConfig.autoRevive.duration or config.aiHealTimer * 1000

    hospitalOccupying = hospitalName
    bedIndexOccupying = bedIndex
    bedOccupyingData = sharedConfig.locations.hospitals[hospitalName].beds[bedIndex]
    IsInHospitalBed = true
    exports.qbx_medical:DisableDamageEffects()
    exports.qbx_medical:DisableRespawn()
    CanLeaveBed = false

    -- Kiểm tra xem màn hình đã tối chưa (player từ xn_deathscreen gọi vào thì đã tối rồi)
    local screenAlreadyBlack = not IsScreenFadedIn()

    -- Skip fade out nếu màn hình đã tối, chỉ teleport + fade in
    setBedCam(screenAlreadyBlack, isAutoRevive)

    -- Thread disable controls và force animation cho PLAYER (giống chữa trị vết thương)
    local treatmentActive = true
    CreateThread(function()
        while treatmentActive do
            Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Cho phép xoay camera
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 249, true) -- N key - mở chat

            -- Kiểm tra và force animation nếu player bị interrupt
            if not IsEntityPlayingAnim(cache.ped, InBedDict, InBedAnim, 3) then
                lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
            end
        end
    end)

    CreateThread(function()
        Wait(100)
        if isRevive then
            exports.qbx_core:Notify(locale('success.being_helped'), 'success')
            Wait(200) -- Đợi để đảm bảo player đã ở trên giường

            -- Đảm bảo progress bar luôn hiện
            exports['progressbar']:Progress({
                name = "healing_autorevive",
                duration = healDuration, -- Dùng thời gian đã tính ở trên: 3 phút cho autoRevive hoặc 1 phút cho doctor treatment
                label = locale('progress.healing') or 'Healing...',
                useWhileDead = true,
                canCancel = false,
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                },
                animation = {},
                prop = {},
                propTwo = {}
            }, function(cancelled)
                if not cancelled then
                    TriggerServerEvent('qbx_ambulancejob:server:playerEnteredBedrv', hospitalName, bedIndex)
                    TriggerEvent('hospital:client:Revive')
                    Wait(500)

                -- Dừng thread force animation
                treatmentActive = false
                Wait(100)

                -- Xóa NPCs bác sĩ nếu có spawn
                if doctorNpcs and #doctorNpcs > 0 then
                    for _, npc in ipairs(doctorNpcs) do
                        if DoesEntityExist(npc) then
                            DeleteEntity(npc)
                        end
                    end
                    doctorNpcs = {}
                end

                -- QUAN TRỌNG: Clear animation trước để tránh bị dính
                ClearPedTasksImmediately(cache.ped)
                Wait(200)

                -- Tự động rời giường sau khi healing xong
                lib.requestAnimDict('switch@franklin@bed', 10000)
                FreezeEntityPosition(cache.ped, false)

                -- QUAN TRỌNG: Set lại collision và các thuộc tính
                Wait(100)
                SetEntityCollision(cache.ped, true, true)
                SetPedCanRagdoll(cache.ped, true)
                SetPedCanRagdoll(cache.ped, true)

                SetEntityInvincible(cache.ped, false)
                SetEntityCanBeDamaged(cache.ped, true)
                SetPedConfigFlag(cache.ped, 281, false)
                SetEntityVisible(cache.ped, true, false)
                SetEveryoneIgnorePlayer(cache.playerId, false)

                if bedOccupyingData then
                    SetEntityHeading(cache.ped, bedOccupyingData.coords.w + 90)
                else
                    SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + 90)
                end

                TaskPlayAnim(cache.ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 100.0, 1.0, -1, 8, -1, false, false, false)
                Wait(4000)
                ClearPedTasksImmediately(cache.ped)
                RemoveAnimDict('switch@franklin@bed')
                Wait(200)

                -- Trigger event để các resource khác biết bed treatment đã kết thúc
                TriggerEvent('qbx_ambulancejob:client:onBedTreatmentEnd')

                if bedIndexOccupying then
                    TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
                end

                if bedObject then
                    FreezeEntityPosition(bedObject, true)
                end

                RenderScriptCams(false, true, 200, true, true)
                DestroyCam(cam, false)

                hospitalOccupying = nil
                bedIndexOccupying = nil
                bedObject = nil
                bedOccupyingData = nil
                IsInHospitalBed = false
                exports.qbx_medical:EnableDamageEffects()
                exports.qbx_medical:AllowRespawn()

                local inJail = GetPlayerMeta('injail') or 0
                if inJail > 0 then
                    TriggerEvent('prison:client:Enter', inJail)
                end
                end
            end)
        else
            CanLeaveBed = true
        end
    end)
end

RegisterNetEvent('qbx_ambulancejob:client:putPlayerInBed', function(hospitalName, bedIndex)
    putPlayerInBed(hospitalName, bedIndex, false, true)
end)


RegisterNetEvent('qbx_ambulancejob:client:putPlayerInBedrv', function(hospitalName, bedIndex, isAutoRevive)
    putPlayerInBedrv(hospitalName, bedIndex, isAutoRevive, true)
end)

---Đưa người chơi vào giường tùy chỉnh
---@param bedCoords vector4 tọa độ giường
RegisterNetEvent('qbx_ambulancejob:client:putPlayerInCustomBed', function(bedCoords)
    if IsInHospitalBed then return end

    IsInHospitalBed = true
    exports.qbx_medical:DisableDamageEffects()
    exports.qbx_medical:DisableRespawn()
    CanLeaveBed = false

    -- Set để tránh lỗi khi leave bed
    hospitalOccupying = 'custom'
    bedIndexOccupying = nil

    -- Fade out màn hình
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end

    -- Hồi sinh nếu đang chết
    if IsPedDeadOrDying(cache.ped, true) then
        local pos = GetEntityCoords(cache.ped, true)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
    end

    -- Teleport người chơi đến giường
    SetEntityCoords(cache.ped, bedCoords.x, bedCoords.y, bedCoords.z + 0.02, true, true, true, false)
    Wait(500)

    -- Clear mọi animation cũ
    ClearPedTasksImmediately(cache.ped)
    Wait(100)

    FreezeEntityPosition(cache.ped, true)
    SetEntityHeading(cache.ped, bedCoords.w)

    -- Áp dụng animation CPR nằm thẳng
    lib.requestAnimDict('mini@cpr@char_b@cpr_def')
    TaskPlayAnim(cache.ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Không tạo camera - để người chơi tự do di chuyển góc nhìn

    DoScreenFadeIn(1000)
    Wait(1000)
    FreezeEntityPosition(cache.ped, true)

    -- Thread disable các phím để người chơi không thể đứng lên
    CreateThread(function()
        while IsInHospitalBed do
            DisableControlAction(0, 73, true) -- X key - disable get up
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 33, true) -- S
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 35, true) -- D
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- G
            DisableControlAction(0, 58, true) -- G
            DisableControlAction(0, 263, true) -- Melee Attack
            DisableControlAction(0, 264, true) -- Melee Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 143, true) -- Melee Block
            DisableControlAction(0, 75, true) -- Exit Vehicle
            DisableControlAction(27, 75, true) -- Exit Vehicle
            Wait(0)
        end
    end)

    -- Thread kiểm tra liên tục animation - force nằm lại nếu đứng lên
    CreateThread(function()
        while IsInHospitalBed do
            if not IsEntityPlayingAnim(cache.ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 3) then
                ClearPedTasksImmediately(cache.ped)
                TaskPlayAnim(cache.ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, -8.0, -1, 1, 0, false, false, false)
                SetEntityCoords(cache.ped, bedCoords.x, bedCoords.y, bedCoords.z + 0.02, true, true, true, false)
                SetEntityHeading(cache.ped, bedCoords.w)
                FreezeEntityPosition(cache.ped, true)
            end
            Wait(500)
        end
    end)

    CreateThread(function()
        Wait(5)
        exports.qbx_core:Notify(locale('success.being_helped'), 'success')
        exports['progressbar']:Progress({
            name = "healing_custom_bed",
            duration = config.aiHealTimer * 1000,
            label = locale('progress.healing') or 'Healing...',
            useWhileDead = true,
            canCancel = false,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
            animation = {},
            prop = {},
            propTwo = {}
        }, function(cancelled)
            if not cancelled then
                TriggerEvent('hospital:client:Revive')
                Wait(500)

            -- Dừng tất cả thread disable controls TRƯỚC
            IsInHospitalBed = false
            Wait(100)

            -- QUAN TRỌNG: Clear animation trước để tránh bị dính
            ClearPedTasksImmediately(cache.ped)
            Wait(200)

            -- Tự động rời giường sau khi healing xong
            lib.requestAnimDict('switch@franklin@bed', 10000)
            FreezeEntityPosition(cache.ped, false)

            -- QUAN TRỌNG: Set lại collision và các thuộc tính
            Wait(100)
            SetEntityCollision(cache.ped, true, true)
            SetPedCanRagdoll(cache.ped, true)
            SetPedCanRagdoll(cache.ped, true)

            SetEntityInvincible(cache.ped, false)
            SetEntityCanBeDamaged(cache.ped, true)
            SetPedCanRagdoll(cache.ped, true)
            SetPedConfigFlag(cache.ped, 281, false)
            SetEntityVisible(cache.ped, true, false)
            SetEveryoneIgnorePlayer(cache.playerId, false)

            local exitHeading = bedCoords.w + 45
            SetEntityHeading(cache.ped, exitHeading)

            TaskPlayAnim(cache.ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 100.0, 1.0, -1, 8, -1, false, false, false)
            Wait(4000)

            -- Clear animation sau khi hoàn thành
            ClearPedTasksImmediately(cache.ped)
            RemoveAnimDict('switch@franklin@bed')
            Wait(200)

            -- Teleport xuống bên cạnh giường
            local exitX = bedCoords.x + math.cos(math.rad(exitHeading)) * 1.5
            local exitY = bedCoords.y + math.sin(math.rad(exitHeading)) * 1.5
            local exitZ = bedCoords.z - 1.0
            SetEntityCoords(cache.ped, exitX, exitY, exitZ, false, false, false, true)
            Wait(100)

            if bedIndexOccupying then
                TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
            end

            if bedObject then
                FreezeEntityPosition(bedObject, true)
            end

            -- Không dùng camera

            hospitalOccupying = nil
            bedIndexOccupying = nil
            bedObject = nil
            bedOccupyingData = nil
            exports.qbx_medical:EnableDamageEffects()
            exports.qbx_medical:AllowRespawn()

            local inJail = GetPlayerMeta('injail') or 0
            if inJail > 0 then
                TriggerEvent('prison:client:Enter', inJail)
            end
            end
        end)
    end)
end)



---Notifies doctors, and puts player in a hospital bed.
local function checkIn(hospitalName)
    local canCheckIn = lib.callback.await('qbx_ambulancejob:server:canCheckIn', false, hospitalName)
    if not canCheckIn then return end

    if lib.progressBar({
        duration = 6000,
        position = 'bottom',
        label = locale('progress.checking_in'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = {
            clip = 'base',
            dict= 'missheistdockssetup1clipboard@base',
            flag = 16
        },
        prop = {
            {
                model = 'prop_notepad_01',
                bone = 18905,
                pos = vec3(0.1, 0.02, 0.05),
                rot = vec3(10.0, 0.0, 0.0),
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec3(0.11, -0.02, 0.001),
                rot = vec3(-120.0, 0.0, 0.0)
            }
        }
    })
    then
        lib.callback.await('qbx_ambulancejob:server:checkIn', false, cache.serverId, hospitalName)
    else
        exports.qbx_core:Notify(locale('error.canceled'), 'error')
    end
end

RegisterNetEvent('qbx_ambulancejob:client:checkedIn', function(hospitalName, bedIndex)
    putPlayerInBed(hospitalName, bedIndex, true, true)
end)

---Plays animation to get out of bed and resets variables
local function leaveBed()
    lib.requestAnimDict('switch@franklin@bed', 10000)
    FreezeEntityPosition(cache.ped, false)
    SetEntityInvincible(cache.ped, false)

    -- Xử lý cho cả custom bed và normal bed
    if bedOccupyingData then
        SetEntityHeading(cache.ped, bedOccupyingData.coords.w + 90)
    else
        -- Nếu là custom bed, giữ heading hiện tại
        SetEntityHeading(cache.ped, GetEntityHeading(cache.ped) + 90)
    end

    TaskPlayAnim(cache.ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 100.0, 1.0, -1, 8, -1, false, false, false)
    RemoveAnimDict('switch@franklin@bed')
    Wait(4000)
    ClearPedTasks(cache.ped)

    -- Chỉ gọi server event nếu không phải custom bed
    if bedIndexOccupying then
        TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    end

    if bedObject then
        FreezeEntityPosition(bedObject, true)
    end

    RenderScriptCams(false, true, 200, true, true)
    DestroyCam(cam, false)

    hospitalOccupying = nil
    bedIndexOccupying = nil
    bedObject = nil
    bedOccupyingData = nil
    IsInHospitalBed = false
    exports.qbx_medical:EnableDamageEffects()
    exports.qbx_medical:AllowRespawn()

    local inJail = GetPlayerMeta('injail') or 0
    if inJail <= 0 then return end
    TriggerEvent('prison:client:Enter', inJail)
end

---Shows player option to press key to leave bed when available.
-- Đã tắt tính năng này vì tự động rời giường sau khi healing
-- CreateThread(function()
--     while true do
--         if IsInHospitalBed and CanLeaveBed then
--             exports["pa-textui-2"]:displayTextUI(locale('text.bed_out'), "E")
--             --lib.showTextUI(locale('text.bed_out'))
--             while IsInHospitalBed and CanLeaveBed do
--                 if not IsEntityPlayingAnim(cache.ped, InBedDict, InBedAnim, 3) then
--                     lib.playAnim(cache.ped, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, 0, false)
--                 end
--                 OnKeyPress(leaveBed)
--                 Wait(0)
--             end
--             exports["pa-textui-2"]:hideTextUI()
--         else
--             Wait(1000)
--         end
--     end
-- end)

---Reset player settings that the server is storing
local function onPlayerUnloaded()
    if bedIndexOccupying then
        TriggerServerEvent('qbx_ambulancejob:server:playerLeftBed', hospitalOccupying, bedIndexOccupying)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', onPlayerUnloaded)

AddEventHandler('onResourceStop', function(resourceName)
    if cache.resource ~= resourceName then return end
    onPlayerUnloaded()
end)
