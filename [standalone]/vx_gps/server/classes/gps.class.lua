---@class GlobalPosition:Class
---@operator call: GlobalPosition
GlobalPosition = class()

function GlobalPosition:Init(name, data)
    self.name = name
    self.data = data
    self.players = {}
    self.destroyed = false
    self.relay = false
    self.delay = 0
    self.syncs = {}
    self:Thread()
end

function GlobalPosition:HasPlayer(playerId)
    for i = 1, #self.players do
        local pId = self.players[i].src
        if tonumber(pId) == tonumber(playerId) then
            return true
        end
    end
    return false
end

---@param playerId number
---@param playerName string
---@param playerCoords vector3
---@return any
function GlobalPosition:AddPlayer(playerId, playerName, playerCoords)
    -- print(playerId, playerName, playerCoords)
    if self:HasPlayer(playerId) then return end
    local coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z, w = 0.0 }
    table.insert(self.players, {
        src = tonumber(playerId),
        name = playerName,
        coords = coords,
    })
    TriggerClientEvent("vinx-gps:client:create", tonumber(playerId), self.name)
    self.implCache["Main"]:SetPlayerGlobal(playerId, self.name)
end

function GlobalPosition:RemovePlayer(playerId)
    for k, player in pairs(self.players) do
        if tonumber(player.src) == tonumber(playerId) then
            TriggerClientEvent("vinx-gps:client:destroy", tonumber(playerId))
            table.remove(self.players, k)
            self.implCache["Main"]:SetPlayerGlobal(playerId, nil)
            break
        end
    end
end

function GlobalPosition:SyncPlayer(playerId, coords)
    if not playerId or not coords then return end
    -- self:BroadcastExcept(playerId, "vinx-globalposition:client:update", {
    --     src = playerId,
    --     coords = coords
    -- })
end

function GlobalPosition:Thread()
    -- Citizen.CreateThread(function()
    --     local ok, err = pcall(function()
    --         while true do
    --             local Syncs = {}
    --             local playersCopy = {}
    --             for i, player in ipairs(self.players or {}) do
    --                 playersCopy[i] = player
    --             end

    --             for _, player in pairs(playersCopy) do
    --                 local src = tonumber(player.src)
    --                 if not src then
    --                     self:LogWarning("Invalid player src")
    --                     goto continue
    --                 end

    --                 local coords = CORE.CallService("PlayersService", "getPlayerCoords", tostring(player.src))
    --                 if coords then
    --                     table.insert(Syncs, {
    --                         src = player.src,
    --                         coords = {
    --                             x = coords[1], y = coords[2], z = coords[3], w = GetEntityHeading(GetPlayerPed(src))
    --                         }
    --                     })
    --                 end
    --                 ::continue::
    --             end

    --             if #Syncs > 0 then
    --                 local ok2, err2 = pcall(function()
    --                     self:SyncToClients("vinx-globalposition:client:syncs", Syncs)
    --                 end)
    --                 -- if not ok2 then
    --                 -- self.implCache["Main"]:SendToDiscord("Error syncing:", err2)
    --                 -- end
    --             end

    --             Citizen.Wait(300)
    --         end
    --     end)

    --     if not ok then
    --         self.implCache["Main"]:SendToDiscord("Thread crashed:", err)
    --     end
    -- end)
end

function GlobalPosition:Destroy()
    self.destroyed = true
end

function GlobalPosition:SyncToClients(event, data)
    for _, player in pairs(self.players) do
        WS.TriggerClientEvent(event, tonumber(player.src), data)
    end
end

function GlobalPosition:BroadcastExcept(except, event, data)
    local exceptId = tonumber(except)
    for _, player in pairs(self.players) do
        local syncId = tonumber(player.src)
        if syncId ~= exceptId then
            WS.TriggerClientEvent(event, syncId, data)
        end
    end
end
