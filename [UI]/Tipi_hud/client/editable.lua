local Framework, frameworkName = getFramework()
SpeedMultiplier = 3.6

-- ═══════════════════════════════════════════════════════════════
-- QBX / FRAMEWORK LOCAL CACHE (Zero polling overhead, 100% Realtime)
-- ═══════════════════════════════════════════════════════════════

PlayerCache = {
    loaded = false,
    citizenid = nil,
    job = {},
    gang = {},
    money = { cash = 0, bank = 0 },
    metadata = {
        hunger = 0,
        thirst = 0,
        sleepiness = 0,
        poop = 0,
        pee = 0,
        stress = 0
    }
}

function ClearPlayerCache()
    PlayerCache.loaded = false
    PlayerCache.citizenid = nil
    PlayerCache.job = {}
    PlayerCache.gang = {}
    PlayerCache.money = { cash = 0, bank = 0 }
    PlayerCache.metadata = {
        hunger = 0,
        thirst = 0,
        sleepiness = 0,
        poop = 0,
        pee = 0,
        stress = 0
    }
end

function RefreshPlayerCache()
    local data = nil
    if GetResourceState('qbx_core') == 'started' then
        local success, qbxData = pcall(function() return exports.qbx_core:GetPlayerData() end)
        if success and qbxData then data = qbxData end
    end
    if not data and Framework and Framework.Functions and Framework.Functions.GetPlayerData then
        data = Framework.Functions.GetPlayerData()
    elseif not data and Framework and Framework.GetPlayerData then
        data = Framework.GetPlayerData()
    end

    if not data then return end

    PlayerCache.citizenid = data.citizenid
    PlayerCache.job = data.job or {}
    PlayerCache.gang = data.gang or {}
    if data.money then
        PlayerCache.money.cash = data.money.cash or 0
        PlayerCache.money.bank = data.money.bank or 0
    end
    if data.metadata then
        for k, _ in pairs(PlayerCache.metadata) do
            if data.metadata[k] ~= nil then
                PlayerCache.metadata[k] = tonumber(data.metadata[k]) or 0
            end
        end
        if data.metadata.stress ~= nil then
            stress = math.max(0, math.min(100, tonumber(data.metadata.stress) or 0))
        end
    end

    -- Đọc thêm từ LocalPlayer.state nếu có (QBX statebag)
    if LocalPlayer and LocalPlayer.state then
        for k, _ in pairs(PlayerCache.metadata) do
            if LocalPlayer.state[k] ~= nil then
                PlayerCache.metadata[k] = tonumber(LocalPlayer.state[k]) or 0
                if k == 'stress' then
                    stress = math.max(0, math.min(100, PlayerCache.metadata.stress))
                end
            end
        end
    end

    PlayerCache.loaded = true
end

function getFuel(vehicle)
    return exports[Config.FuelScript]:GetFuel(vehicle)
end

function getHunger()
    return PlayerCache.metadata.hunger or 0
end

function getThirst()
    return PlayerCache.metadata.thirst or 0
end

function getSleepiness()
    return PlayerCache.metadata.sleepiness or 0
end

function getPoop()
    return PlayerCache.metadata.poop or 0
end

function getPee()
    return PlayerCache.metadata.pee or 0
end

function getStress()
    return PlayerCache.metadata.stress or stress or 0
end

-- ─── Realtime StateBag Handlers (QBX / Qbox 0ms latency) ───────
CreateThread(function()
    local myServerId = ('player:%s'):format(GetPlayerServerId(PlayerId()))
    local metaKeys = { 'hunger', 'thirst', 'stress', 'sleepiness', 'poop', 'pee' }

    for _, key in ipairs(metaKeys) do
        AddStateBagChangeHandler(key, myServerId, function(_, _, value)
            if value == nil then return end
            local num = tonumber(value) or 0
            PlayerCache.metadata[key] = num
            if key == 'stress' then
                stress = math.max(0, math.min(100, num))
                SendNUIMessage({ action = "setStress", stress = stress })
            end
        end)
    end
end)

