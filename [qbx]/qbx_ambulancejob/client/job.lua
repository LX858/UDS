local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()

---Wrapper để tạo hóa đơn từ client
RegisterNetEvent('hospital:client:CreateInvoiceWrapper', function(invoiceData)
    --print("^2[CLIENT INVOICE] Received invoice data:^0", json.encode(invoiceData))
    --print("^3[CLIENT INVOICE] Triggering server event okokBilling:CreateInvoice^0")

    -- Trigger SERVER event của okokBilling từ client này
    -- Source sẽ tự động là client này (doctor)
    TriggerServerEvent("okokBilling:CreateInvoice", invoiceData)

    --print("^2[CLIENT INVOICE] Server event triggered^0")
end)

---Set máu cho người chơi hiện tại
RegisterNetEvent('hospital:client:SetHealth', function(health)
    local ped = PlayerPedId()
    SetEntityHealth(ped, health)
    --print("^2[HEALTH] Set player health to:^0", health)
end)

---Freeze/Unfreeze người chơi trong lúc được điều trị
local beingTreated = false
RegisterNetEvent('hospital:client:SetBeingTreated', function(freeze)
    beingTreated = freeze
    local ped = PlayerPedId()

    if freeze then
        FreezeEntityPosition(ped, true)
        -- Disable controls trong lúc được điều trị
        CreateThread(function()
            while beingTreated do
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true) -- Camera movement
                EnableControlAction(0, 2, true)
                EnableControlAction(0, 249, true) -- N key - mở chat
                Wait(0)
            end
        end)
    else
        FreezeEntityPosition(ped, false)
    end
end)

---Reset toàn bộ injuries và pain
RegisterNetEvent('hospital:client:ResetAllInjuries', function()
    -- Remove all bleeds
    for i = 1, 10 do
        pcall(function()
            exports.qbx_medical:RemoveBleed(1)
        end)
    end

    -- Disable rồi enable lại damage effects để reset pain
    pcall(function()
        exports.qbx_medical:DisableDamageEffects()
    end)

    Wait(100)

    pcall(function()
        exports.qbx_medical:EnableDamageEffects()
    end)

    --print("^2[INJURIES] Reset all injuries and pain^0")
end)---Configures and spawns a vehicle and teleports player to the driver seat.
---@param data { vehicleName: string, coords: vector4}
local function takeOutVehicle(data)
    local netId = lib.callback.await('qbx_ambulancejob:server:spawnVehicle', false, data.vehicleName, data.coords)

    local veh = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)

    SetVehicleEngineOn(veh, true, true, true)

    local settings = config.vehicleSettings[data.vehicleName]
    if not settings then return end

    if settings.extras then
        qbx.setVehicleExtras(veh, settings.extras)
    end

    if settings.livery then
        SetVehicleLivery(veh, settings.livery)
    end
end

---Show the garage spawn menu
---@param vehicles AuthorizedVehicles
---@param coords vector4
local function showGarageMenu(vehicles, coords)
    local gradeLevel = GetJobGradeLevel()
    local authorizedVehicles = vehicles[gradeLevel] or {}
    local optionsMenu = {}
    for veh, label in pairs(authorizedVehicles) do
        optionsMenu[#optionsMenu + 1] = {
            title = label,
            onSelect = takeOutVehicle,
            args = {
                vehicleName = veh,
                coords = coords,
            }
        }
    end

    lib.registerContext({
        id = 'ambulance_garage_context_menu',
        title = locale('menu.amb_vehicles'),
        options = optionsMenu
    })

    lib.showContext('ambulance_garage_context_menu')
end

---Show patient's treatment menu.
---@param status string[]
local function showTreatmentMenu(status)
    local statusMenu = {}
    for i = 1, #status do
        statusMenu[i] = {
            title = status[i],
            event = 'hospital:client:TreatWounds',
        }
    end

    lib.registerContext({
        id = 'ambulance_status_context_menu',
        title = locale('menu.status'),
        options = statusMenu
    })

    lib.showContext('ambulance_status_context_menu')
end

---Check status of nearest player and show treatment menu.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:CheckStatus', function()
    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    local playerId = GetPlayerServerId(player)

    local status = lib.callback.await('qbx_ambulancejob:server:getPlayerStatus', false, playerId)
    if #status.injuries == 0 then
        exports.qbx_core:Notify(locale('success.healthy_player'), 'success')
        return
    end

    for hash in pairs(status.damageCauses) do
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { locale('info.status'), WEAPONS[hash].damagereason }
        })
    end

    if status.bleedLevel > 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            multiline = false,
            args = { locale('info.status'), locale('info.is_status', status.bleedState) }
        })
    end

    showTreatmentMenu(status.injuries)
