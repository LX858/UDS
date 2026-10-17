local isInProspectingZone = false
local isUsingProspector = false
local isInSpectingItem = false
local lastDiggedLocation = nil
local isUsingBomb = false
local BombOwner = nil
local BombObject = nil
local isBombStop = false

local currentAttempt = 0
local totalSuccessCount = 0
local blacklistZones = {}
local isInBlacklistZone = false
local waitingForContinue = false

-- Tạo các blacklist zones
CreateThread(function()
    for i, zoneData in ipairs(Config.BlacklistZones) do
        blacklistZones[i] = lib.zones.sphere({
            coords = zoneData.coords,
            radius = zoneData.radius or Config.BlacklistZoneRadius,
            debug = false,
            onEnter = function()
                isInBlacklistZone = true
            end,
            onExit = function()
                -- Kiểm tra lại xem có còn trong zone nào khác không
                local playerCoords = GetEntityCoords(PlayerPedId())
                isInBlacklistZone = false
                for _, zone in ipairs(blacklistZones) do
                    if zone:contains(playerCoords) then
                        isInBlacklistZone = true
                        break
                    end
                end
            end
        })
    end
end)

-- Difficulty and Old sawing mechanics removed

local function GetSkillbar()
    if GetResourceState('skillbar') == 'started' then
        local success, result = pcall(function()
            return exports['skillbar']:GetSkillbarObject()
        end)
        if success and result then
            return result
        end
    end
    
    if GetResourceState('dc-skillbar') == 'started' then
        local success, result = pcall(function()
            return exports['dc-skillbar']:GetSkillbarObject()
        end)
        if success and result then
            return result
        end
    end
    
    return nil
end


RegisterNetEvent('xn-bombsaw:client:UsingOldBomb', function()
    if not isUsingBomb then
        local playerCoords = GetEntityCoords(PlayerPedId())

        -- Kiểm tra xem có nằm trong khu vực cho phép cưa bom không
        if Config.AllowedZone then
            local dist = #(playerCoords - Config.AllowedZone.coords)
            if dist > Config.AllowedZone.radius then
                lib.notify({
                    title = 'Thông báo',
                    description = 'Bạn ở ngoài khu vực được phép cưa bom!',
                    type = 'error'
                })
                return
            end
        end

        -- Kiểm tra xem có trong khu vực cấm không
        if isInBlacklistZone then
            lib.notify({
                title = 'Cấm đặt bom',
                description = 'Khu vực này không được phép đặt bom!',
                type = 'error'
            })
            return
        end
        
        local player, distance = lib.getClosestPlayer(GetEntityCoords(PlayerPedId()), 2.0, false)
        if player then
            local playerId = GetPlayerServerId(player)
            local playerData = exports.qbx_core:GetPlayerData()
            
            -- Gửi yêu cầu đến người chơi khác
            TriggerServerEvent('xn-bombsaw:server:SendBombRequest', playerId)
        else
            lib.notify({title = 'Thông báo', description = 'Không có ai ở gần.', type = 'error'})
        end
    else
        lib.notify({title = 'Thông báo', description = 'Bạn đang bận gì đó.', type = 'error'})
    end
end)

