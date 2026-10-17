local targetLocations = {
    {
        coords = vec3(86.8, -402.45, 41.53),
        job = 'police',
        label = 'Mua Phiếu Sửa Xe (Cảnh Sát)'
    },
    {
        coords = vec3(357.16012573242,-1415.7836914062,32.381465911865),
        job = 'ambulance',
        label = 'Mua Phiếu Sửa Xe (Y Tế)'
    }
}

CreateThread(function()
    for i, location in ipairs(targetLocations) do
        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'buy_repair_ticket_' .. i,
                    icon = 'fa-solid fa-wrench',
                    label = location.label,
                    groups = location.job,
                    onSelect = function()
                        ShowRepairTicketMenu(location.job)
                    end
                }
            }
        })
    end
end)

function ShowRepairTicketMenu(job)
    lib.registerContext({
        id = 'repair_ticket_menu',
        title = 'Mua Phiếu Sửa Xe',
        options = {
            {
                title = 'Phiếu Sửa Xe Nghành',
                description = 'Giá: 100$ (Tiền mặt) + 900$ (Quỹ nghành)',
                icon = 'wrench',
                iconColor = '#3b82f6',
                onSelect = function()
                    TriggerServerEvent('suaxenghanh:purchaseTicket', job)
                end
            }
        }
    })
    lib.showContext('repair_ticket_menu')
end

RegisterNetEvent('suaxenghanh:notify', function(type, title, description)
    lib.notify({
        title = title,
        description = description,
        type = type
    })
end)
