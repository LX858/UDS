local Impl = NewImpl("Main")

function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  self.coin = 0
  self.primeTicket = 0
  self.dailyRewardsOpen = false
  self.nuiOpen = false
  self:NuiHandler()
  self:EventHandler()
  self:Command()
  self:Online4HoursEvent()
  self:PrimeTicket()
  self:DailyRewardsBridge()
  self:EscWatcherThread()
end

local DAILY_CALLBACK_TIMEOUT_MS = 8000

function Impl:ReplyDailyCallback(cb, callbackName, fallback, onResult, ...)
  local args = { ... }
  local finished = false

  local function reply(payload)
    if finished then return end
    finished = true

    if onResult then
      local ok, transformed = pcall(onResult, payload)
      if ok then
        cb(transformed or fallback)
      else
        print(("[Tipi_menu] Daily callback transform failed: %s"):format(tostring(transformed)))
        cb(fallback)
      end
      return
    end

    cb(payload or fallback)
  end

  SetTimeout(DAILY_CALLBACK_TIMEOUT_MS, function()
    reply(fallback)
  end)

  CreateThread(function()
    local ok, result = pcall(function()
      return lib.callback.await(callbackName, false, table.unpack(args))
    end)

    if ok then
      reply(result or fallback)
    else
      print(("[Tipi_menu] Daily callback failed: %s | %s"):format(callbackName, tostring(result)))
      reply(fallback)
    end
  end)
end

function Impl:PrimeTicket()
  CreateThread(function()
    while true do
      Wait(1000)
      if self.primeTicket > 0 then
        self.primeTicket -= 1
      end
      if self.nuiOpen then
        SendReactMessage("setPrimeTicket", math.max(0, self.primeTicket))
      end
    end
  end)
end

function Impl:Online4HoursEvent()
  CreateThread(function()
    while true do
      if self.nuiOpen then
        SendReactMessage("setTime", GlobalState.OnlineTime)
        Wait(1000)
      else
        Wait(3000)
      end
    end
  end)
end

function Impl:SyncPlayerCoin()
  local coin = lib.callback.await("Tipi_menu:sv:getPlayerCoin", false) or 0
  self.coin = coin
  SendReactMessage("setPlayerCoin", self.coin)
end

function Impl:EventHandler()
  RegisterNetEvent('Tipi_menu:cl:syncPlayerCoin', function(coin)
    self.coin = tonumber(coin) or 0
    SendReactMessage("setPlayerCoin", self.coin)
  end)

  RegisterNetEvent('esx:setAccountMoney', function(account)
    if account.name == 'coin' then
      self:SyncPlayerCoin()
    end
  end)

  RegisterNetEvent('QBCore:Client:OnMoneyChange', function(moneyType)
    if moneyType == 'coin' then
      self:SyncPlayerCoin()
    end
  end)

  RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    if UsesDbCoinColumn() then return end
    local playerData = GetClientPlayerData()
    self.coin = GetCoinAmounts(playerData.accounts)
    SendReactMessage("setPlayerCoin", self.coin)
  end)

  RegisterNetEvent('qbx_core:client:playerDataUpdated', function(key, value)
    if key ~= 'accounts' or UsesDbCoinColumn() then return end
    self.coin = GetCoinAmounts(value)
    SendReactMessage("setPlayerCoin", self.coin)
  end)
end

