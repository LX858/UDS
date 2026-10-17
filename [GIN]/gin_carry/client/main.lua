local isCarrying = false
local beingCarried = false
local currentTargetServerId = nil
local currentCarrierServerId = nil

--- Kiểm tra trạng thái chết / bất tỉnh của Ped (hỗ trợ qbx_medical, QBCore & StateBag)
---@param ped number
---@return boolean
local function isPedDead(ped)
    if not ped or not DoesEntityExist(ped) then return false end

    -- 1. Native GTA V health / dead checks
    if IsPedFatallyInjured(ped) or IsEntityDead(ped) or GetEntityHealth(ped) <= 0 then return true end

    -- 2. Kiểm tra Player StateBag (qbx_medical & QBCore)
    local playerIndex = NetworkGetPlayerIndexFromPed(ped)
    if playerIndex and playerIndex ~= -1 then
        local serverId = GetPlayerServerId(playerIndex)
        if serverId and serverId > 0 then
            local pState = Player(serverId).state
            if pState then
                if pState.isDead or pState.dead or pState.isdead or pState.inLaststand or pState.inlaststand then return true end
                local deathState = pState['qbx_medical:deathState']
                if deathState and (deathState == 2 or deathState == 3 or deathState > 1) then return true end -- 2 = LAST_STAND, 3 = DEAD
            end
        end
    end

    -- 3. Kiểm tra Entity StateBag (hỗ trợ thêm các framework khác)
    local entityState = Entity(ped).state
    if entityState then
        if entityState.isDead or entityState.dead or entityState.isdead or entityState.inLaststand or entityState.inlaststand then return true end
        local deathState = entityState['qbx_medical:deathState']
        if deathState and (deathState == 2 or deathState == 3 or deathState > 1) then return true end
    end

    -- 4. Kiểm tra Animation chết / giãy giụa / nằm gục (Writhe / Dead / LastStand animations)
    if IsEntityPlayingAnim(ped, 'combat@damage@writhe', 'writhe_loop', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_b', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_c', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_d', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_e', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_f', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_g', 3)
    or IsEntityPlayingAnim(ped, 'dead', 'dead_h', 3)
    or IsEntityPlayingAnim(ped, 'veh@low@front_ps@idle_duck', 'sit', 3) then
        return true
    end

    -- 5. Nếu là bản thân người chơi local ped, thử dùng export qbx_medical nếu có
    if ped == cache.ped and GetResourceState('qbx_medical') == 'started' then
        local pcallOk, isDead = pcall(function() return exports.qbx_medical:IsDead() or exports.qbx_medical:IsLaststand() end)
        if pcallOk and isDead then return true end
    end

    return false
end

--- Tải AnimDict một cách an toàn bằng ox_lib
---@param dict string
local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        lib.requestAnimDict(dict, 5000)
    end
end

--- Đăng ký Tương tác Player qua ox_target
CreateThread(function()
    Wait(1000) -- Đợi ox_target khởi tạo hoàn tất
    exports.ox_target:addGlobalPlayer({
        {
            name = 'gin_carry:carryPlayer',
            icon = Config.Locales.target_icon,
            label = Config.Locales.target_label,
            distance = Config.MaxDistance or 3.0,
            canInteract = function(entity, distance, coords, name, bone)
                if not entity or not DoesEntityExist(entity) then return false end
                if entity == cache.ped then return false end
                if isCarrying or beingCarried then return false end

                local targetPlayer = NetworkGetPlayerIndexFromPed(entity)
                if targetPlayer == -1 or targetPlayer == cache.playerId then return false end

                -- Chỉ cho phép vác khi đối phương đã chết hoặc bất tỉnh (Last Stand)
                return isPedDead(entity)
            end,
            onSelect = function(data)
                local targetPlayer = NetworkGetPlayerIndexFromPed(data.entity)
                if targetPlayer and targetPlayer ~= -1 then
                    -- Kiểm tra item trước khi gửi event
                    if Config.ItemName and Config.ItemName ~= '' then
                        local count = exports.ox_inventory:Search('count', Config.ItemName)
                        if not count or count < 1 then
                            lib.notify({
                                type = 'error',
                                description = Config.Locales.no_item
                            })
                            return
                        end
                    end
                    local targetServerId = GetPlayerServerId(targetPlayer)
                    TriggerServerEvent('gin_carry:server:startCarry', targetServerId)
                end
            end
        }
    })
end)