end)

---Use first aid on nearest player to revive them.
---Intended to be invoked by client or server.
---
---
---

RegisterNetEvent('hospital:client:RevivePlayertwo', function()
    -- Tự hồi sinh khi không có bác sĩ
    local playerId = GetPlayerServerId(PlayerId())
    local nearestHospital = nil
    local nearestDistance = math.huge

    -- Tìm bệnh viện gần nhất
    local playerCoords = GetEntityCoords(PlayerPedId())
    for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
        if hospital.coords then
            local distance = #(playerCoords - hospital.coords.xyz)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestHospital = hospitalName
            end
        end
    end

    if nearestHospital then
        exports['progressbar']:Progress({
            name = "self_revive",
            duration = 5000,
            label = 'Đang tự cứu chữa...',
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
                exports.qbx_core:Notify('Bạn đã tự hồi sinh và được đưa đến bệnh viện', 'success')
                TriggerServerEvent('hospital:server:RevivePlayer', playerId)
                Wait(1000)
                local bedIndex = math.random(1, 5)
                TriggerServerEvent('hospital:server:putPlayerInBedrv2', playerId, nearestHospital, bedIndex)
            else
                exports.qbx_core:Notify('Quá trình tự cứu chữa bị hủy bỏ', 'error')
            end
        end)
    else
        exports.qbx_core:Notify('Không tìm thấy bệnh viện gần nhất', 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    local playerPed = PlayerPedId()
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    local playerInVehicle = IsPedInAnyVehicle(playerPed, false)
    local hasFirstAid = exports.ox_inventory:Search('count', 'firstaid') > 0

    if playerInVehicle then
        exports.qbx_core:Notify("bạn đang ngồi trên xe không thể cứu người", 'error')
        return
    end

    if not hasFirstAid then
        exports.qbx_core:Notify(locale('error.no_firstaid'), 'error')
        return
    end

    local player = GetClosestPlayer()
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    local targetId = GetPlayerServerId(player)

    -- Tìm bệnh viện gần nhất với vị trí bác sĩ
    local nearestHospital = 'pillbox'
    local nearestDistance = 999999

    for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
        if hospital.coords and hospital.beds and #hospital.beds > 0 then
            local distance = #(plyCoords - hospital.coords.xyz)
            if distance < nearestDistance then
                nearestDistance = distance
                nearestHospital = hospitalName
            end
        end
    end

    exports['progressbar']:Progress({
        name = "revive_player",
        duration = 5000,
        label = locale('progress.revive'),
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = HealAnimDict,
            anim = HealAnim,
        },
        prop = {},
        propTwo = {}
    }, function(cancelled)
        if not cancelled then
            StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
            exports.qbx_core:Notify(locale('success.revived'), 'success')
            TriggerServerEvent('hospital:server:RevivePlayer', targetId)
            Wait(1000)

            -- Tìm giường gần với vị trí target player (người đang nằm)
            local targetPed = GetPlayerPed(player)
            local targetPos = GetEntityCoords(targetPed)
            local nearestBedIndex = 1
            local nearestBedDistance = 999999
            local hospitalBeds = sharedConfig.locations.hospitals[nearestHospital].beds

            for bedIdx, bedData in pairs(hospitalBeds) do
                local bedCoords = bedData.coords
                local distance = #(targetPos - bedCoords.xyz)
                if distance < nearestBedDistance then
                    nearestBedDistance = distance
                    nearestBedIndex = bedIdx
                end
            end

            TriggerServerEvent('hospital:server:putPlayerInBedrv', targetId, nearestHospital, nearestBedIndex)
            exports.qbx_core:Notify('Đã đưa bệnh nhân lên giường ' .. nearestBedIndex .. ' tại ' .. nearestHospital, 'success')
        else
            StopAnimTask(cache.ped, HealAnimDict, 'exit', 1.0)
            exports.qbx_core:Notify(locale('error.canceled'), 'error')
        end
    end)
end)

---Use bandage on nearest player to treat their wounds.
---Intended to be invoked by client or server.
RegisterNetEvent('hospital:client:TreatWounds', function()
    local plyCoords = GetEntityCoords(PlayerPedId(), false)

    -- Kiểm tra xem có trong bất kỳ khu vực chữa trị nào không
    local inTreatmentZone = false
    for _, zone in pairs(sharedConfig.bedTreatment.treatmentZones) do
        local dist = #(plyCoords - zone.center)
        if dist <= zone.radius then
            inTreatmentZone = true
            break
        end
    end

    local player = GetClosestPlayer()

    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    local playerId = GetPlayerServerId(player)

    -- Kiểm tra nếu người chơi đang chết hoặc ngất qua server callback
    local isDownedOrDead = lib.callback.await('qbx_ambulancejob:server:isPlayerDownedOrDead', false, playerId)
    if isDownedOrDead then
        exports.qbx_core:Notify('Người chơi này đang ngất hoặc chết, không thể chữa trị', 'error')
        return
    end

    -- Kiểm tra máu của người chơi - Sử dụng GetPlayerFromServerId để convert
    local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
    local targetHealth = GetEntityHealth(targetPed)
    local targetMaxHealth = GetEntityMaxHealth(targetPed)
    local healthPercent = (targetHealth / targetMaxHealth) * 100

    if healthPercent >= 100 then
        exports.qbx_core:Notify('Người chơi này có đủ máu, không cần điều trị', 'error')
        return
    end

    if inTreatmentZone then
        -- Gửi yêu cầu xác nhận đến người chơi
        local doctorName = GetPlayerName(PlayerId())
        TriggerServerEvent('hospital:server:RequestTreatment', playerId, doctorName, sharedConfig.chuatri)
    else
        exports.qbx_core:Notify("Bạn phải trong khu vực giường bệnh mới có thể chữa trị", 'error')
    end
end)

-- Event nhận yêu cầu chữa trị từ bác sĩ
RegisterNetEvent('hospital:client:ReceiveTreatmentRequest', function(doctorId, doctorName, cost)
    local alert = lib.alertDialog({
        header = 'Yêu cầu chữa trị',
        content = 'Bác sĩ ' .. doctorName .. ' muốn chữa trị vết thương cho bạn.\nPhí điều trị: $' .. cost .. '\n\nBạn có đồng ý không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Đồng ý',
            cancel = 'Từ chối'
        }
    })

    if alert == 'confirm' then
        -- Người chơi đồng ý, gửi phản hồi cho server
        TriggerServerEvent('hospital:server:AcceptTreatment', doctorId)
    else
        -- Người chơi từ chối
        TriggerServerEvent('hospital:server:DeclineTreatment', doctorId)
    end
end)

