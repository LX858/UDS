local tiedPlayers = {}

-- Load dữ liệu người bị trói từ file JSON khi khởi động resource
CreateThread(function()
    local fileData = LoadResourceFile(GetCurrentResourceName(), 'data/tied_players.json')
    if fileData then
        local status, decoded = pcall(json.decode, fileData)
        if status and type(decoded) == 'table' then
            tiedPlayers = decoded
        end
    end
end)

-- Save dữ liệu người bị trói vào file JSON
local function saveTiedData()
    SaveResourceFile(GetCurrentResourceName(), 'data/tied_players.json', json.encode(tiedPlayers, { indent = true }), -1)
end

-- Lấy Identifier duy nhất của người chơi (License)
local function getPlayerIdentifier(src)
    local identifier = GetPlayerIdentifierByType(src, 'license')
    if not identifier then
        local identifiers = GetPlayerIdentifiers(src)
        identifier = identifiers and identifiers[1]
    end
    return identifier
end

-- Hàm đồng bộ StateBag cho cả Player và Entity (Ped) + Lưu dữ liệu bảo tồn trạng thái khi relog
local function setPlayerTiedState(targetServerId, isTiedState, ropeType)
    Player(targetServerId).state:set('isTied', isTiedState, true)
    Player(targetServerId).state:set('ropeType', ropeType, true)

    local targetPed = GetPlayerPed(targetServerId)
    if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
        Entity(targetPed).state:set('isTied', isTiedState, true)
        Entity(targetPed).state:set('ropeType', ropeType, true)
    end

    -- Lưu trạng thái bị trói vào file JSON server để khi out server vào lại vẫn bị trói
    local identifier = getPlayerIdentifier(targetServerId)
    if identifier then
        if isTiedState then
            tiedPlayers[identifier] = { isTied = true, ropeType = ropeType }
        else
            tiedPlayers[identifier] = nil
        end
        saveTiedData()
    end
end

-- Server Event: Kiểm tra trạng thái bị trói khi người chơi spawn vào game
RegisterNetEvent('gin_troitay:server:checkTiedOnSpawn', function()
    local src = source
    local identifier = getPlayerIdentifier(src)
    if not identifier then return end

    local data = tiedPlayers[identifier]
    if data and data.isTied then
        Player(src).state:set('isTied', true, true)
        Player(src).state:set('ropeType', data.ropeType, true)

        local targetPed = GetPlayerPed(src)
        if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
            Entity(targetPed).state:set('isTied', true, true)
            Entity(targetPed).state:set('ropeType', data.ropeType, true)
        end

        -- Đồng bộ lại còng tay và hạn chế cho client
        TriggerClientEvent('gin_troitay:client:syncTiedState', src, true, data.ropeType)
    end
end)

local activeDuels = {}
local playerDuelSession = {}

-- Hàm kết thúc phiên duel và chốt kết quả thắng thua
local function finishDuel(sessionId, winner)
    local duel = activeDuels[sessionId]
    if not duel or not duel.active then return end

    duel.active = false
    activeDuels[sessionId] = nil
    playerDuelSession[duel.tyer] = nil
    playerDuelSession[duel.target] = nil

    if winner == 'tyer' then
        -- Người trói thắng -> Trói mục tiêu
        setPlayerTiedState(duel.target, true, duel.ropeType)
        TriggerClientEvent('gin_troitay:client:syncTiedState', duel.target, true, duel.ropeType)

        -- Trừ dây trói nếu có tỷ lệ
        if Config.RopeLoseChance and Config.RopeLoseChance > 0 then
            local roll = math.random(1, 100)
            if roll <= Config.RopeLoseChance then
                exports.ox_inventory:RemoveItem(duel.tyer, duel.ropeType, 1)
            end
        end

        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.tyer, 'win', 'Bạn đã áp đảo đối thủ và trói tay thành công!')
        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.target, 'lose', 'Bạn đã bị áp đảo và bị trói tay!')
        TriggerClientEvent('ox_lib:notify', duel.tyer, { type = 'success', description = Config.Locales.TyingSuccess })
    elseif winner == 'target_escaped' then
        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.tyer, 'lose', 'Trói thất bại! Nạn nhân đã chạy thoát quá xa.')
        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.target, 'win', 'Bạn đã di chuyển chạy thoát khỏi người trói!')
        TriggerClientEvent('ox_lib:notify', duel.tyer, { type = 'error', description = Config.Locales.TooFar })
    else
        -- Nạn nhân thắng -> Thoát nạn, không bị trói
        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.tyer, 'lose', 'Trói thất bại! Nạn nhân đã giữ vạch thành công.')
        TriggerClientEvent('gin_troitay:client:finishDuelMinigame', duel.target, 'win', 'Bạn đã giữ vạch thành công và thoát nạn!')
        TriggerClientEvent('ox_lib:notify', duel.tyer, { type = 'error', description = Config.Locales.TyingFailed })

        -- Khi người trói thua minigame: Nạn nhân quay lại tát 1 cái, làm người trói ngã và mất máu
        if Config.SlapOnLose then
            TriggerClientEvent('gin_troitay:client:slapTyer', duel.target, duel.tyer)
            TriggerClientEvent('gin_troitay:client:getSlappedByTarget', duel.tyer, duel.target)
        end
    end
