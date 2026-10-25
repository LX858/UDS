RegisterNetEvent("jumpscare:toggleNUI")
AddEventHandler("jumpscare:toggleNUI", function(display)
    SendNUIMessage({
        type = "ui",
        display = display
    })
end)

RegisterNetEvent("jumpscare:show")
AddEventHandler("jumpscare:show", function(timer)
    SendNUIMessage({
        type = "ui",
        display = true
    })
    Wait(3000)
    SendNUIMessage({
        type = "ui",
        display = false
    })
end)
