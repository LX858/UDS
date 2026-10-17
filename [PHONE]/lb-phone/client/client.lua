local DisableControlActionFunc = DisableControlAction
local IsNuiFocusedFunc = IsNuiFocused
local DisablePlayerFiringFunc = DisablePlayerFiring

phoneData = nil
currentPhone = nil
settings = nil
phoneOpen = false
SavedLocations = {}
PhoneOnScreen = false

local cachedPhoneData = nil
local playerDataLoaded = nil
local isFetchingPhone = nil
local configSentToUI = nil

function WaitForConfig()
    if configSentToUI then
        return
    end
    debugprint("waiting for config to be received")
    while not configSentToUI do
        Wait(0)
    end
    debugprint("config received")
end

function FetchPhone()
    debugprint("FetchPhone triggered")
    if isFetchingPhone then
        debugprint("already fetching phone")
        return
    elseif not configSentToUI then
        debugprint("config has not been sent to UI yet")
        return
    end
    
    isFetchingPhone = true
    
    while not FrameworkLoaded do
        debugprint("waiting for framework to load")
        Wait(500)
    end
    
    debugprint("triggering phone:playerLoaded")
    
    local phoneNumber = nil
    if not playerDataLoaded or not currentPhone then
        phoneNumber = AwaitCallback("playerLoaded")
        cachedPhoneData = phoneNumber
        playerDataLoaded = true
    else
        phoneNumber = cachedPhoneData
    end
    
    debugprint("got number", phoneNumber)
    
    if not phoneNumber then
        debugprint("no number, checking if player has item")
        if HasPhoneItem() then
            debugprint("player has item; triggering phone:generatePhoneNumber")
            phoneNumber = AwaitCallback("generatePhoneNumber")
            debugprint("got number", phoneNumber)
        else
            debugprint("player does not have item")
        end
    end
    
    if not phoneNumber then
        isFetchingPhone = false
        if currentPhone then
            debugprint("no number. using SetPhone")
            SetPhone()
        end
        debugprint("no number, returning")
        return
    end
    
    local defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))
    local latestVersion = AwaitCallback("getLatestVersion")
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
    
    if not latestVersion then
        latestVersion = currentVersion
    end
    
    defaultSettings.locale = Config.DefaultLocale
    defaultSettings.version = currentVersion
    defaultSettings.latestVersion = latestVersion
    
    local isSetup = false
    
    debugprint("fetching phone data")
    local phoneDataFromServer = AwaitCallback("getPhone", phoneNumber)
    debugprint("got phone data", json.encode(phoneDataFromServer))
    
    if phoneDataFromServer then
        if phoneDataFromServer.settings then
            defaultSettings = phoneDataFromServer.settings
        end
        
        if phoneDataFromServer.name then
            defaultSettings.name = phoneDataFromServer.name
        else
            defaultSettings.name = "Not set"
        end
        
        defaultSettings.version = currentVersion
        defaultSettings.latestVersion = latestVersion
        
        SavedLocations = AwaitCallback("maps:getSavedLocations")
        
        isSetup = phoneDataFromServer.is_setup or false
        if not phoneDataFromServer.is_setup then
            isSetup = false
        end
        
        currentPhone = phoneNumber
        
        phoneData = {
            isSetup = isSetup,
            phoneNumber = phoneNumber,
            settings = defaultSettings,
            battery = (Config.Battery.Enabled and phoneDataFromServer.battery) or 100
        }
        
        WaitForConfig()
        
        debugprint("triggering phone:setPhoneData")
        SendReactMessage("setPhoneData", phoneData)
        TriggerEvent("lb-phone:numberChanged", phoneNumber)
        Wait(250)
    end
    
    settings = defaultSettings
    isFetchingPhone = false
end

