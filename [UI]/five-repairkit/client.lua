local result = nil

exports('Minigame', function(difficulty)
    result = nil -- reset
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'start',
        difficulty = difficulty or 'medium'
    }) 
    while result == nil do 
        Wait(100)
    end
    SetNuiFocus(false, false)
    return result
end)

RegisterNUICallback('GetResult', function(data, cb)
    result = data
    cb()
end)