--- Sự kiện Đồng bộ Bắt đầu Vác từ Server
RegisterNetEvent('gin_carry:client:syncCarry', function(carrierServerId, targetServerId, isCarrier)
    if isCarrier then
        isCarrying = true
        currentTargetServerId = targetServerId

        loadAnimDict(Config.Animations.carrier.dict)
        TaskPlayAnim(cache.ped, Config.Animations.carrier.dict, Config.Animations.carrier.anim, 8.0, -8.0, -1, Config.Animations.carrier.flag, 0, false, false, false)

        lib.showTextUI(Config.Locales.drop_text_ui)
        lib.notify({
            type = 'info',
            description = Config.Locales.started_carrying
        })

        -- Vòng lặp giữ animation cho người vác
        CreateThread(function()
            while isCarrying do
                if not IsEntityPlayingAnim(cache.ped, Config.Animations.carrier.dict, Config.Animations.carrier.anim, 3) then
                    TaskPlayAnim(cache.ped, Config.Animations.carrier.dict, Config.Animations.carrier.anim, 8.0, -8.0, -1, Config.Animations.carrier.flag, 0, false, false, false)
                end
                Wait(1000)
            end
        end)
    else
        beingCarried = true
        currentCarrierServerId = carrierServerId

        lib.notify({
            type = 'warning',
            description = Config.Locales.being_carried_notify
        })

        -- Tìm Ped người vác và đính kèm (Attach)
        CreateThread(function()
            local carrierPed = 0
            local timeout = 5000
            local startTime = GetGameTimer()

            while carrierPed == 0 and (GetGameTimer() - startTime) < timeout and beingCarried do
                local carrierPlayerIndex = GetPlayerFromServerId(carrierServerId)
                if carrierPlayerIndex ~= -1 then
                    carrierPed = GetPlayerPed(carrierPlayerIndex)
                end
                Wait(100)
            end

            if carrierPed ~= 0 and DoesEntityExist(carrierPed) and beingCarried then
                AttachEntityToEntity(
                    cache.ped,
                    carrierPed,
                    GetPedBoneIndex(carrierPed, Config.Attach.bone),
                    Config.Attach.pos.x,
                    Config.Attach.pos.y,
                    Config.Attach.pos.z,
                    Config.Attach.rot.x,
                    Config.Attach.rot.y,
                    Config.Attach.rot.z,
                    true, true, false, true, 1, true
                )

                loadAnimDict(Config.Animations.target.dict)
                TaskPlayAnim(cache.ped, Config.Animations.target.dict, Config.Animations.target.anim, 8.0, -8.0, -1, Config.Animations.target.flag, 0, false, false, false)

                -- Vòng lặp giữ animation cho người được vác
                while beingCarried do
                    if not IsEntityPlayingAnim(cache.ped, Config.Animations.target.dict, Config.Animations.target.anim, 3) then
                        TaskPlayAnim(cache.ped, Config.Animations.target.dict, Config.Animations.target.anim, 8.0, -8.0, -1, Config.Animations.target.flag, 0, false, false, false)
                    end
                    Wait(1000)
                end
            end
        end)
    end
end)

--- Sự kiện Dừng / Thả người chơi từ Server
RegisterNetEvent('gin_carry:client:stopCarry', function()
    if isCarrying then
        isCarrying = false
        currentTargetServerId = nil
        ClearPedTasks(cache.ped)
        lib.hideTextUI()
        lib.notify({
            type = 'inform',
            description = Config.Locales.stopped_carrying
        })
    end

    if beingCarried then
        beingCarried = false
        currentCarrierServerId = nil
        DetachEntity(cache.ped, true, true)
        ClearPedTasks(cache.ped)
        lib.notify({
            type = 'inform',
            description = Config.Locales.stopped_carrying
        })
    end
end)

--- Đăng ký Keybind phím thả người qua ox_lib
lib.addKeybind({
    name = 'gin_carry_drop',
    description = 'Thả người chơi đang vác',
    defaultKey = Config.DropKey,
    onPressed = function()
        if isCarrying then
            TriggerServerEvent('gin_carry:server:stopCarry')
        end
    end
})

--- Đăng ký Lệnh phụ /dropcarry
RegisterCommand('dropcarry', function()
    if isCarrying then
        TriggerServerEvent('gin_carry:server:stopCarry')
    end
end, false)

--- Xử lý an toàn khi người vác bị chết
CreateThread(function()
    while true do
        Wait(500)
        if isCarrying and isPedDead(cache.ped) then
            TriggerServerEvent('gin_carry:server:stopCarry')
        end
    end
end)
