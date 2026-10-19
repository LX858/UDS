-- This fixture should report undefined-global when checked with the server config.
SendNUIMessage({ event = "main:setShow", data = true })
LRClient.CreateClientApplication({})
AbortTextChat()
TriggerClientEventInternal("blocked", 1, "", 0)
TriggerLatentClientEventInternal("blocked", 1, "", 0, 1)
AddEventHandler("blocked", function() end)
TriggerEvent("blocked", {})
RegisterResourceAsEventHandler("blocked")