end

local ESX, QBCore = nil, nil

CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        if exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        else
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

-- Hàm kiểm tra người chơi thuộc ban ngành có bị cấm trói hay không (chỉ cấm khi đang On Duty)
local function isJobWhitelisted(targetServerId)
    if not Config.WhitelistedJobs then return false end

    local jobName = nil
    local onDuty = nil

    -- 1. Kiểm tra ESX
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(targetServerId)
        if xPlayer and xPlayer.job then
            jobName = xPlayer.job.name
            if xPlayer.job.onduty ~= nil then
                onDuty = xPlayer.job.onduty
            elseif xPlayer.job.duty ~= nil then
                onDuty = xPlayer.job.duty
            end
        end
    end

    -- 2. Kiểm tra QBCore
    if not jobName and QBCore then
        local qPlayer = QBCore.Functions.GetPlayer(targetServerId)
        if qPlayer and qPlayer.PlayerData and qPlayer.PlayerData.job then
            jobName = qPlayer.PlayerData.job.name
            if qPlayer.PlayerData.job.onduty ~= nil then
                onDuty = qPlayer.PlayerData.job.onduty
            elseif qPlayer.PlayerData.job.duty ~= nil then
                onDuty = qPlayer.PlayerData.job.duty
            end
        end
    end

    -- 3. Fallback: Kiểm tra StateBag của Player
    local playerState = Player(targetServerId).state
    if not jobName and playerState then
        if playerState.job then
            if type(playerState.job) == 'table' then
                jobName = playerState.job.name
                if onDuty == nil then
                    if playerState.job.onduty ~= nil then
                        onDuty = playerState.job.onduty
                    elseif playerState.job.duty ~= nil then
                        onDuty = playerState.job.duty
                    end
                end
            elseif type(playerState.job) == 'string' then
                jobName = playerState.job
            end
        end
    end

    -- Kiểm tra thêm StateBag onDuty nếu chưa lấy được từ job object
    if onDuty == nil and playerState then
        if playerState.onDuty ~= nil then
            onDuty = playerState.onDuty
        elseif playerState.duty ~= nil then
            onDuty = playerState.duty
        elseif playerState.onduty ~= nil then
            onDuty = playerState.onduty
        end
    end

    -- 4. Fallback bổ sung: Thử gọi export nếu framework chưa gán
    if not jobName then
        if GetResourceState('es_extended') == 'started' then
            local status, result = pcall(function() return exports['es_extended']:getSharedObject().GetPlayerFromId(targetServerId) end)
            if status and result and result.job then
                jobName = result.job.name
                if onDuty == nil then
                    if result.job.onduty ~= nil then onDuty = result.job.onduty
                    elseif result.job.duty ~= nil then onDuty = result.job.duty end
                end
            end
        elseif GetResourceState('qb-core') == 'started' then
            local status, result = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayer(targetServerId) end)
            if status and result and result.PlayerData and result.PlayerData.job then
                jobName = result.PlayerData.job.name
                if onDuty == nil then
                    if result.PlayerData.job.onduty ~= nil then onDuty = result.PlayerData.job.onduty
                    elseif result.PlayerData.job.duty ~= nil then onDuty = result.PlayerData.job.duty end
                end
            end
        end
    end

    if jobName and Config.WhitelistedJobs[jobName] then
        -- Nếu người ban ngành đang offduty (onDuty == false) -> Cho phép trói (không bị cấm)
        if onDuty == false then
            return false
        end
        -- Đang onduty (onDuty == true hoặc mặc định) -> Cấm trói
        return true
    end

    return false
