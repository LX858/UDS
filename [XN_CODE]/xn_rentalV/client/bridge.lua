-- ALLGAMERS CLIENT BRIDGE
-- The only client file to touch for integrations. config.lua picks what is used:
--   interaction = 'allgamers_ui' | 'ox_lib' | 'ox_target' | 'qb-target' | 'custom'
--   notify      = 'allgamers_ui' | 'ox_lib' | 'native' | 'custom'
-- Built-in choices need no edits. Choose 'custom' and fill in the CUSTOM block below.
ScootClientBridge = {}
local M, Config = ScootClientBridge, ScootConfig

-------------------------------------------------------------------------------
-- CUSTOM: your own prompt, target zones and notifications. Used only with 'custom'.
-------------------------------------------------------------------------------
local Custom = {}

-- Called once when the player walks into range. Show your own "[key] text" prompt.
-- key is Config.interactKeyLabel ('E') or nil for plain status text. text is translated.
-- The resource still listens for Config.interactKey itself; only draw the prompt here.
function Custom.showPrompt(text, key)
end

-- Called once when the prompt should disappear (out of range, menu opened, moving capsule).
function Custom.hidePrompt()
end

-- data = { description = 'text', type = 'success' | 'error' | 'inform' }
function Custom.notify(data)
end

-- Register a zone in your own target script. Return nil to use no target at all.
-- coords: vector3 centre, radius: metres, distance: metres the options work from.
-- options: list of { label = 'translated text', icon = 'fa-solid fa-car',
--                    onSelect = function() end, canInteract = function() return true end }
-- Return any handle you need in Custom.removeTarget.
function Custom.addTarget(id, coords, radius, distance, options)
    return nil
end

function Custom.removeTarget(handle)
end

-------------------------------------------------------------------------------
-- Built-in behaviour. Nothing below needs changes.
-------------------------------------------------------------------------------
local mode = Config.interaction

function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

function M.usesKey()
    return mode == 'allgamers_ui' or mode == 'ox_lib' or mode == 'custom'
end

function M.usesTarget()
    return mode == 'ox_target' or mode == 'qb-target' or mode == 'custom'
end

local oxText = false
function M.showPrompt(text, key)
    if mode == 'custom' then
        Custom.showPrompt(text, key)
        return
    end
    if mode == 'ox_lib' and resourceStarted('ox_lib') then
        local ok = pcall(function()
            exports.ox_lib:showTextUI(key and ('[%s] %s'):format(key, text) or text)
        end)
        if ok then
            oxText = true
            return
        end
    end
    ScootPrompt.show(text, key)
end

function M.hidePrompt()
    if mode == 'custom' then
        Custom.hidePrompt()
        return
    end
    if oxText then
        pcall(function()
            exports.ox_lib:hideTextUI()
        end)
        oxText = false
    end
    ScootPrompt.hide()
end

function M.notify(data)
    local kind = Config.notify
    if kind == 'custom' then
        Custom.notify(data)
        return
    end
    if kind == 'ox_lib' and resourceStarted('ox_lib') then
        TriggerEvent('ox_lib:notify', data)
        return
    end
    if kind == 'native' then
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(data.description or '')
        EndTextCommandThefeedPostTicker(false, false)
        return
    end
    ScootPrompt.toast(data)
end

function M.addTarget(id, coords, radius, distance, options)
    if mode == 'custom' then
        local handle = Custom.addTarget(id, coords, radius, distance, options)
        return handle ~= nil and { kind = 'custom', id = handle } or nil
    end
    if mode == 'ox_target' and resourceStarted('ox_target') then
        local list = {}
        for i, o in ipairs(options) do
            list[i] = {
                name = ('capsule_%s_%d'):format(id, i),
                label = o.label,
                icon = o.icon or Config.targetIcon,
                distance = distance,
                onSelect = o.onSelect,
                canInteract = o.canInteract,
            }
        end
        return {
            kind = 'ox',
            id = exports.ox_target:addSphereZone({
                coords = coords,
                radius = radius,
                options = list,
            }),
        }
    end
    if mode == 'qb-target' and resourceStarted('qb-target') then
        local name = GetCurrentResourceName() .. ':' .. id
        local list = {}
        for i, o in ipairs(options) do
            list[i] = {
                label = o.label,
                icon = o.icon or Config.targetIcon,
                action = o.onSelect,
                canInteract = o.canInteract,
            }
        end
        exports['qb-target']:AddCircleZone(name, coords, radius, {
            name = name,
            useZ = true,
        }, {
            options = list,
            distance = distance,
        })
        return { kind = 'qb', id = name }
    end
end

function M.removeTarget(handle)
    if not handle then
        return
    end
    if handle.kind == 'custom' then
        Custom.removeTarget(handle.id)
    elseif handle.kind == 'ox' and resourceStarted('ox_target') then
        exports.ox_target:removeZone(handle.id)
    elseif handle.kind == 'qb' and resourceStarted('qb-target') then
        exports['qb-target']:RemoveZone(handle.id)
    end
end

-- Sync rental plate on the local vehicle copy. Keys are granted server-side once;
-- this only refreshes the client KeysList silently (no SetOwner / no extra notify).
RegisterNetEvent('capsulerent:client:giveKeys', function(netId, plate)
    if type(plate) ~= 'string' or plate == '' then
        return
    end
    plate = string.upper(plate:match('^%s*(.-)%s*$') or plate)

    CreateThread(function()
        local vehicle = 0
        if netId and tonumber(netId) and tonumber(netId) > 0 then
            local deadline = GetGameTimer() + 5000
            while GetGameTimer() < deadline do
                if NetworkDoesEntityExistWithNetworkId(netId) then
                    vehicle = NetworkGetEntityFromNetworkId(netId)
                    if vehicle ~= 0 and DoesEntityExist(vehicle) then
                        break
                    end
                end
                Wait(50)
            end
        end

        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            SetVehicleNumberPlateText(vehicle, plate)
            SetVehicleDoorsLocked(vehicle, 1)
        end

        TriggerEvent('qb-vehiclekeys:client:AddKeys', plate)

        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            local live = GetVehicleNumberPlateText(vehicle)
            live = live and string.upper(live:match('^%s*(.-)%s*$') or '') or ''
            if live ~= '' and live ~= plate then
                TriggerEvent('qb-vehiclekeys:client:AddKeys', live)
                TriggerServerEvent('capsulerent:server:syncKeyPlate', live)
            end
        end
    end)
end)
