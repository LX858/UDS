QBCore = nil
local scriptname = GetCurrentResourceName()

-- Biến game
local JoinBomber = false
local gameStart = false
local holdbomb = false
local Bomb = nil
local PreviousCoords = nil
local playerBomb = {}
local effectscale = 0.1
local CountBomb = 20
local currentMap = nil
local joinUIOpen = false
local hasQuit = false -- Đánh dấu player đã quit sớm
local _pedSnapshot = nil -- Snapshot ped gốc trước khi đổi skin tạm thời

-- Biến spectate (xem người khác khi chết)
local isSpectating = false
local spectateCam = nil
local spectateTargetIndex = 1
local spectatePlayerList = {} -- Danh sách server IDs của người còn sống
local celebrationReceived = false -- Flag: đã nhận celebration, không vào spectate nữa

-- Khởi tạo QBCore
Citizen.CreateThread(function()
    while QBCore == nil do
        QBCore = exports['qb-core']:GetCoreObject()
        Citizen.Wait(100)
    end
end)

-- Hiển thị UI tham gia
RegisterNetEvent(scriptname .. ':showJoinUI', function(roomInfo)
    if joinUIOpen then
        SendNUIMessage({
            type = 'updateRoomData',
            data = roomInfo
        })
        return
    end
    
    joinUIOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        type = 'setSoundURL',
        url = Config.SoundURL
    })
    SendNUIMessage({
        type = 'openJoinPanel',
        roomInfo = roomInfo
    })
    SetTimeout(200, function()
        if joinUIOpen then
            SendNUIMessage({
                type = 'updateRoomData',
                data = roomInfo
            })
        end
    end)
end)

RegisterNetEvent(scriptname .. ':showRoomPlayersUI', function(data)
    joinUIOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        type = 'setSoundURL',
        url = Config.SoundURL
    })
    SendNUIMessage({
        type = 'openJoinPanel',
        roomInfo = data
    })
end)

-- Gửi SoundURL khi script khởi chạy
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    SendNUIMessage({
        type = 'setSoundURL',
        url = Config.SoundURL
    })
end)

-- NUI Callbacks cho join
RegisterNUICallback('joinEvent', function(data, cb)
    joinUIOpen = false
    SetNuiFocus(false, false)
    
    -- Lưu vị trí hiện tại khi tham gia
    PreviousCoords = GetEntityCoords(PlayerPedId())
    
    TriggerServerEvent(scriptname .. ':confirmJoin')
    cb('ok')
end)

RegisterNUICallback('cancelJoin', function(data, cb)
    joinUIOpen = false
    SetNuiFocus(false, false)
    
    -- Dừng nhạc khi hủy tham gia
    SendNUIMessage({type = 'stopsound'})
    
    SendNUIMessage({
        type = 'closeJoinPanel'
    })
    cb('ok')
end)

RegisterNUICallback('requestRoomPlayers', function(data, cb)
    TriggerServerEvent(scriptname .. ':requestRoomPlayers')
    cb('ok')
end)

-- Bắt đầu game
RegisterNetEvent(scriptname .. ':startGame', function(mapData)
    if not mapData or not mapData.coords then
        return
    end
    
    JoinBomber = true
    gameStart = true
    hasQuit = false -- Reset flag quit
    celebrationReceived = false -- Reset flag celebration mỗi ván mới
    currentMap = mapData
    local waitTime = mapData.waitTime or 30
    
    -- Lưu tọa độ nếu chưa có (phòng trường hợp join bằng cách khác)
    if not PreviousCoords then
        PreviousCoords = GetEntityCoords(PlayerPedId())
    end
    
    -- Effect chuyển cảnh an toàn bằng screen fade
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end
    
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Chuyển dimension
    TriggerServerEvent(scriptname .. ':changeDimension', mapData.dimension)
    Citizen.Wait(500)
    
    -- Đảm bảo snapshot sạch khi bắt đầu ván mới
    _pedSnapshot = nil

    -- Đổi skin nếu cần
    if Config.DoiSkin then
        local success = SetSkin(Config.TenSkin)
        if not success then
            print("^3[WARNING] Skipping skin change, using default^0")
        end
        Citizen.Wait(500)
    end
    
    -- Teleport vào map với random spawn
    local spawnX = mapData.coords.x + math.random(-mapData.spawnRange, mapData.spawnRange)
    local spawnY = mapData.coords.y + math.random(-mapData.spawnRange, mapData.spawnRange)
    local spawnZ = mapData.coords.z + 2
    local spawnCoords = vector3(spawnX, spawnY, spawnZ)
    SetEntityCoords(PlayerPedId(), spawnX, spawnY, spawnZ)
    
    -- Đợi để đảm bảo đã teleport xong
    Citizen.Wait(500)
    
    -- Dừng nhạc trước khi vào
    SendNUIMessage({type = 'stopsound'})
    Citizen.Wait(300)
    
    -- Fade in màn hình tại vị trí mới
    DoScreenFadeIn(800)
    while not IsScreenFadedIn() do Wait(10) end
    
    -- Xóa prop/bom cũ còn sót từ game trước hoặc từ tay player
    holdbomb = false
    local oldBomb = Bomb
    Bomb = nil
    if oldBomb and DoesEntityExist(oldBomb) then
        DetachEntity(oldBomb, true, true)
        DeleteEntity(oldBomb)
        SetEntityAsMissionEntity(oldBomb, false, true)
        DeleteObject(oldBomb)
    end
    ClearPedSecondaryTask(PlayerPedId())
    RemoveAllPedWeapons(PlayerPedId(), true)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    -- Phát Bomberrun ngay khi vào map
    SendNUIMessage({
        type = 'playsound',
        sound = Config.NhacTrongSuKien.TenNhac,
        volume = Config.NhacTrongSuKien.AmLuong,
        loop = false
    })
    
    FreezeEntityPosition(PlayerPedId(), false)

    -- Hồi sinh + set máu full khi vào game
    Revive()
    Citizen.Wait(400)
    SetEntityHealth(PlayerPedId(), 200)
    SetPedArmour(PlayerPedId(), 0)

    -- Bắt đầu các thread game
    StartGameThreads()
    
    -- ANTI-CHEAT: Kiểm tra khoảng cách trong 30s đầu
    Citizen.CreateThread(function()
        local checkEndTime = GetGameTimer() + 30000 -- 30 giây
        while gameStart and GetGameTimer() < checkEndTime do
            Wait(2000) -- Kiểm tra mỗi 2 giây
            
            local currentPos = GetEntityCoords(PlayerPedId())
            local dist = #(currentPos - spawnCoords)
            
            if dist > Config.AntiCheatDistance then
                -- Tele về spawn nếu xa quá 150m
                SetEntityCoords(PlayerPedId(), spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false, false)
            end
        end
    end)
    
    -- Hiển thị countdown "Di chuyển đến vị trí an toàn! Bom sẽ rơi sau XX giây"
    local countdownTime = waitTime
    
    -- Thread nhạc countdown
    Citizen.CreateThread(function()
        -- Đợi đến khi còn 5 giây (waitTime - 5 giây)
        local waitFor5Count = (waitTime - 5) * 1000
        if waitFor5Count > 0 then
            Citizen.Wait(waitFor5Count)
        end
        if not gameStart then return end
        
        -- Phát 5cont khi còn 5 giây
        SendNUIMessage({
            type = 'playsound',
            sound = '5count.mp3',
            volume = Config.NhacTrongSuKien.AmLuong,
            loop = false
        })
        
        -- Đợi 5 giây rồi phát OpenBomber loop
        Citizen.Wait(5000)
        if not gameStart then return end
        
        SendNUIMessage({
            type = 'playsound',
            sound = Config.NhacTruocKhiVaoSuKien.TenNhac,
            volume = Config.NhacTruocKhiVaoSuKien.AmLuong,
            loop = true
        })
    end)
    
    -- Thread vẽ text liên tục (không bị chớp)
    Citizen.CreateThread(function()
        while countdownTime > 0 and gameStart do

            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 200, 50, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("DI CHUYỂN ĐẾN VỊ TRÍ AN TOÀN!")
            DrawText(0.5, 0.052)

            SetTextFont(4)
            SetTextProportional(0)
            SetTextScale(0.42, 0.42)
            SetTextColour(255, 80, 60, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("BOM SẼ RƠI SAU  %d  GIÂY", countdownTime))
            DrawText(0.5, 0.082)

            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.3, 0.3)
            SetTextColour(255, 80, 80, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("Không ôm bom: Tránh xa người giữ bom")
            DrawText(0.5, 0.116)

            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.3, 0.3)
            SetTextColour(240, 240, 240, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString("Ôm bom: Nhấn ~g~[E]~w~ để chuyền bom cho người gần nhất (3m)")
            DrawText(0.5, 0.138)

            Citizen.Wait(0)
        end
    end)
    
    -- Thread đếm ngược mỗi giây
    Citizen.CreateThread(function()
        while countdownTime > 0 and gameStart do
            Citizen.Wait(1000)
            countdownTime = countdownTime - 1
        end
        -- Countdown kết thúc → báo server để xuất hiện bom
        if gameStart then
            TriggerServerEvent(scriptname .. ':countdownDone')
        end
    end)
end)