end

-- Server Event: Yêu cầu bắt đầu Minigame Đối Kháng Trói Tay giữa 2 người chơi
RegisterNetEvent('gin_troitay:server:startDuelMinigame', function(targetServerId, ropeType)
    local src = source

    -- Kiểm tra mục tiêu hợp lệ
    local targetPed = GetPlayerPed(targetServerId)
    if not targetPed or targetPed == 0 then return end

    -- Kiểm tra người chơi thuộc ban ngành cấm trói
    if isJobWhitelisted(targetServerId) then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.CannotTieJob or 'Không thể trói người thuộc ban ngành này!'
        })
        return
    end

    -- Kiểm tra khoảng cách
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(srcCoords - targetCoords) > 4.0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.TooFar
        })
        return
    end

    -- Kiểm tra mục tiêu đã bị trói chưa
    if Player(targetServerId).state.isTied then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.TargetAlreadyTied
        })
        return
    end

    -- Kiểm tra người trói có dây không
    local ropeCount = exports.ox_inventory:Search(src, 'count', ropeType) or 0
    if ropeCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.NoRope
        })
        return
    end

    -- Kiểm tra 1 trong 2 người chơi có đang trong phiên duel khác không
    if playerDuelSession[src] or playerDuelSession[targetServerId] then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = 'Đang có một phiên đối kháng diễn ra!'
        })
        return
    end

    -- Nếu Config.DebugDisableMinigame = true thì bỏ qua minigame và trói luôn
    if Config.DebugDisableMinigame then
        setPlayerTiedState(targetServerId, true, ropeType)
        TriggerClientEvent('gin_troitay:client:syncTiedState', targetServerId, true, ropeType)
        if Config.RopeLoseChance and Config.RopeLoseChance > 0 then
            local roll = math.random(1, 100)
            if roll <= Config.RopeLoseChance then
                exports.ox_inventory:RemoveItem(src, ropeType, 1)
            end
        end
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = Config.Locales.TyingSuccess
        })
        return
    end

    -- Khởi tạo phiên Duel mới
    local sessionId = string.format("duel_%d_%d_%d", src, targetServerId, os.time())
    local initialProgress = (Config.DuelMinigame and Config.DuelMinigame.InitialProgress) or 0
    local duration = (Config.DuelMinigame and Config.DuelMinigame.Duration) or 10000

    activeDuels[sessionId] = {
        id = sessionId,
        tyer = src,
        target = targetServerId,
        progress = initialProgress,
        ropeType = ropeType,
        active = true
    }
    playerDuelSession[src] = sessionId
    playerDuelSession[targetServerId] = sessionId

    -- Bật Giao diện Minigame NUI đồng thời trên máy của 2 người chơi
    TriggerClientEvent('gin_troitay:client:openDuelMinigame', src, 'tyer', initialProgress, duration, targetServerId)
    TriggerClientEvent('gin_troitay:client:openDuelMinigame', targetServerId, 'target', initialProgress, duration, src)

    -- Hạn giờ tự động xử lý khi hết giờ
    SetTimeout(duration, function()
        if activeDuels[sessionId] and activeDuels[sessionId].active then
            local p = activeDuels[sessionId].progress
            local winTarget = (Config.DuelMinigame and Config.DuelMinigame.TyerWinTarget) or 60
            if p >= winTarget then
                finishDuel(sessionId, 'tyer')
            else
                finishDuel(sessionId, 'target')
            end
        end
    end)
end)