function RefreshPhone(skipFetch)
    debugprint("RefreshPhone triggered")
    
    if isFetchingPhone then
        debugprint("phone is being fetched, waiting before refreshing")
        while isFetchingPhone do
            Wait(0)
        end
    end
    
    if Config.DynamicWebRTC and Config.DynamicWebRTC.Enabled then
        local webRTCCredentials = AwaitCallback("getWebRTCCredentials")
        
        if Config.DynamicWebRTC.RemoveStun and webRTCCredentials then
            for i = #webRTCCredentials, 1, -1 do
                if not webRTCCredentials[i].credential then
                    table.remove(webRTCCredentials, i)
                end
            end
        end
        
        if webRTCCredentials then
            Config.RTCConfig = Config.RTCConfig or {}
            Config.RTCConfig.iceServers = webRTCCredentials
        end
    end
    
    configSentToUI = false
    
    local config = json.decode(GetConfigFile("config.json"))
    
    config.valet = {
        enabled = Config.Valet.Enabled or false,
        price = Config.Valet.Price or 0,
        vehicleTypes = Config.Valet.VehicleTypes or {"car"}
    }
    
    config.locations = Config.Locations
    config.AllowExternal = Config.AllowExternal
    config.ExternalBlacklistedDomains = Config.ExternalBlacklistedDomains
    config.ExternalWhitelistedDomains = Config.ExternalWhitelistedDomains
    config.Format = Config.PhoneNumber.Format
    config.EmailDomain = Config.EmailDomain
    config.RealTime = Config.RealTime
    config.CurrencyFormat = Config.CurrencyFormat
    config.DeleteMessages = Config.DeleteMessages
    config.Battery = Config.Battery
    config.rtc = Config.RTCConfig
    config.PromoteBirdy = Config.PromoteBirdy
    config.DynamicIsland = Config.DynamicIsland
    config.SetupScreen = Config.SetupScreen
    config.MaxTransferAmount = Config.MaxTransferAmount
    config.EnableMessagePay = Config.EnableMessagePay
    config.EnableGIFs = Config.EnableGIFs
    config.GIFsFilter = Config.GIFsFilter or "low"
    config.EnableVoiceMessages = Config.EnableVoiceMessages
    config.DefaultLocale = Config.DefaultLocale
    config.DateLocale = Config.DateLocale
    config.Debug = Config.Debug
    config.TikTokTTS = Config.TrendyTTS or {{"English (US) - Female", "en_us_001"}}
    config.recordNearbyVoices = Config.Voice.RecordNearby
    config.frameColor = Config.FrameColor
    config.allowFrameColorChange = Config.AllowFrameColorChange
    config.unlockPhoneKey = (Config.KeyBinds.UnlockPhone and Config.KeyBinds.UnlockPhone.Bind) or nil
    config.DeleteMail = Config.DeleteMail
    config.ChangePassword = Config.ChangePassword
    config.DeleteAccount = Config.DeleteAccount
    config.CustomCamera = (Config.Camera and Config.Camera.Enabled) or false
    config.UsernameFilter = (Config.UsernameFilter and Config.UsernameFilter.Regex) or "[a-zA-Z0-9]+"
    config.CryptoLimit = (Config.Crypto and Config.Crypto.Limits) or {Buy = 1000000, Sell = 1000000}
    
    config.imageOptions = {
        mime = (Config.Image and Config.Image.Mime) or "image/png",
        quality = (Config.Image and Config.Image.Quality) or 1.0
    }
    
    config.videoOptions = {
        bitrate = (Config.Video and Config.Video.Bitrate) or 250,
        size = (Config.Video and Config.Video.MaxSize) or 10,
        duration = (Config.Video and Config.Video.MaxDuration) or 60,
        fps = (Config.Video and Config.Video.FrameRate) or 24
    }
    
    config.Companies = table.deep_clone(Config.Companies)
    
    if config.Companies and config.Companies.Services then
        for i = 1, #config.Companies.Services do
            if config.Companies.Services[i].onCustomIconClick then
                config.Companies.Services[i].onCustomIconClick = true
            end
        end
    end
    
    if Config.CustomApps then
        --print("[LB-Phone] Processing Custom Apps:", json.encode(Config.CustomApps))
        for appName, appData in pairs(Config.CustomApps) do
            --print("[LB-Phone] Adding custom app:", appName)
            config.apps[appName] = FormatCustomAppDataForUI(appData)
        end
    else
        --print("[LB-Phone] No Custom Apps found in Config")
    end
    
    --print("[LB-Phone] Total apps in config:", json.encode(config.apps))
    
    for appName, appData in pairs(config.apps) do
        appData.access = HasAccessToApp(appName)
        --print("[LB-Phone] App access for", appName, ":", appData.access)
    end
    
    config.defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))
    
    local function removeAppFromDefaultSettings(appToRemove)
        local apps = config.defaultSettings.apps
        for i = 1, #apps do
            for j = 1, #apps[i] do
                if apps[i][j] == appToRemove then
                    table.remove(apps[i], j)
                    break
                end
            end
        end
    end
    
    if Config.Framework == "standalone" and not Config.CustomFramework then
        config.apps.Wallet = nil
        config.apps.Home = nil
        config.apps.Garage = nil
        config.apps.Services = nil
        removeAppFromDefaultSettings("Wallet")
        removeAppFromDefaultSettings("Home")
        removeAppFromDefaultSettings("Garage")
        removeAppFromDefaultSettings("Services")
    end
    
    if not Config.HouseScript then
        config.apps.Home = nil
        debugprint("No Config.HouseScript, removed home app")
        removeAppFromDefaultSettings("Home")
    end
    
    if not (Config.Crypto and Config.Crypto.Enabled) then
        config.apps.Crypto = nil
        debugprint("Config.Crypto not enabled, removed crypto app")
        removeAppFromDefaultSettings("Crypto")
    end
    
    SendReactMessage("setConfig", config)
    
    WaitForConfig()
    
    if phoneData then
        debugprint("phoneData is defined")
        SendReactMessage("setPhoneData", phoneData)
        return
    end
    
    if skipFetch then
        return
    end
    
    FetchPhone()
