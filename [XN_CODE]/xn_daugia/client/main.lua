local isUIOpen = false
local currentAuction = nil
local overheadBidder = nil -- { serverId, name, price, formattedPrice, countdown }

-- Helper: Format tiền tệ (vd: 1,000,000)
local function FormatMoney(amount)
    local formatted = tostring(math.floor(amount or 0))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Helper: Draw Text 3D cao cấp với background badge
local function DrawText3D(coords, text1, text2, progressRatio)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local camCoords = GetGameplayCamCoords()
    local distance = #(camCoords - coords)
    local scale = (Config.Overhead.scale / distance) * 2.0
    local fov = (1.0 / GetGameplayCamFov()) * 100.0
    scale = scale * fov

    SetTextScale(scale * 1.1, scale * 1.1)
    SetTextFont(Config.Overhead.font or 4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(1)

    -- Vẽ Text Dòng 1: Đặt thầu
    SetTextEntry("STRING")
    AddTextComponentString(text1)
    DrawText(_x, _y - 0.028 * scale * 10.0)

    -- Vẽ Text Dòng 2: Đếm ngược
    SetTextScale(scale * 0.95, scale * 0.95)
    SetTextEntry("STRING")
    AddTextComponentString(text2)
    DrawText(_x, _y)

    -- Vẽ Background box mờ hiện đại
    local factor1 = string.len(text1) / 360.0
    local factor2 = string.len(text2) / 360.0
    local maxFactor = math.max(factor1, factor2) * (scale * 8.5)
    local height = 0.058 * (scale * 8.5)
    
    DrawRect(_x, _y - 0.012 * scale * 10.0, maxFactor + 0.02, height, 15, 18, 28, 190)

    -- Vẽ viền / Thanh tiến trình countdown bên dưới box
    if progressRatio and progressRatio > 0 then
        local barWidth = (maxFactor + 0.02) * math.max(0.0, math.min(1.0, progressRatio))
        local r = math.floor(255 * (1.0 - progressRatio))
        local g = math.floor(220 * progressRatio)
        DrawRect(_x - ((maxFactor + 0.02) - barWidth) / 2, _y - 0.012 * scale * 10.0 + (height / 2), barWidth, 0.004, r, g, 50, 240)
    end
end

local overheadWasVisible = false

-- Thread Render Realtime 3D Overhead trên đầu người đặt cược cao nhất
CreateThread(function()
    while true do
        local sleep = 500

        if overheadBidder and overheadBidder.countdown and overheadBidder.countdown > 0 then
            local targetPlayer = GetPlayerFromServerId(overheadBidder.serverId)
            local targetPed = 0

            if targetPlayer ~= -1 then
                targetPed = GetPlayerPed(targetPlayer)
            elseif overheadBidder.serverId == GetPlayerServerId(PlayerId()) then
                targetPed = PlayerPedId()
            end

            if targetPed ~= 0 and DoesEntityExist(targetPed) then
                local myCoords = GetEntityCoords(PlayerPedId())
                local pedCoords = GetEntityCoords(targetPed)
                local distance = #(myCoords - pedCoords)
                local maxDist = Config.Overhead.drawDistance or 35.0

                if distance <= maxDist then
                    sleep = 0
                    local headCoords = GetPedBoneCoords(targetPed, 31086, 0.0, 0.0, 0.0)
                    local drawPos = vector3(headCoords.x, headCoords.y, headCoords.z + (Config.Overhead.heightOffset or 0.65))

                    local onScreen, _x, _y = World3dToScreen2d(drawPos.x, drawPos.y, drawPos.z)

                    if onScreen then
                        local scale = math.max(0.60, math.min(1.0, 1.0 - (distance / maxDist) * 0.45))
                        local ratio = overheadBidder.countdown / (Config.CountdownSeconds or 10)

                        SendNUIMessage({
                            action = 'updateOverhead',
                            visible = true,
                            x = _x * 100,
                            y = _y * 100,
                            scale = scale,
                            name = overheadBidder.name or 'Người Chơi',
                            serverId = overheadBidder.serverId,
                            price = overheadBidder.formattedPrice or FormatMoney(overheadBidder.price),
                            countdown = overheadBidder.countdown,
                            ratio = ratio
                        })
                        overheadWasVisible = true
                    else
                        if overheadWasVisible then
                            SendNUIMessage({ action = 'updateOverhead', visible = false })
                            overheadWasVisible = false
                        end
                    end
                else
                    if overheadWasVisible then
                        SendNUIMessage({ action = 'updateOverhead', visible = false })
                        overheadWasVisible = false
                    end
                end
            else
                if overheadWasVisible then
                    SendNUIMessage({ action = 'updateOverhead', visible = false })
                    overheadWasVisible = false
                end
            end
        else
            if overheadWasVisible then
                SendNUIMessage({ action = 'updateOverhead', visible = false })
                overheadWasVisible = false
            end
        end

        Wait(sleep)
    end
end)

-- ===========================
-- NUI EVENT HANDLERS
-- ===========================

-- Mở giao diện NUI Đấu Giá
RegisterNetEvent('xn_daugia:client:openAuctionUI', function(data)
    data.myServerId = GetPlayerServerId(PlayerId())
    currentAuction = data
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = data
    })
