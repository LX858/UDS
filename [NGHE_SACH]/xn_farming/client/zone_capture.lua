-- ============================================================
--  xn_farming — Chiếm khu (client): marker đỏ, prompt bấm E, banner, blip
--  Tối ưu: chỉ chạy Wait(0) khi người chơi đứng gần marker; NUI chỉ nhận
--  message khi trạng thái đổi (đồng hồ đếm ngược do JS tự chạy).
-- ============================================================

local QBCore = exports['qb-core']:GetCoreObject()
local STATE_KEY = 'xnCapture:'
local INTERACT_KEY = 38 -- E

local zones = {}

local function normalizeGang(name)
    if not name then return nil end
    name = tostring(name):lower():gsub('%s+', '')
    if name == '' or name == 'none' or name == 'nogang' or name == 'no_gang'
        or name == 'unaffiliated' or name == 'civilian' then
        return nil
    end
    return name
end

local function myGang()
    local pd = QBCore.Functions.GetPlayerData()
    return normalizeGang(pd and pd.gang and pd.gang.name)
end

-- ==================== NUI ====================
-- Gửi lại định kỳ dù trạng thái không đổi: trang NUI có thể chưa tải xong khi
-- resource vừa restart, tin nhắn gửi sớm sẽ bị mất.
local RESEND_MS = 3000
local bannerSig, promptSig
local bannerSentAt, promptSentAt = 0, 0

local function setBanner(sig, payload)
    local now = GetGameTimer()
    if sig == bannerSig and now - bannerSentAt < RESEND_MS then return end
    bannerSig = sig
    bannerSentAt = now
    if payload then
        payload.action, payload.visible = 'zoneBanner', true
        SendNUIMessage(payload)
    else
        SendNUIMessage({ action = 'zoneBanner', visible = false })
    end
end

local function setPrompt(sig, payload)
    local now = GetGameTimer()
    if sig == promptSig and now - promptSentAt < RESEND_MS then return end
    promptSig = sig
    promptSentAt = now
    if payload then
        payload.action, payload.visible = 'zonePrompt', true
        SendNUIMessage(payload)
    else
        SendNUIMessage({ action = 'zonePrompt', visible = false })
    end
end

-- ==================== BLIP ====================
local function refreshBlip(z)
    if z.blip then RemoveBlip(z.blip); z.blip = nil end
    local st = z.state
    if not z.cfg.blip or not st or st.phase == 'idle' then return end

    local blip = AddBlipForRadius(z.center.x, z.center.y, z.center.z, z.radius + 0.0)
    SetBlipColour(blip, st.phase == 'capturing' and 1 or 17)
    SetBlipAlpha(blip, 110)
    SetBlipFlashes(blip, st.phase == 'capturing')
    z.blip = blip
end

