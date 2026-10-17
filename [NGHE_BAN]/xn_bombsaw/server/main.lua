local Bombing = {}

function CheckPlayer(citizenid)
    for k, v in pairs(Bombing) do 
        if v['status'] then 
            if v['partner'] == citizenid or k == citizenid then 
                return true 
            end 
        end
    end 
    return false 
end 

exports['monitors']:RegisterProtectedEvent("xn-bombsaw:server:GiveShit", function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    -- Nhận ngẫu nhiên 1 phần thưởng cố định từ config
    local rewardText = ''
    if Config.BombRewards and #Config.BombRewards > 0 then
        local randomIndex = math.random(1, #Config.BombRewards)
        local reward = Config.BombRewards[randomIndex]
        exports.ox_inventory:AddItem(src, reward.item, reward.amount)
        rewardText = reward.amount .. 'x ' .. reward.item
    end
    
    -- Kiểm tra phần thưởng bonus (có tỷ lệ)
    if Config.BonusRewards then
        for _, bonus in ipairs(Config.BonusRewards) do
            local chance = math.random(1, 100)
            if chance <= bonus.chance then
                exports.ox_inventory:AddItem(src, bonus.item, bonus.amount)
                rewardText = rewardText .. ' và ' .. bonus.amount .. 'x ' .. bonus.item .. ' (Bonus!)'
            end
        end
    end

    if Config.Event and Config.Event.enabled then
        if math.random(1, 100) <= Config.Event.chance then
            local roll = math.random(1, 100)
            local cumulativeChance = 0
            for _, reward in ipairs(Config.Event.rewards) do
                cumulativeChance = cumulativeChance + reward.chance
                if roll <= cumulativeChance then
                    exports.ox_inventory:AddItem(src, reward.item, 1)
                    break
                end
            end
        end
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Thành công', 
        description = 'Bạn nhận được ' .. rewardText, 
        type = 'success'
    })
end)

exports.qbx_core:CreateUseableItem('traimin', function(source, item)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    TriggerClientEvent("xn-bombsaw:client:UsingOldBomb", source)
end)

-- Gửi yêu cầu cưa bom
RegisterNetEvent("xn-bombsaw:server:SendBombRequest", function(targetId)
    local requester = exports.qbx_core:GetPlayer(source)
    if not requester then return end
    
    local requesterName = requester.PlayerData.charinfo.firstname .. ' ' .. requester.PlayerData.charinfo.lastname
    TriggerClientEvent('xn-bombsaw:client:ReceiveBombRequest', targetId, requesterName, source)
end)

-- Chấp nhận yêu cầu cưa bom
RegisterNetEvent("xn-bombsaw:server:AcceptBombRequest", function(requesterId)
    local player = exports.qbx_core:GetPlayer(requesterId)
    local partner = exports.qbx_core:GetPlayer(source)
    
    if not player or not partner then return end
    
    -- Kiểm tra routing bucket - nếu không phải thế giới thật thì không cho cưa
    local requesterBucket = GetPlayerRoutingBucket(requesterId)
    local partnerBucket = GetPlayerRoutingBucket(source)
    
    if requesterBucket ~= 0 or partnerBucket ~= 0 then
        exports.ox_inventory:RemoveItem(requesterId, 'traimin', 1)
        TriggerClientEvent('ox_lib:notify', requesterId, {title = 'Cảnh báo', description = 'Không thể cưa bom trong khu vực này!', type = 'error'})
        TriggerClientEvent('ox_lib:notify', source, {title = 'Cảnh báo', description = 'Không thể cưa bom trong khu vực này!', type = 'error'})
        return
    end
    
    if CheckPlayer(partner.PlayerData.citizenid) or CheckPlayer(player.PlayerData.citizenid) then 
        TriggerClientEvent('ox_lib:notify', requesterId, {title = 'Thông báo', description = 'Người chơi đang bận', type = 'error'})
        return 
    end 

    Bombing[player.PlayerData.citizenid] = {
        ["ownerSuccess"] = false,
        ["partnerSuccess"] = false,
        ["fail"] = 0,
        ["partner"] = partner.PlayerData.citizenid,
        ["partnerId"] = source,
        ["ownerId"] = requesterId,
        ['status'] = true
    }
    
    if exports.ox_inventory:RemoveItem(requesterId, 'traimin', 1) then 
        local requesterPed = GetPlayerPed(requesterId)
        local coords = GetEntityCoords(requesterPed)
        local heading = GetEntityHeading(requesterPed)
        
        TriggerClientEvent("xn-bombsaw:client:startP", source, coords, heading)
        TriggerClientEvent("xn-bombsaw:client:start", requesterId, coords, heading)
    else
        Bombing[player.PlayerData.citizenid] = nil
        TriggerClientEvent('ox_lib:notify', requesterId, {title = 'Thông báo', description = 'Không có quả bom', type = 'error'})
    end 
end)