local function DeleteBombEntity(entity)
    if not entity then return end
    if DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        SetEntityAsMissionEntity(entity, false, true)
        DeleteEntity(entity)
        DeleteObject(entity)
    end
end

-- Xóa prop bom (gọi trước khi trao giải)
RegisterNetEvent(scriptname .. ':removeBombProp', function()
    holdbomb = false
    gameStart = false
    
    -- Dừng nhạc trong sự kiện
    SendNUIMessage({type = 'stopsound'})
    
    -- Xóa prop bom trong 5 giây để đảm bảo
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        DeleteBombEntity(bombToDelete)
    end
    
    -- Reset tốc độ chạy về bình thường
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)

-- ================================================
-- Celebration - Ăn mừng chiến thắng
-- ================================================
RegisterNetEvent(scriptname .. ':teleportToCelebration', function(data)
    -- Bỏ qua nếu player đã quit
    if hasQuit then return end
    
    -- NOTE: PreviousCoords VẪN ĐƯỢC GIỮ NGUYÊN trong celebration
    -- Server sẽ gọi :endGame sau 15s để teleport về PreviousCoords
    
    local ped = PlayerPedId()
    
    -- Đánh dấu đã nhận celebration → death thread sẽ không vào StartSpectate nữa
    celebrationReceived = true

    -- Force stop spectate hoàn toàn (dù isSpectating true hay false)
    -- Race condition: celebration có thể đến TRONG KHI StartSpectate() đang chờ list
    -- → isSpectating vẫn false nhưng ped đã invisible, cam chưa về
    isSpectating = false
    spectatePlayerList = {}
    if spectateCam then
        DestroyCam(spectateCam, false)
        RenderScriptCams(false, false, 0, true, false)
        spectateCam = nil
    end
    -- Force restore visibility/state ngay lập tức
    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    -- Đợi engine chuyển về game camera
    Wait(1000)
    
    -- XÓA PROP BOM trong 5 giây để đảm bảo
    holdbomb = false
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        DeleteBombEntity(bombToDelete)
    end
    
    ClearPedSecondaryTask(ped)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    -- FADE OUT NGAY để tối màn hình
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    -- SET VÔ HÌNH trước khi revive
    SetEntityVisible(ped, false, false)
    SetEntityAlpha(ped, 0, false)
    
    -- BƯỚC 1: Gọi server revive qbx_medical (xóa death state chính thức)
    TriggerServerEvent(scriptname .. ':reviveMe')
    
    -- BƯỚC 2: Đợi qbx_medical xử lý revive trên client (state sync)
    Wait(1000)
    
    -- BƯỚC 3: Ẩn death UI
    pcall(function()
        exports['qbx_medical']:HideDeathUI()
    end)
    
    -- BƯỚC 4: Force resurrect + clear state
    local currentPos = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(currentPos.x, currentPos.y, currentPos.z, GetEntityHeading(ped), true, false)
    Wait(500)
    SetEntityHealth(ped, 200)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    SetPedCanRagdoll(ped, false)
    ResetPedMovementClipset(ped, 0.0)
    
    -- BƯỚC 5: Đợi revive hoàn tất (vẫn vô hình)
    Wait(500)
    
    -- Teleport đến vị trí celebration (VẪN VÔ HÌNH)
    local x, y, z, heading = data.position.x, data.position.y, data.position.z, data.position.w
    
    -- Request collision
    RequestCollisionAtCoord(x, y, z)
    
    -- Freeze trước khi teleport
    FreezeEntityPosition(ped, true)
    
    -- Teleport đến tọa độ chính xác
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    
    -- Chờ collision load
    local attempts = 0
    while not HasCollisionLoadedAroundEntity(ped) and attempts < 20 do
        RequestCollisionAtCoord(x, y, z)
        Wait(50)
        attempts = attempts + 1
    end
    
    -- Đảm bảo tại vị trí chính xác
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, true, true)
    
    -- BỎ VÔ HÌNH - HIỆN LÊN
    SetEntityVisible(ped, true, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)
    
    -- Xóa TẤT CẢ vũ khí
    RemoveAllPedWeapons(ped, true)

    -- Đợi 1 giây để entity render đúng (quan trọng khi đến từ spectate mode, engine cần
    -- vài frame sau RenderScriptCams(false) + SetEntityVisible mới áp dụng cho ped)
    Wait(1000)
    
    -- FADE IN để hiện màn hình
    Wait(300)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do
        Wait(0)
    end
    
    -- Wait thêm trước khi chạy animation
    Wait(300)
    
    -- Đảm bảo player đứng đúng vị trí trước khi chạy animation
    local x, y, z, heading = data.position.x, data.position.y, data.position.z, data.position.w
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, heading)
    
    ClearPedTasksImmediately(ped)
    
    -- Chơi animation dựa trên winner/loser
    local animDict, animName
    if data.isWinner then
        -- Animation người thắng - Dơ 2 tay lên cao
        animDict = "anim@mp_player_intcelebrationfemale@air_shagging"
        animName = "air_shagging"
        
        -- Unfreeze để animation tự nhiên hơn
        FreezeEntityPosition(ped, false)
    else
        -- Animation người thua - Quỳ gối dơ 2 tay sau đầu
        animDict = "random@arrests@busted"
        animName = "enter"
        
        -- CỐ ĐỊNH NGƯỜI CHƠI (freeze) trước khi quỳ
        FreezeEntityPosition(ped, true)
    end
    
    -- Phát tiếng pháo hoa
    CreateThread(function()
        for i = 1, 6 do
            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
            Wait(1000)
        end
    end)
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(10)
    end
    
    if data.isWinner then
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        
        -- Freeze sau 500ms
        Wait(500)
        FreezeEntityPosition(ped, true)
    else
        -- Người thua: Chạy animation quỳ gối trong trạng thái FREEZE
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 2, 0, false, false, false)
        Wait(1500) -- Đợi animation "enter" hoàn thành
        
        -- Request animation idle
        RequestAnimDict("random@arrests@busted")
        while not HasAnimDictLoaded("random@arrests@busted") do
            Wait(10)
        end
        
        -- VÒNG LẶP: Giữ animation quỳ gối liên tục
        CreateThread(function()
            local celebrationEndTime = GetGameTimer() + (Config.CelebrationTime * 1000)
            
            -- Chạy animation idle_a lần đầu
            TaskPlayAnim(ped, "random@arrests@busted", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
            
            while GetGameTimer() < celebrationEndTime and JoinBomber do
                Wait(0)
                
                -- Giữ vị trí cố định
                SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
                SetEntityHeading(ped, heading)
                FreezeEntityPosition(ped, true)
                
                -- Nếu animation dừng, chạy lại
                if not IsEntityPlayingAnim(ped, "random@arrests@busted", "idle_a", 3) then
                    TaskPlayAnim(ped, "random@arrests@busted", "idle_a", 8.0, -8.0, -1, 1, 0, false, false, false)
                end
            end
        end)
    end
end)