-- ==================== STATE ====================
CreateThread(function()
    for id, zone in pairs(FarmRental and FarmRental.FarmZones or {}) do
        if zone.capture and zone.center and zone.radius then
            local z = {
                id = id,
                cfg = zone.capture,
                center = zone.center,
                radius = zone.radius,
                center2 = vector2(zone.center.x, zone.center.y),
                version = 0,
            }
            zones[id] = z

            z.state = GlobalState[STATE_KEY .. id]
            refreshBlip(z)

            AddStateBagChangeHandler(STATE_KEY .. id, 'global', function(_, _, value)
                z.state = value
                z.version = z.version + 1
                refreshBlip(z)
            end)
        end
    end
    if next(zones) == nil then return end

    local lastPress = 0

    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local pos2 = vector2(pos.x, pos.y)
        local sleep = 1500
        local active, dist

        for _, z in pairs(zones) do
            local d = #(pos2 - z.center2)
            if d <= z.radius then active, dist = z, d; break end
        end

        if not active then
            setBanner(nil, nil)
            setPrompt(nil, nil)
        else
            local st = active.state or { phase = 'idle', cd = {} }
            local now = GetCloudTimeAsInt()
            local phase = st.phase
            if phase == 'held' and (st.endsAt or 0) <= now then phase = 'idle' end

            if phase == 'idle' then
                setBanner('idle:' .. active.id, { mode = 'idle', remain = 0 })
            else
                setBanner(('%s:%d:%s'):format(phase, active.id, st.endsAt or 0), {
                    mode = phase,
                    label = st.label,
                    remain = (st.endsAt or now) - now,
                    total = phase == 'capturing' and active.cfg.captureTime or active.cfg.holdTime,
                })
            end

            sleep = 500
            if dist <= 45.0 then
                sleep = 0
                local size = active.cfg.markerRadius * 2.0
                if phase ~= 'held' then
                    local alpha = 120
                    if phase == 'capturing' then
                        alpha = 90 + math.floor(70 * (0.5 + 0.5 * math.sin(GetGameTimer() / 250.0)))
                    end
                    DrawMarker(1, active.center.x, active.center.y, active.center.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size, size, 1.5,
                        255, 25, 25, alpha, false, false, 2, false, nil, nil, false)
                end

                local canInteract = dist <= active.cfg.markerRadius
                    and not IsEntityDead(ped)

                if not canInteract then
                    setPrompt(nil, nil)
                elseif phase == 'capturing' then
                    setPrompt('cap:' .. (st.endsAt or 0), {
                        text = 'Đang chiếm khu vực... Hoàn tất sau',
                        remain = (st.endsAt or now) - now,
                    })
                elseif phase == 'held' then
                    setPrompt('held:' .. (st.endsAt or 0), {
                        text = 'Khu vực đang bị chiếm giữ. Mở lại sau',
                        remain = (st.endsAt or now) - now,
                    })
                else
                    local gang = myGang()
                    local cdUntil = gang and st.cd and st.cd[gang] or 0
                    if not gang then
                        setPrompt('nogang', { text = 'Bạn cần thuộc một xã đoàn để chiếm khu vực' })
                    elseif cdUntil > now then
                        setPrompt('cd:' .. cdUntil, {
                            text = 'Xã đoàn của bạn đang bị khóa chiếm khu. Thử lại sau',
                            remain = cdUntil - now,
                        })
                    else
                        setPrompt('start', { text = 'Bấm E để chiếm quyền sở hữu', key = 'E' })
                        local t = GetGameTimer()
                        if IsControlJustPressed(0, INTERACT_KEY) and t - lastPress > 1500 then
                            lastPress = t
                            TriggerServerEvent('xn_farming:zone:startCapture', active.id)
                        end
                    end
                end
            else
                setPrompt(nil, nil)
            end
        end

        Wait(sleep)
    end
end)

-- Chẩn đoán: /zonedebug in trạng thái ra F8 + chat và ép hiện banner thử 6 giây
RegisterCommand('zonedebug', function()
    local pos = GetEntityCoords(PlayerPedId())
    local count = 0
    for _ in pairs(zones) do count = count + 1 end

    local lines = { ('[zonedebug] số khu có capture: %d'):format(count) }
    for id, z in pairs(zones) do
        local d = #(vector2(pos.x, pos.y) - z.center2)
        local st = GlobalState[STATE_KEY .. id]
        lines[#lines + 1] = ('[zonedebug] khu %d: cách tâm %.1fm / bán kính %.1f | phase server = %s | bannerSig = %s'):format(
            id, d, z.radius, st and st.phase or 'NIL (server chưa publish)', tostring(bannerSig))
    end
    for _, l in ipairs(lines) do
        print(l)
        TriggerEvent('chat:addMessage', { args = { l } })
    end

    SendNUIMessage({ action = 'zoneBanner', visible = true, mode = 'idle', remain = 0 })
    SetTimeout(6000, function()
        bannerSig = nil
        SendNUIMessage({ action = 'zoneBanner', visible = false })
    end)
end, false)
