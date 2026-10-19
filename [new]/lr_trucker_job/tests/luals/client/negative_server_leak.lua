-- This fixture should report undefined-global when checked with the client config.
TriggerClientEvent("server-only:event", 1, {})
LRServer.CreateServerApplication({})
local _serverSource = source
local _routingBucket = GetPlayerRoutingBucket(1)
SendNuiMessage("{}")
RegisterRawNuiCallback("blocked", function() end)
UnregisterRawNuiCallback("blocked")
TriggerServerEventInternal("blocked", "", 0)
TriggerLatentServerEventInternal("blocked", "", 0, 1)
AddEventHandler("blocked", function() end)
TriggerEvent("blocked", {})
RegisterResourceAsEventHandler("blocked")