-- Event bắt đầu chữa trị sau khi người chơi đồng ý
RegisterNetEvent('hospital:client:StartTreatment', function(playerId)
    -- Thông báo cho bác sĩ
    exports.qbx_core:Notify('Bệnh nhân đã đồng ý, đang đưa lên giường điều trị...', 'success')

    -- Trigger event cho bệnh nhân đưa lên giường
    TriggerServerEvent('hospital:server:StartBedTreatment', playerId)
end)

-- Event cho bệnh nhân - đưa lên giường và điều trị
RegisterNetEvent('hospital:client:BedTreatment', function()
    -- Tìm bệnh viện gần nhất với vị trí bệnh nhân
    local plyCoords = GetEntityCoords(PlayerPedId())
    local nearestHospital = 'pillbox'
    local nearestDistance = 999999

    for hospitalName, hospital in pairs(sharedConfig.locations.hospitals) do
        if hospital.coords and hospital.beds and #hospital.beds > 0 then
            local distance = #(plyCoords - hospital.coords.xyz)
            --print('^3[BedTreatment] Hospital: ' .. hospitalName .. ' - Distance: ' .. distance .. 'm^0')
            if distance < nearestDistance then
                nearestDistance = distance
                nearestHospital = hospitalName
            end
        end
    end

    --print('^2[BedTreatment] Selected hospital: ' .. nearestHospital .. ' - Distance: ' .. nearestDistance .. 'm^0')

    local beds = sharedConfig.locations.hospitals[nearestHospital].beds
    local randomBed = math.random(1, #beds)
    local bedCoords = beds[randomBed].coords
    local cfg = sharedConfig.bedTreatment -- Lấy config

    exports.qbx_core:Notify('Đang đưa vào bệnh viện ' .. nearestHospital .. ' - giường ' .. randomBed, 'info')

    -- Đưa bệnh nhân lên giường
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, bedCoords.x, bedCoords.y, bedCoords.z + 0.02, true, true, true, false)
    Wait(500)
    FreezeEntityPosition(playerPed, true)

    -- Nằm trên giường bằng lib.playAnim
    lib.requestAnimDict(InBedDict)
    lib.playAnim(playerPed, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
    SetEntityHeading(playerPed, bedCoords.w)
    Wait(1000)
    FreezeEntityPosition(playerPed, true)

    -- Thread disable controls và force animation như code revive gốc
    local treatmentActive = true
    CreateThread(function()
        while treatmentActive do
            Wait(0)
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true) -- Cho phép xoay camera
            EnableControlAction(0, 2, true)

            -- Kiểm tra và force animation nếu bị interrupt (giống code gốc)
            if not IsEntityPlayingAnim(playerPed, InBedDict, InBedAnim, 3) then
                lib.playAnim(playerPed, InBedDict, InBedAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
            end
        end
    end)

    -- Spawn 3 NPC y tá
    local nurseModel = GetHashKey(cfg.nurseModel)
    RequestModel(nurseModel)
    while not HasModelLoaded(nurseModel) do
        Wait(0)
    end

    Wait(200)

    -- Tính toán vị trí dựa trên offset từ config
    local footPos = GetOffsetFromEntityInWorldCoords(playerPed, cfg.npcPositions.foot.x, cfg.npcPositions.foot.y, 0.0)
    local leftPos = GetOffsetFromEntityInWorldCoords(playerPed, cfg.npcPositions.left.x, cfg.npcPositions.left.y, 0.0)
    local rightPos = GetOffsetFromEntityInWorldCoords(playerPed, cfg.npcPositions.right.x, cfg.npcPositions.right.y, 0.0)

    local bedHeading = GetEntityHeading(playerPed)

    -- Spawn NPC dưới chân
    local nurseFoot = CreatePed(4, nurseModel, footPos.x, footPos.y, footPos.z + cfg.npcPositions.foot.z, bedHeading + 180, false, true)
    SetEntityAsMissionEntity(nurseFoot, true, true)
    SetBlockingOfNonTemporaryEvents(nurseFoot, true)
    SetEntityInvincible(nurseFoot, true)
    FreezeEntityPosition(nurseFoot, true)

    -- Spawn NPC trái
    local nurseLeft = CreatePed(4, nurseModel, leftPos.x, leftPos.y, leftPos.z + cfg.npcPositions.left.z, bedHeading - 90, false, true)
    SetEntityAsMissionEntity(nurseLeft, true, true)
    SetBlockingOfNonTemporaryEvents(nurseLeft, true)
    SetEntityInvincible(nurseLeft, true)
    FreezeEntityPosition(nurseLeft, true)

    -- Spawn NPC phải
    local nurseRight = CreatePed(4, nurseModel, rightPos.x, rightPos.y, rightPos.z + cfg.npcPositions.right.z, bedHeading + 90, false, true)
    SetEntityAsMissionEntity(nurseRight, true, true)
    SetBlockingOfNonTemporaryEvents(nurseRight, true)
    SetEntityInvincible(nurseRight, true)
    FreezeEntityPosition(nurseRight, true)

    Wait(500)

    -- Animation từ config
    lib.requestAnimDict(cfg.animations.foot.dict)
    TaskPlayAnim(nurseFoot, cfg.animations.foot.dict, cfg.animations.foot.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    lib.requestAnimDict(cfg.animations.sides.dict)
    TaskPlayAnim(nurseLeft, cfg.animations.sides.dict, cfg.animations.sides.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(nurseRight, cfg.animations.sides.dict, cfg.animations.sides.anim, 8.0, 8.0, -1, 1, 0, false, false, false)

    -- Progress bar với thời gian từ config
    exports['progressbar']:Progress({
        name = "bed_treatment",
        duration = cfg.duration,
        label = 'Đang truyền nước, bạn sẽ sớm hồi phục...',
        useWhileDead = false,
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
            -- Dừng thread
            treatmentActive = false
            Wait(100)

            -- Dừng animation
            ClearPedTasks(playerPed)

            -- Unfreeze bệnh nhân
            FreezeEntityPosition(playerPed, false)

            -- Xóa 3 y tá
            DeleteEntity(nurseFoot)
            DeleteEntity(nurseLeft)
            DeleteEntity(nurseRight)
            SetModelAsNoLongerNeeded(nurseModel)

            -- Đứng dậy
            Wait(500)

            -- Thông báo hoàn thành
            exports.qbx_core:Notify('Bạn đã được điều trị xong, cảm thấy khỏe hơn nhiều!', 'success')

            -- Server sẽ xử lý hồi máu và reset injuries
            TriggerServerEvent('hospital:server:CompleteTreatment')
        end
    end)
end)

---@param stashNumber integer id of stash to open
local function openStash(stashNumber)
    if not IsOnDuty() then return end
    exports.ox_inventory:openInventory('stash', sharedConfig.locations.stash[stashNumber].name)
end

---Opens the hospital armory.
---@param armoryId integer id of armory to open
---@param stashId integer id of armory to open
local function openArmory(armoryId, stashId)
    if not IsOnDuty() then return end
    exports.ox_inventory:openInventory('shop', { type = sharedConfig.locations.armory[armoryId].shopType, id = stashId })
end

---Teleports the player with a fade in/out effect
---@param coords vector3 | vector4
local function teleportPlayerWithFade(coords)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then
        SetEntityHeading(cache.ped, coords.w)
    end

    Wait(100)

    DoScreenFadeIn(1000)
end

---Teleports the player to main elevator
local function teleportToMainElevator()
    teleportPlayerWithFade(sharedConfig.locations.main[1])
end

---Teleports the player to roof elevator
local function teleportToRoofElevator()
    teleportPlayerWithFade(sharedConfig.locations.roof[1])
end

---Toggles the on duty status of the player.
local function toggleDuty()
    --print('sang')
    TriggerServerEvent('QBCore:ToggleDuty')
    TriggerServerEvent('police:server:UpdateBlips')
end

local onduty = false
local stash = false
local armory = false
local locationsroof = false
local locationsmain = false

---Creates a zone that lets players store and retrieve job vehicles
---@param vehicles AuthorizedVehicles
---@param coords vector4
local function createGarage(vehicles, coords)
    lib.zones.box({
        coords = coords.xyz,
        size = vec3(5, 5, 2),
        rotation = coords.w,
        debug = config.debugPoly,
        onEnter = function()
            if IsEms() and IsOnDuty() then
                exports["pa-textui-2"]:displayTextUI(locale('text.veh_button'), "E")
            end
        end,
        onExit = function()
            local _, text = lib.isTextUIOpen()
            if text == locale('text.veh_button') then exports["pa-textui-2"]:hideTextUI() end
        end,
        inside = function()
            if IsEms() and IsOnDuty() and IsControlJustPressed(0, 38) then
                if cache.vehicle then
                    DeleteEntity(cache.vehicle)
                else
                    showGarageMenu(vehicles, coords)
                end
            end
        end,
    })
end

---Creates air and land garages to spawn vehicles at for EMS personnel
CreateThread(function()
    for _, coords in pairs(sharedConfig.locations.vehicle) do
        createGarage(config.authorizedVehicles, coords)
    end

    for _, coords in pairs(sharedConfig.locations.helicopter) do
        createGarage(config.authorizedHelicopters, coords)
    end
end)

---Cứu người và đưa lên giường bệnh
---@param bedCoords vector4 tọa độ giường bệnh
local function rescuePatientToBed(bedCoords)
    local playerPed = PlayerPedId()
    local plyCoords = GetEntityCoords(playerPed, false)
    local playerInVehicle = IsPedInAnyVehicle(playerPed, false)

    if playerInVehicle then
        exports.qbx_core:Notify("Bạn đang ngồi trên xe không thể cứu người", 'error')
        return
    end

    local player = lib.getClosestPlayer(GetEntityCoords(cache.ped), 5.0, false)
    if not player then
        exports.qbx_core:Notify(locale('error.no_player'), 'error')
        return
    end

    local playerId = GetPlayerServerId(player)

    -- Kiểm tra người chơi có đang ngất hoặc chết không qua server callback
    local isDownedOrDead = lib.callback.await('qbx_ambulancejob:server:isPlayerDownedOrDead', false, playerId)
    if not isDownedOrDead then
        exports.qbx_core:Notify('Người chơi này không cần cứu chữa', 'error')
        return
    end

    -- Chỉ stop bác sĩ đang carry đúng bệnh nhân này, không ảnh hưởng bác sĩ khác
    TriggerServerEvent('ambulance:server:StopCarrying', playerId)

    -- Hồi sinh và đưa lên giường ngay lập tức
    TriggerServerEvent('hospital:server:RevivePlayer', playerId)
    TriggerServerEvent('hospital:server:putPlayerInCustomBed', playerId, bedCoords)
    TriggerServerEvent('hospital:server:CreateMedicalInvoice', playerId, sharedConfig.hoisinh, "Hồi sinh và điều trị")

    exports.qbx_core:Notify('Đang đưa bệnh nhân lên giường...', 'success')

    -- Chờ 4 giây để bệnh nhân lên giường trước khi bác sĩ teleport
    Wait(4000)

    -- Bác sĩ teleport lên bên người bệnh (tìm tọa độ thực tế)
    local patientPed = GetPlayerPed(player)
    local patientCoords = GetEntityCoords(patientPed)
    local patientHeading = GetEntityHeading(patientPed)

    -- Đứng bên cạnh người bệnh
    local doctorX = patientCoords.x + math.cos(math.rad(patientHeading + 90)) * 0.6
    local doctorY = patientCoords.y + math.sin(math.rad(patientHeading + 90)) * 0.6
    local doctorZ = patientCoords.z

    SetEntityCoords(cache.ped, doctorX, doctorY, doctorZ, false, false, false, true)
    Wait(100)
    -- Quay bác sĩ về phía người bệnh
    local heading = math.deg(math.atan2(patientCoords.y - doctorY, patientCoords.x - doctorX)) - 90
    SetEntityHeading(cache.ped, heading)
    Wait(500)

    -- Synced CPR animation
    -- lib.requestAnimDict('mini@cpr@char_a@cpr_str')
    -- lib.requestAnimDict('mini@cpr@char_b@cpr_str')

    -- Trigger animation cho bệnh nhân với thời gian CPR
    TriggerServerEvent('hospital:server:syncCPRAnimation', playerId, config.cprTime)
    Wait(500)

    -- local isHealing = true
    -- CreateThread(function()
    --     while isHealing do
    --         if not IsEntityPlayingAnim(cache.ped, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 3) then
    --             TaskPlayAnim(cache.ped, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, -8.0, -1, 1, 0, false, false, false)
    --         end
    --         Wait(500)
    --     end
    -- end)

    exports['progressbar']:Progress({
        name = "rescue_patient",
        duration = config.cprTime * 1000,
        label = 'Đang điều trị bệnh nhân...',
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = 'mini@cpr@char_a@cpr_str',
            anim = 'cpr_pumpchest',
            flags = 1,
        },
        prop = {},
        propTwo = {}
    }, function(cancelled)
        if not cancelled then
            --isHealing = false
            -- ClearPedTasks(cache.ped)
            exports.qbx_core:Notify('Hoàn thành điều trị!', 'success')
        else
            --isHealing = false
            -- ClearPedTasks(cache.ped)
            exports.qbx_core:Notify(locale('error.canceled'), 'error')
        end
    end)
end

---Sets up duty toggle, stash, armory, and elevator interactions using either target or zones.
if config.useTarget then
    for i, bedCoords in ipairs(sharedConfig.locations.customBeds) do
        exports.ox_target:addBoxZone({
            name = 'hospital_bed_rescue_' .. i,
            coords = vec3(bedCoords.x, bedCoords.y, bedCoords.z),
            size = vec3(2, 2, 2),
            rotation = bedCoords.w,
            debug = config.debugPoly,
            options = {
                {
                    icon = 'fas fa-user-nurse',
                    label = 'Cứu người lên giường',
                    canInteract = function()
                        return IsAmbulance() and IsOnDuty()
                    end,
                    onSelect = function()
                        rescuePatientToBed(bedCoords)
                    end,
                    distance = 2.5,
                    groups = 'ambulance',
                }
            }
        })
    end

    for i = 1, #sharedConfig.locations.duty do
        exports.ox_target:addBoxZone({
            name = 'duty' .. i,
            coords = sharedConfig.locations.duty[i],
            size = vec3(1.5, 1, 2),
            rotation = 71,
            debug = config.debugPoly,
            canInteract = function()
                return IsEms()
            end,
            options = {
                {
                    icon = 'fa fa-clipboard',
                    label = locale('text.duty'),
                    onSelect = toggleDuty,
                    distance = 2,
                    groups = 'ambulance',
                }
            }
        })
    end

    for i = 1, #sharedConfig.locations.stash do
        exports.ox_target:addBoxZone({
            name = 'stash' .. i,
            coords = sharedConfig.locations.stash[i].location,
            size = vec3(1, 1, 2),
            rotation = -20,
            debug = config.debugPoly,
            canInteract = function()
                return IsEms()
            end,
            options = {
                {
                    icon = 'fa fa-clipboard',
                    label = locale('text.pstash'),
                    onSelect = function()
                        openStash(i)
                    end,
                    distance = 2,
                    groups = 'ambulance',
                }
            }
        })
    end

    for i = 1, #sharedConfig.locations.armory do
        for ii = 1, #sharedConfig.locations.armory[i].locations do
            exports.ox_target:addBoxZone({
                name = 'armory' .. i .. ':' .. ii,
                coords = sharedConfig.locations.armory[i].locations[ii],
                size = vec3(1, 1, 2),
                rotation = -20,
                debug = config.debugPoly,
                canInteract = function()
                    return IsEms()
                end,
                options = {
                    {
                        icon = 'fa fa-clipboard',
                        label = locale('text.armory'),
                        onSelect = function()
                            openArmory(i, ii)
                        end,
                        distance = 1.5,
                        groups = 'ambulance',
                    }
                }
            })
        end
    end

    exports.ox_target:addBoxZone({
        name = 'roof1',
        coords = sharedConfig.locations.roof[1],
        size = vec3(1, 2, 2),
        rotation = -20,
        debug = config.debugPoly,
        options = {
            {
                icon = 'fas fa-hand-point-down',
                label = locale('text.el_main'),
                onSelect = teleportToMainElevator,
                distance = 1.5,
                groups = 'ambulance',
            }
        }
    })

    exports.ox_target:addBoxZone({
        name = 'main1',
        coords = sharedConfig.locations.main[1],
        size = vec3(2, 1, 2),
        rotation = -20,
        debug = config.debugPoly,
        options = {
            {
                icon = 'fas fa-hand-point-up',
                label = locale('text.el_roof'),
                onSelect = teleportToRoofElevator,
                distance = 1.5,
                groups = 'ambulance',
            }
        }
    })

    -- Thêm target kiểm tra sức khỏe và chữa trị vết thương trên ped của người chơi
    exports.ox_target:addGlobalPlayer({
        {
            icon = 'fas fa-heart-pulse',
            label = 'Kiểm tra sức khỏe',
            onSelect = function(entity)
                TriggerEvent('hospital:client:CheckStatus')
            end,
            distance = 2.5,
            groups = 'ambulance',
            canInteract = function(entity)
                return IsEms() and IsOnDuty()
            end
        },
        {
            icon = 'fas fa-bandage',
            label = 'Chữa trị vết thương',
            onSelect = function(entity)
                TriggerEvent('hospital:client:TreatWounds')
            end,
            distance = 2.5,
            groups = 'ambulance',
            canInteract = function(entity)
                return IsEms() and IsOnDuty()
            end
        }
    })
end

-- Hiển thị vòng tròn khu vực chữa trị cho tất cả các zone
-- CreateThread(function()
--     while true do
--         local playerCoords = GetEntityCoords(PlayerPedId())
--         local shouldDraw = false

--         if sharedConfig.bedTreatment and sharedConfig.bedTreatment.treatmentZones then
--             for _, zone in pairs(sharedConfig.bedTreatment.treatmentZones) do
--                 if zone.showMarker then
--                     local dist = #(playerCoords - zone.center)

--                     -- Chỉ hiển thị khi ở gần (trong vòng 50m)
--                     if dist < 50.0 then
--                         shouldDraw = true
--                         -- Vẽ vòng tròn đỏ
--                         DrawMarker(
--                             1, -- Type: Cylinder
--                             zone.center.x, zone.center.y, zone.center.z - 1.0, -- Position
--                             0.0, 0.0, 0.0, -- Direction
--                             0.0, 0.0, 0.0, -- Rotation
--                             zone.radius * 2, zone.radius * 2, 1.0, -- Scale
--                             255, 0, 0, 100, -- RGBA (đỏ, trong suốt 100)
--                             false, false, 2, false, nil, nil, false
--                         )
--                     end
--                 end
--             end
--         end

--         if shouldDraw then
--             Wait(0)
--         else
--             Wait(1000)
--         end
--     end
-- end)
