local duty = false

local dutyCoords = vec3(2511.24, -428.04, 94.58)

exports.ox_target:addBoxZone({
    coords = dutyCoords,
    size = vec3(1, 1, 2),
    rotation = 0,
    debug = false,
    options = {
        {
            name = 'duty_toggle',
            label = duty and 'Tắt Duty' or 'Bật Duty',
            icon = 'fa-solid fa-user-shield',
            onSelect = function()
                duty = not duty
                TriggerServerEvent('QBCore:ToggleDuty')
                lib.notify({
                    title = 'Duty',
                    description = duty and 'Bạn đã bật duty!' or 'Bạn đã tắt duty!',
                    type = duty and 'success' or 'error'
                })
            end,
            canInteract = function()
                return true
            end
        }
    }
})