end

RegisterNetEvent("lb-phone:jobUpdated", function(jobData)
    if not Config.WhitelistApps and not Config.BlacklistApps then
        return
    end
    
    debugprint("Job updated, refreshing whitelisted & blacklisted apps")
    
    for appName, appConfig in pairs(Config.WhitelistApps) do
        SendReactMessage("app:setHasAccess", {
            app = appName,
            hasAccess = HasAccessToApp(appName, jobData.job, jobData.grade)
        })
    end
    
    for appName, appConfig in pairs(Config.BlacklistApps) do
        SendReactMessage("app:setHasAccess", {
            app = appName,
            hasAccess = HasAccessToApp(appName, jobData.job, jobData.grade)
        })
    end
    
    for appName, appData in pairs(Config.CustomApps) do
        SendReactMessage("app:setHasAccess", {
            app = appName,
            hasAccess = HasAccessToApp(appName, jobData.job, jobData.grade)
        })
    end
end)

RegisterNUICallback("configReceived", function(data, cb)
    debugprint("UI has received the config (configReceived triggered)")
    configSentToUI = true
    cb("ok")
end)

RegisterNUICallback("getPhoneData", function(data, cb)
    debugprint("getPhoneData triggered")
    
    while not FrameworkLoaded do
        Wait(500)
    end
    
    Wait(1000)
    RefreshPhone()
    
    if not cb then
        return debugprint("cb is not defined in getPhoneData", data)
    end
    
    cb(true)
end)