-- ================================================
-- Kết thúc game
-- ================================================
RegisterNetEvent(scriptname .. ':endGame', function()
    -- Bỏ qua nếu player đã quit
    if hasQuit then return end
    
    JoinBomber = false
    gameStart = false
    holdbomb = false
    -- Dừng spectate trước tiên (giải phóng cam, restore ped visibility)
    StopSpectate()
    
    -- Dừng tất cả nhạc
    SendNUIMessage({type = 'stopsound'})

    -- Đảm bảo restore visibility (backup nếu StopSpectate không chạy)
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    
    -- Xóa bom nếu đang cầm (double check) - xóa trong 5s
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        Citizen.CreateThread(function()
            local deleteEndTime = GetGameTimer() + 5000
            while GetGameTimer() < deleteEndTime do
                if DoesEntityExist(bombToDelete) then
                    DetachEntity(bombToDelete, true, true)
                    DeleteEntity(bombToDelete)
                    SetEntityAsMissionEntity(bombToDelete, false, true)
                    DeleteObject(bombToDelete)
                else
                    break
                end
                Wait(100)
            end
        end)
    end
    
    -- Reset tốc độ chạy về bình thường
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    -- Chuyển về dimension chính
    TriggerServerEvent(scriptname .. ':changeDimension', 0)
    -- Đợi server xử lý routing bucket trước khi teleport (dimension change là async server-side)
    Wait(600)

    -- BƯỚC 1: Hồi sinh trước tiên (nếu đang chết) để Ped ở trạng thái hoạt động bình thường
    if IsPedDeadOrDying(PlayerPedId(), 1) then
        Revive()
        Wait(500)
    end

    -- Đảm bảo tất cả ẩn hiển thị/va chạm được phục hồi
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)

    -- Kiểm tra và gán tọa độ dự phòng nếu PreviousCoords bị mất/nil
    if not PreviousCoords then
        local fallbackCoords = Config.JoinNPC and Config.JoinNPC.coords or vec4(224.4309, -902.9344, 29.4835, 0.0)
        PreviousCoords = vec3(fallbackCoords.x, fallbackCoords.y, fallbackCoords.z)
    end
    
    -- Effect chuyển cảnh an toàn bằng screen fade (có timeout guard tránh treo vô hạn)
    DoScreenFadeOut(800)
    local fadeWait = 0
    while not IsScreenFadedOut() and fadeWait < 3000 do
        Wait(50)
        fadeWait = fadeWait + 50
    end
    
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Teleport về vị trí cũ
    SetEntityCoords(PlayerPedId(), PreviousCoords.x, PreviousCoords.y, PreviousCoords.z, false, false, false, false)
    Wait(500)
    
    DoScreenFadeIn(800)
    while not IsScreenFadedIn() do Wait(10) end
    
    -- Reset skin sau khi đã hồi sinh và teleport thành công
    if Config.DoiSkin then
        ResetSkin()
    end
    
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Reset vị trí đã lưu
    PreviousCoords = nil
end)

