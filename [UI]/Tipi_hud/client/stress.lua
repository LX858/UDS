if not Config.UseStress then return end

stress = 0


local function GetBlurIntensity(stresslevel)
    if not Config.StressIntensity or not Config.StressIntensity['blur'] then return 1500 end
    for _, v in pairs(Config.StressIntensity['blur']) do
        if v.min and v.max and stresslevel >= v.min and stresslevel <= v.max then
            return v.intensity or 1500
        end
    end
    return 1500
end

local function GetEffectInterval(stresslevel)
    if not Config.StressEffectInterval then return 60000 end
    for _, v in pairs(Config.StressEffectInterval) do
        if v.min and v.max and stresslevel >= v.min and stresslevel <= v.max then
            return v.timeout or 60000
        end
    end
    return 60000
end



RegisterNetEvent('tipi-hud:updateStress')
AddEventHandler('tipi-hud:updateStress', function(newStress)
    stress = newStress
    SendNUIMessage({ action = "setStress", stress = stress })
end)

-- qbx_core replicates hunger/thirst/stress/sleepiness through this player statebag
-- (SetMetadata -> playerState:set('stress', value, true)); this is the authoritative,
-- lowest-latency source, so read it directly instead of waiting on a full PlayerData sync.
AddStateBagChangeHandler('stress', ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
    if value == nil then return end
    stress = math.max(0, math.min(100, value))
    SendNUIMessage({ action = "setStress", stress = stress })
end)




RegisterNetEvent('QBCore:Player:SetPlayerData')
AddEventHandler('QBCore:Player:SetPlayerData', function(PlayerData)
    -- metadata.stress may be missing on unrelated PlayerData syncs (job/money/etc);
    -- only resync when the server actually sent a stress value, otherwise it
    -- would fall back to 0 and make the bar look like it randomly dropped.
    if not PlayerData.metadata or PlayerData.metadata.stress == nil then return end
    local metaStress = PlayerData.metadata.stress
    stress = stress or 0
    if math.abs(stress - metaStress) > 0.1 then
        stress = math.max(0, math.min(100, metaStress))
        SendNUIMessage({ action = "setStress", stress = stress })
    end
end)


local function IsEligibleJobReducedStress()
    local cfg = Config.DrivingStressJobReduction
    if not cfg or not cfg.enabled then return false end

    local jobName, jobType, onDuty = nil, nil, false

    -- 1. Ưu tiên lấy trực tiếp từ qbx_core
    if GetResourceState('qbx_core') == 'started' then
        local success, qbxData = pcall(function() return exports.qbx_core:GetPlayerData() end)
        if success and qbxData and qbxData.job then
            jobName = qbxData.job.name
            jobType = qbxData.job.type
            onDuty = (qbxData.job.onduty == true or qbxData.job.onduty == 1)
        end
    end

    -- 2. Fallback PlayerCache
    if (not jobName or not onDuty) and PlayerCache and PlayerCache.job then
        jobName = jobName or PlayerCache.job.name
        jobType = jobType or PlayerCache.job.type
        if onDuty == false and (PlayerCache.job.onduty == true or PlayerCache.job.onduty == 1) then
            onDuty = true
        end
    end

    -- 3. Fallback Framework QBCore
    if (not jobName or not onDuty) and Framework and Framework.Functions and Framework.Functions.GetPlayerData then
        local pData = Framework.Functions.GetPlayerData()
        if pData and pData.job then
            jobName = jobName or pData.job.name
            jobType = jobType or pData.job.type
            if onDuty == false and (pData.job.onduty == true or pData.job.onduty == 1) then
                onDuty = true
            end
        end
    end

    -- Nếu không onduty thì không giảm stress (tính như player thông thường)
    if not onDuty then return false end

    -- Kiểm tra tên job
    if jobName and cfg.jobs and cfg.jobs[jobName] then
        return true
    end

    -- Kiểm tra loại job (jobType như 'leo', 'ambulance', 'ems')
    if jobType and cfg.jobTypes and cfg.jobTypes[jobType] then
        return true
    end

    return false
end

