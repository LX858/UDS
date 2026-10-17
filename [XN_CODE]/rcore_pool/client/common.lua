
function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(100)
    end
end

function CustomDisplayHelpTextThisFrame(text)
    DisplayHelpTextThisFrame(text, 0)
end
