local isTied = false
local currentRopeType = nil

-- Tự động gửi sự kiện kiểm tra trạng thái bị trói khi vừa vào game / spawn
RegisterNetEvent('playerSpawned', function()
    TriggerServerEvent('gin_troitay:server:checkTiedOnSpawn')
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('gin_troitay:server:checkTiedOnSpawn')
end)

-- Hàm kiểm tra người chơi có đang bị trói không
local function isPlayerTied()
    return isTied
end
exports('isPlayerTied', isPlayerTied)

-- Hàm hỗ trợ chạy minigame (Tắt minigame nếu Config.DebugDisableMinigame = true)
local function runMinigame(minigameConfig, keys)
    if Config.DebugDisableMinigame then
        return true
    end
    return lib.skillCheck(minigameConfig, keys)
end

-- Thread xử lý animation và vô hiệu hóa điều khiển khi bị trói
local function startTiedLoop()
    CreateThread(function()
        local playerId = PlayerId()
        local dict = Config.Animations.Tied.dict
        local clip = Config.Animations.Tied.clip

        -- Request dict và phát animation 1 lần trước khi vào loop (tránh spam TaskPlayAnim mỗi tick)
        lib.requestAnimDict(dict, 5000)
        local ped = PlayerPedId()
        TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 49, 0, false, false, false)

        local lastAnimCheck = GetGameTimer()

        while isTied do
            ped = PlayerPedId()
            local currentTime = GetGameTimer()
            
            -- Native còng tay của GTA V: Ép 2 tay ra đằng sau lưng và không cho đấm/rút súng
            SetEnableHandcuffs(ped, true)
            SetPedCanPlayGestureAnims(ped, false)
            DisablePlayerFiring(playerId, true)

            -- Chỉ kiểm tra và phát lại animation khi ngắt (ragdoll...) cách nhau ít nhất 1.5 giây
            if currentTime - lastAnimCheck > 1500 then
                if not IsEntityPlayingAnim(ped, dict, clip, 3) then
                    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
                lastAnimCheck = currentTime
            end

            -- Vô hiệu hóa toàn bộ các hành động tấn công, đấm, bắn, lái xe, dùng trang bị
            DisableControlAction(0, 24, true)  -- Attack / Shoot
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon Target
            DisableControlAction(0, 58, true)  -- Weapon Select
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 143, true) -- Block
            DisableControlAction(0, 257, true) -- Attack 2 (Punch)
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 264, true) -- Melee Attack 2
            DisableControlAction(0, 23, true)  -- Enter Vehicle
            DisableControlAction(0, 75, true)  -- Exit Vehicle
            DisableControlAction(0, 289, true) -- Inventory default (F2)
            DisableControlAction(0, 192, true) -- Weapon wheel (TAB)

            -- Xử lý hạn chế di chuyển khi bị trói bằng Dây Cước (day_cuoc): Tắt nhảy tuyệt đối
            if currentRopeType == Config.Items.DayCuoc or currentRopeType == 'day_cuoc' then
                DisableControlAction(0, 22, true)  -- INPUT_JUMP (Group 0)
                DisableControlAction(1, 22, true)  -- INPUT_JUMP (Group 1)
                DisableControlAction(2, 22, true)  -- INPUT_JUMP (Group 2)
                DisableControlAction(0, 102, true) -- INPUT_VEH_FLY_ATTACK_CAMERA / Vault
                
                -- Nếu lỡ nhấn phím nhảy thì chặn đứng lập tức
                if IsControlJustPressed(0, 22) or IsDisabledControlJustPressed(0, 22) then
                    ClearPedTasksImmediately(ped)
                    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end

            -- Cất vũ khí khỏi tay
            if GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED` then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            end

            Wait(0)
        end

        -- Dọn dẹp trạng thái khi cởi trói xong
        local endPed = PlayerPedId()
        SetEnableHandcuffs(endPed, false)
        SetPedCanPlayGestureAnims(endPed, true)
        ClearPedTasks(endPed)
    end)
end

-- Đồng bộ trạng thái bị trói từ server
RegisterNetEvent('gin_troitay:client:syncTiedState', function(tiedState, ropeType)
    isTied = tiedState
    currentRopeType = ropeType

    local ped = PlayerPedId()
    if isTied then
        lib.notify({
            type = 'warning',
            description = Config.Locales.YouHaveBeenTied
        })
        startTiedLoop()
    else
        SetEnableHandcuffs(ped, false)
        SetPedCanPlayGestureAnims(ped, true)
        ClearPedTasks(ped)
        lib.notify({
            type = 'success',
            description = Config.Locales.YouHaveBeenUntied
        })
    end
end)

local isDuelActive = false

-- Đăng ký sự kiện khởi chạy Minigame Đối Kháng Kéo Co từ Server
RegisterNetEvent('gin_troitay:client:openDuelMinigame', function(role, initialProgress, duration, opponentServerId)
    isDuelActive = true

    -- Mở NUI Focus giữ Input để người chơi di chuyển (WASD) thoải mái để trốn thoát
    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)

    -- Gửi thông điệp mở giao diện Minigame NUI
    SendNUIMessage({
        action = 'startDuel',
        role = role,
        progress = initialProgress,
        duration = duration
    })

    -- Phát animation và kiểm tra khoảng cách di chuyển trong thời gian thi đấu
    CreateThread(function()
        local ped = PlayerPedId()
        if role == 'tyer' then
            lib.requestAnimDict(Config.Animations.Tying.dict, 2000)
            TaskPlayAnim(ped, Config.Animations.Tying.dict, Config.Animations.Tying.clip, 8.0, -8.0, duration, 16, 0, false, false, false)
        end

        local maxDistance = Config.MaxDistance or 3.0

        while isDuelActive do
            ped = PlayerPedId()

            -- Chặn các hành động tấn công / chọn vũ khí
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 37, true)  -- Select Weapon
            DisableControlAction(0, 47, true)  -- Weapon Target
            DisableControlAction(0, 140, true) -- Melee Light
            DisableControlAction(0, 141, true) -- Melee Heavy
            DisableControlAction(0, 142, true) -- Melee Alternate
            DisableControlAction(0, 257, true) -- Attack 2

            -- Kiểm tra khoảng cách: Nếu di chuyển xa hơn Config.MaxDistance thì hủy minigame
            if opponentServerId then
                local opponentPlayer = GetPlayerFromServerId(opponentServerId)
                if opponentPlayer ~= -1 then
                    local opponentPed = GetPlayerPed(opponentPlayer)
                    if opponentPed ~= 0 and DoesEntityExist(opponentPed) then
                        local currentDist = #(GetEntityCoords(ped) - GetEntityCoords(opponentPed))
                        if currentDist > maxDistance then
                            TriggerServerEvent('gin_troitay:server:cancelDuelTooFar')
                            break
                        end
                    end
                end
            end

            Wait(0)
        end

        ClearPedTasks(ped)
    end)
end)

-- Đăng ký sự kiện cập nhật tiến trình % từ Server đồng bộ xuống
RegisterNetEvent('gin_troitay:client:updateDuelProgress', function(progress)
    SendNUIMessage({
        action = 'updateProgress',
        progress = progress
    })
end)

-- Đăng ký sự kiện chốt kết quả Thắng/Thua từ Server
RegisterNetEvent('gin_troitay:client:finishDuelMinigame', function(result, message)
    isDuelActive = false
    ClearPedTasks(PlayerPedId())

    SendNUIMessage({
        action = 'finishDuel',
        result = result,
        message = message
    })

    SetTimeout(1500, function()
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
    end)
end)

-- NUI Callback: Nhận tín hiệu khi người chơi spam phím E từ HTML JS
RegisterNUICallback('pressE', function(data, cb)
    TriggerServerEvent('gin_troitay:server:pressDuelE')
    cb('ok')
end)

-- NUI Callback: Đóng giao diện NUI
RegisterNUICallback('closeUI', function(data, cb)
    isDuelActive = false
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Sự kiện khi nạn nhân quay lại tát người trói 1 cái (dành cho client Nạn Nhân)
RegisterNetEvent('gin_troitay:client:slapTyer', function(tyerServerId)
    CreateThread(function()
        Wait(100)

        local ped = PlayerPedId()
        ClearPedTasks(ped)

        local tyerPlayer = GetPlayerFromServerId(tyerServerId)
        local tyerPed = (tyerPlayer ~= -1) and GetPlayerPed(tyerPlayer) or 0

        if tyerPed ~= 0 and DoesEntityExist(tyerPed) then
            -- Quay mặt về phía người trói
            TaskTurnPedToFaceEntity(ped, tyerPed, 800)
            Wait(350)
        end

        local animDict = (Config.Animations and Config.Animations.SlapAttacker and Config.Animations.SlapAttacker.dict) or 'melee@unarmed@streamed_variations'
        local animClip = (Config.Animations and Config.Animations.SlapAttacker and Config.Animations.SlapAttacker.clip) or 'plyr_takedown_front_slap'

        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 50 do
            Wait(20)
            timeout = timeout + 1
        end

        if HasAnimDictLoaded(animDict) then
            -- Phát âm thanh tát
            SendNUIMessage({ action = 'playSlapSound' })
            PlaySoundFromEntity(-1, 'PHYSICAL_IMPACT_FLAT', ped, 'SPECIAL_ABILITY_SOUNDSET', 0, 0)

            TaskPlayAnim(ped, animDict, animClip, 8.0, -8.0, 2000, 0, 0.0, false, false, false)
            Wait(2000)
            ClearPedTasks(ped)
            RemoveAnimDict(animDict)
        end
    end)
end)

-- Sự kiện khi người trói bị nạn nhân tát, ngã xuống và mất 10 máu (dành cho client Người Trói)
RegisterNetEvent('gin_troitay:client:getSlappedByTarget', function(targetServerId)
    CreateThread(function()
        Wait(100)

        local ped = PlayerPedId()
        ClearPedTasks(ped)

        local targetPlayer = GetPlayerFromServerId(targetServerId)
        local targetPed = (targetPlayer ~= -1) and GetPlayerPed(targetPlayer) or 0

        if targetPed ~= 0 and DoesEntityExist(targetPed) then
            -- Quay mặt về phía nạn nhân
            TaskTurnPedToFaceEntity(ped, targetPed, 800)
            Wait(350)
        end

        local animDict = (Config.Animations and Config.Animations.SlapVictim and Config.Animations.SlapVictim.dict) or 'melee@unarmed@streamed_variations'
        local animClip = (Config.Animations and Config.Animations.SlapVictim and Config.Animations.SlapVictim.clip) or 'victim_takedown_front_slap'

        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 50 do
            Wait(20)
            timeout = timeout + 1
        end

        -- Phát âm thanh tát
        SendNUIMessage({ action = 'playSlapSound' })
        PlaySoundFromEntity(-1, 'PHYSICAL_IMPACT_FLAT', ped, 'SPECIAL_ABILITY_SOUNDSET', 0, 0)

        -- 1. Mất 10 máu
        local damage = Config.SlapDamage or 10
        ApplyDamageToPed(ped, damage, false)

        -- 2. Ngã xuống bằng animation victim_takedown_front_slap
        if HasAnimDictLoaded(animDict) then
            TaskPlayAnim(ped, animDict, animClip, 8.0, -8.0, 2500, 0, 0.0, false, false, false)
            Wait(2500)
            RemoveAnimDict(animDict)
        end

        -- 3. Giữ ngã ragdoll thêm một chút sau khi kết thúc animation ngã
        local ragdollTime = Config.SlapRagdollTime or 1500
        if ragdollTime > 0 then
            SetPedToRagdoll(ped, ragdollTime, ragdollTime, 0, true, true, false)
        else
            ClearPedTasks(ped)
        end
    end)
end)

-- Bắt đầu quá trình trói người khác khi bấm ox_target
RegisterNetEvent('gin_troitay:client:startTying', function(targetServerId, ropeType)
    if isTied or isDuelActive then return end

    local ped = PlayerPedId()
    local targetPlayer = GetPlayerFromServerId(targetServerId)
    local targetPed = targetPlayer ~= -1 and GetPlayerPed(targetPlayer) or 0

    if targetPed == 0 or #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) > Config.MaxDistance then
        lib.notify({
            type = 'error',
            description = Config.Locales.TooFar
        })
        return
    end

    -- Gửi sự kiện lên Server để khởi tạo Minigame đối kháng 2 người
    TriggerServerEvent('gin_troitay:server:startDuelMinigame', targetServerId, ropeType)
end)


-- Hàm xử lý tự cởi trói cho bản thân (dùng lệnh /coitroi hoặc dùng item dao_cat)
local function triggerSelfUntie()
    if not isTied then
        lib.notify({
            type = 'error',
            description = Config.Locales.TargetNotTied
        })
        return
    end

    -- Kiểm tra xem người bị trói có con dao (dao_cat) trong túi đồ ox_inventory hay không
    local knifeCount = exports.ox_inventory:Search('count', Config.Items.DaoCat) or 0
    if knifeCount < 1 then
        lib.notify({
            type = 'error',
            description = Config.Locales.NoKnife
        })
        return
    end

    -- 1. Bản thân tự cởi trói: PHẢI chạy minigame oxlib (hoặc tự qua nếu DebugMode = true)
    local success = runMinigame(Config.Minigames.SelfUntie, { 'e', 'r', '1', '2' })

    if not success then
        lib.notify({
            type = 'error',
            description = Config.Locales.SelfUntieFailed
        })
        return
    end

    -- Khỏa lấp trễ 200ms xả phím bấm vừa xong từ minigame
    Wait(200)

    -- 2. Chạy thanh tiến trình Progressbar load tự cắt dây trói
    local completed = lib.progressBar({
        duration = Config.SelfUntieDuration or 3000,
        label = 'Đang tự cắt dây trói...',
        useReplay = false,
        canCancel = false,
        disable = {
            move = false,
            car = true,
            combat = true
        }
    })

    -- 3. Gửi sự kiện lên server để tháo trói
    TriggerServerEvent('gin_troitay:server:selfUntieSuccess')
    lib.notify({
        type = 'success',
        description = Config.Locales.SelfUntieSuccess
    })
end

-- Lệnh /coitroi dành cho người bị trói tự cởi trói (yêu cầu phải có dao_cat)
RegisterCommand('coitroi', function()
    triggerSelfUntie()
end, false)

-- Sự kiện khi người bị trói tự dùng item Dao Cắt (dao_cat) từ túi đồ
RegisterNetEvent('gin_troitay:client:useDaoCat', function()
    triggerSelfUntie()
end)

-- Hàm kiểm tra mục tiêu ped có đang bị trói hay không
local function isPedTied(entity)
    if not DoesEntityExist(entity) then return false end
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
    local pedState = Entity(entity).state.isTied
    local playerState = (targetServerId > 0) and Player(targetServerId).state.isTied
    return (pedState == true or playerState == true)
end

-- Đăng ký các tùy chọn tương tác Target qua ox_target trên người chơi khác
CreateThread(function()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'gin_troitay:tie_day_thung',
            icon = 'fa-solid fa-rope',
            label = 'Trói tay (Dây thừng)',
            items = Config.Items.DayThung,
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if isTied then return false end
                return not isPedTied(entity)
            end,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerEvent('gin_troitay:client:startTying', targetServerId, Config.Items.DayThung)
            end
        },
        {
            name = 'gin_troitay:tie_day_cuoc',
            icon = 'fa-solid fa-spool',
            label = 'Trói tay (Dây cước)',
            items = Config.Items.DayCuoc,
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if isTied then return false end
                return not isPedTied(entity)
            end,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                TriggerEvent('gin_troitay:client:startTying', targetServerId, Config.Items.DayCuoc)
            end
        },
        {
            name = 'gin_troitay:untie_other',
            icon = 'fa-solid fa-scissors',
            label = 'Cắt dây trói (Dùng dao)',
            items = Config.Items.DaoCat,
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if isTied then return false end
                return isPedTied(entity)
            end,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                
                -- Người chơi khác cắt dây KHÔNG CẦN minigame, chạy thanh tiến trình cắt dây
                local ped = PlayerPedId()
                lib.requestAnimDict(Config.Animations.Cutting.dict, 2000)
                TaskPlayAnim(ped, Config.Animations.Cutting.dict, Config.Animations.Cutting.clip, 8.0, -8.0, Config.CutRopeDuration, 1, 0, false, false, false)

                if lib.progressBar({
                    duration = Config.CutRopeDuration,
                    label = 'Đang cắt dây trói...',
                    useReplay = false,
                    canCancel = true,
                    disable = {
                        move = true,
                        car = true,
                        combat = true
                    }
                }) then
                    ClearPedTasks(ped)
                    TriggerServerEvent('gin_troitay:server:untieOther', targetServerId)
                else
                    ClearPedTasks(ped)
                end
            end
        }
    })
end)
