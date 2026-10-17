---@class CLDevToolImpl : Impl
local Impl = NewImpl("DevTool")

function Impl:Init()
  main:LogInfo("%s initialized", self:GetName())
  self:RegisterCommands()
end

function Impl:OnReady()
  main:LogInfo("%s ready", self:GetName())
end

function Impl:RegisterCommands()
  RegisterCommand("vec3", function(source, args, rawCommand)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local str = string.format("vector3(%.4f, %.4f, %.4f)", pedCoords.x, pedCoords.y, pedCoords.z)
    SendNUIMessage({
      event = "main:copyToClipboard",
      data = str
    })
    self:LogInfo("Copied %s to clipboard", str)
  end, false)

  RegisterCommand("vec4", function(source, args, rawCommand)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local str = string.format("vector4(%.4f, %.4f, %.4f, %.4f)", pedCoords.x, pedCoords.y, pedCoords.z,
      GetEntityHeading(PlayerPedId()))
    SendNUIMessage({
      event = "main:copyToClipboard",
      data = str
    })
    self:LogInfo("Copied %s to clipboard", str)
  end, false)
end
