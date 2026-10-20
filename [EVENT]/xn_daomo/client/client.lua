local config = lib.require 'config'
local acceptRob = false
local markerPoints = {}
local sphere = nil
local pedSpawned = false
local qtdGraves = #config.coordsGraves
local isDigging = false
local graveCooldowns = {}
local activeZombies = {}
local isPoisoned = false
local poisonThreadRunning = false

local function isGraveOnCooldown(index)
    if not config.graveCooldown or config.graveCooldown <= 0 then return false end
    local cd = graveCooldowns[index]
    if cd and GetGameTimer() < cd then
        local remaining = math.ceil((cd - GetGameTimer()) / 1000)
        return true, remaining
    end
    return false, 0
end

local function setGraveCooldown(index)
    if config.graveCooldown and config.graveCooldown > 0 then
        graveCooldowns[index] = GetGameTimer() + (config.graveCooldown * 1000)
    end
end

local function hasItem()
    if config.requireShovel == false then return true end
    local item = config.shovelItem or 'shovel'
    return exports.ox_inventory:Search('count', item) >= 1
end

local function clearPoison()
    if isPoisoned or poisonThreadRunning then
        isPoisoned = false
        poisonThreadRunning = false
        AnimpostfxStopAll()
    end
end

local function applyZombiePoison()
    if isPoisoned then return end
    if IsEntityDead(cache.ped) then return end

    local zConfig = config.zombie or {}
    local poisonCfg = zConfig.poison or {}
    local chance = poisonCfg.chance or 70

    if math.random(1, 100) > chance then return end

    isPoisoned = true
    lib.notify({
        title = 'Nhiễm độc xác sống',
        description = 'Bạn đã bị zombie đánh trúng và nhiễm độc! Độc tố đang rút máu của bạn...',
        type = 'error',
        duration = 6000
    })

    if poisonCfg.screenEffect ~= false then
        AnimpostfxPlay('DrugsDrivingIn', 0, true)
    end

    if not poisonThreadRunning then
        poisonThreadRunning = true
        CreateThread(function()
            local damage = poisonCfg.damage or 5
            local interval = poisonCfg.interval or 4000

            while isPoisoned do
                Wait(interval)

                local ped = cache.ped
                if not DoesEntityExist(ped) or IsEntityDead(ped) then
                    clearPoison()
                    break
                end

                local curHealth = GetEntityHealth(ped)
                -- Trong GTA V ped chết khi máu <= 100
                if curHealth <= 100 then
                    SetEntityHealth(ped, 0)
                    clearPoison()
                    break
                else
                    local newHealth = curHealth - damage
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)
                    if newHealth <= 100 then
                        SetEntityHealth(ped, 0)
                        clearPoison()
                        break
                    else
                        SetEntityHealth(ped, newHealth)
                    end
                end
            end
            poisonThreadRunning = false
        end)
    end
end