CreateThread(function()
    if not Config.AddStress["on_fastdrive"].enable then return end
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            local veh = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(veh) * SpeedMultiplier
            if math.random() < (Config.AddStress["on_fastdrive"].chance / 100) then
                local minSpeed = SpeedMultiplier == 3.6
                    and Config.AddStress["on_fastdrive"].minSpeed
                    or  Config.AddStress["on_fastdrive"].minSpeed / 1.6
                if speed >= minSpeed then
                    local baseAmount = math.random(Config.AddStress["on_fastdrive"].min, Config.AddStress["on_fastdrive"].max)
                    local finalAmount = baseAmount

                    -- Nếu là police hoặc ambulance khi onduty, stress chỉ tăng bằng 30% (multiplier = 0.3)
                    if IsEligibleJobReducedStress() then
                        local mult = (Config.DrivingStressJobReduction and Config.DrivingStressJobReduction.multiplier) or 0.3
                        finalAmount = math.floor((baseAmount * mult) * 100 + 0.5) / 100
                    end

                    TriggerServerEvent('tipi-hud:gainStress', finalAmount)
                end
            end
        end
        Wait(10000)
    end
end)


CreateThread(function()
    if not Config.AddStress["on_shoot"].enable then return end
    local sleep = 2000
    while true do
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        if IsPedArmed(ped, 4) and weapon ~= joaat('WEAPON_UNARMED') then
            sleep = 100
            if IsPedShooting(ped) then
                if math.random() < Config.StressChance and not Config.WhitelistedWeaponStress[weapon] then
                    TriggerServerEvent('tipi-hud:gainStress',
                        math.random(Config.AddStress["on_shoot"].min, Config.AddStress["on_shoot"].max))
                end
            end
        else
            sleep = 2000
        end
        Wait(sleep)
    end
end)


RegisterNetEvent("esx_status:add")
AddEventHandler('esx_status:add', function(_type)
    if Config.RemoveStress and Config.RemoveStress["on_eat"] and Config.RemoveStress["on_eat"].enable and _type == "hunger" then
        TriggerServerEvent('tipi-hud:relieveStress',
            math.random(Config.RemoveStress["on_eat"].min, Config.RemoveStress["on_eat"].max))
    elseif Config.RemoveStress and Config.RemoveStress["on_drink"] and Config.RemoveStress["on_drink"].enable and _type == "thirst" then
        TriggerServerEvent('tipi-hud:relieveStress',
            math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max))
    end
end)


AddEventHandler('esx:onPlayerDeath', function()
    TriggerServerEvent('tipi-hud:gainStress', -stress)
end)


RegisterNetEvent('consumables:client:Eat')
AddEventHandler('consumables:client:Eat', function()
    if Config.RemoveStress and Config.RemoveStress["on_eat"] and Config.RemoveStress["on_eat"].enable then
        TriggerServerEvent('tipi-hud:relieveStress',
            math.random(Config.RemoveStress["on_eat"].min, Config.RemoveStress["on_eat"].max))
    end
end)

RegisterNetEvent('consumables:client:Drink')
AddEventHandler('consumables:client:Drink', function()
    if Config.RemoveStress and Config.RemoveStress["on_drink"] and Config.RemoveStress["on_drink"].enable then
        TriggerServerEvent('tipi-hud:relieveStress',
            math.random(Config.RemoveStress["on_drink"].min, Config.RemoveStress["on_drink"].max))
    end
end)


CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if Config.RemoveStress and Config.RemoveStress["on_swim"] and Config.RemoveStress["on_swim"].enable and IsPedSwimming(ped) and stress > 0 then
            TriggerServerEvent('tipi-hud:relieveStress',
                math.random(Config.RemoveStress["on_swim"].min, Config.RemoveStress["on_swim"].max))
        end

        if Config.RemoveStress and Config.RemoveStress["on_run"] and Config.RemoveStress["on_run"].enable and IsPedRunning(ped) and stress > 0 then
            TriggerServerEvent('tipi-hud:relieveStress',
                math.random(Config.RemoveStress["on_run"].min, Config.RemoveStress["on_run"].max))
        end

        if stress >= 50 and Config.StressNotify == true then
            notify('stress')
        end

        Wait(30000) 
    end
end)