-- Event trao giải cho người thắng
RegisterNetEvent(scriptname .. ':gotoAwardCeremony', function()
    JoinBomber = false
    gameStart = false
    holdbomb = false
    
    -- Xóa bom nếu đang cầm (double check - đã xóa ở removeBombProp) - xóa trong 5s
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        Citizen.CreateThread(function()
            local deleteEndTime = GetGameTimer() + 5000
            while GetGameTimer() < deleteEndTime do
                if DoesEntityExist(bombToDelete) then
                    DetachEntity(bombToDelete, true, true)
                    DeleteEntity(bombToDelete)
                    SetEntityAsMissionEntity(bombToDelete, false, true)
                    DeleteObject(bombToDelete)
                else
                    break
                end
                Wait(100)
            end
        end)
    end
    
    -- Reset tốc độ chạy về bình thường (double check)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    
    -- Chuyển về dimension chính
    TriggerServerEvent(scriptname .. ':changeDimension', 0)
    
    -- BƯỚC 1: Hồi sinh trước tiên (nếu đang chết)
    if IsPedDeadOrDying(PlayerPedId(), 1) then
        Revive()
        Wait(500)
    end

    -- Đảm bảo tất cả ẩn hiển thị/va chạm được phục hồi
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    SetEntityAlpha(ped, 255, false)
    ResetEntityAlpha(ped)
    
    -- Effect chuyển cảnh an toàn bằng screen fade
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do Wait(50) end
    
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Teleport đến vị trí trao giải (có fallback)
    local awardCoords = Config.ToaDoTraoGiai
    if not awardCoords then
        local fallbackCoords = Config.JoinNPC and Config.JoinNPC.coords or vec3(224.4309, -902.9344, 29.4835)
        awardCoords = vec3(fallbackCoords.x, fallbackCoords.y, fallbackCoords.z)
    end
    SetEntityCoords(PlayerPedId(), awardCoords.x, awardCoords.y, awardCoords.z, false, false, false, false)
    Wait(500)
    
    DoScreenFadeIn(800)
    while not IsScreenFadedIn() do Wait(10) end
    
    -- Reset skin
    if Config.DoiSkin then
        ResetSkin()
    end
    
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Vỗ tay
    local playerPed = PlayerPedId()
    RequestAnimDict("anim@mp_player_intcelebrationmale@slow_clap")
    while not HasAnimDictLoaded("anim@mp_player_intcelebrationmale@slow_clap") do
        Citizen.Wait(100)
    end
    
    TaskPlayAnim(playerPed, "anim@mp_player_intcelebrationmale@slow_clap", "slow_clap", 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- Hiển thị text đếm ngược
    local ceremonyTime = Config.ThoiGianVoTay
    Citizen.CreateThread(function()
        while ceremonyTime > 0 do
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.6)
            SetTextColour(255, 215, 0, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextCentre(true)
            SetTextEntry("STRING")
            AddTextComponentString(string.format("🏆 CHÚC MỪNG BẠN ĐÃ CHIẾN THẮNG! 🏆"))
            DrawText(0.5, 0.85)
            
            Citizen.Wait(0)
        end
    end)
    
    -- Đếm ngược
    Citizen.CreateThread(function()
        while ceremonyTime > 0 do
            Citizen.Wait(1000)
            ceremonyTime = ceremonyTime - 1
        end
        
        -- Dừng animation
        ClearPedTasks(playerPed)
        
        -- Thông báo server đã xong (để cộng tiền nếu bật auto)
        TriggerServerEvent(scriptname .. ':finishAwardCeremony')
        
        -- Teleport về vị trí cũ sau 2 giây
        Citizen.Wait(2000)
        
        if PreviousCoords then
            -- Effect chuyển cảnh an toàn bằng screen fade
            DoScreenFadeOut(800)
            while not IsScreenFadedOut() do Wait(50) end
            
            FreezeEntityPosition(PlayerPedId(), true)
            SetEntityCoords(PlayerPedId(), PreviousCoords.x, PreviousCoords.y, PreviousCoords.z, false, false, false, false)
            
            Wait(500)
            DoScreenFadeIn(800)
            while not IsScreenFadedIn() do Wait(10) end
            FreezeEntityPosition(PlayerPedId(), false)
        end
        
        PreviousCoords = nil
    end)
end)

-- Cầm bom
RegisterNetEvent(scriptname .. ':holdBomb', function(timeRemaining)
    if IsPedDeadOrDying(PlayerPedId()) and gameStart then
        Revive()
    end
    
    ClearPedTasksImmediately(PlayerPedId())
    
    -- Phát tiếng effect chuyển bom
    SendNUIMessage({
        type = 'eff',
        sound = Config.TiengEffectChuyenBom.TenNhac,
        volume = Config.TiengEffectChuyenBom.AmLuong
    })
    
    HoldBomb(timeRemaining)
end)

-- Xóa bom
RegisterNetEvent(scriptname .. ':clearBomb', function()
    holdbomb = false
    
    -- Xóa prop trong 5 giây để đảm bảo (thử xóa liên tục)
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        DeleteBombEntity(bombToDelete)
    end
    
    -- Phát tiếng effect chuyển bom
    SendNUIMessage({
        type = 'eff',
        sound = Config.TiengEffectChuyenBom.TenNhac,
        volume = Config.TiengEffectChuyenBom.AmLuong
    })
    
    -- Reset tốc độ chạy
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    ClearPedSecondaryTask(PlayerPedId())
end)

-- Cập nhật danh sách người cầm bom
RegisterNetEvent(scriptname .. ':updateBomberList', function(bomberList)
    playerBomb = bomberList
end)

-- Lệnh test cầm bom
-- RegisterCommand('testbomb', function()
--     HoldBomb()
-- end, false)

-- RegisterCommand('testbomb1', function()
--     Config.TenPropBom = 'mondaye_prop_bomb_0_1'
--     HoldBomb()
-- end, false)

-- RegisterCommand('testbomb2', function()
--     Config.TenPropBom = 'mondaye_prop_bomb_0_2'
--     HoldBomb()
-- end, false)

-- RegisterCommand('testbombstrong1', function()
--     Config.TenPropBom = 'mondaye_prop_bomb_strong_0_1'
--     HoldBomb()
-- end, false)

-- RegisterCommand('testbombstrong2', function()
--     Config.TenPropBom = 'mondaye_prop_bomb_strong_0_2'
--     HoldBomb()
-- end, false)

RegisterCommand('clearbomb', function()
    holdbomb = false
    local bombToDelete = Bomb
    Bomb = nil
    
    if bombToDelete then
        Citizen.CreateThread(function()
            local deleteEndTime = GetGameTimer() + 5000
            while GetGameTimer() < deleteEndTime do
                if DoesEntityExist(bombToDelete) then
                    DetachEntity(bombToDelete, true, true)
                    DeleteEntity(bombToDelete)
                    SetEntityAsMissionEntity(bombToDelete, false, true)
                    DeleteObject(bombToDelete)
                else
                    break
                end
                Wait(100)
            end
        end)
    end
    ClearPedSecondaryTask(PlayerPedId())
end, false)

-- Lệnh thoát sớm khỏi ván bomber
RegisterCommand('quitbom', function()
    if not JoinBomber then
        QBCore.Functions.Notify('Bạn không ở trong sự kiện Bomber!', 'error')
        return
    end
    
    -- Đánh dấu đã quit
    hasQuit = true
    
    -- Báo server
    TriggerServerEvent(scriptname .. ':playerQuit')
    
    -- Stop spectate nếu đang xem
    if isSpectating then
        StopSpectate()
    end
    
    -- Reset trạng thái game
    JoinBomber = false
    gameStart = false
    holdbomb = false
    
    -- Xóa bom prop
    local bombToDelete = Bomb
    Bomb = nil
    if bombToDelete then
        Citizen.CreateThread(function()
            local deleteEndTime = GetGameTimer() + 5000
            while GetGameTimer() < deleteEndTime do
                if DoesEntityExist(bombToDelete) then
                    DetachEntity(bombToDelete, true, true)
                    DeleteEntity(bombToDelete)
                    SetEntityAsMissionEntity(bombToDelete, false, true)
                    DeleteObject(bombToDelete)
                else
                    break
                end
                Wait(100)
            end
        end)
    end
    
    -- Reset player state
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    ClearPedSecondaryTask(ped)
    
    -- Dừng nhạc
    SendNUIMessage({type = 'stopsound'})
    
    -- Về dimension chính
    TriggerServerEvent(scriptname .. ':changeDimension', 0)
    
    -- Teleport về PreviousCoords nếu có
    if PreviousCoords then
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        
        -- Hồi sinh trước khi teleport về nếu đang chết
        if IsPedDeadOrDying(ped, 1) then
            Revive()
            Wait(500)
        end
        
        SetEntityCoords(ped, PreviousCoords.x, PreviousCoords.y, PreviousCoords.z, false, false, false, false)
        Wait(500)
        
        DoScreenFadeIn(500)
        PreviousCoords = nil
    end
    
    QBCore.Functions.Notify('Bạn đã rời khỏi sự kiện Bomber!', 'success')
end, false)

-- Hàm cầm bom
function HoldBomb(timeRemaining)
    -- Nếu có timeRemaining (từ transfer) thì dùng, không thì dùng config
    CountBomb = timeRemaining or Config.ThoiGianTruocKhiNoBomp
    effectscale = 0.1 -- Reset hiệu ứng về nhỏ khi cầm bom mới
    
    -- Xóa prop bom CŨ trước (tránh tạo 2 prop khi holdBomb gọi liên tiếp)
    if Bomb then
        local oldBomb = Bomb
        Bomb = nil
        holdbomb = false
        DeleteBombEntity(oldBomb)
        Wait(50) -- Đợi engine xử lý xóa xong
    end
    
    holdbomb = true
    
    -- Dừng hết hiệu ứng chuyển cảnh (tránh bị dính màn hình)
    StopPlayerSwitch()
    
    Wait(100)
    
    -- Animation
    local animdict = "anim@heists@box_carry@"
    local animname = "idle"
    RequestAnimDict(animdict)
    while not HasAnimDictLoaded(animdict) do Citizen.Wait(1) end
    TaskPlayAnim(PlayerPedId(), animdict, animname, 5.0, -1.0, -1, 50, 0, false, false, false)
    
    -- Load model bom
    local bombModel = GetHashKey(Config.TenPropBom)
    
    RequestModel(bombModel)
    local timeout = 0
    while not HasModelLoaded(bombModel) and timeout < 5000 do
        Citizen.Wait(10)
        timeout = timeout + 10
    end
    
    if not HasModelLoaded(bombModel) then
        bombModel = GetHashKey('prop_bomb_01')
        RequestModel(bombModel)
        while not HasModelLoaded(bombModel) do
            Citizen.Wait(1)
        end
    end
    
    -- Tạo bom
    local coords = GetEntityCoords(PlayerPedId())
    Bomb = CreateObject(bombModel, coords.x, coords.y, coords.z, true, true, true)
    
    if Bomb and DoesEntityExist(Bomb) then
        SetEntityAsMissionEntity(Bomb, true, true)
        AttachEntityToEntity(Bomb, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28252), 
                            0.5, 0.6, 0.00, 30.0, 270.0, 180.0, true, true, false, true, 1, true)
    else
        print("^1[ERROR] Failed to create bomb entity^0")
        holdbomb = false
        return
    end
    
    -- Thread giữ animation
    Citizen.CreateThread(function()
        while holdbomb do
            if not IsEntityPlayingAnim(PlayerPedId(), animdict, animname, 3) then
                TaskPlayAnim(PlayerPedId(), animdict, animname, 5.0, -1.0, -1, 50, 0, false, false, false)
            end
            Citizen.Wait(3000)
        end
    end)
    
    -- Thread không bị ragdoll
    Citizen.CreateThread(function()
        while holdbomb do
            SetPedCanRagdoll(PlayerPedId(), false)
            Citizen.Wait(5)
        end
    end)
    
    -- Thread hiệu ứng
    Citizen.CreateThread(function()
        while holdbomb do
            Wait(1000)
            if holdbomb then
                UseParticleFxAssetNextCall('core')
                StartNetworkedParticleFxNonLoopedOnEntity('ent_dst_elec_fire_sp', Bomb, 
                                                           0.0, 0.0, 0.80, 0.0, 0.0, 0.0, 
                                                           effectscale, false, false, false)
            end
        end
    end)
    
    -- Thread đếm ngược
    if Config.NewMode then
        Citizen.CreateThread(function()
            local bombMusicPlayed = false
            while holdbomb do
                Wait(1000)
                CountBomb = CountBomb - 1
                
                if CountBomb < 20 and CountBomb > 10 then
                    effectscale = 0.3
                elseif CountBomb < 10 and CountBomb > 5 then
                    effectscale = 0.5
                elseif CountBomb < 5 and CountBomb > 1 then
                    effectscale = 3.0
                    -- Phát nhạc khi cầm bom (chỉ một lần)
                    if not bombMusicPlayed then
                        SendNUIMessage({
                            type = 'eff',
                            sound = Config.NhacKhiCamBom.TenNhac,
                            volume = Config.NhacKhiCamBom.AmLuong
                        })
                        bombMusicPlayed = true
                    end
                elseif CountBomb < 1 then
                    effectscale = 5.0
                end
                
                if CountBomb == 0 then
                    CountBomb = -10
                    
                    -- Xóa bom khi nổ - xóa trong 5s để đảm bảo
                    local bombToDelete = Bomb
                    Bomb = nil
                    if bombToDelete then
                        Citizen.CreateThread(function()
                            local deleteEndTime = GetGameTimer() + 5000
                            while GetGameTimer() < deleteEndTime do
                                if DoesEntityExist(bombToDelete) then
                                    DetachEntity(bombToDelete, true, true)
                                    DeleteEntity(bombToDelete)
                                    SetEntityAsMissionEntity(bombToDelete, false, true)
                                    DeleteObject(bombToDelete)
                                else
                                    break
                                end
                                Wait(100)
                            end
                        end)
                    end
                    
                    ClearPedSecondaryTask(PlayerPedId())
                    
                    local coords = GetEntityCoords(PlayerPedId())
                    AddExplosion(coords.x, coords.y, coords.z, 19, 0.05, true, false, false)
                    AddExplosion(coords.x, coords.y, coords.z, 2, Config.SucManh, true, false, false)
                    
                    SetEntityHealth(PlayerPedId(), 0)
                    TriggerServerEvent(scriptname .. ':bomberDied')
                    holdbomb = false
                end
            end
        end)
        
        -- Hiển thị đếm ngược
        Citizen.CreateThread(function()
            while holdbomb do
                Wait(0)
                local coords = GetEntityCoords(PlayerPedId())
                if CountBomb > 0 then
                    DrawText3D(coords.x, coords.y, coords.z + 1.0, CountBomb, 255, 0, 0)
                end
            end
        end)
    end
