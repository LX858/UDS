---@class TraderImpl : Impl
local Impl = NewImpl("Trader")

local uiOpen = false
local traderPed

local function drawText3D(coords, text)
  local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
  if not onScreen then return end

  SetTextScale(0.36, 0.36)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextColour(255, 239, 184, 255)
  SetTextCentre(true)
  SetTextOutline()
  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(screenX, screenY)
end

local function startNpcLabelThread()
  CreateThread(function()
    while true do
      if traderPed and DoesEntityExist(traderPed) then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local npcCoords = GetEntityCoords(traderPed)
        local distance = #(playerCoords - npcCoords)

        if distance <= 20.0 then
          drawText3D(vec3(npcCoords.x, npcCoords.y, npcCoords.z + 1.15), "NPC Sự Kiện")
          Wait(0)
        else
          Wait(500)
        end
      else
        Wait(1000)
      end
    end
  end)
end

local function deleteTraderPed()
  if traderPed and DoesEntityExist(traderPed) then
    exports.ox_target:removeLocalEntity(traderPed)
    DeleteEntity(traderPed)
  end
  traderPed = nil
end

local function createTraderPed(openTrader)
  local npcConfig = Config.TraderNpc
  if not npcConfig or npcConfig.enabled == false then return end
  if GetResourceState("ox_target") ~= "started" then
    print("^1[vx_trader]^7 ox_target must be started before vx_trader")
    return
  end

  local model = type(npcConfig.model) == "string" and joaat(npcConfig.model) or npcConfig.model
  if not IsModelInCdimage(model) or not IsModelValid(model) then
    print(("^1[vx_trader]^7 Invalid trader NPC model: %s"):format(tostring(npcConfig.model)))
    return
  end

  RequestModel(model)
  while not HasModelLoaded(model) do Wait(0) end

  local coords = npcConfig.coords
  traderPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
  SetEntityHeading(traderPed, coords.w)
  FreezeEntityPosition(traderPed, true)
  SetEntityInvincible(traderPed, true)
  SetBlockingOfNonTemporaryEvents(traderPed, true)
  SetPedCanRagdoll(traderPed, false)

  exports.ox_target:addLocalEntity(traderPed, {
    {
      name = "vx_trader_open",
      icon = npcConfig.target.icon,
      label = npcConfig.target.label,
      distance = npcConfig.target.distance,
      onSelect = openTrader,
    },
  })

  SetModelAsNoLongerNeeded(model)
end

local function sendVisibility(state)
  SendNUIMessage({
    event = "main:setShow",
    data = state,
  })
end

function Impl:Init()
  self:RegisterHandlers()
  CreateThread(function()
    Wait(500)
    createTraderPed(function()
      self:Open()
    end)
  end)
  startNpcLabelThread()
  self:LogInfo("%s initialized", self:GetName())
end

function Impl:Open()
  if uiOpen then return end

  uiOpen = true
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  sendVisibility(true)
end

function Impl:Close()
  if not uiOpen then return end

  uiOpen = false
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  sendVisibility(false)
end

function Impl:RegisterHandlers()
  -- RegisterNetEvent("vx_trader:client:open", function()
  --   self:Open()
  -- end)

  -- RegisterCommand(Config.Command, function()
  --   self:Open()
  -- end, false)

  RegisterNUICallback("getCatalog", function(_, cb)
    local ok, result = pcall(function()
      return lib.callback.await("vx_trader:server:getCatalog", false)
    end)

    if not ok then
      self:LogError("Failed to get catalog: %s", result)
      cb({ chests = {}, items = {}, outfits = {} })
      return
    end

    cb(result or { chests = {}, items = {}, outfits = {} })
  end)

  RegisterNUICallback("exchange", function(data, cb)
    local entryId = data and data.entryId
    local quantity = data and data.quantity
    local ok, result = pcall(function()
      return lib.callback.await("vx_trader:server:exchange", false, entryId, quantity)
    end)

    if not ok then
      self:LogError("Exchange callback failed: %s", result)
      cb({
        success = false,
        code = "callback_failed",
        message = "Không thể kết nối tới máy chủ.",
      })
      return
    end

    cb(result or {
      success = false,
      code = "unknown_error",
      message = "Quy đổi thất bại.",
    })
  end)

  RegisterNUICallback("close", function(_, cb)
    self:Close()
    cb("ok")
  end)
end

function Impl:OnResourceStop()
  deleteTraderPed()
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
end

exports("OpenTrader", function()
  local trader = main:GetImpl("Trader")
  if trader then trader:Open() end
end)
