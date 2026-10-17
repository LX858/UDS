-- Anti Melee Trick (Fix đấm tay không nhanh) - Optimized version
-- Sử dụng StateBag và native events thay vì loop liên tục (Updated: Continuous monitoring on-foot)

local lastPunchTime = 0
local minPunchDelay = 500 -- Thời gian tối thiểu giữa các cú đấm (ms)
local punchResetTime = 2000 -- Reset số lần đấm sau 2 giây không đấm
local isAlreadyPunching = false
local abuseCount = 0
local warningShown = false

-- Export để check trạng thái cooldown từ các script khác (ví dụ: dr-animationmenu)
exports('IsMeleeCooldownActive', function()
    return GetGameTimer() - lastPunchTime < minPunchDelay
end)

-- Thread giám sát melee liên tục
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        
        -- Chỉ kiểm tra khi không ở trong xe, không mở NUI và không sử dụng mắt thần (ox_target - Left Alt)
        if not IsPedInAnyVehicle(ped, false) and not IsNuiFocused() and not IsControlPressed(0, 19) then
            local weapon = GetSelectedPedWeapon(ped)
            
            -- Chỉ áp dụng cho đấm tay không (WEAPON_UNARMED)
            if weapon == `WEAPON_UNARMED` or weapon == GetHashKey("WEAPON_UNARMED") then
                local currentTime = GetGameTimer()
                local timeSinceLastPunch = currentTime - lastPunchTime
                
                -- Block tất cả attack input nếu đang trong cooldown
                if timeSinceLastPunch < minPunchDelay then
                    DisableControlAction(0, 24, true)   -- Attack (left click)
                    DisableControlAction(0, 25, true)   -- Aim
                    DisableControlAction(0, 140, true)  -- Melee Attack Light
                    DisableControlAction(0, 141, true)  -- Melee Attack Heavy
                    DisableControlAction(0, 142, true)  -- Melee Attack Alternate
                    DisableControlAction(0, 143, true)  -- Melee Block
                    DisableControlAction(0, 257, true)  -- Attack 2
                    DisableControlAction(0, 263, true)  -- Melee Attack 1
                    DisableControlAction(0, 264, true)  -- Melee Attack 2
                    
                    -- Kiểm tra nếu người chơi cố tình nhấn nút tấn công khi đang cooldown (macro spam)
                    if IsDisabledControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 140) or 
                       IsDisabledControlJustPressed(0, 141) or IsDisabledControlJustPressed(0, 142) or
                       IsDisabledControlJustPressed(0, 257) or IsDisabledControlJustPressed(0, 263) or
                       IsDisabledControlJustPressed(0, 264) then
                        
                        abuseCount = abuseCount + 1
                        
                        -- Tăng số lần lạm dụng nhưng không cần báo về server nữa
                        if abuseCount >= 6 and not warningShown then
                            warningShown = true
                            -- TriggerServerEvent('XN_DevMode:server:LogMeleeAbuse', abuseCount)
                        end
                    end
                else
                    -- Hết cooldown, reset state khi không spam nữa
                    if timeSinceLastPunch > punchResetTime then
                        abuseCount = 0
                        warningShown = false
                    end
                    
                    -- Phát hiện cú click chuột đấm khi đã hết cooldown
                    if IsControlJustPressed(0, 24) or IsControlJustPressed(0, 140) or 
                       IsControlJustPressed(0, 141) or IsControlJustPressed(0, 142) or
                       IsControlJustPressed(0, 257) or IsControlJustPressed(0, 263) or
                       IsControlJustPressed(0, 264) then
                        
                        lastPunchTime = currentTime
                        abuseCount = 0
                        warningShown = false
                    end
                end
                
                -- Phát hiện bắt đầu hoạt ảnh đấm thực sự (cho cả trường hợp giữ chuột liên tục)
                local isPunching = IsPedPerformingMeleeAction(ped)
                if isPunching then
                    if not isAlreadyPunching then
                        isAlreadyPunching = true
                        lastPunchTime = currentTime
                        abuseCount = 0
                        warningShown = false
                    end
                else
                    isAlreadyPunching = false
                end
                
                -- Ngăn cancel animation bằng các nút di chuyển/nhảy khi đang thực hiện takedown/đấm đặc biệt
                if IsEntityPlayingAnim(ped, "melee@unarmed@streamed_core", "plyr_takedown_front", 3) or
                   IsEntityPlayingAnim(ped, "melee@unarmed@streamed_core", "plyr_takedown_rear", 3) or
                   IsEntityPlayingAnim(ped, "melee@unarmed@streamed_variations", "plyr_takedown_front", 3) then
                    DisableControlAction(0, 21, true) -- Sprint
                    DisableControlAction(0, 22, true) -- Jump
                end
                
                Wait(0)
            else
                Wait(500) -- Sleep lâu hơn nếu không phải tay không (WEAPON_UNARMED)
            end
        else
            Wait(500) -- Sleep lâu hơn nếu đang ở trong xe, mở NUI hoặc đang bấm mắt thần
        end
    end
end)