local function spawnZombies(selectedGrave)
    local zConfig = config.zombie or {}
    local chance = zConfig.chance or 40
    if math.random(1, 100) > chance then return end

    lib.notify({
        title = 'Coi chừng!',
        description = 'Có xác sống vừa đội mồ chui lên!',
        type = 'warning'
    })

    local count = 1
    if type(zConfig.count) == 'table' then
        count = math.random(zConfig.count.min or 1, zConfig.count.max or 1)
    elseif type(zConfig.count) == 'number' then
        count = zConfig.count
    end

    local models = zConfig.models or { "u_m_y_zombie_01" }

    for i = 1, count do
        local modelName = models[math.random(1, #models)]
        local modelHash = GetHashKey(modelName)
        RequestModel(modelHash)

        while not HasModelLoaded(modelHash) do
            Wait(10)
        end

        local offsetX = (math.random(-15, 15) / 10.0)
        local offsetY = (math.random(-15, 15) / 10.0)
        local ped = CreatePed(0, modelHash, selectedGrave.x + offsetX, selectedGrave.y + offsetY, selectedGrave.z + 0.2, selectedGrave.w or 0.0, true, false)

        SetPedFleeAttributes(ped, 0, false)
        SetPedCombatAttributes(ped, 46, true) -- Cho phép đánh tay không với mục tiêu có vũ khí
        SetPedCombatAttributes(ped, 5, true)  -- Luôn luôn chiến đấu
        SetPedCombatAttributes(ped, 0, false)
        SetPedCombatAbility(ped, 2)           -- Cận chiến quyết liệt
        SetPedCombatMovement(ped, 3)          -- Lao thẳng vào tấn công (rush)
        SetPedCombatRange(ped, 0)             -- Tầm đánh cận chiến (melee)
        SetPedKeepTask(ped, true)
        SetPedDropsWeaponsWhenDead(ped, false)
        SetPedHearingRange(ped, 100.0)
        SetPedSeeingRange(ped, 100.0)
        SetPedAlertness(ped, 3)

        local maxHp = zConfig.health or 250
        SetEntityMaxHealth(ped, maxHp)
        SetEntityHealth(ped, maxHp)

        TaskCombatPed(ped, cache.ped, 0, 16)
        activeZombies[ped] = true
        SetModelAsNoLongerNeeded(modelHash)
    end
end

-- Lắng nghe sát thương từ zombie bằng event mạng
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
        local victim = data[1]
        local attacker = data[2]
        local isFatal = data[6] == 1

        if victim == cache.ped and activeZombies[attacker] and not isFatal then
            applyZombiePoison()
        end
    end
end)

-- Luồng kiểm tra sát thương dự phòng và dọn dẹp danh sách zombie
CreateThread(function()
    while true do
        local hasZombies = false
        local playerPed = cache.ped

        for ped in pairs(activeZombies) do
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                hasZombies = true
                if HasEntityBeenDamagedByEntity(playerPed, ped, true) then
                    ClearEntityLastDamageEntity(playerPed)
                    applyZombiePoison()
                end
            else
                activeZombies[ped] = nil
            end
        end

        Wait(hasZombies and 200 or 1500)
    end
end)

local function callTheCops()
    local hours = GetClockHours()
    local chance = config.policeCallChance

    if hours >= 22 and hours <= 8 then
        chance = config.policeCallNightChance
    end

    if math.random() <= chance then
        TriggerServerEvent('police:server:policeAlert')
    end
end

local function dropFingerprint(selectedGrave)
    if qbx.isWearingGloves() then return end
    if config.fingerprintChance > math.random(0, 100) then
        TriggerServerEvent('evidence:server:CreateFingerDrop', selectedGrave)
    end
end

local function cleanZones()
    if sphere then
        sphere:remove()
        sphere = nil
    end

    for _, point in pairs(markerPoints) do
        point:remove()
    end

    markerPoints = {}
end

local function generateRandomGrave()
    return math.random(1, qtdGraves)
end

local function generateCoords(grave)
    return config.coordsGraves[grave]
end

local function startDigging(graveIndex, selectedGrave)
    if isDigging then return end

    local onCd, remaining = isGraveOnCooldown(graveIndex)
    if onCd then
        lib.notify({
            title = 'Đào mộ',
            description = ('Ngôi mộ này vừa mới bị đào! Vui lòng quay lại sau %s giây.'):format(remaining),
            type = 'error'
        })
        return
    end

    if config.minCops and config.minCops > 0 then
        local cops = lib.callback.await('lonf:server:getNumCops', false)
        if cops < config.minCops then
            lib.notify({
                title = 'Đào mộ',
                description = 'Không đủ cảnh sát online trong thành phố!',
                type = 'error'
            })
            return
        end
    end

    if not hasItem() then
        lib.notify({
            title = 'Yêu cầu vật phẩm',
            description = 'Bạn cần có xẻng để đào mộ!',
            type = 'error'
        })
        return
    end

    isDigging = true
    lib.hideTextUI()

    local progress = lib.progressBar({
        duration = math.random(8000, 12000),
        label = 'Đang đào mộ...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true,
            sprint = true
        },
        anim = {
            dict = 'random@burial',
            clip = 'a_burial',
            flag = 1
        },
        prop = {
            model = `prop_tool_shovel`,
            bone = 28422,
            pos = vec3(0.0, 0.0, 0.24),
            rot = vec3(0.0, 0.0, 0.0)
        }
    })

    isDigging = false

    if progress then
        setGraveCooldown(graveIndex)
        callTheCops()
        dropFingerprint(selectedGrave)
        TriggerServerEvent('hud:server:GainStress', math.random(12, 20))
        lib.callback.await('lonf_fruitpick:server:giveItem', false)
        spawnZombies(selectedGrave)
    end
end

-- Chế độ tự do: Tạo point cho tất cả các ngôi mộ
local function initFreeGraves()
    cleanZones()

    local textUIMsg = config.textUI and config.textUI.message or '[E] - Đào mộ'
    local textUIPos = config.textUI and config.textUI.position or 'right-center'
    local textUIIcon = config.textUI and config.textUI.icon or 'shovel'

    for index, graveCoords in ipairs(config.coordsGraves) do
        local point = lib.points.new({
            coords = vec3(graveCoords.x, graveCoords.y, graveCoords.z),
            distance = 2.0,
            graveIndex = index,
            graveCoords = graveCoords,
        })

        function point:onEnter()
            if not isDigging then
                lib.showTextUI(textUIMsg, {
                    position = textUIPos,
                    icon = textUIIcon
                })
            end
        end

        function point:onExit()
            lib.hideTextUI()
        end

        function point:nearby()
            if config.drawMarker then
                DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 50, false, true, 2, false, nil, nil, false)
            end

            if not isDigging and IsControlJustReleased(0, 38) then
                startDigging(self.graveIndex, self.graveCoords)
            end
        end

        table.insert(markerPoints, point)
    end