function Impl:NuiHandler()
  RegisterNUICallback("close", function(body, cb)
    cb(1)
    if IsPauseMenuActive() then
      SetFrontendActive(false)
    end
    self:ToggleNUI(false)
  end)

  RegisterNUICallback("Close", function(body, cb)
    cb(1)
    if IsPauseMenuActive() then
      SetFrontendActive(false)
    end
    self:ToggleNUI(false)
  end)

  RegisterNUICallback("hideFrame", function(body, cb)
    cb(1)
    if IsPauseMenuActive() then
      SetFrontendActive(false)
    end
    self:ToggleNUI(false)
  end)

  RegisterNUICallback("shop:buyHaloween", function(body, cb)
    cb(1)
    -- print(body)
    if Config.Events[Config.CurrentEvent] then
      local cfgData = Config.Events[Config.CurrentEvent]
      local invData = exports.ox_inventory:Items()
      if cfgData[body] then
        local itemListLabel = ""
        if type(cfgData[body].reward) == "table" then
          for k, v in pairs(cfgData[body].reward) do
            local itemLabel = invData[k].label
            itemListLabel = itemListLabel .. " [ " .. v .. "x " .. itemLabel .. " ]"
          end
          itemListLabel = itemListLabel .. " Bonus : " .. cfgData[body].bonus .. " Bí"
        elseif type(cfgData[body].reward) == "number" then
          itemListLabel = cfgData[body].reward .. "x UL Points"
        else
          itemListLabel = "1x " .. Config.VehicleLabel[cfgData[body].reward] .. " Bonus : " ..
              cfgData[body].bonus .. " Bí"
        end
        local alert = lib.alertDialog({
          header = 'Xác nhận',
          content = string.format("Bạn có chắc chắn muốn mua gói này bao gồm %s với giá %s coins", itemListLabel,
            cfgData[body].price),
          centered = true,
          cancel = true,
          labels = {
            confirm = "Đồng ý",
            cancel = "Huỷ bỏ"
          }
        })
        if alert == 'confirm' then
          local response = lib.callback.await("Tipi_menu:sv:onBuyEvents", 1000, body)
        end
      end
    end
  end)

  RegisterNUICallback("getPrimeTicket", function(body, cb)
    cb(1)
    local response = lib.callback.await("Tipi_menu:sv:getPrimeTicket")
    if response then
      self.primeTicket = response
    end
  end)

  RegisterNUICallback("onBuyPrime", function(body, cb)
    cb(1)
    local alert = lib.alertDialog({
      header = 'Xác nhận',
      content = 'Bạn có chắc chắn muốn mua gói Prime Ticket với giá ' .. Config.PrimePrice .. ' Coin không?',
      centered = true,
      cancel = true,
      labels = {
        confirm = "Đồng ý",
        cancel = "Huỷ bỏ"
      }
    })
    if alert == 'confirm' then
      local response = lib.callback.await("Tipi_menu:sv:onBuyPrime", 1000)
      if response then
        self.primeTicket = response
      end
    end
  end)

  RegisterNUICallback("main:action", function(body, cb)
    cb(1)
    if Config.EventClient[body.key] then
      TriggerEvent(Config.EventClient[body.key])
      self:ToggleNUI(false)
      --[[ elseif body.key == "submitGiftCode" then
      local response = lib.callback.await("Tipi_menu:cb:giftCode:redeem", false, body.value)
      if not response.status then
        Notify(response.message, "error")
        return
      else
        Notify(response.message, "success")
      end

      self:ToggleNUI(false) ]]
    end
    if body == 'getOnlineReward' then
      local response = lib.callback.await("mp_lib:sv:getOnlineReward", false)
      self:ToggleNUI(false)
    end
  end)

  RegisterNUICallback("shop:buycoin", function(body, cb)
    cb(1)
    local alert = lib.alertDialog({
      header = 'Xác nhận',
      content = 'Bạn có chắc chắn muốn mua gói ' .. body .. '$ với giá ' .. Config.IngameRate[body] .. ' Coin không?',
      centered = true,
      cancel = true,
      labels = {
        confirm = "Đồng ý",
        cancel = "Huỷ bỏ"
      }
    })
    if alert == 'confirm' then
      lib.callback.await("Tipi_menu:sv:buyCoin", 1000, body)
      self:ToggleNUI(false)
    end
  end)

  RegisterNUICallback("getBoards", function(_, cb)
    if GetResourceState("Tipi_Rankings") ~= "started" then
      cb({ boards = {}, branding = {}, error = "resource_not_started" })
      return
    end
    local payload = lib.callback.await("Tipi_Rankings:cb:getBoards", false)
    cb(payload)
  end)

  RegisterNUICallback("getLeaderboard", function(data, cb)
    if GetResourceState("Tipi_Rankings") ~= "started" then
      cb({ success = false, error = "Tipi_Rankings_not_started" })
      return
    end
    local boardId = data and data.boardId
    if not boardId then
      cb({ success = false, error = "missing_board_id" })
      return
    end
    local result = lib.callback.await("Tipi_Rankings:cb:getLeaderboard", false, boardId)
    cb(result)
  end)

  RegisterNUICallback("dailyRewards:getSummary", function(_, cb)
    if GetResourceState("Tipi_Daily_Rewards") ~= "started" then
      cb({ error = "resource_not_started" })
      return
    end

    self:ReplyDailyCallback(
      cb,
      "Tipi_Daily_Rewards:Callback:GetSummary",
      { error = "daily_callback_timeout" },
      function(data)
        if not data or data.error then
          return data or { error = "daily_callback_timeout" }
        end

        local metaOk, meta = pcall(function()
          return exports["Tipi_Daily_Rewards"]:GetUiMeta()
        end)
        if not metaOk or not meta then meta = {} end

        data.inventoryImageTemplate = meta.inventoryImageTemplate
        data.inventoryImageCdn = meta.inventoryImageCdn
        data.itemImageResourceTemplate = meta.itemImageResourceTemplate
        return data
      end
    )
  end)

  RegisterNUICallback("dailyRewards:open", function(_, cb)
    if GetResourceState("Tipi_Daily_Rewards") ~= "started" then
      cb({ error = "resource_not_started" })
      return
    end

    self:ReplyDailyCallback(
      cb,
      "Tipi_Daily_Rewards:Callback:GetPlayerForDailyRewards",
      { error = "daily_callback_timeout" },
      function(data)
        if not data or data.error then
          self.dailyRewardsOpen = false
          return data or { error = "daily_callback_timeout" }
        end

        local metaOk, meta = pcall(function()
          return exports["Tipi_Daily_Rewards"]:GetUiMeta()
        end)
        if not metaOk or not meta then meta = {} end

        self.dailyRewardsOpen = true
        return {
          data = data,
          items = data.items,
          locales = meta.locales,
          daysInMonth = data.daysInMonth,
          monthKey = data.monthKey,
          calendarYear = data.calendarYear,
          calendarMonth = data.calendarMonth,
          mysteryImageUrl = meta.mysteryImageUrl,
          inventoryImageTemplate = meta.inventoryImageTemplate,
          inventoryImageCdn = meta.inventoryImageCdn,
          itemImageResourceTemplate = meta.itemImageResourceTemplate,
          clothingImageUrl = meta.clothingImageUrl,
          clothingImageExt = meta.clothingImageExt,
          clothingComponents = meta.clothingComponents,
        }
      end
    )
  end)

  RegisterNUICallback("dailyRewards:close", function(_, cb)
    self.dailyRewardsOpen = false
    cb(1)
  end)

  RegisterNUICallback("dailyRewards:setOpen", function(body, cb)
    self.dailyRewardsOpen = body == true
    cb(1)
  end)

  RegisterNUICallback("dailyRewards:Claimed", function(body, cb)
    if GetResourceState("Tipi_Daily_Rewards") ~= "started" then
      cb({ ok = false, error = "resource_not_started" })
      return
    end
    local day = type(body) == "table" and (body.day or body[1]) or body
    local track = type(body) == "table" and body.track or "normal"
    self:ReplyDailyCallback(
      cb,
      "Tipi_Daily_Rewards:Callback:ClaimDailyReward",
      { ok = false, error = "daily_callback_timeout" },
      function(result)
        result = result or { ok = false, error = "claim_failed" }
        if not result.ok then
          local err = result.error
          local toastMsg = nil
          if err == "not_enough_money" then
            toastMsg = ("Không đủ tiền để nhận bù ngày (cần %s$)"):format(tostring(result.price or 0))
          elseif err == "max_missed_claims_reached" then
            toastMsg = ("Đã hết lượt nhận bù ngày trong tháng này tối đa %d lượt"):format(
              tonumber(result.maxAllowed) or 0
            )
          elseif err == "busy" then
            toastMsg = "Đang xử lý quà, vui lòng chờ..."
          elseif err == "already_claimed" then
            toastMsg = "Ngày này đã nhận rồi"
          elseif err == "not_eligible" then
            toastMsg = "Chưa đủ điều kiện nhận"
          elseif err == "need_vip_pack" then
            toastMsg = "Cần mua gói VIP tháng này"
          elseif err and err ~= "daily_callback_timeout" then
            toastMsg = "Không nhận được quà"
          end

          if toastMsg then
            Notify(toastMsg, "error")
            SendReactMessage("dailyRewardsToast", {
              type = "error",
              message = toastMsg,
              error = err,
              price = result.price,
            })
          end
        end
        return result
      end,
      day,
      track
    )
  end)

  RegisterNUICallback("dailyRewards:ClaimStreak", function(body, cb)
    if GetResourceState("Tipi_Daily_Rewards") ~= "started" then
      cb({ ok = false, error = "resource_not_started" })
      return
    end
    local days = type(body) == "table" and (body.days or body.tier) or body
    self:ReplyDailyCallback(
      cb,
      "Tipi_Daily_Rewards:Callback:ClaimStreak",
      { ok = false, error = "daily_callback_timeout" },
      nil,
      tonumber(days)
    )
  end)

  RegisterNUICallback("dailyRewards:BuyVipPack", function(_, cb)
    if GetResourceState("Tipi_Daily_Rewards") ~= "started" then
      cb({ ok = false, error = "resource_not_started" })
      return
    end
    self:ReplyDailyCallback(
      cb,
      "Tipi_Daily_Rewards:Callback:BuyVipPack",
      { ok = false, error = "daily_callback_timeout" },
      function(result)
        if result and result.ok then
          SendReactMessage("dailyRewardsVipBought", result)
        end
        return result or { ok = false }
      end
    )
  end)

  RegisterNUICallback("playClick", function(_, cb)
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb("ok")
  end)

  RegisterNUICallback("shop:action", function(body, cb)
    cb(1)
    if body == 'openShopCoin' then
      TriggerEvent("mp_shops:cl:openShop", "coin")
      self:ToggleNUI(false)
    elseif body == 'openContainer' then
      TriggerEvent("mp_gachapon:cl:openUI")
      self:ToggleNUI(false)
    elseif body == 'openGacha' then
      TriggerEvent("genscripts:case:openUI")
      self:ToggleNUI(false)
    elseif body == 'openGachaCoin' then
      TriggerEvent("iuh_crate:openMenu")
      self:ToggleNUI(false)
    elseif body == "buyNewbieVoucher" then
      local alert = lib.alertDialog({
        header = 'Xác nhận',
        content = 'Bạn có chắc chắn muốn mua gói NEWBIE với giá ' .. Config.NewBie["price"] .. ' Coin không?',
        centered = true,
        cancel = true,
        labels = {
          confirm = "Đồng ý",
          cancel = "Huỷ bỏ"
        }
      })
      if alert == 'confirm' then
        if self.coin >= Config.NewBie["price"] then
          lib.callback.await("Tipi_menu:sv:buyNewbie", 1000)
        else
          Notify("Bạn không đủ " .. Config.NewBie["price"] .. " Coin để mua gói NewBie", "error")
        end
        self:ToggleNUI(false)
      end
    elseif body == 'openSetting' and Config.EventClient[body] then
      self:ToggleNUI(false, { restoreHud = false })
      TriggerEvent(Config.EventClient[body])
    else
      if Config.EventClient[body] then
        TriggerEvent(Config.EventClient[body])
        self:ToggleNUI(false)
      end
    end
  end)
