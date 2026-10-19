# Framework bridges

LR ships optional, side-isolated adapters for ESX Legacy, QBCore, and Qbox. The
application core remains standalone: no framework resource is declared as a manifest
dependency and no framework object is exposed to feature modules.

## Selection

Configure the bridge in `config.lua`:

```lua
Config.Framework = {
  Name = "qbx", -- standalone | auto | esx | qbcore | qbx
}
```

| Name | Resource | Behavior |
|---|---|---|
| `standalone` | none | Default; application readiness is immediate |
| `esx` | `es_extended` | Uses the modern `getSharedObject` export |
| `qbcore` | `qb-core` | Uses `GetCoreObject` |
| `qbx` | `qbx_core` | Uses direct Qbox exports; no QBCore object |
| `auto` | detected | Zero matches selects standalone, one selects it, multiple matches fail |

`qbox` is accepted as an alias for `qbx`. If a framework resource was renamed, use
`Resource = "custom_name"` with an explicit `Name`. The selected resource must already
be in the `started` state, so place it before this resource in `server.cfg`. Selection
fails closed when the resource or required export is unavailable.

`auto` is intended for simple deployments. Select a framework explicitly when QBCore
compatibility resources coexist with Qbox or when resource names were changed.

The adapters target the current upstream API baseline verified on 2026-08-22: ESX Legacy
with `getSharedObject` and `esx:setPlayerData`, QBCore with
`QBCore:Client:OnPlayerUpdated`, and Qbox with direct `qbx_core` exports and its documented
QBCore-compatible lifecycle events. Older forks that omit these APIs are not guaranteed;
pin framework versions in the deployment and rerun the FXServer matrix after upgrades.

## Client API

The standard boot injects `LRClient.FrameworkBridge` at
`context.services.framework`:

```lua
---@param context LRClient.ModuleContext
local function start(context)
  local framework = context.services.framework
  if not framework then error("framework service is unavailable") end

  local player = framework:GetPlayerData()
  if player and player.job then
    context.logger:Info("job=%s grade=%s", player.job.name, player.job.grade)
  end

  context.disposables:Add(framework:OnPlayerDataChanged(function(_nextPlayer, key)
    context.logger:Debug("framework player data changed: %s", key or "unknown")
  end))

  framework:Notify({
    message = "Bridge ready",
    type = "success",
    duration = 3000,
  })
end
```

| API | Result |
|---|---|
| `GetPlayerData()` | Normalized local player snapshot or `nil` |
| `IsPlayerLoaded()` | Current framework character-loaded state |
| `Notify(notification)` | Sends a framework-native notification; returns availability |
| `OnPlayerLoaded(callback)` | Subscribes to character load and returns a disposer |
| `OnPlayerUnloaded(callback)` | Subscribes to logout and returns a disposer |
| `OnPlayerDataChanged(callback)` | Subscribes to normalized data changes and returns a disposer |

For ESX, QBCore, and Qbox, `start = "player"` modules wait until initial player data is
available or the framework load event arrives. Application readiness is one-way: logout
does not stop modules that already started. Use `OnPlayerUnloaded` to clear character
state and tolerate a later load event.

## Server API

The server bridge always derives the player from the trusted server `source` supplied by
the transport or framework event:

```lua
---@param context LRServer.ModuleContext
local function registerRpc(context)
  local framework = context.services.framework
  if not framework then error("framework service is unavailable") end

  context.disposables:Add(
    context.net.Inventory.rpc.useItem:Handle({
      Authorize = function(playerSource, request)
        local player = framework:GetPlayer(playerSource)
        return player ~= nil and player.job ~= nil and player.job.name == "police"
      end,
      Execute = function(playerSource, request)
        -- Recheck ownership, distance, amount, and world state here.
        return useItem(playerSource, request.itemId)
      end,
    })
  )
end
```

| API | Result |
|---|---|
| `GetPlayer(source)` | Normalized online player snapshot or `nil` |
| `IsPlayerLoaded(source)` | Whether the framework currently owns that player |
| `Notify(source, notification)` | Sends a framework-native notification |
| `OnPlayerLoaded(callback)` | Emits `(source, player)` and returns a disposer |
| `OnPlayerUnloaded(callback)` | Emits `source` and returns a disposer |
| `OnPlayerDataChanged(callback)` | Emits `(source, player, key)` and returns a disposer |

Server application readiness means the selected framework API was acquired. It is not a
per-player state. Use `GetPlayer(source)` for each request.

## Normalized DTO

Client and server snapshots expose only neutral fields:

```text
source, identifier, citizenId, name, firstName, lastName, job, gang
```

`job` and `gang` normalize `name`, `label`, `type`, numeric `grade`, grade names/labels,
`onDuty`, and `isBoss`. Missing framework fields remain `nil`, except `isBoss`, which
defaults to `false`. Raw core/player objects, functions, metadata tables, class instances,
and framework-specific mutators never cross the bridge.

## Boundary rules

- Raw framework exports and lifecycle events belong only in `client/bridges/` and
  `server/bridges/`.
- Feature modules use `context.services.framework`; they do not acquire core objects.
- Lifecycle events are readiness/change hints, not proof of identity or authorization.
- Client snapshots are untrusted. Authoritative mutations still validate the
  transport-provided `source`, permissions, ownership, distance, bounds, and replay risk.
- Add every subscription disposer to `context.disposables`.
- Restart this resource after changing bridge selection or restarting the framework.

Automated tests mock current upstream exports/events, but releases still require the
standalone, ESX, QBCore, and Qbox FXServer matrix in `docs/RELEASE.md`.
