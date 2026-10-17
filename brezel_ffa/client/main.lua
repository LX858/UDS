local currentLobby = nil
local currentZone = nil
local isInLobby = false
local isInFFA = false
local isMatchActive = false
local isRespawning = false
local entryPoint = nil
local playerData = {
    kills = 0,
    deaths = 0
}

local savedClothing = nil
local savedProps = nil

local COMPONENT_MAP = {
    ['mask'] = 1,
    ['hair'] = 2,
    ['arms'] = 3,
    ['pants'] = 4,
    ['bag'] = 5,
    ['shoes'] = 6,
    ['accessory'] = 7,
    ['tshirt'] = 8,
    ['bproof'] = 9,
    ['decals'] = 10,
    ['torso'] = 11
}

local function SaveCurrentClothing()
    if savedClothing then return end
    local ped = cache.ped or PlayerPedId()
    savedClothing = {}
    for compName, compId in pairs(COMPONENT_MAP) do
        savedClothing[compName] = {
            drawable = GetPedDrawableVariation(ped, compId),
            texture = GetPedTextureVariation(ped, compId)
        }
    end

    savedProps = {}
    for propId = 0, 7 do
        savedProps[propId] = {
            drawable = GetPedPropIndex(ped, propId),
            texture = GetPedPropTextureIndex(ped, propId)
        }
    end
end

local function ApplyFFAClothing()
    local ped = cache.ped or PlayerPedId()
    local model = GetEntityModel(ped)
    local gender = (model == `mp_m_freemode_01`) and 'male' or 'female'
    local clothingConfig = BS_C.DefaultClothing and BS_C.DefaultClothing[gender]

    if not clothingConfig then return end

    -- Xóa các props (mũ, kính, tai nghe) để không bị đè
    for propId = 0, 7 do
        ClearPedProp(ped, propId)
    end

    -- Áp dụng quần áo FFA
    for compName, data in pairs(clothingConfig) do
        local compId = COMPONENT_MAP[compName]
        if compId and data.drawable and data.drawable >= 0 then
            SetPedComponentVariation(ped, compId, data.drawable, data.texture or 0, 0)
        end
    end
end

local function IsWearingFFAUniform()
    local ped = cache.ped or PlayerPedId()
    local model = GetEntityModel(ped)
    local gender = (model == `mp_m_freemode_01`) and 'male' or 'female'
    local clothingConfig = BS_C.DefaultClothing and BS_C.DefaultClothing[gender]
    if not clothingConfig then return true end

    -- Kiểm tra tất cả các components xem có bị đổi không
    for compName, data in pairs(clothingConfig) do
        local compId = COMPONENT_MAP[compName]
        if compId and data.drawable and data.drawable >= 0 then
            if GetPedDrawableVariation(ped, compId) ~= data.drawable then
                return false
            end
        end
    end

    -- Kiểm tra props (không cho phép đội mũ, kính, tai nghe)
    for propId = 0, 7 do
        if GetPedPropIndex(ped, propId) ~= -1 then
            return false
        end
    end

    return true
end

-- Thread giám sát chống người chơi cố tình dùng trick/menu/item để đổi đồ trong FFA
CreateThread(function()
    while true do
        local sleep = 1500
        if (isInFFA or isInLobby) and not isRespawning then
            local ped = cache.ped or PlayerPedId()
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                if not IsWearingFFAUniform() then
                    ApplyFFAClothing()
                end
            end
        else
            sleep = 3000
        end
        Wait(sleep)
    end
end)

local function RestoreSavedClothing()
    local ped = cache.ped or PlayerPedId()

    if savedClothing and next(savedClothing) then
        for compName, data in pairs(savedClothing) do
            local compId = COMPONENT_MAP[compName]
            if compId and data.drawable and data.drawable >= 0 then
                SetPedComponentVariation(ped, compId, data.drawable, data.texture or 0, 0)
            end
        end
    end

    if savedProps and next(savedProps) then
        for propId, data in pairs(savedProps) do
            if data.drawable and data.drawable >= 0 then
                SetPedPropIndex(ped, propId, data.drawable, data.texture or 0, true)
            else
                ClearPedProp(ped, propId)
            end
        end
    end

    -- Tải lại đồ gốc từ database quần áo
    TriggerServerEvent('clothes:reloadPlayerClothes')
    if exports['illenium-appearance'] then
        pcall(function()
            TriggerEvent('illenium-appearance:client:reloadSkin')
        end)
    end

    savedClothing = nil
    savedProps = nil