end

function Impl:DailyRewardsBridge()
  RegisterNetEvent("Tipi_Daily_Rewards:Client:SyncOnline", function(data)
    SendReactMessage("dailyRewardsSync", data)
  end)

  RegisterNetEvent("Tipi_Daily_Rewards:Client:MonthClaimReady", function(data)
    SendReactMessage("dailyMonthClaimReady", data)
    -- SyncOnline đã push từ server; chỉ fallback nếu chưa có data
    if data and type(data) == "table" then
      SendReactMessage("dailyRewardsSync", {
        onlineMinutes = data.minutes,
        todayReward = data.todayReward,
        presentToday = true,
      })
    end
  end)

  -- Backup poll nhẹ khi menu mở (server đã push mỗi phút)
  CreateThread(function()
    while true do
      Wait(self.nuiOpen and 10000 or 60000)
      if self.nuiOpen and GetResourceState("Tipi_Daily_Rewards") == "started" then
        local data = lib.callback.await("Tipi_Daily_Rewards:Callback:GetOnlineProgress", false)
        if data then
          SendReactMessage("dailyRewardsSync", data)
        end
      end
    end
  end)
end

RegisterNetEvent('Tipi_menu:cl:openDailyRewards')
AddEventHandler('Tipi_menu:cl:openDailyRewards', function()
  if not main then return end
  main:ImplCall('Main', 'PrepareFirstData')
  main:ImplCall('Main', 'ToggleNUI', true)
  SendReactMessage('openDailyRewards', true)
end)