-- ─── ESX Status Listener ─────────────────────────────────────────
RegisterNetEvent('esx_status:onTick')
AddEventHandler('esx_status:onTick', function(data)
    for k, v in pairs(data) do
        if data[k].name == "hunger" then
            PlayerCache.metadata.hunger = data[k].percent
        elseif data[k].name == "thirst" then
            PlayerCache.metadata.thirst = data[k].percent
        elseif data[k].name == "stress" and frameworkName == "esx" then
            PlayerCache.metadata.stress = data[k].percent
            stress = data[k].percent
            SendNUIMessage({ action = "setStress", stress = stress })
        end
    end
end)

-- ─── QBCore / QBX SetPlayerData Listener ─────────────────────────
local function applyPlayerData(val)
    if not val then return end
    if val.citizenid then PlayerCache.citizenid = val.citizenid end
    if val.job then
        PlayerCache.job = val.job
        SendNUIMessage({
            action = "updateJob",
            job = (val.job.label or "") .. " " .. (val.job.grade and val.job.grade.name or "")
        })
    end
    if val.gang then PlayerCache.gang = val.gang end
    if val.money then
        if val.money.cash ~= nil then PlayerCache.money.cash = val.money.cash end
        if val.money.bank ~= nil then PlayerCache.money.bank = val.money.bank end
        SendNUIMessage({
            action = "updateMoney",
            cash = PlayerCache.money.cash,
            bank = PlayerCache.money.bank
        })
    end
    if val.metadata then
        for k, _ in pairs(PlayerCache.metadata) do
            if val.metadata[k] ~= nil then
                PlayerCache.metadata[k] = tonumber(val.metadata[k]) or 0
            end
        end
        if val.metadata.stress ~= nil then
            stress = math.max(0, math.min(100, tonumber(val.metadata.stress) or 0))
            SendNUIMessage({ action = "setStress", stress = stress })
        end
    end
end

RegisterNetEvent('QBCore:Player:SetPlayerData', applyPlayerData)

RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    if key == 'citizenid' or key == 'job' or key == 'gang' or key == 'money' or key == 'metadata' then
        applyPlayerData({ [key] = value })
    end
end)

RegisterNetEvent('qbx_core:client:metadataUpdated', function(key, value)
    if value ~= nil then applyPlayerData({ metadata = { [key] = value } }) end
end)

RegisterNetEvent('qbx_core:client:moneyUpdated', function(moneyType, balance)
    if moneyType == 'cash' or moneyType == 'bank' then
        applyPlayerData({ money = { [moneyType] = balance } })
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerCache.job = job or {}
    if job and job.label then
        SendNUIMessage({
            action = "updateJob",
            job = job.label .. " " .. (job.grade and job.grade.name or "")
        })
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerCache.job then
        PlayerCache.job.onduty = (duty == true or duty == 1)
    end
end)

RegisterNetEvent('qbx_core:client:onSetDuty', function(duty)
    if PlayerCache.job then
        PlayerCache.job.onduty = (duty == true or duty == 1)
    end
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    PlayerCache.gang = gang or {}
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    ClearPlayerCache()
    loaded = false
end)

RegisterNetEvent('SaltyChat_VoiceRangeChanged', function(voiceRange, index, availableVoiceRanges)
	index = index + 1
    
	if index >= 4 then
		index = 3
	end

	SendNUIMessage({
		action = "setMicrophone",
		value = index
	})
end)

RegisterNetEvent('pma-voice:setTalkingMode', function(value)
	SendNUIMessage({
		action = "setMicrophone",
		value = value
	})
end)

RegisterNetEvent("mumble:SetVoiceData", function(player, key, value)
	if GetPlayerServerId(NetworkGetEntityOwner(PlayerPedId())) == player and key == 'mode' then
		SendNUIMessage({
			action = "setMicrophone",
			value = value
		})
	end
end)

function notify(message)
    if frameworkName == "esx" then
        Framework.ShowNotification(getMessage(message))
    else
        Framework.Functions.Notify(getMessage(message))
    end
end

function getMessage(message)
    return Config.locales[Config.Language][message] or print("Message Not Found: "..message)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    RefreshPlayerCache()
    updateInformation()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    RefreshPlayerCache()
    updateInformation()
end)

RegisterCommand('refreshHud', function()
    updateInformation()
end)


if Config.SettingsKeyBind == true then
    RegisterKeyMapping(Config.SettingsCommand, 'Open Hud Settings', 'keyboard', Config.SettingsMenu)
end