end

function IsInFFA()
    return isInFFA or isInLobby
end
exports("IsInFFA", IsInFFA)

-- Create Blip and NPC Ped at FFA Entrance
CreateThread(function()
    local blipData = BS_C.FFA.blip
    if blipData then
        local blip = AddBlipForCoord(blipData.coords.x, blipData.coords.y, blipData.coords.z)
        SetBlipSprite(blip, blipData.sprite or 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, blipData.scale or 0.8)
        SetBlipColour(blip, blipData.color or 0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.name or "FFA")
        EndTextCommandSetBlipName(blip)
    end

    local pedConfig = BS_C.FFA.ped
    if pedConfig and pedConfig.model then
        local pedModel = joaat(pedConfig.model)
        lib.requestModel(pedModel, 5000)

        local ped = CreatePed(4, pedModel, pedConfig.coords.x, pedConfig.coords.y, pedConfig.coords.z, pedConfig.coords.w, false, false)
        SetEntityHeading(ped, pedConfig.coords.w)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        if pedConfig.animation then
            lib.requestAnimDict(pedConfig.animation.dict, 5000)
            TaskPlayAnim(ped, pedConfig.animation.dict, pedConfig.animation.name, 8.0, -8.0, -1, pedConfig.animation.flag or 1, 0, false, false, false)
        end
        SetModelAsNoLongerNeeded(pedModel)
    end
end)

local function HideQbxMedicalUI()
    if GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports['qbx_medical']:HideDeathUI()
        end)
    end
end

local function OpenFFAMenu()
    local userData = lib.callback.await('brezel_ffa:getuserdata', false)
    if userData then
        playerData = userData
    end

    local serverData = lib.callback.await('brezel_ffa:getdata', false)
    if serverData then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "openmainmenu",
            lobbys = serverData.lobbys or {},
            topplayers = serverData.topplayers or {},
            plrdata = playerData
        })
    end
end

-- ox_lib point for FFA Entrance Interaction
CreateThread(function()
    entryPoint = lib.points.new({
        coords = BS_C.FFA.open_coords,
        distance = 3.0,
        onEnter = function()
            if not isInFFA and not isInLobby then
                lib.showTextUI(BS_Locale("openffamenu"), {
                    position = "right-center",
                    icon = "crosshairs"
                })
            end
        end,
        onExit = function()
            if not isInLobby then
                lib.hideTextUI()
            end
        end,
        nearby = function(self)
            if not isInFFA and not isInLobby then
                DrawMarker(
                    BS_C.FFA.marker.type,
                    self.coords.x, self.coords.y, self.coords.z - 0.9,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    BS_C.FFA.marker.scale.x, BS_C.FFA.marker.scale.y, BS_C.FFA.marker.scale.z,
                    BS_C.FFA.marker.color.x, BS_C.FFA.marker.color.y, BS_C.FFA.marker.color.z,
                    120, false, false, 2, false, nil, nil, false
                )

                if IsControlJustPressed(0, 38) then -- Key E
                    lib.hideTextUI()
                    OpenFFAMenu()
                end
            end
        end
    })
end)

local function SetupFFAPedWeapons(lobbyKey)
    local ped = cache.ped
    local mapData = BS_C.FFA.maps[lobbyKey or currentLobby]
    local weaponsList = mapData and mapData.weapons or {"weapon_wrench"}

    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:weaponWheel(true)
        end)
    end

    for _, weaponModel in ipairs(weaponsList) do
        local hash = joaat(weaponModel)
        GiveWeaponToPed(ped, hash, 255, false, true)
        SetCurrentPedWeapon(ped, hash, true)
        SetPedCurrentWeaponVisible(ped, true, false, false, false)
        SetPedAmmo(ped, hash, 255)
    end
end

