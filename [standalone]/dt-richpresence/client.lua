local isStarted = false

local function StartDiscord()
    if isStarted then return end
    isStarted = true

    -- Cấu hình tĩnh chỉ cần thiết lập 1 lần duy nhất khi khởi động
    if Config.DiscordAppId then
        SetDiscordAppId(Config.DiscordAppId)
    end

    if Config.LargeAssetName then
        SetDiscordRichPresenceAsset(Config.LargeAssetName)
    end

    if Config.LargeAssetText then
        SetDiscordRichPresenceAssetText(Config.LargeAssetText)
    end

    if Config.SmallAssetEnabled and Config.SmallAsset then
        SetDiscordRichPresenceAssetSmall(Config.SmallAsset)
        if Config.SmallAssetText then
            SetDiscordRichPresenceAssetSmallText(Config.SmallAssetText)
        end
    end

    if Config.Button1Label and Config.Button1Url and Config.Button1Url ~= '' then
        SetDiscordRichPresenceAction(0, Config.Button1Label, Config.Button1Url)
    end

    -- Luồng cập nhật trạng thái số lượng người chơi
    CreateThread(function()
        local multiplier = Config.PlayerMultiplier or 1.0
        local interval = Config.UpdateInterval or 30000

        while true do
            local currentPlayers = GlobalState.totalPlayers or #GetActivePlayers()
            local sl = math.ceil(currentPlayers * multiplier)
            SetRichPresence(string.format('%d cư dân đang nhập vai\n', sl))
            Wait(interval)
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', StartDiscord)
RegisterNetEvent('qbx_core:client:playerLoaded', StartDiscord)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StartDiscord()
end)