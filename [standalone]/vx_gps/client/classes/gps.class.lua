---@class GlobalPosition:Class
---@operator call: GlobalPosition
GlobalPosition = class()

function GlobalPosition:Init(global, player, config)
    self.id = player.src
    self.name = player.name
    self.coords = player.coords
    self.global = global
    self.config = config
    self.blip = nil
    self:CreateBlip()
    self:LogInfo("Initial %s", json.encode(self.coords))
end

function GlobalPosition:CreateBlip()
    if not Config.DefautGps[self.global] and not self.config then return end
    local cfg = self.config or Config.DefautGps[self.global]
    self.blip = AddBlipForCoord(self.coords.x, self.coords.y, self.coords.z)
    SetBlipSprite(self.blip, tonumber(cfg.sprite))
    SetBlipColour(self.blip, tonumber(cfg.color))

    SetBlipScale(self.blip, tonumber(cfg.scale) + 0.2)
    SetBlipDisplay(self.blip, tonumber(cfg.display) or 4)
    ShowHeadingIndicatorOnBlip(self.blip, true)
    SetBlipRotation(self.blip, self.coords.w)
    SetBlipCategory(self.blip, 12)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(self.name)
    EndTextCommandSetBlipName(self.blip)
end

function GlobalPosition:RemoveBlip()
    if self.blip and DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
    end
end

function GlobalPosition:Destroy()
    self:RemoveBlip()
end

function GlobalPosition:UpdatePlayer(coords)
    if not DoesBlipExist(self.blip) then
        self:CreateBlip()
    end
    self.coords = coords
    if not self.coords then
        return self:LogError("Update Player Coords Is Null %s", self.name)
    end
    SetBlipCoords(self.blip, self.coords.x, self.coords.y, self.coords.z)
    SetBlipRotation(self.blip, math.ceil(self.coords.w))
end
