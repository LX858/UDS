local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}

-- Load config
Config = Config or require 'config.config'

-- Toggle duty function
local function ToggleDuty()
    TriggerServerEvent('QBCore:ToggleDuty')
end

-- Create duty toggle zones for all locations
if Config and Config.DutyLocations then
    for i, location in pairs(Config.DutyLocations) do
        exports.ox_target:addBoxZone({
            coords = location.coords,
            size = location.size or vec3(2.0, 2.0, 2.0),
            rotation = location.heading or 0.0,
            debug = false,
            options = {
                {
                    name = 'duty_toggle_' .. i,
                    icon = location.icon or 'fas fa-clipboard-check',
                    label = location.label or 'On/off duty',
                    groups = location.jobs or location.job or location.groups or nil,
                    onSelect = function()
                        ToggleDuty()
                    end,
                    canInteract = function()
                        return true
                    end
                }
            }
        })
    end
end


-- Get player data on resource start
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)