end

-- Thread chính của game
function StartGameThreads()
    -- Clear mọi hiệu ứng chuyển cảnh còn lại
    StopPlayerSwitch()

    -- Thread phát hiện chết → spectate ngay
    Citizen.CreateThread(function()
        local markedDead = false  -- ✅ Một khi true thì không reset
        while JoinBomber do
            Wait(500)
            if not markedDead then
                local hp = GetEntityHealth(PlayerPedId())
                local isDead = hp <= 100 or IsPedDeadOrDying(PlayerPedId(), 1)
                if isDead then
                    markedDead = true
                    TriggerServerEvent(scriptname .. ':playerDiedInGame')
                    
                    -- BƯỚC 1: Nằm đó 3 giây (để death animation chạy)
                    local sleepTime1 = 3000
                    while sleepTime1 > 0 and JoinBomber do
                        Wait(100)
                        sleepTime1 = sleepTime1 - 100
                    end
                    if not JoinBomber then return end
                    
                    -- BƯỚC 2: Tàng hình 2 giây
                    local ped = PlayerPedId()
                    SetEntityVisible(ped, false, false)
                    SetEntityInvincible(ped, true)
                    SetEntityCollision(ped, false, false)
                    
                    local sleepTime2 = 2000
                    while sleepTime2 > 0 and JoinBomber do
                        Wait(100)
                        sleepTime2 = sleepTime2 - 100
                    end
                    if not JoinBomber then 
                        -- Hồi phục ped state nếu game kết thúc trong lúc tàng hình
                        SetEntityVisible(ped, true, false)
                        SetEntityInvincible(ped, false)
                        SetEntityCollision(ped, true, true)
                        return 
                    end
                    
                    -- BƯỚC 3: Hồi sinh 1 giây (ẩn death UI + revive trong lúc vô hình)
                    if GetResourceState('qb-ambulancejob') == 'started' then
                        TriggerEvent('hospital:client:Revive')
                    elseif GetResourceState('qbx_medical') == 'started' then
                        pcall(function()
                            exports['qbx_medical']:HideDeathUI()
                        end)
                    end
                    Wait(300)
                    if not JoinBomber then
                        local ped = PlayerPedId()
                        SetEntityVisible(ped, true, false)
                        SetEntityInvincible(ped, false)
                        SetEntityCollision(ped, true, true)
                        return
                    end
                    
                    local pos = GetEntityCoords(ped)
                    NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
                    Wait(200)
                    SetEntityHealth(ped, 200)
                    ClearPedTasksImmediately(ped)
                    Wait(500)
                    if not JoinBomber then
                        local ped = PlayerPedId()
                        SetEntityVisible(ped, true, false)
                        SetEntityInvincible(ped, false)
                        SetEntityCollision(ped, true, true)
                        return
                    end
                    
                    -- BƯỚC 4: Bắt đầu spectate (chỉ nếu chưa nhận celebration)
                    if not celebrationReceived then
                        Citizen.CreateThread(function()
                            StartSpectate()
                        end)
                    end
                end
            end
        end
    end)

    -- ❌ Thread NewMode ĐÃ BỊ XÓA - dùng spectate system thay thế

    -- Thread chuyển bom
    Citizen.CreateThread(function()
        local lastTransfer = 0
        while JoinBomber do
            local waitTime = 150
            if holdbomb then
                waitTime = 0
                if IsControlJustPressed(0, 38) then -- Phím E
                    local now = GetGameTimer()
                    if (now - lastTransfer) > 1000 then -- Giảm cooldown 2500 → 1000ms
                        local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()
                        
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            local targetId = GetPlayerServerId(closestPlayer)
                            local isTargetBomber = false
                            
                            for k, v in pairs(playerBomb) do
                                if targetId == v then
                                    isTargetBomber = true
                                    break
                                end
                            end
                            
                            if isTargetBomber then
                                QBCore.Functions.Notify('💣 Người đó đang cầm bom rồi!', 'error', 2000)
                            else
                                local targetPed = GetPlayerPed(closestPlayer)
                                if not IsPedDeadOrDying(PlayerPedId(), true) and not IsPedDeadOrDying(targetPed, true) then
                                    -- Chặn chuyển bom khi còn <= 3 giây
                                    if Config.BomNoCodinh and CountBomb and CountBomb <= 3 then
                                        QBCore.Functions.Notify('⏰ Bom sắp nổ! Không thể chuyển!', 'error', 2000)
                                    else
                                        lastTransfer = GetGameTimer()
                                        -- Gửi thời gian bom hiện tại nếu config bật
                                        TriggerServerEvent(scriptname .. ':transferBomb', targetId, Config.BomNoCodinh and CountBomb or nil)
                                    end
                                elseif IsPedDeadOrDying(targetPed, true) then
                                    QBCore.Functions.Notify('❌ Người đó đã chết!', 'error', 2000)
                                end
                            end
                        else
                            QBCore.Functions.Notify('❌ Không có ai gần để chuyển bom! (3m)', 'error', 2000)
                        end
                    end
                end
                
                -- Không mệt
                if Config.ChayKhongMet then
                    ResetPlayerStamina(PlayerId())
                end
                
                -- Chạy nhanh
                if Config.ChayNhanh then
                    SetRunSprintMultiplierForPlayer(PlayerId(), Config.TocDoChay)
                end
            end
            Wait(waitTime)
        end
    end)
    
    -- Thread kiểm tra vùng chơi (chỉ khi bật vòng)
    if Config.HienThiVong then
        Citizen.CreateThread(function()
            while JoinBomber do
                Wait(1000)
                
                if not currentMap then
                    print("^3[WARNING] currentMap not set yet, skipping boundary check^0")
                    goto continue
                end
                
                local coords = GetEntityCoords(PlayerPedId())
                local distance = #(coords - currentMap.coords)
                
                if distance > currentMap.radius then
                    local spawnX = currentMap.coords.x + math.random(-currentMap.spawnRange, currentMap.spawnRange)
                    local spawnY = currentMap.coords.y + math.random(-currentMap.spawnRange, currentMap.spawnRange)
                    SetEntityCoords(PlayerPedId(), spawnX, spawnY, currentMap.coords.z + 2)
                end
                
                ::continue::
            end
        end)
    end
    
    -- Vẽ marker vùng chơi
    if Config.HienThiVong then
        Citizen.CreateThread(function()
            while JoinBomber do
                Wait(2)
                
                if not currentMap then
                    goto continue
                end
                
                DrawMarker(1, currentMap.coords.x, currentMap.coords.y, currentMap.coords.z - 5.2, 
                          0.0, 0.0, 0.0, 0, 0.0, 0.0, 
                          currentMap.radius * 2, currentMap.radius * 2, 30.0, 
                          255, 0, 0, 100, false, true, 2, false, false, false, false)
                
                ::continue::
            end
        end)
    end