function DisableControlsLoop()
    local playerId = PlayerId()
    
    while phoneOpen do
        Wait(0)
        DisableControlActionFunc(0, 199, true)
        DisableControlActionFunc(0, 200, true)
        DisableControlActionFunc(0, 24, true)
        DisableControlActionFunc(0, 25, true)
        DisableControlActionFunc(0, 69, true)
        DisableControlActionFunc(0, 70, true)
        DisableControlActionFunc(0, 91, true)
        DisableControlActionFunc(0, 92, true)
        DisableControlActionFunc(0, 106, true)
        DisableControlActionFunc(0, 114, true)
        DisableControlActionFunc(0, 140, true)
        DisableControlActionFunc(0, 141, true)
        DisableControlActionFunc(0, 142, true)
        DisableControlActionFunc(0, 257, true)
        DisableControlActionFunc(0, 263, true)
        DisableControlActionFunc(0, 264, true)
        DisableControlActionFunc(0, 330, true)
        DisableControlActionFunc(0, 331, true)
        DisablePlayerFiringFunc(playerId, true)
        
        if IsNuiFocusedFunc() then
            DisableControlActionFunc(0, 1, true)
            DisableControlActionFunc(0, 2, true)
            DisableControlActionFunc(0, 245, true)
            DisableControlActionFunc(0, 14, true)
            DisableControlActionFunc(0, 15, true)
            DisableControlActionFunc(0, 16, true)
            DisableControlActionFunc(0, 17, true)
            DisableControlActionFunc(0, 37, true)
            DisableControlActionFunc(0, 50, true)
            DisableControlActionFunc(0, 99, true)
            DisableControlActionFunc(0, 115, true)
            DisableControlActionFunc(0, 180, true)
            DisableControlActionFunc(0, 181, true)
            DisableControlActionFunc(0, 198, true)
            DisableControlActionFunc(0, 241, true)
            DisableControlActionFunc(0, 242, true)
            DisableControlActionFunc(0, 261, true)
            DisableControlActionFunc(0, 262, true)
            DisableControlActionFunc(0, 85, true)
        end
    end
    
    while IsDisabledControlPressed(0, 200) do
        DisableControlActionFunc(0, 200, true)
        Wait(0)
    end
    
    if cameraOpen then
        if IsWalkingCamEnabled() then
            local wasSelfieCam = IsSelfieCam()
            DisableWalkableCam()
            
            while phoneOpen do
                Wait(500)
            end
            
            if cameraOpen then
                SetPhoneAction("camera")
                EnableWalkableCam(wasSelfieCam)
            end
        end
    end
end

function ToggleOpen(open, skipAnimation)
    if nil == open then
        open = not phoneOpen
    end
    
    open = true == open
    
    debugprint("ToggleOpen triggered", tostring(open), tostring(skipAnimation))
    
    if phoneDisabled and open then
        debugprint("phone is disabled, returning")
        return
    elseif phoneOpen == open then
        debugprint("phoneOpen & open are both the same value, returning")
        return
    elseif not FrameworkLoaded then
        infoprint("warning", "Framework not loaded")
        return
    elseif open and IsPedDeadOrDying(PlayerPedId(), true) then
        debugprint("player ped is dead/dying, returning")
        return
    elseif open and CanOpenPhone and not CanOpenPhone() then
        debugprint("CanOpenPhone returned false, returning")
        return
    elseif open and IsNuiFocusedFunc() and Config.DisableOpenNUI then
        infoprint("info", "Not opening the phone as another script has NUI focus. You can disable this behavior by setting Config.DisableOpenNUI to false.")
        return
    elseif GetResourceState("lb-tablet") == "started" then
        local success, tabletOpen = pcall(function()
            return exports["lb-tablet"]:IsOpen()
        end)
        if success and tabletOpen then
            infoprint("info", "Not opening the phone as the tablet is open. You can disable this behavior by setting Config.DisableTabletOpenPhone to false.")
            return
        end
    end
    
    if not currentPhone then
        debugprint("no phone, fetching")
        FetchPhone()
        if not currentPhone then
            debugprint("still no phone after fetching, returning")
            return
        end
    end
    
    if open then
        if not HasPhoneItem(currentPhone) then
            debugprint("HasPhoneItem returned false. Phone number:", tostring(currentPhone))
            TriggerServerEvent("phone:togglePhone")
            SendReactMessage("closePhone")
            return
        end
    end
    
    if not open and IsWalkingCamEnabled() and IsSelfieCam() then
        ToggleSelfieCam(false)
    end
    
    if not open and Config.EndLiveClose then
        local liveStream = IsWatchingLive()
        EndLive()
        if liveStream then
            SendReactMessage("instagram:liveEnded", liveStream)
        end
    end
    
    phoneOpen = open
    
    if open then
        debugprint("should open phone. sending openPhone event to ui")
        SendReactMessage("openPhone")
        
        if not skipAnimation then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(Config.KeepInput)
        end
        
        if Config.KeepInput then
            CreateThread(DisableControlsLoop)
        end
        
        if ControllerThread then
            CreateThread(ControllerThread)
        end
        
        debugprint("setting animation action")
        
        if IsWalkingCamEnabled() then
            SetPhoneAction("camera")
        elseif IsInCall() then
            SetPhoneAction("call")
        else
            SetPhoneAction("default")
        end
    else
        debugprint("sending closePhone event to ui")
        PlayCloseAnim()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendReactMessage("closePhone")
    end
    
    if phoneData and phoneData.isSetup then
        TriggerServerEvent("phone:togglePhone", open, settings and settings.name)
    end
    
    TriggerEvent("lb-phone:phoneToggled", open)