-- Nhận yêu cầu từ người chơi khác
RegisterNetEvent('xn-bombsaw:client:ReceiveBombRequest', function(requesterName, requesterId)
    local alert = lib.alertDialog({
        header = 'Yêu cầu cưa bom',
        content = requesterName .. ' muốn cưa bom với bạn. Bạn có muốn làm giàu không?',
        centered = true,
        cancel = true,
        labels = {
            confirm = 'Đồng ý',
            cancel = 'Từ chối'
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('xn-bombsaw:server:AcceptBombRequest', requesterId)
    else
        TriggerServerEvent('xn-bombsaw:server:DenyBombRequest', requesterId)
    end
end)

local function RequestModelHash(Model)
    RequestModel(Model)
    while not HasModelLoaded(Model) do
        Wait(1)
    end
end

function PoliceCall() 
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    exports['ld-dispatch']:sendDispatch(
        {
            title = "Cưa boom",
            code = "12-10B",
            values = {
                {
                    text = "Cưa boom",
                    icon = "fa-solid fa-earth-americas",
                },
                {
                    text = "2 sao",
                    icon = "fa-solid fa-hashtag",
                },
            },
            valuestwo = {}, -- DON'T TOUCH
            jobs = {"police"},
            active = false,-- DON'T TOUCH
            dispatchnumber = nil,-- DON'T TOUCH
            coords = plyCoords,
            blip = {
                blipid = 486,
                blipcolor = 1,
            }
        }
    ) 
end

local function playRepairkitMinigame(role)
    local neededAttempts = Config.CuaBomSuccessCount or 6
    local succeededAttempts = 0
    
    while succeededAttempts < neededAttempts do
        if isBombStop then break end
        
        -- Chọn độ khó ngẫu nhiên giữa 'medium' (normal) và 'hard'
        local diffs = {'medium', 'hard'}
        local randomDiff = diffs[math.random(1, #diffs)]
        
        local result = exports['five-repairkit']:Minigame(randomDiff)
        
        if result then
            succeededAttempts = succeededAttempts + 1
            if succeededAttempts >= neededAttempts then
                TriggerServerEvent("xn-bombsaw:server:success", role)
                break
            end
            Wait(500)
        else
            waitingForContinue = true
            TriggerServerEvent("xn-bombsaw:server:fail")
            
            while waitingForContinue and not isBombStop do
                Wait(100)
            end
        end
    end
end

RegisterNetEvent("xn-bombsaw:client:start", function(coords, heading)
    isBombStop = false
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityHeading(PlayerPedId(), heading - 90.0)
    
    CreateThread(function()
        lib.requestAnimDict('anim@mp_player_intupperair_shagging')
        TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intupperair_shagging', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)
        Wait(1000)
        lib.requestAnimDict('anim@heists@fleeca_bank@ig_7_jetski_owner')
        while not isBombStop do
            if not IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@fleeca_bank@ig_7_jetski_owner', 'owner_idle', 3) then
                TaskPlayAnim(PlayerPedId(), 'anim@heists@fleeca_bank@ig_7_jetski_owner', 'owner_idle', 8.0, -8.0, -1, 1, 0, false, false, false)
            end
            Wait(500)
        end
    end)
    
    playRepairkitMinigame("leader")
end)

RegisterNetEvent("xn-bombsaw:client:startP", function(coords, heading)
    isBombStop = false
    
    -- Tính toán vị trí mới cho người thứ hai trước mặt người thứ nhất
    local distance = 2.0 -- Khoảng cách giữa hai người
    local coordPx = coords.x + math.cos(math.rad(heading)) * distance
    local coordPy = coords.y + math.sin(math.rad(heading)) * distance
    local coordPz = coords.z

    -- Đặt vị trí và hướng cho người thứ hai (partner)
    SetEntityCoords(PlayerPedId(), coordPx, coordPy, coordPz, false, false, false, false)
    SetEntityHeading(PlayerPedId(), heading + 90.0)
    FreezeEntityPosition(PlayerPedId(), true)
    
    local distanceB = 1.0 -- Khoảng cách giữa hai người và bom
    local coordBx = coords.x + math.cos(math.rad(heading)) * distanceB
    local coordBy = coords.y + math.sin(math.rad(heading)) * distanceB
    local coordBz = coords.z

    RequestModelHash('prop_ld_bomb_anim')
    BombObject = CreateObject(GetHashKey('prop_ld_bomb_anim'), coordBx, coordBy, coordBz, true, true, false)
    PlaceObjectOnGroundProperly(BombObject)
    SetEntityHeading(BombObject, heading - 180.0)
    FreezeEntityPosition(BombObject, true)
    
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 15.0, "handsawing2", 0.25)
    CreateThread(function()
        lib.requestAnimDict('anim@mp_player_intupperair_shagging')
        TaskPlayAnim(PlayerPedId(), 'anim@mp_player_intupperair_shagging', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)
        Wait(1000)
        lib.requestAnimDict('anim@heists@fleeca_bank@ig_7_jetski_owner')
        while not isBombStop do
            if not IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@fleeca_bank@ig_7_jetski_owner', 'owner_idle', 3) then
                TaskPlayAnim(PlayerPedId(), 'anim@heists@fleeca_bank@ig_7_jetski_owner', 'owner_idle', 8.0, -8.0, -1, 1, 0, false, false, false)
            end
            Wait(500)
        end
    end)
    
    playRepairkitMinigame("partner")
end)

RegisterNetEvent("xn-bombsaw:client:fail", function()
    local pedCoords = GetEntityCoords(PlayerPedId())
    AddExplosion(pedCoords.x, pedCoords.y, pedCoords.z, 31, 2000.0, true, false, 1.0)
    TriggerServerEvent("InteractSound_SV:Stop")
end)

RegisterNetEvent('xn-bombsaw:client:DonatingTheBomb', function(coords)
    AddExplosion(coords.x, coords.y, coords.z, 4, 50.0, true, false, 1065353216)
end)

RegisterNetEvent('xn-bombsaw:client:ExplodeBomb', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    AddExplosion(playerCoords.x, playerCoords.y, playerCoords.z, 4, 50.0, true, false, 1065353216)
    SetEntityHealth(playerPed, 0)
end)

RegisterNetEvent('xn-bombsaw:client:UpdateTotalSuccess', function(totalSuccess)
    totalSuccessCount = totalSuccess
end)

RegisterNetEvent("xn-bombsaw:client:continueRepeat", function()
    waitingForContinue = false
end)

RegisterNetEvent('xn-bombsaw:client:SawingBombFinish', function(isSuccess)
    isBombStop = true
    waitingForContinue = false
    
    local skillBar = GetSkillbar()
    if skillBar then
        if skillBar.Stop then
            skillBar.Stop()
        else
            skillBar.Data.Active = false
        end
    end

    if isSuccess then
        -- Báo cảnh sát sau khi cưa bom thành công (chỉ 1 client báo để tránh trùng lặp)
        if BombObject ~= nil then
            PoliceCall()
        end

        local finished = lib.progressBar({
            duration = 60000, -- progressbar kéo dài 60s
            label = 'Đang cưa bom...',
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
            anim = {
                dict = 'anim@heists@fleeca_bank@ig_7_jetski_owner',
                clip = 'owner_idle',
                flag = 1,
            }
        })

        if finished then
            lib.notify({title = 'Thành công', description = 'Dô 1 khúc.', type = 'success'})
            ClearPedTasks(PlayerPedId())
            exports['monitors']:TriggerProtectedServerEvent('xn-bombsaw:server:GiveShit')
        else
            ClearPedTasks(PlayerPedId())
            lib.notify({title = 'Thất bại', description = 'Gà thế thì chịu.', type = 'error'})
        end
    else
        ClearPedTasks(PlayerPedId())
        lib.notify({title = 'Thất bại', description = 'Gà thế thì chịu.', type = 'error'})
    end

    if BombObject ~= nil then
        DeleteEntity(BombObject)
        BombObject = nil
    end
    
    BombOwner = nil
    totalSuccessCount = 0
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
end)