end)

-- Đồng bộ State Đấu Giá
RegisterNetEvent('xn_daugia:client:syncAuctionState', function(data)
    data.myServerId = GetPlayerServerId(PlayerId())
    currentAuction = data
    if isUIOpen then
        SendNUIMessage({
            action = 'updateState',
            data = data
        })
    end
end)

-- Đồng bộ Đếm ngược từ Server
RegisterNetEvent('xn_daugia:client:syncCountdown', function(countdown, bidderId)
    if overheadBidder then
        overheadBidder.countdown = countdown
        if countdown <= 0 then
            overheadBidder = nil
        end
    end

    if isUIOpen then
        SendNUIMessage({
            action = 'updateCountdown',
            countdown = countdown
        })
    end
end)

-- Helper: Chạy animation vẫy tay gọi thầu (friends@frj@ig_1 / wave_e)
local function PlayBidAnimation(targetPed)
    local ped = targetPed or PlayerPedId()
    if not DoesEntityExist(ped) then return end

    local dict = "friends@frj@ig_1"
    local anim = "wave_e"

    CreateThread(function()
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end

        if HasAnimDictLoaded(dict) and DoesEntityExist(ped) then
            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 2500, 49, 0, false, false, false)
            RemoveAnimDict(dict)
        end
    end)
end

-- Khi có người đặt cược mới -> Hiển thị trên đầu người đó & chạy animation
RegisterNetEvent('xn_daugia:client:bidPlacedOverhead', function(data)
    overheadBidder = {
        serverId = data.source,
        name = data.name,
        price = data.price,
        formattedPrice = data.formattedPrice,
        countdown = data.countdown or Config.CountdownSeconds
    }

    -- Kích hoạt Animation vẫy tay cho người đặt thầu
    local targetPlayer = GetPlayerFromServerId(data.source)
    local targetPed = 0
    if targetPlayer ~= -1 then
        targetPed = GetPlayerPed(targetPlayer)
    elseif data.source == GetPlayerServerId(PlayerId()) then
        targetPed = PlayerPedId()
    end

    if targetPed ~= 0 and DoesEntityExist(targetPed) then
        PlayBidAnimation(targetPed)
    end

    -- Âm thanh thông báo khi có người bid
    if Config.Overhead.enableSound then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end)

-- Khi phiên đấu giá kết thúc
RegisterNetEvent('xn_daugia:client:auctionEnded', function(resultData)
    overheadBidder = nil
    if currentAuction then
        currentAuction.state = 'ENDED'
    end

    -- Mở hoặc cập nhật bảng kết quả người chiến thắng
    SendNUIMessage({
        action = 'auctionEnded',
        data = resultData
    })
    SendNUIMessage({ action = 'updateOverhead', visible = false })

    PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", true)
end)

-- Khi phiên đấu giá bị huỷ
RegisterNetEvent('xn_daugia:client:auctionCancelled', function()
    overheadBidder = nil
    currentAuction = nil
    if isUIOpen then
        isUIOpen = false
        SetNuiFocus(false, false)
    end
    SendNUIMessage({
        action = 'close'
    })
    SendNUIMessage({ action = 'updateOverhead', visible = false })
end)

-- Broadcast notify popup
RegisterNetEvent('xn_daugia:client:broadcastNotify', function(message, notifyType)
    if exports.qbx_core and exports.qbx_core.Notify then
        exports.qbx_core:Notify(message, notifyType or 'primary')
    elseif GetResourceState('ox_lib') == 'started' then
        TriggerEvent('ox_lib:notify', {
            title = 'Đấu Giá',
            description = message,
            type = (notifyType == 'primary' and 'info') or notifyType
        })
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 215, 0 },
            multiline = true,
            args = { "[ĐẤU GIÁ]", message }
        })
    end
end)

-- ===========================
-- NUI CALLBACKS
-- ===========================

-- Đóng NUI
RegisterNUICallback('close', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Đặt cược từ NUI (Giữ UI mở realtime theo yêu cầu)
RegisterNUICallback('placeBid', function(data, cb)
    local addedAmount = tonumber(data.addedAmount)
    local expectedPrice = tonumber(data.expectedPrice)

    if addedAmount and addedAmount > 0 then
        PlayBidAnimation(PlayerPedId())
        TriggerServerEvent('xn_daugia:server:placeBid', addedAmount, expectedPrice)
    end

    cb('ok')
end)

-- Request sync state khi NUI mở
RegisterNUICallback('requestState', function(data, cb)
    TriggerServerEvent('xn_daugia:server:requestState')
    cb('ok')
end)

-- Phím tắt ESC để đóng NUI nếu đang mở
RegisterCommand('+closeAuctionUI', function()
    if isUIOpen then
        isUIOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    end
end, false)
RegisterKeyMapping('+closeAuctionUI', 'Đóng UI Đấu Giá', 'keyboard', 'ESCAPE')