end

RegisterNUICallback("toggleInput", function(inputEnabled, cb)
    cb("ok")
    
    if not Config.KeepInput then
        return
    end
    
    if (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249) then
        if inputEnabled then
            debugprint("PTT is pressed, ignoring toggle focus")
            return
        end
        
        debugprint("PTT is pressed, waiting before toggling focus")
        
        while (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249) do
            Wait(100)
        end
    end
    
    if inputEnabled then
        Wait(200)
    end
    
    SetNuiFocusKeepInput(not inputEnabled)
end)

local isWaitingForPTTRelease = false

AddEventHandler("lb-phone:keyPressed", function(action)
    if IsPauseMenuActive() then
        return
    end
    
    if action == "Open" then
        debugprint("Pressed open keybind")
        ToggleOpen(not phoneOpen)
    elseif action == "Focus" then
        if not phoneOpen or isWaitingForPTTRelease then
            return
        end
        
        if (Config.DisableFocusTalking and IsDisabledControlPressed(0, 249)) or IsDisabledControlJustReleased(0, 249) then
            debugprint("PTT is pressed, waiting before toggling focus")
            isWaitingForPTTRelease = true
            
            while IsDisabledControlPressed(0, 249) or IsDisabledControlJustReleased(0, 249) do
                Wait(0)
            end
            
            isWaitingForPTTRelease = false
        end
        
        local isFocused = IsNuiFocusedFunc()
        SetNuiFocus(not isFocused, not isFocused)
        
        if not isFocused then
            SetNuiFocusKeepInput(Config.KeepInput)
        else
            SetNuiFocusKeepInput(false)
        end
    elseif action == "StopSounds" then
        SendReactMessage("stopSounds")
    end
    
    if action == "AnswerCall" then
        SendReactMessage("usedCommand", "answer")
    elseif action == "DeclineCall" then
        SendReactMessage("usedCommand", "decline")
    end
    
    if action == "TakePhoto" then
        SendReactMessage("camera:usedCommand", "toggleTaking")
    elseif action == "ToggleFlash" then
        SendReactMessage("camera:usedCommand", "toggleFlash")
    elseif action == "LeftMode" then
        SendReactMessage("camera:usedCommand", "leftMode")
    elseif action == "RightMode" then
        SendReactMessage("camera:usedCommand", "rightMode")
    elseif action == "FlipCamera" then
        SendReactMessage("camera:usedCommand", "toggleFlip")
    end
end)

