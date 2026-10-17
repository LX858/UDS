local statusInterval = require 'config.client'.statusIntervalSeconds
local playerState = LocalPlayer.state

-- Biến để theo dõi hiệu ứng
local sleepinessEffectActive = false
local lastSleepinessEffect = 0

CreateThread(function()
    local timeout = 1000 * statusInterval
    while true do
        Wait(timeout)

        if QBX.IsLoggedIn and not playerState.isDead then
            -- ===== LOGIC CŨ: HUNGER & THIRST =====
            if (playerState.hunger or 0) <= 0 or (playerState.thirst or 0) <= 0 then
                local currentHealth = GetEntityHealth(cache.ped)
                local decreaseThreshold = math.random(5, 10)
                SetEntityHealth(cache.ped, currentHealth - decreaseThreshold)
            end

            -- 🛌 KIỂM TRA NGỦ - CỰC KỲ ĐƠN GIẢN!
            if playerState.isSleeping then
                -- Auto reset effects khi ngủ
                if sleepinessEffectActive then
                    SetPedMotionBlur(cache.ped, false)
                    ClearTimecycleModifier()
                    SetPedMoveRateOverride(cache.ped, 1.0)
                    sleepinessEffectActive = false
                end
                goto continue -- Skip all sleepiness logic
            end

            -- ===== SLEEPINESS LOGIC (CHỈ KHI KHÔNG NGỦ) =====
            local sleepiness = playerState.sleepiness

            -- ⚠️ LƯU Ý: KHÔNG DÙNG return - SẼ DỪNG LOOP!
            if not sleepiness then
                goto continue -- ✅ ĐÚNG: Dùng goto continue
                -- return      -- ❌ SAI: Sẽ dừng toàn bộ loop!
            end

            -- 🔍 DEBUG: Kiểm tra giá trị sleepiness
            --print(('[SLEEPINESS DEBUG] Value: %s, Type: %s'):format(sleepiness, type(sleepiness)))

            if sleepiness < 5 then
                -- 🚨 CỰC KỲ NGUY HIỂM: < 5%
                --print('[SLEEPINESS] CỰC KỲ NGUY HIỂM - Sleepiness: ' .. sleepiness)

                local currentHealth = GetEntityHealth(cache.ped)
                local healthDamage = math.random(3, 6)
                SetEntityHealth(cache.ped, math.max(1, currentHealth - healthDamage))

                -- Hiệu ứng chớp đen + ngã mạnh (mỗi 5 giây cho test nhanh)
                if GetGameTimer() - lastSleepinessEffect > 5000 then
                    --print('[SLEEPINESS] Triggering severe effects...')

                    -- Chớp đen mạnh
                    CreateThread(function()
                        for i = 1, 5 do
                            SetTimecycleModifier('spectator5')
                            Wait(300)
                            ClearTimecycleModifier()
                            Wait(200)
                        end
                    end)

                    -- Ngã mạnh 2 lần
                    CreateThread(function()
                        SetPedToRagdoll(cache.ped, 3000, 3000, 0, true, true, false)
                        Wait(1000)
                        SetPedToRagdoll(cache.ped, 1500, 1500, 0, true, true, false)
                    end)

                    lastSleepinessEffect = GetGameTimer()
                    Notify('🚨 BẠN SẮP NGẤT! TÌM GIƯỜNG NGAY!', 'error', 6000)
                end

                -- Hiệu ứng liên tục
                if not sleepinessEffectActive then
                    --print('[SLEEPINESS] Activating continuous effects...')
                    SetTimecycleModifier('spectator5')
                    SetPedMoveRateOverride(cache.ped, 0.4)
                    SetPedMotionBlur(cache.ped, true)
                    sleepinessEffectActive = true
                end

            elseif sleepiness <= 15 then
                -- ⚠️ RẤT BUỒN NGỦ: <= 15%
                --print('[SLEEPINESS] RẤT BUỒN NGỦ - Sleepiness: ' .. sleepiness)

                if GetGameTimer() - lastSleepinessEffect > 15000 then
                    --print('[SLEEPINESS] Triggering moderate effects...')

                    CreateThread(function()
                        for i = 1, 3 do
                            SetTimecycleModifier('spectator5')
                            Wait(400)
                            ClearTimecycleModifier()
                            Wait(300)
                        end
                    end)

                    CreateThread(function()
                        SetPedToRagdoll(cache.ped, 1500, 1500, 0, true, true, false)
                    end)

                    lastSleepinessEffect = GetGameTimer()
                    Notify('😴 Bạn rất mệt và cần nghỉ ngơi ngay', 'info', 4000)
                end

                SetPedMoveRateOverride(cache.ped, 0.7)

            elseif sleepiness <= 30 then
                -- 💤 BẮT ĐẦU MỆT: <= 30%
                --print('[SLEEPINESS] BẮT ĐẦU MỆT - Sleepiness: ' .. sleepiness)

                if GetGameTimer() - lastSleepinessEffect > 30000 then
                    --print('[SLEEPINESS] Triggering light effects...')
                    lastSleepinessEffect = GetGameTimer()
                    Notify('😪 Bạn bắt đầu mệt mỏi', 'info', 3000)
                end

                SetPedMoveRateOverride(cache.ped, 0.9)

            else
                -- ✅ SLEEPINESS BÌNH THƯỜNG: Reset hiệu ứng
                if sleepinessEffectActive then
                    --print('[SLEEPINESS] Resetting effects - Sleepiness: ' .. sleepiness)
                    SetPedMotionBlur(cache.ped, false)
                    ClearTimecycleModifier()
                    SetPedMoveRateOverride(cache.ped, 1.0)
                    sleepinessEffectActive = false
                end
            end
        end

        ::continue::
    end
end)