end

-- ================================================
-- Skin Change TẠM THỜI (không lưu database)
-- Dùng native snapshot để đảm bảo appearance được restore chính xác
-- ================================================

-- Lưu model hash gốc và snapshot toàn bộ appearance trước khi đổi skin
local _originalModelHash = nil

-- ========== Snapshot helpers ==========
-- Lưu TOÀN BỘ appearance của ped bằng native (component, overlay, headblend, face, hair, eye)
local function SavePedAppearance(ped)
    local snap = {
        components   = {},
        overlays     = {},
        faceFeatures = {},
        headBlend    = nil,
        hairColor    = nil,
        eyeColor     = 0,
    }

    -- 1. Components (tóc, quần áo, phụ kiện...)
    for i = 0, 11 do
        snap.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture  = GetPedTextureVariation(ped, i),
            palette  = GetPedPaletteVariation(ped, i),
        }
    end

    -- 2. Head overlays (makeup, eyebrow, blemish, ageing, complexion, lipstick, blush...)
    for i = 0, 12 do
        local _, index, colorType, colorId, secondColorId, opacity = GetPedHeadOverlayData(ped, i)
        snap.overlays[i] = {
            index         = index,
            opacity       = opacity,
            colorType     = colorType,
            colorId       = colorId,
            secondColorId = secondColorId,
        }
    end

    -- 3. Face features (19 chỉ số hình dạng khuôn mặt)
    for i = 0, 19 do
        snap.faceFeatures[i] = GetPedFaceFeature(ped, i)
    end

    -- 4. Head blend (skin tone / face shape / heritage)
    local s1,s2,s3,sk1,sk2,sk3,sm,skm,tm,hp = GetPedHeadBlendData(ped)
    snap.headBlend = { s1=s1, s2=s2, s3=s3, sk1=sk1, sk2=sk2, sk3=sk3, sm=sm, skm=skm, tm=tm, hp=hp }

    -- 5. Hair color
    snap.hairColor = { color = GetPedHairColor(ped), highlight = GetPedHairHighlightColor(ped) }

    -- 6. Eye color
    snap.eyeColor = GetPedEyeColor(ped)

    return snap