for keyName, keyConfig in pairs(Config.KeyBinds) do
    if not keyConfig.Command then
    else
        keyConfig.Command = keyConfig.Command:lower()
        
        if keyConfig.Bind then
            keyConfig.bindData = AddKeyBind({
                name = keyConfig.Command,
                description = keyConfig.Description or "no description",
                defaultKey = keyConfig.Bind,
                defaultMapper = keyConfig.Mapper,
                secondaryKey = keyConfig.SecondaryBind,
                secondaryMapper = keyConfig.SecondaryMapper,
                onPress = function()
                    TriggerEvent("lb-phone:keyPressed", keyName)
                end,
                onRelease = function(duration)
                    TriggerEvent("lb-tablet:keyReleased", keyName, duration)
                end
            })
        else
            RegisterCommand(keyConfig.Command, function()
                TriggerEvent("lb-phone:keyPressed", keyName)
                Wait(0)
                TriggerEvent("lb-phone:keyReleased", keyName, 0)
            end, false)
        end
    end
end

RegisterNUICallback("finishedSetup", function(setupData, cb)
    if phoneData then
        phoneData.isSetup = true
    end
    
    if setupData then
        local characterName = AwaitCallback("getCharacterName")
        setupData.name = L("BACKEND.MISC.X_PHONE", {
            name = characterName.firstname,
            lastname = characterName.lastname
        })
    end
    
    SendReactMessage("setName", setupData.name)
    TriggerServerEvent("phone:setName", setupData.name)
    TriggerServerEvent("phone:togglePhone", phoneOpen, (setupData and setupData.name) or nil)
    TriggerServerEvent("phone:finishedSetup", setupData)
    
    if Config.AutoBackup then
        TriggerCallback("backup:createBackup")
    end
    
    cb("ok")
end)

RegisterNUICallback("isAdmin", function(data, cb)
    TriggerCallback("isAdmin", cb)
end)

RegisterNUICallback("setPhoneName", function(name, cb)
    if settings then
        settings.name = name
    end
    
    TriggerServerEvent("phone:setName", name)
    cb("ok")
end)

RegisterNUICallback("setSettings", function(newSettings, cb)
    debugprint("setSettings triggered")
    
    if not phoneData then
        print("setSettings triggered, but phoneData is nil")
        return
    end
    
    settings = newSettings
    phoneData.settings = settings
    
    cb("ok")
    
    SetCallVolume((settings and settings.sound and settings.sound.callVolume) or nil)
    
    AwaitCallback("setSettings", settings)
    TriggerEvent("lb-phone:settingsUpdated", newSettings)
    
    SendReactMessage("customApp:sendMessage", {
        identifier = "any",
        message = {
            type = "settingsUpdated",
            settings = settings,
            action = "settingsUpdated",
            data = newSettings
        }
    })
end)

RegisterNUICallback("setCursorLocation", function(data, cb)
    local x, y = data.x, data.y
    local screenWidth, screenHeight = GetActiveScreenResolution()
    
    SetCursorLocation(x / screenWidth, y / screenHeight)
    cb("ok")
end)

RegisterNUICallback("exitFocus", function(data, cb)
    debugprint("exitFocus triggered")
    SetNuiFocus(false, false)
    ToggleOpen(false)
    cb("ok")
end)

RegisterNUICallback("getLocales", function(data, cb)
    cb(Config.Locales or {en = "English"})
end)

RegisterNUICallback("setOnScreen", function(onScreen, cb)
    onScreen = true == onScreen
    
    if onScreen ~= PhoneOnScreen then
        TriggerEvent("lb-phone:setOnScreen", onScreen)
        PhoneOnScreen = onScreen
    end
    
    cb("ok")
end)

exports("IsPhoneOnScreen", function()
    return PhoneOnScreen
end)

function SendReactMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

CreateThread(function()
    local lastTime = {}
    local lastService = nil
    
    while not currentPhone do
        debugprint("Waiting for currentPhone to be set before updating time & service")
        Wait(1000)
    end
    
    while true do
        if not Config.RealTime then
            local timeData = (Config.CustomTime and Config.CustomTime()) or {
                hour = GetClockHours(),
                minute = GetClockMinutes()
            }
            
            if timeData.hour ~= lastTime.hour or timeData.minute ~= lastTime.minute then
                lastTime.hour = timeData.hour
                lastTime.minute = timeData.minute
                SendReactMessage("updateTime", timeData)
            end
        end
        
        local serviceBars = GetServiceBars()
        if lastService ~= serviceBars then
            lastService = serviceBars
            SendReactMessage("updateService", serviceBars)
        end
        
        Wait(1000)
    end
end)