-- Ensure ped keeps weapon equipped during match
CreateThread(function()
    while true do
        local sleep = 1000
        if isInFFA and isMatchActive and not isRespawning then
            local ped = cache.ped
            if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then
                local currentWep = GetSelectedPedWeapon(ped)
                local mapData = BS_C.FFA.maps[currentLobby]
                local defaultWep = mapData and mapData.weapons and mapData.weapons[1] or "weapon_wrench"
                local targetHash = joaat(defaultWep)

                if currentWep ~= targetHash then
                    if not HasPedGotWeapon(ped, targetHash, false) then
                        GiveWeaponToPed(ped, targetHash, 255, false, true)
                    end
                    SetCurrentPedWeapon(ped, targetHash, true)
                    SetPedCurrentWeaponVisible(ped, true, false, false, false)
                end
            end
            sleep = 250
        end
        Wait(sleep)
    end
end)

local function TpToSpawnPoint()
    if not currentLobby or not BS_C.FFA.maps[currentLobby] then return end
    local spawnCoords = BS_C.FFA.maps[currentLobby].spawncoords
    if not spawnCoords or #spawnCoords == 0 then return end

    local selectedCoord = spawnCoords[math.random(1, #spawnCoords)]
    local ped = cache.ped
    local targetZ = selectedCoord.z + (BS_C.SpawnHeightOffset or 1.0)

    RequestCollisionAtCoord(selectedCoord.x, selectedCoord.y, targetZ)
    SetEntityCoords(ped, selectedCoord.x, selectedCoord.y, targetZ, false, false, false, true)
    SetEntityHeading(ped, selectedCoord.w or 0.0)
end

local function onZoneExit()
    if isInFFA and isMatchActive and not isRespawning then
        SetEntityHealth(cache.ped, 0)
    end
end

-- Anti-fall background thread
CreateThread(function()
    while true do
        if isInFFA and currentLobby and BS_C.AntiFallCheck then
            local ped = cache.ped
            if ped and DoesEntityExist(ped) and not isRespawning then
                local coords = GetEntityCoords(ped)
                local mapData = BS_C.FFA.maps[currentLobby]
                if mapData and mapData.border then
                    local borderZ = mapData.border.coords.z
                    local minZ = borderZ - (BS_C.AntiFallMinZOffset or 25.0)
                    if coords.z < minZ or coords.z < -40.0 then
                        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
                        TpToSpawnPoint()
                        SetEntityHealth(ped, 200)
                        BS_C.Notify(BS_Locale("anti_fall_rescue"), "warning")
                    end
                end
            end
            Wait(500)
        else
            Wait(2000)
        end
    end
end)

-- Infinite ammo thread when in active FFA match
CreateThread(function()
    while true do
        if isInFFA and isMatchActive and currentLobby and BS_C.FFA.maps[currentLobby] then
            local ped = cache.ped
            for _, weaponModel in ipairs(BS_C.FFA.maps[currentLobby].weapons) do
                local hash = joaat(weaponModel)
                SetPedInfiniteAmmo(ped, true, hash)
                SetPedInfiniteAmmoClip(ped, true)
            end
            Wait(1000)
        else
            Wait(2000)
        end
    end
end)

local function StartMatchFlow(lobbyKey, countdownTime)
    currentLobby = lobbyKey
    isInLobby = true
    isInFFA = true
    isMatchActive = false
    isRespawning = false

    SendNUIMessage({
        type = "hidewaiting"
    })
    lib.hideTextUI()

    SaveCurrentClothing()
    ApplyFFAClothing()

    HideQbxMedicalUI()

    -- Teleport to spawn point with Z + 1.0 and freeze player during countdown
    local ped = cache.ped
    TpToSpawnPoint()
    FreezeEntityPosition(ped, true)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)

    -- 5s Countdown Loop (5 -> 1 -> START)
    local timer = countdownTime or BS_C.CountdownSeconds or 5
    while timer > 0 do
        lib.showTextUI(string.format("TRẬN ĐẤU BẮT ĐẦU TRONG: %d", timer), {
            position = "top-center",
            icon = "clock"
        })
        PlaySoundFrontend(-1, "5s_To_Event_Start_Countdown", "GTAO_FM_Events_Soundset", true)
        Wait(1000)
        timer = timer - 1
    end

    -- Match Starts!
    lib.hideTextUI()
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", true)
    BS_C.Notify(BS_Locale("match_started"), "success")

    FreezeEntityPosition(ped, false)
    isMatchActive = true

    -- Give weapon_wrench
    SetupFFAPedWeapons(lobbyKey)
    ApplyFFAClothing()

    -- Setup border zone
    local mapBorder = BS_C.FFA.maps[lobbyKey] and BS_C.FFA.maps[lobbyKey].border
    if mapBorder then
        if currentZone then currentZone:remove() end
        currentZone = lib.zones.sphere({
            coords = mapBorder.coords,
            radius = mapBorder.radius,
            debug = mapBorder.visible or false,
            onExit = onZoneExit
        })
    end

    SendNUIMessage({
        type = "openingame",
        plrdata = playerData
    })

    BS_C.OnJoin()
end

RegisterNetEvent('brezel_ffa:client:startMatch', function(lobbyKey, countdownTime)
    StartMatchFlow(lobbyKey, countdownTime)
end)

RegisterNUICallback("joinLobby", function(data, cb)
    local lobbyKey = data.lobby
    cb({})
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closemenu"
    })

    local joinResult = lib.callback.await('brezel_ffa:join', false, lobbyKey)

    if joinResult and joinResult.success then
        currentLobby = lobbyKey
        isInLobby = true
        isRespawning = false

        SaveCurrentClothing()
        ApplyFFAClothing()

        HideQbxMedicalUI()

        if joinResult.started then
            -- Match already in progress, join directly
            SendNUIMessage({ type = "hidewaiting" })
            StartMatchFlow(lobbyKey, 0)
        else
            -- Waiting for admin to start: hiển thị UI nhỏ ở bottom center
            local mapName = BS_C.FFA.maps[lobbyKey] and BS_C.FFA.maps[lobbyKey].name or lobbyKey
            BS_C.Notify(BS_Locale("waiting_in_lobby"), "info")
            SendNUIMessage({
                type = "showwaiting",
                mapName = mapName,
                playerCount = joinResult.playerCount or 1,
                maxPlayers = joinResult.maxPlayers or 16
            })
        end
    elseif joinResult and joinResult.banned then
        BS_C.Notify(BS_Locale("player_banned_from_ffa") or "Bạn đã bị cấm tham gia đấu trường FFA!", "error")
    else
        BS_C.Notify(BS_Locale("lobby_full"), "error")
    end