local function GetPlayerSession(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil, nil end
    local citizenid = player.PlayerData.citizenid

    for ownerCitizenId, session in pairs(Bombing) do
        if session.status then
            if ownerCitizenId == citizenid or session.partner == citizenid then
                return ownerCitizenId, session
            end
        end
    end
    return nil, nil
end

RegisterNetEvent("xn-bombsaw:server:success", function(role)
    local src = source
    local ownerCitizenId, session = GetPlayerSession(src)
    if not session then return end

    if role == "leader" then
        session.ownerSuccess = true
    elseif role == "partner" then
        session.partnerSuccess = true
    end

    -- Nếu cả hai đều thành công
    if session.ownerSuccess and session.partnerSuccess then
        session.status = false
        
        -- Tăng stress cho cả 2 người khi cưa bom thành công
        local ownerPlayer = exports.qbx_core:GetPlayer(session.ownerId)
        if ownerPlayer then
            local currentStress = ownerPlayer.PlayerData.metadata['stress'] or 0
            local newStress = math.min(100.0, currentStress + 30.0)
            ownerPlayer.Functions.SetMetaData("stress", newStress)
        end

        local partnerPlayer = exports.qbx_core:GetPlayer(session.partnerId)
        if partnerPlayer then
            local currentStress = partnerPlayer.PlayerData.metadata['stress'] or 0
            local newStress = math.min(100.0, currentStress + 30.0)
            partnerPlayer.Functions.SetMetaData("stress", newStress)
        end

        TriggerClientEvent("xn-bombsaw:client:SawingBombFinish", session.ownerId, true)
        TriggerClientEvent("xn-bombsaw:client:SawingBombFinish", session.partnerId, true)
        
        Bombing[ownerCitizenId] = nil
    end
end)

RegisterNetEvent("xn-bombsaw:server:fail", function()
    local src = source
    local ownerCitizenId, session = GetPlayerSession(src)
    if not session then return end

    session.fail = session.fail + 1

    if session.fail >= Config.BombSawingFail then
        session.status = false

        -- Kích hoạt hiệu ứng nổ và kết thúc thất bại cho cả hai
        TriggerClientEvent("xn-bombsaw:client:fail", session.ownerId)
        TriggerClientEvent("xn-bombsaw:client:fail", session.partnerId)
        
        TriggerClientEvent("xn-bombsaw:client:SawingBombFinish", session.ownerId, false)
        TriggerClientEvent("xn-bombsaw:client:SawingBombFinish", session.partnerId, false)

        Bombing[ownerCitizenId] = nil
    else
        -- Báo cho người vừa bấm trượt
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cảnh báo',
            description = string.format('Bạn cưa trượt! (%d/%d lần)', session.fail, Config.BombSawingFail),
            type = 'warning'
        })
        -- Báo cho đồng đội của họ
        local otherPlayerId = (src == session.ownerId) and session.partnerId or session.ownerId
        TriggerClientEvent('ox_lib:notify', otherPlayerId, {
            title = 'Thông báo',
            description = string.format('Đồng đội đã cưa trượt! (%d/%d lần)', session.fail, Config.BombSawingFail),
            type = 'warning'
        })
        
        -- Yêu cầu client tiếp tục cưa tiếp
        TriggerClientEvent("xn-bombsaw:client:continueRepeat", src)
    end
end)

-- Từ chối yêu cầu cưa bom
RegisterNetEvent("xn-bombsaw:server:DenyBombRequest", function(requesterId)
    TriggerClientEvent('ox_lib:notify', requesterId, {title = 'Thông báo', description = 'Người chơi đã từ chối yêu cầu của bạn', type = 'error'})
end)

-- QBCore.Commands.Add("hoisinhevent", "Hồi sinh event bằng bông hoa", {}, false, function(source, args)
-- 	local src = source
-- 	local Player = QBCore.Functions.GetPlayer(src)
--     local my_item = Player.Functions.GetItemByName("hoaxanh")
-- 	if my_item ~= nil then
--         Player.Functions.RemoveItem("hoaxanh", 1)
-- 		TriggerClientEvent("hospital:client:Revive", src)
-- 	else
-- 		TriggerClientEvent('QBCore:Notify', src, "Bạn thiếu vật phẩm yêu cầu", "error")
-- 	end
-- end)