-- Function đã được định nghĩa trong customApp.lua, sử dụng từ đó

function GetConfigFile(filename)
    return LoadResourceFile(GetCurrentResourceName(), "config/" .. filename)
end

RegisterNUICallback("getConfigFile", function(fileName, cb)
    local fileContent = GetConfigFile(fileName .. ".json")
    local decodedData = json.decode(fileContent)
    cb(decodedData)
end)

RegisterNetEvent("phone:logoutFromApp", function(logoutData)
    debugprint("logoutFromApp:", logoutData)
    
    if logoutData.number and logoutData.number == currentPhone then
        return debugprint("Ignoring logoutFromApp event since number matches")
    end
    
    debugprint(logoutData.app .. ":logout", logoutData.username)
    SendReactMessage(logoutData.app .. ":logout", logoutData.username)
end)

local nearbyPlayers = {}

function GetNearbyPlayers()
    return nearbyPlayers
end

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local allPlayers = GetActivePlayers()
        local nearby = {}
        
        for i = 1, #allPlayers do
            local player = allPlayers[i]
            
            if player ~= PlayerId() then
                local ped = GetPlayerPed(player)
                local targetCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - targetCoords)
                
                if distance <= 60.0 then
                    nearby[#nearby + 1] = {
                        player = player,
                        source = GetPlayerServerId(player),
                        ped = ped
                    }
                end
            end
        end
        
        nearbyPlayers = nearby
        Wait(5000)
    end
end)

function LogOut()
    debugprint("LogOut triggered")
    
    while isFetchingPhone do
        debugprint("LogOut triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end
    
    AwaitCallback("setLastPhone")
    
    phoneData = nil
    currentPhone = nil
    settings = nil
    
    TriggerEvent("lb-phone:numberChanged", nil)
    ResetSecurity()
    OnDeath()
end

function SetPhone(phoneNumber, shouldFetch)
    debugprint("SetPhone triggered", phoneNumber, shouldFetch)
    
    while isFetchingPhone do
        debugprint("SetPhone triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end
    
    OnDeath()
    AwaitCallback("setLastPhone", phoneNumber)
    ResetSecurity(true)
    ToggleCharging(false)
    
    phoneData = nil
    currentPhone = nil
    settings = nil
    
    TriggerEvent("lb-phone:numberChanged", nil)
    
    if phoneNumber or shouldFetch then
        FetchPhone()
    end
    
    if nil == phoneNumber and not shouldFetch then
        local firstNumber = GetFirstNumber()
        if firstNumber then
            SetPhone(firstNumber)
        end
    end
end

function OnDeath()
    debugprint("OnDeath triggered")
    
    local liveStream = IsWatchingLive()
    EndLive()
    
    if liveStream then
        SendReactMessage("instagram:liveEnded", liveStream)
    end
    
    if flashlightEnabled then
        flashlightEnabled = false
        TriggerServerEvent("phone:toggleFlashlight", false)
    end
    
    EndCall()
    
    if phoneOpen then
        ToggleOpen(false)
    end
end

RegisterNetEvent("phone:toggleOpen", ToggleOpen)
exports("ToggleOpen", ToggleOpen)

exports("IsOpen", function()
    return phoneOpen
end)

exports("IsDisabled", function()
    return phoneDisabled
end)

exports("ToggleDisabled", function(disabled)
    phoneDisabled = true == disabled
    debugprint("ToggleDisabled triggered", phoneDisabled)
    
    if phoneDisabled and phoneOpen then
        ToggleOpen(false)
    end
end)

exports("GetSettings", function()
    return settings
end)

exports("GetAirplaneMode", function()
    return settings and settings.airplaneMode
end)

exports("GetStreamerMode", function()
    return settings and settings.streamerMode
end)

exports("GetEquippedPhoneNumber", function()
    return currentPhone
end)