end)

local function RevivePlayerInFFA()
    isRespawning = true

    -- Cancel FFA deathscreen NUI immediately
    SendNUIMessage({
        type = "canceldeathscreen"
    })

    -- Yêu cầu Server thực hiện hồi sinh chuẩn qua qbx_medical
    TriggerServerEvent('brezel_ffa:server:revivePlayer')
end

-- Hook sự kiện chính thức sau khi qbx_medical đã hoàn tất quy trình hồi sinh
AddEventHandler('qbx_medical:client:onPlayerRevived', function()
    if isInFFA and isMatchActive then
        local ped = cache.ped or PlayerPedId()

        -- Teleport đến vị trí an toàn Z + 1.0
        TpToSpawnPoint()

        -- Set đầy đủ Máu & 100 Giáp ngay lập tức (không cần thread chờ)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)

        -- Trang bị lại vũ khí và quần áo
        SetupFFAPedWeapons(currentLobby)
        ApplyFFAClothing()

        BS_C.OnRespawn()
        isRespawning = false
    end
end)

local function Deathscreen(killerName, duration)
    SendNUIMessage({
        type = "startdeathscreen",
        killer = killerName,
        time = duration
    })
end

-- Detect player death in FFA
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    if not isInFFA or not isMatchActive or isRespawning then return end

    local victim = data[1]
    local attacker = data[2]
    local victimDied = data[4]
    local isFatal = (victimDied == 1 or victimDied == true or data[6] == 1)

    -- Must be the local player ped
    if not IsEntityAPed(victim) or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId then return end

    -- Must actually be dead / fatally injured or health <= 0
    if not isFatal and not IsEntityDead(cache.ped) and not IsPedFatallyInjured(cache.ped) and GetEntityHealth(cache.ped) > 0 then
        return
    end

    if not IsEntityDead(cache.ped) and GetEntityHealth(cache.ped) > 0 then
        return
    end

    isRespawning = true
    playerData.deaths = playerData.deaths + 1

    -- Ensure qbx_medical death screen & Island UI are hidden
    HideQbxMedicalUI()

    SendNUIMessage({
        type = "updatestats",
        plrdata = playerData
    })

    local killerServerId = nil
    local killerName = BS_Locale("unknown")

    if attacker and attacker ~= 0 and attacker ~= cache.ped then
        local attackerPlayerIndex = NetworkGetPlayerIndexFromPed(attacker)
        if attackerPlayerIndex and attackerPlayerIndex ~= -1 then
            killerServerId = GetPlayerServerId(attackerPlayerIndex)
            killerName = GetPlayerName(attackerPlayerIndex)
        end
    end

    Deathscreen(killerName, 3)
    BS_C.OnDeath()

    TriggerServerEvent('brezel_ffa:server:onDeath', killerServerId)

    SetTimeout(3000, function()
        if isInFFA and isMatchActive then
            RevivePlayerInFFA()
        end
    end)