local isMapOpen = false

Citizen.CreateThread(function()
  while true do
    Wait(0)
    if not isMapOpen and not IsPauseMenuActive() then
      SetPauseMenuActive(false)
    end
  end
end)

function Impl:Command()
  local lastToggle = 0
  RegisterKeyMapping('menumain1', "<FONT FACE = 'Oswald'>Menu Chính", 'keyboard', 'ESCAPE')
  RegisterCommand('menumain1', function()
    local now = GetGameTimer()
    if (now - lastToggle) < 350 then return end
    lastToggle = now

    if self.nuiOpen then
      self:ToggleNUI(false)
      return
    end
    if IsNuiFocused() then
      return
    end
    -- TriggerServerEvent('ox_inventory:closeInventory')
    if isMapOpen or IsPauseMenuActive() then
      return
    end
    if LocalPlayer.state.isDead then return end
    if LocalPlayer.state.isEmotesMenuOpen then return end
    self:ToggleNUI(true)
    self:PrepareFirstData()
  end, false)
end

function Impl:PrepareFirstData()
  local playerData = GetClientPlayerData()
  local initialData = {}
  local ok, result = pcall(function()
    return lib.callback.await("Tipi_menu:sv:getMenuPlayerData", false)
  end)
  if ok and type(result) == "table" then
    initialData = result
  end

  local ageData = initialData.ageData or {}

  local UIData = {
    id = GetPlayerServerId(PlayerId()),
    name = (playerData and playerData.name) or '',
    job = (playerData and playerData.job and playerData.job.label) or '',
    phoneNumber = initialData.phoneNumber or '',
    age = ageData.display or Config.FormatPlaytimeAgeDisplay(ageData.level, ageData.label),
    timeRegistered = initialData.dateRegistered or (os.time() * 1000),
  }
  self.coin = tonumber(initialData.coin) or 0
  self.point = (playerData and playerData.accounts and GetCoinAmounts2(playerData.accounts)) or 0
  SendReactMessage("setPlayerInfo", UIData)
  SendReactMessage("setPlayerCoin", self.coin)