end

-- Khôi phục appearance từ snapshot đã lưu
local function RestorePedAppearance(ped, snap)
    if not snap then return end

    -- 1. Head blend trước (phải set trước component để headshape đúng)
    local hb = snap.headBlend
    if hb then
        SetPedHeadBlendData(ped, hb.s1, hb.s2, hb.s3, hb.sk1, hb.sk2, hb.sk3, hb.sm, hb.skm, hb.tm, hb.hp)
    end

    -- 2. Components
    for i = 0, 11 do
        local c = snap.components[i]
        if c then SetPedComponentVariation(ped, i, c.drawable, c.texture, c.palette) end
    end

    -- 3. Face features
    for i = 0, 19 do
        if snap.faceFeatures[i] then
            SetPedFaceFeature(ped, i, snap.faceFeatures[i])
        end
    end

    -- 4. Head overlays (makeup, blemish, eyebrows, lipstick, blush...)
    for i = 0, 12 do
        local ov = snap.overlays[i]
        if ov then
            SetPedHeadOverlay(ped, i, ov.index, ov.opacity)
            if ov.colorType ~= nil and ov.colorId ~= nil then
                SetPedHeadOverlayColor(ped, i, ov.colorType, ov.colorId, ov.secondColorId or 0)
            end
        end
    end

    -- 5. Hair color
    if snap.hairColor then
        SetPedHairColor(ped, snap.hairColor.color, snap.hairColor.highlight)
    end

    -- 6. Eye color
    if snap.eyeColor then
        SetPedEyeColor(ped, snap.eyeColor)
    end
end
-- ======================================

-- Đổi skin TẠM THỜI sang model Bomberman (chỉ client-side)
function SetSkin(model)
    local hash = GetHashKey(model)

    if not IsModelValid(hash) then
        print("^1[BOMBER] Model không hợp lệ: " .. model .. "^0")
        return false
    end

    -- Lưu model gốc
    _originalModelHash = GetEntityModel(PlayerPedId())

    -- ★ Lưu TOÀN BỘ appearance TRƯỚC khi đổi skin (tóc, makeup, màu da, eye color...)
    _pedSnapshot = SavePedAppearance(PlayerPedId())

    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end

    if not HasModelLoaded(hash) then
        print("^1[BOMBER] Không load được model: " .. model .. "^0")
        _originalModelHash = nil
        _pedSnapshot = nil
        return false
    end

    -- Đổi model (KHÔNG trigger clothing event)
    SetPlayerModel(PlayerId(), hash)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(hash)

    print("^2[BOMBER] Đã đổi skin tạm sang: " .. model .. "^0")
    return true
end

-- Khôi phục toàn bộ appearance gốc
function ResetSkin()
    local PlayerData = QBCore and QBCore.Functions.GetPlayerData()
    local gender = (PlayerData and PlayerData.charinfo and PlayerData.charinfo.gender) or 0

    -- Bước 1: Restore về base freemode model
    local baseModel = (gender == 1) and `mp_f_freemode_01` or `mp_m_freemode_01`

    RequestModel(baseModel)
    local timeout = 0
    while not HasModelLoaded(baseModel) and timeout < 3000 do
        Wait(10)
        timeout = timeout + 10
    end

    if HasModelLoaded(baseModel) then
        SetPlayerModel(PlayerId(), baseModel)
        -- ★ KHÔNG gọi SetPedDefaultComponentVariation ở đây
        -- (gọi sẽ xóa sạch makeup/hair/overlay trước khi clothing reload kịp chạy)
        SetModelAsNoLongerNeeded(baseModel)
    end

    -- Bước 2: Đợi engine xử lý model change
    Wait(500)

    -- Bước 3: ★ Khôi phục snapshot ngay lập tức (đặc biệt quan trọng cho nhân vật nữ)
    -- Snapshot đã lưu đầy đủ: tóc, màu tóc, makeup, màu da, eye color, face features...
    if _pedSnapshot then
        RestorePedAppearance(PlayerPedId(), _pedSnapshot)
        _pedSnapshot = nil
        Wait(300)
    end

    _originalModelHash = nil

    -- Bước 4: Trigger clothing reload làm backup (apply thêm từ database)
    if GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent('illenium-appearance:client:reloadSkin')
    elseif GetResourceState('fivem-appearance') == 'started' then
        TriggerEvent('fivem-appearance:client:reloadSkin')
    elseif GetResourceState('qb-clothing') == 'started' or GetResourceState('XNClothes') == 'started' then
        TriggerEvent('qb-clothing:client:loadPlayerClothing')
    else
        TriggerEvent('illenium-appearance:client:reloadSkin')
        TriggerEvent('qb-clothing:client:loadPlayerClothing')
    end

    print("^2[BOMBER] Đã restore skin + appearance (snapshot + clothing reload)^0")
end

-- ================================================
-- SPECTATE KHI CHẾT
-- ================================================
-- Event nhận danh sách người còn sống từ server
RegisterNetEvent(scriptname .. ':updateSpectateList', function(aliveServerIds)
    spectatePlayerList = aliveServerIds
end)

