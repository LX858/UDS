---@class MainImpl : Impl
local Impl = NewImpl("Main")

function Impl:Init()
    main:LogInfo("%s initialized", self:GetName())
    self.global = nil
    self.players = {}
    self.ShowGps = true
    self.config = nil
    self.delay = 0
    self.globals = {}
    self:MainThread()
end

function Impl:OnReady()
    self:WSEventHandlers()
    self:RegisterCommands()
end

function Impl:WSEventHandlers()
    AddTextEntry("BLIP_CAT_" .. 12, "GPS")  
    RegisterNetEvent("vinx-gps:client:create", function(globalName)
        self:LogInfo("GlobalPosition[%s] created", globalName)
        self.global = globalName
        SendReactMessage("GlobalPosition:Register", {
            globalName = globalName,
            playerId = main.playerServerId,
            playerName = GetPlayerName(PlayerId())
        })
    end)
    RegisterNetEvent("vinx-gps:client:destroy", function()
        self.global = nil
        for k, v in pairs(self.globals) do 
            v:Destroy()
        end
        self.globals = {}
        self:LogInfo("GlobalPosition destroyed")
    end)

    RegisterNUICallback("ClientRegistered", function(data, cb)
        local playerId, playerName, globalName = data.player_id, data.player_name, data.faction

        if not self.globals[playerId] then
            if playerId == main.playerServerId then return end
            self.globals[playerId] = GlobalPosition(globalName, {
                src = playerId,
                name = playerName,
                coords = {x = 0, y = 0, z = 0, w = 0}
            }, {
                sprite = 1,
                color = 3,
                scale = 1.0,
                display = 4,
                name = globalName
            })
        end
        cb({})
    end)
    RegisterNUICallback("ClientRemoved", function(data, cb)
        local playerId = data.player_id
        if self.globals[playerId] then
            self.globals[playerId]:Destroy()
            self.globals[playerId] = nil
        end
        cb({})
    end)
    RegisterNUICallback("ClientUpdate", function(data, cb)
        cb({})
        if not self.global then return end
        local player = data.player_id
        local position = data.position
        if self.globals[player] then
            if playerId == main.playerServerId then return end
            self.globals[player]:UpdatePlayer(position)
        end
    end)
    RegisterNUICallback("ClientUpdateBatch", function(data, cb)
        cb({})
        -- print("ClientUpdateBatch", json.encode(data))
        if not self.global then return end
        if type(data) ~= "table" or type(data.updates) ~= "table" then
            return
        end

        for _, update in ipairs(data.updates) do
            local player = tonumber(update.player_id)
            local position = update.position

            if player and position and self.globals[player] then
                local serverId = tonumber(player)

                if tonumber(player) ~= main.playerServerId then 
                    self.globals[player]:UpdatePlayer(position)
                end
            end
        end
    end)
    RegisterNUICallback("Gps:Toggle", function(data, cb)
        self.ShowGps = data.enabled
        local player = main.playerServerId
        -- if not self.ShowGps then 
        --   if self.globals[player] then
        --     self.globals[player]:Destroy()
        --     self.globals[player] = nil
        --   end
        -- elseif self.global then
        --   self.globals[player] = GlobalPosition(self.global, {
        --     src = player,
        --     name = GetPlayerName(PlayerId()),
        --     coords = { x = 0, y = 0, z = 0, w = 0 }
        --   }, {
        --     sprite = 1,
        --     color = 1,
        --     scale = 1.0,
        --     display = 4,
        --     name = self.global,
        --   })
        -- end
        cb({})
    end)

    TriggerServerEvent("vinx-gps:server:playerLoaded")

    -- for i = 0, 3 do
    --     StatSetInt(GetHashKey("mp" .. i .. "_shooting_ability"), 130, true)
    --     StatSetInt(GetHashKey("sp" .. i .. "_shooting_ability"), 130, true)
    -- end
end

function Impl:RegisterCommands()
    RegisterCommand("gps", function(src, args, raw)
        if not self.global then return end
        SendReactMessage("main:setShow", true)
        SetNuiFocus(true, true)
    end, false)
    RegisterNUICallback("close", function(data, cb)
        SendReactMessage("main:setShow", false)
        SetNuiFocus(false, false)
        cb({})
    end)
end

function Impl:OnResourceStop() if not self.global then return end end

function Impl:MainThread()
    Citizen.CreateThread(function()
        local name = GetPlayerName(PlayerId())
        self:LogInfo("MainThread started for player %s", name)
        while true do
            local ms = 1000
            if self.global and DoesEntityExist(cache.ped) and self.ShowGps then
                ms = 250
                local coords = GetEntityCoords(cache.ped)
                local heading = GetEntityHeading(cache.ped)
                SendReactMessage("GlobalPosition:UpdatePlayer", {
                    src = main.playerServerId,
                    coords = {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        w = heading
                    }
                })
            end
            Wait(ms)
        end
    end)
end