end

-- Chế độ nhiệm vụ (Nếu requireMission = true)
local function generatePoints()
    local randomGrave = generateRandomGrave()
    local selectedGrave = generateCoords(randomGrave)

    local textUIMsg = config.textUI and config.textUI.message or '[E] - Đào mộ'
    local textUIPos = config.textUI and config.textUI.position or 'right-center'
    local textUIIcon = config.textUI and config.textUI.icon or 'shovel'

    local point = lib.points.new({
        coords = vec3(selectedGrave.x, selectedGrave.y, selectedGrave.z),
        distance = 2.0,
        graveIndex = randomGrave,
        graveCoords = selectedGrave,
    })

    function point:onEnter()
        if not isDigging then
            lib.showTextUI(textUIMsg, {
                position = textUIPos,
                icon = textUIIcon
            })
        end
    end

    function point:onExit()
        lib.hideTextUI()
    end

    function point:nearby()
        if config.drawMarker then
            DrawMarker(2, self.coords.x, self.coords.y, self.coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0.0, 0.5, 0.5, 0.5, 255, 255, 255, 50, false, true, 2, false, nil, nil, false)
        end

        if not isDigging and IsControlJustReleased(0, 38) then
            startDigging(self.graveIndex, self.graveCoords)
            point:remove()
            Wait(500)
            generatePoints()
        end
    end

    table.insert(markerPoints, point)
end

local function createGravesBoxes()
    Citizen.CreateThread(function()
        generatePoints()
        Wait(500)
    end)
end

local function createRobZone()
    sphere = lib.zones.sphere({
        coords = config.robZone,
        radius = 147,
        debug = false,
        inside = function()
            exports.ox_target:removeModel(config.model, _)
            inSphere = true
        end,
        onEnter = function()
            inSphere = true
        end,
        onExit = function()
            acceptRob = false
            lib.hideTextUI()
            cleanZones()

            exports.ox_target:addModel(config.model, {
                {
                    icon = 'fa-solid fa-user-secret',
                    label = 'Talk to corrupt priest',
                    onSelect = function()
                        local cops = lib.callback.await('lonf:server:getNumCops')
                        if cops >= config.minCops then
                            acceptRob = true
                            if acceptRob then
                                createGravesBoxes()
                                createRobZone()
                            end
                        end
                    end,
                    distance = 1.5,
                }
            })
            inSphere = false
        end
    })
end

local function SpawnPeds()
    local model = GetHashKey(config.model)
    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(1)
    end

    local pedModel = CreatePed(0, model, config.coords.x, config.coords.y, config.coords.z, config.coords.w, false, false)
    SetEntityInvincible(pedModel, true)
    FreezeEntityPosition(pedModel, true)
    SetBlockingOfNonTemporaryEvents(pedModel, true)
    SetModelAsNoLongerNeeded(pedModel)
    lib.RequestAnimDict('timetable@michael@on_chairidle_c')
    TaskPlayAnim(pedModel, 'timetable@michael@on_chairidle_c', 'on_chair_e', 8.0, 1.0, -1, 01, 0, 0, 0, 0)

    exports.ox_target:addModel(config.model, {
        {
            icon = 'fa-solid fa-user-secret',
            label = 'Talk to corrupt priest',
            onSelect = function()
                local cops = lib.callback.await('lonf:server:getNumCops')

                if cops >= config.minCops then
                    acceptRob = true
                    if acceptRob then
                        createGravesBoxes()
                        createRobZone()
                    end
                end
            end,
            distance = 1.5,
        }
    })
    pedSpawned = true
end

local function initCemetery()
    if not config.requireMission then
        initFreeGraves()
    else
        if not pedSpawned then
            SpawnPeds()
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    initCemetery()
end)

RegisterNetEvent('qbx_medical:client:playerRevived', function()
    clearPoison()
end)

RegisterNetEvent('hospital:client:Revive', function()
    clearPoison()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        initCemetery()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        lib.hideTextUI()
        cleanZones()
        clearPoison()
        for ped in pairs(activeZombies) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
    end
end)