end

function Impl:FormatTime(time)
  local seconds = time / 1000
  return os.date("%d/%m/%Y", seconds)
end

function Impl:GetTotalOnlineTime(time)
  local seconds = time / 1000
  local currentTime = GlobalState.ostime
  local time_diff = currentTime - seconds
  local hour = math.floor(time_diff / 3600)
  local minute = math.floor((time_diff % 3600) / 60)
  local second = time_diff % 60
  return string.format("%02d:%02d:%02d", hour, minute, second)
end

function Impl:SetHudVisible(visible)
  local hudResource = Config.QBX and Config.QBX.hudResource
  if not hudResource then return end

  if hudResource == 'Tipi_hud' then
    TriggerEvent('tipi_hud:setHideAll', not visible)
    return
  end

  if GetResourceState(hudResource) == 'started' then
    pcall(function()
      exports[hudResource]:ImplCall('Hud', 'OpenHud', visible)
    end)
  end
end

function Impl:EscWatcherThread()
  CreateThread(function()
    while true do
      if self.nuiOpen then
        DisableControlAction(0, 199, true) -- Pause Menu
        DisableControlAction(0, 200, true) -- ESC (Pause Alternate)
        DisableControlAction(0, 1, true)   -- LookLeftRight
        DisableControlAction(0, 2, true)   -- LookUpDown
        DisableControlAction(0, 24, true)  -- Attack
        DisableControlAction(0, 257, true) -- Attack 2
        DisableControlAction(0, 140, true) -- Melee Attack Light
        DisableControlAction(0, 141, true) -- Melee Attack Heavy
        DisableControlAction(0, 142, true) -- Melee Attack Alternate
        DisableControlAction(0, 30, true)  -- Move LR
        DisableControlAction(0, 31, true)  -- Move UD
        DisableControlAction(0, 23, true)  -- Enter Vehicle
        DisableControlAction(0, 75, true)  -- Exit Vehicle

        if (GetGameTimer() - (self.openedAt or 0)) > 350 then
          if IsDisabledControlJustPressed(0, 199) or IsDisabledControlJustPressed(0, 200) or IsControlJustPressed(0, 199) or IsControlJustPressed(0, 200) then
            self:ToggleNUI(false)
          end
        end
        Wait(0)
      else
        Wait(250)
      end
    end
  end)
