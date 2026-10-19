-- This fixture should report undefined-global when checked with the shared config.
SendNUIMessage({ event = "main:setShow", data = true })
TriggerClientEvent("server-only:event", 1, {})
LRClient.CreateClientApplication({})
LRServer.CreateServerApplication({})
local _serverSource = source
AbortTextChat()
local _routingBucket = GetPlayerRoutingBucket(1)
TriggerEventInternal("blocked", "", 0)
AddEventHandler("blocked", function() end)
TriggerEvent("blocked", {})
RegisterResourceAsEventHandler("blocked")