end)

RegisterNetEvent('brezel_ffa:client:kill', function()
    if isInFFA then
        playerData.kills = playerData.kills + 1
        SendNUIMessage({
            type = "updatestats",
            plrdata = playerData
        })
    end
end)

RegisterNetEvent('brezel_ffa:client:killmessage', function(killer, victim)
    if isInFFA then
        SendNUIMessage({
            type = "sendkillfeedmsg",
            killer = killer,
            victim = victim
        })
    end
end)

local function LeaveFFA()
    if not isInFFA and not isInLobby then return end

    lib.hideTextUI()

    SendNUIMessage({
        type = "canceldeathscreen"
    })
    SendNUIMessage({
        type = "leavegame"
    })

    HideQbxMedicalUI()

    local ped = cache.ped
    FreezeEntityPosition(ped, false)

    if currentLobby and BS_C.FFA.maps[currentLobby] then
        for _, weaponModel in ipairs(BS_C.FFA.maps[currentLobby].weapons) do
            SetPedInfiniteAmmo(ped, false, joaat(weaponModel))
            SetPedInfiniteAmmoClip(ped, false)
        end
    end

    if currentZone then
        currentZone:remove()
        currentZone = nil
    end

    -- Resurrect and heal
    local entranceCoords = BS_C.FFA.open_coords
    NetworkResurrectLocalPlayer(entranceCoords.x, entranceCoords.y, entranceCoords.z + 0.5, 0.0, true, false)
    ClearPedTasksImmediately(ped)
    SetPedCanRagdoll(ped, true)
    SetEntityInvincible(ped, false)
    SetEntityCoords(ped, entranceCoords.x, entranceCoords.y, entranceCoords.z, false, false, false, true)
    SetEntityHealth(ped, 200)

    -- Remove FFA ped weapons
    RemoveAllPedWeapons(ped, true)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)

    if GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:weaponWheel(false)
        end)
    end

    -- Khôi phục lại quần áo gốc của người chơi
    RestoreSavedClothing()

    isInLobby = false
    isInFFA = false
    isMatchActive = false
    isRespawning = false
    currentLobby = nil

    BS_C.OnLeave()
    BS_C.Notify("Bạn đã rời khỏi đấu trường FFA", "info")
end

RegisterNetEvent('brezel_ffa:client:leave', function()
    LeaveFFA()
end)

RegisterCommand(BS_C.LeaveFFACommand, function()
    if isInFFA or isInLobby then
        lib.callback.await('brezel_ffa:leave', false)
        LeaveFFA()
    end
end, false)

RegisterNUICallback("close", function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closemenu"
    })
    cb({})
end)

RegisterNUICallback("getLocales", function(data, cb)
    cb(BS_Locale("ui"))
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.hideTextUI()
        if entryPoint then
            entryPoint:remove()
        end
        if currentZone then
            currentZone:remove()
        end
        if isInFFA or isInLobby then
            LeaveFFA()
        end
    end
end)