end

function Impl:ToggleNUI(state, opts)
  opts = opts or {}
  local restoreHud = opts.restoreHud
  if restoreHud == nil then
    restoreHud = not state
  end

  self.nuiOpen = state == true
  if not self.nuiOpen then
    self.dailyRewardsOpen = false
  end

  if state == true then
    self.openedAt = GetGameTimer()
    self:DocumentTask()
    TriggerScreenblurFadeIn(1000)
    DisplayRadar(false)
    self:SetHudVisible(false)
    SetNuiFocus(true, true)
  else
    TriggerScreenblurFadeOut(1000)
    DisplayRadar(true)
    if restoreHud then
      self:SetHudVisible(true)
    end
    SetNuiFocus(false, false)
  end
  SendReactMessage("setShow", state)
end

function Impl:DocumentTask()
  local hasItemDrive = exports.ox_inventory:Search('count', 'id_drive') >= 1
  local hasItemBoat = exports.ox_inventory:Search('count', 'id_boat') >= 1
  local hasItemFly = exports.ox_inventory:Search('count', 'id_fly') >= 1
  local hasItemWeapon = exports.ox_inventory:Search('count', 'id_weapon2') >= 1
  local hasItemIdCard = exports.ox_inventory:Search('count', 'id_card') >= 1

  local license = {
    hasItemDrive = hasItemDrive,
    hasItemBoat = hasItemBoat,
    hasItemFly = hasItemFly,
    hasItemWeapon = hasItemWeapon,
    hasItemIdCard = hasItemIdCard
  }
  SendReactMessage("setLicense", license)
end

RegisterNetEvent('open:map')
AddEventHandler('open:map', function()
  isMapOpen = true
  main:ImplCall('Main', 'ToggleNUI', false)
  ActivateFrontendMenu("FE_MENU_VERSION_MP_PAUSE", true, -1)
  while not IsPauseMenuActive() do Wait(0) end
  PauseMenuceptionGoDeeper(0)
  PauseMenuceptionTheKick()
  SetNuiFocus(false, false)
  CreateThread(function()
    while IsPauseMenuActive() do
      Wait(100)
    end
    isMapOpen = false
  end)
end)

RegisterNetEvent('open:Settings')
AddEventHandler('open:Settings', function()
  isMapOpen = true
  main:ImplCall('Main', 'ToggleNUI', false)
  main:ImplCall('Main', 'SetHudVisible', false)
  ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_LANDING_MENU'), 0, -1)
  CreateThread(function()
    while not IsPauseMenuActive() do
      Wait(0)
    end
    while IsPauseMenuActive() do
      Wait(100)
    end
    main:ImplCall('Main', 'SetHudVisible', true)
    isMapOpen = false
  end)
end)