function StartSpectate()
    if isSpectating then
        return
    end
    
    -- Yêu cầu server gửi danh sách người còn sống
    TriggerServerEvent(scriptname .. ':requestSpectateList')
    
    -- FIX: Đợi danh sách tối đa 3 giây (100ms cũ quá ngắn với latency mạng thực)
    local timeout = GetGameTimer() + 3000
    while #spectatePlayerList == 0 and GetGameTimer() < timeout do
        Wait(100)
    end
    
    -- Retry lần 2 nếu vẫn trống (double-check)
    if #spectatePlayerList == 0 then
        TriggerServerEvent(scriptname .. ':requestSpectateList')
        Wait(500)
    end
    
    if #spectatePlayerList == 0 then
        return -- Không còn ai để xem (game kết thúc hoặc chỉ còn 1 mình)
    end

    isSpectating = true
    spectateTargetIndex = 1

    -- Tàng hình, vô địch, không va chạm, đứng yên
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    -- Tạo camera
    spectateCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(spectateCam, true)
    RenderScriptCams(true, false, 0, true, false)

    -- Thread camera + phím A/D
    Citizen.CreateThread(function()
        local lastListUpdate = 0  -- FIX: Dùng timer biến, không dùng modulo
        while isSpectating and JoinBomber do
            Wait(0)
            
            -- FIX: Update danh sách mỗi 2 giây - dùng lastListUpdate để chính xác
            local now = GetGameTimer()
            if now - lastListUpdate >= 2000 then
                lastListUpdate = now
                TriggerServerEvent(scriptname .. ':requestSpectateList')
            end
            
            if #spectatePlayerList == 0 then
                StopSpectate()
                break
            end

            -- Giới hạn index
            if spectateTargetIndex > #spectatePlayerList then spectateTargetIndex = 1 end
            if spectateTargetIndex < 1 then spectateTargetIndex = #spectatePlayerList end

            local targetServerId = spectatePlayerList[spectateTargetIndex]
            local targetPlayer = GetPlayerFromServerId(targetServerId)
            
            -- FIX: Tránh vòng lặp vô hạn khi player ngoài tầm streaming
            if targetPlayer == -1 then
                local found = false
                for i = 1, #spectatePlayerList do
                    local checkIdx = (spectateTargetIndex - 1 + i) % #spectatePlayerList + 1
                    if GetPlayerFromServerId(spectatePlayerList[checkIdx]) ~= -1 then
                        spectateTargetIndex = checkIdx
                        found = true
                        break
                    end
                end
                if not found then
                    Wait(500) -- Tất cả đều ngoài tầm, đợi rồi thử lại
                    goto continue
                end
                targetPlayer = GetPlayerFromServerId(spectatePlayerList[spectateTargetIndex])
            end
            
            local targetPed = GetPlayerPed(targetPlayer)

            if DoesEntityExist(targetPed) then
                -- Teleport ped ẩn đến target
                local coords = GetEntityCoords(targetPed)
                SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)

                -- Camera phía sau và trên target (góc nhìn rộng)
                local heading = GetEntityHeading(targetPed)
                local camX = coords.x + math.sin(math.rad(heading)) * 6.0
                local camY = coords.y - math.cos(math.rad(heading)) * 6.0
                local camZ = coords.z + 4.0
                SetCamCoord(spectateCam, camX, camY, camZ)
                PointCamAtEntity(spectateCam, targetPed, 0.0, 0.0, 0.0, true)

                -- HUD hướng dẫn (KHÔNG HIỆN TÊN)
                SetTextFont(0)
                SetTextScale(0.3, 0.3)
                SetTextColour(200, 200, 200, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextCentre(true)
                SetTextEntry('STRING')
                AddTextComponentString('~g~[A]~w~ Nguoi truoc    ~g~[D]~w~ Nguoi tiep theo')
                DrawText(0.5, 0.05)
            end

            -- Disable các controls không cần thiết
            DisableControlAction(0, 1, true)   -- Camera Y-Axis
            DisableControlAction(0, 2, true)   -- Camera X-Axis
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon Wheel
            -- Phải disable A/D để dùng IsDisabledControlJustPressed (khi ped bị freeze + script cam, engine tự disable movement controls)
            DisableControlAction(0, 34, true)  -- A (Move Left)
            DisableControlAction(0, 35, true)  -- D (Move Right)
            
            -- Chuyển target với A/D - dùng IsDisabledControlJustPressed vì control đã bị disable
            if IsDisabledControlJustPressed(0, 34) then -- A
                spectateTargetIndex = spectateTargetIndex - 1
                Wait(200) -- Debounce
            elseif IsDisabledControlJustPressed(0, 35) then -- D
                spectateTargetIndex = spectateTargetIndex + 1
                Wait(200) -- Debounce
            end
            
            ::continue::
        end
    end)
end

function StopSpectate()
    if not isSpectating then return end
    isSpectating = false
    spectatePlayerList = {} -- Clear danh sách

    if spectateCam then
        DestroyCam(spectateCam, false)
        RenderScriptCams(false, false, 0, true, false)
        spectateCam = nil
    end

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
end
-- ================================================

-- Hàm hồi sinh
function Revive()
    -- Gọi server để revive qua framework/ambulancejob
    TriggerServerEvent(scriptname .. ':reviveMe')
    
    -- Trực tiếp ẩn death UI nếu dùng qbx_medical hoặc qb-ambulancejob
    if GetResourceState('qb-ambulancejob') == 'started' then
        TriggerEvent('hospital:client:Revive')
    elseif GetResourceState('qbx_medical') == 'started' then
        pcall(function()
            exports['qbx_medical']:HideDeathUI()
        end)
    end
    
    -- Backup phía client
    Citizen.SetTimeout(300, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
        SetEntityHealth(ped, 200)
        ClearPedBloodDamage(ped)
    end)
end

-- Hàm vẽ text 3D
function DrawText3D(x, y, z, text, r, g, b)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(r or 255, g or 255, b or 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- ================================================
-- Spawn NPC & ox_target interaction
-- ================================================
local spawnedJoinPed = nil

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if Config.JoinNPC and Config.JoinNPC.enabled then
            local pedCoords = Config.JoinNPC.coords
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - pedCoords.xyz)
            
            if dist < 50.0 then
                -- Spawn Ped
                if not DoesEntityExist(spawnedJoinPed) then
                    local pedModel = GetHashKey(Config.JoinNPC.model)
                    RequestModel(pedModel)
                    while not HasModelLoaded(pedModel) do
                        Wait(10)
                    end
                    
                    spawnedJoinPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, false)
                    SetEntityAsMissionEntity(spawnedJoinPed, true, true)
                    SetBlockingOfNonTemporaryEvents(spawnedJoinPed, true)
                    SetEntityInvincible(spawnedJoinPed, true)
                    FreezeEntityPosition(spawnedJoinPed, true)
                    
                    -- Play an idle / holding animation
                    RequestAnimDict("amb@world_human_cop_idles@male@idle_b")
                    local waitTime = 0
                    while not HasAnimDictLoaded("amb@world_human_cop_idles@male@idle_b") and waitTime < 50 do
                        Wait(10)
                        waitTime = waitTime + 1
                    end
                    if HasAnimDictLoaded("amb@world_human_cop_idles@male@idle_b") then
                        TaskPlayAnim(spawnedJoinPed, "amb@world_human_cop_idles@male@idle_b", "idle_e", 8.0, -8.0, -1, 1, 0, false, false, false)
                    end
                    
                    -- Register ox_target option on the ped
                    exports.ox_target:addLocalEntity(spawnedJoinPed, {
                        {
                            name = 'zc_bomber_join',
                            icon = Config.JoinNPC.icon or 'fas fa-bomb',
                            label = Config.JoinNPC.label or 'Bomberman',
                            onSelect = function()
                                TriggerServerEvent(scriptname .. ':requestJoin')
                            end
                        }
                    })
                end
            else
                if DoesEntityExist(spawnedJoinPed) then
                    DeleteEntity(spawnedJoinPed)
                    spawnedJoinPed = nil
                end
            end
        end
        Wait(sleep)
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(spawnedJoinPed) then
            DeleteEntity(spawnedJoinPed)
            spawnedJoinPed = nil
        end
    end
end)