-- Server Event: Hủy phiên minigame khi 2 người di chuyển quá xa nhau
RegisterNetEvent('gin_troitay:server:cancelDuelTooFar', function()
    local src = source
    local sessionId = playerDuelSession[src]
    if not sessionId then return end

    local duel = activeDuels[sessionId]
    if not duel or not duel.active then return end

    finishDuel(sessionId, 'target_escaped')
end)

-- Server Event: Nhận tín hiệu khi người chơi spam phím E
RegisterNetEvent('gin_troitay:server:pressDuelE', function()
    local src = source
    local sessionId = playerDuelSession[src]
    if not sessionId then return end

    local duel = activeDuels[sessionId]
    if not duel or not duel.active then return end

    local pushPower = (Config.DuelMinigame and Config.DuelMinigame.PushPower) or 4

    if src == duel.tyer then
        duel.progress = math.min(100, duel.progress + pushPower)
    elseif src == duel.target then
        duel.progress = math.max(0, duel.progress - pushPower)
    end

    -- Đồng bộ tiến trình % mới xuống cả 2 máy người chơi ngay lập tức
    TriggerClientEvent('gin_troitay:client:updateDuelProgress', duel.tyer, duel.progress)
    TriggerClientEvent('gin_troitay:client:updateDuelProgress', duel.target, duel.progress)
end)

-- Tự động hủy phiên duel nếu có người rớt mạng / ngắt kết nối
AddEventHandler('playerDropped', function()
    local src = source
    local sessionId = playerDuelSession[src]
    if sessionId and activeDuels[sessionId] and activeDuels[sessionId].active then
        local duel = activeDuels[sessionId]
        local winner = (src == duel.tyer) and 'target' or 'tyer'
        finishDuel(sessionId, winner)
    end
end)


-- Server Event: Nạn nhân tự cởi trói thành công (sau khi vượt qua minigame)
RegisterNetEvent('gin_troitay:server:selfUntieSuccess', function()
    local src = source
    if not Player(src).state.isTied then return end

    -- Xử lý tỷ lệ mất dao cắt theo Config.KnifeLoseChance khi tự cởi trói
    if Config.KnifeLoseChance and Config.KnifeLoseChance > 0 then
        local knifeCount = exports.ox_inventory:Search(src, 'count', Config.Items.DaoCat) or 0
        if knifeCount > 0 then
            local roll = math.random(1, 100)
            if roll <= Config.KnifeLoseChance then
                exports.ox_inventory:RemoveItem(src, Config.Items.DaoCat, 1)
            end
        end
    end

    -- Reset trạng thái
    setPlayerTiedState(src, false, nil)

    TriggerClientEvent('gin_troitay:client:syncTiedState', src, false, nil)
end)

-- Server Event: Người chơi khác cắt dây trói giải cứu (Dùng dao_cat)
RegisterNetEvent('gin_troitay:server:untieOther', function(targetServerId)
    local src = source

    local targetPed = GetPlayerPed(targetServerId)
    if not targetPed or targetPed == 0 then return end

    -- Kiểm tra khoảng cách
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)
    local targetCoords = GetEntityCoords(targetPed)
    if #(srcCoords - targetCoords) > 4.0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.TooFar
        })
        return
    end

    -- Kiểm tra mục tiêu có bị trói không
    local isTiedState = Player(targetServerId).state.isTied or Entity(targetPed).state.isTied
    if not isTiedState then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.TargetNotTied
        })
        return
    end

    -- Kiểm tra người cắt có dao_cat trong ox_inventory không
    local knifeCount = exports.ox_inventory:Search(src, 'count', Config.Items.DaoCat) or 0
    if knifeCount < 1 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Locales.NoKnife
        })
        return
    end

    -- Xử lý tỷ lệ mất dao cắt theo Config.KnifeLoseChance khi cắt dây giải cứu người khác
    if Config.KnifeLoseChance and Config.KnifeLoseChance > 0 then
        local roll = math.random(1, 100)
        if roll <= Config.KnifeLoseChance then
            exports.ox_inventory:RemoveItem(src, Config.Items.DaoCat, 1)
        end
    end

    -- Giải trói thành công
    setPlayerTiedState(targetServerId, false, nil)

    TriggerClientEvent('gin_troitay:client:syncTiedState', targetServerId, false, nil)
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = Config.Locales.OtherUntieSuccess
    })
end)