CreateThread(function()
    while true do
        local curStress = stress or 0

        if curStress < Config.MinimumStress then
            Wait(5000)
            goto continue
        end

        if curStress >= 100 then
            local BlurIntensity = GetBlurIntensity(curStress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = FallRepeat * 1750
            local ped = PlayerPedId()

            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1,
                    GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(1000)
            for _ = 1, FallRepeat do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                TriggerScreenblurFadeIn(1000.0)
                Wait(BlurIntensity)
                TriggerScreenblurFadeOut(1000.0)
            end

        else
            local BlurIntensity = GetBlurIntensity(curStress)
            TriggerScreenblurFadeIn(1000.0)
            Wait(BlurIntensity)
            TriggerScreenblurFadeOut(1000.0)
        end

        Wait(GetEffectInterval(stress or 0))

        ::continue::
    end
end)

-- ─── API khác ─────────────────────────────────────────────────────

RegisterNetEvent("tipi_hud:stress:add")
AddEventHandler("tipi_hud:stress:add", function(val)
    TriggerServerEvent('tipi-hud:gainStress', val)
end)

RegisterNetEvent("tipi_hud:stress:decrease")
AddEventHandler("tipi_hud:stress:decrease", function(val)
    TriggerServerEvent('tipi-hud:relieveStress', val)
end)

-- ─── Lấy Stress thực tế từ QBX / QBCore Metadata ─────────────────────────

local function GetActualStress()
    -- 1. StateBag của LocalPlayer (qbx_core đồng bộ qua playerState:set('stress', value, true))
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.stress ~= nil then
        return tonumber(LocalPlayer.state.stress) or 0
    end

    -- 2. Đọc từ PlayerCache metadata
    if PlayerCache and PlayerCache.metadata and PlayerCache.metadata.stress ~= nil then
        return tonumber(PlayerCache.metadata.stress) or 0
    end

    return stress or 0
end

-- ─── Command kiểm tra stress ──────────────────────────────────────────

local function CheckStressCommand()
    local realStress = GetActualStress()
    stress = math.max(0, math.min(100, realStress)) -- đồng bộ lại cache cục bộ

    local displayVal = (realStress % 1 == 0) and string.format("%d", realStress) or string.format("%.1f", realStress)
    local statusMsg = ""
    local notifType = "inform"

    if realStress >= 80 then
        statusMsg = string.format("Chỉ số Stress thực tế: %s/100 (Cực kỳ căng thẳng! Nguy cơ ngất xỉu/mờ mắt)", displayVal)
        notifType = "error"
    elseif realStress >= 50 then
        statusMsg = string.format("Chỉ số Stress thực tế: %s/100 (Khá căng thẳng, cần ăn uống hoặc nghỉ ngơi)", displayVal)
        notifType = "warning"
    elseif realStress >= 20 then
        statusMsg = string.format("Chỉ số Stress thực tế: %s/100 (Căng thẳng nhẹ)", displayVal)
        notifType = "inform"
    else
        statusMsg = string.format("Chỉ số Stress thực tế: %s/100 (Tinh thần rất thoải mái và ổn định)", displayVal)
        notifType = "success"
    end

    if lib and lib.notify then
        lib.notify({
            title = "Kiểm Tra Stress (qbx_core)",
            description = statusMsg,
            type = notifType,
            icon = "brain",
            duration = 6000,
            position = "top-right"
        })
    else
        notify(statusMsg)
    end
end

RegisterCommand('checkstress', function()
    CheckStressCommand()
end, false)

RegisterCommand('stress', function()
    CheckStressCommand()
end, false)

-- ─── Hàm & Command Set Stress để Test ──────────────────────────────────

local function SetStress(val)
    local num = tonumber(val)
    if not num then return false end
    num = math.max(0, math.min(100, num))

    stress = num
    SendNUIMessage({ action = "setStress", stress = stress })
    TriggerServerEvent('tipi-hud:setStressDirect', num)

    if lib and lib.notify then
        lib.notify({
            title = "Set Stress (Test)",
            description = string.format("Đã cập nhật stress thành: %d%%", num),
            type = "inform",
            icon = "brain",
            duration = 4000,
            position = "top-right"
        })
    else
        notify(string.format("Đã cập nhật stress thành: %d%%", num))
    end
    return true
end

RegisterCommand('setstress', function(_, args)
    local val = tonumber(args[1])
    if not val then
        if lib and lib.notify then
            lib.notify({
                title = "Lỗi cú pháp",
                description = "Vui lòng nhập số stress: /setstress [0-100]",
                type = "error"
            })
        else
            print("^1[Tipi_hud] Cú pháp: /setstress [0-100]^0")
        end
        return
    end
    SetStress(val)
end, false)

TriggerEvent('chat:addSuggestion', '/checkstress', 'Kiểm tra chỉ số stress thực tế từ metadata qbx_core')
TriggerEvent('chat:addSuggestion', '/stress', 'Kiểm tra chỉ số stress thực tế từ metadata qbx_core')
TriggerEvent('chat:addSuggestion', '/setstress', 'Set chỉ số stress để test (0-100)', {
    { name = "số_stress", help = "Số điểm stress cần set (VD: 0, 50, 100)" }
})

exports('getStress', GetActualStress)
exports('getActualStress', GetActualStress)
exports('checkStress', CheckStressCommand)
exports('setStress', SetStress)




